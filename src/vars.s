; Storage for the globals declared in globals.inc
.p816
.smart -
.include "globals.inc"

.segment "ZEROPAGE"
tmp0:       .res 2
tmp1:       .res 2
tmp2:       .res 2
tmp3:       .res 2
tmp4:       .res 2
tmp5:       .res 2
tmp6:       .res 2
tmp7:       .res 2
ptr0:       .res 3
ptr1:       .res 3
ptr2:       .res 3
frame:      .res 2
nmi_ready:  .res 1
lag:        .res 1
pad:        .res 2      ; pad1 | pad2, held
pad_prev:   .res 2
pad_new:    .res 2      ; newly pressed this frame
pad1:       .res 2
pad2:       .res 2
rng:        .res 2
inidisp_sh: .res 1
tm_sh:      .res 1
ts_sh:      .res 1
hdma_sh:    .res 1
cgwsel_sh:  .res 1
cgadsub_sh: .res 1
mosaic_sh:  .res 1
bg1x:       .res 2
bg1y:       .res 2
bg2x:       .res 2
bg2y:       .res 2
bg3x:       .res 2
bg3y:       .res 2
txt_dirty:  .res 1
pal_dirty:  .res 1
dmaq_len:   .res 2      ; bytes used in dmaq
oam_idx:    .res 2      ; next free OAM slot * 4
music_on:   .res 1
txt_bg:     .res 1      ; 0 = plain text, 128 = text on window fill
spr_x:      .res 2      ; oam_put / oam_meta inputs
spr_y:      .res 2
spr_tile:   .res 2
spr_attr:   .res 1
spr_size:   .res 1

.segment "BSS"
oam_buf:    .res 512
oam_hi:     .res 32
txt_map:    .res 2048
pal_buf:    .res 512
dmaq:       .res 8*24   ; vram(2) src(3) len(2) vmain(1)

players:    .res PL_SIZE * MAX_PLAYERS
num_players:.res 1
cur_player: .res 1
game_mode:  .res 1
event_on:   .res NUM_EVENTS     ; 1 = event is in this competition
event_idx:  .res 1
; The turn's result, read by score_card (cards.s). game.s clears ev_fail,
; ev_break and ev_giveup before every turn.
ev_score:   .res 2
; ev_fail: 0 finished, 1 the event's own fail line (cards.s ev_fails),
; 2 out of time, 3 gave up, 4 the event's second fail line (ev_fails2, e.g.
; the bike's idle kick: YOU'RE FIRED!). The event sets it; the card never
; second-guesses it.
ev_fail:    .res 1
ev_stat:    .res 8              ; up to 4 words of per-event stats for the result card
ev_style:   .res 10             ; up to 5 style sources, points each (0 = none), summing to ev_break+2 on a finish; labels in cards.s
ev_break:   .res 6              ; result card arithmetic: base, bonus, penalty words (base + bonus - penalty = ev_score)
; ev_giveup: set by the pause menu (CALL IT A DAY). Every event loop checks
; it each frame and ends with ev_fail 3, scored exactly like a failed run
; (the event's own fail formula for what was done so far: never a bonus for
; quitting, never less than failing would have scored). An event whose run
; is already over (end condition met, or the finish/fail animation playing)
; ignores it and reports the real result.
ev_giveup:  .res 1
records:    .res 16 * NUM_EVENTS * 5 ; top 5 per event, rank-major: score(2) name(9) pad(5)
ev_ram:     .res EV_RAM_SIZE    ; scratch shared by whichever screen is running
pause_ok:   .res 1              ; 1 = START pauses (event play: countdown to score card)
; attract demo: demo_on 0 off, 1 playing a recorded stream, 2 recording
demo_on:    .res 1
demo_off:   .res 2              ; byte offset in demo_blob (or in the $7F log)
demo_left:  .res 2              ; frames left in the current run
demo_mask:  .res 2              ; buttons held in the current run
demo_real:  .res 2              ; real buttons held last frame
demo_sp:    .res 2              ; stack pointer to unwind to
demo_ev:    .res 1              ; next event in the demo rotation
demo_force: .res 1              ; harness hook: 1 play a demo, 2 record one
