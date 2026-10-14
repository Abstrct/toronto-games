// Toronto Games player: a minimal macOS libretro frontend for the snes9x core.
//   player <core.dylib> <rom.sfc>
// Window at 3x, keyboard + game controllers (2 pads), CoreAudio sound,
// battery SRAM saved next to the ROM (.srm) so records survive.
//
// Keys (pad 1):  arrows = D-pad   A / X / Space = A   B / Z = B
//                Return = Start   Right Shift / Tab = Select   Esc = quit
//                Esc = quit
#import <Cocoa/Cocoa.h>
#import <AudioToolbox/AudioToolbox.h>
#import <GameController/GameController.h>
#include <dlfcn.h>
#include "libretro.h"

// ---- core symbols ----
static void (*r_init)(void);
static void (*r_deinit)(void);
static void (*r_run)(void);
static bool (*r_load_game)(const struct retro_game_info *);
static void (*r_unload_game)(void);
static void (*r_set_environment)(retro_environment_t);
static void (*r_set_video)(retro_video_refresh_t);
static void (*r_set_audio)(retro_audio_sample_t);
static void (*r_set_audio_batch)(retro_audio_sample_batch_t);
static void (*r_set_poll)(retro_input_poll_t);
static void (*r_set_state)(retro_input_state_t);
static void (*r_get_av)(struct retro_system_av_info *);
static void *(*r_get_mem)(unsigned);
static size_t (*r_get_mem_size)(unsigned);
static void (*r_set_controller)(unsigned, unsigned);

// ---- shared state ----
static unsigned pixfmt = RETRO_PIXEL_FORMAT_0RGB1555;
static uint32_t fb[512 * 480];
static unsigned fbw = 256, fbh = 224;
static int keys[2][16];
static NSString *srmPath;

// audio ring buffer (stereo int16 frames)
#define RING (1 << 15)
static int16_t ring[RING * 2];
static volatile uint32_t rhead, rtail;
static AudioQueueRef queue;

static bool env_cb(unsigned cmd, void *data) {
    switch (cmd) {
    case RETRO_ENVIRONMENT_SET_PIXEL_FORMAT: pixfmt = *(const unsigned *)data; return true;
    case RETRO_ENVIRONMENT_GET_CAN_DUPE: *(bool *)data = true; return true;
    case RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY:
    case RETRO_ENVIRONMENT_GET_SAVE_DIRECTORY: *(const char **)data = "."; return true;
    default: return false;
    }
}

static void video_cb(const void *data, unsigned w, unsigned h, size_t pitch) {
    if (!data) return;
    fbw = w; fbh = h;
    for (unsigned y = 0; y < h; y++) {
        uint32_t *o = &fb[y * w];
        if (pixfmt == RETRO_PIXEL_FORMAT_XRGB8888) {
            const uint32_t *s = (const uint32_t *)((const uint8_t *)data + y * pitch);
            for (unsigned x = 0; x < w; x++) {
                uint32_t p = s[x];
                o[x] = 0xFF000000 | ((p & 0xFF) << 16) | (p & 0xFF00) | ((p >> 16) & 0xFF);
            }
        } else {
            const uint16_t *s = (const uint16_t *)((const uint8_t *)data + y * pitch);
            for (unsigned x = 0; x < w; x++) {
                uint16_t p = s[x];
                unsigned r, g, b;
                if (pixfmt == RETRO_PIXEL_FORMAT_RGB565) {
                    r = (p >> 11) << 3; g = ((p >> 5) & 63) << 2; b = (p & 31) << 3;
                } else {
                    r = ((p >> 10) & 31) << 3; g = ((p >> 5) & 31) << 3; b = (p & 31) << 3;
                }
                o[x] = 0xFF000000 | (b << 16) | (g << 8) | r;
            }
        }
    }
}

static void push_audio(const int16_t *d, size_t frames) {
    for (size_t i = 0; i < frames; i++) {
        uint32_t next = (rhead + 1) & (RING - 1);
        if (next == rtail) break;               // full: drop
        ring[rhead * 2] = d[i * 2];
        ring[rhead * 2 + 1] = d[i * 2 + 1];
        rhead = next;
    }
}
static void audio_cb(int16_t l, int16_t r) { int16_t s[2] = {l, r}; push_audio(s, 1); }
static size_t audio_batch_cb(const int16_t *d, size_t frames) { push_audio(d, frames); return frames; }

