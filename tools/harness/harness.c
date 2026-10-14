/* Headless libretro harness for testing the ROM.
 *   harness <core.dylib> <rom.sfc> "<script>"
 * Script tokens (space separated):
 *   wN          run N frames
 *   hBTN rBTN   hold / release (A B X Y L R UP DOWN LEFT RIGHT START SELECT)
 *   pBTN        tap: hold 3 frames, release, run 3 frames
 *   s:FILE      save the current frame as PPM
 *   mADDR:LEN   hex dump WRAM (ADDR hex)
 *   a           print audio peak since the last 'a'
 */
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "libretro.h"

static unsigned fmt = RETRO_PIXEL_FORMAT_0RGB1555;
static uint8_t frame_rgb[512 * 480 * 3];
static unsigned fw, fh;
static int held[16];
static int audio_peak;
static FILE *wav_f;

static bool env(unsigned cmd, void *data) {
    switch (cmd) {
    case RETRO_ENVIRONMENT_SET_PIXEL_FORMAT:
        fmt = *(const unsigned *)data;
        return true;
    case RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY:
    case RETRO_ENVIRONMENT_GET_SAVE_DIRECTORY:
        *(const char **)data = "build/emu";
        return true;
    case RETRO_ENVIRONMENT_GET_CAN_DUPE:
        *(bool *)data = true;
        return true;
    default:
        return false;
    }
}

static void video(const void *data, unsigned w, unsigned h, size_t pitch) {
    if (!data) return;
    fw = w; fh = h;
    for (unsigned y = 0; y < h; y++) {
        for (unsigned x = 0; x < w; x++) {
            uint8_t *o = &frame_rgb[(y * w + x) * 3];
            if (fmt == RETRO_PIXEL_FORMAT_XRGB8888) {
                uint32_t p = ((const uint32_t *)((const uint8_t *)data + y * pitch))[x];
                o[0] = p >> 16; o[1] = p >> 8; o[2] = p;
            } else {
                uint16_t p = ((const uint16_t *)((const uint8_t *)data + y * pitch))[x];
                if (fmt == RETRO_PIXEL_FORMAT_RGB565) {
                    o[0] = ((p >> 11) & 31) << 3; o[1] = ((p >> 5) & 63) << 2; o[2] = (p & 31) << 3;
                } else {
                    o[0] = ((p >> 10) & 31) << 3; o[1] = ((p >> 5) & 31) << 3; o[2] = (p & 31) << 3;
                }
            }
        }
    }
}

static void audio1(int16_t l, int16_t r) {
    int a = abs(l); if (a > audio_peak) audio_peak = a;
    (void)r;
}
static size_t audiob(const int16_t *d, size_t frames) {
    for (size_t i = 0; i < frames * 2; i++) { int a = abs(d[i]); if (a > audio_peak) audio_peak = a; }
    if (wav_f) fwrite(d, 4, frames, wav_f);
    return frames;
}
static void poll(void) {}
static int16_t input(unsigned port, unsigned device, unsigned index, unsigned id) {
    (void)index;
    if (port != 0 || device != RETRO_DEVICE_JOYPAD || id >= 16) return 0;
    return held[id] ? 1 : 0;
}

static int btn_id(const char *s) {
    const char *names[] = {"B", "Y", "SELECT", "START", "UP", "DOWN", "LEFT", "RIGHT", "A", "X", "L", "R"};
    for (int i = 0; i < 12; i++) if (!strcmp(s, names[i])) return i;
    fprintf(stderr, "unknown button %s\n", s);
    exit(2);
}

#define SYM(name) name##_t name = (name##_t)dlsym(h, #name); if (!name) { fprintf(stderr, "missing %s\n", #name); return 1; }
typedef void (*retro_init_t)(void);
typedef void (*retro_run_t)(void);
typedef bool (*retro_load_game_t)(const struct retro_game_info *);
typedef void (*retro_set_environment_t)(retro_environment_t);
typedef void (*retro_set_video_refresh_t)(retro_video_refresh_t);
typedef void (*retro_set_audio_sample_t)(retro_audio_sample_t);
typedef void (*retro_set_audio_sample_batch_t)(retro_audio_sample_batch_t);
typedef void (*retro_set_input_poll_t)(retro_input_poll_t);
typedef void (*retro_set_input_state_t)(retro_input_state_t);
typedef void *(*retro_get_memory_data_t)(unsigned);
typedef size_t (*retro_serialize_size_t)(void);
typedef bool (*retro_serialize_t)(void *, size_t);

