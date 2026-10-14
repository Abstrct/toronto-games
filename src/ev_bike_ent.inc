; Bike Courier: traffic, hazards and pickups (included by ev_bike.s)

b_cur = ev_ram + 40             ; entity being drawn

; Every vehicle in a lane goes the same speed, so nothing rear-ends anything;
; the 501 coming up behind slows down for a car in front of it.
CAR_N_VY  = $0120
SOUTH_VY  = ($10000 - $0150)    ; cars and streetcars heading south
TRAM_N_VY = $03C0              ; the 501 overtakes a courier at full tilt
TRAM_DECEL = $000C              ; the 501 brakes over ~48 frames (brake lights)
TRAM_ACC  = $0006
LANE_GAP  = 120                 ; spawn spacing between vehicles in a lane
DRAFT_NEAR = 58                 ; slipstream: this far behind the 501's centre...
DRAFT_LEN  = 66                 ; ...for this long
DRAFT_DX   = 12
DRAFT_PER  = 3                  ; DRAFT moves one streetcar is good for
DRAFT_SPD  = $0200              ; slower than this isn't drafting, it's queueing

; ---- course RNG (fixed seed => same course for every player) ----
brand:
    A16
    lda b_seed
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    eor b_seed
    sta b_seed
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    eor b_seed
    sta b_seed
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    eor b_seed
    sta b_seed
    A8
    lda b_seed
    eor b_seed+1
    rts

; A = n -> A = 0..n-1
brange:
    pha
    jsr brand
    sta WRMPYA
    pla
    sta WRMPYB
    nop
    nop
    nop
    nop
    lda RDMPYH
    rts

; X = free slot * 2 (carry clear), carry set when full
alloc_ent:
    ldx #$0000
@f:
    lda E_TYPE,x
    beq @got
    inx
    inx
    cpx #(NUM_ENT*2)
    bne @f
    sec
    rts
@got:
    A16
    stz E_WYF,x
    stz E_VY,x
    stz E_VX,x
    stz E_TIMER,x
    stz E_PAL,x
    stz E_REL,x
    lda #$0008                  ; fresh: skip near-miss test once
    sta E_FLAGS,x
    A8
    clc
    rts

rand_car_pal:
    lda #4
    jsr brange
    TAYB
    lda car_pals,y
    rts

car_pals: .byte $22, $24, $26, $2C

; carry set if a vehicle of type tmp3 lo or tmp3 hi is within LANE_GAP of
; world y tmp2 (keeps X)
lane_busy:
    ldy #$0000
@l:
    lda E_TYPE,y
    cmp tmp3
    beq @chk
    cmp tmp3+1
    bne @n
@chk:
    A16
    lda E_WY,y
    sec
    sbc tmp2
    bpl @p
    eor #$FFFF
    inc a
@p:
    cmp #LANE_GAP
    A8
    bcc @busy
@n:
    iny
    iny
    cpy #(NUM_ENT*2)
    bne @l
    clc
    rts
@busy:
    sec
    rts

north_busy:
    lda #T_CAR_N
    sta tmp3
    lda #T_TRAM_N
    sta tmp3+1
    jmp lane_busy

south_busy:
    lda #T_CAR_S
    sta tmp3
    lda #T_TRAM_S
    sta tmp3+1
    jmp lane_busy

; ------------------------------------------------------------------
spawn_ahead:
@l:
    A16
    lda b_nextsp
    cmp #$FFFF
    beq @done
    lda b_dist
    clc
    adc #260
    cmp b_nextsp
    bcc @done
    A8
    jsr spawn_segment
    bra @l
@done:
    A8
    rts

spawn_segment:
    A16
    lda b_nextsp
    cmp #(COURSE_LEN - 60)
    A8
    bcc @normal
    jsr alloc_ent
    bcs @full
    A16
    lda #T_FINISH
    sta E_TYPE,x
    lda #(128*256)
    sta E_X,x
    lda #COURSE_LEN
    sta E_WY,x
    A8
@full:
    ldx #$FFFF
    stx b_nextsp
    rts
