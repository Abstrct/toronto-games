; EVENT 2: BAY ST POWER WALK — side view, rush hour.
;  Step LEFT/RIGHT on the beat of the music to stride, UP/DOWN (or X/B) to
; change lanes, A to say "EXCUSE ME!", Y on the gold bar-line beat for a
; PRESTO TAP. Reach Union before the 5:42 GO train.
;
; Rhythm: the song runs at 15 frames per 8th note (16ths alternate 8,7) and
; is sequenced on this CPU once per main-loop pass, so w_ph (0..14) is locked
; to it: w_ph = 0 is the frame an 8th note keys on, and the frame the dot
; visibly lands in the target (the sprites drawn a pass earlier go up in
; this frame's vblank). Every 8th is a "slot" (w_ph 9..14 and 0 belong to
; the coming 8th, 1..8 to the one just played). A press read in the landing
; frame scores -1, the next frame 0: PERFECT is -3..+2, GOOD -5..+4, so the
; landing frame and the one after are both dead centre. 6-7 out is
; EARLY/LATE: a short stride, never a dead stop.
;  The walk is on the BEAT (the big dots, every quarter note: 2 steps a
; second, a brisk walk). A beat is only missed when neither its 8th nor the
; "and" after it got a step, so a walker a little late, or one who steps on
; the "and" all along, still walks; a step on the "and" alone is graded from
; the nearer big dot (half a beat LATE or EARLY), never as a PERFECT on the
; small dot, so a hand a whole 8th behind never out-scores a quicker one.
; The target lights as each big dot lands (8 frames), and only then.
; DOUBLE TIME: a good step on the beat and another on the small dot after it
; (8 steps every 2 s) is a longer stride and twice the PERFECTs (booked to
; its own row): that is the expert's walk. Trying it is free: a loose small
; dot after a good big one only drops you to single time.
; Consecutive good beats build the GROOVE (speed); 4 taps inside 19 frames
; is a mash and trips you.
; Style: unbroken GOOD-or-better steps build the POWER WALK combo (a level
; every 10, x2..x8); every PERFECT scores the level, half again DEAD ON (the
; beat's two centre frames). Anything sloppy, a bump, a double step or an
; "EXCUSE ME!" breaks it, so weaving through lanes beats asking.
; Lanes: everybody ahead in your lane inside WARN_PX, or WARN_T frames of
; closing in, gets a red !, and a white arrow by your chest points to the
; lane that's clear (an A when there's none but they can hear you: anyone
; under a red ! does). Leaving a lane under a red ! is a DODGE (20); leaving
; it in the last moments before you'd walk into them is CUT IT FINE (25).
; A bump in the lane you just moved into on a red ! is only a brush (no
; spill). PRESTO TAP (Y on a bar's downbeat, PERFECT) adds 5 x level and
; pushes the combo; a Y anywhere else is CARD DECLINED. EXCUSE ME with no
; red ! in your lane stops you dead for a beat (nobody to ask).
; A bump knocks you off your stride (DOUBLE TIME: stops you dead); every bump
; but the first spills coffee (40) and stops you dead to mop up (SPILL_T),
; so walking into people costs the train, not just points; they step aside.
; The cup holds four spills; then it's DECAF: no DOUBLE TIME for the rest of
; the walk, and every bump spills somebody else's latte (still 40, still a
; stop). A steady walk that lands off the dots still strides (a rhythm of
; your own), and the coach says which way to move. Out of time within sight
; of Union, the doors are held a few seconds.
;  Undocumented: CUT IT FINEs inside SLALOM_T of each other are a SLALOM
; (X2, X3, X4 the cut). While one is open, whoever a lane over you could
; fall in behind wears a gold ring; once someone in your way is in reach, a
; gold burst ! goes up over them with a beep and the arrow turns gold,
; TELL_T frames before cutting past them counts (cut_window).
.p816
.smart -
.include "globals.inc"
.include "screens.inc"

.import bay_tiles, bay_bg1, bay_bg2, bay_pal, bay_spr, bay_spr_pal, bay_sky
.import trick_seen          ; boot.s: the attract demo's WATCH THAT MOVE! cue

PLAYER_SX  = 72
COURSE_LEN = 3600           ; keep in step with tools/art_bay.py
STRIP_COLS = 496            ; facade columns streamed into BG1 (3968 px)
UNION_C0   = 3520           ; where Union's colonnade starts
TRAIN_Y    = 80
BOARD_X    = 184            ; screen x of the opening the walker climbs through
TRAIN_TAIL = 3536           ; world x of the train's last car (4 coaches + engine)
TRAIN_LEN  = 320
TRAIN_FLOOR= TRAIN_Y + 30   ; where the climbing walker's feet reach the door
TIME_LIMIT = 60*60
BEAT       = 15             ; frames per 8th note
ACCEL      = $0010          ; speed approach per frame (8.8 px/frame)
DECEL      = $0008
SPD_OFF    = $00F0          ; EARLY / LATE: a short stride
SPD_STUT   = $0080          ; a double step
SPD_STEADY = $0118          ; a steady EARLY / LATE walk (a rhythm of your own)
SPD_GOOD   = $0128
SPD_PERF   = $0130
SPD_DT     = $0040          ; DOUBLE TIME: the longer stride on top
GROOVE_MAX = 8              ; streak cap; each step of streak adds 7/256 px/frame
DECAF_MAX  = 8              ; DECAF's groove cap (none: no DOUBLE TIME is the cost)
SPILL_SIPS = 4              ; a spill: one cell of the cup's four
BUMP_T     = 12             ; frames a bump knocks you off your stride
BUMP_DT    = 24             ; ... and stops you dead in DOUBLE TIME
BUMP_N     = 2              ; notches of groove a bump costs
BUMP_NDT   = 4              ; ... rushing in DOUBLE TIME
SPILL_T    = 40             ; frames a spill stops you dead (every bump but the first)
DOORS_T    = 10*60          ; "doors closing" with this many frames left

ST_WALK    = 0
ST_STUMBLE = 1
ST_FINISH  = 2
ST_DONE    = 3

G_NONE    = 0
G_OFF     = 1
G_GOOD    = 2
G_PERFECT = 3
G_EARLY   = 4
G_LATE    = 5
G_MISS    = 6
G_DEADON  = 7               ; a PERFECT step dead on the beat (display / style)

w_dist   = ev_ram + 0
w_distf  = ev_ram + 2
w_speed  = ev_ram + 4
w_lane   = ev_ram + 6
w_y      = ev_ram + 8
w_last   = ev_ram + 10          ; last foot: 2 left, 1 right, 0 none
w_anim   = ev_ram + 12
w_state  = ev_ram + 14
w_timer  = ev_ram + 16
w_time   = ev_ram + 18
w_coffee = ev_ram + 20
w_passed = ev_ram + 22
w_spills = ev_ram + 24
w_cd     = ev_ram + 26
w_popup  = ev_ram + 28
w_nextsp = ev_ram + 30
w_cur    = ev_ram + 32
w_splash = ev_ram + 34
w_made   = ev_ram + 36
w_dlane  = ev_ram + 38
w_pose   = ev_ram + 40
w_ph     = ev_ram + 42          ; beat phase 0..14 (0 = an 8th note sounds)
w_beat   = ev_ram + 44          ; 8th-note counter (even = quarter beat)
w_target = ev_ram + 46          ; stride speed the walker eases toward
w_streak = ev_ram + 48
w_sbest  = ev_ram + 50          ; best grade in the current slot
w_staps  = ev_ram + 52          ; taps in the current slot
w_sd     = ev_ram + 54          ; signed offset of the slot's best step
w_grade  = ev_ram + 56          ; grade word on show
w_gradet = ev_ram + 58
w_perfect= ev_ram + 60          ; PERFECT steps (word)
w_since  = ev_ram + 62          ; frames since the last step

NUM_ENT = 20
E_TYPE  = ev_ram + 64
E_WX    = E_TYPE + NUM_ENT*2
E_WXF   = E_WX + NUM_ENT*2
E_V     = E_WXF + NUM_ENT*2
E_LANE  = E_V + NUM_ENT*2
E_LY    = E_LANE + NUM_ENT*2
E_TIMER = E_LY + NUM_ENT*2
E_PAL   = E_TIMER + NUM_ENT*2
E_FLAGS = E_PAL + NUM_ENT*2     ; 1 passed, 2 fresh, 4 bumped us, 8 stepped aside
E_REL   = E_FLAGS + NUM_ENT*2
E_STATE = E_REL + NUM_ENT*2
EV_SEED  = ev_ram + 510

