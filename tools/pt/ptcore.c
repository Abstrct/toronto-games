/* ptcore: long-lived headless SNES core for the playtest harness (tools/pt).
 *   ptcore <core.dylib> <rom.sfc>
 * Reads one command per line on stdin, answers one line on stdout:
 * "ok ..." or "err <message>".
 *
 *   run N M1 [M2]          run N frames with joypad masks (libretro bit order)
 *   watch A:L[,A:L...]     WRAM regions to return after every run ("watch -" clears)
 *   peek A L               hex dump WRAM (A hex, L decimal)
 *   poke A HEX             write bytes to WRAM
 *   shot PATH              current frame as PPM
 *   film PATH N STRIDE M1 M2  run N*STRIDE frames, append a raw RGB frame every STRIDE
 *   hash                   FNV-1a of the current frame
 *   save PATH / load PATH  savestate to / from a file
 *   sramget PATH / sramput PATH  battery RAM to / from a file
 *   regs                   PB PC S A X Y P DB (hex)
 *   stack                  S, then hex bytes S+1..$1FFF
 *   audio                  peak and rms since the last audio command
 *   wav PATH / wavend      capture raw s16 stereo 32 kHz audio
 *   reset / quit
 */
#include <dlfcn.h>
#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "libretro.h"

static unsigned fmt = RETRO_PIXEL_FORMAT_0RGB1555;
static uint8_t raw[512 * 480 * 4];
static size_t raw_pitch;
static unsigned fw, fh;
static uint8_t rgb[512 * 480 * 3];
static uint16_t mask[2];
static int audio_peak;
static double audio_sq;
static long audio_n;
static FILE *wav_f;
static long total;

static bool env(unsigned cmd, void *data) {
    switch (cmd) {
    case RETRO_ENVIRONMENT_SET_PIXEL_FORMAT:
        fmt = *(const unsigned *)data;
        return true;
    case RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY:
    case RETRO_ENVIRONMENT_GET_SAVE_DIRECTORY:
        *(const char **)data = "build/pt";
        return true;
    case RETRO_ENVIRONMENT_GET_CAN_DUPE:
        *(bool *)data = true;
        return true;
    default:
        return false;
    }
}

/* keep the raw frame; convert only when someone looks at it */
static void video(const void *data, unsigned w, unsigned h, size_t pitch) {
    if (!data) return;
    fw = w; fh = h;
    size_t row = w * (fmt == RETRO_PIXEL_FORMAT_XRGB8888 ? 4 : 2);
    raw_pitch = row;
    for (unsigned y = 0; y < h; y++)
        memcpy(raw + y * row, (const uint8_t *)data + y * pitch, row);
}

static void to_rgb(void) {
    for (unsigned y = 0; y < fh; y++) {
        for (unsigned x = 0; x < fw; x++) {
            uint8_t *o = &rgb[(y * fw + x) * 3];
            if (fmt == RETRO_PIXEL_FORMAT_XRGB8888) {
                uint32_t p = ((const uint32_t *)(raw + y * raw_pitch))[x];
                o[0] = p >> 16; o[1] = p >> 8; o[2] = p;
            } else {
                uint16_t p = ((const uint16_t *)(raw + y * raw_pitch))[x];
                if (fmt == RETRO_PIXEL_FORMAT_RGB565) {
                    o[0] = ((p >> 11) & 31) << 3; o[1] = ((p >> 5) & 63) << 2; o[2] = (p & 31) << 3;
                } else {
                    o[0] = ((p >> 10) & 31) << 3; o[1] = ((p >> 5) & 31) << 3; o[2] = (p & 31) << 3;
                }
            }
        }
    }
}

static void audio1(int16_t l, int16_t r) { (void)l; (void)r; }
static size_t audiob(const int16_t *d, size_t frames) {
    for (size_t i = 0; i < frames * 2; i++) {
        int a = abs(d[i]);
        if (a > audio_peak) audio_peak = a;
        audio_sq += (double)d[i] * d[i];
    }
    audio_n += frames * 2;
    if (wav_f) fwrite(d, 4, frames, wav_f);
    return frames;
}
static void poll_in(void) {}
static int16_t input(unsigned port, unsigned device, unsigned index, unsigned id) {
    (void)index;
    if (port > 1 || device != RETRO_DEVICE_JOYPAD || id >= 16) return 0;
    return (mask[port] >> id) & 1;
}