static void aq_callback(void *user, AudioQueueRef q, AudioQueueBufferRef buf) {
    int16_t *out = buf->mAudioData;
    unsigned frames = buf->mAudioDataBytesCapacity / 4;
    for (unsigned i = 0; i < frames; i++) {
        if (rtail != rhead) {
            out[i * 2] = ring[rtail * 2];
            out[i * 2 + 1] = ring[rtail * 2 + 1];
            rtail = (rtail + 1) & (RING - 1);
        } else {
            out[i * 2] = out[i * 2 + 1] = 0;
        }
    }
    buf->mAudioDataByteSize = frames * 4;
    AudioQueueEnqueueBuffer(q, buf, 0, NULL);
}

static void start_audio(double rate) {
    AudioStreamBasicDescription f = {0};
    f.mSampleRate = rate;
    f.mFormatID = kAudioFormatLinearPCM;
    f.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    f.mChannelsPerFrame = 2;
    f.mBitsPerChannel = 16;
    f.mBytesPerFrame = 4;
    f.mFramesPerPacket = 1;
    f.mBytesPerPacket = 4;
    OSStatus st = AudioQueueNewOutput(&f, aq_callback, NULL, NULL, NULL, 0, &queue);
    fprintf(stderr, "audio: new=%d\n", (int)st);
    if (st != noErr) return;
    for (int i = 0; i < 3; i++) {
        AudioQueueBufferRef b;
        AudioQueueAllocateBuffer(queue, 1024 * 4, &b);
        memset(b->mAudioData, 0, 1024 * 4);
        b->mAudioDataByteSize = 1024 * 4;
        AudioQueueEnqueueBuffer(queue, b, 0, NULL);
    }
    fprintf(stderr, "audio: start=%d\n", (int)AudioQueueStart(queue, NULL));
}

static void poll_cb(void) {}

// game controllers: first two connected pads -> ports 0, 1 (OR'd with keyboard)
static int pad_bit(unsigned port, unsigned id) {
    NSArray<GCController *> *cs = [GCController controllers];
    if (port >= cs.count) return 0;
    GCExtendedGamepad *g = cs[port].extendedGamepad;
    if (!g) return 0;
    switch (id) {
    case RETRO_DEVICE_ID_JOYPAD_UP:     return g.dpad.up.pressed || g.leftThumbstick.yAxis.value > 0.5;
    case RETRO_DEVICE_ID_JOYPAD_DOWN:   return g.dpad.down.pressed || g.leftThumbstick.yAxis.value < -0.5;
    case RETRO_DEVICE_ID_JOYPAD_LEFT:   return g.dpad.left.pressed || g.leftThumbstick.xAxis.value < -0.5;
    case RETRO_DEVICE_ID_JOYPAD_RIGHT:  return g.dpad.right.pressed || g.leftThumbstick.xAxis.value > 0.5;
    case RETRO_DEVICE_ID_JOYPAD_A:      return g.buttonB.pressed;   // SNES layout: right face = A
    case RETRO_DEVICE_ID_JOYPAD_B:      return g.buttonA.pressed;   // bottom face = B
    case RETRO_DEVICE_ID_JOYPAD_X:      return g.buttonY.pressed;
    case RETRO_DEVICE_ID_JOYPAD_Y:      return g.buttonX.pressed;
    case RETRO_DEVICE_ID_JOYPAD_L:      return g.leftShoulder.pressed;
    case RETRO_DEVICE_ID_JOYPAD_R:      return g.rightShoulder.pressed;
    case RETRO_DEVICE_ID_JOYPAD_START:  return g.buttonMenu.pressed;
    case RETRO_DEVICE_ID_JOYPAD_SELECT: return g.buttonOptions ? g.buttonOptions.pressed : 0;
    }
    return 0;
}

static int16_t state_cb(unsigned port, unsigned device, unsigned index, unsigned id) {
    if (port > 1 || device != RETRO_DEVICE_JOYPAD || id >= 16) return 0;
    return (keys[port][id] || pad_bit(port, id)) ? 1 : 0;
}