w_decaf  = ev_ram + 512         ; coffee ran out
w_groove = ev_ram + 516         ; "POWER WALK!" shown for this streak
r_seg    = ev_ram + 520         ; course RNG draws for one segment
r_lane   = ev_ram + 521
r_v      = ev_ram + 522
r_t      = ev_ram + 523
r_gap    = ev_ram + 524
d_f      = ev_ram + 526         ; draw_beat: frames to a tick, its 8th index
d_b      = ev_ram + 527
w_oamlast= ev_ram + 528         ; OAM bytes used last frame
w_clock  = ev_ram + 530         ; frames (for the mash check)
w_tap1   = ev_ram + 532         ; frame stamps of the last three taps
w_tap2   = ev_ram + 534
w_tap3   = ev_ram + 536
w_col    = ev_ram + 538         ; next facade column to stream
w_px     = ev_ram + 540         ; walker's screen x (moves only at the finish)
w_pxf    = ev_ram + 542
w_trx    = ev_ram + 544         ; GO train: world x of a coach start
w_trxf   = ev_ram + 546
w_trv    = ev_ram + 548         ; its speed (8.8), 0 = at the platform
w_hide   = ev_ram + 550         ; walker has boarded
w_trgo   = ev_ram + 552         ; frames until the train pulls out
h_sec    = ev_ram + 554         ; HUD: last values printed ($FF = reprint)
h_pass   = ev_ram + 556
h_cof    = ev_ram + 558
h_prog   = ev_ram + 560
w_combo  = ev_ram + 562         ; unbroken PERFECT steps (POWER WALK combo)
w_level  = ev_ram + 563         ; combo level 1..5
w_style  = ev_ram + 564         ; style points (word)
w_presto = ev_ram + 566         ; PRESTO taps (word)
w_ybar   = ev_ram + 568         ; bar of the last Y tap + 1
w_quit   = ev_ram + 569         ; gave up from the pause menu
h_grv    = ev_ram + 570         ; HUD: groove / combo / pace last printed
h_lvl    = ev_ram + 571
h_par    = ev_ram + 572
w_board  = ev_ram + 573         ; at Union: 0 stroll, 1 climb
w_pri    = ev_ram + 574         ; walker sprite priority bits
h_cells  = ev_ram + 576         ; HUD: the 20 progress cells on show (20 bytes)
p_msg    = ev_ram + 596         ; popup waiting to be printed (one a frame)
p_pal    = ev_ram + 598
w_hitd   = ev_ram + 600         ; signed frames off the beat of the last step
w_hitt   = ev_ram + 601         ; frames its mark stays on the strip
w_tips   = ev_ram + 602         ; coaching tips already given (bits)
w_tipt   = ev_ram + 603         ; frames until the queued tip shows
w_tipm   = ev_ram + 604         ; the queued tip
w_sloppy = ev_ram + 606         ; EARLY / LATE / MISS so far
w_immov  = ev_ram + 607         ; EXCUSE ME at a cart or board
w_warn   = ev_ram + 608         ; slot of the next one in your way ($FFFF none)
w_warnr  = ev_ram + 610         ; ... how far ahead
w_jogw   = ev_ram + 612         ; slot of a jogger coming up behind you
w_jogr   = ev_ram + 614         ; ... how far back (negative)
w_bgrade = ev_ram + 616         ; grade of this beat's own 8th (0 none)
w_dt     = ev_ram + 617         ; DOUBLE TIME: stepping every 8th
w_dtn    = ev_ram + 618         ; double-time steps (word)
w_deadon = ev_ram + 620         ; this step was DEAD ON (the beat's centre frames)
w_shaves = ev_ram + 621         ; CUT IT FINEs (byte)
w_bumps  = ev_ram + 622         ; bumps, spilt or not (byte)
w_same   = ev_ram + 623         ; this step was the same foot again
w_msg    = ev_ram + 624         ; a popup with points in it (32 bytes: 30
                                ; characters at most; low WRAM, so bank $82
                                ; reads it through the mirror)
w_slalom = ev_ram + 656         ; CUT IT FINEs in a row (SLALOM), 0..4
w_slt    = ev_ram + 657         ; frames the chain stays open
w_dodges = ev_ram + 658         ; early dodges (a red ! far ahead)
w_slaloms= ev_ram + 659         ; SLALOMs (X2 or better)
w_sidet  = ev_ram + 660         ; after walking into a cart or a board: frames
                                ; until you step round it into the middle lane
w_adv    = ev_ram + 661         ; the lane arrow: 0 none, 1 up, 2 down
w_dodn   = ev_ram + 662         ; DODGEs on this lane change
w_room   = ev_ram + 664         ; lane_room: px free ahead in a lane (0 blocked)
w_roomu  = ev_ram + 666         ; ... the lane above, the lane below
w_roomd  = ev_ram + 668
w_advl   = ev_ram + 670         ; ... the lane it points to ($FF none)
w_atip   = ev_ram + 671         ; the A prompt has been explained
w_lchg   = ev_ram + 672         ; frames left of a lane change made on a red !
                                ; (a bump in the new lane meanwhile: a brush)
w_brush  = ev_ram + 673         ; brushes (byte)
w_soff   = ev_ram + 674         ; signed frames off of the last step
w_steady = ev_ram + 675         ; steps in a row landing as the one before (+-2)
w_stok   = ev_ram + 676         ; this slot's off step is a steady one: full stride
w_srun   = ev_ram + 677         ; LATE (+) / EARLY (-) steps in a row
w_scoach = ev_ram + 678         ; frames until the timing coach may speak again
w_scn    = ev_ram + 679         ; ... times it has spoken
w_ssrc   = ev_ram + 680         ; style_add: which source (0, 2, 4, 6, 8)
s_src    = ev_ram + 682         ; style by source, 5 words (ev_style on the card):
                                ; PERFECT steps, DOUBLE TIME, CUT IT FINE and
                                ; DODGE, PRESTO, the chain's extra
w_hold   = ev_ram + 692         ; frames the 5:42's doors are still held (word)
w_held   = ev_ram + 694         ; the doors were held for you
w_cutw   = ev_ram + 696         ; slot of the nearest one in your lane you could
                                ; cut it fine past right now ($FFFF none)
w_rawu   = ev_ram + 698         ; lane_advice: room above / below as found
w_rawd   = ev_ram + 700
w_cwt    = ev_ram + 703         ; w_cutw's gold !: frames until cutting past
                                ; them counts (0: the window is open)

T_SUIT    = 1
T_TOURIST = 2
T_ZOMBIE  = 3
T_JOGGER  = 4
T_PIGEON  = 5
T_CART    = 6
T_BOARD   = 7

.segment "EVENTS1"
.a8
.i16

ev_bay:
    phb
    phk
    plb
    jsr bay_init
    jsr bay_draw
    jsl event_card
    jsr hud_clock
    jsr hud_passed
    jsr hud_coffee
    PRINT 1, 3, TP_WHITE, str_king
    PRINT 26, 3, TP_YELLOW, str_union
    PRINT 21, 25, TP_WHITE, str_grvl
    jsr hud_progress
    jsr hud_groove
    jsl event_countdown
    lda #SONG_BAY
    jsl music_play
@loop:
    jsl wait_frame
    jsr bay_update
    jsr popup_flush
    jsr bay_stream
    jsr bay_draw
    jsr bay_hud
    lda ev_giveup               ; pause menu: GIVE UP ends the run now
    beq @on
    lda w_state                 ; the train already came (made it or
    cmp #ST_FINISH              ; missed it): that result stands
    bcs @end
    lda #$01
    sta w_quit                  ; scored as a missed train, ev_fail 3
@end:
    lda #ST_DONE
    sta w_state
@on:
    lda w_state
    cmp #ST_DONE
    bne @loop
    jsl music_stop
    jsr bay_score
    jsr hud_off
    jsl score_card
    jsl hdma_off
    plb
    rtl

.include "evcommon.inc"

; before the result card: blank the HUD rows that would peek out beside and
; under it (KING / the progress bar / UNION, GROOVE and the combo)
hud_off:
    ldx #(3*32)
    lda #1
    jsr @rows
    ldx #(25*32)
    lda #2
@rows:
    sta tmp1+1
    lda #32
    sta tmp1
    stz tmp2
    lda #$20
    jsl txt_fill
    rts


bay_init:
    jsl ppu_off
    jsl set_mode1_defaults
    jsl load_text_gfx
    VLOAD VRAM_BGTILES, bay_tiles, (bay_bg1 - bay_tiles)
    VLOAD VRAM_BG1MAP, bay_bg1, 4096
    VLOAD VRAM_BG2MAP, bay_bg2, 4096
    PLOAD 32, bay_pal, 96
    VLOAD VRAM_OBJTILES, bay_spr, (bay_spr_pal - bay_spr)
    PLOAD 144, bay_spr_pal, 80
    lda cur_player
    ldy #$0000
    jsl player_palette
    lda #$17
    sta tm_sh
    stz txt_bg
    LDPTR0 bay_sky
    jsr ev_sky
    jsr ev_clear
    lda #1
    sta w_lane
    ldx #168
    stx w_y
    ldx #TIME_LIMIT
    stx w_time
    ldx #(4*SPILL_SIPS)
    stx w_coffee
    ldx #$5A17
    stx EV_SEED
    ldx #100
    stx w_nextsp
    lda #$FF
    sta w_since
    ldx #1000
    stx w_clock
    ldx #64
    stx w_col
    ldx #PLAYER_SX
    stx w_px
    ldx #TRAIN_TAIL
    stx w_trx
    lda #1
    sta w_level
    lda #$30
    sta w_pri
    ldx #$FFFF
    stx w_warn                  ; nobody in the way yet (no stray '!' on
    stx w_jogw                  ; the intro card), no gold ! either
    stx w_cutw
    stx h_sec
    stx h_pass
    stx h_cof
    stx h_prog
    stx h_grv                   ; and h_lvl
    lda #$FF
    sta h_par
    sta w_advl                  ; no lane arrow yet
    ldx #19
@hc:
    sta h_cells,x
    dex
    bpl @hc
    jsr spawn_ahead
    rts

; ------------------------------------------------------------------
bay_update:
    lda w_state
    cmp #ST_FINISH
    bcc @play
    jmp finish_update
@play:
    jsr beat_slot
    lda w_state
    cmp #ST_WALK
    bne @stumble
    jsr input_steps
    jsr input_excuse
    jsr input_presto
    bra @lanes
@stumble:
    jsr stumble_step
    A16
    dec w_timer
    A8
    bne @lanes
    lda #ST_WALK
    sta w_state
    stz w_last
    stz w_staps
@lanes:
    jsr input_lane
    jsr approach_speed
    jsr move_player
    jsr tick_timers
    jsr check_clock
    jsr spawn_ahead
    jsr ents_update
    jmp beat_advance

; knocked off your stride: a step still lands (no MISS for a beat you
; stepped through a bump), it just isn't judged
stumble_step:
    lda pad_new+1
    and #$03
    beq @x
    cmp #$03
    beq @x
    sta w_last
    stz w_since
    SFX SFX_STEP
@x:
    rts

; after the whistle. Made it: the camera stops at Union, the walker heads
; for an opening in the colonnade, climbs the steps to the coach door and
; the GO train pulls out with them. Missed it: the train goes without you.
finish_update:
    A16
    stz w_speed
    A8
    lda w_made
    beq @tick
    lda w_hide
    bne @tick
    lda w_board
    bne @climb
    ; stroll to the opening
    A16
    lda w_pxf
    and #$00FF
    clc
    adc #$0160
    pha
    and #$00FF
    sta w_pxf
    pla
    xba
    and #$00FF
    clc
    adc w_px
    sta w_px
    cmp #BOARD_X
    A8
    bcc @tick
    ldx #BOARD_X
    stx w_px
    inc w_board
    lda #$20                    ; priority 2: behind the columns and steps
    sta w_pri
    bra @tick
@climb:
    A16
    dec w_y
    lda w_y
    cmp #TRAIN_FLOOR
    A8
    bcs @tick
    lda #$01
    sta w_hide
    SFX SFX_COIN
    ldx #.loword(str_aboard)
    lda #TP_GREEN
    ldy #120
    jsr popup
    lda #30
    sta w_trgo
@tick:
    jsr train_move
    A16
    dec w_timer
    A8
    bne @move
    lda #ST_DONE
    sta w_state
    rts
@move:
    lda w_board
    bne @still                  ; climbing: no lane easing
    jsr move_player
@still:
    jsr tick_timers
    jsr ents_update
    jmp beat_advance

str_aboard: .byte "ALL ABOARD! NEXT STOP: HOME", 0

; the train waits w_trgo frames once told to go, sounds the horn, pulls out
train_move:
    lda w_trgo
    beq @run
    dec w_trgo
    bne @x
    SFX SFX_HORN
    A16
    lda #$0010
    sta w_trv
    A8
@run:
    A16
    lda w_trv
    beq @x16
    cmp #$0400
    bcs @fast
    clc
    adc #$0006
    sta w_trv
@fast:
    lda w_trxf
    and #$00FF
    clc
    adc w_trv
    pha
    and #$00FF
    sta w_trxf
    pla
    xba
    and #$00FF
    clc
    adc w_trx
    sta w_trx
@x16:
    A8
@x:
    rts

beat_advance:
    A16
    inc w_clock
    A8
    lda w_since
    cmp #$FF
    beq @s
    inc w_since
@s:
    lda w_gradet
    beq @g
    dec w_gradet
@g:
    inc w_ph
    lda w_ph
    cmp #BEAT
    bcc @x
    stz w_ph
    inc w_beat
@x:
    rts

; close the slot when the phase passes the half-way point. The walk is
; judged a beat at a time: the beat's own 8th, then the "and" after it.
beat_slot:
    lda w_ph
    cmp #9
    beq @close
    rts
@close:
    lda w_state
    cmp #ST_WALK
    bne @off
    lda w_beat
    lsr a
    bcs @and                    ; odd: the "and" after a beat
    lda w_sbest                 ; the beat: grade it now, or (nothing yet)
    sta w_bgrade                ; wait and see if the step comes on the "and"
    beq @reset
    jsr slot_grade
    bra @reset
@and:
    lda w_sbest
    bne @astep
    stz w_dt                    ; nothing on the "and": single time again
    lda w_bgrade
    bne @reset0
    lda w_since                 ; nothing on the beat or after it: missed,
    cmp #34                     ; unless the step came early (within a beat
    bcc @reset0                 ; and a bit of now)
    jsr slot_miss
    bra @reset0
@astep:
    lda w_bgrade
    beq @late
    lda w_sbest                 ; double time: a good "and" was judged as it
    cmp #G_OFF                  ; landed; a sloppy one (or a double step)
    bne @reset0                 ; costs a notch like any sloppy step
@late:
    lda w_sbest
    jsr slot_grade              ; the beat's step, late or on the "and"
    bra @reset0
@off:
    stz w_dt
@reset0:
    stz w_bgrade
@reset:
    stz w_sbest
    stz w_staps
    rts

; a beat walked: A = its grade (G_OFF / G_GOOD / G_PERFECT); a steady off
; step builds the groove like a GOOD one
slot_grade:
    cmp #G_OFF
    bne @good
    lda w_stok
    beq @sloppy
@good:
    lda #GROOVE_MAX
    ldx w_decaf
    beq @cap
    lda #DECAF_MAX              ; DECAF: the groove's cap
@cap:
    sta tmp0
    lda w_streak
    cmp tmp0
    bcs @x
    inc w_streak
    lda w_streak
    cmp #GROOVE_MAX
    bne @x
    lda w_groove
    bne @x
    inc w_groove
    ldx #.loword(str_groove)
    lda #TP_GREEN
    ldy #50
    jsr popup
    lda w_stok                  ; (off the dots: the timing coach first)
    bne @x
    lda #TIP_DT                 ; the walk is easy now: show the expert's
    ldx #.loword(str_tdt)       ; way to go faster
    jmp tip
@sloppy:
    lda w_streak                ; a sloppy step costs a notch of groove
    beq @sl
    dec a
@sl:
    sta w_streak
    stz w_groove
@x:
    rts

; a beat skipped altogether
slot_miss:
    lda w_streak                ; a skipped beat costs three
    sec
    sbc #3
    bcs @ms
    lda #0
@ms:
    sta w_streak
    stz w_groove
    jsr combo_break
    A16
    lda w_target
    A8
    bne @was                    ; walking (or tried to): say so
    lda w_staps
    beq @x
@was:
    jsr sloppy_tip
    lda #G_MISS
    jsr show_grade
    A16
    lda w_target
    lsr a
    lsr a
    sta tmp0
    lda w_target
    sec
    sbc tmp0
    sta w_target
    A8
@x:
    rts

str_groove: .byte "IN THE GROOVE! FULL STRIDE", 0

; the third EARLY / LATE / MISS of the run: how the strip works
sloppy_tip:
    inc w_sloppy
    lda w_sloppy
    cmp #3
    bne @x
    ldx #.loword(str_tbeat)
    lda w_decaf                 ; walking DOUBLE TIME: how, not "stop it"
    bne @t
    lda w_dt
    ora w_dtn
    ora w_dtn+1
    beq @t
    ldx #.loword(str_tbdt)
@t:
    lda #TIP_BEAT
    jmp tip
@x:
    rts

; A = grade word to show
show_grade:
    sta w_grade
    lda #24
    sta w_gradet
    rts

; A = tip bit, X = tip: queue it once a run, after the current popup
; (not while another tip is waiting: that one keeps its turn). Keeps Y.
tip:
    bit w_tips
    bne @x
    pha
    lda w_tipt
    bne @busy
    pla
    ora w_tips
    sta w_tips
    stx w_tipm
    lda #64
    sta w_tipt
@x:
    rts
@busy:
    pla
    rts

TIP_LANE  = $01
TIP_BEAT  = $02
TIP_DT    = $04
TIP_SPILL = $08
TIP_PRESTO= $10
TIP_FOOT  = $20
TIP_LAST  = $40
TIP_SHAVE = $80
str_tlane: .byte "RED ! AHEAD? ", TXT_ARROW_U + $20, "/", TXT_ARROW_D + $20, " AS ARROW SAYS", 0
str_tasks: .byte "NO WAY ROUND? A: EXCUSE ME!", 0
str_tshave:.byte "DODGE LATER: CUT IT FINE +25", 0
str_tbeat: .byte "TIP: STEP AS BIG DOTS LAND", 0
str_tbdt:  .byte "DOUBLE TIME: EVERY DOT, ", TXT_ARROW_L + $20, TXT_ARROW_R + $20, TXT_ARROW_L + $20, TXT_ARROW_R + $20, 0
str_tdt:   .byte "SMALL DOTS TOO: DOUBLE TIME", 0
str_tspill:.byte "NEXT BUMP SPILLS: STOP, -40", 0
str_tlast: .byte "LAST SIP! 1 MORE SPILL: DECAF", 0
str_tpresto:.byte "Y ON GOLD DOTS: COMBO BOOST", 0
str_tfoot: .byte "OTHER FOOT! ", TXT_ARROW_L + $20, " ", TXT_ARROW_R + $20, " ", TXT_ARROW_L + $20, " ", TXT_ARROW_R + $20, 0
str_dt:    .byte "DOUBLE TIME!", 0

; X = message (this bank), A = text palette, Y = frames on show.
; Queued: popup_flush prints the last one asked for once a frame (a step,
; a combo banner and a PRESTO can all land on one beat).
popup:
    stx p_msg
    sty w_popup
    ora #$80                    ; pending
    sta p_pal
    rts

; Popups sit centred on row 9 inside a padded 3-row panel (as Tallboy's and
; Parking's), so they read over any facade. Two frames, the text first: the
; middle row with its words, then the rows above and below (never an empty
; box on screen; a busy frame near Union can't take all three rows and the
; text on top of the train and the crowd).
popup_flush:
    lda p_pal
    bmi @go
    asl a
    bmi @rims
    rts
@go:
    and #$3F
    ora #$40                    ; the rims next frame
    sta p_pal
    jsr @measure
    .a16
    ldx #(9*32*2)
    lda #($2000 | (TXT_BOX + 3))
    jsr @row
    A8
    lda p_pal
    and #$3F
    asl a
    asl a
    ora #$20
    ldx #(9*32)
    jsl txt_print_centre        ; (sets txt_dirty)
    stz txt_bg
    rts
@rims:
    lda p_pal
    and #$3F
    sta p_pal
    jsr @measure
    .a16
    ldx #(8*32*2)
    lda #($2000 | TXT_BOX)
    jsr @row
    ldx #(10*32*2)
    lda #($2000 | (TXT_BOX + 6))
    jsr @row
    A8
    lda #$01
    sta txt_dirty
    rts
; ptr0 = the message (txt_bg set for it); tmp5 / tmp6 / tmp7 = the panel's
; middle cells and the blanks left and right of it. Returns A16.
@measure:
    .a8
    ldx p_msg
    stx ptr0
    lda #^popup
    sta ptr0+2
    lda #TXT_WIN
    sta txt_bg
    ldy #$0000
@len:
    lda [ptr0],y
    beq @got
    iny
    bra @len
@got:
    tya
    clc
    adc #4                      ; width: the text and two cells a side,
    cmp #33                     ; one a side for the longest (30 at most)
    bcc @w
    lda #32
@w:
    sta tmp1
    lda #32
    sec
    sbc tmp1
    lsr a
    sta tmp3                    ; first column
    A16
    lda tmp1
    and #$00FF
    pha
    dec a
    dec a
    sta tmp5                    ; middle cells
    lda tmp3
    and #$00FF
    sta tmp6                    ; blanks on the left
    pla
    clc
    adc tmp6
    eor #$FFFF
    sec
    adc #32
    sta tmp7                    ; blanks on the right
    rts
@row:
    .a16
    sta tmp4
    lda #$2000
    ldy tmp6
    beq @l1
@l0:
    sta f:txt_map,x
    inx
    inx
    dey
    bne @l0
@l1:
    lda tmp4
    sta f:txt_map,x
    inx
    inx
    inc a
    ldy tmp5
    beq @m1
@m0:
    sta f:txt_map,x
    inx
    inx
    dey
    bne @m0
@m1:
    inc a
    sta f:txt_map,x
    inx
    inx
    lda #$2000
    ldy tmp7
    beq @r1
@r0:
    sta f:txt_map,x
    inx
    inx
    dey
    bne @r0
@r1:
    rts
    .a8

; blank the popup panel (rows 8-10)
popup_clear:
    ldx #(8*32)
    A16
    lda #$0320
    sta tmp1
    A8
    stz tmp2
    lda #$20
    jsl txt_fill
    rts

; tmp1 = signed frames from the nearest 8th (0: read the frame after the
; landing frame), A = how far off that is for grading: |tmp1|, one less on
; the early side, so the landing frame itself (-1) is dead centre too and
; PERFECT (A < 3) is -3..+2
beat_offset:
    lda w_ph
    dec a
    bpl @lat
    lda #(BEAT - 1)
@lat:
    cmp #8
    bcc @pos
    sec
    sbc #BEAT
@pos:
    sta tmp1
    ora #$00
    bpl @abs
    eor #$FF                    ; -d - 1 = |d| - 1
@abs:
    rts

; LEFT / RIGHT taps. The first alternating step of a slot sets the stride;
; a second one in the same 8th is a double step: a stutter off the beat. It
; breaks the combo and makes the slot sloppy (a short stride, groove down),
; so tapping faster than the music doesn't pay.
input_steps:
    lda pad_new+1               ; LEFT = $02, RIGHT = $01
    and #$03
    bne @tap
    rts
@tap:
    sta tmp0
    ; mashing: a 4th tap within 19 frames (over 12 a second) trips you
    A16
    lda w_clock
    sec
    sbc w_tap3
    cmp #19
    A8
    bcs @ok
    jmp trip
@ok:
    ldx w_tap2
    stx w_tap3
    ldx w_tap1
    stx w_tap2
    ldx w_clock
    stx w_tap1
    inc w_staps
    lda tmp0
    cmp #$03
    jeq @shuffle                ; both at once
    cmp w_last
    bne @alt
    lda #$01                    ; the same foot twice: a shuffle (a short
    bra @foot                   ; stride, never a good one)
@alt:
    lda #$00
@foot:
    sta w_same
    lda tmp0
    sta w_last
    stz w_since
    lda w_sbest
    beq @first
    jsr combo_break             ; double step
    stz w_dt
    stz w_stok
    lda w_sbest
    cmp #G_OFF
    jeq @step                   ; already sloppy
    lda #G_OFF
    sta w_sbest
    A16
    lda #SPD_STUT               ; a stutter: shorter than any stride, and
    sta w_target                ; it checks you a little on the spot
    lda w_speed
    lsr a
    lsr a
    sta tmp1
    lda w_speed
    sec
    sbc tmp1
    sta w_speed
    A8
    jsr beat_offset
    lda tmp1
    sta w_sd
    sta w_hitd
    lda #16
    sta w_hitt
    jmp @off
@first:
    jsr beat_offset
    sta tmp2                    ; how far off (0: dead on)
    ldy #G_PERFECT
    cmp #3
    bcc @g
    dey
    cmp #5
    bcc @g
    dey                         ; -6/-7, +5..+7: EARLY / LATE
@g:
    jsr off_beat                ; (on the "and" alone: half a beat LATE)
    lda w_same
    beq @g2
    ldy #G_OFF
    lda #TIP_FOOT
    ldx #.loword(str_tfoot)
    jsr tip
@g2:
    cpy #G_OFF                  ; a loose small dot after a good big one:
    bne @g2a                    ; only the DOUBLE TIME stride is lost
    lda w_same
    bne @g2a
    jsr loose_and
    bcc @g2a
    rts
@g2a:
    jsr steady_step             ; (keeps Y)
    tya
    sta w_sbest
    stz w_deadon
    cmp #G_PERFECT
    bne @g3
    lda tmp2
    bne @g3
    inc w_deadon                ; the landing frame or the one after
@g3:
    lda tmp1
    sta w_sd
    sta w_hitd                  ; where the step landed, for the strip
    lda #16
    sta w_hitt
    jsr double_time
    jsr set_target
    lda w_sbest
    cmp #G_OFF
    beq @off
    cmp #G_PERFECT
    beq @pf
    jsr combo_good              ; GOOD builds the combo, scores nothing
    bra @lit
@pf:
    A16
    inc w_perfect
    A8
    jsr combo_perfect
@lit:
    lda w_deadon
    beq @nd
    lda #G_DEADON
    bra @show
@nd:
    lda w_sbest
    bra @show
@off:
    jsr combo_break
    jsr sloppy_tip
    lda w_sd
    bmi @early
    lda #G_LATE
    bra @show
@early:
    lda #G_EARLY
@show:
    jsr show_grade
@step:
    SFX SFX_STEP
@shuffle:
    rts

; A step on the "and" with nothing on the beat before it, walking single
; time, is half a beat off: graded from the nearer big dot (LATE if it's at
; or before the small one, EARLY if after) and never on the small dot, so a
; hand a whole 8th behind the music never out-scores one a few frames
; behind it. It still strides (a steady walk of your own). DOUBLE TIME's
; "and" after a dropped beat is judged as ever. Y = grade, tmp1 = signed
; frames off the "and": Y = G_OFF and tmp1 = frames off the beat if so
; (8..15 LATE, -8..-14 EARLY).
off_beat:
    lda w_dt
    bne @x
    lda w_bgrade
    bne @x
    lda w_ph                    ; the 8th this step belongs to
    cmp #9
    lda w_beat
    bcc @n
    inc a
@n:
    lsr a
    bcc @x                      ; the beat itself
    ldy #G_OFF
    lda tmp1
    beq @late
    bmi @late
    sec
    sbc #BEAT                   ; after the small dot: EARLY for the next
    sta tmp1
    rts
@late:
    clc
    adc #BEAT                   ; at or before it: LATE for the last
    sta tmp1
@x:
    rts

; A step (Y = its grade, tmp1 = signed frames off): is the walk steady?
; Steps landing as the one before did (+-2 frames, three in a row) are a
; rhythm of your own, even off the dots (a TV's lag, a late habit): an
; EARLY / LATE one then strides like a GOOD one (w_stok), so a steady
; walker always makes the train; only the dots pay style. Four EARLY or
; LATE in a row the same way: the coach says which way to move (three
; times a run at most, 8 s apart). Keeps Y.
steady_step:
    lda tmp1
    sec
    sbc w_soff                  ; (-29..29: offsets wrap round the 8th)
@red:
    bpl @pos
    cmp #($100 - 7)
    bcs @neg
    clc
    adc #BEAT
    bra @red
@pos:
    cmp #8
    bcc @abs
    sec
    sbc #BEAT
    bra @red
@neg:
    eor #$FF
    inc a                       ; |diff|
@abs:
    cmp #3
    bcc @same
    stz w_steady
    bra @on
@same:
    lda w_steady
    cmp #8
    bcs @on
    inc w_steady
@on:
    lda tmp1
    sta w_soff
    stz w_stok
    cpy #G_OFF
    bne @good
    lda w_same
    bne @good
    lda w_steady
    cmp #2
    bcc @run
    inc w_stok
@run:
    lda tmp1                    ; LATE (+) / EARLY (-) in a row
    bmi @early
    lda w_srun
    bmi @l1
    cmp #$7F
    bcs @chk
    inc a
    bra @l2
@l1:
    lda #1
@l2:
    sta w_srun
    bra @chk
@early:
    lda w_srun
    beq @e1
    bpl @e1
    cmp #$81
    bcc @chk
    dec a
    bra @e2
@e1:
    lda #$FF
@e2:
    sta w_srun
@chk:
    lda w_scoach                ; the coach: not again yet, not over others
    ora w_tipt
    bne @x
    lda w_scn
    cmp #3
    bcs @x
    ldx w_popup
    bne @x
    ldx #.loword(str_late)
    lda w_srun
    bmi @ce
    cmp #4
    bcc @x
    bra @say
@ce:
    cmp #($100 - 3)
    bcs @x
    ldx #.loword(str_early)
@say:
    inc w_scn
    lda #120                    ; (x4 frames: 8 s)
    sta w_scoach
    lda #TP_CYAN
    phy
    ldy #100
    jsr popup
    ply
@x:
    rts
@good:
    stz w_srun
    rts

str_late:  .byte "LATE: STEP AS THE DOT HITS ", TXT_ARROW_L + $20, 0
str_early: .byte "EARLY: WAIT TILL THE DOT HITS", 0

; Trying DOUBLE TIME doesn't cost a walk that's on the beat: an EARLY / LATE
; step on the small dot right after a good step on the big one just drops
; you to single time (the grade still shows). The combo and the groove
; stand; the "and" closes as if nothing was stepped on it (w_sbest
; G_EARLY: "taken, but loose"). Carry set if it was that.
loose_and:
    lda w_decaf
    bne @no
    lda w_bgrade
    cmp #G_GOOD
    bcc @no
    lda w_ph                    ; the 8th this step belongs to
    cmp #9
    lda w_beat
    bcc @n
    inc a
@n:
    lsr a
    bcc @no                     ; on the beat itself: judged as ever
    stz w_dt
    lda #G_GOOD                 ; the beat's own stride, single time
    sta w_sbest
    jsr set_target
    lda #G_EARLY
    sta w_sbest
    stz w_deadon
    lda tmp1
    sta w_sd
    sta w_hitd
    lda #16
    sta w_hitt
    jsr sloppy_tip
    lda w_sd
    bmi @e
    lda #G_LATE
    bra @show
@e:
    lda #G_EARLY
@show:
    jsr show_grade
    SFX SFX_STEP
    sec
    rts
@no:
    clc
    rts

; target speed from the slot's grade and the groove (a steady EARLY / LATE
; walk: a GOOD stride)
set_target:
    lda w_sbest
    asl a
    TAXB
    A16
    lda spd_base,x
    sta tmp3
    A8
    lda w_sbest
    cmp #G_OFF
    bne @g
    lda w_stok
    beq @g
    ldx #SPD_STEADY
    stx tmp3
@g:
    lda w_streak
    asl a
    asl a
    asl a
    sec
    sbc w_streak                ; streak * 7 (streak <= 8)
    A16
    and #$00FF
    clc
    adc tmp3
    sta tmp3
    lda w_dt
    and #$00FF
    beq @t
    lda tmp3
    clc
    adc #SPD_DT
    sta tmp3
@t:
    lda tmp3
    sta w_target
    A8
    rts

; DOUBLE TIME is a good step on the "and" right after a good step on the
; beat; a sloppy step anywhere drops back to single time. DECAF: never.
double_time:
    lda w_decaf
    bne @single
    lda w_sbest
    cmp #G_GOOD
    bcc @single
    lda w_ph                    ; the 8th this step belongs to
    cmp #9
    lda w_beat
    bcc @n
    inc a
@n:
    lsr a
    bcc @x                      ; on the beat: wait for the "and"
    lda w_bgrade
    cmp #G_GOOD
    bcc @x                      ; the beat itself wasn't good
    A16
    inc w_dtn
    A8
    lda w_dt
    bne @x
    inc w_dt
    ldx w_popup                 ; say so, unless something else is up
    bne @x
    ldx #.loword(str_dt)
    lda #TP_GREEN
    ldy #40
    jmp popup
@x:
    rts
@single:
    stz w_dt
    rts

; ---- POWER WALK combo -------------------------------------------------
; every GOOD or better step adds to it; PERFECT ones score
combo_good:
    lda w_combo
    inc a
    beq @cap
    sta w_combo
@cap:
    jmp combo_level

combo_perfect:
    jsr combo_good
    lda w_level                 ; every PERFECT step scores the level,
    sta tmp2
    lda w_deadon                ; half as much again DEAD ON (rounded up),
    beq @dd
    lda w_level
    inc a
    lsr a
    clc
    adc tmp2
    sta tmp2
@dd:
    stz w_ssrc                  ; (the card's PERFECT STEPS row, or, walking
    lda w_dt                    ; DOUBLE TIME, its own row: twice the steps)
    beq @d2
    lda #2
    sta w_ssrc
@d2:
    lda tmp2
    jmp style_add

; A = points (0..255) to style, booked to source w_ssrc (s_src, the card's
; rows). Keeps X and Y.
style_add:
    .a8
    phx
    A16
    and #$00FF
    pha
    clc
    adc w_style
    sta w_style
    lda w_ssrc
    and #$000E
    tax
    pla
    clc
    adc s_src,x
    sta s_src,x
    A8
    plx
    rts

; level = 1 + combo / 10 (max 8); a banner and a ding on the way up
COMBO_MAX  = 8
COMBO_STEP = 10
combo_level:
    lda w_combo
    ldy #$0001
@lv:
    cmp #COMBO_STEP
    bcc @l0
    sbc #COMBO_STEP
    iny
    cpy #COMBO_MAX
    bcc @lv
@l0:
    tya
@l:
    cmp w_level
    beq @x
    bcc @x
    sta w_level
    asl a
    TAXB
    lda combo_msg-4,x           ; levels 2..5
    pha
    lda combo_msg-3,x
    xba
    pla
    A16
    tax
    A8
    lda #TP_GREEN
    ldy #60
    jsr popup
    SFX SFX_COIN
    lda #TIP_PRESTO             ; a combo going: the gold dots pay more
    ldx #.loword(str_tpresto)
    jmp tip
@x:
    rts

combo_break:
    stz w_combo
    lda #1
    sta w_level
    rts

combo_msg: .addr str_cx2, str_cx3, str_cx4, str_cx5, str_cx6, str_cx7, str_cx8
str_cx2: .byte "POWER WALK X2!", 0
str_cx3: .byte "RUSH HOUR X3!", 0
str_cx4: .byte "BAY STREAK X4!", 0
str_cx5: .byte "GO EXPRESS X5!", 0
str_cx6: .byte "CORNER OFFICE X6!", 0
str_cx7: .byte "BONUS SEASON X7!", 0
str_cx8: .byte "KING OF BAY ST X8!", 0

; Y: PRESTO TAP. One swipe a bar: PERFECT on the bar's downbeat (the gold
; tick) scores 10 x level and pushes the combo half a level; anything else
; is declined and breaks the combo.
input_presto:
    A16
    lda pad_new
    and #PAD_Y
    A8
    bne @go
    rts