typedef void (*retro_init_t)(void);
typedef void (*retro_run_t)(void);
typedef void (*retro_reset_t)(void);
typedef bool (*retro_load_game_t)(const struct retro_game_info *);
typedef void (*retro_set_environment_t)(retro_environment_t);
typedef void (*retro_set_video_refresh_t)(retro_video_refresh_t);
typedef void (*retro_set_audio_sample_t)(retro_audio_sample_t);
typedef void (*retro_set_audio_sample_batch_t)(retro_audio_sample_batch_t);
typedef void (*retro_set_input_poll_t)(retro_input_poll_t);
typedef void (*retro_set_input_state_t)(retro_input_state_t);
typedef void *(*retro_get_memory_data_t)(unsigned);
typedef size_t (*retro_get_memory_size_t)(unsigned);
typedef size_t (*retro_serialize_size_t)(void);
typedef bool (*retro_serialize_t)(void *, size_t);
typedef bool (*retro_unserialize_t)(const void *, size_t);

static retro_run_t f_run;
static retro_get_memory_data_t f_get_memory_data;
static retro_get_memory_size_t f_get_memory_size;
static retro_serialize_size_t f_serialize_size;
static retro_serialize_t f_serialize;
static retro_unserialize_t f_unserialize;

#define WATCH_MAX 32
static unsigned watch_addr[WATCH_MAX], watch_len[WATCH_MAX], nwatch;

static uint8_t *wram(void) { return f_get_memory_data(RETRO_MEMORY_SYSTEM_RAM); }

static void put_hex(const uint8_t *p, unsigned n) {
    for (unsigned i = 0; i < n; i++) printf("%02X", p[i]);
}

static void run_frames(long n) {
    for (long i = 0; i < n; i++) { f_run(); total++; }
}

static void reply_run(void) {
    printf("ok %ld", total);
    uint8_t *r = wram();
    for (unsigned i = 0; i < nwatch; i++) { putchar(' '); put_hex(r + watch_addr[i], watch_len[i]); }
    putchar('\n');
}

/* find a savestate block "NAME:nnnnnn:" and return a pointer to its data */
static const uint8_t *state_block(const uint8_t *st, size_t sz, const char *name) {
    size_t nl = strlen(name);
    for (size_t i = 0; i + nl + 8 < sz; i++)
        if (!memcmp(st + i, name, nl) && st[i + nl] == ':' && st[i + nl + 7] == ':')
            return st + i + nl + 8;
    return NULL;
}

static int write_file(const char *path, const void *d, size_t n) {
    FILE *o = fopen(path, "wb");
    if (!o) return 0;
    fwrite(d, 1, n, o);
    fclose(o);
    return 1;
}

static void *read_file(const char *path, size_t *n) {
    FILE *f = fopen(path, "rb");
    if (!f) return NULL;
    fseek(f, 0, SEEK_END); *n = ftell(f); fseek(f, 0, SEEK_SET);
    void *d = malloc(*n);
    if (fread(d, 1, *n, f) != *n) { fclose(f); free(d); return NULL; }
    fclose(f);
    return d;
}

#define SYM(name) name##_t name##_p = (name##_t)dlsym(h, #name); if (!name##_p) { fprintf(stderr, "missing %s\n", #name); return 1; }