static int key_to_id(unsigned short code, NSString *chars) {
    switch (code) {
    case 126: return RETRO_DEVICE_ID_JOYPAD_UP;
    case 125: return RETRO_DEVICE_ID_JOYPAD_DOWN;
    case 123: return RETRO_DEVICE_ID_JOYPAD_LEFT;
    case 124: return RETRO_DEVICE_ID_JOYPAD_RIGHT;
    case 36:  return RETRO_DEVICE_ID_JOYPAD_START;    // return
    case 76:  return RETRO_DEVICE_ID_JOYPAD_START;    // keypad enter
    case 48:  return RETRO_DEVICE_ID_JOYPAD_SELECT;   // tab
    case 60:  return RETRO_DEVICE_ID_JOYPAD_SELECT;   // right shift
    }
    // the game's prompts say A and B, so those keys are A and B
    NSString *c = chars.lowercaseString;
    if ([c isEqualToString:@"a"] || [c isEqualToString:@"x"] || [c isEqualToString:@" "])
        return RETRO_DEVICE_ID_JOYPAD_A;
    if ([c isEqualToString:@"b"] || [c isEqualToString:@"z"]) return RETRO_DEVICE_ID_JOYPAD_B;
    if ([c isEqualToString:@"s"]) return RETRO_DEVICE_ID_JOYPAD_X;
    if ([c isEqualToString:@"y"]) return RETRO_DEVICE_ID_JOYPAD_Y;
    if ([c isEqualToString:@"q"]) return RETRO_DEVICE_ID_JOYPAD_L;
    if ([c isEqualToString:@"w"]) return RETRO_DEVICE_ID_JOYPAD_R;
    return -1;
}

static void save_srm(void) {
    if (!r_get_mem || !srmPath) return;
    void *m = r_get_mem(RETRO_MEMORY_SAVE_RAM);
    size_t n = r_get_mem_size(RETRO_MEMORY_SAVE_RAM);
    if (m && n) [[NSData dataWithBytes:m length:n] writeToFile:srmPath atomically:YES];
}

// ---- view ----
@interface GameView : NSView
@end

@implementation GameView
- (BOOL)acceptsFirstResponder { return YES; }
- (BOOL)isFlipped { return YES; }
- (void)drawRect:(NSRect)r {
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef bc = CGBitmapContextCreate(fb, fbw, fbh, 8, fbw * 4, cs,
                                            kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGImageRef img = CGBitmapContextCreateImage(bc);
    CGContextRef ctx = [[NSGraphicsContext currentContext] CGContext];
    CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);
    // keep the 8:7 picture centred and pixel-crisp in any window size
    NSRect b = self.bounds;
    double s = MIN(b.size.width / fbw, b.size.height / fbh);
    double w = fbw * s, h = fbh * s;
    CGContextSetFillColorWithColor(ctx, CGColorGetConstantColor(kCGColorBlack));
    CGContextFillRect(ctx, b);
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, (b.size.width - w) / 2, (b.size.height - h) / 2 + h);
    CGContextScaleCTM(ctx, 1, -1);
    CGContextDrawImage(ctx, CGRectMake(0, 0, w, h), img);
    CGContextRestoreGState(ctx);
    CGImageRelease(img);
    CGContextRelease(bc);
    CGColorSpaceRelease(cs);
}
- (void)setKey:(NSEvent *)e down:(int)d {
    if (e.keyCode == 53 && d) { save_srm(); [NSApp terminate:nil]; return; }
    int id = key_to_id(e.keyCode, e.charactersIgnoringModifiers);
    if (id >= 0) keys[0][id] = d;
}
- (void)keyDown:(NSEvent *)e { if (!e.isARepeat) [self setKey:e down:1]; }
- (void)keyUp:(NSEvent *)e { [self setKey:e down:0]; }
- (void)flagsChanged:(NSEvent *)e {
    if (e.keyCode == 60) keys[0][RETRO_DEVICE_ID_JOYPAD_SELECT] = (e.modifierFlags & NSEventModifierFlagShift) != 0;
}
@end

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>
@property (strong) NSWindow *window;
@property (strong) GameView *view;
@end

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)n {
    NSRect frame = NSMakeRect(0, 0, 256 * 3, 224 * 3);
    self.window = [[NSWindow alloc] initWithContentRect:frame
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable
        backing:NSBackingStoreBuffered defer:NO];
    self.window.title = @"Toronto Games";
    self.window.delegate = self;
    self.window.contentAspectRatio = NSMakeSize(256, 224);
    self.view = [[GameView alloc] initWithFrame:frame];
    self.window.contentView = self.view;
    [self.window center];
    [self.window makeKeyAndOrderFront:nil];
    [self.window makeFirstResponder:self.view];
    [NSApp activateIgnoringOtherApps:YES];
    // 60 fps emulation tick
    NSTimer *t = [NSTimer timerWithTimeInterval:1.0 / 60.0 repeats:YES block:^(NSTimer *tm) {
        // keep audio latency in check: skip a frame if the buffer runs long
        uint32_t queued = (rhead - rtail) & (RING - 1);
        if (queued < 32040 / 4) r_run();
        if (queued < 1600) r_run();          // catch up when starving
        [self.view setNeedsDisplay:YES];
    }];
    [[NSRunLoop currentRunLoop] addTimer:t forMode:NSRunLoopCommonModes];
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)a { return YES; }
- (void)applicationWillTerminate:(NSNotification *)n { save_srm(); }
@end