@normal:
    lda #16
    jsr brange
    asl a
    TAXB
    jsr (.loword(seg_table),x)
    ; gap to the next segment, tighter as the ride goes on
    lda #48
    jsr brange
    A16
    and #$00FF
    clc
    adc #54
    sta tmp0
    lda b_dist
    xba
    lsr a
    and #$00FF
    cmp #26
    bcc @t
    lda #26
@t:
    sta tmp1
    lda tmp0
    sec
    sbc tmp1
    clc
    adc b_nextsp
    sta b_nextsp
    A8
    rts

seg_table:
    .addr seg_parked, seg_parked, seg_parked, seg_parked
    .addr seg_parked_l, seg_car_n, seg_car_n, seg_car_s
    .addr seg_car_s, seg_tram_n, seg_tram_s, seg_hole
    .addr seg_hole, seg_tokens, seg_tokens, seg_ped

; a row of parked cars on the right; some drivers are about to open up
seg_parked:
    lda #2
    jsr brange
    clc
    adc #2
    sta tmp7
    stz tmp6
@car:
    jsr alloc_ent
    bcs @done
    lda tmp6
    sta WRMPYA
    lda #52
    sta WRMPYB
    nop
    nop
    nop
    A16
    lda #T_PARKED
    sta E_TYPE,x
    lda #(216*256)
    sta E_X,x
    lda RDMPYL
    clc
    adc b_nextsp
    sta E_WY,x
    A8
    jsr rand_car_pal
    sta E_PAL,x
    lda #2
    jsr brange
    beq @nodoor
    lda #50
    jsr brange
    A16
    and #$00FF
    clc
    adc #100
    sta E_TIMER,x
    A8
@nodoor:
    inc tmp6
    dec tmp7
    bne @car
@done:
    lda tmp6
    sta WRMPYA
    lda #52
    sta WRMPYB
    nop
    nop
    nop
    A16
    lda RDMPYL
    clc
    adc b_nextsp
    sta b_nextsp
    A8
    rts

seg_parked_l:
    jsr alloc_ent
    bcs @x
    A16
    lda #T_PARKED_S
    sta E_TYPE,x
    lda #(40*256)
    sta E_X,x
    lda b_nextsp
    clc
    adc #20
    sta E_WY,x
    A8
    jsr rand_car_pal
    sta E_PAL,x
@x:
    rts

seg_car_n:
    ; no new cars on the northbound tracks while the 501 is about
    ldy #$0000
@t:
    lda E_TYPE,y
    cmp #T_TRAM_N
    beq @x
    iny
    iny
    cpy #(NUM_ENT*2)
    bne @t
    A16
    lda b_nextsp
    clc
    adc #60
    sta tmp2
    A8
    jsr north_busy
    bcs @x
    jsr alloc_ent
    bcs @x
    A16
    lda #CAR_N_VY
    sta E_VY,x
    lda #T_CAR_N
    sta E_TYPE,x
    lda #(166*256)
    sta E_X,x
    lda b_nextsp
    clc
    adc #60
    sta E_WY,x
    A8
    jsr rand_car_pal
    sta E_PAL,x
@x:
    rts

seg_car_s:
    A16
    lda b_nextsp
    clc
    adc #200
    sta tmp2
    A8
    jsr south_busy
    bcs @x
    jsr alloc_ent
    bcs @x
    A16
    lda #SOUTH_VY
    sta E_VY,x
    lda #T_CAR_S
    sta E_TYPE,x
    lda #(88*256)
    sta E_X,x
    lda b_nextsp
    clc
    adc #200
    sta E_WY,x
    A8
    jsr rand_car_pal
    sta E_PAL,x
@x:
    rts

; the 501 rolls up behind you (one at a time)
seg_tram_n:
    ldy #$0000
@chk:
    lda E_TYPE,y
    cmp #T_TRAM_N
    bne @n
    jmp seg_car_n
@n:
    iny
    iny
    cpy #(NUM_ENT*2)
    bne @chk
    A16
    lda b_dist
    sec
    sbc #170
    sta tmp2
    A8
    jsr north_busy
    bcs @x
    jsr alloc_ent
    bcs @x
    A16
    lda #T_TRAM_N
    sta E_TYPE,x
    lda #(164*256)
    sta E_X,x
    lda tmp2
    sta E_WY,x
    lda #TRAM_N_VY
    sta E_VY,x
    A8