int main(int argc, char **argv) {
    if (argc < 3) { fprintf(stderr, "usage: ptcore core rom\n"); return 1; }
    void *h = dlopen(argv[1], RTLD_NOW);
    if (!h) { fprintf(stderr, "%s\n", dlerror()); return 1; }
    SYM(retro_set_environment) SYM(retro_set_video_refresh) SYM(retro_set_audio_sample)
    SYM(retro_set_audio_sample_batch) SYM(retro_set_input_poll) SYM(retro_set_input_state)
    SYM(retro_init) SYM(retro_load_game) SYM(retro_run) SYM(retro_reset) SYM(retro_get_memory_data)
    SYM(retro_get_memory_size) SYM(retro_serialize_size) SYM(retro_serialize) SYM(retro_unserialize)
    f_run = retro_run_p;
    f_get_memory_data = retro_get_memory_data_p;
    f_get_memory_size = retro_get_memory_size_p;
    f_serialize_size = retro_serialize_size_p;
    f_serialize = retro_serialize_p;
    f_unserialize = retro_unserialize_p;

    retro_set_environment_p(env);
    retro_init_p();
    retro_set_video_refresh_p(video);
    retro_set_audio_sample_p(audio1);
    retro_set_audio_sample_batch_p(audiob);
    retro_set_input_poll_p(poll_in);
    retro_set_input_state_p(input);

    size_t n;
    void *rom = read_file(argv[2], &n);
    if (!rom) { perror(argv[2]); return 1; }
    struct retro_game_info gi = { argv[2], rom, n, NULL };
    if (!retro_load_game_p(&gi)) { fprintf(stderr, "load failed\n"); return 1; }
    setvbuf(stdout, NULL, _IOLBF, 0);
    printf("ok ready\n");

    char line[4096], a1[2048];
    while (fgets(line, sizeof line, stdin)) {
        char cmd[32] = {0};
        if (sscanf(line, "%31s", cmd) != 1) continue;
        if (!strcmp(cmd, "run")) {
            long k = 0; unsigned m1 = 0, m2 = 0;
            sscanf(line, "%*s %ld %x %x", &k, &m1, &m2);
            mask[0] = m1; mask[1] = m2;
            run_frames(k);
            reply_run();
        } else if (!strcmp(cmd, "watch")) {
            nwatch = 0;
            if (sscanf(line, "%*s %2047s", a1) == 1 && a1[0] != '-') {
                for (char *t = strtok(a1, ","); t && nwatch < WATCH_MAX; t = strtok(NULL, ",")) {
                    if (sscanf(t, "%x:%u", &watch_addr[nwatch], &watch_len[nwatch]) == 2
                        && watch_addr[nwatch] + watch_len[nwatch] <= 0x20000)
                        nwatch++;
                }
            }
            printf("ok %u\n", nwatch);
        } else if (!strcmp(cmd, "peek")) {
            unsigned a = 0, l = 0;
            sscanf(line, "%*s %x %u", &a, &l);
            if (a + l > 0x20000) { printf("err range\n"); continue; }
            printf("ok "); put_hex(wram() + a, l); putchar('\n');
        } else if (!strcmp(cmd, "poke")) {
            unsigned a = 0;
            if (sscanf(line, "%*s %x %2047s", &a, a1) != 2) { printf("err args\n"); continue; }
            size_t l = strlen(a1) / 2;
            if (a + l > 0x20000) { printf("err range\n"); continue; }
            for (size_t i = 0; i < l; i++) { unsigned b; sscanf(a1 + i * 2, "%2x", &b); wram()[a + i] = b; }
            printf("ok\n");
        } else if (!strcmp(cmd, "shot")) {
            sscanf(line, "%*s %2047s", a1);
            to_rgb();
            FILE *o = fopen(a1, "wb");
            if (!o) { printf("err open\n"); continue; }
            fprintf(o, "P6\n%u %u\n255\n", fw, fh);
            fwrite(rgb, 1, fw * fh * 3, o);
            fclose(o);
            printf("ok %u %u\n", fw, fh);
        } else if (!strcmp(cmd, "film")) {
            long k = 0, stride = 1; unsigned m1 = 0, m2 = 0;
            sscanf(line, "%*s %2047s %ld %ld %x %x", a1, &k, &stride, &m1, &m2);
            FILE *o = fopen(a1, "ab");
            if (!o) { printf("err open\n"); continue; }
            mask[0] = m1; mask[1] = m2;
            for (long i = 0; i < k; i++) {
                run_frames(stride);
                to_rgb();
                fwrite(rgb, 1, fw * fh * 3, o);
            }
            fclose(o);
            printf("ok %ld %u %u\n", total, fw, fh);
        } else if (!strcmp(cmd, "hash")) {
            uint32_t hv = 2166136261u;
            for (size_t i = 0; i < fh * raw_pitch; i++) { hv ^= raw[i]; hv *= 16777619u; }
            printf("ok %08X\n", hv);
        } else if (!strcmp(cmd, "save") || !strcmp(cmd, "load")) {
            sscanf(line, "%*s %2047s", a1);
            size_t sz = f_serialize_size();
            if (cmd[0] == 's') {
                uint8_t *st = malloc(sz);
                bool ok = f_serialize(st, sz) && write_file(a1, st, sz);
                free(st);
                /* keep the picture too, so a loaded state can be looked at before it runs */
                char fbp[2100];
                snprintf(fbp, sizeof fbp, "%s.fb", a1);
                FILE *o = fopen(fbp, "wb");
                if (o) {
                    unsigned hd[3] = { fw, fh, (unsigned)raw_pitch };
                    fwrite(hd, sizeof hd, 1, o);
                    fwrite(raw, 1, fh * raw_pitch, o);
                    fclose(o);
                }
                printf(ok ? "ok %zu\n" : "err save\n", sz);
            } else {
                size_t got;
                uint8_t *st = read_file(a1, &got);
                if (!st) { printf("err open\n"); continue; }
                bool ok = f_unserialize(st, got);
                free(st);
                char fbp[2100];
                snprintf(fbp, sizeof fbp, "%s.fb", a1);
                FILE *fi = fopen(fbp, "rb");
                if (fi) {
                    unsigned hd[3];
                    if (fread(hd, sizeof hd, 1, fi) == 1 && hd[1] * hd[2] <= sizeof raw) {
                        fw = hd[0]; fh = hd[1]; raw_pitch = hd[2];
                        fread(raw, 1, fh * raw_pitch, fi);
                    }
                    fclose(fi);
                }
                printf(ok ? "ok\n" : "err load\n");
            }
        } else if (!strcmp(cmd, "sramget") || !strcmp(cmd, "sramput")) {
            sscanf(line, "%*s %2047s", a1);
            uint8_t *s = f_get_memory_data(RETRO_MEMORY_SAVE_RAM);
            size_t sz = f_get_memory_size(RETRO_MEMORY_SAVE_RAM);
            if (!s || !sz) { printf("err nosram\n"); continue; }
            if (cmd[4] == 'g') {
                printf(write_file(a1, s, sz) ? "ok %zu\n" : "err write\n", sz);
            } else {
                size_t got;
                uint8_t *d = read_file(a1, &got);
                if (!d) { printf("err open\n"); continue; }
                memcpy(s, d, got < sz ? got : sz);
                free(d);
                printf("ok\n");
            }
        } else if (!strcmp(cmd, "regs")) {
            size_t sz = f_serialize_size();
            uint8_t *st = malloc(sz);
            f_serialize(st, sz);
            const uint8_t *r = state_block(st, sz, "REG");
            if (!r) { free(st); printf("err noreg\n"); continue; }
            /* PB DB P A D S X Y PC, multi-byte fields big-endian */
            printf("ok %02X %04X %04X %04X %04X %04X %04X %02X\n",
                   r[0], r[14] << 8 | r[15], r[8] << 8 | r[9], r[4] << 8 | r[5],
                   r[10] << 8 | r[11], r[12] << 8 | r[13], r[2] << 8 | r[3], r[1]);
            free(st);
        } else if (!strcmp(cmd, "stack")) {
            size_t sz = f_serialize_size();
            uint8_t *st = malloc(sz);
            f_serialize(st, sz);
            const uint8_t *r = state_block(st, sz, "REG");
            unsigned s = r ? (r[8] << 8 | r[9]) : 0x1FFF;
            free(st);
            if (s >= 0x1FFF || s < 0x100) { printf("ok %04X\n", s); continue; }
            printf("ok %04X ", s); put_hex(wram() + s + 1, 0x1FFF - s); putchar('\n');
        } else if (!strcmp(cmd, "audio")) {
            double rms = audio_n ? sqrt(audio_sq / audio_n) : 0;
            printf("ok %d %.1f\n", audio_peak, rms);
            audio_peak = 0; audio_sq = 0; audio_n = 0;
        } else if (!strcmp(cmd, "wav")) {
            sscanf(line, "%*s %2047s", a1);
            if (wav_f) fclose(wav_f);
            wav_f = fopen(a1, "wb");
            printf(wav_f ? "ok\n" : "err open\n");
        } else if (!strcmp(cmd, "wavend")) {
            if (wav_f) fclose(wav_f);
            wav_f = NULL;
            printf("ok\n");
        } else if (!strcmp(cmd, "reset")) {
            ((retro_reset_t)retro_reset_p)();
            printf("ok\n");
        } else if (!strcmp(cmd, "quit")) {
            printf("ok\n");
            break;
        } else {
            printf("err unknown %s\n", cmd);
        }
    }
    return 0;
}
