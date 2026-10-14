; EVENT 2: BAY ST POWER WALK — side view, rush hour.
;  Step LEFT/RIGHT on the beat of the music to stride, UP/DOWN (or X/B) to
; change lanes, A to say "EXCUSE ME!", Y on the gold bar-line beat for a
; PRESTO TAP. Reach Union before the 5:42 GO train.
;
; Rhythm: the song runs at 15 frames per 8th note (16ths alternate 8,7) and
; is sequenced on this CPU once per main-loop pass, so w_ph (0..14) is locked
; to it: w_ph = 0 is the frame an 8th note sounds. Every 8th is a "slot"
; (w_ph 9..14 and 0 belong to the coming beat, 1..8 to the one just played;
; one frame is allowed for pad/display latency). The
; first alternating step in a slot sets the stride (PERFECT within 2 frames,
; GOOD within 4, 5-7 out is EARLY/LATE: a short stride, never a dead stop);
; consecutive good slots build the GROOVE (speed); 4 taps inside 19 frames
; is a mash and trips you.
; Style: unbroken PERFECT steps build the POWER WALK combo (x2..x5, every
; PERFECT scores the level); GOOD holds it; anything sloppy, a bump, a
; double step or an "EXCUSE ME!" breaks it, so weaving through lanes beats
; asking. PRESTO TAP (Y on a bar's downbeat, PERFECT) adds 10 x level and
; pushes the combo; a Y anywhere else is CARD DECLINED and breaks it.
.p816
.smart -
.include "globals.inc"
.include "screens.inc"

.import bay_tiles, bay_bg1, bay_bg2, bay_pal, bay_spr, bay_spr_pal, bay_sky

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
ACCEL      = $000C          ; speed approach per frame (8.8 px/frame)
DECEL      = $0008
SPD_OFF    = $00A0          ; EARLY / LATE: a short stride
SPD_GOOD   = $0110
SPD_PERF   = $0130
GROOVE_MAX = 8              ; streak cap; each step of streak adds 6/256 px/frame
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
w_flash  = ev_ram + 514         ; beat target lit
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
    PRINT 8, 27, TP_WHITE, str_grvl
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
    sta w_quit
    lda #ST_DONE
    sta w_state
@on:
    lda w_state
    cmp #ST_DONE
    bne @loop
    jsl music_stop
    jsr bay_score
    jsl score_card
    jsl hdma_off
    plb
    rtl

.include "evcommon.inc"


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
    ldx #172
    stx w_y
    ldx #TIME_LIMIT
    stx w_time
    ldx #16
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
    stx h_sec
    stx h_pass
    stx h_cof
    stx h_prog
    stx h_grv                   ; and h_lvl
    lda #$FF
    sta h_par
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
    lda w_flash
    beq @f
    dec w_flash
@f:
    inc w_ph
    lda w_ph
    cmp #BEAT
    bcc @x
    stz w_ph
    inc w_beat
@x:
    rts

; close the slot when the phase passes the half-way point
beat_slot:
    lda w_ph
    cmp #9
    beq @close
    rts
@close:
    lda w_state
    cmp #ST_WALK
    jne @reset
    lda w_sbest
    beq @miss
    cmp #G_OFF
    beq @sloppy
    lda w_streak
    cmp #GROOVE_MAX
    bcs @reset
    inc w_streak
    lda w_streak
    cmp #GROOVE_MAX
    bne @reset
    lda w_decaf
    bne @reset
    lda w_groove
    bne @reset
    inc w_groove
    ldx #.loword(str_groove)
    lda #TP_GREEN
    ldy #50
    jsr popup
    bra @reset
@sloppy:
    lsr w_streak                ; a sloppy step costs half the groove
    stz w_groove
    bra @reset
@miss:
    lsr w_streak                ; so does a skipped beat
    stz w_groove
    jsr combo_break
    A16
    lda w_target
    A8
    bne @was                    ; walking (or tried to): say so
    lda w_staps
    beq @reset
@was:
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
@reset:
    stz w_sbest
    stz w_staps
    rts

str_groove: .byte "IN THE GROOVE! TOP SPEED", 0

; A = grade word to show
show_grade:
    sta w_grade
    lda #24
    sta w_gradet
    rts

; X = message (this bank), A = text palette, Y = frames on show.
; Queued: popup_flush prints the last one asked for once a frame (a step,
; a combo banner and a PRESTO can all land on one beat).
popup:
    stx p_msg
    sty w_popup
    ora #$80                    ; pending
    sta p_pal
    rts

; Popups sit on a dark window strip so they read over any facade.
popup_flush:
    lda p_pal
    bmi @go
    rts
@go:
    and #$7F
    sta p_pal
    ldx p_msg
    stx ptr0
    lda #^popup
    sta ptr0+2
    lda #TXT_WIN
    sta txt_bg
    lda p_pal
    jsl event_popup
    stz txt_bg
    rts

; tmp1 = signed frames from the nearest 8th (one frame of pad / display
; latency allowed for: a press in time with the note lands at ph 1),
; A = |tmp1| (0..7)
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
    eor #$FF
    inc a
@abs:
    rts

; LEFT / RIGHT taps. The first alternating step of a slot sets the stride;
; a second one in the same 8th is a double step (no harm to the stride, but
; it's off the beat, so it breaks the combo).
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
    beq @shuffle                ; both at once
    cmp w_last
    beq @shuffle                ; same foot twice
    sta w_last
    stz w_since
    lda w_sbest
    beq @first
    jsr combo_break             ; double step
    bra @step
@first:
    jsr beat_offset
    ldy #G_PERFECT
    cmp #3
    bcc @g
    dey
    cmp #5
    bcc @g
    dey                         ; 5-7 frames out: EARLY / LATE
@g:
    tya
    sta w_sbest
    lda tmp1
    sta w_sd
    jsr set_target
    lda w_sbest
    cmp #G_OFF
    beq @off
    cmp #G_PERFECT
    bne @lit                    ; GOOD holds the combo
    A16
    inc w_perfect
    A8
    jsr combo_perfect
@lit:
    lda #8
    sta w_flash
    lda w_sbest
    bra @show
@off:
    jsr combo_break
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

; target speed from the slot's grade and the groove
set_target:
    lda w_sbest
    asl a
    TAXB
    A16
    lda spd_base,x
    sta tmp3
    A8
    lda w_decaf
    bne @d
    lda w_streak
    asl a
    adc w_streak                ; streak * 3 (no carry: streak <= 8)
    asl a                       ; * 6
    A16
    and #$00FF
    clc
    adc tmp3
    sta tmp3
    A8
@d:
    A16
    lda tmp3
    sta w_target
    A8
    rts

; ---- POWER WALK combo -------------------------------------------------
combo_perfect:
    lda w_combo
    inc a
    beq @cap
    sta w_combo
@cap:
    jsr combo_level
    lda w_level                 ; every PERFECT step scores the level
style_add:
    A16
    and #$00FF
    clc
    adc w_style
    sta w_style
    A8
    rts

; level = 1 + combo / 8 (max 5); a banner and a ding on the way up
combo_level:
    lda w_combo
    lsr a
    lsr a
    lsr a
    inc a
    cmp #5
    bcc @l
    lda #5
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
@x:
    rts

combo_break:
    stz w_combo
    lda #1
    sta w_level
    rts

combo_msg: .addr str_cx2, str_cx3, str_cx4, str_cx5
str_cx2: .byte "POWER WALK X2!", 0
str_cx3: .byte "RUSH HOUR X3!", 0
str_cx4: .byte "BAY STREAK X4!", 0
str_cx5: .byte "GO EXPRESS X5!", 0

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
    ldx #.loword(str_presto)
    lda #TP_CYAN
    ldy #40
    jsr popup
    SFX SFX_COIN
    lda #12
    sta w_flash
    lda w_combo
    clc
    adc #4
    bcc @c
    lda #$FF
@c:
    sta w_combo
    jsr combo_level             ; (its banner wins over PRESTO)
    lda w_level
    asl a
    sta tmp0
    asl a
    asl a
    clc
    adc tmp0                    ; level * 10
    jmp style_add
@declined:
    ldx #.loword(str_declined)
    lda #TP_RED
    ldy #40
    jsr popup
    SFX SFX_BACK
    jmp combo_break
@x:
    rts

str_presto:   .byte "PRESTO TAP! *BEEP*", 0
str_declined: .byte "PRESTO: CARD DECLINED!", 0

spd_base: .word 0, SPD_OFF, SPD_GOOD, SPD_PERF

; mashing: three taps inside one 8th
trip:
    lda #ST_STUMBLE
    sta w_state
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
    lda #2
    jmp spill

str_whoa: .byte "WHOA! STEP ON THE BEAT!", 0

; A = coffee lost
spill:
    sta tmp0
    stz tmp0+1
    A16
    lda w_coffee
    beq @dry
    inc w_spills
    sec
    sbc tmp0
    bcs @c
    lda #$0000
@c:
    sta w_coffee
    lda #30
    sta w_splash
    lda w_coffee
    bne @dry
    A8
    lda #$01
    sta w_decaf
    stz w_groove
    ldx #.loword(str_decaf)
    lda #TP_RED
    ldy #90
    jsr popup
    rts
@dry:
    A8
    rts

str_decaf: .byte "OUT OF COFFEE! NO GROOVE!", 0

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
    ; ease into the lane, 4 px a frame
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
    adc #4
    sta w_y
    bra @ly
@lup:
    lda w_y
    sec
    sbc #4
    sta w_y
@ly:
    A8
    rts

tick_timers:
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
    jsl event_popup_clear
    A16
@c4:
    A8
    rts

check_clock:
    A16
    lda w_time
    beq @missed
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
    LDPTR0 str_made
    lda #TP_GREEN
    ldx #330
    bra @end
@missed:
    A8
    stz w_made
    lda #1
    sta w_trgo                  ; the 5:42 leaves on time
    LDPTR0 str_missed
    lda #TP_RED
    ldx #150
@end:
    stx w_timer
    pha
    lda #TXT_WIN
    sta txt_bg
    pla
    jsl event_popup
    stz txt_bg
    ldx #300
    stx w_popup
    lda #ST_FINISH
    sta w_state
    rts

lane_y: .byte 156, 172, 188
str_made:   .byte "MADE THE 5:42!", 0
str_missed: .byte "MISSED THE TRAIN!", 0
str_doors:  .byte "STAND CLEAR OF THE DOORS!", 0

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
    sta w_lane
    SFX SFX_BLIP
@no:
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

; A: "EXCUSE ME!": everyone on foot just ahead in your lane steps aside.
; Stopping to ask breaks the POWER WALK combo; asking nobody stops you dead
; and costs the groove (so shouting blind on a timer doesn't pay).
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
    stz d_b                     ; anybody in earshot at all
    ldy #$0000
@e:
    lda E_TYPE,y
    beq @n
    cmp #T_PIGEON
    beq @n
    lda E_LANE,y
    cmp w_lane
    bne @n
    A16
    lda E_WX,y
    sec
    sbc w_dist
    clc
    adc #8                      ; from 8 px behind ...
    cmp #(128 + 8)              ; ... to 128 ahead: somebody to talk to
    A8
    bcs @n
    inc d_b
    A16
    cmp #(64 + 8)               ; within 64: they step aside
    A8
    bcs @n
    lda E_TYPE,y
    cmp #T_JOGGER
    bcs @n                      ; joggers, carts and boards don't
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
    lda d_b
    beq @none
    SFX SFX_STEP                ; too far yet: polite, but nobody moves
    bra @say
@moved:
    SFX SFX_SELECT
@say:
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
    ldx #20
    stx w_timer
    stz w_streak
    stz w_groove
    A16
    stz w_speed
    stz w_target
    A8
    ldx #.loword(str_nobody)
    lda #TP_GREY
    ldy #40
    jmp popup

excuse_tab: .addr str_excuse, str_excuse2, str_excuse3, str_excuse4
str_excuse:  .byte "EXCUSE ME!", 0
str_excuse2: .byte "PARDON ME! COMING THROUGH!", 0
str_excuse3: .byte "SORRY, JUST SQUEEZING BY!", 0
str_excuse4: .byte "ON YOUR LEFT! ER, RIGHT!", 0
str_nobody:  .byte "EXCUSE ME? ...NOBODY THERE", 0

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

; bump: A = type of who we hit (the jogger hits us from behind)
bump_player:
    pha
    lda #ST_STUMBLE
    sta w_state
    ldx #30
    stx w_timer
    stz w_streak
    stz w_groove
    jsr combo_break
    A16
    stz w_speed
    stz w_target
    lda w_dist
    sec
    sbc #6
    bcs @d
    lda #$0000
@d:
    sta w_dist
    A8
    SFX SFX_SPLASH
    pla
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
    lda #3
    jmp spill

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
    ldx #($10000 - 400)
    stx d_f
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
    rts

; per-type behaviour, X = slot
ent_behave:
    lda E_TYPE,x
    cmp #T_TOURIST
    beq @tourist
    cmp #T_ZOMBIE
    beq @zombie
    cmp #T_PIGEON
    beq @pigeon
    rts
@tourist:
    dec E_TIMER,x
    bne @x
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
    lda w_state
    cmp #ST_WALK
    bne @x
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
    jsr draw_train
    ldx oam_idx
    stx w_oamlast
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
; attr = props palette, priority 3
put_one:
    sta spr_size
    lda #$3A
    sta spr_attr
    ldx tmp6
    stx spr_tile
    jsl oam_put
    rts

; the beat strip on the road: a target on the left, 8th-note ticks sliding
; into it (one per step), the next foot inside it, and the
; grade of your last step above it
BEAT_X = 32
BEAT_Y = 204                    ; on the dark panel under the curb (row 25)
draw_beat:
    ; grade word
    lda w_gradet
    beq @nog
    A16
    lda #2                      ; under the target, left of GROOVE (row 27)
    sta spr_x
    lda #215
    sta spr_y
    A8
    lda #$3A
    sta tmp5
    stz tmp5+1
    lda w_grade
    asl a
    TAXB
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
    jsl oam_meta
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
    ; target (lit on a good step, and on every beat)
    A16
    lda #(BEAT_X - 8)
    sta spr_x
    lda #(BEAT_Y - 8)
    sta spr_y
    A8
    ldx #MS_TARGETLIT_BASE
    lda w_flash
    bne @tg
    lda w_ph
    cmp #3
    bcc @tg
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
    cmp #(BEAT_X + 140)
    A8
    bcs @x
    A16
    sta spr_x
    A8
    ldx #MS_TICKBIG_BASE        ; every 8th is a step ...
    lda d_b
    and #$07
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

grade_lo:   .addr 0, 0, ms_wgood, ms_wperfect, ms_wearly, ms_wlate, ms_wmiss
grade_base: .word 0, 0, MS_WGOOD_BASE, MS_WPERFECT_BASE, MS_WEARLY_BASE, MS_WLATE_BASE, MS_WMISS_BASE

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

; bottom panel, row 27: GROOVE [4 cells] and the combo's name, each
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
    adc #(27*32 + 14)
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
    ldx #(27*32 + 19)
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_print
@x:
    rts

combo_hud: .addr str_hx1, str_hx2, str_hx3, str_hx4, str_hx5
str_hx1: .byte "             ", 0
str_hx2: .byte "X2 POWER WALK", 0
str_hx3: .byte "X3 RUSH HOUR ", 0
str_hx4: .byte "X4 BAY STREAK", 0
str_hx5: .byte "X5 GO EXPRESS", 0

str_541:    .byte "5:41:", 0
str_542:    .byte "5:42:00", 0
str_passed: .byte "PASSED", 0
str_coffee: .byte "COFFEE", 0
str_decafl: .byte "DECAF ", 0
str_king:   .byte "KING", 0
str_union:  .byte "UNION", 0
str_grvl:   .byte "GROOVE", 0

; ------------------------------------------------------------------
; made it:  1000 + 25/sec to spare + 15/pass + 20/coffee + STYLE
;           (STYLE: the combo level for every PERFECT step, 10 x level a
;           PRESTO TAP)
; missed:   distance/5 + 5/pass (always under a finish); gave up: the same,
;           ev_fail 3
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
    stz ev_stat+6
    lda w_made
    and #$00FF
    beq @missed
    lda w_quit
    and #$00FF
    bne @missed
    lda w_style
    sta ev_stat+6
    lda tmp4
    asl a
    asl a
    asl a
    sta tmp1                    ; s*8
    asl a
    asl a                       ; s*32
    sec
    sbc tmp1                    ; s*24
    clc
    adc tmp4                    ; s*25
    clc
    adc #1000
    sta tmp4
    lda w_passed
    asl a
    asl a
    asl a
    asl a
    sec
    sbc w_passed                ; p*15
    clc
    adc tmp4
    sta tmp4
    lda w_coffee
    and #$00FF
    asl a
    asl a
    sta tmp1
    asl a
    asl a
    clc
    adc tmp1                    ; c*20
    clc
    adc tmp4
    clc
    adc w_style
    sta ev_score
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
    lda w_passed
    asl a
    asl a
    clc
    adc w_passed                ; p*5
    clc
    adc tmp0
    sta ev_score
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

.include "bay_meta.inc"
