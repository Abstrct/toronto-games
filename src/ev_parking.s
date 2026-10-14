; EVENT 6: PARALLEL PARKING — an Annex side street (Brunswick Ave), from above.
;
; You drive. UP is gas, DOWN is reverse, let go to brake. Hold LEFT / RIGHT
; to steer (full lock; the wheel centres when you let go), so backing in is
; a thumb roll on the d-pad: DOWN+RIGHT, then DOWN+LEFT, then let go.
; A puts it in park once you've stopped in the spot.
;
; The car follows a bicycle model (rear axle reference, full lock = 32 px
; radius), so the classic manoeuvre works: pull up with your rear bumper
; level with the car ahead's, full right lock and back in, counter-steer
; full left at about 55 degrees, straighten and stop. The top panel shows
; three grade lamps (CURB / ANGLE / SPACE) that read exactly what A would
; score right now, and a wheel indicator. A coach line in the panel says
; what to do next.
;
; Each spot is graded when you park:
;   PARKED 300 + CURB 400/200/50 + ANGLE 250/120/40 + SPACE 150/80/30
;   style: ONE-MOVE +150 (never drove forward after backing in),
;          QUICK +150 (<= 10 s) / +75 (<= 15 s), CURB KISS +150 (gap <= 2 px
;          without touching the curb)
;   penalties: bumping a parked car 150 (car alarm), curb 50, sidewalk 100,
;          hydrant 200, hedge 100, clipping a cyclist 150
;   half in / crooked when you press A or time runs out: $75 TICKET, 150;
;   not in the spot when time runs out: TOWED, 0.
; The coach line is a driving instructor: it gets a beginner parked (GET
; READY... / NOW!), but GREAT grades need you to anticipate.
; Spots: 1 roomy, 2 snug with a cyclist coming up the lane (bell + callout
; once you've pulled up: wait for her before backing in), 3 tight with less time. The meter maid walks
; down the sidewalk in the last 10 seconds.
; Run = sum of spots; ev_break = base / style / penalties. No spot parked at
; all = ev_fail 1 (towed). A finish never scores under 500; a fail at most 450.
; Calling it a day (pause menu) = ev_fail 3, scored like a failed run.
.p816
.smart -
.include "globals.inc"
.include "screens.inc"

.import parking_tiles, parking_map, parking_pal, parking_spr, parking_spr_pal

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
TOP_LIM  = 42           ; no corner above this (the panel)
BOT_LIM  = 222
LEFT_LIM = 52
HYD_X    = 242
BIKE_X   = 170          ; the cyclist's line up the lane

; handling (speeds in 1/128 px per frame)
VF_MAX   = 96           ; forward 0.75 px/f
VR_MAX   = 48           ; reverse 0.375 px/f
ACC_F    = 4
ACC_R    = 3
BRAKE    = 8
STEER_RT = 8            ; wheel slew per frame (32 = one notch)
TH_MAX   = $3800        ; heading clamp (about 79 degrees)

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

; per-spot flags (k_flags)
F_REV    = $01          ; has backed up
F_FWD    = $02          ; drove forward after backing up (no ONE-MOVE)
F_CURB   = $04
F_WALK   = $08
F_HYD    = $10
F_HEDGE  = $20
F_BIKE   = $40

; blockers (k_hit)
H_CARA   = $01
H_CARB   = $02
H_HEDGE  = $04
H_BOUND  = $08

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
k_style  = ev_ram + 126     ; style earned this spot: 1 one-move 2 quick 4 quick2 8 kiss
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

.segment "GFX0"
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
    ; called it a day from the pause menu: scored as a failed run (what
    ; was banked, at most 450, the most a run with no park can make)
    jsl music_stop
    jsr pk_score
    A16
    lda ev_score
    cmp #451
    bcc @cap
    sec
    sbc #450
    clc
    adc ev_break+4
    sta ev_break+4
    lda #450
    sta ev_score
@cap:
    A8
    lda #$03
    sta ev_fail
@card:
    jsl oam_clear               ; nothing pokes through the results card
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
    rts

; per spot: length, clock, cyclist
spot_len:  .word 84, 74, 66
spot_clk:  .word 30*60, 30*60, 25*60
spot_bike: .word 0, 1, 1
spot_msg:  .addr str_spot1, str_spot2, str_spot3

spot_setup:
    lda k_spot
    asl a
    TAXB
    A16
    lda spot_len,x
    sta k_len
    clc
    adc #A_REAR
    sta k_btop
    sec
    sbc #10
    sta k_hyd
    lda spot_clk,x
    sta k_clock
    lda spot_bike,x
    sta k_bst                   ; 1 = a cyclist is coming this spot
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
    jsr pose_trig
    jsr corners
    jsr spot_eval
    rts

str_spot1: .byte "SPOT 1: ROOMY. EASY DOES IT", 0
str_spot2: .byte "SPOT 2: SNUG. MIND THE BIKES", 0
str_spot3: .byte "SPOT 3: TIGHT. MAID'S ON DUTY", 0

; X = message (bank-local), A = text palette: show it in the panel for ~1.7 s
say:
    stx k_msg
    sta k_msgcol
    lda #100
    sta k_msgt
    rts

; X = points: add to this spot's penalties
add_pen:
    A16
    txa
    clc
    adc k_spen
    sta k_spen
    A8
    jsr update_total
    rts

; ------------------------------------------------------------------
pk_update:
    ; timers that run in every phase
    lda k_msgt
    beq @m
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
    jsr steer_slew
    jsr move_car
    jsr soft_hazards
    jsr bike_update
    jsr maid_update
    jsr spot_eval
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
    ; the wheel: held LEFT / RIGHT = full lock that way, let go = it centres
    A16
    lda pad
    and #(PAD_LEFT | PAD_RIGHT)
    ldx #$0000
    cmp #PAD_LEFT
    bne @nl
    dex
@nl:
    cmp #PAD_RIGHT
    bne @nr
    inx
@nr:
    stx k_notch
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
    rts
@blocked:
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
; r = (cos, sin), f = (sin, -cos)  (sin/cos scaled by 127)
corners:
    ; tmp1 = cos*11, tmp2 = sin*11, tmp3 = cos*6, tmp4 = sin*6, tmp5 = cos*32, tmp6 = sin*32 (>>7)
    lda k_c
    ldy #LAT
    jsr smul
    .a16
    jsr asr7
    sta tmp1
    A8
    lda k_s
    ldy #LAT
    jsr smul
    .a16
    jsr asr7
    sta tmp2
    A8
    lda k_c
    ldy #REAR
    jsr smul
    .a16
    jsr asr7
    sta tmp3
    A8
    lda k_s
    ldy #REAR
    jsr smul
    .a16
    jsr asr7
    sta tmp4
    A8
    lda k_c
    ldy #FRONT
    jsr smul
    .a16
    jsr asr7
    sta tmp5
    A8
    lda k_s
    ldy #FRONT
    jsr smul
    .a16
    jsr asr7
    sta tmp6
    lda k_ax
    xba
    and #$00FF
    sta tmp7                    ; axle x
    lda k_ay
    xba
    and #$00FF
    sta tmp0                    ; axle y
    ; rear left (-11, -6): x = ax - c11 - s6, y = ay - s11 + c6
    lda tmp7
    sec
    sbc tmp1
    sec
    sbc tmp4
    sta CX
    lda tmp0
    sec
    sbc tmp2
    clc
    adc tmp3
    sta CY
    ; rear right (+11, -6)
    lda tmp7
    clc
    adc tmp1
    sec
    sbc tmp4
    sta CX+2
    lda tmp0
    clc
    adc tmp2
    clc
    adc tmp3
    sta CY+2
    ; front left (-11, +32)
    lda tmp7
    sec
    sbc tmp1
    clc
    adc tmp6
    sta CX+4
    lda tmp0
    sec
    sbc tmp2
    sec
    sbc tmp5
    sta CY+4
    ; front right (+11, +32)
    lda tmp7
    clc
    adc tmp1
    clc
    adc tmp6
    sta CX+6
    lda tmp0
    clc
    adc tmp2
    sec
    sbc tmp5
    sta CY+6
    A8
    rts

; k_hit = what the body overlaps: parked cars, hedge, screen bounds
block_check:
    stz k_hit
    ldx #$0000
@c:
    A16
    lda CX,x
    cmp #HEDGE
    bcc @nh
    A8
    lda #H_HEDGE
    tsb k_hit
    A16
@nh:
    lda CX,x
    cmp #LEFT_LIM
    bcc @bound
    lda CY,x
    cmp #TOP_LIM
    bcc @bound
    cmp #(BOT_LIM + 1)
    bcs @bound
    ; parked cars (x 205..227)
    lda CX,x
    cmp #SPOT_X0
    bcc @next
    cmp #(SPOT_X1 + 1)
    bcs @next
    lda CY,x
    cmp #A_TOP
    bcc @next
    cmp #(A_REAR + 1)
    bcs @notA
    A8
    lda #H_CARA
    tsb k_hit
    bra @next8
@notA:
    .a16
    cmp k_btop
    bcc @next
    lda k_btop
    clc
    adc #40
    cmp CY,x
    bcc @next
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
    bne @c
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

; X, Y = a point (px): carry set if it's inside the car body
pt_in_car:
    A16
    txa
    sta k_tmp+8
    lda k_ax
    xba
    and #$00FF
    eor #$FFFF
    sec
    adc k_tmp+8                 ; dx = px - axle x
    sta k_tmp+8
    jsr @abs_ok
    jcs @out
    tya
    sta k_tmp+10
    lda k_ay
    xba
    and #$00FF
    eor #$FFFF
    sec
    adc k_tmp+10                ; dy = py - axle y
    sta k_tmp+10
    jsr @abs_ok
    bcs @out
    ; lat = (dx*c + dy*s) >> 7
    lda k_tmp+8
    sta k_md
    A8
    lda k_c
    jsr smul_w
    .a16
    sta k_tmp+12
    lda k_tmp+10
    sta k_md
    A8
    lda k_s
    jsr smul_w
    .a16
    clc
    adc k_tmp+12
    jsr asr7
    ; |lat| < LAT
    bpl @lp
    eor #$FFFF
    inc a
@lp:
    cmp #LAT
    bcs @out
    ; lon = (dx*s - dy*c) >> 7
    lda k_tmp+8
    sta k_md
    A8
    lda k_s
    jsr smul_w
    .a16
    sta k_tmp+12
    lda k_tmp+10
    sta k_md
    A8
    lda k_c
    jsr smul_w
    .a16
    eor #$FFFF
    sec
    adc k_tmp+12
    jsr asr7
    ; -REAR < lon < FRONT
    bmi @neg
    cmp #FRONT
    bcs @out
    bra @in
@neg:
    cmp #($10000 - REAR + 1)
    bcc @out
@in:
    A8
    sec
    rts
@out:
    A8
    clc
    rts
; A16 = value: carry clear when |value| < 40 (close enough to test)
@abs_ok:
    .a16
    bpl @ap
    eor #$FFFF
    inc a
@ap:
    cmp #40
    rts
.a8

; something blocked the move: parked cars honk, the hedge eats you
on_block:
    lda k_hit
    and #(H_CARA | H_CARB)
    beq @nc
    lda k_bumpcd
    bne @refresh
    ; a new bump
    inc k_dents
    lda #8
    sta k_jig
    SFX SFX_CRASH
    lda k_hit
    and #H_CARA
    beq @b
    lda #1
    sta k_alarm
    ldx #.loword(str_dentA)
    bra @say
@b:
    lda #2
    sta k_alarm
    ldx #.loword(str_dentB)
@say:
    lda #TP_RED
    jsr say
    lda #90
    sta k_alarmt
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

str_dentA: .byte "BUMPER TAP! (IT'S A BMW)", 0
str_dentB: .byte "WEE-OO! WEE-OO! WEE-OO!", 0
str_hedge: .byte "INTO THE HEDGE!", 0

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

str_curb: .byte "CURB CHECK! SCRAAAPE", 0
str_walk: .byte "UP ON THE SIDEWALK!", 0
str_hyd:  .byte "HYDRANT! SPLOOSH!", 0

; ------------------------------------------------------------------
; the cyclist (spots 2 and 3): once you've pulled up beside the car ahead
; (or start backing up), the bell rings and she appears at the bottom of
; the lane, riding up at 1.25 px/f. Your nose swings out across her line as
; soon as you back in, so check your mirror: wait the ~2 s for her to pass.
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
    lda k_v
    bne @x16
    lda k_ay
    xba
    and #$00FF
    cmp #(A_REAR + 16)
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
    lda #120
    sta k_msgt
@x:
    rts
@x16:
    A8
    rts
@ride:
    cmp #2
    bne @x
    A16
    lda k_by
    sec
    sbc #$0140
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
    rts
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

str_bell: .byte "DING DING! BIKE! WAIT FOR IT", 0
str_bike: .byte "HEY! WATCH THE BIKE LANE!", 0

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
    ; curb: 0-2 great, 3-5 good, 6-12 ok, more = ticket; over by 1-6 ok, 7+ ticket
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
    cmp #13
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
    ; angle (1/256 turn): 0-1 great, 2-3 good, 4-6 ok, 7+ crooked
    lda k_ang
    ldy #0
    cmp #2
    bcc @ga
    iny
    cmp #4
    bcc @ga
    iny
    cmp #7
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
TGT_Y = A_REAR + 3          ; ideal rear axle y before backing in (bumpers level)
READY_GAP = 22              ; coach: GET READY when the predicted gap is under this
NOW_GAP   = 12              ; ... and NOW! under this (tuned for a ~1/4 s reaction)
coach:
    ; the cyclist coming up the lane, not yet past your nose: wait
    lda k_bst
    cmp #2
    bne @nobike
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
@nobike:
    lda k_inspot
    beq @notin
    lda k_ang                   ; still swinging in: the turning lines
    cmp #7
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
    bra @set
@fixs:
    ldx #.loword(co_fix)
    bra @set
@notin:
    ; nearly straight with the wheel not yet counter-steered: line it up
    lda k_ang
    cmp #4
    bcs @turning
    lda k_notch
    bmi @turning
    A16
    lda k_ay
    xba
    and #$00FF
    cmp #(TGT_Y - 4)
    bcc @far
    sec
    sbc #TGT_Y                  ; px still to go
    bmi @ready16
    cmp #5
    bcc @ready16
    ; once you've started backing in, don't flip back to "pull up"
    pha
    lda k_flags
    and #F_REV
    beq @nrev
    pla
    cmp #14
    bcc @ready16
    pha
@nrev:
    pla
    sta k_tmp+14
    lda k_v
    beq @up16
    bmi @up16
    ; about to get there: a human beat of travel plus braking
    lsr a
    lsr a
    lsr a
    clc
    adc #4
    cmp k_tmp+14
    bcs @brake16
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
    ldx #.loword(co_toofar)
    bra @set
@ready16:
    A8
@ready:
    lda k_notch
    cmp #1
    beq @back
    ldx #.loword(co_lock)
    bra @set
@back:
    ldx #.loword(co_back)
@set:
    stx k_coach
    rts
@turning:
    lda k_notch
    bmi @counter
    ; wheel right (or centred mid-turn): back up until the gap will close
    jsr gap_pred
    eor #$80
    cmp #($80 + READY_GAP)
    bcs @back
    cmp #($80 + NOW_GAP)
    bcc @now
    ldx #.loword(co_ready)
    bra @set
@now:
    ldx #.loword(co_now)
    bra @set
@counter:
    ; counter-steering: swing in until straight (past it: stop)
    lda k_th+1
    bmi @swing
    ldx #.loword(co_stop)
    bra @set
@swing:
    ldx #.loword(co_swing)
    bra @set

; A8 = predicted curb gap if you counter-steer now (signed, clamped to -128..127)
;   = curb - 11 - axle x - 32 (1 - cos) - 5 for the wheel's travel
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
    adc #(CURB - 11 - 5)
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

co_up:     .byte "HOLD UP: PULL UP BESIDE IT", 0
co_brake:  .byte "LET GO! REAR BUMPERS LEVEL", 0
co_toofar: .byte "TOO FAR. HOLD DOWN A BIT", 0
co_lock:   .byte "HOLD DOWN+RIGHT: BACK IN", 0
co_back:   .byte "HOLD DOWN+RIGHT: BACK IN", 0
co_wait:   .byte "WAIT! LET THE BIKE GO BY", 0
co_ready:  .byte "GET READY: DOWN+LEFT SOON", 0
co_now:    .byte "NOW! ROLL TO DOWN+LEFT", 0
co_swing:  .byte "HOLD DOWN+LEFT: SWING IN", 0
co_stop:   .byte "STRAIGHT! LET GO TO STOP", 0
co_park:   .byte "A: PARK IT!", 0
co_fix:    .byte "TOO FAR OUT. FIX IT, OR A", 0

; ------------------------------------------------------------------
; work out what this spot scores (carry set = time ran out)
park_result:
    php
    stz k_style
    lda k_inspot
    bne @in
    ; nowhere near the spot: towed
    plp
    lda #O_TOWED
    sta k_out
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
    plp
    lda #O_TICKET
    sta k_out
    ldx #150
    stx k_sbase
    jmp @done
@parked:
    inc k_parked
    ; base: PARKED 400 + curb + angle + space
    lda k_gc
    asl a
    TAXB
    A16
    lda f:pts_curb,x
    clc
    adc #300
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
    ; the outcome: all great = perfect, nothing ok = nicely done
    lda k_gc
    ora k_ga
    ora k_gs
    TAXB
    lda f:out_of_grades,x
    sta k_out
    plp
    bcc @style
    ; time ran out: parked, but no style
    lda #O_LATE
    sta k_out
    bra @done
@style:
    ; ONE-MOVE: backed in and never drove forward again
    lda k_flags
    and #(F_REV | F_FWD)
    cmp #F_REV
    bne @nq
    inc k_onemv
    lda #$01
    tsb k_style
    A16
    lda k_sbonus
    clc
    adc #150
    sta k_sbonus
    A8
@nq:
    ; QUICK: parked inside 10 s (+150) or 15 s (+75)
    A16
    lda k_elap
    cmp #(10 * 60 + 1)
    bcs @q2
    lda k_sbonus
    clc
    adc #150
    sta k_sbonus
    A8
    lda #$02
    tsb k_style
    bra @nk
@q2:
    .a16
    cmp #(15 * 60 + 1)
    bcs @nk16
    lda k_sbonus
    clc
    adc #75
    sta k_sbonus
    A8
    lda #$04
    tsb k_style
    bra @nk
@nk16:
    A8
@nk:
    ; CURB KISS: within 2 px of the curb without ever touching it
    lda k_flags
    and #F_CURB
    bne @done
    A16
    lda k_gap
    cmp #3
    A8
    bcs @done
    inc k_kisses
    lda #$08
    tsb k_style
    A16
    lda k_sbonus
    clc
    adc #150
    sta k_sbonus
    A8
@done:
    ; bank it
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
    jsr update_total
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
pts_curb:  .word 400, 200, 50, 0, 0
pts_ang:   .word 250, 120, 40, 0, 0
pts_space: .word 150, 80, 30, 0, 0

; k_score = base + bonus + this spot so far - penalties, never below 0
update_total:
    A16
    lda k_base
    clc
    adc k_bonus
    clc
    adc k_sbase
    clc
    adc k_sbonus
    sec
    sbc k_pen
    sec
    sbc k_spen
    bpl @p
    lda #$0000
@p:
    sta k_score
    A8
    rts

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
    .addr om0, om1, om2, om3, om4, om5
out_tp:
    .byte TP_GREEN, TP_GREEN, TP_WHITE, TP_RED, TP_RED, TP_YELLOW
om0: .byte "PERFECT PARK! GREEN P PRO!", 0
om1: .byte "NICELY DONE.", 0
om2: .byte "PARKED. IT'LL DO.", 0
om3: .byte "$75 TICKET! NICE TRY.", 0
om4: .byte "TOWED! SEE YA AT THE LOT", 0
om5: .byte "TIME! IT'LL DO, I GUESS.", 0

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
    jsr result_box
    A16
@nb:
    ; A moves on once the box has been up a moment; otherwise ~4 s
    lda k_anim
    cmp #240
    bcs @next16
    cmp #80
    A8
    bcc @x
    A16
    lda pad_new
    and #(PAD_A | PAD_B)
    A8
    beq @x
@next:
    jsr restore_car_pals
    stz k_alarmt
    jsr clear_box
    stz k_msgt
    inc k_spot
    lda k_spot
    cmp #3
    bcs @done
    jmp spot_setup
@done:
    lda #PH_DONE
    sta k_phase
@x:
    rts
@next16:
    A8
    bra @next

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
; the breakdown box on the left (over the houses and the far lane):
;   NICELY DONE. / CURB GREAT / ANGLE GOOD / SPACE OK / ONE-MOVE +200 /
;   QUICK +150 / CURB KISS +100 / PENALTY -150 / SPOT +1234
BOX_COL = 0
BOX_ROW = 7
result_box:
    ; lines: title, 3 grades (parked), style lines, penalty, total
    lda #2
    sta tmp0
    lda k_out
    cmp #O_TICKET
    bcc @g3
    cmp #O_LATE
    bne @ns
@g3:
    lda #5
    sta tmp0
    lda k_style
    ldx #4
@bits:
    lsr a
    bcc @nb
    inc tmp0
@nb:
    dex
    bne @bits
    lda k_style
    and #$06
    cmp #$06                    ; (QUICK is one line, never both)
    bne @ns
    dec tmp0
@ns:
    ldx k_lpen
    beq @np
    inc tmp0
@np:
    lda tmp0
    clc
    adc #2
    xba
    lda #16
    A16
    sta tmp1
    A8
    ldx #(BOX_ROW*32 + BOX_COL)
    lda #$20
    jsl txt_box
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
    lda #(BOX_ROW+2)
    sta k_row
    lda k_out
    cmp #O_TICKET
    bcc @grades
    cmp #O_LATE
    bne @pen
@grades:
    ldx #.loword(bl_curb)
    lda k_gc
    jsr box_grade
    ldx #.loword(bl_ang)
    lda k_ga
    jsr box_grade
    ldx #.loword(bl_space)
    lda k_gs
    jsr box_grade
    lda k_style
    and #$01
    beq @s2
    ldx #.loword(bl_one)
    ldy #150
    lda #TP_GREEN
    jsr box_line
@s2:
    lda k_style
    and #$02
    beq @s3
    ldx #.loword(bl_quick)
    ldy #150
    lda #TP_GREEN
    jsr box_line
@s3:
    lda k_style
    and #$04
    beq @s4
    ldx #.loword(bl_quick)
    ldy #75
    lda #TP_GREEN
    jsr box_line
@s4:
    lda k_style
    and #$08
    beq @pen
    ldx #.loword(bl_kiss)
    ldy #150
    lda #TP_GREEN
    jsr box_line
@pen:
    ldy k_lpen
    beq @tot
    ldx #.loword(bl_pen)
    lda #TP_RED
    jsr box_line_neg
@tot:
    ldy k_last
    ldx #.loword(bl_spot)
    lda #TP_YELLOW
    A16
    cpy #$8000
    A8
    bcs @neg
    jsr box_line
    bra @x
@neg:
    A16
    tya
    eor #$FFFF
    inc a
    tay
    A8
    lda #TP_RED
    jsr box_line_neg
@x:
    stz txt_bg
    SFX SFX_COIN
    rts

box_titles: .addr bt0, bt1, bt2, bt3, bt4, bt5
bt0: .byte "PERFECT PARK!", 0
bt1: .byte "NICELY DONE.", 0
bt2: .byte "PARKED.", 0
bt3: .byte "$75 TICKET!", 0
bt4: .byte "TOWED!", 0
bt5: .byte "TIME'S UP.", 0
bl_curb:  .byte "CURB", 0
bl_ang:   .byte "ANGLE", 0
bl_space: .byte "SPACE", 0
bl_one:   .byte "ONE-MOVE", 0
bl_quick: .byte "QUICK", 0
bl_kiss:  .byte "CURB KISS", 0
bl_pen:   .byte "PENALTY", 0
bl_spot:  .byte "SPOT", 0
grade_words: .addr gw0, gw1, gw2, gw3, gw3
grade_tp:    .byte TP_GREEN, TP_YELLOW, TP_ORANGE, TP_RED, TP_RED
gw0: .byte "GREAT", 0
gw1: .byte "GOOD", 0
gw2: .byte "OK", 0
gw3: .byte "BAD", 0

; X = label, A = grade: "LABEL   GRADE" on row k_row
box_grade:
    pha
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
    asl a
    asl a
    ora #$20
    pha
    jsr row_cell
    A16
    txa
    clc
    adc #9
    tax
    A8
    pla
    jsl txt_print
    inc k_row
    rts

; X = label, Y = points, A = palette: "LABEL    +nnn"
box_line:
    pha
    phy
    jsr box_label
    lda #('+' - 32 + TXT_WIN)
    bra box_num
box_line_neg:
    pha
    phy
    jsr box_label
    lda #('-' - 32 + TXT_WIN)
box_num:
    ; "+nnn" right-aligned against column 14: the sign sits by the digits
    sta tmp2
    ply
    sty tmp1
    sty k_tmp+18
    jsr row_cell
    A16
    txa
    clc
    adc #(11 - 1)
    tax
    A8
    pla
    asl a
    asl a
    ora #$20
    pha
    ldy #4
    jsl txt_num                 ; (pads with spaces: the sign goes on after)
    A16
    lda k_tmp+18
    ldy #(14 - 1)               ; sign column for 1 digit
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
    sec
    sbc #(BOX_COL + 1)
    clc
    adc k_tmp+16
    clc
    adc #BOX_COL
    tax
    A8
    pla
    jsl txt_char
    inc k_row
    rts

; X = label string: print it in white at column 1 of row k_row
box_label:
    A16
    stx ptr0
    A8
    lda #^bl_curb
    sta ptr0+2
    jsr row_cell
    lda #($20 | (TP_WHITE << 2))
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

clear_box:
    ldx #(BOX_ROW*32 + BOX_COL)
    A16
    lda #$0B10
    sta tmp1
    A8
    stz tmp2
    lda #$00
    jsl txt_fill
    rts

; ------------------------------------------------------------------
; HUD: a navy panel across the top (rows 0-4).
;   row 1: SPOT 1/3  TIME 30  SCORE 12345
;   row 2: CURB o ANGLE o SPACE o   <<.>>   (grade lamps, wheel)
;   row 3: coach line / callouts
HUD_ATTR = $20
hud_full:
    ldx #$0000
    A16
    lda #$0520                  ; 32 x 5
    sta tmp1
    A8
    lda #HUD_ATTR
    jsl txt_box
    lda #TXT_WIN
    sta txt_bg
    PRINT 1, 1, TP_WHITE, str_spot
    PRINT 11, 1, TP_WHITE, str_time
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
str_lamps: .byte "CURB   ANGLE   SPACE", 0

pk_hud:
    inc k_hud
    lda k_hud
    and #$03
    beq hud_top
    cmp #1
    beq hud_lamps
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
    ; seconds left (rounded up)
    A16
    lda k_clock
    clc
    adc #59
    sta tmp0
    A8
    lda #60
    jsl div16
    ldx tmp0
    stx tmp1
    lda #(HUD_ATTR | (TP_YELLOW << 2))
    cpx #11
    bcs @tc
    lda #(HUD_ATTR | (TP_RED << 2))
@tc:
    ldx #(1*32 + 16)
    ldy #2
    jsl txt_num
    ldx k_score
    stx tmp1
    ldx #(1*32 + 26)
    ldy #5
    lda #(HUD_ATTR | (TP_YELLOW << 2))
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
    ; wheel: five cells, lit from the middle out to the notch
    ldy #$0000
@w:
    phy
    lda wheel_tile,y
    clc
    adc #TXT_WIN
    sta tmp2
    ; middle always lit; each side lit when the wheel is locked that way
    lda #(HUD_ATTR | (TP_GREY << 2))
    pha
    cpy #2
    beq @lit
    bcs @r
    lda k_notch
    bmi @lit
    bra @put
@r:
    lda k_notch
    beq @put
    bmi @put
@lit:
    pla
    lda #(HUD_ATTR | (TP_YELLOW << 2))
    pha
@put:
    A16
    tya
    clc
    adc #(2*32 + 26)
    tax
    A8
    pla
    jsl txt_char
    ply
    iny
    cpy #5
    bne @w
    rts

wheel_tile: .byte TXT_ARROW_L, TXT_ARROW_L, TXT_DOT, TXT_ARROW_R, TXT_ARROW_R

; X = cell, A = grade -> a coloured lamp (grey when not in the spot)
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
lamp_tile: .byte TXT_METER+4+TXT_WIN, TXT_METER+4+TXT_WIN, TXT_METER+4+TXT_WIN, TXT_METER+4+TXT_WIN, TXT_METER+TXT_WIN

; the message line: a callout while one is up, else the coach
hud_msg:
    lda k_msgt
    beq @coach
    ldx k_msg
    lda k_msgcol
    bra @show
@coach:
    lda k_phase
    bne @x
    ldx k_coach
    beq @x
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
    beq @x
@draw:
    stx k_shown
    sta k_shcol
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
    ; frame = |angle| * 9 / 64 (10 degree steps), mirrored when positive
    stz tmp5+1
    lda k_th+1
    bpl @pos
    eor #$FF
    inc a
    bra @f
@pos:
    beq @f
    pha
    lda #$40
    sta tmp5+1
    pla
@f:
    sta WRMPYA
    lda #9
    sta WRMPYB
    nop
    nop
    nop
    A16
    lda RDMPYL
    clc
    adc #32
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    cmp #9
    bcc @ok
    lda #8
@ok:
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
draw_bike:
    lda k_bst
    cmp #2
    beq @go
    rts
@go:
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
    stz k_tmp+20
@spk:
    jsr car_centre
    lda frame
    asl a
    asl a
    clc
    adc k_tmp+20
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
    adc k_tmp+20
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
    lda k_tmp+20
    clc
    adc #64
    sta k_tmp+20
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
; ev_score = base + style - penalties. A finish (at least one spot parked)
; never scores under 500; no spot parked = towed (ev_fail 1).
; ev_stat: spots parked, curb kisses, one-move parks, dents
pk_score:
    A16
    lda k_base
    clc
    adc k_bonus
    sta tmp0                    ; base + style
    sec
    sbc k_pen
    bmi @zero
    sta ev_score
    lda k_parked
    beq @brk
    lda ev_score
    cmp #500
    bcs @brk
    lda #500
    sta ev_score
    bra @fixpen
@zero:
    stz ev_score
@fixpen:
    ; the penalty line shows what was actually taken off
    lda tmp0
    sec
    sbc ev_score
    sta k_pen
@brk:
    lda k_base
    sta ev_break
    lda k_bonus
    sta ev_break+2
    lda k_pen
    sta ev_break+4
    lda k_parked
    sta ev_stat
    lda k_kisses
    sta ev_stat+2
    lda k_onemv
    sta ev_stat+4
    lda k_dents
    sta ev_stat+6
    A8
    stz ev_fail
    lda k_parked
    bne @x
    lda #$01
    sta ev_fail
@x:
    rts

.include "parking_meta.inc"