@go:
    jsr beat_offset
    sta tmp2
    lda w_ph
    cmp #9
    lda w_beat                  ; the 8th this tap is nearest
    bcc @n
    inc a
@n:
    sta tmp3
    lsr a
    lsr a
    lsr a
    inc a
    cmp w_ybar
    beq @x                      ; already swiped this bar
    sta w_ybar
    lda tmp3
    and #$07
    bne @declined
    lda tmp2
    cmp #3
    bcs @declined
    A16
    inc w_presto
    A8
    SFX SFX_GO                  ; the reader's beep
    lda w_level
    asl a
    asl a
    clc
    adc w_level                 ; level * 5 (the level before the push)
    sta tmp2
    ldx #6                      ; (the PRESTO row)
    stx w_ssrc
    jsr style_add
    ldx #.loword(str_presto)
    lda #TP_CYAN
    ldy #40
    jsr popup_pts
    lda w_combo
    clc
    adc #4
    bcc @c
    lda #$FF
@c:
    sta w_combo
    jmp combo_level             ; (its banner wins over PRESTO)
@declined:
    ldx #.loword(str_declined)
    lda #TP_RED
    ldy #40
    jsr popup
    SFX SFX_BACK
    jmp combo_break
@x:
    rts

str_presto:   .byte "PRESTO *BEEP*! COMBO UP", 0
str_declined: .byte "CARD DECLINED! GOLD DOTS ONLY", 0

spd_base: .word 0, SPD_OFF, SPD_GOOD, SPD_PERF

; mashing: three taps inside one 8th
trip:
    lda #ST_STUMBLE
    sta w_state
    stz w_dt
    ldx #24
    stx w_timer
    stz w_streak
    stz w_groove
    jsr combo_break
    A16
    stz w_target
    lsr w_speed
    A8
    SFX SFX_CRASH
    ldx #.loword(str_whoa)
    lda #TP_YELLOW
    ldy #50
    jsr popup
    lda #0                      ; (an empty cup has nothing to spill)
    jmp spill

str_whoa: .byte "WHOA! STEP ON THE BEAT!", 0

; One spill (40 on the card): a cell of the cup's four. A = 1 for a bump:
; once the cup is dry, a bump spills the other person's latte instead (still
; a spill, still 40), so a walk that never dodges keeps paying for it.
spill:
    sta tmp0
    A16
    lda w_coffee
    bne @mine
    A8
    lda tmp0
    beq @x
    A16
    inc w_spills
    lda #30
    sta w_splash
    A8
    ldx #.loword(str_theirs)
    lda #TP_RED
    ldy #60
    jmp popup
@mine:
    .a16
    inc w_spills
    sec
    sbc #SPILL_SIPS
    bcs @c
    lda #$0000
@c:
    sta w_coffee
    lda #30
    sta w_splash
    lda w_coffee
    cmp #SPILL_SIPS
    bne @nl
    A8
    lda #TIP_LAST               ; one spill left in the cup
    ldx #.loword(str_tlast)
    jsr tip
    A16
@nl:
    lda w_coffee
    A8
    bne @x
    ; DECAF: no DOUBLE TIME from here to Union
    ldx w_tipm                  ; "LAST SIP!" still waiting: too late now
    cpx #.loword(str_tlast)
    bne @nolast
    stz w_tipt
@nolast:
    lda #$01
    sta w_decaf
    stz w_groove
    stz w_dt
    lda w_streak
    cmp #DECAF_MAX
    bcc @half
    lda #DECAF_MAX
    sta w_streak
@half:
    SFX SFX_GROAN
    ldx #.loword(str_decaf)
    lda #TP_RED
    ldy #90
    jmp popup
@x:
    rts

str_decaf:  .byte "DECAF! NO MORE DOUBLE TIME", 0
str_theirs: .byte "SORRY! SPILLED THEIR LATTE", 0

approach_speed:
    A16
    lda w_speed
    cmp w_target
    beq @x
    bcs @down
    clc
    adc #ACCEL
    cmp w_target
    bcc @s
    lda w_target
    bra @s
@down:
    sec
    sbc #DECEL
    bcc @t
    cmp w_target
    bcs @s
@t:
    lda w_target
@s:
    sta w_speed
@x:
    A8
    rts

move_player:
    ; dist += speed (8.8)
    A16
    lda w_distf
    and #$00FF
    clc
    adc w_speed
    pha
    and #$00FF
    sta w_distf
    pla
    xba
    and #$00FF
    clc
    adc w_dist
    sta w_dist
    ; ease into the lane, 5 px a frame (lanes are 20 apart)
    lda w_lane
    and #$00FF
    tax
    lda f:lane_y,x
    and #$00FF
    cmp w_y
    beq @ly
    bcc @lup
    lda w_y
    clc
    adc #5
    sta w_y
    bra @ly
@lup:
    lda w_y
    sec
    sbc #5
    sta w_y
@ly:
    A8
    rts

tick_timers:
    lda w_slt                   ; a SLALOM chain closing (held while
    beq @sl                     ; its gold ! is up)
    ldx w_cutw
    bpl @sl
    dec w_slt
@sl:
    lda w_lchg                  ; finding your feet in a new lane
    beq @lg
    dec w_lchg
