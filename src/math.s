; Random numbers, trig, multiply / divide
.p816
.smart -
.include "globals.inc"

.global sine_table

.segment "CODE"
.a8
.i16

; rand: 16-bit xorshift; returns A = low byte (A8), rng updated
rand:
    A16
    lda rng
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    eor rng
    sta rng
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    eor rng
    sta rng
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    eor rng
    sta rng
    A8
    lda rng
    eor rng+1
    rtl

; rand_range: A = n (1-255) -> A = 0..n-1
rand_range:
    pha
    jsl rand
    sta WRMPYA
    pla
    sta WRMPYB
    nop
    nop
    nop
    nop
    lda RDMPYH
    rtl

; sin8 / cos8: A = angle (256 per turn) -> A = signed sine * 127
sin8:
    phx
    A16
    and #$00FF
    tax
    A8
    lda f:sine_table,x
    plx
    rtl

cos8:
    clc
    adc #64
    jml sin8

; mul8: A * tmp0 low (unsigned) -> tmp0 = 16-bit product
mul8:
    sta WRMPYA
    lda tmp0
    sta WRMPYB
    nop
    nop
    nop
    nop
    ldx RDMPYL
    stx tmp0
    rtl

; div16: tmp0 / A (unsigned, A != 0) -> tmp0 = quotient, A = remainder
div16:
    ldx tmp0
    stx WRDIVL
    sta WRDIVB
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ldx RDDIVL
    stx tmp0
    lda RDMPYL
    rtl
