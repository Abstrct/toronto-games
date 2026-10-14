; EVENT 1: BIKE COURIER — Queen St West, top-down.
; Pedal up Queen without getting doored, eating a pothole, or meeting the
; 501 head-on. Everyone rides the same course (fixed seed). The first stretch
; (WARMUP) is a quiet warm-up: wide gaps, no doors, nothing in the bike lane.
;
; Controls: D-pad steers (the bike goes where you point it and settles the
; moment you let go), A or UP pedals, DOWN brakes, B or Y bunny-hops.
; STYLE (all of it earned with the hop button or a risk):
;   TRACK HOP    hop, and be in the air as you cross a streetcar rail
;   POTHOLE HOP  hop clean over a pothole
;   CLOSE CALL   in the way of a car or the 501, slip out just in time
;   DRAFTING     tuck in behind the 501: it pulls you along
; Mix them inside 2.5 s of each other and they chain, x2 .. x8. Cross a rail
; on the ground and the groove grabs your wheel: RAIL WOBBLE, a quarter of
; your speed and the chain. Sit in one line too long and Queen St comes for
; you: a fresh pothole in your lane, or the 501 up the tracks behind you.
.p816
.smart -
.include "globals.inc"
.include "screens.inc"

.import bike_tiles, bike_map, bike_pal, bike_spr, bike_spr_pal

PLAYER_SY   = 176
COURSE_LEN  = 9000
WARMUP      = 3200          ; the first ~20 s: sparse, wide gaps, a quiet bike lane
TIME_LIMIT  = 80*60
MAXSPD      = $0300
ACCEL       = $000A
BRAKE       = $0024
COAST       = $0003
STROKE_T    = 12            ; each tap of A / UP is a pedal stroke this long
; steering: hold to slide over at STEER_SPD, let go and it settles in
; ~4 frames (a few px), so a tap moves a little and a hold moves a lot
STEER_SPD   = $0200
STEER_ACC   = $0040         ; up to speed in 8 frames
STEER_REL   = $0080         ; let go / reverse: stops in 4
HOP_SPD     = $0140         ; a hop needs this much forward speed
HOP_T       = 20            ; frames in the air
HOP_CD      = 10            ; frames on the ground before the next hop
HOP_GAP     = 240           ; road between two scoring track hops
WOB_T       = 24
BIKE_LANE   = 186           ; start / respawn here (clear of the 501 and the doors)
INV_GETUP   = 120           ; blink frames after getting back on
WIPE_COST   = 200           ; points per wipeout on a delivered run
CHAIN_WIN   = 150           ; 2.5 s to land the next style move
CHAIN_MAX   = 8
STYLE_CAP   = 50000
CAMP_T      = 300           ; 5 s in one line...
CAMP_BAND   = 12            ; ...means within this many px
STILL_T     = 480           ; 8 s stopped: FIRED
DRAFT_TICK  = 36            ; frames of slipstream per DRAFT move
POP_ROW     = 16            ; crash messages: just over the rider

ST_RIDE   = 0
ST_CRASH  = 1
ST_FINISH = 2
ST_DONE   = 3

; causes (popup text)
CA_DOOR  = 0
CA_TRACK = 1
CA_CAR   = 2
CA_TRAM  = 3
CA_HOLE  = 4
CA_PED   = 5
CA_REAR  = 6

; style moves
SM_HOP   = 0
SM_CLOSE = 1
SM_DRAFT = 2
SM_BUNNY = 3

