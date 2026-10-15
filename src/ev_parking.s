; EVENT 6: PARALLEL PARKING — an Annex side street (Brunswick Ave), from above.
;
; You drive. UP is gas, DOWN is reverse, let go to brake. Hold LEFT / RIGHT
; to steer (full lock; the wheel centres when you let go), so backing in is
; a thumb roll on the d-pad: DOWN+RIGHT, then DOWN+LEFT, then let go. With
; both LEFT and RIGHT down (a keyboard), the one pressed last steers.
; A puts it in park once you've stopped in the spot.
;
; The car follows a bicycle model (rear axle reference, full lock = 32 px
; radius), so the classic manoeuvre works: pull up with your rear bumper on
; the yellow line beside the car ahead, full right lock and back in,
; counter-steer full left at about 55 degrees, straighten and stop. A green
; P marks the spot. The top panel (three text rows split by HDMA gaps) shows
; three grade lamps (CURB / ANGLE / SPACE) that read exactly what A would
; score right now, and the wheel. A coach line in the panel says what to do.
;
; Each spot is graded when you park; the result box lists every line:
;   base:  PARKED 200 + CURB 300/150/50 + ANGLE 200/100/40 + SPACE 100/60/30
;          (half in / crooked: HALF IN 150 plus the lamps that aren't red)
;   style: ONE-MOVE +150 (never drove forward after backing in),
;          NONSTOP +300 / SMOOTH +150 (stood still at most 10 / 20 frames
;          from moving off to A: brake on DOWN and roll straight into
;          reverse, A as it stops; on a cyclist's spot, time your approach),
;          TIME LEFT +10 a second, to the tenth the HUD clock shows,
;          DEAD CENTRE +100, ZERO ANGLE +150 (straight to half a degree),
;          CURB KISS by the pixel without touching the curb: KISSED IT
;          (0 px) +300, CLOSE KISS (1) +200, CURB KISS (2) +100,
;          PERFECT x2 +400 / x3 +800 (all-GREAT spots in a row),
;          BIKE SHAVE +200 (backing in right behind the cyclist, 0-3 px
;          from her line: the coach never mentions it, it says WAIT. The
;          tell, on every cyclist: DING ... DING and a DING! bubble beside
;          her, 16 frames before the window opens and up until it closes;
;          roll to DOWN+RIGHT from the line 16-30 frames after it pops up)
;   penalties: each bump into a parked car 150, curb 50, sidewalk 100,
;          hydrant 200, hedge 100, clipping a cyclist 150, the $75 TICKET 75
;   not in the spot when time runs out: TOWED, 0.
; The coach line is a driving instructor timed to your hand: it measures how
; long you take to answer LET GO OF UP and BACK IN (the pedal cues), and
; separately NOW! and STRAIGHT! (the steering cues: until it has seen one,
; it assumes at least RS_MIN and aims wider). It says LET GO early enough
; that you stop on the line or a little short of it (which counts), NOW!
; when the swing you'd get once your hand gets there ends NOW_AIM px out
; (and clears the BMW from where you'll be then), and STRAIGHT! LET GO in
; time to stop straight. Callouts wait under those timed lines. Too late,
; it says so and has you stop, pull out a bit and stop again, one line at
; a time. It aims safe: GREAT grades need you to
; anticipate. The car sprite's tilt steps match the ANGLE lamp's grades.
; Spots: 1 roomy, 2 snug with a cyclist coming up the lane (bell + callout
; as you near the line: wait for her before backing in), 3 tight with less
; time. The meter maid walks down the sidewalk in the last 10 seconds.
; Ten seconds without touching the d-pad (and not in the spot) gets you towed
; and ends the run (ev_fail 4).
; Run = sum of spots; ev_break = base / style / penalties, exactly the sum of
; the result boxes. No spot parked = ev_fail 1. The HUD never shows a minus
; score: below 0 it reads OWED (red), and at the end the run's score.
; Calling it a day (pause menu) = ev_fail 3, scored like a failed run.
.p816
.smart -
.include "globals.inc"
.include "screens.inc"

.import parking_tiles, parking_map, parking_pal, parking_spr, parking_spr_pal
.import trick_seen          ; boot.s: the attract demo's WATCH THAT MOVE! cue

; geometry (screen pixels; the car's reference point is its rear axle)
A_TOP    = 48           ; car ahead occupies y 48..88
A_REAR   = 88
SPOT_X0  = 205          ; parked cars span x 205..227
SPOT_X1  = 227
CURB     = 232
HEDGE    = 248
LANE_X   = 189          ; rear axle x at the start
START_Y  = 206          ; rear axle y at the start (car spans 174..212)
LAT      = 11           ; half width
REAR     = 6            ; rear bumper behind the axle
FRONT    = 32           ; front bumper ahead of the axle
TOP_LIM  = 48           ; no corner above this (the panel)
BOT_LIM  = 222
LEFT_LIM = 52
FAR_X    = 76           ; the far side's parked cars end here (x 53..74)
HYD_X    = 242
BIKE_X   = 170          ; the cyclist's line up the lane

; handling (speeds in 1/128 px per frame)
VF_MAX   = 96           ; forward 0.75 px/f
VR_MAX   = 48           ; reverse 0.375 px/f
ACC_F    = 4
ACC_R    = 3
BRAKE    = 8
STEER_RT = 16           ; wheel slew per frame (64 = full lock: 4 frames)
TH_MAX   = $3800        ; heading clamp (about 79 degrees)

IDLE_TOW = 10*60        ; frames without a button before the tow truck comes

; phases
PH_DRIVE = 0
PH_ANIM  = 1
PH_DONE  = 2

; outcomes
O_PERFECT = 0
O_NICE    = 1
O_OK      = 2
O_TICKET  = 3
O_TOWED   = 4
O_LATE    = 5           ; time ran out, but it was parked well enough
O_OKC     = 6           ; parked, one lamp short of NICELY DONE: the curb
O_OKA     = 7           ;   ... the angle
O_OKS     = 8           ;   ... the space

; per-spot flags (k_flags)
F_REV    = $01          ; has backed up
F_FWD    = $02          ; drove forward after backing up (no ONE-MOVE)
F_CURB   = $04
F_WALK   = $08
F_HYD    = $10
F_HEDGE  = $20
F_BIKE   = $40
F_OVER   = $80          ; pulled up past the line (no ONE-MOVE)

; blockers (k_hit)
H_CARA   = $01
H_CARB   = $02
H_HEDGE  = $04
H_BOUND  = $08
H_CARL   = $10          ; a car parked on the far side

k_ax     = ev_ram + 0       ; 8.8
k_ay     = ev_ram + 2       ; 8.8
k_th     = ev_ram + 4       ; 1/65536 turn, signed; high byte = sin8 angle
k_phase  = ev_ram + 6
k_timer  = ev_ram + 8
k_spot   = ev_ram + 10
k_len    = ev_ram + 12      ; spot length
k_btop   = ev_ram + 14      ; top of the car behind
k_v      = ev_ram + 16      ; signed speed (+ forward), 1/128 px per frame
k_steer  = ev_ram + 18      ; signed wheel -64..64 (+ = right)
k_notch  = ev_ram + 20      ; wheel target from the pad: -1 left lock, 0 centre, 1 right
k_clock  = ev_ram + 24      ; frames left on this spot
k_elap   = ev_ram + 26      ; frames since the spot started
k_score  = ev_ram + 28      ; running total shown on the HUD
k_last   = ev_ram + 30      ; this spot's net score (signed)
k_flags  = ev_ram + 32
k_bumpcd = ev_ram + 34
k_alarm  = ev_ram + 36      ; 1 car ahead, 2 car behind
k_alarmt = ev_ram + 38
k_msg    = ev_ram + 40      ; callout string (bank-local address)
k_msgt   = ev_ram + 42
k_msgcol = ev_ram + 44
k_out    = ev_ram + 46
k_anim   = ev_ram + 48
k_ex     = ev_ram + 50      ; meter maid / tow truck position
k_ey     = ev_ram + 52
k_palA   = ev_ram + 54
k_palB   = ev_ram + 56
k_hyd    = ev_ram + 58      ; hydrant y
k_gap    = ev_ram + 60      ; curb - rightmost corner (signed)
k_room   = ev_ram + 62      ; smaller of the front / rear clearances (signed)
k_ang    = ev_ram + 64      ; |heading| in 1/256 turns
k_gc     = ev_ram + 66      ; grades 0 great 1 good 2 ok 3 bad 4 n/a
k_ga     = ev_ram + 68
k_gs     = ev_ram + 70
k_s      = ev_ram + 72      ; sin / cos of the current heading
k_c      = ev_ram + 74
k_jig    = ev_ram + 76      ; shake timer
k_inspot = ev_ram + 78      ; 1 = in the spot zone (lamps lit)
CX       = ev_ram + 80      ; 4 corner x (words, px): RL RR FL FR
CY       = ev_ram + 88
CX8      = ev_ram + 248     ; the same in 8.8 (what the blockers test)
CY8      = ev_ram + 256
k_oax    = ev_ram + 96      ; pose before this frame's move
k_oay    = ev_ram + 98
k_oth    = ev_ram + 100
k_base   = ev_ram + 102     ; run totals
k_bonus  = ev_ram + 104
k_pen    = ev_ram + 106
k_sbase  = ev_ram + 108     ; this spot
k_sbonus = ev_ram + 110
k_spen   = ev_ram + 112
k_parked = ev_ram + 114     ; stats
k_kisses = ev_ram + 116
k_onemv  = ev_ram + 118
k_dents  = ev_ram + 120
k_curbx  = ev_ram + 122     ; rightmost corner - curb (signed)
k_shown  = ev_ram + 124     ; message line as last drawn (address)
k_style  = ev_ram + 126     ; style earned this spot: 1 one-move 2 time left 4 zero angle 8 kiss
                            ; $10 streak $20 centre $40 shave $80 nonstop / smooth
k_bx     = ev_ram + 128     ; cyclist
k_by     = ev_ram + 130     ; 8.8
k_bst    = ev_ram + 132     ; 0 none, 1 waiting, 2 riding, 3 gone
k_btime  = ev_ram + 134
k_geyser = ev_ram + 136
k_hit    = ev_ram + 138
k_coach  = ev_ram + 140     ; coach line (address)
k_maid   = ev_ram + 142     ; meter maid on the sidewalk
k_shcol  = ev_ram + 144     ; colour of the message line as drawn
k_hud    = ev_ram + 146     ; HUD phase
k_wob    = ev_ram + 148     ; cyclist wobble timer
k_row    = ev_ram + 150     ; results box: next row
k_lpen   = ev_ram + 152     ; last spot's penalties
k_tmp    = ev_ram + 160     ; scratch words (160..175)
k_md     = ev_ram + 176     ; smul_w operand
k_idle   = ev_ram + 178     ; frames without a button
k_asleep = ev_ram + 180     ; 1 = towed for idling: the run ends
k_sdent  = ev_ram + 182     ; bumps this spot
k_bmode  = ev_ram + 184     ; result box: 0 count lines, 1 draw them
k_bcount = ev_ram + 186
k_streak = ev_ram + 188     ; all-GREAT spots in a row
k_tickets = ev_ram + 190    ; stats
k_towed  = ev_ram + 192
k_stime  = ev_ram + 194     ; this spot's TIME LEFT bonus
k_sstrk  = ev_ram + 196     ; this spot's PERFECT streak bonus
k_val    = ev_ram + 198     ; result box line: points, sign, palette
k_bsign  = ev_ram + 200
k_bpal   = ev_ram + 202
k_ssec   = ev_ram + 204     ; whole seconds left when parked
k_tgt    = ev_ram + 206     ; where the rear axle should stop before backing in
k_bcur   = ev_ram + 208     ; result box: line being walked, line to draw now,
k_bstep  = ev_ram + 210     ;   and whether the last line was the one drawn
k_bdrew  = ev_ram + 212
k_react  = ev_ram + 214     ; the coach's idea of your reaction time (frames)
k_rt     = ev_ram + 216     ; timing an answer to "BACK IN"
k_rtst   = ev_ram + 218     ; 0 not yet, 1 timing, 2 done this spot
k_nowb   = ev_ram + 220     ; NOW! / KEEP HOLDING gap thresholds (biased by $80)
k_rdyb   = ev_ram + 222
k_stuck  = ev_ram + 224     ; frames the car has been blocked while you drive it
k_stuckv = ev_ram + 226     ; the gear it was blocked in: 1 forward, $FF reverse
k_bgap   = ev_ram + 228     ; result box: blank lines between its rows (HDMA)
k_half   = ev_ram + 230     ; half in: what it pays (HALF_IN, or WAY_OFF)
k_front  = ev_ram + 232     ; clearance to the car ahead / behind (signed px)
k_rear   = ev_ram + 234
k_rows   = ev_ram + 236     ; result box layout: rows, screen line, row
k_line   = ev_ram + 238
k_rowk   = ev_ram + 240
k_spark  = ev_ram + 242     ; sparkle angle (draw_extras)
k_stuckn = ev_ram + 244     ; the wheel when it got stuck
k_bring  = ev_ram + 246     ; the cyclist's bell: this far short of the line
k_cr     = ev_ram + 264     ; bmw_clear: radius, radius squared
k_cr2    = ev_ram + 266
k_psave  = ev_ram + 268     ; pause_ok while the result box has it off
k_sx     = ev_ram + 270     ; move_car: the blocked pose, and what blocked it
k_sy     = ev_ram + 272
k_shit   = ev_ram + 274
k_saycoach = ev_ram + 276   ; the coach line when the callout went up
k_lgo    = ev_ram + 278     ; timing an answer to LET GO OF UP: 0 not yet, 1 timing, 2 done
k_lgot   = ev_ram + 280
k_drove  = ev_ram + 282     ; 1 = the d-pad has driven the car this spot
k_late   = ev_ram + 284     ; swung in too late: 1 stop, 2 pull out a bit, 3 stop, 0 swing again
k_shave  = ev_ram + 286     ; cyclist: closest the car came to her (px), $FF none
k_short  = ev_ram + 288     ; how far short of the line still counts as on it
k_t0     = ev_ram + 290     ; scratch for the coach's predictions
k_t1     = ev_ram + 292
k_bspd   = ev_ram + 294     ; the cyclist's speed this spot (8.8 px a frame)
k_lgpad  = ev_ram + 296     ; LET GO OF UP: frames of margin on top of your reaction
k_reacts = ev_ram + 300     ; your reaction to the steering cues (NOW!, STRAIGHT!): 0 = not seen yet
k_nst    = ev_ram + 302     ; timing an answer to NOW! (1) or STRAIGHT! (2), 0 not timing
k_ntm    = ev_ram + 304
k_over   = ev_ram + 306     ; this far past the line still counts as on it (px)
k_lead   = ev_ram + 308     ; frames ahead the coach is judging (scratch)
k_skiss  = ev_ram + 310     ; this spot's CURB KISS: px from the curb (0-2)
k_still  = ev_ram + 312     ; frames the car has stood still since it first moved (NONSTOP)
k_moved  = ev_ram + 314     ; 1 = the car has moved this spot
k_cuev   = ev_ram + 316     ; the cyclist's warning: 1 = her DING! bubble is up
k_cuet   = ev_ram + 318     ;   frames since she rang it (0 = not yet this spot, $FF = long ago)
k_sflow  = ev_ram + 320     ; this spot's NONSTOP / SMOOTH bonus
k_sty    = ev_ram + 324     ; the run's TIME+STYLE by source (5 words, ev_style): TIME LEFT,
                            ;   KEPT ROLLING, CURB KISSES, TIDY PARKING, the cyclist's
k_hdma   = ev_ram + 512     ; result box: BG3VOFS HDMA table (<= 160 bytes)

.segment "EVENTS2"             ; with Off-Leash and Tallboy (GFX0 is full with TTC Surfing)
.a8
.i16

ev_parking:
    phb
    phk
    plb
    jsr pk_init
    jsr spot_setup
    jsr pk_draw
    jsl event_card
    jsr hud_full
    jsr hud_hdma_on
    jsl event_countdown
    lda #SONG_PARKING
    jsl music_play
@loop:
    jsl wait_frame
    ; the end condition first: a pause on the last frame can't undo a finish
    lda k_phase
    cmp #PH_DONE
    beq @end
    lda ev_giveup
    bne @quit
    jsr pk_update
    jsr pk_draw
    jsr pk_hud
    lda k_phase
    cmp #PH_DONE
    bne @loop
@end:
    jsl music_stop
    jsr pk_score
    bra @card
@quit:
    ; called it a day from the pause menu: the spots you finished count,
    ; the one you walked away from pays nothing (its dings still count).
    ; The last spot's result box already showing: the run is over anyway.
    lda k_phase
    cmp #PH_ANIM
    bne @q
    lda k_asleep
    bne @end
    lda k_spot
    cmp #2
    beq @end
@q:
    jsl music_stop
    A16
    lda k_pen
    clc
    adc k_spen
    sta k_pen
    stz k_spen
    A8
    jsr pk_score
    lda #$03
    sta ev_fail
@card:
    ; the HUD's total as the card has it (never below 0)
    ldx ev_score
    stx k_score
    jsr hud_top
    jsl oam_clear               ; nothing pokes through the results card
    jsl hdma_off                ; the panel's row gaps
    jsl score_card
    plb
    rtl

pk_init:
    jsl ppu_off
    jsl set_mode1_defaults
    jsl load_text_gfx
    VLOAD VRAM_BGTILES, parking_tiles, (parking_map - parking_tiles)
    VLOAD VRAM_BG1MAP, parking_map, 2048
    PLOAD 32, parking_pal, 96
    VLOAD VRAM_OBJTILES, parking_spr, 16384
    PLOAD 144, parking_spr_pal, 80
    lda cur_player
    ldy #$0000
    jsl player_palette
    lda #$15
    sta tm_sh
    stz txt_bg
    ldx #$0000
@c:
    stz ev_ram,x
    inx
    cpx #256
    bne @c
    lda #REACT0                 ; 0.4 s until it knows you (a first-timer)
    sta k_react
    stz k_reacts                ; (the steering cues: from your pedal answers till then)
    stz k_nst
    ldx #$0000
@s:
    stz k_sty,x                 ; (past the 256 bytes cleared above)
    inx
    cpx #10
    bne @s
    rts

REACT0 = 20

; per spot: length (shortest, plus 0..spot_var-1 at random), clock, cyclist
spot_len:  .word 80, 71, 65
spot_var:  .word 9, 7, 4
spot_clk:  .word 30*60, 30*60, 25*60
spot_bike: .word 0, 1, 1
spot_tgt:  .word TGT_Y, TGT_Y, TGT_Y - 3
spot_short: .word 12, 10, 8     ; stopped this far short of the line is still on it
spot_lgpad: .word 12, 12, 12    ; LET GO margin (frames): short of the line beats past it
spot_over: .word 4, 4, 2        ; past the line by more than this: back to it first (the swing
                                ; in from further up would clip the BMW)
spot_msg:  .addr str_spot1, str_spot2, str_spot3

spot_setup:
    lda k_spot
    asl a
    TAXB
    lda spot_var,x
    jsl rand_range
    A16
    and #$00FF
    clc
    adc spot_len,x
    sta k_len
    clc
    adc #A_REAR
    sta k_btop
    sec
    sbc #10
    sta k_hyd
    lda spot_clk,x
    sta k_clock
    lda spot_tgt,x
    sta k_tgt
    lda spot_bike,x
    sta k_bst                   ; 1 = a cyclist is coming this spot
    lda spot_short,x
    sta k_short
    lda spot_lgpad,x
    sta k_lgpad
    lda spot_over,x
    sta k_over
    stz k_nst
    stz k_lgo
    stz k_drove
    stz k_late
    lda #$00FF
    sta k_shave
    lda #.loword(co_up)
    sta k_coach                 ; (the spot's name isn't cut short for GAS)
    lda spot_msg,x
    tax
    lda #(LANE_X * 256 + 128)
    sta k_ax
    lda #(START_Y * 256)
    sta k_ay
    stz k_th
    stz k_v
    stz k_steer
    stz k_notch
    stz k_elap
    stz k_flags
    stz k_bumpcd
    stz k_alarm
    stz k_alarmt
    stz k_jig
    stz k_geyser
    stz k_maid
    stz k_sbase
    stz k_sbonus
    stz k_spen
    stz k_style
    stz k_btime
    stz k_wob
    stz k_idle
    stz k_sdent
    stz k_stime
    stz k_sstrk
    stz k_rtst
    stz k_stuck
    stz k_still
    stz k_moved
    stz k_cuev
    stz k_cuet
    stz k_sflow
    lda #$FFFF
    sta k_shown
    A8
    lda #TP_YELLOW
    jsr say
    lda #90
    sta k_msgt
    lda #PH_DRIVE
    sta k_phase
    ; parked cars: two random colours (sprite palettes 1-3)
    lda #3
    jsl rand_range
    inc a
    sta k_palA
    lda #3
    jsl rand_range
    inc a
    sta k_palB
    jsr restore_car_pals
    lda #24
    jsl rand_range
    clc
    adc #BIKE_RING
    sta k_bring
    stz k_bring+1
    lda #$80                    ; she rides 1 to 1.5 px a frame
    jsl rand_range
    A16
    and #$00FF
    clc
    adc #$0100
    sta k_bspd
    A8
    lda #10                     ; where in the lane you start varies a little
    jsl rand_range
    clc
    adc #START_Y
    sta k_ay+1
    jsr pose_trig
    jsr corners
    jsr spot_eval
    rts

str_spot1: .byte "SPOT 1: ROOMY. EASY DOES IT", 0
str_spot2: .byte "SPOT 2: SNUG. MIND THE BIKES", 0
str_spot3: .byte "SPOT 3: TIGHT, 25 S, BIKES", 0

; X = message (bank-local), A = text palette: show it in the panel for ~1.7 s
; (at least MSG_MIN frames; after that, a coach instruction other than the
; one that was up when it went up replaces it). Clobbers X.
MSG_T   = 100
MSG_MIN = 40
say:
    stx k_msg
    sta k_msgcol
    lda #MSG_T
    sta k_msgt
    ldx k_coach
    stx k_saycoach
    rts

; X = points: add to this spot's penalties (the callout says what it cost;
; the HUD score moves when the spot's box adds it all up)
add_pen:
    A16
    txa
    clc
    adc k_spen
    sta k_spen
    A8
    rts

; carry set = the coach's line shows, not the callout: while driving, the
; timed lines (LET GO, NOW!, STRAIGHT!, TOO LATE) are up and your hand needs
; them now. A callout that has had its moment (MSG_SEEN frames) ends; a
; newer one waits under the line (a curb scrape is told once you've let go)
MSG_SEEN = 20
msg_held:
    lda k_phase
    bne @no
    ldx k_coach
    cpx #.loword(co_brake)
    beq @yes
    cpx #.loword(co_now)
    beq @yes
    cpx #.loword(co_stop)
    beq @yes
    cpx #.loword(co_late)
    beq @yes
@no:
    clc
    rts
@yes:
    lda k_msgt
    cmp #(MSG_T - MSG_SEEN + 1)
    bcs @w
    stz k_msgt
@w:
    sec
    rts

; ------------------------------------------------------------------
pk_update:
    ; timers that run in every phase (a callout waits under an urgent line)
    lda k_msgt
    beq @m
    jsr msg_held
    bcs @m
    dec k_msgt
@m:
    lda k_jig
    beq @j
    dec k_jig
@j:
    lda k_alarmt
    beq @a
    dec k_alarmt
    jsr anim_alarm
    lda k_alarmt
    bne @a
    jsr restore_car_pals
@a:
    lda k_phase
    beq ph_drive
    cmp #PH_ANIM
    bne @x
    jmp ph_anim
@x:
    rts

ph_drive:
    lda k_bumpcd
    beq @b
    dec k_bumpcd
@b:
    A16
    inc k_elap
    dec k_clock
    A8
    bne @live
    ; time's up: whatever it is now is what you get
    jsr spot_eval
    sec
    jmp park_result
@live:
    ; a beat at the start of each spot: inputs held over from the last one
    ; (or the A that skipped its result) don't count
    lda k_spot
    beq @ctl
    A16
    lda k_elap
    cmp #24
    A8
    bcs @ctl
    A16
    stz k_v
    A8
    bra @in
@ctl:
    jsr read_input
@in:
    ; ten seconds without touching the d-pad (mashing A isn't driving),
    ; nowhere near the spot: towed, and that's the run (a crowd shouldn't
    ; watch a parked car for 90 s)
    A16
    lda pad
    and #(PAD_UP | PAD_DOWN | PAD_LEFT | PAD_RIGHT)
    beq @idle
    stz k_idle
    A8
    lda #1
    sta k_drove
    bra @awake8
@idle:
    .a16
    inc k_idle
    lda k_idle
    cmp #IDLE_TOW
    A8
    bcc @awake8
    lda k_inspot
    bne @awake8
    lda #1
    sta k_asleep
    sec
    jmp park_result
@awake:
    A8
@awake8:
    jsr steer_slew
    jsr move_car
    jsl flow_count
    jsr soft_hazards
    jsr bike_update
    jsl bike_cue
    jsr maid_update
    jsr spot_eval
    jsr react_time
    jsr coach
    ; A / B: put it in park (stopped, in the spot)
    A16
    lda k_elap
    cmp #24
    A8
    bcs @a
    rts
@a:
    A16
    lda pad_new
    and #(PAD_A | PAD_B)
    A8
    beq @x
    A16
    lda k_v
    bpl @p
    eor #$FFFF
    inc a
@p:
    cmp #9
    A8
    bcs @moving
    lda k_inspot
    beq @nospot
    A16
    stz k_v
    A8
    clc
    jmp park_result
@moving:
    ldx #.loword(str_stopfirst)
    lda #TP_ORANGE
    jmp say
@nospot:
    lda k_drove                 ; an A left over from the box: not yet
    beq @x
    ldx #.loword(str_nospot)
    lda #TP_ORANGE
    jmp say
@x:
    rts

str_stopfirst: .byte "STOP FIRST, THEN A", 0
str_nospot:    .byte "THAT'S NOT A SPOT!", 0

; ------------------------------------------------------------------
; D-pad: hold LEFT / RIGHT to steer (full lock; let go and the wheel
; centres), UP gas, DOWN reverse, neither brakes. Backing in is a thumb
; roll: DOWN+RIGHT, then DOWN+LEFT, then let go.
read_input:
    ; the wheel: held LEFT / RIGHT = full lock that way, let go = it centres.
    ; Both held (a keyboard, or a thumb rolling over): the newer one steers.
    A16
    lda pad
    and #(PAD_LEFT | PAD_RIGHT)
    beq @centre
    cmp #(PAD_LEFT | PAD_RIGHT)
    bne @one
    lda pad_new
    and #(PAD_LEFT | PAD_RIGHT)
    beq @keep                   ; neither is new: keep the lock you had
    cmp #(PAD_LEFT | PAD_RIGHT)
    beq @keep
@one:
    ldx #$FFFF
    cmp #PAD_LEFT
    beq @set
    ldx #$0001
    bra @set
@centre:
    ldx #$0000
@set:
    stx k_notch
@keep:
    A8
@thr:
    A16
    lda pad
    and #(PAD_UP | PAD_DOWN)
    cmp #PAD_UP
    beq @fwd
    cmp #PAD_DOWN
    beq @rev
    ; neither (or both): brake
    lda k_v
    beq @st
    bmi @bn
    sec
    sbc #BRAKE
    bpl @st
    lda #$0000
    bra @st
@bn:
    clc
    adc #BRAKE
    bmi @st
    lda #$0000
    bra @st
@fwd:
    lda k_v
    bpl @fa
    clc
    adc #BRAKE
    bmi @st
    lda #$0000
    bra @st
@fa:
    clc
    adc #ACC_F
    cmp #VF_MAX
    bcc @st
    lda #VF_MAX
    bra @st
@rev:
    lda k_v
    beq @ra
    bmi @ra
    sec
    sbc #BRAKE
    bpl @st
    lda #$0000
    bra @st
@ra:
    sec
    sbc #ACC_R
    cmp #($10000 - VR_MAX)
    bcs @st
    lda #($10000 - VR_MAX)
@st:
    sta k_v
    ; gears: backing up, then driving forward again, costs the ONE-MOVE
    lda k_v
    beq @g
    bpl @gf
    lda k_flags
    ora #F_REV
    sta k_flags
    bra @g
@gf:
    lda k_flags
    and #F_REV
    beq @g
    lda k_flags
    ora #F_FWD
    sta k_flags
@g:
    A8
    rts

; the wheel turns toward the notch (64 = full lock) at STEER_RT per frame
steer_slew:
    A16
    lda k_notch
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    sec
    sbc k_steer                 ; target - steer
    beq @x
    bmi @dn
    cmp #STEER_RT
    bcc @add
    lda #STEER_RT
    bra @add
@dn:
    cmp #($10000 - STEER_RT)
    bcs @add
    lda #($10000 - STEER_RT)
@add:
    clc
    adc k_steer
    sta k_steer
@x:
    A8
    rts

; ------------------------------------------------------------------
; one frame of driving: heading, then position, then the blockers
move_car:
    A16
    lda k_ax
    sta k_oax
    lda k_ay
    sta k_oay
    lda k_th
    sta k_oth
    lda k_v
    bne @go
    A8
    jsr pose_trig
    jmp corners
@go:
    .a16
    bpl @p
    eor #$FFFF
    inc a
@p:
    sta k_tmp                   ; distance this frame (1/128 px, < 128)
    A8
    ; full-lock turn = dist * 2.546 (radius 32): r = dist * 163 >> 7
    sta WRMPYA
    lda #163
    sta WRMPYB
    nop
    nop
    nop
    nop
    A16
    lda RDMPYL
    asl a
    xba
    and #$00FF
    sta k_tmp+2
    ; times |wheel| / 64
    lda k_steer
    bpl @s
    eor #$FFFF
    inc a
@s:
    A8
    sta WRMPYA
    lda k_tmp+2
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
    lsr a
    sta k_tmp+2
    ; forward + right wheel turns clockwise; reversing flips it
    lda k_v
    eor k_steer
    bpl @plus
    lda k_th
    sec
    sbc k_tmp+2
    bra @clamp
@plus:
    lda k_th
    clc
    adc k_tmp+2
@clamp:
    bmi @neg
    cmp #TH_MAX
    bcc @ok
    lda #TH_MAX
    bra @ok
@neg:
    cmp #($10000 - TH_MAX)
    bcs @ok
    lda #($10000 - TH_MAX)
@ok:
    sta k_th
    A8
    jsr pose_trig
    ; dx = sin * dist / 64, dy = cos * dist / 64 (8.8)
    lda k_s
    ldy k_tmp
    jsr smul
    .a16
    jsr asr6
    sta k_tmp+4
    A8
    lda k_c
    ldy k_tmp
    jsr smul
    .a16
    jsr asr6
    sta k_tmp+6
    lda k_v
    bmi @back
    lda k_ax
    clc
    adc k_tmp+4
    sta k_ax
    lda k_ay
    sec
    sbc k_tmp+6
    sta k_ay
    bra @moved
@back:
    lda k_ax
    sec
    sbc k_tmp+4
    sta k_ax
    lda k_ay
    clc
    adc k_tmp+6
    sta k_ay
@moved:
    A8
    jsr corners
    jsr block_check
    lda k_hit
    bne @blocked
    stz k_stuck                 ; it moved: not stuck
    rts
@blocked:
    ; against a parked car: slide along it (the move across or along the
    ; street alone) rather than stick, if that much is free
    lda k_hit
    sta k_shit
    and #(H_CARA | H_CARB | H_CARL)
    beq @stop
    A16
    lda k_ax
    sta k_sx
    lda k_ay
    sta k_sy
    lda k_oax
    sta k_ax
    A8
    jsr corners
    jsr block_check
    lda k_hit
    beq @slid
    A16
    lda k_sx
    sta k_ax
    lda k_oay
    sta k_ay
    A8
    jsr corners
    jsr block_check
    lda k_hit
    beq @slid
    lda k_shit
    sta k_hit
    bra @stop
@slid:
    stz k_stuck
    rts
@stop:
    ; stuck against it: how long, and in which gear (for the coach)
    lda k_stuck
    inc a
    beq @sat
    sta k_stuck
@sat:
    lda #$01
    ldy k_v
    bpl @gear
    lda #$FF
@gear:
    sta k_stuckv
    lda k_notch
    sta k_stuckn
    A16
    lda k_oax
    sta k_ax
    lda k_oay
    sta k_ay
    lda k_oth
    sta k_th
    stz k_v
    A8
    jsr pose_trig
    jsr corners
    jmp on_block

pose_trig:
    lda k_th+1
    jsl sin8
    sta k_s
    lda k_th+1
    jsl cos8
    sta k_c
    rts

; A8 = signed s8, Y = unsigned multiplier (< 256) -> A16 = signed product
smul:
    pha
    cmp #$80                    ; sign of A itself (pha sets no flags)
    bcc @p
    eor #$FF
    inc a
@p:
    sta WRMPYA
    tya
    sta WRMPYB
    nop
    nop
    nop
    nop
    pla
    A16
    bpl @pos
    lda RDMPYL
    eor #$FFFF
    inc a
    rts
@pos:
    lda RDMPYL
    rts
.a8

; A8 = signed s8, k_md = signed word (|k_md| < 256) -> A16 = product
smul_w:
    pha
    A16
    lda k_md
    bpl @p
    eor #$FFFF
    inc a
@p:
    tay
    A8
    pla
    jsr smul
    .a16
    bit k_md
    bpl @x
    eor #$FFFF
    inc a
@x:
    rts
.a8

; arithmetic shifts on A16
asr6:
    .a16
    cmp #$8000
    ror a
asr5:
    cmp #$8000
    ror a
    cmp #$8000
    ror a
    cmp #$8000
    ror a
    cmp #$8000
    ror a
    cmp #$8000
    ror a
    rts
asr7:
    cmp #$8000
    ror a
    bra asr6
.a8

; corners of the rotated body: P = axle + lat*r + lon*f,
; r = (cos, sin), f = (sin, -cos)  (sin/cos scaled by 127). Worked out in
; 8.8 from the 8.8 axle (CX8 / CY8: what the blockers test, so the car slides
; along a bumper instead of catching on a rounded pixel), and in whole px
; (CX / CY: for everything else).
corners:
    ; tmp1 = cos*11, tmp2 = sin*11, tmp3 = cos*6, tmp4 = sin*6, tmp5 = cos*32,
    ; tmp6 = sin*32, all 8.8 (x 2 / 128 = x 256 / 127, near enough)
    lda k_c
    ldy #(LAT * 2)
    jsr smul
    .a16
    sta tmp1
    A8
    lda k_s
    ldy #(LAT * 2)
    jsr smul
    .a16
    sta tmp2
    A8
    lda k_c
    ldy #(REAR * 2)
    jsr smul
    .a16
    sta tmp3
    A8
    lda k_s
    ldy #(REAR * 2)
    jsr smul
    .a16
    sta tmp4
    A8
    lda k_c
    ldy #(FRONT * 2)
    jsr smul
    .a16
    sta tmp5
    A8
    lda k_s
    ldy #(FRONT * 2)
    jsr smul
    .a16
    sta tmp6
    ; rear left (-11, -6): x = ax - c11 - s6, y = ay - s11 + c6
    lda k_ax
    sec
    sbc tmp1
    sec
    sbc tmp4
    sta CX8
    lda k_ay
    sec
    sbc tmp2
    clc
    adc tmp3
    sta CY8
    ; rear right (+11, -6)
    lda k_ax
    clc
    adc tmp1
    sec
    sbc tmp4
    sta CX8+2
    lda k_ay
    clc
    adc tmp2
    clc
    adc tmp3
    sta CY8+2
    ; front left (-11, +32)
    lda k_ax
    sec
    sbc tmp1
    clc
    adc tmp6
    sta CX8+4
    lda k_ay
    sec
    sbc tmp2
    sec
    sbc tmp5
    sta CY8+4
    ; front right (+11, +32)
    lda k_ax
    clc
    adc tmp1
    clc
    adc tmp6
    sta CX8+6
    lda k_ay
    clc
    adc tmp2
    sec
    sbc tmp5
    sta CY8+6
    ; whole pixels (the bounds keep every corner on screen while you drive)
    ldx #$0000
@px:
    lda CX8,x
    xba
    and #$00FF
    sta CX,x
    lda CY8,x
    xba
    and #$00FF
    sta CY,x
    inx
    inx
    cpx #8
    bne @px
    A8
    rts

; k_hit = what the body overlaps: parked cars, hedge, screen bounds (corner
; tests in 8.8: a corner is in a pixel once it's anywhere inside it)
block_check:
    stz k_hit
    ldx #$0000
@c:
    A16
    lda CX8,x
    cmp #(HEDGE * 256)
    bcc @nh
    A8
    lda #H_HEDGE
    tsb k_hit
    A16
@nh:
    lda CX8,x
    cmp #(FAR_X * 256)
    bcs @nfar
    ; over in the far parking lane: is there a car parked there?
    lda CY8,x
    cmp #(44 * 256)
    bcc @nfar
    cmp #(82 * 256)
    bcc @far
    cmp #(100 * 256)
    bcc @nfar
    cmp #(138 * 256)
    bcc @far
    cmp #(150 * 256)
    bcc @nfar
    cmp #(188 * 256)
    bcc @far
    cmp #(204 * 256)
    bcc @nfar
@far:
    A8
    lda #H_CARL
    tsb k_hit
    A16
@nfar:
    lda CX8,x
    cmp #(LEFT_LIM * 256)
    bcc @bound
    lda CY8,x
    cmp #(TOP_LIM * 256)
    bcc @bound
    cmp #((BOT_LIM + 1) * 256)
    bcs @bound
    ; parked cars (x 205..227)
    lda CX8,x
    cmp #(SPOT_X0 * 256)
    bcc @next
    cmp #((SPOT_X1 + 1) * 256)
    bcs @next
    lda CY8,x
    cmp #(A_TOP * 256)
    bcc @next
    cmp #((A_REAR + 1) * 256)
    bcs @notA
    A8
    lda #H_CARA
    tsb k_hit
    bra @next8
@notA:
    .a16
    lda k_btop
    xba                         ; btop * 256
    cmp CY8,x
    beq @inB
    bcs @next
@inB:
    clc
    adc #(41 * 256)
    cmp CY8,x
    bcc @next
    beq @next
    A8
    lda #H_CARB
    tsb k_hit
    bra @next8
@bound:
    .a16
    A8
    lda #H_BOUND
    tsb k_hit
@next8:
    A16
@next:
    A8
    inx
    inx
    cpx #8
    jne @c
    ; the parked cars' inner corners poking into the body
    ldx #SPOT_X0
    ldy #A_REAR
    jsr pt_in_car
    bcc @a2
    lda #H_CARA
    tsb k_hit
@a2:
    ldx #SPOT_X1
    ldy #A_REAR
    jsr pt_in_car
    bcc @b1
    lda #H_CARA
    tsb k_hit
@b1:
    ldx #SPOT_X0
    ldy k_btop
    jsr pt_in_car
    bcc @b2
    lda #H_CARB
    tsb k_hit
@b2:
    ldx #SPOT_X1
    ldy k_btop
    jsr pt_in_car
    bcc @x
    lda #H_CARB
    tsb k_hit
@x:
    rts

; X, Y = a point (px): carry set if it's inside the car body. Worked out in
; 8.8 against the 8.8 axle with the PPU's 16 x 8 multiplier, so it doesn't
; jump a pixel as the axle crosses one.
PK_M7A = $211B
PK_M7B = $211C
pt_in_car:
    A16
    txa
    xba
    and #$FF00
    sec
    sbc k_ax                    ; dx (8.8)
    sta k_tmp+8
    jsr @abs_ok
    jcs @out
    tya
    xba
    and #$FF00
    sec
    sbc k_ay                    ; dy (8.8)
    sta k_tmp+10
    jsr @abs_ok
    jcs @out
    ; lat = dx*c + dy*s (in 1/128 px: |lat| < LAT*128 is inside)
    lda k_tmp+8
    ldy k_c
    jsr @mul
    sta k_tmp+12
    lda k_tmp+10
    ldy k_s
    jsr @mul
    clc
    adc k_tmp+12
    bpl @lp
    eor #$FFFF
    inc a
@lp:
    cmp #(LAT * 128)
    bcs @out
    ; lon = dx*s - dy*c: -REAR < lon < FRONT
    lda k_tmp+8
    ldy k_s
    jsr @mul
    sta k_tmp+12
    lda k_tmp+10
    ldy k_c
    jsr @mul
    eor #$FFFF
    sec
    adc k_tmp+12
    bmi @neg
    cmp #(FRONT * 128)
    bcs @out
    bra @in
@neg:
    cmp #($10000 - REAR * 128 + 1)
    bcc @out
@in:
    A8
    sec
    rts
@out:
    A8
    clc
    rts
; A16 = 8.8 value, Y = sin / cos byte -> A16 = value * it / 256 (signed)
@mul:
    .a16
    A8
    sta PK_M7A
    xba
    sta PK_M7A
    tya
    sta PK_M7B
    A16
    lda MPYM
    rts
; A16 = 8.8 value: carry clear when it's within 40 px (close enough to test)
@abs_ok:
    .a16
    bpl @ap
    eor #$FFFF
    inc a
@ap:
    cmp #(40 * 256)
    rts
.a8

; something blocked the move: parked cars honk, the hedge eats you
on_block:
    lda k_hit
    and #(H_CARA | H_CARB | H_CARL)
    beq @nc
    lda k_bumpcd
    bne @refresh
    ; a new bump
    inc k_dents
    inc k_sdent
    lda #8
    sta k_jig
    SFX SFX_CRASH
    lda k_hit
    and #H_CARA
    beq @b
    lda #1
    sta k_alarm
    ldx #.loword(str_dentA)
    bra @alarm
@b:
    lda k_hit
    and #H_CARB
    beq @far
    lda #2
    sta k_alarm
    ldx #.loword(str_dentB)
@alarm:
    lda #90
    sta k_alarmt
    bra @say
@far:
    ldx #.loword(str_dentL)     ; the far side: no alarm, just a honk
@say:
    lda #TP_RED
    jsr say
    ldx #150
    jsr add_pen
@refresh:
    lda #45
    sta k_bumpcd
@nc:
    lda k_hit
    and #H_HEDGE
    beq @x
    lda k_flags
    and #F_HEDGE
    bne @x
    lda #F_HEDGE
    tsb k_flags
    lda #12
    sta k_jig
    SFX SFX_CRASH
    ldx #.loword(str_hedge)
    lda #TP_ORANGE
    jsr say
    ldx #100
    jsr add_pen
@x:
    rts

str_dentA: .byte "BUMPER TAP -150 (IT'S A BMW)", 0
str_dentB: .byte "WEE-OO! WEE-OO! DENT -150", 0
str_dentL: .byte "WRONG SIDE! BUMPER TAP -150", 0
str_hedge: .byte "INTO THE HEDGE! -100", 0

; curb, sidewalk and hydrant: you can drive over them, it just costs you
soft_hazards:
    A16
    ; rightmost corner
    lda CX
    cmp CX+2
    bcs @m1
    lda CX+2
@m1:
    cmp CX+4
    bcs @m2
    lda CX+4
@m2:
    cmp CX+6
    bcs @m3
    lda CX+6
@m3:
    sec
    sbc #CURB
    sta k_curbx
    jeq @nocurb
    jmi @nocurb
    A8
    lda k_flags
    and #F_CURB
    bne @walk
    lda #F_CURB
    tsb k_flags
    lda #6
    sta k_jig
    SFX SFX_STEP
    ldx #.loword(str_curb)
    lda #TP_YELLOW
    jsr say
    ldx #50
    jsr add_pen
@walk:
    A16
    lda k_curbx
    cmp #7
    A8
    bcc @hyd
    lda k_flags
    and #F_WALK
    bne @hyd
    lda #F_WALK
    tsb k_flags
    lda #10
    sta k_jig
    SFX SFX_STEP
    ldx #.loword(str_walk)
    lda #TP_ORANGE
    jsr say
    ldx #100
    jsr add_pen
@hyd:
    ; hydrant at (HYD_X, k_hyd): any corner within 5 x 6
    lda k_flags
    and #F_HYD
    bne @x
    ldx #$0000
@h:
    A16
    lda CX,x
    sec
    sbc #HYD_X
    bpl @h1
    eor #$FFFF
    inc a
@h1:
    cmp #5
    bcs @hn
    lda CY,x
    sec
    sbc k_hyd
    bpl @h2
    eor #$FFFF
    inc a
@h2:
    cmp #6
    bcs @hn
    A8
    lda #F_HYD
    tsb k_flags
    lda #1
    sta k_geyser
    lda #10
    sta k_jig
    SFX SFX_SPLASH
    ldx #.loword(str_hyd)
    lda #TP_CYAN
    jsr say
    ldx #200
    jmp add_pen
@hn:
    A8
    inx
    inx
    cpx #8
    bne @h
@x:
    rts
@nocurb:
    .a16
    A8
    rts

str_curb: .byte "CURB CHECK! SCRAAAPE -50", 0
str_walk: .byte "UP ON THE SIDEWALK! -100", 0
str_hyd:  .byte "HYDRANT! SPLOOSH! -200", 0

; ------------------------------------------------------------------
; the cyclist (spots 2 and 3): on your way up to the line (or once you
; start backing up), the bell rings and she appears at the bottom of the
; lane, riding up at 1 to 1.5 px/f (late enough that a first-timer is
; stopped on the line, waiting, by the time she comes by). Your nose swings out across her line as
; soon as you back in, so the coach has you wait on the line until she's by.
BIKE_RING = 40              ; the bell: 40-63 px short of the line
bike_update:
    lda k_bst
    bne @act
    rts
@act:
    cmp #1
    bne @ride
    lda k_flags
    and #F_REV
    bne @go
    A16
    lda k_ay
    xba
    and #$00FF
    sec
    sbc k_tgt
    cmp k_bring
    A8
    bcs @x
@go:
    lda #2
    sta k_bst
    ldx #BIKE_X
    stx k_bx
    ldx #(236 * 256)
    stx k_by
    SFX SFX_BELL
    ldx #.loword(str_bell)
    lda #TP_CYAN
    jsr say
@x:
    rts
@ride:
    cmp #2
    bne @x
    A16
    lda k_by
    sec
    sbc k_bspd
    sta k_by
    cmp #(16 * 256)
    A8
    bcs @hit
    lda #3
    sta k_bst
    rts
@hit:
    lda k_wob
    beq @w
    dec k_wob
@w:
    lda k_flags
    and #F_BIKE
    bne @x
    ; her front wheel / back wheel inside the car, or a corner on her line
    ldx k_bx
    A16
    lda k_by
    xba
    and #$00FF
    sec
    sbc #8
    tay
    A8
    jsr pt_in_car
    bcs @clip
    ldx k_bx
    A16
    lda k_by
    xba
    and #$00FF
    clc
    adc #6
    tay
    A8
    jsr pt_in_car
    bcs @clip
    ldx #$0000
@c:
    A16
    lda CX,x
    sec
    sbc #(BIKE_X - 4)
    cmp #9
    bcs @cn
    lda k_by
    xba
    and #$00FF
    sec
    sbc CY,x
    clc
    adc #10
    cmp #21
    bcc @clip16
@cn:
    A8
    inx
    inx
    cpx #8
    bne @c
    jmp bike_shave
@clip16:
    A8
@clip:
    lda #F_BIKE
    tsb k_flags
    lda #40
    sta k_wob
    SFX SFX_HORN
    ldx #.loword(str_bike)
    lda #TP_RED
    jsr say
    ldx #150
    jmp add_pen

; no clip this frame: how close did the car come? A corner level with her
; (within SHAVE_DY px) while the car is moving and turned in, 1 to SHAVE_PX px
; clear of her line, is a BIKE SHAVE: called out once she's past the nose,
; paid with the spot's style if you park
SHAVE_PX = 3
SHAVE_DY = 18               ; px: a corner this close behind or beside her counts as level
bike_shave:
    lda k_shave+1
    jne @x                      ; already called
    A16
    lda k_v
    A8
    beq @past
    lda k_ang
    beq @past
    ldx #$0000
@c:
    A16
    lda k_by
    xba
    and #$00FF
    sec
    sbc CY,x
    clc
    adc #SHAVE_DY
    cmp #(SHAVE_DY * 2 + 1)      ; level with her: |dy| <= SHAVE_DY
    bcs @n
    lda CX,x
    sec
    sbc #(BIKE_X + 4)
    bmi @n
    cmp k_shave
    bcs @n
    sta k_shave
@n:
    A8
    inx
    inx
    cpx #8
    bne @c
@past:
    lda k_shave
    cmp #(SHAVE_PX + 1)
    bcs @x
    ; called once she's clear past your nose: her back wheel 11 px above
    ; your topmost corner (out of reach of the clip test)
    A16
    lda CY
    cmp CY+2
    bcc @y1
    lda CY+2
@y1:
    cmp CY+4
    bcc @y2
    lda CY+4
@y2:
    cmp CY+6
    bcc @y3
    lda CY+6
@y3:
    sta k_t0
    lda k_by
    xba
    and #$00FF
    clc
    adc #11
    cmp k_t0
    A8
    bcs @x
    lda #1
    sta k_shave+1
    jsl trick_seen
    SFX SFX_CHEER
    ldx #.loword(str_shave)
    lda #TP_GREEN
    jmp say
@x:
    rts

str_shave: .byte "BIKE SHAVE! SHE DIDN'T BLINK", 0
str_bell: .byte "DING DING! BIKE COMING UP!", 0
str_bike: .byte "HEY! WATCH THE BIKE LANE -150", 0

; the meter maid walks down the sidewalk in the last 10 seconds
maid_update:
    lda k_maid
    bne @walk
    A16
    lda k_clock
    cmp #600
    A8
    bcs @x
    lda #1
    sta k_maid
    ldx #240
    stx k_ex
    ldx #40
    stx k_ey
    SFX SFX_WHISTLE
    ldx #.loword(str_maid)
    lda #TP_ORANGE
    jsr say
@x:
    rts
@walk:
    lda k_clock
    and #$03
    bne @x
    A16
    lda k_ay
    xba
    and #$00FF
    sec
    sbc #(13 + 8)
    cmp k_ey
    bcc @w16
    beq @w16
    inc k_ey
@w16:
    A8
    rts

str_maid: .byte "METER MAID! 10 SECONDS!", 0

; ------------------------------------------------------------------
; where the car is relative to the spot, and the grades A would give now
;   k_gap = curb - rightmost corner, k_room = min(front, rear) clearance,
;   k_ang = |heading|, k_inspot, grades k_gc / k_ga / k_gs
spot_eval:
    A16
    lda CX
    cmp CX+2
    bcs @m1
    lda CX+2
@m1:
    cmp CX+4
    bcs @m2
    lda CX+4
@m2:
    cmp CX+6
    bcs @m3
    lda CX+6
@m3:
    eor #$FFFF
    sec
    adc #CURB
    sta k_gap
    ; front clearance = top corner - A_REAR, rear = btop - bottom corner
    lda CY
    cmp CY+2
    bcc @n1
    lda CY+2
@n1:
    cmp CY+4
    bcc @n2
    lda CY+4
@n2:
    cmp CY+6
    bcc @n3
    lda CY+6
@n3:
    sec
    sbc #A_REAR
    sta k_tmp+14                ; front clearance
    sta k_front
    lda CY
    cmp CY+2
    bcs @x1
    lda CY+2
@x1:
    cmp CY+4
    bcs @x2
    lda CY+4
@x2:
    cmp CY+6
    bcs @x3
    lda CY+6
@x3:
    eor #$FFFF
    sec
    adc k_btop                  ; rear clearance
    sta k_rear
    cmp k_tmp+14
    bmi @r
    lda k_tmp+14
@r:
    sta k_room
    ; heading
    lda k_th
    bpl @a
    eor #$FFFF
    inc a
@a:
    xba
    and #$00FF
    sta k_ang
    ; in the spot: between the cars (centre y), and the gap at most 26 px
    lda CY
    clc
    adc CY+2
    clc
    adc CY+4
    clc
    adc CY+6
    lsr a
    lsr a                       ; centre y
    cmp #A_REAR
    bcc @out
    cmp k_btop
    bcs @out
    lda k_gap
    bmi @in                     ; over the curb counts
    cmp #27
    bcs @out
@in:
    A8
    lda #1
    sta k_inspot
    ; curb: 0-2 great, 3-5 good, 6-15 ok, more = ticket; over by 1-6 ok, 7+ ticket
    A16
    lda k_gap
    bmi @over
    ldy #0
    cmp #3
    bcc @gc
    iny
    cmp #6
    bcc @gc
    iny
    cmp #16
    bcc @gc
    iny
    bra @gc
@over:
    ldy #2
    cmp #($10000 - 6)
    bcs @gc
    ldy #3
@gc:
    sty k_gc
    ; angle (1/256 turn): 0-1 great, 2-3 good, 4-8 ok, 9+ crooked (13 degrees)
    lda k_ang
    ldy #0
    cmp #2
    bcc @ga
    iny
    cmp #4
    bcc @ga
    iny
    cmp #9
    bcc @ga
    iny
@ga:
    sty k_ga
    ; space: room to get out at both ends: 8+ great, 4+ good, else ok
    lda k_room
    ldy #2
    bmi @gs
    cmp #4
    bcc @gs
    dey
    cmp #8
    bcc @gs
    dey
@gs:
    sty k_gs
    A8
    rts
@out:
    A8
    stz k_inspot
    lda #4
    sta k_gc
    sta k_ga
    sta k_gs
    rts

; ------------------------------------------------------------------
; the coach line: what to do next (shown when no callout is up)
LATE_GAP = -4               ; a swing ending further over the curb than this: too late
EASE_AIM = 8                ; pull out until the swing would end this far from the curb
TGT_Y = A_REAR + 3          ; ideal rear axle y before backing in (bumpers level);
                            ; the tight spot wants it 4 px further up (k_tgt)
; coach: NOW! when the predicted gap is under 7 + 3/8 of your reaction time
; (12 px for a quarter second), KEEP HOLDING 10 px before that (react_time),
; and only once the swing in will clear the car ahead (bmw_clear). Stuck
; against something, it says how to get out.
coach:
    lda k_stuck
    cmp #12
    bcc @free
    bne @stk
    stz k_msgt                  ; cut the bump's joke short: this matters more
@stk:
    ldx #.loword(co_backup)     ; blocked going forward: back off
    lda k_stuckv
    bpl @set0
    ldx #.loword(co_pullup)     ; blocked backing up: pull away
    lda k_hit
    and #H_CARA
    beq @set0
    lda k_stuckn
    beq @set0
    ldx #.loword(co_pinned)     ; nose swung onto the BMW: straight back
@set0:
    jmp @set
@free:
    ; the cyclist coming up the lane, not yet past your nose: wait for her
    ; (once you're on the line, or backing up)
    lda k_bst
    cmp #2
    bne @nobike
    lda k_flags
    and #F_REV
    bne @bk
    A16
    lda k_ay
    xba
    and #$00FF
    sec
    sbc k_tgt
    bmi @bk16
    cmp #9
    bcc @bk16
    ldx k_v                     ; stopped short of it, but near enough that
    bne @nob16                  ; the coach would say BACK IN: wait too
    cmp k_short
    beq @bk16
    bcs @nob16
@bk16:
    A8
@bk:
    A16
    lda k_by
    xba
    and #$00FF
    clc
    adc #6
    cmp CY+4                    ; front-left corner
    A8
    bcc @nobike
    ldx #.loword(co_wait)
    jmp @set
@nob16:
    A8
@nobike:
    ; wandered across the street with the nose swung round: straighten first
    A16
    lda k_ax
    xba
    and #$00FF
    cmp #(LANE_X - 14)
    A8
    bcs @inlane
    lda k_ang
    cmp #4
    bcc @inlane
    ldx #.loword(co_strl)       ; nose left: reverse on left lock
    lda k_th+1
    bmi @set1
    ldx #.loword(co_strr)
@set1:
    jmp @set
@inlane:
    ; too late to swing in: stop (k_late 1), pull out a bit (2), stop (3),
    ; and only then swing again. Each line stays up till it's done: no
    ; flipping back to SWING IN on the way
    lda k_late
    beq @nolate
    lda k_ang
    cmp #4
    bcs @lf1
@lfclr:
    stz k_late                  ; straight anyway: the usual lines
    bra @nolate
@lf1:
    A16
    lda k_v
    A8
    tay                         ; (Y: the speed's sign, for the branches below)
    lda k_late
    cmp #2
    beq @lf2
    bcs @lf3
    ; 1: TOO LATE! LET GO OF THE PAD, till it stops
    cpy #$0000
    bmi @lfrev
    lda #2
    sta k_late
@lf2:
    ; 2: HOLD UP+RIGHT: PULL OUT A BIT, till what you'll still roll puts the
    ; swing EASE_AIM out (then 3)
    jsr room_ahead              ; no room to pull out: swing in and take the curb
    bcc @lfclr
    cpy #$0000
    beq @lfstop
    bmi @lfout
    jmp @easing
@lfstop:
    jsr gap_pred
    eor #$80
    cmp #($80 + EASE_AIM - 3)
    bcs @lfclr                  ; out far enough already: NOW! from here
@lfout:
    ldx #.loword(co_easeout)
    jmp @set
@lf3:
    ; 3: ENOUGH! LET GO OF THE PAD, till it stops
    cpy #$0000
    beq @lfclr
    ldx #.loword(co_easestop)
    jmp @set
@lfrev:
    ldx #.loword(co_late)
    jmp @set
@nolate:
    ; swung past straight (nose into the curb) after backing in: forward and
    ; left lock brings the nose back out; let go before it's straight
    lda k_flags
    and #F_REV
    beq @noflip
    lda k_th+1
    bmi @noflip
    cmp #4
    bcc @noflip
    jsr th_pred
    bmi @nstop
    cmp #2
    bcc @nstop
    ldx #.loword(co_nosein)
    jmp @set
@nstop:
    ldx #.loword(co_stop)
    jmp @set
@noflip:
    lda k_inspot
    beq @notin
    lda k_ang                   ; still swinging in: the turning lines
    cmp #9
    bcs @notin
    A16
    lda k_v
    A8
    beq @stopped
    ldx #.loword(co_stop)
    jmp @set
@stopped:
    lda k_gc
    cmp #3
    bcs @fixs
    lda k_ga
    cmp #3
    bcs @fixs
    ldx #.loword(co_park)
    jmp @set
@fixs:
    ldx #.loword(co_fix)
    lda k_gap+1
    bpl @fset
    ldx #.loword(co_fixin)      ; over the curb, not out from it
@fset:
    jmp @set
@notin:
    ; nearly straight with the wheel not yet counter-steered: line it up
    lda k_ang
    cmp #4
    jcs @turning
    lda k_notch
    jmi @turning
    A16
    lda k_ay
    xba
    and #$00FF
    sec
    sbc k_tgt                   ; px still to go (signed: + short of the line)
    sta k_tmp+14
    bpl @ahead
    clc
    adc k_over
    bmi @far                    ; more than k_over px past the line
@ahead:
    lda k_v
    beq @halt16
    bmi @halt16
    ; rolling forward: LET GO OF UP once your hand's worth of travel and the
    ; braking cover what's left (and never BACK IN while still rolling on)
    lda k_tmp+14
    bmi @brake16
    lda pad
    and #PAD_UP
    beq @coast16
    jsr stop_dist
    cmp k_tmp+14
    bcs @brake16
    bra @up16
@coast16:
    ; already off the gas and rolling to a stop: no flip to GAS until it
    ; has stopped (then GAS again if that's short of the line)
    bra @brake16
@halt16:
    ; stopped (or backing): on the line, or close enough short of it
    lda k_tmp+14
    bmi @ready16
    cmp k_short
    bcc @ready16
    beq @ready16
    ; once you've started backing in, don't flip back to "pull up"
    lda k_flags
    and #F_REV
    beq @up16
    lda k_tmp+14
    cmp #20
    bcc @ready16
@up16:
    A8
    ldx #.loword(co_up)
    bra @set
@brake16:
    A8
    ldx #.loword(co_brake)
    bra @set
@far:
    A8
    lda #F_OVER                 ; overshot the line: no ONE-MOVE this spot
    tsb k_flags
    ldx #.loword(co_toofar)
    bra @set
@ready16:
    A8
    ; time how long you take to answer BACK IN (if you aren't already)
    lda k_rtst
    bne @rtx
    inc k_rtst
    stz k_rt
    A16
    lda pad
    and #PAD_DOWN
    A8
    beq @rtx
    lda #2
    sta k_rtst
@rtx:
    lda k_notch
    cmp #1
    beq @back
    ldx #.loword(co_lock)
    bra @set
@back:
    ldx #.loword(co_back)
@set:
    ; a new instruction ends a callout that has had its moment (a bump's
    ; joke mustn't hide BACK IN): new since the callout went up, not just
    ; new this frame. (The timed lines, LET GO, NOW! and STRAIGHT!, don't
    ; wait at all: a callout waits under them, msg_held)
    cpx k_saycoach
    beq @same
    lda #(MSG_T - MSG_MIN + 1)
    cmp k_msgt
    beq @same
    bcc @same
    stz k_msgt
@same:
    stx k_coach
    rts
@turning:
    lda k_notch
    jmi @counter
    ; rolling forward, nose turned in, after backing in: pulling out a bit
    ; to swing in again. LET GO once what you'll still roll puts the swing
    ; EASE_AIM px out from the curb (each px forward gains about 1.5)
    A16
    lda k_v
    A8
    beq @tv
    bmi @tv
    lda k_flags
    and #F_REV
    beq @tv
    lda k_th+1
    bpl @tv
@easing:
    A16
    lda k_front
    cmp #6
    A8
    bmi @ezs                    ; nose nearly on the car ahead: stop here
    bcs @ez
@ezs:
    jmp @ezstop
@ez:
    jsr gap_pred
    A16
    and #$00FF
    cmp #$0080
    bcc @gp
    ora #$FF00
@gp:
    sta k_tmp+16
    jsr stop_dist
    sta k_tmp+12
    lsr a
    clc
    adc k_tmp+12
    clc
    adc k_tmp+16
    bmi @eo16
    cmp #EASE_AIM
    bcc @eo16
    A8
@ezstop:
    lda k_late                  ; (pulling out after TOO LATE: ENOUGH stays up)
    beq @ezs2
    lda #3
    sta k_late
@ezs2:
    ldx #.loword(co_easestop)
    jmp @set
@eo16:
    A8
    ldx #.loword(co_easeout)
    jmp @set
@tv:
    ; wheel right (or centred mid-turn): back up until the gap you'll have
    ; when your hand catches up is about to close
    jsr gap_ahead
    cmp k_rdyb
    jcs @back
    cmp k_nowb
    bcc @now
    ldx #.loword(co_ready)
    jmp @set
@now:
    ; too late to swing in from here (it would end on the sidewalk): stop,
    ; pull out a bit, then swing in
    jsr gap_pred
    eor #$80
    cmp #($80 + LATE_GAP)
    bcs @nl
    jsr room_ahead              ; (no room to pull out: swing now, take the curb)
    bcs @late
@nl:
    ; NOW!, if the nose will swing clear of the car ahead once your hand gets
    ; there; if not, back straight until it will
    jsr bmw_ahead
    bcc @clr
    ldx #.loword(co_now)
    jmp @set
@clr:
    ldx #.loword(co_clear)
    jmp @set
@late:
    ldy #2                      ; stay with it till it's pulled out
    ldx #.loword(co_easeout)
    A16
    lda k_v
    A8
    bpl @lset
    dey
    ldx #.loword(co_late)
@lset:
    sty k_late
    jmp @set
@counter:
    ; swinging in on left lock, still well turned, and it'll end on the
    ; sidewalk: stop and pull out a bit
    A16
    lda k_v
    A8
    bpl @c1
    lda k_ang
    cmp #12
    bcc @c1
    jsr gap_pred
    eor #$80
    cmp #($80 + LATE_GAP - 3)   ; (the wheel is already over: no -3)
    bcs @c1
    jsr room_ahead
    bcc @c1
    lda #1
    sta k_late
    ldx #.loword(co_late)
    jmp @set
@c1:
    ; counter-steered too soon: the nose will hit the car ahead (still well
    ; turned: back to right lock; nearly straight: back straight past it),
    ; or (10 px or more before NOW! would have shown) it would end way out
    jsr bmw_clear
    bcs @c2
    ldx #.loword(co_clear)
    lda k_ang
    cmp #16
    bcc @cset
    ldx #.loword(co_early)
@cset:
    jmp @set
@c2:
    lda k_ang
    cmp #16
    bcc @cs
    jsr gap_pred
    eor #$80
    sec
    sbc #10
    bcc @cs
    cmp k_nowb
    bcc @cs
@early:
    ldx #.loword(co_early)
    jmp @set
@cs:
    ; counter-steering: swing in until you'll be straight by the time you
    ; let go (heading + turn rate x your reaction time)
    jsr th_pred
    bmi @swing
    ldx #.loword(co_stop)
    jmp @set
@swing:
    ldx #.loword(co_swing)
    jmp @set

; A16 = px the car still rolls forward if the coach says LET GO now: your
; reaction (still speeding up if you're on the gas), plus a margin and the
; braking: v x (react + k_lgpad) / 128. A first-timer stops a little short
; of the line rather than past it.
stop_dist:
    A16
    lda pad
    and #PAD_UP
    beq @coast
    lda k_react
    and #$00FF
    asl a
    clc
    adc k_v                     ; about the speed you'll have by then
    cmp #VF_MAX
    bcc @v
    lda #VF_MAX
    bra @v
@coast:
    lda k_v
@v:
    A8
    sta WRMPYA
    lda k_react
    clc
    adc k_lgpad
    sta WRMPYB
    nop
    nop
    nop
    nop
    A16
    lda RDMPYL
    asl a
    xba
    and #$00FF
    rts

; A8 = high byte of (heading + this frame's turn x your reaction time), with
TH_PAD = 4
; its flags: where the car will be pointing when your hand catches up
.a8
th_pred:
    jsr rs_now
    clc
    adc #TH_PAD                 ; and the wheel centring, the braking
; A8 = frames: the same, that many frames ahead
th_ahead:
    sta k_t1
    A16
    lda k_th
    sec
    sbc k_oth                   ; turn this frame (signed)
    sta k_tmp+12
    bpl @p
    eor #$FFFF
    inc a
@p:
    cmp #256
    bcc @ok
    lda #255
@ok:
    A8
    sta WRMPYA
    lda k_t1
    sta WRMPYB
    nop
    nop
    nop
    nop
    A16
    lda RDMPYL
    bit k_tmp+12
    bpl @add
    eor #$FFFF
    inc a
@add:
    clc
    adc k_th
    A8
    xba
    rts

; carry set = swinging in on left lock from here clears the car ahead. The
; turn centre is C = axle - 32 (cos, sin); the front corner swings round it
; 54 px out, so C must be about that far from the BMW's rear corner: 53 px.
; bmw_clear judges the pose the car is in now (it has counter-steered);
; bmw_ahead the pose it will be in on right lock when a hand that's 3/4 of
; your reaction away rolls to DOWN+LEFT (NOW! is said that early), so a
; slow hand doesn't get MIND THE BMW for a swing its NOW! would clear.
; From heading t to t' on right lock the axle moves 32 (c - c', s - s'), so
; C' = axle + (32 c - 64 c', 32 s - 64 s') (bmw_at: k_t0 = c', k_t1 = s')
CLEAR_R = 53
bmw_ahead:
    jsr rs_now
    inc a
    inc a
    sta k_lead
    lsr a
    lsr a
    eor #$FF
    sec
    adc k_lead                  ; 3/4 of it
    jsr th_ahead
    pha
    jsl cos8
    sta k_t0
    pla
    jsl sin8
    sta k_t1
    bra bmw_at
bmw_clear:
    lda k_c
    sta k_t0
    lda k_s
    sta k_t1
bmw_at:
    lda #CLEAR_R
    ldx k_coach                 ; (once NOW! is up, a pixel's wobble won't take it back)
    cpx #.loword(co_now)
    bne @r
    lda #(CLEAR_R - 2)
@r:
    sta k_cr                    ; r
    stz k_cr+1
    sta WRMPYA
    sta WRMPYB
    nop
    nop
    nop
    nop
    ldx RDMPYL
    stx k_cr2                   ; r * r
    lda k_t0
    ldy #64
    jsr smul
    .a16
    sta k_tmp+12
    A8
    lda k_c
    ldy #32
    jsr smul
    .a16
    sec
    sbc k_tmp+12
    jsr asr7
    sta k_tmp+12
    lda k_ax
    xba
    and #$00FF
    clc
    adc k_tmp+12                ; C x
    eor #$FFFF
    sec
    adc #SPOT_X0                ; dx
    jsr @sq
    bcs @yes
    sta k_tmp+14
    A8
    lda k_t1
    ldy #64
    jsr smul
    .a16
    sta k_tmp+12
    A8
    lda k_s
    ldy #32
    jsr smul
    .a16
    sec
    sbc k_tmp+12
    jsr asr7
    sta k_tmp+12
    lda k_ay
    xba
    and #$00FF
    clc
    adc k_tmp+12                ; C y
    eor #$FFFF
    sec
    adc #A_REAR                 ; dy
    jsr @sq
    bcs @yes
    clc
    adc k_tmp+14
    cmp k_cr2
    A8
    rts
@yes:
    A8
    sec
    rts
; A16 = d -> A16 = d * d, carry set when |d| is CLEAR_R or more on its own
@sq:
    .a16
    bpl @sp
    eor #$FFFF
    inc a
@sp:
    cmp k_cr
    bcs @sx
    A8
    sta WRMPYA
    sta WRMPYB
    nop
    nop
    nop
    nop
    A16
    lda RDMPYL
    clc
@sx:
    rts
.a8

; the instructor learns your timing: frames from LET GO OF UP to letting go,
; and from BACK IN to DOWN, averaged in as they come. NOW! goes up when the
; gap you'd end up with once your hand gets there is NOW_AIM.
NOW_AIM = 6
NOW_AIM1 = 8                ; (before it has timed your answer to a NOW! or a STRAIGHT!)
react_time:
    lda k_lgo
    cmp #1
    bne @bk
    inc k_lgot
    A16
    lda pad
    and #PAD_UP
    A8
    bne @lgw
    lda k_lgot
    jsr fold_react
    lda #2
    sta k_lgo
    bra @bk
@lgw:
    lda k_lgot
    cmp #60
    bcc @bk
    lda #2                      ; no answer: stop timing
    sta k_lgo
@bk:
    lda k_rtst
    cmp #1
    bne @thr
    inc k_rt
    A16
    lda pad
    and #PAD_DOWN
    A8
    bne @ans
    lda k_rt
    cmp #60
    bcc @thr
    lda #2                      ; no answer: stop timing
    sta k_rtst
    bra @thr
@ans:
    lda #2
    sta k_rtst
    lda k_rt
    jsr fold_react
@thr:
    ; the steering cues: NOW! answered by rolling to LEFT, STRAIGHT! by
    ; letting go of the d-pad
    lda k_nst
    beq @aim
    inc k_ntm
    cmp #1
    bne @st
    lda k_notch
    bmi @sans
    bra @sw
@st:
    A16
    lda pad
    and #(PAD_UP | PAD_DOWN | PAD_LEFT | PAD_RIGHT)
    A8
    beq @sans
@sw:
    lda k_ntm
    cmp #60
    bcc @aim
    stz k_nst                   ; no answer: stop timing
    bra @aim
@sans:
    ; the first answer is your steering reaction; after that a slower one
    ; counts at once, a quicker one half (late costs more than early)
    stz k_nst
    lda k_ntm
    jsr clamp_react
    ldy k_reacts
    beq @set
    cmp k_reacts
    bcs @set
    adc k_reacts
    lsr a
@set:
    sta k_reacts
@aim:
    ; NOW! when the gap you'll get (gap_ahead) is NOW_AIM, KEEP HOLDING 10 px
    ; before; wider until the coach has seen you answer a steering cue
    lda #($80 + NOW_AIM)
    ldy k_reacts
    bne @aimk
    lda #($80 + NOW_AIM1)
@aimk:
    sta k_nowb
    clc
    adc #10
    sta k_rdyb
    rts

; A = a measured answer (frames): average it into k_react (6..40)
fold_react:
    jsr clamp_react
    clc
    adc k_react
    lsr a
    sta k_react
    rts

clamp_react:
    cmp #6
    bcs @lo
    lda #6
@lo:
    cmp #40
    bcc @hi
    lda #40
@hi:
    rts

; A8 = your reaction to the steering cues, as far as the coach knows it:
; before it has timed one, your pedal answers, but at least RS_MIN (a pedal
; cue is easy to see coming; NOW! isn't)
RS_MIN = 18
rs_now:
    lda k_reacts
    bne @x
    lda k_react
    cmp #RS_MIN
    bcs @x
    lda #RS_MIN
@x:
    rts

; A8 = the curb gap you'd end up with if your hand rolls to DOWN+LEFT when
; it catches up (react + 2 frames from now), biased by $80 (clamped). Backing
; on right lock the axle circles round, so from heading t to t' the gap
; closes by 64 (cos t - cos t') px: gap_pred - (c - c') / 2 (c scaled 127).
gap_ahead:
    jsr gap_pred
    A16
    and #$00FF
    cmp #$0080
    bcc @p
    ora #$FF00
@p:
    sta k_t0
    A8
    jsr rs_now
    inc a
    inc a
    jsr th_ahead
    jsl cos8
    A16
    and #$00FF
    cmp #$0080
    bcc @c
    ora #$FF00
@c:
    sta k_t1                    ; c'
    lda k_c
    and #$00FF
    cmp #$0080
    bcc @c0
    ora #$FF00
@c0:
    sec
    sbc k_t1                    ; c - c'
    cmp #$8000
    ror a
    eor #$FFFF
    sec
    adc k_t0                    ; gap - (c - c') / 2
    bmi @neg
    cmp #$007F
    bcc @ok
    lda #$007F
    bra @ok
@neg:
    cmp #$FF80
    bcs @ok
    lda #$FF80
@ok:
    A8
    eor #$80
    rts

; carry set = room ahead to pull out a bit (ROOM_PX clear of the car ahead)
ROOM_PX = 12
room_ahead:
    A16
    lda k_front
    bmi @no
    cmp #ROOM_PX
    A8
    rts
@no:
    A8
    clc
    rts

; A8 = predicted curb gap if you counter-steer now (signed, clamped to -128..127)
;   = curb - 11 - axle x - 32 (1 - cos) - 3 for the wheel's travel
gap_pred:
    lda k_c
    eor #$FF
    sec
    adc #127                    ; 127 - cos
    lsr a
    lsr a
    A16
    and #$00FF
    sta k_tmp+14
    lda k_ax
    xba
    and #$00FF
    clc
    adc k_tmp+14
    eor #$FFFF
    sec
    adc #(CURB - 11 - 3)
    bmi @neg
    cmp #127
    bcc @ok
    lda #127
    bra @ok
@neg:
    cmp #$FF80
    bcs @ok
    lda #$FF80
@ok:
    A8
    cmp #$00                    ; flags for the caller
    rts

co_up:     .byte "GAS ", TXT_ARROW_U + $20, ": REAR BUMPER TO LINE", 0
co_brake:  .byte "LET GO OF ", TXT_ARROW_U + $20, ": STOP ON THE LINE", 0
co_toofar: .byte "PAST IT! ", TXT_ARROW_D + $20, " BACK TO THE LINE", 0
co_strl:   .byte "HOLD ", TXT_ARROW_D + $20, "+", TXT_ARROW_L + $20, ": STRAIGHTEN", 0
co_strr:   .byte "HOLD ", TXT_ARROW_D + $20, "+", TXT_ARROW_R + $20, ": STRAIGHTEN", 0
co_lock:   .byte "HOLD ", TXT_ARROW_D + $20, "+", TXT_ARROW_R + $20, ": BACK IN", 0
co_back:   .byte "HOLD ", TXT_ARROW_D + $20, "+", TXT_ARROW_R + $20, ": BACK IN", 0
co_wait:   .byte "WAIT! LET THE BIKE GO BY", 0
co_ready:  .byte "KEEP HOLDING ", TXT_ARROW_D + $20, "+", TXT_ARROW_R + $20, "...", 0
co_now:    .byte "NOW! ROLL TO ", TXT_ARROW_D + $20, "+", TXT_ARROW_L + $20, 0
co_clear:  .byte "MIND THE BMW: HOLD ", TXT_ARROW_D + $20, " ONLY", 0
co_swing:  .byte "HOLD ", TXT_ARROW_D + $20, "+", TXT_ARROW_L + $20, ": SWING IN", 0
co_early:  .byte "TOO SOON! BACK TO ", TXT_ARROW_D + $20, "+", TXT_ARROW_R + $20, 0
co_stop:   .byte "STRAIGHT! LET GO OF THE PAD", 0
co_late:   .byte "EASY, CURB! LET GO OF THE PAD", 0
co_easeout: .byte "HOLD ", TXT_ARROW_U + $20, "+", TXT_ARROW_R + $20, ": PULL OUT A BIT", 0
co_easestop: .byte "ENOUGH! LET GO OF THE PAD", 0
co_park:   .byte "A: PARK IT!", 0
co_fix:    .byte "TOO FAR OUT! A = $75 TICKET", 0
co_fixin:  .byte "OVER THE CURB! A = $75 TICKET", 0
co_nosein: .byte "HOLD ", TXT_ARROW_U + $20, "+", TXT_ARROW_L + $20, ": STRAIGHTEN", 0
co_pinned: .byte "PINNED! HOLD ", TXT_ARROW_D + $20, " ONLY", 0
co_pullup: .byte "STUCK! HOLD ", TXT_ARROW_U + $20, " TO PULL AWAY", 0
co_backup: .byte "STUCK! HOLD ", TXT_ARROW_D + $20, " TO BACK OFF", 0

; k_sbase += what the three lamps pay (a red one pays 0)
grade_pts:
    lda k_gc
    asl a
    TAXB
    A16
    lda f:pts_curb,x
    clc
    adc k_sbase
    sta k_sbase
    A8
    lda k_ga
    asl a
    TAXB
    A16
    lda f:pts_ang,x
    clc
    adc k_sbase
    sta k_sbase
    A8
    lda k_gs
    asl a
    TAXB
    A16
    lda f:pts_space,x
    clc
    adc k_sbase
    sta k_sbase
    A8
    rts


; A16 = what this spot's CURB KISS pays (k_skiss px out); X = its label
kiss_pts:
    lda k_skiss
    asl a
    TAXB
    A16
    lda f:kiss_lbl,x
    pha
    lda f:kiss_tbl,x
    plx
    rts
.a8
kiss_tbl: .word KISS, KISS - 100, KISS - 200
kiss_lbl: .addr bl_kiss0, bl_kiss1, bl_kiss2

; ------------------------------------------------------------------
;  work out what this spot scores (carry set = time ran out)
park_result:
    php
    stz k_style
    lda k_inspot
    bne @in
    ; nowhere near the spot: towed
    plp
    lda #O_TOWED
    sta k_out
    inc k_towed
    stz k_streak
    ldx #$0000
    stx k_sbase
    jmp @done
@in:
    lda k_gc
    cmp #3
    bcs @ticket
    lda k_ga
    cmp #3
    bcc @parked
@ticket:
    ; half in: HALF IN 150 and the lamps that aren't red (a crooked park
    ; tight to the curb still pays its curb), and the $75 TICKET takes 75
    ; back; both the curb and the angle red: WAY OFF 50
    plp
    lda #O_TICKET
    sta k_out
    inc k_tickets
    stz k_streak
    ldx #HALF_IN
    lda k_gc
    cmp #3
    bcc @hp
    lda k_ga
    cmp #3
    bcc @hp
    ldx #WAY_OFF
@hp:
    stx k_half
    stx k_sbase
    jsr grade_pts
    ldx #TICKET
    jsr add_pen
    jmp @done
@parked:
    inc k_parked
    ; base: PARKED 200 + curb + angle + space
    ldx #PARKED
    stx k_sbase
    jsr grade_pts
    ; the outcome: all great = perfect, nothing ok = nicely done
    lda k_gc
    ora k_ga
    ora k_gs
    TAXB
    lda f:out_of_grades,x
    sta k_out
    ; just one lamp at OK: a good park, and which lamp to work on
    cmp #O_OK
    bne @og
    lda k_gc
    cmp #2
    beq @oc
    lda k_ga
    cmp #2
    beq @oa
    lda #O_OKS                  ; (only the space is left at OK)
    bra @os
@oc:
    lda k_ga
    ora k_gs
    cmp #2
    bcs @og
    lda #O_OKC
    bra @os
@oa:
    lda k_gs
    cmp #2
    bcs @og
    lda #O_OKA
@os:
    sta k_out
@og:
    plp
    bcc @style
    ; time ran out: parked, but no style
    lda #O_LATE
    sta k_out
    stz k_streak
    jmp @done
@style:
    ; ONE-MOVE: stopped on the line, backed in and never drove forward
    ; again, and touched nothing on the way
    lda k_flags
    and #(F_REV | F_FWD | F_OVER)
    cmp #F_REV
    bne @nq
    A16
    lda k_spen
    A8
    bne @nq
    inc k_onemv
    lda #$01
    tsb k_style
    A16
    lda k_sbonus
    clc
    adc #ONE_MOVE
    sta k_sbonus
    A8
@nq:
    ; NONSTOP / SMOOTH: the car hardly stood still from the moment it moved
    ; off to A (no stop on the line, no wait, A as it stops)
    jsl flow_pts
    ; BIKE SHAVE: backed in right behind the cyclist without clipping her
    lda k_shave+1
    beq @nsh
    lda #$40
    tsb k_style
    A16
    lda k_sbonus
    clc
    adc #SHAVE
    sta k_sbonus
    A8
@nsh:
    ; DEAD CENTRE: the same room ahead and behind, give or take a pixel
    A16
    lda k_front
    sec
    sbc k_rear
    inc a
    cmp #3
    A8
    bcs @nc
    lda #$20
    tsb k_style
    A16
    lda k_sbonus
    clc
    adc #CENTRE
    sta k_sbonus
    A8
@nc:
    ; TIME LEFT: 10 a second still on the clock, to the tenth the HUD
    ; shows (1 a 6 frames): TIME 22.5 pays +225
    A16
    lda k_clock
    sta tmp0
    A8
    lda #6
    jsl div16
    A16
    lda tmp0
    sta k_stime
    beq @nt16
    clc
    adc k_sbonus
    sta k_sbonus
    A8
    lda #$02
    tsb k_style
    bra @nk
@nt16:
    A8
@nk:
    ; ZERO ANGLE: straight to half a degree (the GREAT lamp allows three)
    A16
    lda k_th
    bpl @za
    eor #$FFFF
    inc a
@za:
    cmp #ZERO_TH
    A8
    bcs @nz
    lda #$04
    tsb k_style
    A16
    lda k_sbonus
    clc
    adc #ZERO
    sta k_sbonus
    A8
@nz:
    ; CURB KISS: within 2 px of the curb without ever touching it, paid by
    ; the pixel: 0 px 300, 1 px 200, 2 px 100
    lda k_flags
    and #F_CURB
    bne @streak
    A16
    lda k_gap
    cmp #3
    A8
    bcs @streak
    sta k_skiss
    inc k_kisses
    lda #$08
    tsb k_style
    jsr kiss_pts
    A16
    clc
    adc k_sbonus
    sta k_sbonus
    A8
@streak:
    ; PERFECT x2 / x3: all-GREAT spots in a row
    lda k_out
    beq @perfect
    stz k_streak
    bra @done
@perfect:
    inc k_streak
    lda k_streak
    dec a
    beq @done
    ; 400 per perfect before this one
    A16
    and #$00FF
    tax
    lda #$0000
@sm:
    clc
    adc #STREAK
    dex
    bne @sm
    sta k_sstrk
    clc
    adc k_sbonus
    sta k_sbonus
    A8
    lda #$10
    tsb k_style
@done:
    ; bank it (and its style, by source, for the card)
    jsl style_bank
    A16
    lda k_sbase
    clc
    adc k_sbonus
    sec
    sbc k_spen
    sta k_last
    lda k_base
    clc
    adc k_sbase
    sta k_base
    lda k_bonus
    clc
    adc k_sbonus
    sta k_bonus
    lda k_pen
    clc
    adc k_spen
    sta k_pen
    lda k_spen
    sta k_lpen
    stz k_spen
    stz k_sbase
    stz k_sbonus
    stz k_v
    A8
    stz k_anim
    stz k_anim+1
    lda #PH_ANIM
    sta k_phase
    lda #$FF
    sta k_bst                   ; no more cyclist
    stz k_bst+1
    ; the officer / tow truck
    lda k_out
    cmp #O_TOWED
    bne @nt
    ldx #$FFD0                  ; the truck comes down from the top
    stx k_ey
    bra @msg
@nt:
    cmp #O_TICKET
    bne @msg
    lda k_maid
    bne @msg                    ; she's already on her way
    ldx #240
    stx k_ex
    ldx #24
    stx k_ey
@msg:
    jmp outcome_message

out_of_grades: .byte O_PERFECT, O_NICE, O_OK, O_OK
PARKED   = 200
HALF_IN  = 150
WAY_OFF  = 50                   ; half in with the curb and angle lamps both red
CENTRE   = 100
TICKET   = 75
ONE_MOVE = 150
KISS     = 300                  ; CURB KISS at 0 px; 100 less a pixel out
ZERO     = 150                  ; ZERO ANGLE
ZERO_TH  = $0060                ; |heading| under this (half a degree)
SHAVE    = 200                  ; BIKE SHAVE (the coach never mentions it)
NONSTOP  = 300                  ; stood still at most NONSTOP_F frames, moving off to A
SMOOTH   = 150                  ;   ... at most SMOOTH_F
NONSTOP_F = 10
SMOOTH_F = 20
STREAK   = 400                  ; PERFECT x2 +400, x3 +800
pts_curb:  .word 300, 150, 50, 0, 0
pts_ang:   .word 200, 100, 40, 0, 0
pts_space: .word 100, 60, 30, 0, 0


outcome_message:
    lda k_out
    asl a
    TAXB
    A16
    lda f:out_msgs,x
    tax
    A8
    lda k_out
    TAYB
    lda out_tp,y
    ldy k_asleep
    beq @say
    ldx #.loword(str_asleep)
@say:
    jsr say
    lda #250
    sta k_msgt
    ; sound
    lda k_out
    cmp #O_NICE
    bcs @nc
    SFX SFX_CHEER
    rts
@nc:
    cmp #O_TICKET
    bne @nt
    SFX SFX_WHISTLE
    rts
@nt:
    cmp #O_TOWED
    bne @nn
    SFX SFX_GROAN
    rts
@nn:
    SFX SFX_COIN
    rts

out_msgs:
    .addr om0, om1, om2, om3, om4, om5, om6, om7, om8
out_tp:
    .byte TP_GREEN, TP_GREEN, TP_WHITE, TP_ORANGE, TP_RED, TP_YELLOW, TP_GREEN, TP_GREEN, TP_GREEN
om0: .byte "PERFECT PARK! GREEN P PRO!", 0
om1: .byte "NICELY DONE.", 0
om2: .byte "PARKED. IT'LL DO.", 0
om3: .byte "HALF IN. $75 TICKET!", 0
om4: .byte "TOWED! SEE YA AT THE LOT", 0
om5: .byte "TIME! IT'LL DO, I GUESS.", 0
om6: .byte "GOOD PARK! NEXT: HUG CURB", 0
om7: .byte "GOOD PARK! NEXT: STRAIGHTER", 0
om8: .byte "GOOD PARK! NEXT: CENTRE IT", 0
str_asleep: .byte "ASLEEP AT THE WHEEL? TOWED!", 0

; ------------------------------------------------------------------
; the result of the spot: animation, the breakdown box, then the next spot
ph_anim:
    A16
    inc k_anim
    A8
    lda k_out
    cmp #O_TICKET
    bne @nt
    jsr anim_ticket
    bra @t
@nt:
    cmp #O_TOWED
    bne @t
    jsr anim_towed
@t:
    A16
    lda k_anim
    cmp #24
    bne @nb
    A8
    jsl result_box
    A16
@nb:
    lda k_anim
    sec
    sbc #26
    bcc @ns
    lsr a
    bcs @ns
    cmp #24
    bcs @ns
    A8
    jsl box_step
    A16
@ns:
    ; A moves on once the box has been up a moment; otherwise ~4 s
    lda k_anim
    cmp #240
    bcs @next16
    cmp #80
    A8
    bcc @x
    bne @ka
    ; the box is all up: say what A does (it moves on by itself too)
    lda k_spot
    asl a
    TAXB
    A16
    lda f:next_msgs,x
    tax
    A8
    lda k_asleep
    beq @nm
    ldx #.loword(str_nx3)
@nm:
    lda #TP_WHITE
    jsr say
    lda #200
    sta k_msgt
@ka:
    A16
    lda pad_new
    and #(PAD_A | PAD_B)
    A8
    beq @x
@next:
    jsr restore_car_pals
    stz k_alarmt
    stz k_msgt
    lda k_asleep
    bne @done                   ; towed for idling: that's the run
    lda k_spot
    cmp #2
    bcs @done
    jmp next_spot
@done:
    jsr clear_box
    lda #PH_DONE
    sta k_phase
@x:
    rts

@next16:
    A8
    bra @next

next_msgs: .addr str_nx1, str_nx2, str_nx3
str_nx1: .byte "A: ON TO SPOT 2", 0
str_nx2: .byte "A: ON TO SPOT 3", 0
str_nx3: .byte "A: SEE YOUR SCORE", 0

; fade down, set up the next spot (HUD and all) in the dark, fade back up.
; No pausing in the dark: START waits for the picture.
next_spot:
    lda #15
@out:
    sta inidisp_sh
    jsl wait_frame
    lda inidisp_sh
    sec
    sbc #3
    bpl @out
    stz inidisp_sh
    jsr clear_box
    inc k_spot
    jsr spot_setup
    jsr pk_draw
    jsr hud_top
    jsr hud_lamps
    jsr hud_msg
    jsl wait_frame
    lda #3
@in:
    sta inidisp_sh
    jsl wait_frame
    lda inidisp_sh
    clc
    adc #3
    cmp #16
    bcc @in
    lda #15
    sta inidisp_sh
    lda k_psave
    sta pause_ok
    rts

; the bumped car's alarm: flash its body colours, honk
anim_alarm:
    lda k_alarmt
    and #$1F
    cmp #$1F
    bne @nh
    SFX SFX_HORN
@nh:
    lda k_alarm
    cmp #1
    bne @b
    lda k_palA
    bra @p
@b:
    lda k_palB
@p:
    ; body colours 2-4 of that palette (CGRAM 128 + pal*16 + 2..4)
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    clc
    adc #(256 + 4)
    tax
    A8
    lda k_alarmt
    and #$08
    beq @off
    A16
    lda #$7FFF
    sta pal_buf,x
    lda #$001F
    sta pal_buf+2,x
    sta pal_buf+4,x
    A8
    lda #$01
    sta pal_dirty
    rts
@off:
    jmp restore_car_pals

; reload sprite palettes 1-3 (undo any alarm flashing)
restore_car_pals:
    PLOAD 144, parking_spr_pal, 48
    rts

; parking enforcement strolls down the sidewalk and leaves a ticket
anim_ticket:
    A16
    lda k_ay
    xba
    and #$00FF
    sec
    sbc #13
    cmp k_ey
    bmi @there
    beq @there
    inc k_ey
    inc k_ey
    A8
    rts
@there:
    A8
    lda k_maid
    cmp #2
    beq @x
    lda #2
    sta k_maid
    SFX SFX_TICK
@x:
    rts

; the tow truck comes down the lane, hooks the car and hauls it away
anim_towed:
    A16
    lda k_anim
    cmp #90
    bcs @haul
    lda k_ay
    xba
    and #$00FF
    sec
    sbc #(FRONT + 24)
    cmp k_ey
    bmi @wait
    beq @wait
    inc k_ey
    inc k_ey
@wait:
    A8
    rts
@haul:
    .a16
    lda k_ay
    sec
    sbc #$0200
    bcs @h
    lda #$0000
@h:
    sta k_ay
    dec k_ey
    dec k_ey
    lda k_anim
    cmp #91
    A8
    bne @x
    SFX SFX_HORN
@x:
    rts

; ------------------------------------------------------------------
; the breakdown box on the left (over the houses and the far lane): every
; line the result card will add up, base in white, style in green,
; penalties in red, then this spot's net:
;   NICELY DONE. / PARKED +200 / CURB GREAT +300 / ANGLE GOOD +100 /
;   SPACE OK +30 / ONE-MOVE +150 / 21S LEFT +210 / DENT -150 / SPOT +840
BOX_COL = 0
BOX_ROW = 6
BOX_W   = 18
NUM_COL = BOX_W - 2             ; the numbers end in this column

; The result box's code lives in bank $80 (jsl result_box / box_step); its
; strings and tables stay here in EVENTS2, read with DB = $83 as before.
.segment "CODE"               ; (bank $80: EVENTS2 is full)
result_box:
    ; no pausing over the box (its rows are spread out; the PAUSED box's
    ; wouldn't be): START is back with the next spot
    lda pause_ok
    beq @np
    sta k_psave
    stz pause_ok
@np:
    ; count the lines, draw the box, then draw them
    stz k_bmode
    stz k_bcount
    jsr box_items
    lda k_bcount
    clc
    adc #4                      ; borders, title, total
    xba
    lda #BOX_W
    A16
    sta tmp1
    A8
    ldx #(BOX_ROW*32 + BOX_COL)
    lda #$20
    jsl txt_box
    jsr box_spread
    lda #TXT_WIN
    sta txt_bg
    ; title
    lda k_out
    asl a
    TAXB
    A16
    lda f:box_titles,x
    sta ptr0
    A8
    lda k_asleep
    beq @t
    A16
    lda #.loword(bt_asleep)
    sta ptr0
    A8
@t:
    lda #^box_titles
    sta ptr0+2
    lda k_out
    TAYB
    lda out_tp,y
    asl a
    asl a
    ora #$20
    ldx #((BOX_ROW+1)*32 + BOX_COL + 1)
    jsl txt_print
    stz txt_bg
    rtl

; the box's lines tick in one every other frame (all at once is more than a
; frame's work): A = which line; the one after the last is this spot's net
box_step:
    sta k_bstep
    lda #TXT_WIN
    sta txt_bg
    lda k_bstep
    cmp k_bcount
    beq @tot
    bcs @x
    lda #2
    sta k_bmode
    lda #(BOX_ROW+2)
    sta k_row
    stz k_bcur
    jsr box_items
@x:
    stz txt_bg
    rtl
@tot:
    lda #1
    sta k_bmode
    lda k_bcount
    clc
    adc #(BOX_ROW+2)
    sta k_row
    ; this spot's net
    ldx #.loword(bl_spot)
    ldy k_last
    lda #TP_YELLOW
    A16
    cpy #$8000
    A8
    bcs @neg
    jsr bi_plus
    bra @sum
@neg:
    A16
    tya
    eor #$FFFF
    inc a
    tay
    A8
    lda #TP_RED
    jsr bi_minus
@sum:
    stz txt_bg
    jsr update_total            ; the HUD score moves by exactly this line
    SFX SFX_COIN
    rtl

; k_score = the spots banked so far (base + bonus - penalties), signed: the
; HUD shows -175 after a -175 spot, so the next spot's box adds up on it
; (only the final score stops at 0)
update_total:
    A16
    lda k_base
    clc
    adc k_bonus
    sec
    sbc k_pen
    sta k_score
    A8
    rts

; NONSTOP: frames the car stands still, counted from the moment it first
; moves this spot (A as it stops, with |speed| under 9, adds none)
.a8
.i16
flow_count:
    A16
    lda k_v
    beq @still
    A8
    lda #1
    sta k_moved
    rtl
@still:
    .a16
    A8
    lda k_moved
    beq @x
    A16
    lda k_still
    inc a
    beq @sat                    ; (saturates)
    sta k_still
@sat:
    A8
@x:
    rtl

; park_result's style: NONSTOP (stood still NONSTOP_F frames at most from
; moving off to A) or SMOOTH (SMOOTH_F): k_sflow, k_sbonus, k_style $80
.a8
.i16
flow_pts:
    A16
    lda k_still
    cmp #(NONSTOP_F + 1)
    bcs @sm
    lda #NONSTOP
    bra @pay
@sm:
    cmp #(SMOOTH_F + 1)
    bcs @no
    lda #SMOOTH
@pay:
    sta k_sflow
    clc
    adc k_sbonus
    sta k_sbonus
    A8
    lda #$80
    tsb k_style
    rtl
@no:
    .a16
    A8
    rtl

; This spot's TIME+STYLE (k_sbonus, about to be banked) by source into the
; run's k_sty (ev_style for the card): TIME LEFT, KEPT ROLLING (NONSTOP /
; SMOOTH), CURB KISSES, TIDY PARKING (ONE-MOVE, DEAD CENTRE, ZERO ANGLE,
; PERFECT streaks: the rest), and the cyclist's slot. The five always sum to
; k_bonus.
.a8
.i16
style_bank:
    A16
    lda k_sbonus
    sta k_t0                    ; what's left over: TIDY PARKING
    lda k_style
    and #$0002                  ; TIME LEFT
    beq @a
    lda k_stime
    ldx #0
    jsr @put
@a:
    lda k_style
    and #$0080                  ; NONSTOP / SMOOTH
    beq @b
    lda k_sflow
    ldx #2
    jsr @put
@b:
    lda k_style
    and #$0008                  ; CURB KISS: 300 at 0 px, 100 less a pixel out
    beq @c
    lda k_skiss
    and #$00FF
    asl a
    tax
    lda f:kiss_tbl,x
    ldx #4
    jsr @put
@c:
    lda k_style
    and #$0040                  ; the cyclist
    beq @d
    lda #SHAVE
    ldx #8
    jsr @put
@d:
    lda k_t0
    ldx #6
    jsr @put
    A8
    rtl
.a16
@put:
    ; A = points into slot X; off what's left over
    pha
    clc
    adc k_sty,x
    sta k_sty,x
    lda k_t0
    sec
    sbc 1,s
    sta k_t0
    pla
    rts
.a8

; The cyclist's warning (every cyclist, spots 2 and 3): DING ... DING, and
; a DING! bubble pops up beside her. It goes up CUE_WARN frames before a roll
; to DOWN+RIGHT from a standstill would start to swing your nose out right
; behind her back wheel, and stays up until the last frame that still does
; (CUE_OPEN / CUE_CLOSE, at her speed: about a 12 frame window, whatever her
; speed). It reads only where she is and where your nose is: it rings on
; every cyclist, however you came up to the line. The coach never says why.
CUE_D     = 8                   ; px, her front wheel to your front-left corner
CUE_OPEN  = 6                   ; frames of her riding before CUE_D: the window opens
CUE_CLOSE = 11                  ;   ... and after it: the window closes
CUE_WARN  = 16                  ; frames of warning before it opens
CUE_DING2 = 9                   ; the second ding, this many frames after the first
.a8
.i16
bike_cue:
    lda k_bst
    cmp #2
    beq @on
    stz k_cuev                  ; she's gone (or never came)
    rtl
@on:
    lda k_cuet
    bne @rung
    ; not rung yet: ring once she's (CUE_OPEN + CUE_WARN) frames out
    ldx #(CUE_OPEN + CUE_WARN)
    jsr cue_left
    bpl @x
    lda #1
    sta k_cuet
    sta k_cuev
    SFX SFX_BELL
    rtl
@rung:
    cmp #$FF
    beq @shown
    inc k_cuet
    lda k_cuet
    cmp #CUE_DING2
    bne @shown
    SFX SFX_BELL                ; DING ... DING
@shown:
    lda k_cuev
    beq @x
    ; down once even a frame-perfect roll would be too late
    A16
    lda k_bspd
    lsr a
    lsr a
    lsr a
    lsr a
    sta k_t1
    ldx #CUE_CLOSE
    lda #$0000
@m:
    clc
    adc k_t1
    dex
    bne @m
    sta k_t0
    jsr cue_lead
    clc
    adc k_t0
    A8
    bpl @x
    stz k_cuev
@x:
    rtl

; N+ = she is more than X frames (at her speed) from CUE_D px short of your
; front-left corner; N- = she's that close or closer (A8 on return)
.a8
cue_left:
    A16
    lda k_bspd
    lsr a
    lsr a
    lsr a
    lsr a
    sta k_t1                    ; her speed, 1/16 px a frame
    lda #$0000
@m:
    clc
    adc k_t1
    dex
    bne @m
    sta k_t0
    jsr cue_lead
    sec
    sbc k_t0
    dec a                       ; (<= 0: rung)
    A8
    rts

; A16 = her lead on your front-left corner beyond CUE_D px, in 1/16 px
; (signed; called and returns in A16)
.a16
cue_lead:
    lda CY+4
    clc
    adc #CUE_D
    asl a
    asl a
    asl a
    asl a
    sta k_t1
    lda k_by
    lsr a
    lsr a
    lsr a
    lsr a
    sec
    sbc k_t1
    rts
.a8

.segment "EVENTS2"
box_titles: .addr bt0, bt1, bt2, bt3, bt4, bt5, bt6, bt6, bt6
bt0: .byte "PERFECT PARK!", 0
bt1: .byte "NICELY DONE.", 0
bt2: .byte "IT'LL DO.", 0
bt3: .byte "HALF IN. TICKET!", 0
bt4: .byte "TOWED!", 0
bt5: .byte "TIME'S UP.", 0
bt6: .byte "GOOD PARK.", 0
bt_asleep: .byte "ASLEEP? TOWED!", 0

.segment "CODE"               ; (bank $80: EVENTS2 is full)
; the lines (k_bmode 0: just count them into k_bcount)
box_items:
    lda k_out
    cmp #O_TICKET
    bne @nh
    ldx #.loword(bl_half)
    ldy k_half
    cpy #HALF_IN
    beq @hl
    ldx #.loword(bl_wayoff)
@hl:
    lda #TP_WHITE
    jsr bi_plus
    bra @grades                 ; (the lamps that aren't red pay; no style)
@nh:
    cmp #O_TOWED
    jeq @pens
    ; parked (or parked as time ran out)
    ldx #.loword(bl_parked)
    ldy #PARKED
    lda #TP_WHITE
    jsr bi_plus
@grades:
    lda k_gc
    asl a
    TAXB
    A16
    lda f:pts_curb,x
    tay
    A8
    ldx #.loword(bl_curb)
    lda k_gc
    jsr bi_grade
    lda k_ga
    asl a
    TAXB
    A16
    lda f:pts_ang,x
    tay
    A8
    ldx #.loword(bl_ang)
    lda k_ga
    jsr bi_grade
    lda k_gs
    asl a
    TAXB
    A16
    lda f:pts_space,x
    tay
    A8
    ldx #.loword(bl_space)
    lda k_gs
    jsr bi_grade
    ; style
    lda k_style
    and #$01
    beq @s2
    ldx #.loword(bl_one)
    ldy #ONE_MOVE
    lda #TP_GREEN
    jsr bi_plus
@s2:
    lda k_style
    and #$80
    beq @s2b
    ldx #.loword(bl_smooth)
    ldy k_sflow
    cpy #NONSTOP
    bne @s2a
    ldx #.loword(bl_nonstop)
@s2a:
    lda #TP_GREEN
    jsr bi_plus
@s2b:
    lda k_style
    and #$02
    beq @s3
    ldx #.loword(bl_left)
    ldy k_stime
    lda #TP_GREEN
    jsr bi_plus
@s3:
    lda k_style
    and #$20
    beq @s3b
    ldx #.loword(bl_centre)
    ldy #CENTRE
    lda #TP_GREEN
    jsr bi_plus
@s3b:
    lda k_style
    and #$04
    beq @s3c
    ldx #.loword(bl_zero)
    ldy #ZERO
    lda #TP_GREEN
    jsr bi_plus
@s3c:
    lda k_style
    and #$08
    beq @s4
    lda k_skiss
    asl a
    TAXB
    A16
    lda f:kiss_tbl,x
    tay
    lda f:kiss_lbl,x
    tax
    A8
    lda #TP_GREEN
    jsr bi_plus
@s4:
    lda k_style
    and #$40
    beq @s4b
    ldx #.loword(bl_shave)
    ldy #SHAVE
    lda #TP_GREEN
    jsr bi_plus
@s4b:
    lda k_style
    and #$10
    beq @pens
    ldx #.loword(bl_streak2)
    lda k_streak
    cmp #3
    bcc @s5
    ldx #.loword(bl_streak3)
@s5:
    ldy k_sstrk
    lda #TP_GREEN
    jsr bi_plus
@pens:
    ; penalties: one line each, as they happened
    lda k_sdent
    beq @p1
    ; 150 a bump
    sta WRMPYA
    lda #150
    sta WRMPYB
    nop
    nop
    nop
    nop
    ldy RDMPYL
    ldx #.loword(bl_dent)
    lda k_sdent
    cmp #2
    bcc @p0
    ldx #.loword(bl_dents)
@p0:
    lda #TP_RED
    jsr bi_minus
    lda k_bdrew
    beq @p1
    lda k_sdent
    cmp #2
    bcc @p1
    ; the count after "DENTS X"
    cmp #10
    bcc @p9
    lda #9
@p9:
    clc
    adc #('0' - $20 + TXT_WIN)
    sta tmp2
    dec k_row
    jsr row_cell
    A16
    txa
    clc
    adc #7
    tax
    A8
    lda #($20 | (TP_RED << 2))
    jsl txt_char
    inc k_row
@p1:
    ldy #$0000
@pl:
    phy
    lda k_flags
    and pen_flag,y
    beq @pn
    tya
    asl a
    TAYB
    A16
    lda pen_pts,y
    pha
    lda pen_lbl,y
    tax
    ply
    A8
    lda #TP_RED
    jsr bi_minus
@pn:
    ply
    iny
    cpy #5
    bne @pl
    lda k_out
    cmp #O_TICKET
    bne @x
    ldx #.loword(bl_ticket)
    ldy #TICKET
    lda #TP_RED
    jmp bi_minus
@x:
    rts

.segment "EVENTS2"
pen_flag: .byte F_CURB, F_WALK, F_HYD, F_HEDGE, F_BIKE
pen_pts:  .word 50, 100, 200, 100, 150
pen_lbl:  .addr bl_curbhit, bl_walk, bl_hyd, bl_hedge, bl_bike

bl_parked:  .byte "PARKED", 0
bl_half:    .byte "HALF IN", 0
bl_wayoff:  .byte "WAY OFF", 0
bl_centre:  .byte "DEAD CENTRE", 0
bl_curb:    .byte "CURB", 0
bl_ang:     .byte "ANGLE", 0
bl_space:   .byte "SPACE", 0
bl_one:     .byte "ONE-MOVE", 0
bl_nonstop: .byte "NONSTOP", 0
bl_smooth:  .byte "SMOOTH", 0
bl_left:    .byte "TIME LEFT", 0
bl_kiss0:   .byte "KISSED IT", 0      ; 0 px off the curb
bl_kiss1:   .byte "CLOSE KISS", 0     ; 1 px
bl_kiss2:   .byte "CURB KISS", 0      ; 2 px
bl_zero:    .byte "ZERO ANGLE", 0
bl_shave:   .byte "BIKE SHAVE", 0
bl_streak2: .byte "PERFECT X2", 0
bl_streak3: .byte "PERFECT X3", 0
bl_dent:    .byte "DENT", 0
bl_dents:   .byte "DENTS X", 0
bl_curbhit: .byte "CURB HIT", 0
bl_walk:    .byte "SIDEWALK", 0
bl_hyd:     .byte "HYDRANT", 0
bl_hedge:   .byte "HEDGE", 0
bl_bike:    .byte "BIKE LANE", 0
bl_ticket:  .byte "$75 TICKET", 0
bl_spot:    .byte "SPOT", 0
grade_words: .addr gw0, gw1, gw2, gw3, gw3
grade_tp:    .byte TP_GREEN, TP_YELLOW, TP_ORANGE, TP_RED, TP_RED
gw0: .byte "GREAT", 0
gw1: .byte "GOOD", 0
gw2: .byte "OK", 0
gw3: .byte "BAD", 0

.segment "CODE"               ; (bank $80: EVENTS2 is full)
; X = label, Y = points, A = palette: "LABEL   +nnn" in that colour
bi_plus:
    pha
    lda #'+'
    bra bi_line
bi_minus:
    pha
    lda #'-'
bi_line:
    sta k_bsign
    pla
    sta k_bpal
    sty k_val
    jsr bi_mine
    bcc @x
    jsr box_label
    jsr box_value
@x:
    inc k_row
    rts

; carry set = draw this line now (k_bdrew says so too); count pass: count it
bi_mine:
    stz k_bdrew
    lda k_bmode
    bne @draw
    inc k_bcount
    clc
    rts
@draw:
    cmp #2
    bne @go
    lda k_bcur
    inc k_bcur
    cmp k_bstep
    beq @go
    clc
    rts
@go:
    inc k_bdrew
    sec
    rts

; X = label, Y = points, A = grade: "CURB  GREAT  +300", in the grade's colour
bi_grade:
    sty k_val
    pha
    jsr bi_mine
    bcs @draw
    pla
    inc k_row
    rts
@draw:
    lda #TP_WHITE
    sta k_bpal
    jsr box_label
    pla
    pha
    asl a
    TAXB
    A16
    lda f:grade_words,x
    sta ptr0
    A8
    lda #^grade_words
    sta ptr0+2
    pla
    TAYB
    lda grade_tp,y
    sta k_bpal
    asl a
    asl a
    ora #$20
    pha
    jsr row_cell
    A16
    txa
    clc
    adc #6
    tax
    A8
    pla
    jsl txt_print
    lda #'+'
    sta k_bsign
    jsr box_value
    inc k_row
    rts

; k_val with its sign k_bsign, right-aligned on column NUM_COL, colour k_bpal
box_value:
    A16
    lda k_val
    sta tmp1
    A8
    jsr row_cell
    A16
    txa
    clc
    adc #(NUM_COL - 4)
    tax
    A8
    lda k_bpal
    asl a
    asl a
    ora #$20
    ldy #4
    jsl txt_num                 ; (pads with spaces: the sign goes on after)
    A16
    lda k_val
    ldy #(NUM_COL - 1)          ; sign column for 1 digit
    cmp #10
    bcc @c
    dey
    cmp #100
    bcc @c
    dey
    cmp #1000
    bcc @c
    dey
@c:
    sty k_tmp+16
    A8
    jsr row_cell
    A16
    txa
    dec a
    clc
    adc k_tmp+16
    tax
    A8
    lda k_bsign
    sec
    sbc #$20
    clc
    adc #TXT_WIN
    sta tmp2
    lda k_bpal
    asl a
    asl a
    ora #$20
    jsl txt_char
    rts

; X = label string: print it in colour k_bpal at column 1 of row k_row
box_label:
    A16
    stx ptr0
    A8
    lda #^bl_curb
    sta ptr0+2
    jsr row_cell
    lda k_bpal
    asl a
    asl a
    ora #$20
    jsl txt_print
    rts

; X = cell of column 1 on row k_row
row_cell:
    lda k_row
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    clc
    adc #(BOX_COL + 1)
    tax
    A8
    rts

.segment "EVENTS2"
clear_box:
    ldx #(BOX_ROW*32 + BOX_COL)
    A16
    lda #($1500 | BOX_W)        ; rows 6..26 (27 is clear of it)
    sta tmp1
    A8
    stz tmp2
    lda #$00
    jsl txt_fill
    ldx #(STRIP_ROW*32 + BOX_COL)
    A16
    lda #($0100 | BOX_W)
    sta tmp1
    A8
    stz tmp2
    lda #$00
    jsl txt_fill
    jmp hud_hdma_on             ; back to the panel's own table

; Open the box's rows up: an HDMA table on BG3VOFS (the panel's entries,
; then each box row followed by k_bgap lines of STRIP_ROW, a copy of a blank
; box row) so the box reads at 8 + gap px a row. The gap is BOX_GAP px, less
; for a box too tall to fit above the bottom row.
.segment "CODE"               ; (bank $80: EVENTS2 is full)
BOX_GAP   = 6
STRIP_ROW = 28                  ; off screen; the panel's own strip is 29-31
BOX_TOP   = 51                  ; screen line of the box's top border
BOX_BOT   = 216                 ; the box ends above this line
box_spread:
    ; a blank row of the box (border, inside, border) for the gaps
    ldx #$0000
@cp:
    lda txt_map+((BOX_ROW+1)*32 + BOX_COL)*2,x
    sta txt_map+(STRIP_ROW*32 + BOX_COL)*2,x
    inx
    cpx #(BOX_W*2)
    bne @cp
    ; rows, and the widest gap that fits
    lda k_bcount
    clc
    adc #4
    sta k_rows                  ; rows R
    lda #(BOX_GAP + 1)
    sta k_bgap
@g:
    dec k_bgap
    beq @tab
    ; BOX_TOP + 8R + gap (R - 1) <= BOX_BOT ?
    lda k_rows
    dec a
    sta WRMPYA
    lda k_bgap
    sta WRMPYB
    nop
    nop
    nop
    nop
    A16
    lda k_rows
    and #$00FF
    asl a
    asl a
    asl a
    clc
    adc RDMPYL
    cmp #(BOX_BOT - BOX_TOP + 1)
    A8
    bcs @g
@tab:
    ; the panel's entries, as they are
    ldx #$0000
@hc:
    lda f:hud_vofs,x
    sta k_hdma,x
    inx
    cpx #HUD_ENTRIES*3
    bne @hc
    lda #(BOX_TOP - HUD_LINES)  ; the lines down to the box: row 5 (blank)
    sta k_hdma,x
    A16
    lda #((5 * 8 - HUD_LINES - 1) & $3FF)
    sta k_hdma+1,x
    A8
    inx
    inx
    inx
    A16
    lda #BOX_TOP
    sta k_line                  ; screen line now
    A8
    stz k_rowk                  ; row k
@row:
    lda #8
    sta k_hdma,x
    A16
    lda k_rowk
    and #$00FF
    asl a
    asl a
    asl a
    clc
    adc #(BOX_ROW * 8 - 1)
    sec
    sbc k_line
    and #$03FF
    sta k_hdma+1,x
    lda k_line
    clc
    adc #8
    sta k_line
    A8
    inx
    inx
    inx
    inc k_rowk
    lda k_rowk
    cmp k_rows
    beq @end
    lda k_bgap
    beq @row
    sta k_hdma,x
    A16
    lda #(STRIP_ROW * 8 - 1)
    sec
    sbc k_line
    and #$03FF
    sta k_hdma+1,x
    lda k_bgap
    and #$00FF
    clc
    adc k_line
    sta k_line
    A8
    inx
    inx
    inx
    bra @row
@end:
    ; the rest of the screen as it is
    lda #1
    sta k_hdma,x
    A16
    stz k_hdma+1,x
    A8
    stz k_hdma+3,x
    lda k_bgap
    beq @x
    ldx #.loword(k_hdma)
    stx $4372
    lda #^k_hdma
    sta $4374
@x:
    rts

.segment "EVENTS2"

; ------------------------------------------------------------------
; HUD: a navy panel across the top, BG3 rows 0-4, opened up by an HDMA
; table on BG3VOFS so the three text rows sit 4 px apart:
;   row 1 (lines  7-14): SPOT 1/3  TIME 30  SCORE 12345
;   row 2 (lines 19-26): CURB # ANGLE # SPACE # <WHEEL>  (lamps, wheel)
;   row 3 (lines 31-38): coach line / callouts
;   row 4 (lines 39-46): the panel's bottom edge
; The gaps show row 30 (a strip of empty panel). Below the panel BG3 is
; unshifted (line 47 on), so the result box and the pause menu sit where they always do.
HUD_ATTR = $20
GAP_ROW  = 30
hud_full:
    ldx #$0000
    A16
    lda #$0520                  ; 32 x 5
    sta tmp1
    A8
    lda #HUD_ATTR
    jsl txt_box
    ; the gap strip: rows 29-31 (only row 30, a middle row, is ever shown)
    ldx #((GAP_ROW - 1) * 32)
    A16
    lda #$0320
    sta tmp1
    A8
    lda #HUD_ATTR
    jsl txt_box
    lda #TXT_WIN
    sta txt_bg
    PRINT 1, 1, TP_WHITE, str_spot
    PRINT 10, 1, TP_WHITE, str_time
    PRINT 20, 1, TP_WHITE, str_score
    PRINT 1, 2, TP_WHITE, str_lamps
    stz txt_bg
    ldx #$FFFF
    stx k_shown
    jsr hud_top
    jsr hud_lamps
    jmp hud_msg

str_spot:  .byte "SPOT  /3", 0
str_time:  .byte "TIME", 0
str_score: .byte "SCORE", 0
str_owed:  .byte "OWED ", 0
str_lamps: .byte "CURB   ANGLE   SPACE    WHEEL", 0

; HDMA channel 7 -> BG3VOFS (one register, written twice)
hud_hdma_on:
    lda #$02
    sta $4370
    lda #<BG3VOFS
    sta $4371
    ldx #.loword(hud_vofs)
    stx $4372
    lda #^hud_vofs
    sta $4374
    lda #$80
    sta hdma_sh
    rts

; (screen line y shows BG3 line y + 1 + VOFS; an entry takes effect on the
; screen line its count starts at)
hud_vofs:
    .byte 15
    .word 0                             ; lines 0-14: rows 0-1 as they are
    .byte 4
    .word (GAP_ROW * 8 - 16) & $3FF     ; lines 15-18: the empty strip
    .byte 8
    .word (16 - 20) & $3FF              ; lines 19-26: row 2
    .byte 4
    .word (GAP_ROW * 8 - 28) & $3FF     ; lines 27-30: the empty strip
    .byte 16
    .word (24 - 32) & $3FF              ; lines 31-46: rows 3 and 4
HUD_ENTRIES = 5                         ; (box_spread copies these)
HUD_LINES   = 47
    .byte 1
    .word 0                             ; the rest of the screen
    .byte 0

pk_hud:
    inc k_hud
    lda k_hud
    and #$03
    beq hud_top
    cmp #1
    jeq hud_lamps
    cmp #2
    jeq hud_msg
    rts

hud_top:
    lda #TXT_WIN
    sta txt_bg
    lda k_spot
    cmp #3
    bcc @s
    lda #2
@s:
    inc a
    sta tmp1
    stz tmp1+1
    ldx #(1*32 + 6)
    ldy #1
    lda #(HUD_ATTR | (TP_YELLOW << 2))
    jsl txt_num
    ; time left to the tenth (what TIME LEFT pays): SS.T
    A16
    lda k_clock
    sta tmp0
    A8
    lda #6
    jsl div16                   ; tenths
    lda #10
    jsl div16                   ; tmp0 = seconds, A = the tenth
    pha
    ldx tmp0
    stx tmp1
    lda #(HUD_ATTR | (TP_YELLOW << 2))
    cpx #10
    bcs @tc
    lda #(HUD_ATTR | (TP_RED << 2))
@tc:
    sta k_t0
    ldx #(1*32 + 15)
    ldy #2
    jsl txt_num
    lda #('.' - $20 + TXT_WIN)
    sta tmp2
    lda k_t0
    ldx #(1*32 + 17)
    jsl txt_char
    pla
    sta tmp1
    stz tmp1+1
    lda k_t0
    ldx #(1*32 + 18)
    ldy #1
    jsl txt_num
    ; the running total: SCORE, or OWED in red while the spots so far add up
    ; below 0 (never a minus score: the run's score stops at 0, and a later
    ; spot's box pays the debt off first)
    LDPTR0 str_score
    lda #(HUD_ATTR | (TP_WHITE << 2))
    bit k_score+1
    bpl @lab
    LDPTR0 str_owed
    lda #(HUD_ATTR | (TP_RED << 2))
@lab:
    ldx #(1*32 + 20)
    jsl txt_print
    A16
    lda k_score
    bpl @sp
    eor #$FFFF
    inc a
@sp:
    sta tmp1
    A8
    lda #(HUD_ATTR | (TP_YELLOW << 2))
    bit k_score+1
    bpl @sc
    lda #(HUD_ATTR | (TP_RED << 2))
@sc:
    ldx #(1*32 + 26)
    ldy #5
    jsl txt_num
    stz txt_bg
    rts

; three grade lamps (exactly what A would score now) and the wheel
hud_lamps:
    ldx #(2*32 + 6)
    lda k_gc
    jsr lamp
    ldx #(2*32 + 14)
    lda k_ga
    jsr lamp
    ldx #(2*32 + 22)
    lda k_gs
    jsr lamp
    ; the wheel: an arrow either side of WHEEL, lit while locked that way
    lda #TXT_ARROW_L + TXT_WIN
    sta tmp2
    lda #(HUD_ATTR | (TP_GREY << 2))
    ldy k_notch
    bpl @l
    lda #(HUD_ATTR | (TP_YELLOW << 2))
@l:
    ldx #(2*32 + 24)
    jsl txt_char
    lda #TXT_ARROW_R + TXT_WIN
    sta tmp2
    lda #(HUD_ATTR | (TP_GREY << 2))
    ldy k_notch
    beq @r
    bmi @r
    lda #(HUD_ATTR | (TP_YELLOW << 2))
@r:
    ldx #(2*32 + 30)
    jsl txt_char
    rts

; X = cell, A = grade -> a coloured lamp (a grey one when not in the spot)
lamp:
    TAYB
    lda lamp_tp,y
    asl a
    asl a
    ora #HUD_ATTR
    pha
    lda lamp_tile,y
    sta tmp2
    pla
    jsl txt_char
    rts

lamp_tp:   .byte TP_GREEN, TP_YELLOW, TP_ORANGE, TP_RED, TP_GREY
lamp_tile: .byte TXT_METER+4+TXT_WIN, TXT_METER+4+TXT_WIN, TXT_METER+4+TXT_WIN, TXT_METER+4+TXT_WIN, TXT_METER+4+TXT_WIN

; the message line: a callout while one is up, else the coach
hud_msg:
    lda k_msgt
    beq @coach
    jsr msg_held
    bcs @coach
    ldx k_msg
    lda k_msgcol
    bra @show
@coach:
    lda k_phase
    jne @x
    ldx k_coach
    jeq @x
    lda #TP_CYAN
    cpx #.loword(co_park)
    bne @show
    lda frame
    and #$10
    beq @g
    lda #TP_GREEN
    bra @show
@g:
    lda #TP_WHITE
@show:
    cpx k_shown
    bne @draw
    cmp k_shcol
    jeq @x
@draw:
    stx k_shown
    sta k_shcol
    ; LET GO OF UP just went up with your foot on the gas: time your answer
    cpx #.loword(co_brake)
    bne @nlg
    lda k_lgo
    bne @nlg
    A16
    lda pad
    and #PAD_UP
    A8
    beq @nlg
    lda #1
    sta k_lgo
    stz k_lgot
@nlg:
    ; NOW! or STRAIGHT! just went up: time your answer (if it's still to come)
    lda k_nst
    bne @nst                    ; (back from under a callout: already timing)
    cpx #.loword(co_now)
    bne @nnow
    lda k_notch
    bmi @nst
    lda #1
    bra @tst
@nnow:
    cpx #.loword(co_stop)
    bne @nst
    A16
    lda pad
    and #(PAD_UP | PAD_DOWN | PAD_LEFT | PAD_RIGHT)
    A8
    beq @nst
    lda #2
@tst:
    sta k_nst
    stz k_ntm
@nst:
    ; blank the line inside the panel, then centre the text
    phx
    ldx #(3*32 + 1)
    A16
    lda #$011E                  ; 30 x 1
    sta tmp1
    A8
    lda #TXT_WIN
    sta tmp2
    lda #HUD_ATTR
    jsl txt_fill
    plx
    A16
    stx ptr0
    A8
    lda #^co_up
    sta ptr0+2
    lda #TXT_WIN
    sta txt_bg
    lda k_shcol
    asl a
    asl a
    ora #HUD_ATTR
    ldx #(3*32)
    jsl txt_print_centre
    stz txt_bg
@x:
    rts

; ------------------------------------------------------------------
pk_draw:
    jsl oam_clear
    stz bg1x
    stz bg1x+1
    stz bg1y
    stz bg1y+1
    jsr draw_extras
    jsr draw_bike
    jsr draw_player
    jsr draw_parked
    jsr draw_hydrant
    jmp draw_marks              ; last: road paint goes under everything

; road paint: the Green P in the empty spot, and the yellow stop line for
; your rear bumper until you start backing up
draw_marks:
    lda k_phase
    bne @x
    ldx #(SPOT_X0 + 11)
    stx spr_x
    A16
    lda k_btop
    clc
    adc #A_REAR
    lsr a
    sta spr_y
    A8
    lda #$3A
    sta tmp5
    stz tmp5+1
    LDPTR1 ms_spotp
    ldx #MS_SPOTP_BASE
    stx tmp6
    jsl oam_meta
    lda k_flags
    and #F_REV
    bne @x
    ldx #LANE_X
    stx spr_x
    A16
    lda k_tgt
    clc
    adc #REAR
    sta spr_y
    A8
    lda #$3A
    sta tmp5
    stz tmp5+1
    LDPTR1 ms_stopline
    ldx #MS_STOPLINE_BASE
    stx tmp6
    jsl oam_meta
@x:
    rts

; player car: frame from the heading, drawn about its centre
draw_player:
    jsr pose_trig
    ; centre = axle + f * 13
    lda k_s
    ldy #13
    jsr smul
    .a16
    jsr asr7
    sta tmp1
    lda k_ax
    xba
    and #$00FF
    clc
    adc tmp1
    sta spr_x
    lda k_jig
    and #$0002
    clc
    adc spr_x
    sta spr_x
    A8
    lda k_c
    ldy #13
    jsr smul
    .a16
    jsr asr7
    sta tmp1
    lda k_ay
    xba
    and #$00FF
    sec
    sbc tmp1
    sta spr_y
    ; towed off the top?
    cmp #8
    A8
    bcs @vis
    rts
@vis:
    ; frame from |heading| (the same 1/256 turns the ANGLE lamp grades), so
    ; a car the lamp calls straight is drawn straight: frames at 0, 4, 8,
    ; 14, 22, 32, 44, 58, 72 degrees, mirrored when the nose points right
    A8
    stz tmp5+1
    A16
    lda k_th
    beq @f0
    bpl @f1
    eor #$FFFF
    inc a
    bra @f2
@f1:
    pha
    A8
    lda #$40
    sta tmp5+1
    A16
    pla
@f2:
    xba
    and #$00FF
    cmp #PCAR_ANGS
    bcc @f3
    lda #(PCAR_ANGS - 1)
@f3:
    tax
    A8
    lda f:pcar_frame,x
    bne @f5
    stz tmp5+1                  ; (the straight frame is never mirrored)
@f5:
    A16
    and #$00FF
    bra @f4
@f0:
    lda #$0000
@f4:
    asl a
    tax
    lda f:pcar_lo,x
    sta ptr1
    lda f:pcar_base,x
    sta tmp6
    A8
    lda #^ms_pcar0
    sta ptr1+2
    lda #$20
    sta tmp5
    jsl oam_meta
    rts

; |heading| in 1/256 turns -> frame: GREAT (0-1) straight, GOOD (2-3) 4,
; OK (4-8) 8, then 14 / 22 / 32 / 44 / 58 / 72 degrees
pcar_frame: .byte 0, 0, 1, 1, 2, 2, 2, 2, 2
            .byte 3, 3, 3, 3
            .byte 4, 4, 4, 4, 4, 4
            .byte 5, 5, 5, 5, 5, 5, 5, 5
            .byte 6, 6, 6, 6, 6, 6, 6, 6, 6, 6
            .byte 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
            .byte 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
PCAR_ANGS = 57
pcar_lo:   .addr ms_pcar0, ms_pcar1, ms_pcar2, ms_pcar3, ms_pcar4, ms_pcar5, ms_pcar6, ms_pcar7, ms_pcar8
pcar_base: .word MS_PCAR0_BASE, MS_PCAR1_BASE, MS_PCAR2_BASE, MS_PCAR3_BASE, MS_PCAR4_BASE
           .word MS_PCAR5_BASE, MS_PCAR6_BASE, MS_PCAR7_BASE, MS_PCAR8_BASE

draw_parked:
    ; car ahead
    ldx #(SPOT_X0 + 11)
    stx spr_x
    ldx #(A_TOP + 20)
    stx spr_y
    lda k_palA
    asl a
    ora #$20
    sta tmp5
    stz tmp5+1
    LDPTR1 ms_parked
    ldx #MS_PARKED_BASE
    stx tmp6
    jsl oam_meta
    ; car behind
    A16
    lda k_btop
    clc
    adc #20
    sta spr_y
    A8
    lda k_palB
    asl a
    ora #$20
    sta tmp5
    LDPTR1 ms_parked
    ldx #MS_PARKED_BASE
    stx tmp6
    jsl oam_meta
    ; alarm light over a bumped car
    lda k_alarmt
    beq @x
    and #$08
    beq @x
    lda k_alarm
    cmp #1
    beq @a
    A16
    lda k_btop
    sec
    sbc #6
    bra @s
@a:
    A16
    lda #(A_TOP - 2)
@s:
    sta spr_y
    lda #(SPOT_X0 + 7)
    sta spr_x
    A8
    lda #$3A
    sta tmp5
    stz tmp5+1
    LDPTR1 ms_alarm
    ldx #MS_ALARM_BASE
    stx tmp6
    jsl oam_meta
@x:
    rts

; hydrant, with a geyser once you've hit it
draw_hydrant:
    ldx #HYD_X
    stx spr_x
    ldx k_hyd
    stx spr_y
    lda #$38
    sta tmp5
    stz tmp5+1
    LDPTR1 ms_hydrant
    ldx #MS_HYDRANT_BASE
    stx tmp6
    jsl oam_meta
    lda k_geyser
    beq @x
    A16
    lda k_hyd
    clc
    adc #3
    sta spr_y
    A8
    lda frame
    and #$04
    beq @g0
    LDPTR1 ms_geyser1
    ldx #MS_GEYSER1_BASE
    bra @g
@g0:
    LDPTR1 ms_geyser0
    ldx #MS_GEYSER0_BASE
@g:
    stx tmp6
    jsl oam_meta
    lda frame
    and #$1F
    bne @x
    SFX SFX_SPLASH
@x:
    rts

; the cyclist coming up the lane
BUB_MINY = TOP_LIM + 18         ; the DING! bubble's lowest anchor (its top just under the panel)
draw_bike:
    lda k_bst
    cmp #2
    beq @go
    rts
@go:
    ; her DING! bubble beside her head (bike_cue), steady while it's up, and
    ; drawn first: on top of her
    lda k_cuev
    beq @nb
    A16
    lda k_bx
    sec
    sbc #4
    sta spr_x
    lda k_by
    xba
    and #$00FF
    sec
    sbc #12
    cmp #BUB_MINY               ; never up under the panel: it stays in
    bcs @by                     ; sight until the last frame it means
    lda #BUB_MINY
@by:
    sta spr_y
    A8
    lda #$3A
    sta tmp5
    stz tmp5+1
    LDPTR1 ms_bubble
    ldx #MS_BUBBLE_BASE
    stx tmp6
    jsl oam_meta
@nb:
    A16
    lda k_by
    xba
    and #$00FF
    sta spr_y
    lda k_bx
    sta spr_x
    lda k_wob
    and #$0004
    beq @n
    lda spr_x
    clc
    adc #2
    sta spr_x
@n:
    A8
    lda #$3A
    sta tmp5
    stz tmp5+1
    lda frame
    and #$08
    beq @f0
    LDPTR1 ms_cyc1
    ldx #MS_CYC1_BASE
    bra @f
@f0:
    LDPTR1 ms_cyc0
    ldx #MS_CYC0_BASE
@f:
    stx tmp6
    jsl oam_meta
    rts

; meter maid (and her ticket), tow truck, sparkles
draw_extras:
    lda k_out
    cmp #O_TOWED
    bne @nt
    lda k_phase
    cmp #PH_ANIM
    bne @nt
    A16
    lda k_ax
    xba
    and #$00FF
    sta spr_x
    A8
    ldx k_ey
    stx spr_y
    lda #$38
    sta tmp5
    stz tmp5+1
    LDPTR1 ms_truck
    ldx #MS_TRUCK_BASE
    stx tmp6
    jsl oam_meta
    rts
@nt:
    lda k_maid
    bne @maid
    lda k_out
    cmp #O_TICKET
    bne @sp
    lda k_phase
    cmp #PH_ANIM
    bne @sp
@maid:
    ldx k_ex
    stx spr_x
    ldx k_ey
    stx spr_y
    lda #$3A
    sta tmp5
    stz tmp5+1
    lda frame
    and #$10
    beq @c0
    LDPTR1 ms_cop1
    ldx #MS_COP1_BASE
    bra @c
@c0:
    LDPTR1 ms_cop0
    ldx #MS_COP0_BASE
@c:
    stx tmp6
    jsl oam_meta
    ; the ticket on the windshield once she's there
    lda k_maid
    cmp #2
    bne @sp
    jsr car_centre
    LDPTR1 ms_ticket
    ldx #MS_TICKET_BASE
    stx tmp6
    lda #$3A
    sta tmp5
    stz tmp5+1
    jsl oam_meta
@sp:
    lda k_phase
    cmp #PH_ANIM
    bne @x
    lda k_out
    cmp #O_PERFECT
    bne @x
    ; four sparkles circling the car
    stz k_spark
@spk:
    jsr car_centre
    lda frame
    asl a
    asl a
    clc
    adc k_spark
    jsl sin8
    jsr ev_sext6
    clc
    adc spr_x
    sta spr_x
    A8
    lda frame
    asl a
    asl a
    clc
    adc k_spark
    jsl cos8
    jsr ev_sext6
    clc
    adc spr_y
    sta spr_y
    A8
    lda #$3A
    sta tmp5
    stz tmp5+1
    LDPTR1 ms_sparkle
    ldx #MS_SPARKLE_BASE
    stx tmp6
    jsl oam_meta
    lda k_spark
    clc
    adc #64
    sta k_spark
    bne @spk
@x:
    rts

; A8 signed -> A16 = A / 4 (sign extended), about +-31 px
ev_sext6:
    A16
    and #$00FF
    cmp #$0080
    bcc @p
    ora #$FF00
@p:
    cmp #$8000
    ror a
    cmp #$8000
    ror a
    rts
.a8

; spr_x / spr_y = the car's centre (heading 0 or close)
car_centre:
    A16
    lda k_ax
    xba
    and #$00FF
    sta spr_x
    lda k_ay
    xba
    and #$00FF
    sec
    sbc #13
    sta spr_y
    A8
    rts

; ------------------------------------------------------------------
; ev_score = base + style - penalties: exactly the result boxes added up,
; never below 0 (the penalty word is always the true cost of every hit).
; No spot parked = ev_fail 1; towed for idling = ev_fail 4.
; ev_stat: spots parked, curb kisses, tickets, spots towed
pk_score:
    A16
    lda k_base
    clc
    adc k_bonus
    sec
    sbc k_pen
    bpl @pos
    lda #$0000
@pos:
    sta ev_score
    lda k_base
    sta ev_break
    lda k_bonus
    sta ev_break+2
    lda k_pen
    sta ev_break+4
    lda k_parked
    clc
    adc k_tickets               ; half in (ticketed) is parked too: it pays
    sta ev_stat
    ldx #$0000
@sty:
    lda k_sty,x                 ; TIME+STYLE by source: sums to ev_break+2
    sta ev_style,x
    inx
    inx
    cpx #10
    bne @sty
    lda k_kisses
    sta ev_stat+2
    lda k_tickets
    sta ev_stat+4
    lda k_towed
    sta ev_stat+6
    A8
    stz ev_fail
    lda k_asleep
    beq @a
    lda #FAIL_OWN2
    sta ev_fail
    rts
@a:
    lda k_parked
    bne @x
    lda #$01
    sta ev_fail
@x:
    rts

.include "parking_meta.inc"