@lg:
    lda w_clock                 ; (the timing coach's rest, x4 frames)
    and #$03
    bne @sc
    lda w_scoach
    beq @sc
    dec w_scoach
@sc:
    lda w_sidet                 ; stepping round a cart or a board
    beq @sd
    dec w_sidet
    bne @sd
    lda #1
    sta w_lane
    lda #BRUSH_T                ; (somebody there: only a brush)
    sta w_lchg
@sd:
    lda w_tipt                  ; a coaching tip waiting its turn
    beq @t0
    dec w_tipt
    bne @t0
    ldx w_tipm
    lda #TP_CYAN
    ldy #100
    jsr popup
@t0:
    A16
    lda w_cd
    beq @c1
    dec w_cd
@c1:
    lda w_pose
    beq @c2
    dec w_pose
@c2:
    lda w_splash
    beq @c3
    dec w_splash
@c3:
    lda w_popup
    beq @c4
    dec w_popup
    bne @c4
    A8
    jsr popup_clear
    A16
@c4:
    A8
    rts

; Out of time but within HOLD_PX of Union: the conductor holds the doors
; for you (once, HOLD_T frames). Made it then: no seconds to spare.
HOLD_PX = 240
HOLD_T  = 240
check_clock:
    A16
    lda w_time
    bne @tick
    A8
    lda w_held
    bne @holding
    A16
    lda #COURSE_LEN
    sec
    sbc w_dist
    cmp #HOLD_PX
    A8
    bcs @missed
    inc w_held
    ldx #HOLD_T
    stx w_hold
    SFX SFX_BELL
    ldx #.loword(str_hold)
    lda #TP_YELLOW
    ldy #HOLD_T
    jsr popup
    stz w_tipt                  ; (no tip over it)
    A16
    bra @nd
@holding:
    A16
    lda w_hold
    beq @missed
    dec w_hold
    bra @nd
@tick:
    dec w_time
    lda w_time
    cmp #DOORS_T
    bne @nd
    A8
    SFX SFX_BELL                ; GO's door chime: ten seconds
    ldx #.loword(str_doors)
    lda #TP_YELLOW
    ldy #90
    jsr popup
    A16
@nd:
    lda w_dist
    cmp #COURSE_LEN
    bcs @made
    A8
    rts
@made:
    .a16
    lda #COURSE_LEN             ; the camera stops dead at Union
    sta w_dist
    A8
    lda #$01
    sta w_made
    stz w_lane                  ; head for the doors
    SFX SFX_CHEER
    ldx #330
    stx w_timer
    ldx #.loword(str_made)
    lda #TP_GREEN
    bra @end
@missed:
    A8
    stz w_made
    lda #1
    sta w_trgo                  ; the 5:42 leaves on time
    ldx #150
    stx w_timer
    ldx #.loword(str_missed)
    lda #TP_RED
@end:
    ldy #300
    jsr popup
    stz w_tipt                  ; no coaching tip over the headline
    lda #ST_FINISH
    sta w_state
    rts

lane_y: .byte 148, 168, 188         ; feet: 20 px apart, on the floor's lane lines
str_made:   .byte "MADE THE 5:42!", 0
str_missed: .byte "MISSED THE TRAIN!", 0
str_doors:  .byte "STAND CLEAR OF THE DOORS!", 0
str_hold:   .byte "HOLD THE DOORS! HURRY!", 0

; UP / X: lane toward the buildings, DOWN / B: toward the curb.
; Always allowed (also mid-stumble): it's a sidewalk, you can sidestep.
input_lane:
    A16
    lda pad_new
    bit #(PAD_UP | PAD_X)
    bne @up
    bit #(PAD_DOWN | PAD_B)
    bne @down
    A8
    rts
@up:
    A8
    lda w_lane
    beq @no
    dec a
    bra @set
@down:
    A8
    lda w_lane
    cmp #2
    beq @no
    inc a
@set:
    pha
    jsr close_shave             ; (from the lane you're leaving)
    ldx w_warn                  ; leaving under a red ! (yours, or a jogger's):
    bpl @obey                   ; for a moment, a bump in the new lane is
    ldx w_jogw                  ; only a brush
    bmi @lc
@obey:
    lda #BRUSH_T
    sta w_lchg
@lc:
    pla
    sta w_lane
    stz w_sidet                 ; (you stepped round it yourself)
    SFX SFX_BLIP
@no:
    rts

; Leaving a lane with someone right in front of you (or a jogger right on
; your heels): CUT IT FINE, SHAVE_PTS, once a person. The window is the
; last SHAVE_PX or SHAVE_T frames before you'd have walked into them (cut_px).
; Undocumented: another one inside SLALOM_T frames is a SLALOM, the shave
; times the chain (X2, X3, X4); a bump ends the chain.
; Leaving a lane while the red ! is still well ahead of somebody in it is a
; DODGE (DODGE_PTS each, once a person; a jogger's too): obeying the red !
; and the arrow pays. The second gets the coach's "DODGE LATER" tip.
SHAVE_PX = 16
SHAVE_PTS= 25               ; (str_tshave says +25)
DODGE_PTS= 20               ; (the card says +20)
SLALOM_T = 150
close_shave:
    lda w_state
    cmp #ST_WALK
    beq @go
    rts
@go:
    stz w_dodn
    ldy #$0000
@e:
    lda E_TYPE,y
    jeq @n
    cmp #T_PIGEON
    jeq @n
    lda E_LANE,y
    cmp w_lane
    jne @n
    lda E_FLAGS,y
    and #$1C                    ; bumped us, stepped aside, shaved already
    jne @n
    A16
    lda E_WX,y
    sec
    sbc w_dist
    sta tmp4                    ; how far ahead (signed)
    A8
    lda E_TYPE,y
    cmp #T_JOGGER
    beq @jog
    cpy w_cutw                  ; under the chain's gold !: the window is
    bne @px                     ; TELL_T frames after it went up, never
    lda w_cwt                   ; sooner
    jeq @got
    bra @far
@px:
    jsr cut_px                  ; tmp3: how close is cutting it fine
    A16
    lda tmp4
    jmi @n16
    cmp tmp3
    bcc @got
    A8
@far:
    lda E_FLAGS,y               ; a red ! over them, still well ahead: a
    and #$40                    ; DODGE, paid as you get past them
    jeq @n
    lda E_FLAGS,y
    ora #$30
    sta E_FLAGS,y
    inc w_dodges
    jmp @n
@dodge:
    lda E_FLAGS,y               ; (a jogger: paid now)
    ora #$10
    sta E_FLAGS,y
    inc w_dodn
    inc w_dodges
    jmp @n
@jog:
    A16
    lda tmp4
    jpl @n16
    cmp #($10000 - 12 - SHAVE_PX)
    bcs @got
    A8
    cpy w_jogw                  ; the jogger's red !: out of the way in time
    beq @dodge
    jmp @n
@got:
    A8
    jsr dodge_pay               ; (any dodged on the way: paid, the shave's
    lda E_FLAGS,y               ; popup wins)
    ora #$10
    sta E_FLAGS,y
    inc w_shaves
    lda #SHAVE_PTS
    sta tmp2
    lda w_slt                   ; SLALOM: inside the window of the last one
    beq @first
    lda w_slalom
    cmp #4
    bcs @chain
    inc w_slalom
    bra @chain
@first:
    lda #1
    sta w_slalom
@chain:
    lda #SLALOM_T
    sta w_slt
    lda w_slalom
    sta tmp3
    lda tmp2
    sta tmp4
@mul:
    dec tmp3
    beq @pts
    clc
    adc tmp4                    ; (100 at most)
    bra @mul
@pts:
    sta tmp2
    ldx #4                      ; the cut itself: the CUT IT FINE row
    stx w_ssrc
    lda #SHAVE_PTS
    jsr style_add
    lda tmp2                    ; the chain's extra: its own row
    sec
    sbc #SHAVE_PTS
    beq @one
    ldx #8
    stx w_ssrc
    jsr style_add
@one:
    SFX SFX_COIN
    lda w_slalom
    cmp #2
    bcs @slalom
    ldx #.loword(str_shave)
    lda #TP_CYAN
    ldy #40
    jmp popup_pts
@slalom:
    inc w_slaloms
    jsl trick_seen
    asl a
    TAXB
    lda slalom_msg-4,x
    pha
    lda slalom_msg-3,x
    xba
    pla
    A16
    tax
    A8
    lda #TP_GREEN
    ldy #50
    jmp popup_pts
@n16:
    A8
@n:
    iny
    iny
    cpy #(NUM_ENT*2)
    jne @e
    jsr dodge_pay
    bcc @x
    ldx #.loword(str_dodge)
    lda #TP_CYAN
    ldy #36
    jsr popup_pts
    lda w_dodges                ; the second: you could cut it finer
    cmp #2
    bcc @x
    lda #TIP_SHAVE
    ldx #.loword(str_tshave)
    jmp tip
@x:
    rts

; pay the DODGEs counted so far (tmp2 = points): carry set if any. Keeps Y.
dodge_pay:
    lda w_dodn
    beq @no
    sta tmp3
    lda #0
@m:
    clc
    adc #DODGE_PTS
    dec tmp3
    bne @m
    sta tmp2
    stz w_dodn
    ldx #4                      ; (the CUT IT FINE / DODGE row; style_add
    stx w_ssrc                  ; keeps X and Y)
    jsr style_add
    sec
    rts
@no:
    clc
    rts

; Y = slot (not a jogger): tmp3 = how far ahead (px) they may be for leaving
; their lane to count as cutting it fine: contact, plus SHAVE_PX or the last
; SHAVE_T frames of closing in on them, whichever is more (so a stopped
; tourist or a board gives as long a window as a stroller). Keeps X, Y.
SHAVE_T = 24
cut_px:
    .a8
    jsr close_v                 ; closing speed (8.8)
    .a16
    sta tmp3
    asl a                       ; x 24 = x 16 + x 8
    clc
    adc tmp3                    ; x 3
    asl a
    asl a
    asl a                       ; x 24
    xba
    and #$00FF                  ; px in the last SHAVE_T frames
    cmp #SHAVE_PX
    bcs @got
    lda #SHAVE_PX
@got:
    clc
    adc #12
    sta tmp3
    A8
    lda E_TYPE,y
    cmp #T_CART
    bne @x
    A16
    lda tmp3
    clc
    adc #10                     ; (a cart is wider)
    sta tmp3
    A8
@x:
    rts
.assert SHAVE_T = 24, error, "cut_px multiplies by 24"

; Y = slot: A16 = how fast you're closing in on them (8.8, at the stride
; you're easing toward if that's faster), 0 if you aren't. Returns A16.
close_v:
    .a8
    A16
    lda w_speed
    cmp w_target
    bcs @s
    lda w_target
@s:
    sec
    sbc E_V,y
    bcs @x
    lda #$0000
@x:
    rts
    .a8

str_dodge: .byte "DODGE!", 0
slalom_msg: .addr str_sl2, str_sl3, str_sl4
str_sl2: .byte "SLALOM X2!", 0
str_sl3: .byte "SLALOM X3!", 0
str_sl4: .byte "BAY ST SLALOM X4!", 0
str_shave: .byte "CUT IT FINE!", 0

; popup "<X> +<tmp2>" (tmp2 = 0..255), A = text palette, Y = frames on show
popup_pts:
    pha
    phy
    stx ptr1
    lda #^popup
    sta ptr1+2
    ldy #$0000
@c:
    lda [ptr1],y
    beq @num
    sta w_msg,y
    iny
    bra @c
@num:
    lda #' '
    sta w_msg,y
    iny
    lda #'+'
    sta w_msg,y
    iny
    stz tmp3                    ; no digit yet (no leading zeros)
    lda tmp2
    ldx #$0000
@h:
    cmp #100
    bcc @h1
    sbc #100
    inx
    bra @h
@h1:
    jsr @digit
    ldx #$0000
@t:
    cmp #10
    bcc @t1
    sbc #10
    inx
    bra @t
@t1:
    jsr @digit
    ora #'0'
    sta w_msg,y
    iny
    lda #0
    sta w_msg,y
    ply
    pla
    ldx #.loword(w_msg)
    jmp popup
; X = a digit (A, the rest, is kept): print it unless it's a leading zero
@digit:
    pha
    txa
    ora tmp3
    beq @skip
    txa
    ora #'0'
    sta w_msg,y
    iny
    sta tmp3
@skip:
    pla
    rts

; lane_free: A = lane, tmp4 = world x, tmp5 = entity to ignore.
; Carry set if someone (not a pigeon) stands within 14 px there.
lane_free:
    sta tmp3
    ldy #$0000
@e:
    lda E_TYPE,y
    beq @next
    cmp #T_PIGEON
    beq @next
    cpy tmp5
    beq @next
    lda E_LANE,y
    cmp tmp3
    bne @next
    A16
    lda E_WX,y
    sec
    sbc tmp4
    bpl @p
    eor #$FFFF
    inc a
@p:
    cmp #14
    A8
    bcs @next
    sec
    rts
@next:
    iny
    iny
    cpy #(NUM_ENT*2)
    bne @e
    clc
    rts

; A: "EXCUSE ME!": everyone on foot in your lane under a red ! (in your
; way) steps aside. Stopping to ask breaks the POWER WALK combo; asking with
; nobody in your way (no red ! in your lane) stops you dead for a beat and
; costs groove, so shouting blind on a timer doesn't pay.
EXCUSE_T = 20                   ; frames you stand there looking around
input_excuse:
    ldx w_cd
    beq @ready
    rts
@ready:
    A16
    lda pad_new
    and #PAD_A
    A8
    bne @go
    rts
@go:
    ldx #20
    stx w_pose
    ldx #40
    stx w_cd
    jsr combo_break
    stz d_f                     ; people who stepped aside
    stz d_b                     ; anybody in sight, not in the way
    stz w_immov                 ; a cart or board in the way
    ldy #$0000
@e:
    lda E_TYPE,y
    beq @n
    cmp #T_PIGEON
    beq @n
    lda E_LANE,y
    cmp w_lane
    bne @n
    lda E_FLAGS,y               ; a red ! over them: in your way, and they
    and #$40                    ; hear you, however far ahead
    bne @heard
    A16
    lda E_WX,y
    sec
    sbc w_dist
    clc
    adc #8                      ; from 8 px behind ...
    cmp #(128 + 8)              ; ... to 128 ahead: in sight, not in the way
    A8
    bcs @n
    inc d_b
    bra @n
@heard:
    lda E_TYPE,y
    cmp #T_CART
    bcc @walk
    inc w_immov                 ; carts and boards don't
    bra @n
@walk:
    cmp #T_JOGGER
    bcs @n                      ; nor do joggers
    lda E_FLAGS,y
    and #$08
    bne @n
    tyx
    jsr step_aside
    inc d_f
@n:
    iny
    iny
    cpy #(NUM_ENT*2)
    bne @e
    lda d_f
    bne @moved
    lda w_immov
    beq @none
    SFX SFX_BACK                ; asking a hot dog cart to move
    ldx #.loword(str_budge)
    lda #TP_YELLOW
    ldy #50
    jmp popup
@moved:
    SFX SFX_SELECT
    lda w_clock                 ; a Torontonian has more than one way to say it
    and #$03
    asl a
    TAXB
    lda excuse_tab,x
    pha
    lda excuse_tab+1,x
    xba
    pla
    A16
    tax
    A8
    lda #TP_YELLOW
    ldy #40
    jmp popup
@none:
    SFX SFX_BACK                ; you stopped dead to shout at nobody
    lda #ST_STUMBLE             ; ... and stand there looking around
    sta w_state
    ldx #EXCUSE_T
    stx w_timer
    lda w_streak
    sec
    sbc #BUMP_N
    bcs @st
    lda #0
@st:
    sta w_streak
    stz w_groove
    A16
    stz w_speed
    stz w_target
    A8
    ldx #.loword(str_nobody)
    lda d_b                     ; (somebody up ahead, but not in your way)
    beq @say
    ldx #.loword(str_far)
@say:
    lda #TP_GREY
    ldy #40
    jmp popup

excuse_tab: .addr str_excuse, str_excuse2, str_excuse3, str_excuse4
str_excuse:  .byte "EXCUSE ME!", 0
str_excuse2: .byte "PARDON ME! COMING THROUGH!", 0
str_excuse3: .byte "SORRY, JUST SQUEEZING BY!", 0
str_excuse4: .byte "ON YOUR LEFT! ER, RIGHT!", 0
str_nobody:  .byte "EXCUSE ME? ...NOBODY THERE", 0
str_far:     .byte "EXCUSE ME? ...THEY CAN'T HEAR", 0
str_budge:   .byte "IT WON'T BUDGE! UP/DOWN!", 0

; X = slot: move to a free neighbouring lane, or flatten against the
; wall; either way they never block you again. Keeps Y.
step_aside:
    phy
    stx tmp5
    lda E_WX,x
    sta tmp4
    lda E_WX+1,x
    sta tmp4+1
    lda E_LANE,x
    dec a
    bmi @below
    sta tmp6
    jsr lane_free
    bcc @move
@below:
    ldx tmp5
    lda E_LANE,x
    inc a
    cmp #3
    bcs @squeeze
    sta tmp6
    jsr lane_free
    bcs @squeeze
@move:
    ldx tmp5
    lda tmp6
    sta E_LANE,x
@squeeze:
    ldx tmp5
    lda E_FLAGS,x
    ora #$08
    sta E_FLAGS,x
    ply
    rts

; bump: A = type of who we hit (the jogger hits us from behind). It knocks
; you to half pace while you apologise (this is Toronto) and costs three
; notches of groove (like a skipped beat), the combo and a SLALOM. Every
; bump but the first spills coffee (40), even once the cup is dry.
BRUSH_T = 64                    ; frames after a lane change made on a red !
bump_player:
    pha
    lda w_lchg                  ; you'd just moved over, as the ! said: you
    beq @bump                   ; only brush past them
    jmp brush
@bump:
    lda #ST_STUMBLE
    sta w_state
    lda w_dt                    ; rushing in DOUBLE TIME: a harder bump, a
    sta tmp7                    ; dead stop for longer
    stz w_dt
    ldx #BUMP_T
    stx w_timer
    lda tmp7
    beq @nn0
    lda #BUMP_NDT
    bra @nn
@nn0:
    lda #BUMP_N
@nn:
    sta tmp6
    lda w_streak
    sec
    sbc tmp6
    bcs @st
    lda #0
@st:
    sta w_streak
    stz w_groove
    jsr combo_break
    inc w_bumps
    stz w_slalom                ; a bump ends a SLALOM
    stz w_slt
    A16
    lsr w_speed                 ; knocked to half pace while you say sorry
    lda tmp7
    and #$00FF
    beq @half
    stz w_speed                 ; (DOUBLE TIME: stopped dead)
    lda #BUMP_DT
    sta w_timer
@half:
    A8
    lda w_bumps                 ; a spill (every bump but the first): you
    cmp #2                      ; stop dead to mop up and say sorry, and the
    bcc @warn1                  ; groove is gone, so walking into people
    stz w_streak                ; costs the train, not just points
    A16
    stz w_speed
    lda #SPILL_T
    sta w_timer
    bra @tgt
@warn1:
    A16
@tgt:
    lda w_speed
    sta w_target
    lda w_dist
    sec
    sbc #4
    bcs @d
    lda #$0000
@d:
    sta w_dist
    A8
    SFX SFX_SPLASH
    pla
    cmp #T_CART                 ; a cart or a sandwich board doesn't give:
    bcc @soft                   ; you stand there a moment (in its lane, so
    pha                         ; the bump reads), then step round it into
    lda #12                     ; the middle lane
    sta w_sidet
    pla
@soft:
    asl a
    TAXB
    lda bump_tab,x              ; say who it was: that's what cost you
    pha
    lda bump_tab+1,x
    xba
    pla
    A16
    tax
    A8
    lda #TP_RED
    ldy #60
    jsr popup
    lda w_bumps
    cmp #1
    bne @sp
    lda #TIP_SPILL              ; the first one's a warning: nothing spilt
    ldx #.loword(str_tspill)
    jmp tip
@sp:
    lda #1
    jsr spill
    lda #TIP_LANE               ; the second: how not to
    ldx #.loword(str_tlane)
    jmp tip

; A (on the stack) = type: a brush in the lane you just moved into on a red !.
; You check your stride (a quarter of your pace) and say sorry; nothing
; spills, the combo and the groove stand.
brush:
    stz w_lchg                  ; (one a lane change)
    inc w_brush
    A16
    lda w_speed
    lsr a
    lsr a
    eor #$FFFF
    sec
    adc w_speed
    sta w_speed
    A8
    SFX SFX_STEP
    pla
    cmp #T_CART                 ; a cart or a board still won't give: step
    bcc @soft                   ; round it into the middle lane
    lda #12
    sta w_sidet
@soft:
    ldx #.loword(str_brush)
    lda #TP_YELLOW
    ldy #50
    jmp popup

str_brush: .byte "BRUSHED PAST! SORRY!", 0

bump_tab: .addr str_sorry, str_sorry, str_tourist, str_zombie, str_left, str_sorry, str_cart, str_board
str_sorry:   .byte "BUMPED A BANKER! SORRY!", 0
str_tourist: .byte "PHOTOBOMBED A TOURIST! SORRY!", 0
str_zombie:  .byte "PHONE ZOMBIE! SORRY! SORRY!", 0
str_left:    .byte "JOGGER! ON YOUR LEFT! SPLASH", 0
str_cart:    .byte "HOT DOG CART! OOF! SORRY!", 0
str_board:   .byte "SANDWICH BOARD! SORRY!", 0

; ------------------------------------------------------------------
; The course: segments are drawn from EV_SEED as the walker reaches them.
; Every segment takes the same five draws whatever happens, so the crowd
; is the same for every player and every run.
spawn_ahead:
@l:
    A16
    lda w_nextsp
    cmp #$FFFF
    beq @done
    lda w_dist
    clc
    adc #60
    cmp w_nextsp
    bcc @done
    A8
    jsr spawn_segment
    bra @l
@done:
    A8
    rts

spawn_segment:
    A16
    lda w_nextsp
    cmp #(COURSE_LEN - 260)
    A8
    bcc @normal
    ldx #$FFFF
    stx w_nextsp
    rts
@normal:
    lda #16
    jsr ev_range
    sta r_seg
    lda #3
    jsr ev_range
    sta r_lane
    lda #64
    jsr ev_range
    sta r_v
    lda #60
    jsr ev_range
    sta r_t
    lda #50
    jsr ev_range
    sta r_gap
    lda r_seg
    asl a
    TAXB
    jsr (.loword(seg_table),x)
    ; next segment: 46..95 px on, closing up by up to 20 px along the way
    A16
    lda r_gap
    and #$00FF
    clc
    adc #46
    sta tmp0
    lda w_nextsp
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    cmp #20
    bcc @t
    lda #20
@t:
    sta tmp1
    lda tmp0
    sec
    sbc tmp1
    clc
    adc w_nextsp
    sta w_nextsp
    A8
    rts

seg_table:
    .addr seg_suit, seg_suit, seg_suit, seg_suit, seg_wall, seg_tourist, seg_tourist, seg_tourist
    .addr seg_zombie, seg_zombie, seg_zombie, seg_jogger, seg_pigeons, seg_pigeons, seg_cart, seg_board

; X = slot: zero its fields
ent_clear:
    A16
    stz E_WXF,x
    stz E_V,x
    stz E_TIMER,x
    stz E_STATE,x
    stz E_REL,x
    stz E_TYPE,x
    lda #$0002
    sta E_FLAGS,x
    A8
    rts

; common: new person of type A in lane tmp6 at x = nextsp + 260 + d_f
; (palette from the segment's draws, no RNG here)
new_person:
    pha
    jsr ev_alloc
    bcc @ok
    pla
    sec
    rts
@ok:
    jsr ent_clear
    pla
    sta E_TYPE,x
    A16
    lda w_nextsp
    clc
    adc #260
    clc
    adc d_f
    sta E_WX,x
    A8
    lda tmp6
    sta E_LANE,x
    TAYB
    lda lane_y,y
    sta E_LY,x
    lda r_v
    and #$03
    inc a
    asl a
    ora #$30                    ; priority 3: in front of Union's columns
    sta E_PAL,x
    clc
    rts

rand_lane:
    lda r_lane
    sta tmp6
    rts

seg_suit:
    jsr rand_lane
    stz d_f
    stz d_b
    lda #T_SUIT
    jsr new_person
    bcs @x
    lda r_v
    A16
    and #$00FF
    clc
    adc #$00D0
    sta E_V,x
    A8
@x:
    rts

; two suits shoulder to shoulder: one lane stays open
seg_wall:
    jsr rand_lane
    sta tmp2
    stz d_f
    stz d_b
    ldy #$0000
@two:
    phy
    lda tmp2
    inc a
    cmp #3
    bcc @l
    lda #0
@l:
    sta tmp2
    sta tmp6
    lda #T_SUIT
    jsr new_person
    bcs @n
    A16
    lda #$00C0
    sta E_V,x
    A8
@n:
    ply
    iny
    cpy #2
    bne @two
    rts

seg_tourist:
    jsr rand_lane
    stz d_f
    stz d_b
    lda #T_TOURIST
    jsr new_person
    bcs @x
    A16
    lda #$0070
    sta E_V,x
    A8
    lda r_t
    clc
    adc #40
    sta E_TIMER,x
@x:
    rts

seg_zombie:
    jsr rand_lane
    stz d_f
    stz d_b
    lda #T_ZOMBIE
    jsr new_person
    bcs @x
    A16
    lda #$0090
    sta E_V,x
    A8
    lda #80
    sta E_TIMER,x
    lda r_t
    and #$01
    sta E_STATE,x               ; first drift direction
@x:
    rts

; a jogger comes up from behind (not right at the start)
seg_jogger:
    A16
    lda w_nextsp
    cmp #400
    A8
    bcs @ok
    jmp seg_suit
@ok:
    jsr rand_lane
    ldx #($10000 - 560)         ; (about 240 px behind you: a red ! at the
    stx d_f                     ; left edge two seconds before they reach you)
    lda #T_JOGGER
    jsr new_person
    bcs @x
    A16
    lda #$0330
    sta E_V,x
    A8
@x:
    rts

seg_pigeons:
    jsr rand_lane
    stz d_f
    stz d_b
    ldy #$0000
@p:
    phy
    lda #T_PIGEON
    jsr new_person
    bcs @n
    lda #$3A
    sta E_PAL,x
    lda d_f
    clc
    adc #7
    sta d_f
@n:
    ply
    iny
    cpy #3
    bne @p
    rts

seg_cart:
    lda #2
    sta tmp6
    stz d_f
    stz d_b
    lda #T_CART
    jsr new_person
    bcs @x
    lda #$3A
    sta E_PAL,x
@x:
    rts

seg_board:
    stz tmp6
    stz d_f
    stz d_b
    lda #T_BOARD
    jsr new_person
    bcs @x
    lda #$3A
    sta E_PAL,x
@x:
    rts

; ------------------------------------------------------------------
ents_update:
    ldx #$FFFF
    stx w_warn
    stx w_jogw
    ldx #$7FFF
    stx w_warnr
    ldx #$0000
@ent:
    lda E_TYPE,x
    bne @live
    jmp @next
@live:
    stx w_cur
    jsr ent_behave
    ldx w_cur
    lda E_TYPE,x
    bne @alive
    jmp @next
@alive:
    ; x += v (8.8)
    A16
    lda E_V,x
    beq @nomove
    and #$00FF
    clc
    adc E_WXF,x
    pha
    and #$00FF
    sta E_WXF,x
    pla
    xba
    and #$00FF
    sta tmp1
    lda E_V,x
    xba
    and #$00FF
    clc
    adc tmp1
    clc
    adc E_WX,x
    sta E_WX,x
@nomove:
    A8
    ; ease into lane (pigeons in flight climb instead)
    lda E_TYPE,x
    cmp #T_PIGEON
    bne @ease
    lda E_STATE,x
    beq @ease
    lda E_LY,x
    sec
    sbc #3
    sta E_LY,x
    cmp #40
    bcs @rel
    jmp @kill
@ease:
    lda E_LANE,x
    TAYB
    lda lane_y,y
    cmp E_LY,x
    beq @rel
    bcc @up
    inc E_LY,x
    bra @rel
@up:
    dec E_LY,x
@rel:
    A16
    lda E_WX,x
    sec
    sbc w_dist
    sta tmp0
    bmi @behind
    cmp #640
    bcs @kill
    bra @ok
@behind:
    cmp #($10000 - 440)
    bcc @kill
    cmp #($10000 - 100)
    bcs @ok
    lda E_TYPE,x
    and #$00FF
    cmp #T_JOGGER
    bne @kill
@ok:
    A8
    jsr warn_check
    jsr ent_collide
    ldx w_cur
    A16
    lda tmp0
    sta E_REL,x
    lda E_FLAGS,x
    and #$FFFD
    sta E_FLAGS,x
    A8
    bra @next
@kill:
    A16
    stz E_TYPE,x
    A8
@next:
    inx
    inx
    cpx #(NUM_ENT*2)
    jne @ent
    jsr lane_advice
    jsr cut_window
    ; the first A in the arrow's place: what it means (when nothing else
    ; is up)
    lda w_adv
    cmp #3
    bne @na
    lda w_atip
    bne @na
    ldx w_popup
    bne @na
    inc w_atip
    ldx #.loword(str_tasks)
    lda #TP_CYAN
    ldy #90
    jmp popup
@na:
    ; the first red ! of the walk: say what it means, now (not after a bump)
    lda w_tips
    bit #TIP_LANE
    bne @x
    ldx w_warn
    bmi @x
    lda w_state
    cmp #ST_FINISH
    bcs @x
    lda w_tips
    ora #TIP_LANE
    sta w_tips
    ldx #.loword(str_tlane)
    lda #TP_CYAN
    ldy #100
    jmp popup
@x:
    rts

; Who's in your way: everybody ahead in your lane inside WARN_PX (at least
; a second and a half of walking, even in DOUBLE TIME at a standstill
; board) gets a red '!' over their head (E_FLAGS bit $40), not just the
; nearest, so nobody hides behind somebody else; w_warn is the nearest. A
; jogger closing in behind you gets one from JOG_PX back (off screen: at the
; left edge). X = slot, tmp0 = rel. Keeps X.
WARN_PX = 104
WARN_T  = 96                    ; frames (warn_check multiplies by 96)
JOG_PX  = 250                   ; a jogger's ! from this far behind
warn_check:
    lda E_FLAGS,x
    and #$BF
    sta E_FLAGS,x
    lda E_LANE,x
    cmp w_lane
    bne @x
    lda E_FLAGS,x
    and #$0C                    ; already bumped us / stepped aside
    bne @x
    lda E_TYPE,x
    cmp #T_PIGEON
    beq @x
    cmp #T_JOGGER
    beq @jog
    A16
    lda tmp0
    bmi @x16
    cmp #WARN_PX
    bcc @warn
    ; further off, but closing in fast (a board, a tourist stopped for a
    ; photo, a DOUBLE TIME walk): the ! goes up WARN_T frames before you'd
    ; walk into them
    lda w_speed
    cmp w_target
    bcs @sp
    lda w_target