; run state (words)
b_px     = ev_ram + 0
b_vx     = ev_ram + 2
b_speed  = ev_ram + 4
b_dist   = ev_ram + 6
b_distf  = ev_ram + 8
b_time   = ev_ram + 10
b_state  = ev_ram + 12
b_timer  = ev_ram + 14
b_inv    = ev_ram + 16
b_tokens = ev_ram + 18
b_near   = ev_ram + 20
b_wipes  = ev_ram + 22
b_nextsp = ev_ram + 24
b_seed   = ev_ram + 26
b_popup  = ev_ram + 28
b_bell   = ev_ram + 30
b_shake  = ev_ram + 32
b_oldx   = ev_ram + 34
b_finish = ev_ram + 36
b_banner = ev_ram + 38
b_hopcd  = ev_ram + 42      ; frames until the next hop is allowed
b_hopsc  = ev_ram + 44      ; 1 = this hop already scored a rail
b_prow   = ev_ram + 46      ; 1 = a crash message is up on POP_ROW
b_fired  = ev_ram + 48      ; 1 = stood still too long: YOU'RE FIRED! (ev_fail 4)
b_stroke = ev_ram + 50      ; frames left in the last pedal stroke (a tap of A)
; drawer / HUD bookkeeping (cleared by init, < 512)
b_oamhw  = ev_ram + 384     ; OAM bytes used last frame (the local clear)
b_hq     = ev_ram + 386     ; HUD caches: what is on screen now
b_hw     = ev_ram + 388
b_ht     = ev_ram + 390
b_htk    = ev_ram + 392
b_tout   = ev_ram + 394     ; 1 = the clock ran out
b_pass   = ev_ram + 396     ; ents_draw pass: 0 traffic, 1 road-level things
b_hop    = ev_ram + 400     ; frames left in the air
b_hopd   = ev_ram + 402     ; distance at the last scoring hop
b_wob    = ev_ram + 404     ; frames left wobbling
b_chain  = ev_ram + 406     ; style chain (0 = none)
b_chaint = ev_ram + 408     ; frames left to extend it
b_style  = ev_ram + 410     ; style points
b_camp   = ev_ram + 412     ; frames in one line
b_campx  = ev_ram + 414     ; ...which line
b_still  = ev_ram + 416     ; frames stopped
b_draft  = ev_ram + 418     ; frames in the slipstream (toward a DRAFT move)
b_indr   = ev_ram + 420     ; 1 = in a slipstream this frame
b_quit   = ev_ram + 422     ; 1 = gave up from the pause menu
b_crank  = ev_ram + 424     ; pedal phase (8.8, wraps)
b_hch    = ev_ram + 426     ; HUD cache: chain shown
b_kind   = ev_ram + 428
b_dcap   = ev_ram + 430     ; top speed in the slipstream (the 501's + a bit)
b_lastk  = ev_ram + 464     ; the last style move
b_pbuf   = ev_ram + 432     ; popup text built here (24 bytes)

; entities: one word per entity per field, X = index * 2
NUM_ENT = 16
E_TYPE  = ev_ram + 64
E_X     = ev_ram + 96       ; 8.8
E_WY    = ev_ram + 128
E_WYF   = ev_ram + 160
E_VY    = ev_ram + 192      ; 8.8 signed
E_VX    = ev_ram + 224
E_TIMER = ev_ram + 256
E_PAL   = ev_ram + 288
E_FLAGS = ev_ram + 320      ; 1 close call counted, 2 door open, 4 bumped, 8 fresh, $10 brakes, $20 in its path
E_REL   = ev_ram + 352

T_NONE     = 0
T_PARKED   = 1
T_PARKED_S = 2
T_CAR_N    = 3
T_CAR_S    = 4
T_TRAM_N   = 5
T_TRAM_S   = 6
T_POTHOLE  = 7
T_TOKEN    = 8
T_PED      = 9
T_FINISH   = 10

.segment "EVENTS1"
.a8
.i16

ev_bike:
    phb
    phk
    plb
    jsr bike_init
    jsr bike_draw
    jsl event_card
    jsr hud_full
    jsl event_countdown
    lda #SONG_BIKE
    jsl music_play
@loop:
    jsl wait_frame
    lda ev_giveup               ; pause menu: GIVE UP ends the run now...
    beq @play
    lda b_state                 ; ...unless it already ended on its own
    cmp #ST_FINISH              ; (delivered, fired: that result stands)
    beq @over
    cmp #ST_DONE
    beq @over
    cmp #ST_CRASH               ; (the third wipeout: WIPED OUT! stands)
    bne @quit
    lda b_wipes
    cmp #3
    bcs @over
@quit:
    lda #$01
    sta b_quit
    bra @over
@play:
    jsr bike_update
    jsr bike_draw
    jsr bike_hud
    lda b_state
    cmp #ST_DONE
    bne @loop
@over:
    jsl music_stop
    jsr bike_score
    jsl score_card
    plb
    rtl

; ------------------------------------------------------------------
bike_init:
    jsl ppu_off
    jsl set_mode1_defaults
    jsl load_text_gfx
    VLOAD VRAM_BGTILES, bike_tiles, (bike_map - bike_tiles)
    VLOAD VRAM_BG1MAP, bike_map, 2048
    PLOAD 32, bike_pal, 96
    VLOAD VRAM_OBJTILES, bike_spr, (bike_spr_pal - bike_spr)
    PLOAD 144, bike_spr_pal, 112
    lda cur_player
    ldy #$0000
    jsl player_palette
    lda #$15                    ; BG1, BG3, sprites
    sta tm_sh
    stz txt_bg
    ldx #$0000
@clr:
    stz ev_ram,x
    inx
    cpx #512
    bne @clr
    ldx #(BIKE_LANE*256)
    stx b_px
    ldx #TIME_LIMIT
    stx b_time
    ldx #$9E37
    stx b_seed
    ldx #300
    stx b_nextsp
    ldx #($10000 - HOP_GAP)
    stx b_hopd
    ldx #BIKE_LANE
    stx b_campx
    jsr spawn_ahead
    rts

; ------------------------------------------------------------------
bike_update:
    lda b_state
    cmp #ST_RIDE
    beq @ride
    cmp #ST_CRASH
    beq @crash
    jmp @finish
@ride:
    jsr steer_and_pedal
    jsr move_x
    jsr ride_checks
    jmp @common
@crash:
    jsr slow_down
    A16
    dec b_timer
    A8
    bne @common
    lda b_wipes
    cmp #3
    bcc @getup
    lda #ST_DONE
    sta b_state
    rts
@getup:
    ; back on the bike in the bike lane (never in live traffic), blinking
    lda #ST_RIDE
    sta b_state
    ldx #INV_GETUP
    stx b_inv
    ldx #(BIKE_LANE*256)
    stx b_px
    stx b_oldx
    ldx #$0000
    stx b_vx
    stx b_camp
    stx b_still
    ldx #BIKE_LANE
    stx b_campx
    jsr clear_ahead
    bra @common
@finish:
    jsr slow_down
    A16
    dec b_timer
    A8
    bne @common
    lda #ST_DONE
    sta b_state
    rts

@common:
    ; distance += speed (8.8)
    A16
    lda b_distf
    and #$00FF
    clc
    adc b_speed
    pha
    and #$00FF
    sta b_distf
    pla
    xba
    and #$00FF
    clc
    adc b_dist
    sta b_dist
    ; clock
    lda b_state
    and #$00FF
    cmp #ST_FINISH
    beq @noclock
    lda b_time
    beq @timeup
    dec b_time
    bra @noclock
@timeup:
    A8
    lda #$01
    sta b_tout
    lda #ST_DONE
    sta b_state
    rts
@noclock:
    .a16
    lda b_inv
    beq @noinv
    dec b_inv
@noinv:
    lda b_shake
    beq @noshake
    dec b_shake
@noshake:
    lda b_hop
    beq @nohop
    dec b_hop
@nohop:
    lda b_hopcd
    beq @nohopcd
    dec b_hopcd
@nohopcd:
    lda b_wob
    beq @nowob
    dec b_wob
@nowob:
    lda b_chaint
    beq @nochain
    dec b_chaint
    bne @nochain
    stz b_chain
@nochain:
    lda b_popup
    beq @nopop
    dec b_popup
    bne @nopop
    A8
    jsr pop_clear
    A16
@nopop:
    ; delivered?
    lda b_state
    and #$00FF
    bne @nofin
    lda b_dist
    cmp #COURSE_LEN
    bcc @nofin
    A8
    lda #ST_FINISH
    sta b_state
    ldx #100
    stx b_timer
    SFX SFX_CHEER
    LDPTR0 str_delivered
    lda #TP_GREEN
    jsr pop_mid
    ldx #200
    stx b_popup
    A16
@nofin:
    A8
    jsr spawn_ahead
    jsr ents_update
    rts

str_delivered: .byte "DELIVERED!", 0

; once a frame while riding: FIRED for standing still, and Queen St
; punishing anyone who sits in one line
ride_checks:
    A16
    lda b_speed
    cmp #$0040
    bcs @moving
    inc b_still
    lda b_still
    cmp #STILL_T
    bcc @camp
    A8
    lda #$01                    ; ends as YOU'RE FIRED! (ev_fail 4), a DNF
    sta b_fired
    lda #ST_FINISH
    sta b_state
    ldx #90
    stx b_timer
    SFX SFX_GROAN
    LDPTR0 str_fired
    lda #TP_RED
    jsr pop_mid
    ldx #200
    stx b_popup
    rts
@moving:
    .a16
    stz b_still
@camp:
    ; same line (within CAMP_BAND px) for CAMP_T frames? (not in the warm-up)
    lda b_dist
    cmp #WARMUP
    bcs @campon
    stz b_camp
    A8
    rts
@campon:
    .a16
    lda b_px
    xba
    and #$00FF
    sta tmp1
    sec
    sbc b_campx
    bpl @cp
    eor #$FFFF
    inc a
@cp:
    cmp #CAMP_BAND
    bcc @same
    lda tmp1
    sta b_campx
    stz b_camp
    A8
    rts
@same:
    .a16
    inc b_camp
    lda b_camp
    cmp #CAMP_T
    bcs @punish
    A8
    rts
@punish:
    stz b_camp
    A8
    jmp punish_camper

str_fired: .byte "STOPPED? YOU'RE FIRED!", 0

; after a wipeout: nothing waiting right on top of the respawn point
; (potholes, people, doors about to open within ~1.5 screens)
clear_ahead:
    ldx #$0000
@e:
    lda E_TYPE,x
    beq @n
    A16
    lda E_WY,x
    sec
    sbc b_dist
    clc
    adc #40
    cmp #360                    ; rel -40 .. +320
    A8
    bcs @n
    lda E_TYPE,x
    cmp #T_POTHOLE
    beq @kill
    cmp #T_PED
    beq @kill
    cmp #T_PARKED
    bne @n
    A16
    stz E_TIMER,x               ; this door stays shut
    A8
    lda E_FLAGS,x
    and #$FD
    sta E_FLAGS,x
    bra @n
@kill:
    A16
    stz E_TYPE,x
    A8
@n:
    inx
    inx
    cpx #(NUM_ENT*2)
    bne @e
    rts

; speed decays while down / after the line
slow_down:
    A16
    lda b_speed
    sec
    sbc #$0010
    bcs @ok
    lda #$0000
@ok:
    sta b_speed
    stz b_vx
    A8
    rts

steer_and_pedal:
    A16
    ; bunny hop: B or Y, at speed, on the ground, off cooldown
    lda pad_new
    and #(PAD_B | PAD_Y)
    beq @nohop
    lda b_hop
    ora b_hopcd
    bne @nohop
    lda b_speed
    cmp #HOP_SPD
    bcc @nohop
    lda #HOP_T
    sta b_hop
    lda #(HOP_T + HOP_CD)
    sta b_hopcd
    stz b_hopsc
    A8
    SFX SFX_JUMP
    A16
@nohop:
    ; steering: the bike goes where the pad points and settles on release
    lda pad
    bit #PAD_LEFT
    bne @left
    bit #PAD_RIGHT
    bne @right
    lda b_vx
    beq @sv
    bmi @neg
    sec
    sbc #STEER_REL
    bpl @sv
    lda #$0000
    bra @sv
@neg:
    clc
    adc #STEER_REL
    bmi @sv
    lda #$0000
    bra @sv
@left:
    lda b_vx
    beq @la
    bmi @la
    sec
    sbc #STEER_REL              ; reversing: brake the slide first
    bra @lc
@la:
    sec
    sbc #STEER_ACC
@lc:
    bpl @sv
    cmp #($10000 - STEER_SPD)
    bcs @sv
    lda #($10000 - STEER_SPD)
    bra @sv
@right:
    lda b_vx
    bpl @ra
    clc
    adc #STEER_REL
    bra @rc
@ra:
    clc
    adc #STEER_ACC
@rc:
    bmi @sv
    cmp #STEER_SPD
    bcc @sv
    lda #STEER_SPD
@sv:
    sta b_vx
    ; pedal / brake / coast; a slipstream lifts the top speed
    lda #MAXSPD
    ldx b_indr
    beq @cap
    cmp b_dcap
    bcs @cap
    lda b_dcap
@cap:
    sta tmp2
    ; every tap of A / UP is a pedal stroke (so mashing rides as well as
    ; holding); DOWN on its own brakes, even mid-stroke
    lda pad_new
    and #(PAD_A | PAD_UP)
    beq @nostroke
    lda #STROKE_T
    sta b_stroke
@nostroke:
    lda b_stroke
    beq @sk
    dec b_stroke
@sk:
    lda pad
    bit #(PAD_A | PAD_UP)
    bne @pedal
    bit #PAD_DOWN
    bne @no_pedal
    ldx b_stroke
    beq @no_pedal
@pedal:
    lda b_speed
    clc
    adc #ACCEL
    ldx b_indr
    beq @p1
    clc
    adc #ACCEL                  ; pulled along: twice the pickup
@p1:
    cmp tmp2
    bcc @ss
    ; over the top speed (just left a slipstream): ease down to it
    lda b_speed
    sec
    sbc #$0004
    bcc @top
    cmp tmp2
    bcs @ss
@top:
    lda tmp2
    bra @ss
@no_pedal:
    bit #PAD_DOWN
    beq @coast
    lda b_speed
    sec
    sbc #BRAKE
    bcs @ss
    lda #$0000
    bra @ss
@coast:
    lda b_speed
    sec
    sbc #COAST
    bcs @ss
    lda #$0000
@ss:
    sta b_speed
    clc
    adc b_crank                 ; the cranks turn with the wheels
    sta b_crank
    A8
    rts

; x += vx, clamp to the road, check streetcar rails
move_x:
    A16
    lda b_px
    sta b_oldx
    jsr settle
    clc
    adc b_vx
    cmp #(26*256)
    bcs @lo_ok
    lda #(26*256)
    stz b_vx
@lo_ok:
    cmp #(230*256)
    bcc @hi_ok
    lda #(230*256)
    stz b_vx
@hi_ok:
    sta b_px
    A8
    ldy #$0000
@rail:
    tyx
    lda f:rails,x
    sta tmp0                    ; rail centre
    lda b_oldx+1
    cmp tmp0
    lda #$00
    rol a                       ; 1 if old >= rail
    sta tmp0+1
    lda b_px+1
    cmp tmp0
    lda #$00
    rol a
    cmp tmp0+1
    beq @next
    jsr rail_cross
@next:
    iny
    cpy #4
    bne @rail
    rts

; crossed a rail. In the air (a hop): TRACK HOP, once a hop, HOP_GAP of
; road between scoring ones. On the ground the groove grabs the front wheel:
; RAIL WOBBLE (a quarter of your speed and the chain). Keeps Y.
rail_cross:
    lda b_hop
    beq @ground
    lda b_hopsc
    jne @x
    lda #$01
    sta b_hopsc
    A16
    lda b_dist
    sec
    sbc b_hopd
    cmp #HOP_GAP
    jcc @x16
    lda b_dist
    sta b_hopd
    A8
    phy
    lda #SM_HOP
    jsr style_award
    ply
    rts
@ground:
    A16
@wobble:
    .a16
    lda b_wob
    bne @x16
    lda #WOB_T
    sta b_wob
    lda #8
    sta b_shake
    lda b_speed                 ; lose a quarter of your speed
    lsr a
    lsr a
    eor #$FFFF
    sec
    adc b_speed
    sta b_speed
    stz b_chain
    stz b_chaint
    A8
    phy
    SFX SFX_STEP
    LDPTR0 str_wobble
    lda #TP_ORANGE
    jsr pop_mid
    ldx #50
    stx b_popup
    ply
    rts
@x16:
    A8
@x:
    rts

; Hands off the pad and not sliding: ease into the nearest riding line
; (within SETTLE_W px) at half a px a frame, so a tap that ends a few px
; off still lands you in the lane. A16 in/out: A = b_px -> A = new b_px.
SETTLE_W = 7
settle:
    .a16
    ldx b_vx
    bne @x
    tax                         ; keep b_px
    lda pad
    and #(PAD_LEFT | PAD_RIGHT)
    bne @keep
    lda b_state
    and #$00FF
    bne @keep
    ldy #$0000
@l:
    lda lines,y
    and #$00FF
    xba                         ; line * 256
    sta tmp1
    txa
    sec
    sbc tmp1                    ; px - line (signed 8.8)
    bpl @pos
    eor #$FFFF
    inc a
    cmp #((SETTLE_W + 1) * 256)
    bcs @n
    cmp #$0081
    bcc @snap
    txa
    clc
    adc #$0080
    rts
@pos:
    cmp #((SETTLE_W + 1) * 256)
    bcs @n
    cmp #$0081
    bcc @snap
    txa
    sec
    sbc #$0080
    rts
@snap:
    lda tmp1
    rts
@n:
    iny
    cpy #(lines_end - lines)
    bne @l
@keep:
    txa
@x:
    rts

; the riding lines: the left parking lane, the southbound lane, between
; the southbound rails, by the yellow line, the northbound lane, between
; the northbound rails, the bike lane
lines: .byte 40, 66, 95, 117, 140, 163, BIKE_LANE
lines_end:
.a8

str_wobble: .byte "RAIL WOBBLE! HOP RAILS: B", 0

rails:
    .byte 83, 107, 151, 175

; crash: A = cause. Only while riding and not invulnerable.
crash:
    phx
    phy
    pha
    lda b_state
    cmp #ST_RIDE
    bne @no
    ldx b_inv
    bne @no
    lda #ST_CRASH
    sta b_state
    ldx #80
    stx b_timer
    inc b_wipes
    A16
    lda b_speed
    lsr a
    sta b_speed
    stz b_vx
    stz b_chain
    stz b_chaint
    stz b_draft
    stz b_hop
    stz b_wob
    lda #14
    sta b_shake
    A8
    SFX SFX_CRASH
    pla
    A16
    and #$00FF
    asl a
    tax
    lda f:crash_msgs,x
    sta ptr0
    A8
    lda #^crash_msgs
    sta ptr0+2
    jsr pop_near
    ldx #80
    stx b_popup
    ply
    plx
    rts
@no:
    pla
    ply
    plx
    rts

; ------------------------------------------------------------------
; popups. pop_mid: ptr0 = text, A = palette, the usual centre banner (row 9).
; pop_near: ptr0 = text, in yellow on POP_ROW right over the rider, so a
; wipeout's SPLAT! lands where the crash is. pop_clear: whichever is up.
pop_mid:
    pha
    jsr pop_clear
    pla
    jsl event_popup
    rts

pop_near:
    jsr pop_clear
    ; length -> tmp6
    ldy #$0000
@len:
    lda [ptr0],y
    beq @got
    iny
    bra @len
@got:
    sty tmp6
    ; column: rider column - len/2, kept on screen (1 .. 31-len)
    lda b_px+1
    lsr a
    lsr a
    lsr a
    sta tmp7
    lda tmp6
    lsr a
    sta tmp6+1
    lda tmp7
    sec
    sbc tmp6+1
    bcs @c1
    lda #$00
@c1:
    cmp #1
    bcs @c2
    lda #1
@c2:
    sta tmp7
    lda #31
    sec
    sbc tmp6
    cmp tmp7
    bcs @c3
    sta tmp7
@c3:
    A16
    lda tmp7
    and #$00FF
    clc
    adc #(POP_ROW*32)
    tax
    A8
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_print
    lda #$01
    sta b_prow
    rts

pop_clear:
    jsl event_popup_clear
    lda b_prow
    beq @x
    stz b_prow
    ldx #(POP_ROW*32)
    A16
    lda #$0120
    sta tmp1
    A8
    stz tmp2
    lda #$20
    jsl txt_fill
@x:
    rts

crash_msgs: .addr cm0, cm1, cm2, cm3, cm4, cm5, cm6
cm0: .byte "DOORED!", 0
cm1: .byte "CAUGHT A TRACK!", 0     ; (unused: rails wobble now)
cm2: .byte "SPLAT!", 0
cm3: .byte "HIT BY THE 501!", 0
cm4: .byte "POTHOLE!", 0
cm5: .byte "SORRY! SORRY!", 0
cm6: .byte "KISSED THE 501!", 0

; ------------------------------------------------------------------
; style_award: A = SM_ move. A different move inside CHAIN_WIN frames
; raises the chain (x2..x8), the same move again just keeps it alive;
; points = base * chain. Banner "TRACK HOP! X3 +45".
style_award:
    sta b_kind
    A16
    lda b_chaint
    beq @first
    lda b_kind                  ; the same move again keeps the chain going;
    cmp b_lastk                 ; a different one raises it
    beq @keep
    lda b_chain
    cmp #CHAIN_MAX
    bcs @keep
    inc a
    bra @set
@first:
    lda #$0001
@set:
    sta b_chain
@keep:
    lda b_kind
    sta b_lastk
    lda #CHAIN_WIN
    sta b_chaint
    ; points = base * chain
    lda b_kind
    and #$00FF
    tax
    lda f:sm_base,x
    and #$00FF
    sta tmp1
    lda #$0000
    ldx b_chain
@mul:
    clc
    adc tmp1
    dex
    bne @mul
    sta tmp1                    ; this move's points
    clc
    adc b_style
    cmp #STYLE_CAP              ; (keeps RIDE + TIPS inside 16 bits)
    bcc @cap
    lda #STYLE_CAP
@cap:
    sta b_style
    ; banner text
    lda b_kind
    and #$00FF
    asl a
    tax
    lda f:sm_names,x
    sta ptr1
    A8
    lda #^sm_names
    sta ptr1+2
    ldx #$0000
    ldy #$0000
@cpy:
    lda [ptr1],y
    beq @named
    sta b_pbuf,x
    inx
    iny
    bra @cpy
@named:
    lda b_chain
    cmp #2
    bcc @nox
    lda #' '
    sta b_pbuf,x
    inx
    lda #'X'
    sta b_pbuf,x
    inx
    lda b_chain
    clc
    adc #'0'
    sta b_pbuf,x
    inx
@nox:
    lda #' '
    sta b_pbuf,x
    inx
    lda #'+'
    sta b_pbuf,x
    inx
    ; tmp1 < 1000: up to three digits, no leading zeros
    A16
    stz tmp2                    ; 1 once a digit is out
    lda tmp1
    ldy #100
    jsr @digit
    ldy #10
    jsr @digit
    A8
    clc
    adc #'0'
    sta b_pbuf,x
    inx
    stz b_pbuf,x
    LDPTR0 b_pbuf
    lda b_chain
    cmp #3
    lda #TP_CYAN
    bcc @pal
    lda #TP_YELLOW              ; x3, x4: gold
@pal:
    jsr pop_mid
    ldx #50
    stx b_popup
    SFX SFX_COIN
    rts
; A16 = value, Y = place: emits a digit (skips leading zeros), A = remainder
@digit:
    .a16
    sty tmp3
    ldy #$0000
@d:
    cmp tmp3
    bcc @dd
    sec
    sbc tmp3
    iny
    bra @d
@dd:
    pha
    tya
    ora tmp2
    beq @skip
    tya
    clc
    adc #'0'
    A8
    sta b_pbuf,x
    lda #$01
    sta tmp2
    A16
    inx
@skip:
    pla
    rts

sm_base:  .byte 60, 100, 60, 80     ; x the chain (x8 max: 800, three digits)
sm_names: .addr smn0, smn1, smn2, smn3
smn0: .byte "TRACK HOP!", 0
smn1: .byte "CLOSE CALL!", 0
smn2: .byte "DRAFTING THE 501", 0
smn3: .byte "POTHOLE HOP!", 0

; ------------------------------------------------------------------
bike_draw:
    jsr oam_wipe
    A16
    lda b_dist
    eor #$FFFF
    inc a
    sta bg1y
    stz bg1x
    lda b_shake
    beq @noshake
    and #$0002
    beq @l
    lda #$0002
    bra @s
@l:
    lda #$FFFE
@s:
    sta bg1x
@noshake:
    A8
    jsr draw_player
    jsr draw_warning
    ; traffic first (on top), then things lying on the road
    stz b_pass
    jsr ents_draw
    lda #$01
    sta b_pass
    jsr ents_draw
    ldx oam_idx
    stx b_oamhw
    rts

; Hide only the sprites we used last frame (oam_clear walks all 128 + the
; high table every frame, which this event can't afford).
oam_wipe:
    A16
    lda #$F000                  ; x = 0, y = 240
    ldx b_oamhw
    beq @hi
@l:
    dex
    dex
    dex
    dex
    sta oam_buf,x
    bne @l
@hi:
    ldx #30
@h:
    stz oam_hi,x
    dex
    dex
    bpl @h
    stz oam_idx
    A8
    rts

draw_player:
    ; blink while invulnerable
    lda b_inv
    beq @show
    lda frame
    and #$04
    beq @show
    rts
@show:
    A16
    lda b_px
    xba
    and #$00FF
    sta spr_x
    lda #PLAYER_SY
    sta spr_y
    A8
    lda #$20
    sta tmp5
    lda b_state
    cmp #ST_CRASH
    beq @crash
    jmp @riding
@crash:
    ; wipeout: cartwheel up the road for 20 frames, then sit there dazed
    A16
    lda #80
    sec
    sbc b_timer
    cmp #20
    bcc @t
    lda #20
@t:
    lsr a
    sta tmp6
    lda spr_y
    sec
    sbc tmp6
    sta spr_y
    lda b_timer
    cmp #60
    A8
    bcc @down
    lda b_timer
    and #$04
    beq @tb
    LDPTR1 bm_tumble1
    jmp bmeta
@tb:
    LDPTR1 bm_tumble0
    jmp bmeta
@down:
    LDPTR1 bm_rider_crash
    jsr bmeta
    ; stars over the head
    lda frame
    and #$08
    bne @p1
    LDPTR1 bm_pow0
    bra @pow
@p1:
    LDPTR1 bm_pow1
@pow:
    A16
    lda spr_y
    sec
    sbc #18
    sta spr_y
    A8
    lda #$2E                    ; palette 7
    sta tmp5
    jmp bmeta
@riding:
    ; RAIL WOBBLE: the bike snakes left-right, 2 px each way, leaning into it
    lda b_wob
    beq @nowob
    A16
    lda frame
    and #$0004
    dec a
    dec a
    clc
    adc spr_x
    sta spr_x
    lda frame
    and #$0004
    lsr a
    clc
    adc #4                      ; lean left (4) / lean right (6)
    jmp @pick
    .a8
@nowob:
    ; pedal phase from the cranks; lean frames when steering hard
    A16
    lda b_crank
    xba
    lsr a
    lsr a
    lsr a
    lsr a
    and #$0003
    sta tmp6
    lda b_vx
    bmi @left
    cmp #$0081
    bcc @straight
    lda tmp6                    ; right: 6 + phase/2
    lsr a
    clc
    adc #6
    bra @pick
@left:
    cmp #($10000 - $80)
    bcs @straight
    lda tmp6                    ; left: 4 + phase/2
    lsr a
    clc
    adc #4
    bra @pick
@straight:
    lda tmp6
@pick:
    asl a
    tax
    lda f:rider_tab,x
    sta ptr1
    ; TRACK HOP: up in the air over a shadow
    lda b_hop
    and #$00FF
    tax
    lda f:hop_lift,x
    and #$00FF
    sta tmp6
    lda spr_y
    sec
    sbc tmp6
    sta spr_y
    A8
    lda #^rider_tab
    sta ptr1+2
    jsr bmeta
    lda tmp6
    beq @noshadow
    A16
    lda #(PLAYER_SY + 12)
    sta spr_y
    A8
    lda #$2E                    ; FX palette
    sta tmp5
    LDPTR1 bm_shadow
    jsr bmeta
@noshadow:
    ; in a slipstream: wind streaks either side
    lda b_indr
    beq @x
    lda frame
    and #$02
    beq @x
    A16
    lda #(PLAYER_SY + 6)
    sta spr_y
    lda spr_x
    sec
    sbc #11
    sta spr_x
    A8
    lda #$2A
    sta tmp5
    LDPTR1 bm_wind
    jsr bmeta
    A16
    lda spr_x
    clc
    adc #22
    sta spr_x
    A8
    LDPTR1 bm_wind
    jmp bmeta
@x:
    rts

rider_tab:
    .addr bm_rider_0, bm_rider_1, bm_rider_2, bm_rider_3
    .addr bm_rider_l0, bm_rider_l1, bm_rider_r0, bm_rider_r1
; px of lift by frames left in the air (HOP_T = 20)
hop_lift: .byte 0, 1, 3, 4, 5, 6, 7, 8, 9, 9, 9, 9, 9, 8, 7, 6, 5, 4, 3, 1, 0
.assert HOP_T = 20, error, "hop_lift: one entry per frame in the air"

; streetcar coming up behind: blinking sign + bell
draw_warning:
    lda b_bell
    bne @on
    rts
@on:
    stz b_bell
    lda frame
    and #$1F
    bne @nobell
    SFX SFX_BELL
@nobell:
    lda frame
    and #$08
    bne @x
    A16
    lda #164
    sta spr_x
    lda #200
    sta spr_y
    A8
    lda #$3A                    ; palette 5, priority 3
    sta tmp5
    LDPTR1 bm_warn
    jmp bmeta
@x:
    rts

; ------------------------------------------------------------------
; HUD on a solid BG3 band (BG3 is on top, so traffic slides under it).
; One item per frame, and only when its value changed.
hud_full:
    A16
    lda #$0220                  ; 32 x 2: rows 0-1
    sta tmp1
    A8
    lda #(TXT_SPACE + TXT_WIN)
    sta tmp2
    ldx #$0000
    lda #$20
    jsl txt_fill
    A16
    lda #$0220                  ; 32 x 2: rows 26-27 (the text sits on 26,
    sta tmp1                    ; clear of the last 8 overscan lines)
    A8
    ldx #(26*32)
    lda #$20
    jsl txt_fill
    lda #TXT_WIN
    sta txt_bg
    PRINT 1, 1, TP_WHITE, str_time
    PRINT 10, 1, TP_WHITE, str_tokens
    PRINT 1, 26, TP_WHITE, str_start
    PRINT 24, 26, TP_YELLOW, str_end
    stz txt_bg
    ldx #$FFFF
    stx b_hq
    stx b_hw
    stx b_ht
    stx b_htk
    stx b_hch
    jsr hud_time
    jsr hud_tokens
    jsr hud_hearts
    jmp hud_bar

bike_hud:
    lda frame
    and #$03
    beq hud_time
    cmp #$01
    jeq hud_tokens
    cmp #$02
    bne @bar
    jsr hud_chain
    jmp hud_hearts
@bar:
    jmp hud_bar

; style chain x2..x4 next to the tokens (blank when there is none)
hud_chain:
    ldx b_chain
    cpx #2
    bcs @c
    ldx #$0000
@c:
    cpx b_hch
    beq @x
    stx b_hch
    lda #TXT_WIN
    sta txt_bg
    cpx #$0000
    beq @blank
    LDPTR0 b_pbuf+28
    lda #'X'
    sta b_pbuf+28
    lda b_hch
    clc
    adc #'0'
    sta b_pbuf+29
    stz b_pbuf+30
    ldx #(1*32 + 21)
    lda #($20 | (TP_CYAN << 2))
    jsl txt_print
    stz txt_bg
@x:
    rts
@blank:
    LDPTR0 str_blank2
    ldx #(1*32 + 21)
    lda #($20 | (TP_CYAN << 2))
    jsl txt_print
    stz txt_bg
    rts

str_blank2: .byte "  ", 0

hud_time:
    A16
    lda b_time
    sta tmp0
    A8
    lda #60
    jsl div16
    ldx tmp0
    cpx b_ht
    beq @x
    stx b_ht
    stx tmp1
    lda #TXT_WIN
    sta txt_bg
    ldx #(1*32 + 6)
    ldy #2
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_num
    stz txt_bg
@x:
    rts

hud_tokens:
    ldx b_tokens
    cpx b_htk
    beq @x
    stx b_htk
    stx tmp1
    lda #TXT_WIN
    sta txt_bg
    ldx #(1*32 + 17)
    ldy #2
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_num
    stz txt_bg
@x:
    rts

hud_hearts:
    ldx b_wipes
    cpx b_hw
    bne @go
    rts
@go:
    stx b_hw
    ldx #$0000
@heart:
    phx
    lda #(TXT_HEART + TXT_WIN)
    sta tmp2
    txa
    cmp b_wipes
    lda #($20 | (TP_GREY << 2))
    bcc @lost
    lda #($20 | (TP_RED << 2))
@lost:
    pha
    A16
    lda 2,s
    clc
    adc #(1*32 + 26)
    tax
    A8
    pla
    jsl txt_char
    plx
    inx
    cpx #3
    bne @heart
    rts

    ; progress bar, row 26, cols 7..22 (16 cells = 64 quarters)
hud_bar:
    A16
    lda b_dist
    cmp #COURSE_LEN
    bcc @in
    lda #COURSE_LEN
@in:
    sta tmp0
    A8
    lda #140                    ; COURSE_LEN / 64
    jsl div16
    ldx tmp0
    cpx b_hq
    bne @go
    rts
@go:
    stx b_hq
    lda tmp0
    sta tmp3                    ; quarters filled
    ldx #$0000
@cell:
    lda tmp3
    cmp #4
    bcc @part
    sbc #4
    sta tmp3
    lda #(TXT_METER + 4 + TXT_WIN)
    bra @put
@part:
    clc
    adc #(TXT_METER + TXT_WIN)
    stz tmp3
@put:
    sta tmp2
    phx
    A16
    txa
    clc
    adc #(26*32 + 7)
    tax
    A8
    lda #($20 | (TP_GREEN << 2))
    jsl txt_char
    plx
    inx
    cpx #16
    bne @cell
    rts

str_time:   .byte "TIME", 0
str_tokens: .byte "TOKENS", 0
str_start:  .byte "QUEEN", 0
str_end:    .byte "SPADINA", 0

; ------------------------------------------------------------------
; Delivered:  RIDE     1000 + distance/16 (562) + time left/3 (~20 a s)
;              TIPS     50 a TTC token + STYLE
;              WIPEOUTS 200 each
; Not delivered (wiped out 1, out of time 2, gave up 3, fired 4): no
; delivery, no tips. RIDE = distance/24 (up to 375) and that's the score,
; so a failed run never beats a delivery (>= 1162); the card's reason line
; says why the tips and the wipeouts don't count.
; ev_break = RIDE, TIPS, WIPEOUTS; ev_score = RIDE + TIPS - WIPEOUTS.
; Stats: METRES (distance / 6), TOKENS, WIPEOUTS, STYLE.
bike_score:
    A16
    lda b_dist
    cmp #COURSE_LEN
    bcc @d
    lda #COURSE_LEN
@d:
    sta tmp3                    ; distance, clamped
    sta tmp0
    A8
    lda #6
    jsl div16
    A16
    lda tmp0
    sta ev_stat                 ; METRES
    lda b_tokens
    sta ev_stat+2
    lda b_wipes
    sta ev_stat+4
    lda b_style
    sta ev_stat+6
    stz ev_break+4
    lda b_quit
    bne @dnf
    lda b_dist
    cmp #COURSE_LEN
    bcs @delivered
    jmp @dnf
@delivered:
    ; RIDE = 1000 + distance/16 + time/3
    lda b_time
    sta tmp0
    A8
    lda #3
    jsl div16
    A16
    lda tmp3
    lsr a
    lsr a
    lsr a
    lsr a
    clc
    adc tmp0
    clc
    adc #1000
    sta ev_break
    ; TIPS = 50 * tokens + style
    lda b_tokens
    asl a
    sta tmp1                    ; t*2
    asl a
    asl a
    asl a
    sta tmp2                    ; t*16
    asl a                       ; t*32
    clc
    adc tmp2
    clc
    adc tmp1
    clc
    adc b_style
    sta ev_break+2
    ; WIPEOUTS = 200 each
    lda #$0000
    ldx b_wipes
    beq @nowipe
@wipe:
    clc
    adc #WIPE_COST
    dex
    bne @wipe
@nowipe:
    sta ev_break+4
    lda ev_break
    clc
    adc ev_break+2
    sec
    sbc ev_break+4
    sta ev_score
    A8
    stz ev_fail
    rts
@dnf:
    .a16
    ; RIDE = distance/24, and nothing else: no delivery, no tips
    lda tmp3
    sta tmp0
    A8
    lda #24
    jsl div16
    A16
    lda tmp0
    sta ev_break
    stz ev_break+2
    sta ev_score
    A8
    lda #$03                    ; gave up
    ldx b_quit
    bne @f
    lda #$04                    ; YOU'RE FIRED!
    ldx b_fired
    bne @f
    lda #$01                    ; WIPED OUT!
    ldx b_tout
    beq @f
    lda #$02                    ; OUT OF TIME!
@f:
    sta ev_fail
    rts

.include "ev_bike_ent.inc"
.include "bike_meta.inc"