int main(int argc, char **argv) {
    if (argc < 4) { fprintf(stderr, "usage: harness core rom script\n"); return 1; }
    void *h = dlopen(argv[1], RTLD_NOW);
    if (!h) { fprintf(stderr, "%s\n", dlerror()); return 1; }
    SYM(retro_set_environment) SYM(retro_set_video_refresh) SYM(retro_set_audio_sample)
    SYM(retro_set_audio_sample_batch) SYM(retro_set_input_poll) SYM(retro_set_input_state)
    SYM(retro_init) SYM(retro_load_game) SYM(retro_run) SYM(retro_get_memory_data)
    SYM(retro_serialize_size) SYM(retro_serialize)
    retro_set_environment(env);
    retro_init();
    retro_set_video_refresh(video);
    retro_set_audio_sample(audio1);
    retro_set_audio_sample_batch(audiob);
    retro_set_input_poll(poll);
    retro_set_input_state(input);

    FILE *f = fopen(argv[2], "rb");
    if (!f) { perror(argv[2]); return 1; }
    fseek(f, 0, SEEK_END); long n = ftell(f); fseek(f, 0, SEEK_SET);
    void *rom = malloc(n); fread(rom, 1, n, f); fclose(f);
    struct retro_game_info gi = { argv[2], rom, (size_t)n, NULL };
    if (!retro_load_game(&gi)) { fprintf(stderr, "load failed\n"); return 1; }

    char *script = strdup(argv[3]);
    long total = 0;
    for (char *tok = strtok(script, " \n"); tok; tok = strtok(NULL, " \n")) {
        if (tok[0] == 'w') {
            int k = atoi(tok + 1);
            for (int i = 0; i < k; i++) { retro_run(); total++; }
        } else if (tok[0] == 'h') {
            held[btn_id(tok + 1)] = 1;
        } else if (tok[0] == 'r') {
            held[btn_id(tok + 1)] = 0;
        } else if (tok[0] == 'p') {
            int id = btn_id(tok + 1);
            held[id] = 1; for (int i = 0; i < 3; i++) { retro_run(); total++; }
            held[id] = 0; for (int i = 0; i < 3; i++) { retro_run(); total++; }
        } else if (tok[0] == 's' && tok[1] == ':') {
            FILE *o = fopen(tok + 2, "wb");
            fprintf(o, "P6\n%u %u\n255\n", fw, fh);
            fwrite(frame_rgb, 1, fw * fh * 3, o);
            fclose(o);
            printf("frame %ld: saved %s (%ux%u)\n", total, tok + 2, fw, fh);
        } else if (tok[0] == 'm') {
            unsigned addr, len;
            sscanf(tok + 1, "%x:%u", &addr, &len);
            uint8_t *ram = retro_get_memory_data(RETRO_MEMORY_SYSTEM_RAM);
            printf("ram %05X:", addr);
            for (unsigned i = 0; i < len; i++) printf(" %02X", ram[addr + i]);
            printf("\n");
        } else if (tok[0] == 'c') {
            size_t sz = retro_serialize_size();
            uint8_t *st = malloc(sz);
            retro_serialize(st, sz);
            for (size_t i = 0; i + 4 < sz; i++) {
                if (!memcmp(st + i, "REG:", 4)) {
                    printf("REG block:");
                    for (int k = 0; k < 40; k++) printf(" %02X", st[i + k]);
                    printf("\n");
                    break;
                }
            }
            free(st);
        } else if (tok[0] == 'v' && tok[1] == ':') {
            wav_f = fopen(tok + 2, "wb");
        } else if (tok[0] == 'V') {
            if (wav_f) fclose(wav_f);
            wav_f = NULL;
        } else if (tok[0] == 'u') {
            /* uADDR:LO:HI:BTN  run until LO <= ram[ADDR] <= HI (max 3000 frames), then tap BTN */
            unsigned addr, lo, hi; char btn[16];
            sscanf(tok + 1, "%x:%u:%u:%15s", &addr, &lo, &hi, btn);
            uint8_t *ram = retro_get_memory_data(RETRO_MEMORY_SYSTEM_RAM);
            int n = 0;
            while (!(ram[addr] >= lo && ram[addr] <= hi) && n < 3000) { retro_run(); total++; n++; }
            int id = btn_id(btn);
            held[id] = 1; retro_run(); total++;
            held[id] = 0; retro_run(); total++;
            printf("frame %ld: u %05X=%u after %d -> %s\n", total, addr, ram[addr], n, btn);
        } else if (tok[0] == 'b') {
            /* bADDR:FRAMES:DELAY  balance bot: ADDR = bx, by, vx, vy (signed 8.8 words).
               Each frame it looks at the state DELAY frames ago, extrapolates 8 frames
               and holds the D-pad against any lean past 1.5 px. */
            unsigned addr, frames, delay;
            sscanf(tok + 1, "%x:%u:%u", &addr, &frames, &delay);
            uint8_t *ram = retro_get_memory_data(RETRO_MEMORY_SYSTEM_RAM);
            static int16_t hist[4096][4];
            if (delay > 60) delay = 60;
            for (unsigned f = 0; f < frames; f++) {
                int16_t *h = hist[f & 4095];
                for (int k = 0; k < 4; k++) h[k] = (int16_t)(ram[addr + 2 * k] | (ram[addr + 2 * k + 1] << 8));
                int16_t *o = hist[(f >= delay ? f - delay : 0) & 4095];
                double px = (o[0] + o[2] * 8) / 256.0, py = (o[1] + o[3] * 8) / 256.0;
                held[7] = px < -1.5;    /* leaning left: RIGHT */
                held[6] = px > 1.5;     /* leaning right: LEFT */
                held[4] = py > 1.5;  held[5] = py < -1.5;
                retro_run(); total++;
            }
            held[4] = held[5] = held[6] = held[7] = 0;
            printf("frame %ld: bot done\n", total);
        } else if (tok[0] == 'a') {
            printf("frame %ld: audio peak %d\n", total, audio_peak);
            audio_peak = 0;
        }
    }
    return 0;
}