@x:
    rts

seg_tram_s:
    A16
    lda b_nextsp
    clc
    adc #240
    sta tmp2
    A8
    jsr south_busy
    bcs @x
    jsr alloc_ent
    bcs @x
    A16
    lda #T_TRAM_S
    sta E_TYPE,x
    lda #(96*256)
    sta E_X,x
    lda b_nextsp
    clc
    adc #240
    sta E_WY,x
    lda #SOUTH_VY
    sta E_VY,x
    A8
@x:
    rts

; Queen St comes for a camper: the 501 up the tracks behind you in the
; northbound bed, an oncoming 501 in the southbound one, otherwise a fresh
; pothole (with its cone) just over the top of the screen in your line.
punish_camper:
    lda b_px+1
    cmp #142
    bcc @notn
    cmp #185
    bcs @hole
    jsr tram_behind
    bcc @x
    bra @hole
@notn:
    cmp #74
    bcc @hole
    cmp #117
    bcs @hole
    jsr tram_ahead
    bcc @x
@hole:
    jsr alloc_ent
    bcs @x
    lda b_px+1
    cmp #30
    bcs @lo
    lda #30
@lo:
    cmp #226
    bcc @hi
    lda #226
@hi:
    xba
    lda #$00
    A16
    sta E_X,x
    lda #T_POTHOLE
    sta E_TYPE,x
    lda b_dist
    clc
    adc #250
    sta E_WY,x
    A8
@x:
    rts

; the 501 up the northbound tracks behind you; carry set if it can't come
tram_behind:
    ldy #$0000
@chk:
    lda E_TYPE,y
    cmp #T_TRAM_N
    beq @no
    iny
    iny
    cpy #(NUM_ENT*2)
    bne @chk
    A16
    lda b_dist
    sec
    sbc #170
    sta tmp2
    A8
    jsr north_busy
    bcs @no
    jsr alloc_ent
    bcs @no
    A16
    lda #T_TRAM_N
    sta E_TYPE,x
    lda #(164*256)
    sta E_X,x
    lda tmp2
    sta E_WY,x
    lda #TRAM_N_VY
    sta E_VY,x
    A8
    clc
    rts
@no:
    sec
    rts

; an oncoming 501 down the southbound tracks
tram_ahead:
    A16
    lda b_dist
    clc
    adc #330
    sta tmp2
    A8
    jsr south_busy
    bcs @no
    jsr alloc_ent
    bcs @no
    A16
    lda #T_TRAM_S
    sta E_TYPE,x
    lda #(96*256)
    sta E_X,x
    lda tmp2
    sta E_WY,x
    lda #SOUTH_VY
    sta E_VY,x
    A8
    clc
    rts
@no:
    sec
    rts

seg_hole:
    jsr alloc_ent
    bcs @x
    lda #6
    jsr brange
    TAYB
    lda #13
    jsr brange
    clc
    adc hole_lanes,y
    xba
    lda #$00
    xba
    A16
    xba
    sta E_X,x
    lda #T_POTHOLE
    sta E_TYPE,x
    lda b_nextsp
    sta E_WY,x
    A8
@x:
    rts

hole_lanes: .byte 178, 160, 160, 122, 88, 60        ; - 6 .. + 6

; a line of TTC tokens; some lines run diagonally across a lane or the
; tracks, so the courier has to go and get them
seg_tokens:
    lda #6
    jsr brange
    TAYB
    lda token_lanes,y
    sta tmp5
    lda #3
    jsr brange
    TAYB
    lda token_drift,y
    sta tmp5+1
    lda #2
    jsr brange
    clc
    adc #3
    sta tmp7
    stz tmp6
@t:
    jsr alloc_ent
    bcs @x
    lda tmp6
    sta WRMPYA
    lda #22
    sta WRMPYB
    nop
    nop
    nop
    A16
    lda #T_TOKEN
    sta E_TYPE,x
    lda tmp5
    and #$00FF
    xba
    sta E_X,x
    lda RDMPYL
    clc
    adc b_nextsp
    sta E_WY,x
    A8
    lda tmp5
    clc
    adc tmp5+1
    sta tmp5
    inc tmp6
    dec tmp7
    bne @t
