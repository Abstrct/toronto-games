; EVENT 7: TTC SURFING — Line 1 southbound, Bloor-Yonge to Union, no hands.
; The train accelerates, brakes, takes curves and lurches; each pushes your
; balance dot (the ring over your head). The D-pad leans against it. Let the
; dot leave the ring and you grab whatever's closest: germs. Fewest wins.
.p816
.smart -
.include "globals.inc"
.include "screens.inc"

.import subway_tiles, subway_bg1, subway_tunnel, subway_platform, subway_pal, subway_spr, subway_spr_pal

RIDER_X   = 128
RIDER_Y   = 196
RING_X    = 128
RING_Y    = 84
SIGN_ROW  = 5               ; station sign box rows 5-7, over the window tops
POP_ROW   = 13              ; grab popups, under the ring
RADIUS2   = 169             ; grab when bx^2 + by^2 > 13^2
NUM_SEG   = 6
VRAM_PLAT = $4C00           ; spare 32x32 map for the station wall

; train phases per segment
TP_ACCEL  = 0
TP_CRUISE = 1
TP_BRAKE  = 2
TP_STOP   = 3

w_bx     = ev_ram + 0       ; balance offset, 8.8 px (signed)
w_by     = ev_ram + 2
w_vx     = ev_ram + 4
w_vy     = ev_ram + 6
w_fx     = ev_ram + 8       ; train force this frame (8.8)
w_fy     = ev_ram + 10
w_tp     = ev_ram + 12      ; train phase
w_tt     = ev_ram + 14      ; frames left in the phase
w_seg    = ev_ram + 16      ; segment 0-5
w_speed  = ev_ram + 18      ; train speed 8.8 (window scroll)
w_scroll = ev_ram + 20      ; BG2 scroll 8.8
w_curve  = ev_ram + 22      ; frames left in a curve
w_cdir   = ev_ram + 24      ; curve force (signed 8.8)
w_next   = ev_ram + 26      ; frames to the next cruise event
w_germs  = ev_ram + 28
w_grab   = ev_ram + 30      ; frames left in a grab
w_gkind  = ev_ram + 32      ; 0 pole 1 backpack 2 window 3 stranger
w_streak = ev_ram + 34      ; frames since the last grab
w_best   = ev_ram + 36
w_popup  = ev_ram + 38
w_status = ev_ram + 40      ; status line id
w_plat   = ev_ram + 42      ; 1 = windows show the platform
w_done   = ev_ram + 44
w_cur    = ev_ram + 46
w_lurch  = ev_ram + 48
w_pal    = ev_ram + 50      ; boarding: palette of the swap-in passenger
w_shake  = ev_ram + 52
w_stat_old = ev_ram + 54
EV_SEED  = ev_ram + 510
NUM_ENT  = 1                ; (evcommon's ev_alloc is unused here)
E_TYPE   = ev_ram + 120

NUM_GERMS = 8
G_X      = ev_ram + 64      ; germ particles: x, y (words), life
G_Y      = ev_ram + 80
G_L      = ev_ram + 96

ST_NONE   = 0
ST_ACCEL  = 1
ST_CRUISE = 2
ST_LEFT   = 3
ST_RIGHT  = 4
ST_BRAKE  = 5
ST_DOORS  = 6

.segment "EVENTS3"
.a8
.i16

ev_subway:
    phb
    phk
    plb
    jsr sb_init
    jsr sb_draw
    jsl event_card
    jsr sb_hud_full
    jsl event_countdown
    lda #SONG_SUBWAY
    jsl music_play
@loop:
    jsl wait_frame
    jsr sb_windows              ; right after vblank: swap tunnel / platform
    lda ev_giveup
    bne @quit
    jsr sb_update
    jsr sb_draw
    jsr sb_hud
    lda w_done
    beq @loop
    jsl music_stop
    jsr sb_score
    bra @card
@quit:
    ; gave up from the pause menu (fewer stops ridden must not mean fewer germs)
    jsl music_stop
    jsr sb_score
    ldx #$0000
    stx ev_score
    lda #$03
    sta ev_fail
@card:
    jsl score_card
    ; leave the normal BG2 map behind
    lda #((VRAM_BG2MAP >> 8) | 1)
    sta BG2SC
    plb
    rtl

.include "evcommon.inc"

sb_init:
    jsl ppu_off
    jsl set_mode1_defaults
    jsl load_text_gfx
    VLOAD VRAM_BGTILES, subway_tiles, (subway_bg1 - subway_tiles)
    VLOAD VRAM_BG1MAP, subway_bg1, 2048
    VLOAD VRAM_BG2MAP, subway_tunnel, 4096
    VLOAD VRAM_PLAT, subway_platform, 2048
    PLOAD 32, subway_pal, 96
    VLOAD VRAM_OBJTILES, subway_spr, (subway_spr_pal - subway_spr)
    PLOAD 144, subway_spr_pal, 80
    lda cur_player
    ldy #$0000
    jsl player_palette
    lda #$17
    sta tm_sh
    stz txt_bg
    ldx #$0000
@c:
    stz ev_ram,x
    inx
    cpx #512
    bne @c
    ldx #$2E6B
    stx EV_SEED
    ; start in the station at Bloor-Yonge, doors closing
    lda #1
    sta w_plat
    lda #((VRAM_PLAT >> 8) | 0)
    sta BG2SC
    lda #TP_STOP
    sta w_tp
    ldx #40
    stx w_tt
    lda #ST_DOORS
    sta w_status
    lda #3
    sta w_pal
    rts

; windows: tunnel while moving, the station wall when slow at a stop
sb_windows:
    lda w_plat
    bne @inplat
    ; in the tunnel: arriving (braking and slow)?
    lda w_tp
    cmp #TP_BRAKE
    bne @x
    A16
    lda w_speed
    cmp #$0180
    A8
    bcs @x
    lda #1
    sta w_plat
    lda #((VRAM_PLAT >> 8) | 0)
    sta BG2SC
    rts
@inplat:
    ; leaving: accelerating past a walking pace
    lda w_tp
    cmp #TP_ACCEL
    bne @x
    A16
    lda w_speed
    cmp #$0200
    A8
    bcc @x
    stz w_plat
    lda #((VRAM_BG2MAP >> 8) | 1)
    sta BG2SC
@x:
    rts

; ------------------------------------------------------------------
sb_update:
    jsr train
    jsr balance
    jsr germs_update
    ; patient zero: the ride ends once the 20th germ's grab has played out
    A16
    lda w_germs
    cmp #20
    bcc @alive
    lda w_grab
    bne @alive
    A8
    lda #1
    sta w_done
@alive:
    A16
    lda w_popup
    beq @p
    dec w_popup
    bne @p
    A8
    jsr popup_clear
    A16
@p:
    A8
    rts

; the train: phases, forces, speed
train:
    stz w_fx
    stz w_fx+1
    stz w_fy
    stz w_fy+1
    ; strength grows a little each segment: tmp7 = seg * 2
    lda w_seg
    asl a
    sta tmp7
    stz tmp7+1
    lda w_tp
    cmp #TP_ACCEL
    bne @n0
    jmp tr_accel
@n0:
    cmp #TP_CRUISE
    bne @n1
    jmp tr_cruise
@n1:
    cmp #TP_BRAKE
    bne @n2
    jmp tr_brake
@n2:
    jmp tr_stop

tr_accel:
    lda #ST_ACCEL
    sta w_status
    ; pushed toward the back (left): 0.035 px/f^2 and up
    A16
    lda #9
    clc
    adc tmp7
    eor #$FFFF
    inc a
    sta w_fx
    lda w_speed
    clc
    adc #$0010
    cmp #$0600
    bcc @s
    lda #$0600
@s:
    sta w_speed
    dec w_tt
    A8
    bne @x
    lda #TP_CRUISE
    sta w_tp
    lda #200
    jsr ev_range
    A16
    and #$00FF
    clc
    adc #260
    sta w_tt
    lda #30
    sta w_next
    A8
@x:
    rts

tr_cruise:
    ; curves and jolts on a schedule from the course seed
    A16
    lda w_curve
    beq @nocurve
    dec w_curve
    lda w_cdir
    sta w_fy
    A8
    lda w_cdir+1
    bmi @cr
    lda #ST_LEFT
    bra @cs
@cr:
    lda #ST_RIGHT
@cs:
    sta w_status
    bra @tick
@nocurve:
    A8
    lda #ST_CRUISE
    sta w_status
    A16
    dec w_next
    A8
    bne @tick
    lda #60
    jsr ev_range
    A16
    and #$00FF
    clc
    adc #40
    sta w_next
    A8
    lda #10
    jsr ev_range
    cmp #7
    bcs @jolt
    ; a curve: 60-100 frames, either way
    lda #40
    jsr ev_range
    A16
    and #$00FF
    clc
    adc #60
    sta w_curve
    lda #8
    clc
    adc tmp7
    sta w_cdir
    A8
    lda #2
    jsr ev_range
    beq @tick
    A16
    lda w_cdir
    eor #$FFFF
    inc a
    sta w_cdir
    A8
    bra @tick
@jolt:
    ; track joint: a kick in a random direction
    jsr kick
@tick:
    A16
    dec w_tt
    A8
    bne @x
    lda #TP_BRAKE
    sta w_tp
    ldx #0
    stx w_curve
@x:
    rts

; random impulse to the balance velocity
kick:
    lda #4
    jsr ev_range
    asl a
    TAXB
    A16
    lda f:kick_vx,x
    clc
    adc w_vx
    sta w_vx
    lda f:kick_vy,x
    clc
    adc w_vy
    sta w_vy
    A8
    lda #1
    sta w_shake
    SFX SFX_STEP
    rts

kick_vx: .word $0060, $10000 - $0060, $0026, $10000 - $0026
kick_vy: .word $0026, $10000 - $0026, $0060, $10000 - $0060

tr_brake:
    lda #ST_BRAKE
    sta w_status
    A16
    lda #10
    clc
    adc tmp7
    sta w_fx
    lda w_speed
    sec
    sbc #$000E
    bcs @s
    lda #$0000
@s:
    sta w_speed
    bne @x16
    ; stopped: the classic snap back, doors open
    lda w_vx
    sec
    sbc #$00C0
    sta w_vx
    A8
    lda #TP_STOP
    sta w_tp
    ldx #110
    stx w_tt
    lda #ST_DOORS
    sta w_status
    lda #1
    sta w_shake
    SFX SFX_BELL
    jsr station_sign
    inc w_seg
    ; someone gets on: swap a passenger
    lda w_pal
    inc a
    cmp #5
    bcc @pp
    lda #1
@pp:
    sta w_pal
    rts
@x16:
    A8
    rts

tr_stop:
    lda #ST_DOORS
    sta w_status
    ; a boarding passenger bumps you
    A16
    lda w_tt
    cmp #50
    A8
    bne @nb
    lda w_seg
    beq @nb
    jsr kick
@nb:
    A16
    dec w_tt
    A8
    bne @x
    jsr sign_clear
    ; last stop?
    lda w_seg
    cmp #NUM_SEG
    bcc @go
    lda #1
    sta w_done
    rts
@go:
    lda #TP_ACCEL
    sta w_tp
    ldx #100
    stx w_tt
    SFX SFX_BELL
@x:
    rts

; ------------------------------------------------------------------
; balance: train force + your lean + a little instability, damped
; (tuned with a reaction-delay sim: ~130 ms reflexes ride clean, ~200 ms
;  collect about 6 germs, ~270 ms about 18)
balance:
    A16
    inc w_streak
    lda w_grab
    beq @free
    dec w_grab
    A8
    rts
@free:
    .a16
    ; input: the D-pad leans against the push
    lda pad
    bit #PAD_LEFT
    beq @nl
    lda w_vx
    sec
    sbc #$001C
    sta w_vx
    lda pad
@nl:
    bit #PAD_RIGHT
    beq @nr
    lda w_vx
    clc
    adc #$001C
    sta w_vx
    lda pad
@nr:
    bit #PAD_UP
    beq @nu
    lda w_vy
    sec
    sbc #$001C
    sta w_vy
    lda pad
@nu:
    bit #PAD_DOWN
    beq @nd
    lda w_vy
    clc
    adc #$001C
    sta w_vy
@nd:
    ; v += train force + bx/256 (an upright body tips further once it leans)
    lda w_bx
    jsr int_part
    clc
    adc w_fx
    clc
    adc w_vx
    sta w_vx
    lda w_by
    jsr int_part
    clc
    adc w_fy
    clc
    adc w_vy
    sta w_vy
    ; damping: v -= v/8
    lda w_vx
    jsr asr3
    eor #$FFFF
    inc a
    clc
    adc w_vx
    sta w_vx
    lda w_vy
    jsr asr3
    eor #$FFFF
    inc a
    clc
    adc w_vy
    sta w_vy
    ; position
    lda w_bx
    clc
    adc w_vx
    sta w_bx
    lda w_by
    clc
    adc w_vy
    sta w_by
    ; outside the ring? (integer parts squared)
    lda w_bx
    jsr int_part
    jsr square
    sta tmp1
    lda w_by
    jsr int_part
    jsr square
    clc
    adc tmp1
    cmp #RADIUS2
    A8
    bcc @x
    jsr grab
@x:
    rts

; A16 helpers
asr3:
    .a16
    cmp #$8000
    ror a
    cmp #$8000
    ror a
    cmp #$8000
    ror a
    rts
asr7:
    .a16
    cmp #$8000
    ror a
asr6:
    cmp #$8000
    ror a
asr5:
    cmp #$8000
    ror a
asr4:
    cmp #$8000
    ror a
    cmp #$8000
    ror a
    cmp #$8000
    ror a
    cmp #$8000
    ror a
    rts

; signed 8.8 -> signed integer (A16)
int_part:
    xba
    and #$00FF
    cmp #$0080
    bcc @p
    ora #$FF00
    rts
@p:
    and #$00FF                  ; N/Z from the result, not from the cmp
    rts

; A16 = |A| ^ 2, capped at $7FFF
square:
    bpl @p
    eor #$FFFF
    inc a
@p:
    cmp #128
    bcc @ok
    lda #$7FFF
    rts
@ok:
    A8
    sta WRMPYA
    sta WRMPYB
    nop
    nop
    nop
    nop
    A16
    lda RDMPYL
    rts
.a8

; blank the popup row
popup_clear:
    ldx #(POP_ROW*32)
    A16
    lda #$0120
    sta tmp1
    A8
    stz tmp2
    lda #$20
    jsl txt_fill
    rts

; lost it: grab the nearest thing
grab:
    ; which way? dominant axis
    A16
    lda w_bx
    bpl @ax
    eor #$FFFF
    inc a
@ax:
    sta tmp1
    lda w_by
    bpl @ay
    eor #$FFFF
    inc a
@ay:
    cmp tmp1
    A8
    bcs @lateral
    lda w_bx+1
    bmi @back
    lda #1                      ; forward: the backpack
    ldy #2
    bra @set
@back:
    lda #0                      ; back: the sticky pole
    ldy #1
    bra @set
@lateral:
    lda w_by+1
    bmi @window
    lda #3                      ; toward us: a stranger's lap
    ldy #2
    bra @set
@window:
    lda #2                      ; the far wall: hand on the window
    ldy #1
@set:
    sta w_gkind
    A16
    tya
    clc
    adc w_germs
    sta w_germs
    ; best streak (frames)
    lda w_streak
    cmp w_best
    bcc @nb
    sta w_best
@nb:
    stz w_streak
    stz w_bx
    stz w_by
    stz w_vx
    stz w_vy
    lda #45
    sta w_grab
    A8
    SFX SFX_GROAN
    ; message
    lda w_gkind
    A16
    and #$00FF
    asl a
    tax
    lda f:grab_msgs,x
    sta ptr0
    A8
    lda #^grab_msgs
    sta ptr0+2
    jsr popup_clear
    lda #TXT_WIN
    sta txt_bg
    ldx #(POP_ROW*32)
    lda #($20 | (TP_GREEN << 2))
    jsl txt_print_centre
    stz txt_bg
    ldx #70
    stx w_popup
    jsr spawn_germs
    rts

grab_msgs: .addr gm0, gm1, gm2, gm3
gm0: .byte " GRABBED THE STICKY POLE! ", 0
gm1: .byte " FACE-FIRST INTO A BACKPACK! ", 0
gm2: .byte " HAND ON THE WINDOW. EW! ", 0
gm3: .byte " SAT ON A STRANGER! SORRY! ", 0

; a puff of germs around the hand
spawn_germs:
    ldx #$0000
@g:
    stx w_cur
    lda #24
    jsl rand_range
    ldx w_cur
    clc
    adc #(RIDER_X - 12)
    sta G_X,x
    stz G_X+1,x
    lda #16
    jsl rand_range
    ldx w_cur
    clc
    adc #(RIDER_Y - 40)
    sta G_Y,x
    stz G_Y+1,x
    lda #40
    sta G_L,x
    stz G_L+1,x
    inx
    inx
    cpx #(NUM_GERMS*2)
    bne @g
    rts

germs_update:
    ldx #$0000
@g:
    lda G_L,x
    beq @n
    dec G_L,x
    lda frame
    and #$01
    bne @n
    A16
    dec G_Y,x
    A8
@n:
    inx
    inx
    cpx #(NUM_GERMS*2)
    bne @g
    rts

; station name in a box over the windows
station_sign:
    lda #TXT_WIN
    sta txt_bg
    ldx #(SIGN_ROW*32 + 8)
    A16
    lda #$0310
    sta tmp1
    A8
    lda #$20
    jsl txt_box
    lda w_seg
    A16
    and #$00FF
    asl a
    tax
    lda f:station_names,x
    sta ptr0
    A8
    lda #^station_names
    sta ptr0+2
    ldx #((SIGN_ROW+1)*32)
    lda #($20 | (TP_WHITE << 2))
    jsl txt_print_centre
    stz txt_bg
    rts

sign_clear:
    ldx #(SIGN_ROW*32 + 8)
    A16
    lda #$0310
    sta tmp1
    A8
    stz tmp2
    lda #$20
    jsl txt_fill
    rts

station_names:
    .addr sn_well, sn_coll, sn_dund, sn_queen, sn_king, sn_union
sn_well:  .byte "WELLESLEY", 0
sn_coll:  .byte "COLLEGE", 0
sn_dund:  .byte "DUNDAS", 0
sn_queen: .byte "QUEEN", 0
sn_king:  .byte "KING", 0
sn_union: .byte "UNION", 0

; ------------------------------------------------------------------
sb_draw:
    jsl oam_clear
    ; window view scrolls with the train
    A16
    lda w_scroll
    clc
    adc w_speed
    sta w_scroll
    xba
    and #$00FF
    sta bg2x
    stz bg2y
    stz bg1x
    ; rattle when fast
    lda w_speed
    cmp #$0300
    bcc @still
    lda frame
    and #$0006
    beq @still
    lda #$0001
    bra @b
@still:
    lda #$0000
@b:
    sta bg1y
    A8
    lda w_shake
    beq @ns
    stz w_shake
    A16
    lda #$0002
    sta bg1y
    A8
@ns:
    jsr draw_germs
    jsr draw_ring
    jsr draw_rider
    jsr draw_people
    rts

draw_ring:
    ; dot first so it sits on top of the ring
    A16
    lda w_bx
    jsr int_part
    clc
    adc #RING_X
    sta spr_x
    lda w_by
    jsr int_part
    clc
    adc #RING_Y
    sta spr_y
    ; red when near the edge
    lda w_bx
    jsr int_part
    jsr square
    sta tmp1
    lda w_by
    jsr int_part
    jsr square
    clc
    adc tmp1
    cmp #100
    A8
    bcs @bad
    LDPTR1 ms_dot_ok
    ldx #MS_DOT_OK_BASE
    bra @d
@bad:
    LDPTR1 ms_dot_bad
    ldx #MS_DOT_BAD_BASE
@d:
    stx tmp6
    lda #$3A
    sta tmp5
    stz tmp5+1
    jsl oam_meta
    ldx #RING_X
    stx spr_x
    ldx #RING_Y
    stx spr_y
    LDPTR1 ms_ring
    ldx #MS_RING_BASE
    stx tmp6
    jsl oam_meta
    rts

draw_rider:
    ldx #RIDER_X
    stx spr_x
    ldx #RIDER_Y
    stx spr_y
    lda #$30
    sta tmp5
    stz tmp5+1
    ldx w_grab
    beq @free
    lda w_gkind
    asl a
    TAXB
    lda f:grab_frame,x
    bra @f
@free:
    ; lean frames from the balance offset
    A16
    lda w_by
    jsr int_part
    bpl @ay
    eor #$FFFF
    inc a
@ay:
    cmp #9
    A8
    bcc @lean
    lda #5                      ; arms flailing
    bra @f
@lean:
    A16
    lda w_bx
    jsr int_part
    A8
    cmp #$80
    bcs @neg
    cmp #7
    bcs @f2
    cmp #3
    bcs @f1
    lda #0
    bra @f
@f1:
    lda #3
    bra @f
@f2:
    lda #4
    bra @f
@neg:
    cmp #($100 - 6)
    bcc @b2
    cmp #($100 - 2)
    bcc @b1
    lda #0
    bra @f
@b1:
    lda #1
    bra @f
@b2:
    lda #2
@f:
    asl a
    TAXB
    lda f:rider_lo,x
    sta ptr1
    lda f:rider_lo+1,x
    sta ptr1+1
    lda #^ms_up
    sta ptr1+2
    lda f:rider_base,x
    sta tmp6
    lda f:rider_base+1,x
    sta tmp6+1
    jsl oam_meta
    rts

grab_frame: .byte 6, 0, 7, 0, 5, 0, 8, 0
rider_lo:   .addr ms_up, ms_lb1, ms_lb2, ms_lf1, ms_lf2, ms_wobble, ms_grab_b, ms_grab_f, ms_splat
rider_base: .word MS_UP_BASE, MS_LB1_BASE, MS_LB2_BASE, MS_LF1_BASE, MS_LF2_BASE
            .word MS_WOBBLE_BASE, MS_GRAB_B_BASE, MS_GRAB_F_BASE, MS_SPLAT_BASE

; seated and standing passengers
draw_people:
    ldx #$0000
@p:
    stx w_cur
    lda f:pp_x,x
    sta spr_x
    stz spr_x+1
    lda f:pp_y,x
    sta spr_y
    stz spr_y+1
    lda f:pp_pal,x
    cpx #6                      ; the one by the door changes at each stop
    bne @np
    lda w_pal
@np:
    asl a
    ora #$30
    sta tmp5
    stz tmp5+1
    lda f:pp_kind,x
    asl a
    TAXB
    lda f:pk_lo,x
    sta ptr1
    lda f:pk_lo+1,x
    sta ptr1+1
    lda #^ms_sit_phone
    sta ptr1+2
    lda f:pk_base,x
    sta tmp6
    stz tmp6+1
    jsl oam_meta
    ldx w_cur
    inx
    inx
    cpx #10
    bne @p
    rts

pp_x:    .word 36, 80, 216, 176, 64
pp_y:    .word 151, 151, 151, 196, 196
pp_pal:  .word 1, 3, 2, 4, 2
pp_kind: .word 0, 1, 0, 3, 2
pk_lo:   .addr ms_sit_phone, ms_sit_sleep, ms_strap, ms_backpack
pk_base: .word MS_SIT_PHONE_BASE, MS_SIT_SLEEP_BASE, MS_STRAP_BASE, MS_BACKPACK_BASE

draw_germs:
    ldx #$0000
@g:
    lda G_L,x
    beq @n
    stx w_cur
    lda G_X,x
    sta spr_x
    stz spr_x+1
    A16
    lda G_Y,x
    sta spr_y
    A8
    lda #$3A
    sta tmp5
    stz tmp5+1
    lda frame
    and #$08
    beq @a
    LDPTR1 ms_germ1
    ldx #MS_GERM1_BASE
    bra @d
@a:
    LDPTR1 ms_germ0
    ldx #MS_GERM0_BASE
@d:
    stx tmp6
    jsl oam_meta
    ldx w_cur
@n:
    inx
    inx
    cpx #(NUM_GERMS*2)
    bne @g
    rts

; ------------------------------------------------------------------
sb_hud_full:
    PRINT 1, 1, TP_WHITE, str_germs
    PRINT 14, 1, TP_GREY, str_line
    lda #$FF
    sta w_stat_old
    jsr sb_hud_now
    rts

sb_hud:
    lda frame
    and #$03
    beq sb_hud_now
    rts
sb_hud_now:
    ldx w_germs
    stx tmp1
    ldx #(1*32 + 7)
    ldy #2
    lda #($20 | (TP_GREEN << 2))
    jsl txt_num
    ; next station
    lda w_seg
    cmp #NUM_SEG
    bcs @st
    A16
    and #$00FF
    asl a
    tax
    lda f:station_names,x
    sta ptr0
    A8
    lda #^station_names
    sta ptr0+2
    PRINT 14, 2, TP_GREY, str_next
    ldx #(2*32 + 20)
    A16
    lda #$010B
    sta tmp1
    A8
    stz tmp2
    lda #$20
    jsl txt_fill
    lda w_seg
    A16
    and #$00FF
    asl a
    tax
    lda f:station_names,x
    sta ptr0
    A8
    lda #^station_names
    sta ptr0+2
    ldx #(2*32 + 20)
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_print
@st:
    ; status line
    lda w_status
    cmp w_stat_old
    beq @x
    sta w_stat_old
    ldx #(2*32 + 1)
    A16
    lda #$010C
    sta tmp1
    A8
    stz tmp2
    lda #$20
    jsl txt_fill
    lda w_status
    A16
    and #$00FF
    asl a
    tax
    lda f:status_msgs,x
    sta ptr0
    A8
    lda #^status_msgs
    sta ptr0+2
    lda w_status
    TAXB
    lda f:status_tp,x
    ldx #(2*32 + 1)
    jsl txt_print
@x:
    rts

str_germs: .byte "GERMS", 0
str_line:  .byte "BLOOR ", TXT_ARROW_R + 32, " UNION", 0
str_next:  .byte "NEXT:", 0
status_msgs: .addr ss0, ss1, ss2, ss3, ss4, ss5, ss6
status_tp:   .byte ($20 | (TP_WHITE << 2)), ($20 | (TP_ORANGE << 2)), ($20 | (TP_GREY << 2))
             .byte ($20 | (TP_CYAN << 2)), ($20 | (TP_CYAN << 2)), ($20 | (TP_RED << 2))
             .byte ($20 | (TP_YELLOW << 2))
ss0: .byte " ", 0
ss1: .byte "GO! GO! GO!", 0
ss2: .byte "CRUISING", 0
ss3: .byte "CURVE LEFT", 0
ss4: .byte "CURVE RIGHT", 0
ss5: .byte "BRAKING!", 0
ss6: .byte "DOORS OPEN", 0

; ------------------------------------------------------------------
; score: 2000 - 100 per germ (floor 0) + 5 per second of best streak (max 300)
sb_score:
    A16
    lda w_streak
    cmp w_best
    bcc @k
    sta w_best
@k:
    lda w_best
    sta tmp0
    A8
    lda #60
    jsl div16
    A16
    lda tmp0
    cmp #60
    bcc @c
    lda #60
@c:
    sta ev_stat+4               ; best streak, seconds
    asl a
    asl a
    clc
    adc ev_stat+4               ; *5
    sta tmp4
    lda w_germs
    sta ev_stat
    lda w_seg
    sta ev_stat+2               ; stations reached
    ; 2000 - 100*germs
    lda w_germs
    cmp #20
    bcc @g
    lda #20
@g:
    asl a
    asl a
    sta tmp1                    ; 4g
    asl a
    asl a
    asl a                       ; 32g
    sta tmp2
    asl a                       ; 64g
    clc
    adc tmp2
    clc
    adc tmp1                    ; 100g
    eor #$FFFF
    sec
    adc #2000
    clc
    adc tmp4
    sta ev_score
    A8
    stz ev_fail
    lda w_germs
    cmp #20
    bcc @x
    lda #$01
    sta ev_fail
@x:
    rts

.include "subway_meta.inc"
