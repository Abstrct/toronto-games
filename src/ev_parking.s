; EVENT 6: PARALLEL PARKING — an Annex side street, from above.
; Three spots, each tighter. Three timing gauges, each driven by the car's
; real motion: STOP alongside (A), CRANK the wheel while reversing (A),
; STRAIGHTEN out (A). The car then follows a simple bicycle model, so where
; you pressed is where you end up — against the curb, in the next car's
; bumper, on the sidewalk, or sticking out for a ticket or the tow truck.
.p816
.smart -
.include "globals.inc"
.include "screens.inc"

.import parking_tiles, parking_map, parking_pal, parking_spr, parking_spr_pal

; geometry (screen pixels; the car's reference point is its rear axle)
A_TOP    = 24           ; car ahead occupies y 24..64
A_REAR   = 64
SPOT_X0  = 205          ; parked cars span x 205..227
SPOT_X1  = 227
CURB     = 232
HEDGE    = 248
LANE_X   = 189          ; rear axle x while driving up
START_Y  = 250
LAT      = 11           ; half width
REAR     = 6            ; rear bumper behind the axle
FRONT    = 32           ; front bumper ahead of the axle
CENTRE   = 13           ; car centre ahead of the axle
D1_TGT   = 10           ; ideal straight reverse before cranking (px)
PHI_TGT  = 39           ; ideal turn-in angle (256 = full turn) ~55 deg
PHI_HW   = 3

; phases
PH_DRIVE  = 0
PH_SHIFT  = 1
PH_BACK   = 2
PH_TURN1  = 3
PH_TURN2  = 4
PH_RESULT = 5
PH_ANIM   = 6
PH_DONE   = 7

; outcomes
O_PERFECT  = 0
O_GOOD     = 1
O_CURB     = 2
O_SIDEWALK = 3
O_HYDRANT  = 4
O_DENT_A   = 5
O_DENT_B   = 6
O_TICKET   = 7
O_TOWED    = 8
O_HEDGE    = 9

k_ax     = ev_ram + 0       ; 8.8
k_ay     = ev_ram + 2       ; 8.8
k_th     = ev_ram + 4       ; 1/65536 turn, signed; high byte = sin8 angle
k_phase  = ev_ram + 6
k_timer  = ev_ram + 8
k_spot   = ev_ram + 10
k_len    = ev_ram + 12      ; spot length
k_btop   = ev_ram + 14      ; top of the car behind
k_v      = ev_ram + 16      ; reverse speed, 1/128 px per frame
k_vf     = ev_ram + 18      ; forward speed 8.8
k_d1     = ev_ram + 20      ; straight reverse so far, 8.8
k_g1     = ev_ram + 22      ; where each gauge was stopped (0-127), $FF = not yet
k_g2     = ev_ram + 24
k_g3     = ev_ram + 26
k_score  = ev_ram + 28
k_last   = ev_ram + 30      ; this spot's score
k_clean  = ev_ram + 32
k_best   = ev_ram + 34      ; best curb gap of a clean park
k_dents  = ev_ram + 36
k_curb   = ev_ram + 38      ; furthest a corner went past the curb
k_hit    = ev_ram + 40      ; 1 car A, 2 car B, 4 hydrant, 8 hedge
k_out    = ev_ram + 42
k_anim   = ev_ram + 44
k_popup  = ev_ram + 46
k_ex     = ev_ram + 48      ; officer / tow truck position
k_ey     = ev_ram + 50
k_palA   = ev_ram + 52
k_palB   = ev_ram + 54
k_t1     = ev_ram + 56      ; gauge targets (marker px) and half widths
k_h1     = ev_ram + 58
k_t2     = ev_ram + 60
k_h2     = ev_ram + 62
k_gap    = ev_ram + 64
k_dy     = ev_ram + 66
k_hyd    = ev_ram + 68      ; hydrant y
k_jig    = ev_ram + 70
k_s      = ev_ram + 72      ; sin / cos of the current heading
k_c      = ev_ram + 74
CX       = ev_ram + 80      ; 4 corner x (words, signed px)
CY       = ev_ram + 88
EV_SEED  = ev_ram + 510

.segment "EVENTS2"
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
    jsr draw_gauges
    jsr pk_hud
    jsl event_countdown
    lda #SONG_PARKING
    jsl music_play
@loop:
    jsl wait_frame
    lda ev_giveup
    bne @quit
    jsr pk_update
    jsr pk_draw
    jsr pk_hud
    lda k_phase
    cmp #PH_DONE
    bne @loop
    jsl music_stop
    jsr pk_score
    bra @card
@quit:
    ; gave up from the pause menu: nothing banked counts
    jsl music_stop
    jsr pk_score
    ldx #$0000
    stx ev_score
    lda #$03
    sta ev_fail
@card:
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
    ldx #99
    stx k_best
    rts

; per spot: length, speeds, gauge targets
spot_len: .word 78, 70, 64
spot_y0:  .word 62, 58, 55          ; ideal stopping axle y
spot_hw:  .word 5, 3, 2             ; gauge half widths (px of travel)
spot_v:   .word 96, 112, 128        ; reverse speed (1/128 px)
spot_vf:  .word $0180, $01C0, $0200 ; driving speed

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
    lda spot_v,x
    sta k_v
    lda spot_vf,x
    sta k_vf
    ; gauge 1 marker = 140 - axle y
    lda #140
    sec
    sbc spot_y0,x
    sta k_t1
    lda spot_hw,x
    sta k_h1
    ; gauge 2 marker = straight reverse * 3
    lda #(D1_TGT * 3)
    sta k_t2
    lda spot_hw,x
    asl a
    adc spot_hw,x
    sta k_h2
    ; car placed below the screen, wheel straight
    lda #(LANE_X * 256)
    sta k_ax
    lda #(START_Y * 256)
    sta k_ay
    stz k_th
    stz k_d1
    stz k_timer
    stz k_curb
    stz k_hit
    stz k_jig
    lda #$00FF
    sta k_g1
    sta k_g2
    sta k_g3
    A8
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
    rts

; ------------------------------------------------------------------
pk_update:
    lda k_phase
    asl a
    TAXB
    jmp (.loword(phase_tab),x)

phase_tab:
    .addr ph_drive, ph_shift, ph_back, ph_turn1, ph_turn2, ph_result, ph_anim, ph_done

; drive up alongside the car ahead; A stops (gauge 1)
ph_drive:
    A16
    lda k_ay
    sec
    sbc k_vf
    sta k_ay
    xba
    and #$00FF
    cmp #12
    A8
    bcc @stop
    A16
    lda pad_new
    and #(PAD_A | PAD_B)
    A8
    bne @stop
    rts
@stop:
    lda #12
    jsr g1_pos
    sta k_g1
    SFX SFX_STEP
    lda #PH_SHIFT
    sta k_phase
    lda #36
    sta k_timer
    rts

; gauge 1 marker for the current axle y (A unused)
g1_pos:
    A16
    lda k_ay
    xba
    and #$00FF
    eor #$FFFF
    sec
    adc #140
    bpl @p
    lda #$0000
@p:
    cmp #127
    bcc @q
    lda #127
@q:
    A8
    rts

; into reverse: beep beep
ph_shift:
    lda k_timer
    and #$0F
    cmp #$08
    bne @n
    SFX SFX_TICK
@n:
    dec k_timer
    bne @x
    lda #PH_BACK
    sta k_phase
@x:
    rts

; reverse straight; A cranks the wheel (gauge 2)
ph_back:
    jsr reverse_step
    lda k_phase
    cmp #PH_BACK
    bne @x
    A16
    lda k_v
    asl a
    clc
    adc k_d1
    sta k_d1
    A8
    jsr g2_pos
    cmp #127
    bcs @crank
    A16
    lda pad_new
    and #(PAD_A | PAD_B)
    A8
    bne @crank
@x:
    rts
@crank:
    jsr g2_pos
    sta k_g2
    SFX SFX_BLIP
    lda #PH_TURN1
    sta k_phase
    rts

; d1 (8.8 px) * 3 -> marker
g2_pos:
    A16
    lda k_d1
    xba
    and #$00FF
    sta tmp0
    asl a
    adc tmp0
    cmp #127
    bcc @q
    lda #127
@q:
    A8
    rts

; turning in (counter-clockwise); A straightens (gauge 3)
ph_turn1:
    jsr reverse_step
    lda k_phase
    cmp #PH_TURN1
    bne @x
    jsr turn_rate
    A16
    lda k_th
    sec
    sbc tmp0
    sta k_th
    A8
    jsr g3_pos
    cmp #127
    bcs @straight
    A16
    lda pad_new
    and #(PAD_A | PAD_B)
    A8
    bne @straight
@x:
    rts
@straight:
    jsr g3_pos
    sta k_g3
    SFX SFX_BLIP
    lda #PH_TURN2
    sta k_phase
    rts

; -angle (1/65536 turn) >> 7 = marker (64 units = 90 deg = 128 px)
g3_pos:
    A16
    lda k_th
    eor #$FFFF
    inc a
    bpl @p
    lda #$0000
@p:
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    cmp #127
    bcc @q
    lda #127
@q:
    A8
    rts

; counter-steer until straight
ph_turn2:
    jsr reverse_step
    lda k_phase
    cmp #PH_TURN2
    bne @x
    jsr turn_rate
    A16
    lda k_th
    clc
    adc tmp0
    sta k_th
    bmi @x16
    stz k_th
    A8
    lda #PH_RESULT
    sta k_phase
    rts
@x16:
    A8
@x:
    rts

; tmp0 = heading change per frame = v * 2.546 (radius 32 px)
turn_rate:
    lda k_v
    sta WRMPYA
    lda #163
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
    lsr a
    sta tmp0
    A8
    rts

; one frame of reversing along the heading, then collisions
reverse_step:
    lda k_th+1
    jsl sin8
    sta k_s
    lda k_th+1
    jsl cos8
    sta k_c
    ; ax -= sin * v / 64 ; ay += cos * v / 64   (8.8)
    lda k_s
    ldy k_v
    jsr smul
    .a16
    jsr asr6
    eor #$FFFF
    inc a
    clc
    adc k_ax
    sta k_ax
    A8
    lda k_c
    ldy k_v
    jsr smul
    .a16
    jsr asr6
    clc
    adc k_ay
    sta k_ay
    A8
    jsr corners
    jsr collide
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

; check the four corners against the parked cars, curb, hydrant, hedge
collide:
    ldx #$0000
@c:
    A16
    lda CX,x
    ; curb excursion
    cmp #(CURB + 1)
    bmi @nocurb
    sec
    sbc #CURB
    cmp k_curb
    bcc @nocurb16
    sta k_curb
@nocurb16:
    lda CX,x
@nocurb:
    ; hedge: stop dead
    cmp #HEDGE
    bmi @nohedge
    A8
    lda k_hit
    ora #$08
    sta k_hit
    jmp @stop
@nohedge:
    .a16
    ; hydrant: (242, k_hyd) +- 5
    sec
    sbc #242
    bpl @h1
    eor #$FFFF
    inc a
@h1:
    cmp #5
    bcs @nohyd
    lda CY,x
    sec
    sbc k_hyd
    bpl @h2
    eor #$FFFF
    inc a
@h2:
    cmp #6
    bcs @nohyd
    A8
    lda k_hit
    ora #$04
    sta k_hit
    A16
@nohyd:
    ; parked cars (x 205..227)
    lda CX,x
    cmp #SPOT_X0
    bmi @next16
    cmp #(SPOT_X1 + 1)
    bpl @next16
    lda CY,x
    cmp #A_TOP
    bmi @next16
    cmp #(A_REAR + 1)
    bpl @notA
    A8
    lda k_hit
    ora #$01
    sta k_hit
    bra @stop
@notA:
    .a16
    cmp k_btop
    bmi @next16
    lda k_btop
    clc
    adc #40
    cmp CY,x
    bmi @next16
    A8
    lda k_hit
    ora #$02
    sta k_hit
    bra @stop
@next16:
    A8
    inx
    inx
    cpx #8
    beq @x
    jmp @c
@x:
    rts
@stop:
    A8
    SFX SFX_CRASH
    lda #PH_RESULT
    sta k_phase
    ; settle into the result with the gauge(s) left unpressed
    rts

; ------------------------------------------------------------------
; work out what happened and how it scores
ph_result:
    ; curb gap from the car's right side, centre offset in the spot
    A16
    lda k_ax
    xba
    and #$00FF
    clc
    adc #LAT
    eor #$FFFF
    sec
    adc #CURB
    sta k_gap                   ; may be negative (over the curb)
    lda k_ay
    xba
    and #$00FF
    sec
    sbc #CENTRE
    sec
    sbc #A_REAR
    sec
    sbc k_len
    clc
    adc k_len
    pha
    lda k_len
    lsr a
    sta tmp0
    pla
    sec
    sbc tmp0
    sta k_dy
    A8
    ; classify, worst first
    lda k_hit
    and #$03
    beq @no_dent
    inc k_dents
    lda k_curb
    cmp #8
    jcs @towed
    lda k_hit
    and #$01
    bne @dentA
    lda #O_DENT_B
    ldx #60
    jmp @set
@dentA:
    lda #O_DENT_A
    ldx #60
    jmp @set
@no_dent:
    lda k_hit
    and #$08
    beq @no_hedge
    lda #O_HEDGE
    ldx #40
    jmp @set
@no_hedge:
    lda k_hit
    and #$04
    beq @no_hyd
    lda #O_HYDRANT
    ldx #80
    jmp @set
@no_hyd:
    lda k_curb
    cmp #7
    bcc @no_walk
    lda #O_SIDEWALK
    ldx #150
    jmp @set
@no_walk:
    lda k_curb
    beq @no_curb
    lda #O_CURB
    ldx #300
    jmp @set
@no_curb:
    ; sticking out?
    A16
    lda k_gap
    cmp #25
    bpl @towed16
    cmp #11
    bmi @clean16
    ; ticket: 200 - 5 per px past 10
    sec
    sbc #10
    asl a
    asl a
    adc k_gap
    sec
    sbc #10
    eor #$FFFF
    sec
    adc #200
    bpl @tk
    lda #$0000
@tk:
    tax
    A8
    lda #O_TICKET
    bra @set
@towed16:
    A8
@towed:
    lda #O_TOWED
    ldx #0
    bra @set
@clean16:
    .a16
    ; clean park: 600 - 25*gap (+100 tight, +100 centred)
    lda k_gap
    bpl @g
    lda #$0000
@g:
    sta tmp0
    asl a
    asl a
    asl a
    sta tmp1                    ; 8g
    asl a
    asl a                       ; 32g
    sec
    sbc tmp1                    ; 24g
    clc
    adc tmp0                    ; 25g
    eor #$FFFF
    sec
    adc #600
    sta tmp1
    ldy #O_GOOD
    lda k_gap
    cmp #4
    bpl @not_tight
    lda tmp1
    clc
    adc #100
    sta tmp1
    lda k_dy
    bpl @ady
    eor #$FFFF
    inc a
@ady:
    cmp #7
    bcs @not_tight
    lda tmp1
    clc
    adc #100
    sta tmp1
    ldy #O_PERFECT
@not_tight:
    A8
    inc k_clean
    lda k_gap
    cmp k_best
    bcs @nb
    sta k_best
@nb:
    tya
    ldx tmp1
@set:
    sta k_out
    stx k_last
    A16
    lda k_score
    clc
    adc k_last
    sta k_score
    A8
    stz k_anim
    stz k_anim+1
    lda #PH_ANIM
    sta k_phase
    ; the officer / tow truck start off-screen
    ldx #(240*256)
    stx k_ex
    ldx #$FFE0
    stx k_ey
    lda k_out
    cmp #O_TOWED
    bne @msg
    ldx #$FFD0                  ; the truck comes down from the top
    stx k_ey
@msg:
    jsr outcome_message
    rts

outcome_message:
    lda k_out
    A16
    and #$00FF
    asl a
    tax
    lda f:out_msgs,x
    sta ptr0
    A8
    lda #^out_msgs
    sta ptr0+2
    lda k_out
    TAXB
    lda f:out_tp,x
    asl a                       ; left-aligned on row 9, clear of the parking lane
    asl a
    ora #$20
    pha
    jsl event_popup_clear
    pla
    ldx #(9*32 + 1)
    jsl txt_print
    ldx #200
    stx k_popup
    ; sound
    lda k_out
    cmp #O_GOOD
    bcs @nc
    SFX SFX_CHEER
    rts
@nc:
    cmp #O_CURB
    bne @ncu
    SFX SFX_STEP
    rts
@ncu:
    cmp #O_TICKET
    bne @nt
    SFX SFX_WHISTLE
    rts
@nt:
    cmp #O_TOWED
    bne @nn
    SFX SFX_HORN
    rts
@nn:
    SFX SFX_CRASH
    rts

out_msgs:
    .addr om0, om1, om2, om3, om4, om5, om6, om7, om8, om9
out_tp:
    .byte TP_GREEN, TP_WHITE, TP_YELLOW, TP_ORANGE, TP_CYAN, TP_RED, TP_RED, TP_RED, TP_RED, TP_ORANGE
om0: .byte "PERFECT PARK!", 0
om1: .byte "NICELY DONE.", 0
om2: .byte "CURB CHECK! SCRAAAPE", 0
om3: .byte "UP ON THE SIDEWALK!", 0
om4: .byte "HYDRANT! SPLOOSH!", 0
om5: .byte "WEE-OO! WEE-OO! WEE-OO!", 0
om6: .byte "BUMPER TAP! (IT'S A BMW)", 0
om7: .byte "$75 TICKET! NICE TRY.", 0
om8: .byte "TOWED! SEE YA AT THE LOT", 0
om9: .byte "INTO THE HEDGE!", 0

; ------------------------------------------------------------------
; outcome animations, then the next spot
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
    bne @nw
    jsr anim_towed
    bra @t
@nw:
    cmp #O_DENT_A
    beq @alarm
    cmp #O_DENT_B
    bne @nd
@alarm:
    jsr anim_alarm
    bra @t
@nd:
    cmp #O_HYDRANT
    bne @t
    lda k_anim
    and #$1F
    bne @t
    SFX SFX_SPLASH
@t:
    ; jiggle for curb / sidewalk / hedge
    lda k_out
    cmp #O_CURB
    beq @jig
    cmp #O_SIDEWALK
    beq @jig
    cmp #O_HEDGE
    bne @nj
@jig:
    lda k_anim
    cmp #40
    bcs @nj
    and #$02
    sta k_jig
@nj:
    ; points after the message, then move on
    A16
    lda k_anim
    cmp #50
    bne @np
    A8
    jsr show_points
    A16
@np:
    lda k_anim
    cmp #200
    A8
    bcc @x
    jsr restore_car_pals
    jsl event_popup_clear
    jsr clear_points
    inc k_spot
    lda k_spot
    cmp #3
    bcs @done
    jsr spot_setup
    jsr draw_gauges
    rts
@done:
    lda #PH_DONE
    sta k_phase
@x:
    rts

ph_done:
    rts

; the bumped car's alarm: flash its body colours, honk
anim_alarm:
    lda k_anim
    and #$17
    bne @nh
    SFX SFX_HORN
@nh:
    lda k_out
    cmp #O_DENT_A
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
    lda k_anim
    and #$08
    beq @off
    A16
    lda #$7FFF
    sta pal_buf,x
    lda #$001F
    sta pal_buf+2,x
    sta pal_buf+4,x
    A8
    bra @dirty
@off:
    jsr restore_car_pals
@dirty:
    lda #$01
    sta pal_dirty
    rts

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
    sbc #CENTRE
    cmp k_ey
    bmi @there
    beq @there
    inc k_ey
    inc k_ey
    A8
    rts
@there:
    A8
    lda k_anim
    cmp #120
    bne @x
    SFX SFX_TICK
@x:
    rts

; the tow truck backs up the lane, hooks the car and hauls it away
anim_towed:
    A16
    lda k_anim
    cmp #90
    bcs @haul
    ; approach from above until its boom meets the car's front bumper
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
    ; everything drives off the top
    lda k_ay
    sec
    sbc #$0200
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

show_points:
    lda #TXT_WIN
    sta txt_bg
    ldx #(11*32 + 12)
    A16
    lda #$0308
    sta tmp1
    A8
    lda #$20
    jsl txt_box
    lda #(TXT_WIN + ('+' - 32))
    sta tmp2
    ldx #(12*32 + 13)
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_char
    ldx k_last
    stx tmp1
    ldx #(12*32 + 14)
    ldy #4
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_num
    stz txt_bg
    SFX SFX_COIN
    rts

clear_points:
    ldx #(11*32 + 12)
    A16
    lda #$0308
    sta tmp1
    A8
    stz tmp2
    lda #$20
    jsl txt_fill
    rts

; ------------------------------------------------------------------
; gauges: rows 23 / 25 / 27, label in cols 1-8, 16-cell bar in cols 10-25
draw_gauges:
    PRINT 1, 23, TP_WHITE, str_g1
    PRINT 1, 25, TP_WHITE, str_g2
    PRINT 1, 27, TP_WHITE, str_g3
    ; gauge 1
    A16
    lda k_t1
    sta tmp4
    lda k_h1
    sta tmp5
    A8
    ldx #(23*32 + 10)
    jsr draw_bar
    A16
    lda k_t2
    sta tmp4
    lda k_h2
    sta tmp5
    A8
    ldx #(25*32 + 10)
    jsr draw_bar
    A16
    lda #(PHI_TGT * 2)
    sta tmp4
    lda #(PHI_HW * 2)
    sta tmp5
    A8
    ldx #(27*32 + 10)
    jsr draw_bar
    rts

str_g1: .byte "STOP", 0
str_g2: .byte "CRANK", 0
str_g3: .byte "STRAIGHT", 0

; X = first cell; tmp4 = target px, tmp5 = half width px
draw_bar:
    ldy #$0000
@cell:
    phy
    ; cell spans px [y*8, y*8+7]; green if it overlaps [t-h, t+h]
    A16
    tya
    asl a
    asl a
    asl a
    sta tmp6                    ; cell left
    lda tmp4
    sec
    sbc tmp5
    sta tmp7                    ; zone left
    lda tmp6
    clc
    adc #7
    cmp tmp7
    bmi @grey16
    lda tmp4
    clc
    adc tmp5
    cmp tmp6
    bmi @grey16
    A8
    lda #TXT_SOLID1
    sta tmp2
    lda #($20 | (TP_GREEN << 2))
    bra @put
@grey16:
    A8
    lda #TXT_METER
    sta tmp2
    lda #($20 | (TP_GREY << 2))
@put:
    jsl txt_char
    inx
    ply
    iny
    cpy #16
    bne @cell
    rts

pk_hud:
    lda frame
    and #$07
    beq @go
    rts
@go:
    PRINT 1, 1, TP_WHITE, str_spot
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
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_num
    PRINT 18, 1, TP_WHITE, str_score
    ldx k_score
    stx tmp1
    ldx #(1*32 + 24)
    ldy #5
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_num
    rts

str_spot:  .byte "SPOT  /3", 0
str_score: .byte "SCORE", 0

; ------------------------------------------------------------------
pk_draw:
    jsl oam_clear
    stz bg1x
    stz bg1x+1
    stz bg1y
    stz bg1y+1
    jsr draw_markers
    jsr draw_extras
    jsr draw_player
    jsr draw_parked
    rts

; gauge markers: live one follows the car, stopped ones stay as pins
draw_markers:
    lda k_phase
    cmp #PH_DRIVE
    bne @n1
    jsr g1_pos
    ldx #(23*8 - 1)
    jsr marker_live
@n1:
    lda k_phase
    cmp #PH_BACK
    bne @n2
    jsr g2_pos
    ldx #(25*8 - 1)
    jsr marker_live
@n2:
    lda k_phase
    cmp #PH_TURN1
    bne @n3
    jsr g3_pos
    ldx #(27*8 - 1)
    jsr marker_live
@n3:
    ; pins
    lda k_g1
    cmp #$FF
    beq @p2
    ldx #(23*8 - 1)
    ldy k_t1
    sty tmp4
    ldy k_h1
    sty tmp5
    jsr marker_pin
@p2:
    lda k_g2
    cmp #$FF
    beq @p3
    ldx #(25*8 - 1)
    ldy k_t2
    sty tmp4
    ldy k_h2
    sty tmp5
    jsr marker_pin
@p3:
    lda k_g3
    cmp #$FF
    beq @x
    ldx #(27*8 - 1)
    ldy #(PHI_TGT * 2)
    sty tmp4
    ldy #(PHI_HW * 2)
    sty tmp5
    jsr marker_pin
@x:
    rts

; A = marker px (0-127), X = y
marker_live:
    stx spr_y
    A16
    and #$00FF
    clc
    adc #80
    sta spr_x
    A8
    lda #$3A                    ; palette 5, priority 3
    sta tmp5
    stz tmp5+1
    LDPTR1 ms_marker
    ldx #MS_MARKER_BASE
    stx tmp6
    jsl oam_meta
    rts

; A = stopped px, X = y, tmp4/tmp5 = target / half width -> green or red pin
marker_pin:
    stx spr_y
    A16
    and #$00FF
    sta tmp7
    clc
    adc #80
    sta spr_x
    lda tmp7
    sec
    sbc tmp4
    bpl @a
    eor #$FFFF
    inc a
@a:
    cmp tmp5
    A8
    beq @ok
    bcc @ok
    LDPTR1 ms_pin_bad
    ldx #MS_PIN_BAD_BASE
    bra @go
@ok:
    LDPTR1 ms_pin_ok
    ldx #MS_PIN_OK_BASE
@go:
    stx tmp6
    lda #$3A
    sta tmp5
    stz tmp5+1
    jsl oam_meta
    rts

; player car: frame from the heading, drawn about its centre
draw_player:
    lda k_th+1
    jsl sin8
    sta k_s
    lda k_th+1
    jsl cos8
    sta k_c
    ; centre = axle + f * 13
    lda k_s
    ldy #CENTRE
    jsr smul
    .a16
    jsr asr7
    sta tmp1
    lda k_ax
    xba
    and #$00FF
    clc
    adc tmp1
    clc
    adc k_jig
    sta spr_x
    A8
    lda k_c
    ldy #CENTRE
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
    ; off the bottom (driving in / towed away)?
    clc
    adc #32
    cmp #(224 + 64)
    A8
    bcc @vis
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
    lda k_phase
    cmp #PH_ANIM
    bne @x
    lda k_out
    cmp #O_DENT_A
    beq @a
    cmp #O_DENT_B
    bne @x
    A16
    lda k_btop
    sec
    sbc #6
    bra @s
@a:
    A16
    lda #(A_TOP - 6)
@s:
    sta spr_y
    lda #(SPOT_X0 + 7)
    sta spr_x
    A8
    lda k_anim
    and #$08
    beq @x
    lda #$3A
    sta tmp5
    LDPTR1 ms_alarm
    ldx #MS_ALARM_BASE
    stx tmp6
    jsl oam_meta
@x:
    rts

; hydrant (with a geyser), officer, tow truck, sparkles
draw_extras:
    ; hydrant
    ldx #242
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
    lda k_phase
    cmp #PH_ANIM
    beq @anim
    rts
@anim:
    lda k_out
    cmp #O_HYDRANT
    bne @nh
    A16
    lda k_hyd
    clc
    adc #3
    sta spr_y
    A8
    lda k_anim
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
    rts
@nh:
    cmp #O_TICKET
    bne @nt
    ldx #240
    stx spr_x
    ldx k_ey
    stx spr_y
    lda #$3A
    sta tmp5
    lda k_anim
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
    ; ticket on the windshield once he's there
    lda k_anim
    cmp #120
    bcc @x
    jsr car_centre
    LDPTR1 ms_ticket
    ldx #MS_TICKET_BASE
    stx tmp6
    lda #$3A
    sta tmp5
    jsl oam_meta
@x:
    rts
@nt:
    cmp #O_TOWED
    bne @np
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
    LDPTR1 ms_truck
    ldx #MS_TRUCK_BASE
    stx tmp6
    jsl oam_meta
    rts
@np:
    cmp #O_PERFECT
    bne @x
    ; four sparkles circling the car
    stz tmp7
@sp:
    jsr car_centre
    lda frame
    asl a
    asl a
    clc
    adc tmp7
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
    adc tmp7
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
    lda tmp7
    clc
    adc #64
    sta tmp7
    bne @sp
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
    sbc #CENTRE
    sta spr_y
    A8
    rts

; ------------------------------------------------------------------
pk_score:
    A16
    lda k_score
    sta ev_score
    lda k_clean
    sta ev_stat
    lda k_best
    sta ev_stat+2
    lda k_dents
    sta ev_stat+4
    A8
    stz ev_fail
    ; nothing parked at all and towed on the last try: called out
    lda k_clean
    bne @x
    lda k_out
    cmp #O_TOWED
    bne @x
    lda #$01
    sta ev_fail
@x:
    rts

.include "parking_meta.inc"