@x:
    rts

token_lanes: .byte 188, 166, 140, 116, 70, 96
token_drift: .byte 0, 8, $F8

seg_ped:
    jsr alloc_ent
    bcs @x
    A16
    lda #T_PED
    sta E_TYPE,x
    lda b_nextsp
    clc
    adc #30
    sta E_WY,x
    A8
    lda #2
    jsr brange
    A16
    beq @from_right
    lda #(14*256)
    sta E_X,x
    lda #$0090
    sta E_VX,x
    bra @x16
@from_right:
    lda #(242*256)
    sta E_X,x
    lda #($10000 - $0090)
    sta E_VX,x
@x16:
    A8
@x:
    rts

; ------------------------------------------------------------------
ents_update:
    ldx #$0000
    stx b_indr
    jsr @loop
    lda b_indr
    bne @x
    ldx #$0000
    stx b_draft
@x:
    rts
@loop:
@ent:
    lda E_TYPE,x
    bne @live
    jmp @next
@live:
    ; move along the road: (WY:WYF) += VY (signed 8.8)
    A16
    lda E_VY,x
    beq @nomove
    and #$00FF
    sta tmp1
    lda E_WYF,x
    and #$00FF
    clc
    adc tmp1
    sta tmp1
    and #$00FF
    sta E_WYF,x
    lda tmp1
    xba
    and #$00FF
    sta tmp1                    ; carry out of the fraction
    lda E_VY,x
    xba
    and #$00FF
    cmp #$0080
    bcc @pos
    ora #$FF00
@pos:
    clc
    adc tmp1
    clc
    adc E_WY,x
    sta E_WY,x
@nomove:
    ; sideways (pedestrians)
    lda E_VX,x
    beq @nox
    clc
    adc E_X,x
    sta E_X,x
    xba
    and #$00FF
    cmp #4
    bcc @kill
    cmp #252
    bcs @kill
@nox:
    lda E_WY,x
    sec
    sbc b_dist
    sta tmp0                    ; rel: + ahead, - behind
    bmi @behind
    cmp #720
    bcs @kill
    bra @alive
@behind:
    cmp #($10000 - 330)
    bcc @kill
    cmp #($10000 - 120)
    bcs @alive
    lda E_TYPE,x
    cmp #T_TRAM_N
    bne @kill
@alive:
    A8
    stx b_cur
    jsr ent_logic
    jsr ent_collide
    A16
    lda tmp0
    sta E_REL,x
    lda E_FLAGS,x
    and #$FFF7
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

; per-type behaviour (X = entity, tmp0 = rel)
ent_logic:
    lda E_TYPE,x
    cmp #T_PARKED
    bne @tram
    lda E_FLAGS,x
    and #$02
    bne @x
    A16
    lda E_TIMER,x
    beq @x16
    lda tmp0
    bmi @x16
    cmp E_TIMER,x
    bcs @x16
    A8
    lda E_FLAGS,x
    ora #$02
    sta E_FLAGS,x
    SFX SFX_TICK
    rts
@x16:
    A8
@x:
    rts
@tram:
    cmp #T_TRAM_N
    bne @x
    jsr tram_follow
    jsr tram_draft
    ; bell + sign only while it is behind us AND catching up
    lda tmp0+1
    bpl @x
    A16
    lda tmp0
    cmp #($10000 - 70)
    bcs @x16b
    cmp #($10000 - 160)
    bcc @x16b
    lda E_VY,x
    cmp b_speed
    bcc @x16b
    beq @x16b
    A8
    lda #$01
    sta b_bell
    rts
@x16b:
    A8
    rts

; tucked in behind the 501 (X = tram, tmp0 = rel): slipstream
tram_draft:
    lda b_state
    bne @x
    A16
    lda tmp0
    sec
    sbc #DRAFT_NEAR
    cmp #DRAFT_LEN
    A8
    bcs @x
    lda E_X+1,x
    sec
    sbc b_px+1
    bcs @p
    eor #$FF
    inc a