@sp:
    sec
    sbc E_V,x                   ; closing speed (8.8)
    bcc @x16
    sta tmp1
    asl a
    clc
    adc tmp1                    ; x 3
    asl a
    asl a
    asl a
    asl a
    asl a                       ; x 96
    xba
    and #$00FF
    clc
    adc #22                     ; (contact, a cart's)
    cmp tmp0
    bcc @x16
    beq @x16
@warn:
    A8
    lda E_FLAGS,x
    ora #$40
    sta E_FLAGS,x
    A16
    lda tmp0
    cmp w_warnr
    bcs @x16
    sta w_warnr
    stx w_warn
@x16:
    A8
@x:
    rts
@jog:
    A16
    lda tmp0
    bpl @x16
    cmp #($10000 - JOG_PX)
    bcc @x16
    sta w_jogr
    stx w_jogw
    bra @x16
    .a8

; The undocumented chain's tell. While a chain is open (w_slt), the one in
; your way (w_warn) gets a gold ! and a beep (w_cutw) TELL_T frames before
; cutting past them counts: as they come within cut_px plus TELL_T frames of
; closing in, with a lane to cut into (the arrow turns gold too), and only
; while that leaves TELL_WIN frames or more of window before you'd walk into
; them (else it's just a red !). Exactly TELL_T frames after the gold ! the
; window opens (w_cwt 0) and it stays open until you'd walk into them; the
; chain is held open meanwhile (tick_timers). Without a gold ! up, anybody a
; lane over you could step in behind in time wears a gold ring (chain_next).
TELL_T   = 15
TELL_WIN = 8                    ; frames of window at least
cut_window:
    lda w_state
    bne @off
    lda w_slt
    beq @off
    ldy w_warn
    bmi @off
    cpy w_cutw
    bne @new
    lda w_cwt                   ; the gold ! stands: count down to the window
    beq @x
    dec w_cwt
@x:
    rts
@new:
    lda w_adv                   ; a lane to cut into
    beq @off
    cmp #3
    beq @off
    lda E_FLAGS,y               ; (dodged or cut past already: not again)
    and #$10
    bne @off
    jsr cut_px                  ; tmp3: the window's far edge
    lda #TELL_T
    jsr close_px
    .a16
    beq @off16                  ; (not closing in)
    clc
    adc tmp3
    sta tmp4                    ; the gold ! goes up inside this
    jsr ent_rel
    cmp tmp4
    bcs @off16
    A8
    lda #(TELL_T + TELL_WIN)    ; ... while there's time for a window
    jsr close_px
    .a16
    clc
    adc #12
    sta tmp4
    jsr ent_rel
    cmp tmp4
    bcc @off16
    A8
    sty w_cutw
    lda #TELL_T
    sta w_cwt
    SFX SFX_READY
    rts
@off16:
    A8
@off:
    ldx #$FFFF
    stx w_cutw
    stz w_cwt
    rts

; Y = slot: A16 = how far ahead they are (signed). Returns A16.
ent_rel:
    A16
    lda E_WX,y
    sec
    sbc w_dist
    rts
    .a8

; Y = slot, A = frames: A16 = px you close in on them in that many frames
; (zero flag: none). Keeps X, Y; uses tmp7. Returns A16.
close_px:
    .a8
    sta tmp7
    jsr close_v
    .a16
    lsr a
    lsr a
    lsr a
    lsr a                       ; 1/16 px a frame
    A8
    sta WRMPYA
    lda tmp7
    sta WRMPYB
    nop
    nop
    nop
    nop
    A16
    lda RDMPYL
    lsr a
    lsr a
    lsr a
    lsr a
    rts
    .a8

; X = slot: carry set if they wear the chain's gold ring: a chain open, no
; gold ! up, one lane over, free to cut past, and where stepping in behind
; them within REACT_T frames gets a gold ! with its full window before the
; chain closes. Keeps X.
REACT_T = 20
chain_next:
    .a8
    lda w_slt
    cmp #(REACT_T + 1)
    bcc @no
    lda w_state
    bne @no
    ldy w_cutw
    bpl @no
    lda E_TYPE,x
    cmp #T_JOGGER
    beq @no
    lda E_FLAGS,x
    and #$1C                    ; bumped us, stepped aside, cut past
    bne @no
    lda E_LANE,x
    sec
    sbc w_lane
    inc a
    beq @lane                   ; -1
    cmp #2
    bne @no                     ; not +1 either
@lane:
    txy
    lda #(REACT_T + TELL_T + TELL_WIN)
    jsr close_px                ; near enough to step in behind?
    .a16
    clc
    adc #12
    sta tmp4
    jsr ent_rel
    cmp tmp4
    bcc @no16
    cmp #36
    bcc @no16
    A8
    lda w_slt                   ; far enough for the gold ! in time?
    sec
    sbc #(REACT_T - TELL_T)
    jsr close_px
    .a16
    clc
    adc #(SHAVE_PX + 12)
    sta tmp4
    jsr ent_rel
    cmp tmp4
    bcs @no16
    A8
    sec
    rts
@no16:
    A8
@no:
    clc
    rts

; The lane arrow beside the walker while a red ! is up: which way is clear.
; A lane is clear when nobody is beside you there, no jogger is coming up it,
; and the first person or thing ahead in it is ADV_PX further on than the
; one in your way (and ADV_MIN at least), so a hand that takes half a second
; to move still lands well clear and gets its own red ! in good time. The
; arrow sticks to its lane while that lane stays clear (no flip-flopping
; under a reaction), else the one with more room; none clear: no arrow.
ADV_MIN = 56                    ; px (as they'll be) a lane needs ahead
ADV_PX  = 8                     ; ... and more than the one in your way
ADV_RAW = 48                    ; px it needs ahead right now (your reaction)
lane_advice:
    lda w_state
    cmp #ST_FINISH
    bcs @none
    ldx w_warn
    bpl @need
    ldx w_jogw
    bpl @jogneed
@none:
    stz w_adv
    lda #$FF
    sta w_advl
    rts
@jogneed:
    ldx #ADV_MIN
    bra @n2
@need:
    txy
    jsr eff_rel                 ; (where they'll be, not where they are)
    A16
    lda tmp5
    clc
    adc #ADV_PX
    cmp #ADV_MIN
    bcs @n1
    lda #ADV_MIN
@n1:
    tax
    A8
@n2:
    stx tmp7                    ; room a lane needs
    ldx #$0000
    stx w_roomu
    stx w_roomd
    lda w_lane
    beq @dn
    dec a
    jsr lane_room
    ldx w_room
    stx w_roomu
@dn:
    lda w_lane
    cmp #2
    bcs @pick
    inc a
    jsr lane_room
    ldx w_room
    stx w_roomd
@pick:
    ldx w_roomu                 ; (as found, before "not enough" zeroes them)
    stx w_rawu
    ldx w_roomd
    stx w_rawd
    A8
    lda w_adv                   ; keep the arrow while its lane stays good
    cmp #1                      ; enough (no flip-flopping under a reaction)
    bne @k2
    ldx w_roomu
    cpx #ADV_MIN
    bcs @x
@k2:
    cmp #2
    bne @k3
    ldx w_roomd
    cpx #ADV_MIN
    bcs @x
@k3:
    A16
    lda w_roomu
    cmp tmp7
    bcs @uok
    stz w_roomu                 ; not enough: no good
@uok:
    lda w_roomd
    cmp tmp7
    bcs @dok
    stz w_roomd
@dok:
@fresh:
    A16
    lda w_roomu
    ora w_roomd
    beq @ask
    lda w_roomu
    cmp w_roomd
    A8
    lda #2
    bcc @set                    ; more room below
    lda #1
@set:
    sta w_adv
@x:
    lda w_adv                   ; the lane it points to (zombies keep out)
    beq @nl
    asl a
    sec
    sbc #3                      ; -1 / +1
    clc
    adc w_lane
    sta w_advl
    rts
@ask:
    ; no lane to go to: somebody on foot in your way? the card's other
    ; answer, A (EXCUSE ME)
    A8
    ldx w_warn
    bmi @imm                    ; (a jogger)
    lda E_TYPE,x
    cmp #T_JOGGER
    bcs @imm
    lda w_state                 ; (not while you're knocked off your stride:
    bne @none8                  ; A does nothing then)
    ldx w_cd                    ; (anyone under a red ! hears it)
    bne @none8
    lda #3
    sta w_adv
    bra @nl
@imm:
    ; a cart, a board or a jogger won't step aside: point to the lane with
    ; the most room anyway, unless somebody is right beside you in both
    A16
    lda w_rawu
    ora w_rawd
    beq @none16
    lda w_rawu
    cmp w_rawd
    A8
    lda #2
    bcc @imm2
    lda #1
@imm2:
    jmp @set
@none16:
    A8
@none8:
    stz w_adv
@nl:
    lda #$FF
    sta w_advl
    rts

; Y = slot: tmp5 = how far ahead they'll be, give or take: rel plus about
; 1.5 s of their own walking (a stroller is further off than a cart at the
; same distance). Keeps X, Y.
eff_rel:
    A16
    lda E_V,y
    asl a
    clc
    adc E_V,y
    lsr a
    lsr a
    lsr a                       ; v * 3/8: 96 frames of walking (8.8)
    clc
    adc E_WX,y
    sec
    sbc w_dist
    sta tmp5
    A8
    rts

; A = lane: w_room = px free ahead of you there ($7FFF: nobody), or 0 when
; somebody is right beside you in it or a jogger is coming up it
lane_room:
    sta tmp6
    ldx #$7FFF
    stx w_room
    ldy #$0000
@e:
    lda E_TYPE,y
    beq @n
    cmp #T_PIGEON
    beq @n
    lda E_LANE,y
    cmp tmp6
    bne @n
    lda E_FLAGS,y
    and #$0C
    bne @n
    A16
    lda E_WX,y
    sec
    sbc w_dist
    sta tmp5                    ; rel
    A8
    lda E_TYPE,y
    cmp #T_JOGGER
    bne @walk
    A16
    lda tmp5
    bpl @n16                    ; running away from you
    cmp #($10000 - JOG_PX)
    bcs @blk                    ; coming up behind: that lane is taken
    bra @n16
@walk:
    A16
    lda tmp5
    clc
    adc #16
    cmp #(16 + ADV_RAW)
    bcc @blk                    ; beside you, or too close to get past
    lda tmp5
    bmi @n16                    ; behind you
    jsr eff_rel
    A16
    lda tmp5
    cmp w_room
    bcs @n16
    sta w_room
@n16:
    A8
@n:
    iny
    iny
    cpy #(NUM_ENT*2)
    bne @e
    rts
@blk:
    A8
    ldx #$0000
    stx w_room
    rts

; per-type behaviour, X = slot
ent_behave:
    lda E_TYPE,x
    cmp #T_TOURIST
    beq @tourist
    cmp #T_ZOMBIE
    beq @zombie
    cmp #T_PIGEON
    jeq @pigeon
    rts
@tourist:
    dec E_TIMER,x
    jne @x
    lda E_STATE,x
    beq @photo
    stz E_STATE,x
    A16
    lda #$0070
    sta E_V,x
    A8
    lda #140
    sta E_TIMER,x
    rts
@photo:
    lda #$01
    sta E_STATE,x
    A16
    stz E_V,x
    A8
    lda #80
    sta E_TIMER,x
    rts
@zombie:
    dec E_TIMER,x
    bne @x
    lda #90
    sta E_TIMER,x
    ; drift up and down by turns, if there is room
    lda E_STATE,x
    eor #$01
    sta E_STATE,x
    asl a
    dec a                       ; -1 or +1
    clc
    adc E_LANE,x
    cmp #3
    bcs @x
    sta tmp6
    cmp w_lane                  ; never into your lane right in front of
    beq @ahead                  ; you: that would be a bump nobody saw coming,
    cmp w_advl                  ; nor into the lane the arrow sends you to
    bne @free
@ahead:
    A16
    lda E_WX,x
    sec
    sbc w_dist
    clc
    adc #24
    cmp #(24 + 96)
    A8
    bcc @x
@free:
    stx tmp5
    lda E_WX,x
    sta tmp4
    lda E_WX+1,x
    sta tmp4+1
    lda tmp6
    jsr lane_free
    ldx w_cur
    bcs @x
    lda tmp6
    sta E_LANE,x
@x:
    rts
@pigeon:
    lda E_STATE,x
    bne @x
    lda E_LANE,x
    cmp w_lane
    bne @x
    A16
    lda E_WX,x
    sec
    sbc w_dist
    cmp #20
    A8
    bcs @x
    ; flap away, and they slow you down
    lda #$01
    sta E_STATE,x
    A16
    lda #$0200
    sta E_V,x
    lda w_speed
    lsr a
    sta tmp1
    lsr a
    clc
    adc tmp1
    sta w_speed
    A8
    SFX SFX_TICK
    rts

; collisions + passes, X = slot, tmp0 = rel
ent_collide:
    ; nothing to do unless they're within a few steps of us
    A16
    lda tmp0
    clc
    adc #16
    cmp #(16 + 40)
    A8
    bcc @near
    rts
@near:
    lda E_TYPE,x
    cmp #T_PIGEON
    bcs @static
    ; passing someone counts
    cmp #T_JOGGER
    beq @nopass
    lda E_FLAGS,x
    and #$03
    bne @nopass
    lda E_REL+1,x
    bmi @nopass
    lda tmp0+1
    bpl @nopass
    lda E_FLAGS,x
    ora #$01
    sta E_FLAGS,x
    A16
    inc w_passed
    A8
@nopass:
@static:
    ; got past somebody you DODGEd (a red ! over them as you left their
    ; lane) without a bump: now it pays
    lda E_FLAGS,x
    and #$20
    beq @nod
    lda tmp0+1
    bpl @nod
    lda E_REL+1,x
    bmi @nod
    lda E_FLAGS,x
    and #$DF
    sta E_FLAGS,x
    and #$04
    bne @nod
    lda #1
    sta w_dodn
    jsr dodge_pay
    phx
    ldx #.loword(str_dodge)
    lda #TP_CYAN
    ldy #36
    jsr popup_pts
    plx
@nod:
    lda w_state
    cmp #ST_WALK
    jne @x
    lda E_FLAGS,x
    and #$0C                    ; already bumped us / stepped aside
    bne @x
    lda E_TYPE,x
    cmp #T_PIGEON
    beq @x
    lda E_LANE,x
    cmp w_lane
    bne @x
    lda E_LY,x
    sec
    sbc w_y
    bpl @ady
    eor #$FF
    inc a
@ady:
    cmp #8
    bcs @x
    lda E_TYPE,x
    cmp #T_JOGGER
    beq @jog
    ; walked into the back of someone / something
    ldy #12
    cmp #T_CART
    bne @w
    ldy #22
@w:
    sty tmp1
    A16
    lda tmp0
    bmi @x16
    beq @x16
    cmp tmp1
    bcs @x16
    lda w_speed
    cmp E_V,x
    bcc @x16
    A8
    lda E_FLAGS,x
    ora #$04
    sta E_FLAGS,x
    lda E_TYPE,x
    cmp #T_JOGGER
    bcs @hard
    jsr step_aside              ; "sorry!": they make room (you don't walk
    lda E_TYPE,x                ; through them)
@hard:
    jmp bump_player
@jog:
    A16
    lda tmp0
    bpl @x16
    cmp #($10000 - 12)
    bcc @x16
    A8
    lda E_FLAGS,x
    ora #$04
    sta E_FLAGS,x
    lda #T_JOGGER
    jmp bump_player
@x16:
    A8
@x:
    rts

; ------------------------------------------------------------------
; Bay St from King to Union is one long strip of facade columns (rows 0-16
; of BG1, de-duplicated in bay_cols); the column about to scroll in is
; queued into the 64-column map ring. The sidewalk rows below just loop.
bay_stream:
    A16
    lda w_col
    cmp #STRIP_COLS
    bcs @x
    asl a
    asl a
    asl a
    sec
    sbc w_dist
    cmp #(256 + 16)
    bcs @x
    ldx w_col
    lda f:bay_colidx,x
    and #$00FF
    sta tmp0
    asl a
    asl a
    asl a
    asl a
    asl a
    sta tmp1                    ; id * 32
    lda tmp0
    asl a
    clc
    adc tmp1                    ; id * 34
    clc
    adc #.loword(bay_cols)
    sta ptr0
    lda w_col
    and #$003F
    cmp #32
    bcc @l
    clc
    adc #($0400 - 32)           ; right-hand 32x32 screen
@l:
    clc
    adc #VRAM_BG1MAP
    tax
    lda #34
    sta tmp0
    A8
    lda #^bay_cols
    sta ptr0+2
    lda #$81                    ; down a column
    jsl dma_queue
    A16
    inc w_col
@x:
    A8
    rts

bay_cols:   .incbin "bay_cols.bin"
bay_colidx: .incbin "bay_colidx.bin"

; ------------------------------------------------------------------
bay_draw:
    jsr oam_reset
    A16
    lda w_dist
    sta bg1x
    lsr a
    lsr a
    sta bg2x
    A8
    jsr draw_marker
    lda w_state
    cmp #ST_FINISH
    bcs @nobeat
    jsr draw_warn
    jsr draw_beat
@nobeat:
    ; front lane first so nearer people overlap farther ones
    lda #2
    sta w_dlane
@lane:
    lda w_lane
    cmp w_dlane
    bne @np
    jsr draw_player
@np:
    ldx #$0000
@e:
    lda E_TYPE,x
    beq @ne
    lda E_LANE,x
    cmp w_dlane
    bne @ne
    stx w_cur
    jsr draw_ent
    ldx w_cur
@ne:
    inx
    inx
    cpx #(NUM_ENT*2)
    bne @e
    dec w_dlane
    bpl @lane
    jsr draw_floor
    jsr draw_train
    ldx oam_idx
    stx w_oamlast
    rts

;  Floor marks, after everyone (later OAM slots draw underneath them): a
; yellow ring under your feet, a red one under whoever the '!' is over, and
; a shadow under everybody else, so the 3/4 view shows which lane each
; person's feet are in.
draw_floor:
    lda w_hide
    ora w_board
    bne @ents
    A16
    lda w_px
    sec
    sbc #8
    sta spr_x
    lda w_y
    sec
    sbc #12
    sta spr_y
    A8
    ldx #MS_RINGYEL_BASE
    stx tmp6
    jsr put_ring
@ents:
    lda #$3A
    sta tmp5
    ldx #$0000
@e:
    lda E_TYPE,x
    jeq @n
    cmp #T_PIGEON
    jeq @n
    stx w_cur
    A16
    lda E_WX,x
    sec
    sbc w_dist
    clc
    adc #PLAYER_SX
    sta spr_x                   ; feet, centre
    clc
    adc #8
    cmp #(256 + 8 - 4)          ; ring / shadow wholly on screen (x 8..251)
    A8
    bcs @n
    lda spr_x+1
    bne @n
    lda spr_x
    cmp #8
    bcc @n
    lda w_state
    cmp #ST_FINISH
    bcs @shadow
    ldy #MS_RINGRED_BASE
    lda E_FLAGS,x
    and #$40
    bne @ring
    cpx w_jogw
    beq @ring
    jsr chain_next              ; the chain's next one: a gold ring
    bcc @shadow
    ldy #MS_RINGYEL_BASE
@ring:
    cpx w_cutw                  ; (under the gold ! too)
    bne @rr
    ldy #MS_RINGYEL_BASE
@rr:
    sty tmp6
    lda E_LY,x
    sec
    sbc #12
    sta spr_y
    stz spr_y+1
    A16
    lda spr_x
    sec
    sbc #8
    sta spr_x
    A8
    jsr put_ring
    bra @nx
@shadow:
    lda E_TYPE,x
    cmp #T_CART
    beq @nx                     ; (on wheels: only the red ring)
    lda E_LY,x
    sec
    sbc #5
    sta spr_y
    lda spr_x
    sec
    sbc #4
    sta spr_x
    ldx #MS_SHADOW_BASE
    stx tmp6
    jsr put_small
@nx:
    ldx w_cur
@n:
    inx
    inx
    cpx #(NUM_ENT*2)
    jne @e
    rts

; a 16x16 floor ring straight into OAM: spr_x (0..255) / spr_y = top-left,
; tmp6 = tile; props palette, priority 3
put_ring:
    ldx oam_idx
    cpx #(512 - 4)
    bcs @x
    lda spr_x
    sta oam_buf,x
    lda spr_y
    sta oam_buf+1,x
    lda tmp6
    sta oam_buf+2,x
    lda tmp6+1
    and #$01
    ora #$3A
    sta oam_buf+3,x
    A16
    txa
    lsr a
    lsr a
    pha
    lsr a
    lsr a
    tay                         ; hi-table byte
    pla
    and #$0003                  ; which pair of bits
    tax
    A8
    lda f:ring_size,x
    ora oam_hi,y
    sta oam_hi,y
    A16
    lda oam_idx
    clc
    adc #4
    sta oam_idx
    A8
@x:
    rts
ring_size: .byte $02, $08, $20, $80     ; "large" for slot 0..3 of the byte

; one 8x8 sprite straight into OAM (x 0..255, so no hi-table bits):
; spr_x / spr_y = top-left, tmp6 = tile, tmp5 = attr
put_small:
    ldx oam_idx
    cpx #(512 - 4)
    bcs @x
    lda spr_x
    sta oam_buf,x
    lda spr_y
    sta oam_buf+1,x
    lda tmp6
    sta oam_buf+2,x
    lda tmp6+1
    and #$01
    ora tmp5
    sta oam_buf+3,x
    inx
    inx
    inx
    inx
    stx oam_idx
@x:
    rts

; The GO train at Union's platform, seen between the columns (sprite
; priority 2: Union's columns and entablature are BG1 high priority and
; cover it; people are priority 3). A cab car at the tail, four bi-level
; coaches and the engine at the head (east, where it leaves): 20 pieces of
; 16x32 written straight into OAM as pairs of 16x16.
draw_train:
    A16
    lda #UNION_C0
    sec
    sbc w_dist                  ; screen x where the colonnade starts
    bpl @on
    lda #$0000
@on:
    cmp #256
    bcc @vis
    A8
    rts
@vis:
    .a16
    sta tmp3                    ; leftmost x to cover
    lda w_trx
    sec
    sbc w_dist
    sta tmp2                    ; screen x of the tail
    stz tmp4                    ; piece 0..19
    ; pairs go on an even OAM slot (one hi-table nibble per pair)
    lda oam_idx
    and #$0004
    beq @piece
    ldx oam_idx
    lda #$F000
    sta oam_buf,x
    inx
    inx
    inx
    inx
    stx oam_idx
@piece:
    lda tmp2
    clc
    adc #16
    bmi @next                   ; wholly off the left edge
    cmp tmp3
    bcc @next
    beq @next
    lda tmp2
    cmp #256
    bmi @put
    jmp @done
@put:
    ldx oam_idx
    cpx #(512 - 8)
    bcc @room
    jmp @done
@room:
    lda tmp4
    asl a
    tay
    lda train_tiles,y
    A8
    sta oam_buf+2,x
    clc
    adc #32
    sta oam_buf+6,x
    lda tmp2
    sta oam_buf,x
    sta oam_buf+4,x
    lda #TRAIN_Y
    sta oam_buf+1,x
    lda #(TRAIN_Y + 16)
    sta oam_buf+5,x
    lda #($2A | (MS_COACH_BASE >> 8))
    sta oam_buf+3,x
    sta oam_buf+7,x
    ; hi table: both large, x bit 8 from the sign of x
    lda tmp2+1
    and #$01
    ora #$02
    sta tmp5
    asl a
    asl a
    ora tmp5                    ; nibble for the pair
    sta tmp5
    A16
    txa
    lsr a
    lsr a
    lsr a
    lsr a
    tay
    txa
    and #$0008
    A8
    beq @lo
    lda tmp5
    asl a
    asl a
    asl a
    asl a
    sta tmp5
@lo:
    lda tmp5
    ora oam_hi,y
    sta oam_hi,y
    A16
    txa
    clc
    adc #8
    sta oam_idx
@next:
    .a16
    lda tmp2
    clc
    adc #16
    sta tmp2
    inc tmp4
    lda tmp4
    cmp #(TRAIN_LEN / 16)
    bcs @done
    jmp @piece
@done:
    .a16
    A8
    rts

train_tiles:
    .word MS_CAB_BASE, MS_COACH_BASE+2, MS_COACH_BASE+4, MS_COACH_BASE+6
    .repeat 3
    .word MS_COACH_BASE, MS_COACH_BASE+2, MS_COACH_BASE+4, MS_COACH_BASE+6
    .endrepeat
    .word MS_LOCO_BASE, MS_LOCO_BASE+2, MS_LOCO_BASE+4, MS_LOCO_BASE+6

; hide only the sprites last frame used (oam_clear walks all 128)
oam_reset:
    A16
    ldx #$0000
    lda #$F000                  ; x 0, y 240
@l:
    cpx w_oamlast
    bcs @hi
    sta oam_buf,x
    inx
    inx
    inx
    inx
    bra @l
@hi:
    ldx #$0000
@h:
    stz oam_hi,x
    inx
    inx
    cpx #32
    bne @h
    stz oam_idx
    A8
    rts

; one 16x32 person (two 16x16 pieces) anchored at the feet:
; spr_x / spr_y = anchor, tmp6 = tile base, tmp5 = attr. Keeps spr_x/y.
; Written straight into OAM as an aligned pair (one hi-table nibble);
; oam_put costs about four times as much and a crowd adds up.
put_tall:
    A16
    lda spr_x
    sec
    sbc #8
    sta tmp0                    ; left edge
    clc
    adc #16
    bmi @out
    beq @out
    cmp #(256 + 16)
    bcs @out
    ldx oam_idx
    cpx #(512 - 12)
    bcc @room
@out:
    A8
    rts
@room:
    .a16
    txa
    and #$0004
    beq @even
    lda #$F000                  ; pad to an even slot
    sta oam_buf,x
    inx
    inx
    inx
    inx
@even:
    lda tmp6
    A8
    sta oam_buf+2,x
    clc
    adc #$20
    sta oam_buf+6,x
    lda tmp6+1
    and #$01
    ora tmp5
    sta oam_buf+3,x
    sta oam_buf+7,x
    lda tmp0
    sta oam_buf,x
    sta oam_buf+4,x
    lda spr_y
    sec
    sbc #31
    sta oam_buf+1,x
    clc
    adc #16
    sta oam_buf+5,x
    lda tmp0+1
    and #$01
    ora #$02                    ; large, x bit 8
    sta tmp1
    asl a
    asl a
    ora tmp1
    sta tmp1
    A16
    txa
    lsr a
    lsr a
    lsr a
    lsr a
    tay
    txa
    and #$0008
    A8
    beq @lo
    lda tmp1
    asl a
    asl a
    asl a
    asl a
    sta tmp1
@lo:
    lda tmp1
    ora oam_hi,y
    sta oam_hi,y
    A16
    txa
    clc
    adc #8
    sta oam_idx
    A8
    rts

; one sprite: spr_x / spr_y = top-left, tmp6 = tile, A = size (0 8x8, 1 16x16),
; attr = props palette, priority 3. On screen (x 0..255) it goes straight
; into OAM (the strip, the arrows, the marker: a dozen a frame, and oam_put
; costs about four times as much); oam_put only for x off the left edge.
put_one:
    sta spr_size
    lda spr_x+1
    bne @slow
    lda spr_size
    beq @small
    jmp put_ring                ; (16x16, props palette, priority 3)
@small:
    ldx oam_idx
    cpx #(512 - 4)
    bcs @x
    lda spr_x
    sta oam_buf,x
    lda spr_y
    sta oam_buf+1,x
    lda tmp6
    sta oam_buf+2,x
    lda tmp6+1
    and #$01
    ora #$3A
    sta oam_buf+3,x
    inx
    inx
    inx
    inx
    stx oam_idx
@x:
    rts
@slow:
    lda #$3A
    sta spr_attr
    ldx tmp6
    stx spr_tile
    jsl oam_put
    rts

; the beat strip on the bottom panel: the grade of your last step, a
; target, 8th-note ticks sliding into it (one per step), the next foot inside
; it, and a mark where your last step landed (right of the target: early,
; left: late; 2 px a frame, like the ticks). All of it inside scanlines
; 200-215, clear of the bottom overscan.
BEAT_X = 60
BEAT_Y = 208
GRADE_Y = 100                    ; target on rows 25-26 of the panel
draw_beat:
    ; where the last step landed
    lda w_hitt
    beq @noh
    dec w_hitt
    lda w_hitd
    jsr ev_sext                 ; (returns A16)
    .a16
    asl a
    eor #$FFFF
    inc a                       ; -2 * offset
    clc
    adc #(BEAT_X - 4)
    sta spr_x
    lda #(BEAT_Y - 9)
    sta spr_y
    A8
    ldx #MS_HIT_BASE
    stx tmp6
    lda #0
    jsr put_one
@noh:
    ; grade word: in line with the walker, above everybody's head (the
    ; back lane's heads start at 117), under the popup panel (rows 8-10):
    ; never over a face
    lda w_gradet
    beq @nog
    lda w_grade
    asl a
    TAXB
    A16
    lda w_px
    sec
    sbc grade_hw,x
    sta spr_x
    lda #GRADE_Y
    sta spr_y
    A8
    lda #$3A
    sta tmp5
    stz tmp5+1
    lda grade_lo,x
    sta ptr1
    lda grade_lo+1,x
    sta ptr1+1
    lda #^ms_wperfect
    sta ptr1+2
    lda grade_base,x
    sta tmp6
    lda grade_base+1,x
    sta tmp6+1
    jsr put_word
@nog:
    ; next foot
    A16
    lda #(BEAT_X - 4)
    sta spr_x
    lda #(BEAT_Y - 4)
    sta spr_y
    A8
    ldx #MS_FOOTL_BASE
    lda w_last
    cmp #2
    bne @foot
    ldx #MS_FOOTR_BASE
@foot:
    stx tmp6
    lda #0
    jsr put_one
    ; target: lit as a beat (a big dot) lands, and only then, so the beat
    ; is never mistaken for your own step (the mark and the grade word
    ; say how the step went)
    A16
    lda #(BEAT_X - 8)
    sta spr_x
    lda #(BEAT_Y - 8)
    sta spr_y
    A8
    ldx #MS_TARGETLIT_BASE
    lda w_beat
    lsr a
    bcs @dark
    lda w_ph
    cmp #8                      ; (lit for half the 8th: no 3-frame flicker)
    bcc @tg
@dark:
    ldx #MS_TARGET_BASE
@tg:
    stx tmp6
    lda #1
    jsr put_one
    ; ticks: beat k arrives in f = (15 - ph) mod 15 + 15k frames, 2 px a frame
    lda #BEAT
    sec
    sbc w_ph
    cmp #BEAT
    bcc @f0
    lda #0
@f0:
    sta d_f                     ; frames to the next tick
    lda w_ph
    beq @b0
    lda #1
@b0:
    clc
    adc w_beat
    sta d_b                     ; its 8th-note index
    A16
    lda #(BEAT_Y - 4)
    sta spr_y
    A8
@tick:
    lda d_f
    beq @skip                   ; the one landing now is the lit target
    A16
    and #$00FF
    asl a
    clc
    adc #(BEAT_X - 4)
    cmp #(BEAT_X + 96)          ; clear of GROOVE on the right
    A8
    bcs @x
    A16
    sta spr_x
    A8
    lda d_b
    ldx #MS_TICKSM_BASE         ; the "and": a small dot (double time)
    lsr a
    bcs @tk
    ldx #MS_TICKBIG_BASE        ; every beat is a step ...
    and #$03
    bne @tk
    ldx #MS_TICKGOLD_BASE       ; ... the bar's downbeat is PRESTO gold
@tk:
    stx tmp6
    lda #0
    jsr put_one
@skip:
    lda d_f
    clc
    adc #BEAT
    sta d_f
    inc d_b
    bra @tick
@x:
    rts

; a grade word straight into OAM: ptr1 = its metasprite (8x8 pieces in a
; row, unflipped), tmp6 = its first tile, spr_x / spr_y = where (on screen);
; props palette, priority 3 (oam_meta costs several times as much)
put_word:
    ldy #$0000
    ldx oam_idx
@p:
    cpx #(512 - 4)
    bcs @done
    lda [ptr1],y
    cmp #$80
    beq @done
    clc
    adc spr_x
    sta oam_buf,x
    iny
    lda [ptr1],y
    clc
    adc spr_y
    sta oam_buf+1,x
    iny
    lda [ptr1],y
    clc
    adc tmp6
    sta oam_buf+2,x
    lda tmp6+1
    adc #0
    and #$01
    ora #$3A
    sta oam_buf+3,x
    iny
    iny
    iny
    inx
    inx
    inx
    inx
    bra @p
@done:
    stx oam_idx
    rts

grade_lo:   .addr 0, 0, ms_wgood, ms_wperfect, ms_wearly, ms_wlate, ms_wmiss, ms_wdeadon
grade_hw:   .word 0, 0, 12, 21, 15, 12, 12, 21     ; half the word's width (6 px a letter)
grade_base: .word 0, 0, MS_WGOOD_BASE, MS_WPERFECT_BASE, MS_WEARLY_BASE, MS_WLATE_BASE, MS_WMISS_BASE, MS_WDEADON_BASE

; the red '!' over whoever is in your way (see warn_check), and the arrow
; to the clear lane (lane_advice) in front of the walker's chest, nudging
; the way to go
draw_warn:
    lda w_adv
    beq @na
    ldx #MS_LANEUP_BASE
    ldy #($10000 - 24)
    cmp #1
    beq @ad
    ldx #MS_LANEA_BASE
    ldy #($10000 - 22)
    cmp #3
    beq @ad
    ldx #MS_LANEDN_BASE
    ldy #($10000 - 20)
@ad:
    stx tmp6
    sty tmp7
    cmp #3
    beq @ag
    ldy w_cutw                  ; the chain's gold !: the arrow's gold too
    bmi @ag
    A16
    lda tmp6
    clc
    adc #((MS_LANEUPG_BASE - MS_LANEUP_BASE) & $FFFF)   ; (gold, as far from white both ways)
    sta tmp6
    A8
@ag:
    A16
    lda w_px
    clc
    adc #12
    sta spr_x
    lda w_y
    clc
    adc tmp7
    sta spr_y
    A8
    lda w_clock
    and #$08
    beq @ab
    lda w_adv
    cmp #3
    beq @ab                     ; (A: no nudge)
    cmp #1
    beq @aup
    inc spr_y
    inc spr_y
    bra @ab
@aup:
    dec spr_y
    dec spr_y
@ab:
    lda #0
    jsr put_one
@na:
    ldx #$0000
@e:
    lda E_TYPE,x
    beq @en
    lda E_FLAGS,x
    and #$40
    beq @en
    stx w_cur
    A16
    lda E_WX,x
    sec
    sbc w_dist
    clc
    adc #(PLAYER_SX - 4)
    sta spr_x
    A8
    jsr @put
    ldx w_cur
@en:
    inx
    inx
    cpx #(NUM_ENT*2)
    bne @e
@jog:
    ldx w_jogw
    bmi @x
    A16
    lda w_jogr
    clc
    adc #(PLAYER_SX - 4)
    cmp #4
    bpl @in
    lda #4                      ; still off screen: at the left edge
@in:
    sta spr_x
    A8
@put:
    lda E_LY,x
    sec
    sbc #44
    sta spr_y
    stz spr_y+1
    lda w_clock                 ; a little hop so it catches the eye
    and #$08
    beq @h
    dec spr_y
@h:
    ldy #MS_WARN_BASE
    cpx w_cutw                  ; the chain's tell: a gold burst ! (twice
    beq @gold                   ; the size) from TELL_T frames before the
    sty tmp6                    ; cut counts until you'd walk into them
    lda #0
    jmp put_one
@gold:
    A16
    lda spr_x
    sec
    sbc #4
    sta spr_x
    A8
    lda spr_y
    sec
    sbc #7
    sta spr_y
    ldy #MS_WARNBIG_BASE
    sty tmp6
    lda #1
    jmp put_one
@x:
    rts

.assert MS_LANEDNG_BASE - MS_LANEDN_BASE = MS_LANEUPG_BASE - MS_LANEUP_BASE, error, "draw_warn: gold arrows sit as far from the white ones"

; the "you" marker, bobbing on the beat (drawn first: always on top)
draw_marker:
    lda w_hide
    ora w_board
    beq @shown
    rts
@shown:
    A16
    lda w_px
    sec
    sbc #4
    sta spr_x
    lda w_y
    sec
    sbc #43
    sta spr_y
    A8
    lda w_beat                  ; a nod on every beat
    lsr a
    bcs @nb
    lda w_ph
    cmp #4
    bcs @nb
    A16
    inc spr_y
    inc spr_y
    A8
@nb:
    ldx #MS_MARKER_BASE
    stx tmp6
    lda #0
    jmp put_one

; the power walker: a 32x32 frame (two 16x32 columns) anchored at the
; feet, and the coffee as its own sprite in the near hand (gone when DECAF)
PW_STAND   = 8
PW_EXCUSE  = 9
PW_STUMBLE = 10
draw_player:
    lda w_hide
    beq @shown
    rts
@shown:
    lda w_pri
    sta tmp5
    stz tmp5+1
    lda w_pose
    beq @nex
    lda #PW_EXCUSE
    bra @go
@nex:
    lda w_state
    cmp #ST_STUMBLE
    bne @nst
    lda #PW_STUMBLE
    bra @go
@nst:
    cmp #ST_FINISH
    bne @walking
    lda w_made
    beq @standing
    lda w_clock                 ; strolling / climbing to the train
    lsr a
    lsr a
    and #$07
    bra @go
@walking:
    A16
    lda w_speed
    A8
    beq @standing
    ; heel strike when the step lands (frame 2 or 6), then three more
    ; frames through the stride, a quarter of a beat each
    lda w_since
    lsr a
    lsr a
    cmp #4
    bcc @s
    lda #3
@s:
    clc
    adc #2
    ldy w_last
    cpy #1
    bne @lf
    clc
    adc #4
@lf:
    and #$07
    bra @go
@standing:
    lda #PW_STAND
@go:
    sta tmp7
    pha                         ; (oam_put uses the temps)
    lda w_decaf
    bne @body
    ; the cup first: lower OAM slots draw on top, and the hand is in front
    lda tmp7
    asl a
    TAXB
    lda f:walker_cup,x
    jsr ev_sext
    clc
    adc w_px
    sta spr_x
    A8
    lda f:walker_cup+1,x
    jsr ev_sext
    clc
    adc w_y
    sta spr_y
    A8
    stz spr_size
    lda w_pri
    ora #$0A                    ; props palette
    sta spr_attr
    ldx #MS_CUP_BASE
    stx spr_tile
    jsl oam_put
@body:
    lda w_pri
    sta tmp5
    stz tmp5+1
    pla
    asl a
    TAXB
    lda pw_base,x
    sta tmp6
    lda pw_base+1,x
    sta tmp6+1
    A16
    lda w_px
    sec
    sbc #8
    sta spr_x
    lda w_y
    sta spr_y
    A8
    jsr put_tall                ; left column
    A16
    lda tmp6
    clc
    adc #2
    sta tmp6
    lda spr_x
    clc
    adc #16
    sta spr_x
    A8
    jsr put_tall                ; right column
@splash:
    lda w_splash
    beq @x
    A16
    lda w_px
    clc
    adc #6
    sta spr_x
    lda w_y
    sec
    sbc #22
    sta spr_y
    A8
    lda #$3A
    sta tmp5
    LDPTR1 ms_splash
    ldx #MS_SPLASH_BASE
    stx tmp6
    jsl oam_meta
@x:
    rts

pw_base: .word MS_PW0_BASE, MS_PW1_BASE, MS_PW2_BASE, MS_PW3_BASE, MS_PW4_BASE, MS_PW5_BASE
         .word MS_PW6_BASE, MS_PW7_BASE, MS_PW8_BASE, MS_PW9_BASE, MS_PW10_BASE

draw_ent:
    A16
    lda E_WX,x
    sec
    sbc w_dist
    clc
    adc #PLAYER_SX
    sta spr_x
    clc
    adc #32
    cmp #(256 + 64)
    A8
    bcc @vis
    rts
@vis:
    lda E_LY,x
    sta spr_y
    stz spr_y+1
    lda E_PAL,x
    sta tmp5
    stz tmp5+1
    lda E_TYPE,x
    asl a
    TAXB
    jmp (.loword(ent_draw_tab),x)

ent_draw_tab:
    .addr dr_none, dr_walker, dr_tourist, dr_zombie, dr_jogger, dr_pigeon, dr_cart, dr_board

dr_none:
    rts

dr_walker:
    lda w_clock                 ; event-local: the same every turn
    lsr a
    lsr a
    lsr a
    and #$03
dr_walk_frame:
    asl a
    TAXB
    lda npc_base,x
    sta tmp6
    lda npc_base+1,x
    sta tmp6+1
    jmp put_tall

npc_base: .word MS_NPC0_BASE, MS_NPC1_BASE, MS_NPC2_BASE, MS_NPC3_BASE

dr_tourist:
    ldx w_cur
    lda E_STATE,x
    bne @photo
    lda w_clock                 ; event-local: the same every turn
    lsr a
    lsr a
    lsr a
    lsr a
    and #$03
    bra dr_walk_frame
@photo:
    ldx #MS_PHOTO_BASE
    stx tmp6
    jsr put_tall
    lda w_clock                 ; event-local: the same every turn
    and #$18
    bne @x
    A16
    lda spr_x
    clc
    adc #6
    sta spr_x
    lda spr_y
    sec
    sbc #30
    sta spr_y
    A8
    lda #$3A
    sta tmp5
    LDPTR1 ms_flash
    ldx #MS_FLASH_BASE
    stx tmp6
    jsl oam_meta
@x:
    rts

dr_zombie:
    ldx #MS_ZOMBIE0_BASE
    lda w_clock                 ; event-local: the same every turn
    and #$10
    beq @go
    ldx #MS_ZOMBIE1_BASE
@go:
    stx tmp6
    jmp put_tall

dr_jogger:
    lda w_clock                 ; event-local: the same every turn
    lsr a
    lsr a
    and #$03
    asl a
    TAXB
    lda jog_base,x
    sta tmp6
    lda jog_base+1,x
    sta tmp6+1
    jmp put_tall

jog_base: .word MS_JOG0_BASE, MS_JOG1_BASE, MS_JOG2_BASE, MS_JOG3_BASE

dr_pigeon:
    ldx w_cur
    lda E_STATE,x
    beq @slow
    lda w_clock                 ; event-local: the same every turn
    and #$02
    bra @f
@slow:
    lda w_clock                 ; event-local: the same every turn
    and #$10
@f:
    beq @a
    LDPTR1 ms_pigeon1
    ldx #MS_PIGEON1_BASE
    bra @go
@a:
    LDPTR1 ms_pigeon0
    ldx #MS_PIGEON0_BASE
@go:
    stx tmp6
    jsl oam_meta
    rts

dr_cart:
    LDPTR1 ms_cart
    ldx #MS_CART_BASE
    stx tmp6
    jsl oam_meta
    rts

dr_board:
    ldx #MS_BOARD_BASE
    stx tmp6
    jmp put_tall

; ------------------------------------------------------------------
bay_hud:
    ; spread over four frames (by the event's own clock, so every turn
    ; does the same work on the same frames): clock / counters / pace / groove
    lda w_clock
    and #$03
    beq hud_clock
    cmp #1
    bne @n1
    jsr hud_passed
    jmp hud_coffee
@n1:
    cmp #2
    bne @n2
    jmp hud_progress
@n2:
    jmp hud_groove

; top band, row 1: 5:41:SS counting up to 5:42:00
hud_clock:
    A16
    lda w_time
    beq @late
    lda #TIME_LIMIT
    sec
    sbc w_time
    sta tmp0
    A8
    lda #60
    jsl div16
    lda tmp0
    cmp h_sec
    bne @new
    rts
@new:
    sta h_sec
    PRINT 1, 1, TP_WHITE, str_541
    ldx tmp0
    stx tmp1
    ldx #(1*32 + 6)
    ldy #$82
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_num
    rts
@late:
    A8
    lda h_sec
    cmp #$FE
    bne @new2
    rts
@new2:
    lda #$FE
    sta h_sec
    PRINT 1, 1, TP_RED, str_542
    rts

hud_passed:
    ldx w_passed
    cpx h_pass
    bne @new
    rts
@new:
    stx h_pass
    PRINT 11, 1, TP_WHITE, str_passed
    ldx w_passed
    stx tmp1
    ldx #(1*32 + 18)
    ldy #2
    lda #($20 | (TP_CYAN << 2))
    jsl txt_num
    rts

hud_coffee:
    lda w_coffee
    cmp h_cof
    bne @new
    rts
@new:
    sta h_cof
    lda w_decaf
    bne @decaf
    PRINT 21, 1, TP_WHITE, str_coffee
    bra @meter
@decaf:
    PRINT 21, 1, TP_RED, str_decafl
@meter:
    ; coffee meter: 4 cells of 4
    lda w_coffee
    sta tmp3
    ldx #$0000
@cell:
    lda tmp3
    cmp #4
    bcc @part
    sbc #4
    sta tmp3
    lda #(TXT_METER + 4)
    bra @put
@part:
    clc
    adc #TXT_METER
    stz tmp3
@put:
    sta tmp2
    phx
    A16
    txa
    clc
    adc #(1*32 + 27)
    tax
    A8
    lda #($20 | (TP_ORANGE << 2))
    jsl txt_char
    plx
    inx
    cpx #4
    bne @cell
    rts

; top band, row 3: KING [20 cells] UNION. Green is how far you've walked;
; red cells are how far behind the 5:42's pace you are.
hud_progress:
    A16
    lda w_dist
    cmp #COURSE_LEN
    bcc @in
    lda #COURSE_LEN
@in:
    sta tmp0
    A8
    lda #45                     ; COURSE_LEN / 80
    jsl div16
    lda tmp0
    sta tmp3                    ; you, 0..80
    A16
    lda #TIME_LIMIT
    sec
    sbc w_time
    sta tmp0
    A8
    lda #45                     ; TIME_LIMIT / 80: the pace you need
    jsl div16
    lda tmp0
    sta tmp4                    ; par, 0..80
    cmp h_par
    bne @new
    lda tmp3
    cmp h_prog
    bne @new
    rts
@new:
    lda tmp3
    sta h_prog
    lda tmp4
    sta h_par
    ldx #$0000
@pc:
    lda tmp3
    cmp #4
    bcc @f
    lda #4
@f:
    sta tmp5                    ; your fill
    lda tmp4
    cmp #4
    bcc @g
    lda #4
@g:
    sta tmp6                    ; the train's
    lda tmp3
    sec
    sbc tmp5
    sta tmp3
    lda tmp4
    sec
    sbc tmp6
    sta tmp4
    lda tmp5
    cmp tmp6
    bcs @k                      ; level with the pace or ahead: green
    lda tmp6
    ora #$08                    ; behind: red, the train's fill
@k:
    cmp h_cells,x
    beq @same                   ; only touch cells that changed
    sta h_cells,x
    sta tmp7
    and #$07
    clc
    adc #TXT_METER
    sta tmp2
    phx
    A16
    txa
    clc
    adc #(3*32 + 6)
    tax
    A8
    lda #($20 | (TP_GREEN << 2))
    bit tmp7
    beq @g2
    lda #($20 | (TP_RED << 2))
@g2:
    jsl txt_char
    plx
@same:
    inx
    cpx #20
    bne @pc
    rts

; bottom panel, right of the strip: GROOVE [4 cells] on row 25 and the
; combo on row 26 (rows 25-26: clear of the bottom overscan), each
; redrawn only when it changes
hud_groove:
    lda w_streak
    ldx w_decaf
    beq @k
    ora #$80
@k:
    cmp h_grv
    beq @lvl
    sta h_grv
    lda w_streak
    asl a
    sta tmp3
    lda #($20 | (TP_GREEN << 2))
    ldx w_decaf
    beq @c
    lda #($20 | (TP_GREY << 2))
@c:
    sta tmp7
    ldx #$0000
@cell:
    lda tmp3
    cmp #4
    bcc @part
    sbc #4
    sta tmp3
    lda #(TXT_METER + 4)
    bra @put
@part:
    clc
    adc #TXT_METER
    stz tmp3
@put:
    sta tmp2
    phx
    A16
    txa
    clc
    adc #(25*32 + 27)
    tax
    A8
    lda tmp7
    jsl txt_char
    plx
    inx
    cpx #4
    bne @cell
@lvl:
    lda w_level
    cmp h_lvl
    beq @x
    sta h_lvl
    dec a
    asl a
    TAXB
    lda combo_hud,x
    sta ptr0
    lda combo_hud+1,x
    sta ptr0+1
    lda #^combo_hud
    sta ptr0+2
    ldx #(26*32 + 22)
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_print
@x:
    rts

combo_hud: .addr str_hx1, str_hx2, str_hx3, str_hx4, str_hx5, str_hx6, str_hx7, str_hx8
str_hx1: .byte "        ", 0
str_hx2: .byte "COMBO X2", 0
str_hx3: .byte "COMBO X3", 0
str_hx4: .byte "COMBO X4", 0
str_hx5: .byte "COMBO X5", 0
str_hx6: .byte "COMBO X6", 0
str_hx7: .byte "COMBO X7", 0
str_hx8: .byte "COMBO X8", 0

str_541:    .byte "5:41:", 0
str_542:    .byte "5:42:00", 0
str_passed: .byte "PASSED", 0
str_coffee: .byte "COFFEE", 0
str_decafl: .byte "DECAF ", 0
str_king:   .byte "KING", 0
str_union:  .byte "UNION", 0
str_grvl:   .byte "GROOVE", 0

; ------------------------------------------------------------------
; The card: WALK + STYLE - SPILLS = SCORE, never below 0.
;  WALK   made it: 1000 + 40 a second to spare (TIME LEFT on the card);
;         missed it (or gave up): how far you got, distance / 5 (719 max)
;  STYLE  the combo level for every PERFECT step, half again DEAD ON and
;         twice in DOUBLE TIME; 5 x level a PRESTO TAP; 25 a CUT IT FINE
;         (x2..x4 in a SLALOM)
;  SPILLS 40 a spill: every bump but the first, uncapped (the cup holds
;         four, then you spill theirs)
; The penalty row is always the true cost; a sum below 0 scores 0.
FIN_BASE  = 1000
SEC_PTS   = 40              ; (bay_score multiplies by hand)
SPILL_PTS = 40
bay_score:
    A16
    lda w_time
    sta tmp0
    A8
    lda #60
    jsl div16
    A16
    lda tmp0
    sta ev_stat                 ; seconds to spare
    sta tmp4
    lda w_passed
    sta ev_stat+2
    lda w_spills
    sta ev_stat+4
    lda w_style
    sta ev_stat+6
    sta ev_break+2              ; + STYLE
    ldx #8                      ; ... and where it came from (the card's rows,
@src:                           ; summing to STYLE): PERFECT STEPS, DOUBLE
    lda s_src,x                 ; TIME, CUT IT FINE / DODGE, PRESTO, the
    sta ev_style,x              ; chain's extra
    dex
    dex
    bpl @src
    lda w_spills                ; - SPILLS: 40 each
    asl a
    asl a
    asl a
    sta tmp1                    ; *8
    asl a
    asl a                       ; *32
    clc
    adc tmp1
    sta ev_break+4
    lda w_made
    and #$00FF
    beq @missed
    lda w_quit
    and #$00FF
    bne @missed
    lda tmp4
    asl a
    asl a
    asl a
    sta tmp1                    ; s*8
    asl a
    asl a                       ; s*32
    clc
    adc tmp1                    ; s*40
    clc
    adc #FIN_BASE
    sta ev_break                ; WALK
    jsr @sum
    A8
    stz ev_fail
    rts
@missed:
    .a16
    lda w_dist
    sta tmp0
    A8
    lda #5
    jsl div16
    A16
    lda tmp0
    sta ev_break                ; WALK: how far you got
    jsr @sum
    A8
    lda w_quit
    beq @one
    lda #$03                    ; gave up
    bra @f
@one:
    lda #$01                    ; missed the train: the event's own headline
@f:
    sta ev_fail
    rts
@sum:
    .a16
    lda ev_break
    clc
    adc ev_break+2
    sec
    sbc ev_break+4
    bcs @pos
    lda #$0000                  ; never below 0 (the card says so)
@pos:
    sta ev_score
    rts
    .a8

.include "bay_meta.inc"
