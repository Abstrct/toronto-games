; Helpers shared by event modules (textually included; each event defines
; EV_SEED, E_TYPE, NUM_ENT before including this).

; course RNG: fixed seed per event => every player gets the same course
ev_rand:
    A16
    lda EV_SEED
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    eor EV_SEED
    sta EV_SEED
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    eor EV_SEED
    sta EV_SEED
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    eor EV_SEED
    sta EV_SEED
    A8
    lda EV_SEED
    eor EV_SEED+1
    rts

; A = n -> A = 0..n-1
ev_range:
    pha
    jsr ev_rand
    sta WRMPYA
    pla
    sta WRMPYB
    nop
    nop
    nop
    nop
    lda RDMPYH
    rts

; X = first free entity slot * 2 (carry clear) or carry set when full.
; The event clears the slot's other fields itself.
ev_alloc:
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
    clc
    rts

; A8 signed byte -> A16 sign-extended (returns in 16-bit mode)
ev_sext:
    A16
    and #$00FF
    cmp #$0080
    bcc @p
    ora #$FF00
@p:
    rts
.a8

; clear ev_ram (all 2 KB)
ev_clear:
    ldx #$0000
@c:
    stz ev_ram,x
    inx
    cpx #EV_RAM_SIZE
    bne @c
    rts

; HDMA channel 7: colour-0 gradient from a mode-3 table (ptr0)
ev_sky:
    lda #$03
    sta $4370
    lda #<CGADD
    sta $4371
    ldx ptr0
    stx $4372
    lda ptr0+2
    sta $4374
    lda #$80
    sta hdma_sh
    rts