@p:
    cmp #DRAFT_DX
    bcs @x
    lda #$01
    sta b_indr
    A16
    lda E_VY,x                  ; pulled along at its speed (and a bit)
    clc
    adc #$0018
    sta b_dcap
    lda b_speed
    cmp #DRAFT_SPD
    bcc @x16
    lda E_TIMER,x
    cmp #DRAFT_PER
    bcs @x16
    inc b_draft
    lda b_draft
    cmp #DRAFT_TICK
    bcc @x16
    stz b_draft
    inc E_TIMER,x
    lda tmp0
    pha
    A8
    lda #SM_DRAFT
    jsr style_award
    A16
    pla
    sta tmp0
    A8
    ldx b_cur
    rts
@x16:
    A8
@x:
    rts

; the 501 brakes (gently, brake lights on) for a car in its lane
; (X = tram, keeps X, tmp0)
tram_follow:
    ; off the bottom of the screen it doesn't queue behind anyone (it just
    ; gets on with it), so the 501 does reach you
    A16
    lda tmp0
    cmp #($10000 - 60)
    A8
    bcs @look
    lda tmp0+1
    bmi @free
@look:
    ldy #$0000
@l:
    lda E_TYPE,y
    cmp #T_CAR_N
    bne @n
    A16
    lda E_WY,y
    sec
    sbc E_WY,x
    bmi @n16                    ; behind the tram
    cmp #150
    bcs @n16
    lda #CAR_N_VY
    bra @tgt
@n16:
    A8
@n:
    iny
    iny
    cpy #(NUM_ENT*2)
    bne @l
@free:
    A16
    lda #TRAM_N_VY
@tgt:
    sta tmp2
    lda E_VY,x
    cmp tmp2
    beq @off
    bcc @up
    sec
    sbc #TRAM_DECEL
    cmp tmp2
    bcs @slow
    lda tmp2
@slow:
    sta E_VY,x
    A8
    lda E_FLAGS,x
    ora #$10
    sta E_FLAGS,x
    rts
@up:
    .a16
    clc
    adc #TRAM_ACC
    cmp tmp2
    bcc @fast
    lda tmp2
@fast:
    sta E_VY,x
@off:
    A8
    lda E_FLAGS,x
    and #$EF
    sta E_FLAGS,x
    rts

; hw+4, hh+10, kind (1 car, 2 tram, 3 hole, 4 token, 5 ped), near-miss
hw_tab:   .byte 0, 15, 15, 15, 15, 20, 20, 11,  9,  8, 0
hh_tab:   .byte 0, 29, 29, 29, 29, 55, 55, 14, 15, 14, 0
kind_tab: .byte 0,  1,  1,  1,  1,  2,  2,  3,  4,  5, 0
near_tab: .byte 0,  1,  1,  1,  1,  1,  1,  0,  0,  0, 0

ent_collide:
    lda b_state
    beq @riding
    rts
@riding:
    ; dx = |entity x - player x|
    lda E_X+1,x
    sec
    sbc b_px+1
    bcs @dxp
    eor #$FF
    inc a
@dxp:
    sta tmp1
    ; dy = |rel|
    A16
    lda tmp0
    bpl @dyp
    eor #$FFFF
    inc a
@dyp:
    cmp #$0100
    A8
    bcc @close
    rts
@close:
    sta tmp1+1
    lda E_TYPE,x
    TAYB
    ; open doors stick out to the left of parked cars
    cpy #T_PARKED
    bne @body
    lda E_FLAGS,x
    and #$02
    beq @body
    jsr door_hit
@body:
    lda tmp1
    cmp hw_tab,y
    jcs @miss
    lda tmp1+1
    cmp hh_tab,y
    jcs @miss
    lda kind_tab,y
    cmp #4
    beq @token
    ldx b_inv
    bne @restore
    ldx b_cur
    cmp #1
    beq @car
    cmp #2
    beq @tram
    cmp #3
    beq @hole
    cmp #5
    beq @ped
    rts
@restore:
    ldx b_cur
    rts