#define LOAD(var, name) var = dlsym(h, name); if (!var) { fprintf(stderr, "missing %s\n", name); return 1; }

int main(int argc, char **argv) {
    @autoreleasepool {
        NSString *corePath, *romArg;
        if (argc >= 3) {
            corePath = [NSString stringWithUTF8String:argv[1]];
            romArg = [NSString stringWithUTF8String:argv[2]];
        } else {
            NSBundle *b = [NSBundle mainBundle];
            corePath = [b pathForResource:@"snes9x_libretro" ofType:@"dylib"];
            romArg = [b pathForResource:@"toronto_games" ofType:@"sfc"];
            if (!corePath || !romArg) { fprintf(stderr, "usage: player core.dylib rom.sfc\n"); return 1; }
        }
        void *h = dlopen(corePath.fileSystemRepresentation, RTLD_NOW);
        if (!h) { fprintf(stderr, "%s\n", dlerror()); return 1; }
        LOAD(r_init, "retro_init") LOAD(r_deinit, "retro_deinit") LOAD(r_run, "retro_run")
        LOAD(r_load_game, "retro_load_game") LOAD(r_unload_game, "retro_unload_game")
        LOAD(r_set_environment, "retro_set_environment") LOAD(r_set_video, "retro_set_video_refresh")
        LOAD(r_set_audio, "retro_set_audio_sample") LOAD(r_set_audio_batch, "retro_set_audio_sample_batch")
        LOAD(r_set_poll, "retro_set_input_poll") LOAD(r_set_state, "retro_set_input_state")
        LOAD(r_get_av, "retro_get_system_av_info") LOAD(r_get_mem, "retro_get_memory_data")
        LOAD(r_get_mem_size, "retro_get_memory_size") LOAD(r_set_controller, "retro_set_controller_port_device")

        r_set_environment(env_cb);
        r_init();
        r_set_video(video_cb);
        r_set_audio(audio_cb);
        r_set_audio_batch(audio_batch_cb);
        r_set_poll(poll_cb);
        r_set_state(state_cb);

        NSString *romPath = romArg;
        NSData *rom = [NSData dataWithContentsOfFile:romPath];
        if (!rom) { fprintf(stderr, "can't read %s\n", romPath.UTF8String); return 1; }
        struct retro_game_info gi = { romPath.fileSystemRepresentation, rom.bytes, rom.length, NULL };
        if (!r_load_game(&gi)) { fprintf(stderr, "core refused the ROM\n"); return 1; }
        r_set_controller(0, RETRO_DEVICE_JOYPAD);
        r_set_controller(1, RETRO_DEVICE_JOYPAD);

        // battery save next to the ROM
        srmPath = [[romPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"srm"];
        if (argc < 3) {
            NSString *dir = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/Toronto Games"];
            [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
            srmPath = [dir stringByAppendingPathComponent:@"toronto_games.srm"];
        }
        NSData *srm = [NSData dataWithContentsOfFile:srmPath];
        void *m = r_get_mem(RETRO_MEMORY_SAVE_RAM);
        size_t n = r_get_mem_size(RETRO_MEMORY_SAVE_RAM);
        if (srm && m && n) memcpy(m, srm.bytes, MIN(n, srm.length));

        struct retro_system_av_info av;
        r_get_av(&av);
        start_audio(av.timing.sample_rate > 0 ? av.timing.sample_rate : 32040.5);

        NSApplication *app = [NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        // minimal menu so Cmd-Q works
        NSMenu *bar = [NSMenu new];
        NSMenuItem *appItem = [NSMenuItem new];
        [bar addItem:appItem];
        NSMenu *appMenu = [NSMenu new];
        [appMenu addItemWithTitle:@"Quit Toronto Games" action:@selector(terminate:) keyEquivalent:@"q"];
        appItem.submenu = appMenu;
        app.mainMenu = bar;
        AppDelegate *d = [AppDelegate new];
        app.delegate = d;
        [app run];
    }
    return 0;
}