@car:
    lda #CA_CAR
    jmp crash
@tram:
    lda tmp0+1
    bmi @hitby
    lda #CA_REAR                ; we ran into the back of it
    jmp crash
@hitby:
    lda #CA_TRAM
    jmp crash
@ped:
    lda #CA_PED
    jmp crash
@hole:
    lda b_hop
    bne @r                      ; hopped it
    lda E_FLAGS,x
    and #$04
    bne @r
    lda E_FLAGS,x
    ora #$04
    sta E_FLAGS,x
    A16
    lda b_speed
    cmp #$0180
    bcc @bump
    A8
    lda #CA_HOLE
    jmp crash
@bump:
    .a16
    lsr a
    sta b_speed
    lda #6
    sta b_shake
    A8
    SFX SFX_STEP
@r:
    rts
@token:
    A16
    stz E_TYPE,x
    inc b_tokens
    A8
    SFX SFX_COIN
    rts
@miss:
    ; near miss: the thing just slid past our shoulder
    lda near_tab,y
    beq @nx
    lda b_speed+1               ; standing still isn't a close call
    beq @nx
    lda E_FLAGS,x
    and #$09
    bne @nx
    lda E_REL+1,x
    eor tmp0+1
    bpl @nx
    lda tmp1
    sec
    sbc hw_tab,y
    bcc @nx
    cmp #4
    bcs @nx
    lda E_FLAGS,x
    ora #$01
    sta E_FLAGS,x
    A16
    inc b_near
    lda tmp0
    pha
    A8
    lda #SM_CLOSE
    jsr style_award
    A16
    pla
    sta tmp0
    A8
    ldx b_cur
@nx:
    rts


; door box: centre (car x - 19, rel + 6), half size 7 x 3
door_hit:
    lda b_inv
    bne @x
    lda E_X+1,x
    sec
    sbc #20
    sec
    sbc b_px+1
    bcs @p
    eor #$FF
    inc a
@p:
    cmp #10
    bcs @x
    A16
    lda tmp0
    clc
    adc #6
    bpl @q
    eor #$FFFF
    inc a
@q:
    cmp #13
    A8
    bcs @x
    pla                         ; drop our return address
    pla
    lda #CA_DOOR
    jmp crash
@x:
    rts

; ------------------------------------------------------------------
; bmeta: this event's sprite drawer. ptr1 = a bm_ table in this bank
; (dx, dy, tile|attr<<8, size<<1 words per piece, flips baked in),
; spr_x/spr_y = origin, tmp5 lo = attr OR. Uses tmp2-tmp4, tmp7.
; About 4x quicker than oam_meta, which is what the lag was.
bmeta:
    A16
    lda tmp5
    xba
    and #$FF00
    sta tmp4                    ; attr OR, high byte
    ldy #$0000
    ldx oam_idx
@piece:
    lda (ptr1),y                ; dx
    cmp #$8000
    jeq @done
    clc
    adc spr_x
    sta tmp2
    clc
    adc #16
    cmp #(256+16)
    bcs @skip_x
    iny
    iny
    lda (ptr1),y                ; dy
    clc
    adc spr_y
    sta tmp3
    clc
    adc #16
    cmp #(224+16)
    bcs @skip_y
    cpx #512
    jcs @done
    lda tmp3
    xba
    and #$FF00
    sta tmp7
    lda tmp2
    and #$00FF
    ora tmp7
    sta oam_buf,x               ; x lo, y
    iny
    iny
    lda (ptr1),y
    ora tmp4
    sta oam_buf+2,x             ; tile, attr
    iny
    iny
    ; high table: (x bit 8) | size<<1, in this sprite's 2 bits
    lda tmp2
    xba
    and #$0001
    ora (ptr1),y
    sta tmp7
    iny
    iny
    phy
    stx tmp3
    txa
    and #$000C
    ora tmp7
    tay
    lda tmp3
    lsr a
    lsr a
    lsr a
    lsr a
    tax
    A8
    lda bm_hibits,y
    ora oam_hi,x
    sta oam_hi,x
    A16
    ply
    lda tmp3
    clc
    adc #4
    tax
    jmp @piece
@skip_x:
    iny
    iny
@skip_y:
    iny
    iny
    iny
    iny
    iny
    iny
    jmp @piece
@done:
    stx oam_idx
    A8
    rts

bm_hibits:
    .byte $00, $01, $02, $03
    .byte $00, $04, $08, $0C
    .byte $00, $10, $20, $30
    .byte $00, $40, $80, $C0

; draw pass per type: 0 traffic and people, 1 things on the road surface
pass_tab: .byte 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1

ents_draw:
    ldx #$0000
@e:
    lda E_TYPE,x
    bne @live
    jmp @next
@live:
    TAYB
    lda pass_tab,y
    cmp b_pass
    beq @mine
    jmp @next
@mine:
    stx b_cur
    A16
    lda E_WY,x
    sec
    sbc b_dist
    eor #$FFFF
    inc a
    clc
    adc #PLAYER_SY
    sta spr_y
    clc
    adc #56
    cmp #(224 + 112)
    bcs @skip
    lda E_X,x
    xba
    and #$00FF
    sta spr_x
    A8
    lda E_PAL,x
    sta tmp5
    lda E_TYPE,x
    asl a
    TAXB
    jsr (.loword(draw_tab),x)
@skip:
    A8
    ldx b_cur
@next:
    inx
    inx
    cpx #(NUM_ENT*2)
    jne @e
    rts

draw_tab:
    .addr dr_none, dr_car, dr_car_s, dr_car, dr_car_s, dr_tram, dr_tram_s
    .addr dr_hole, dr_token, dr_ped, dr_finish

dr_none:
    rts

dr_car:
    LDPTR1 bm_car
    jsr bmeta
    ldx b_cur
    lda E_TYPE,x
    cmp #T_PARKED
    bne @x
    lda E_FLAGS,x
    and #$02
    beq @x
    A16
    lda spr_x
    sec
    sbc #12
    sta spr_x
    lda spr_y
    sec
    sbc #6
    sta spr_y
    A8
    LDPTR1 bm_door
    jmp bmeta
@x:
    rts

dr_car_s:
    LDPTR1 bm_car_v
    jmp bmeta

dr_tram:
    ; brake lights first (so they sit on top of the car)
    ldx b_cur
    lda E_FLAGS,x
    and #$10
    beq @nolights
    lda #$2A
    sta tmp5
    LDPTR1 bm_brake
    jsr bmeta
@nolights:
    lda #$28
    sta tmp5
    LDPTR1 bm_streetcar
    jmp bmeta

dr_tram_s:
    lda #$28
    sta tmp5
    LDPTR1 bm_streetcar_v
    jmp bmeta

dr_hole:
    lda #$2E                    ; FX palette: asphalt + cone orange
    sta tmp5
    LDPTR1 bm_pothole
    jmp bmeta

dr_token:
    lda #$2A
    sta tmp5
    lda frame
    and #$10
    beq @a
    A16
    dec spr_y
    A8
@a:
    LDPTR1 bm_token
    jmp bmeta

dr_ped:
    lda #$2A
    sta tmp5
    ldx b_cur
    lda E_VX+1,x
    bpl @r
    lda frame
    and #$08
    beq @l0
    LDPTR1 bm_ped1_h
    jmp bmeta
@l0:
    LDPTR1 bm_ped0_h
    jmp bmeta
@r:
    lda frame
    and #$08
    beq @f0
    LDPTR1 bm_ped1
    jmp bmeta
@f0:
    LDPTR1 bm_ped0
    jmp bmeta

; checkered line across the road at Spadina
dr_finish:
    lda #$2A
    sta tmp5
    A16
    lda #32
    sta spr_x
    A8
@sq:
    LDPTR1 bm_finish
    jsr bmeta
    A16
    lda spr_x
    clc
    adc #16
    sta spr_x
    cmp #240
    A8
    bcc @sq
    lda b_banner
    bne @x
    lda #$01
    sta b_banner
    LDPTR0 str_spadina
    lda #TP_CYAN
    jsl event_popup
    ldx #90
    stx b_popup
@x:
    rts

str_spadina: .byte "SPADINA AHEAD!", 0
