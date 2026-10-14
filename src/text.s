; BG3 text: everything is drawn into txt_map (32x32 words) and pushed by NMI.
; Inputs come in A/X/Y, ptr0, tmp1 and tmp2; all other scratch is private,
; so callers' tmp0 and tmp3-tmp7 survive every call here.
.p816
.smart -
.include "globals.inc"

.segment "ZEROPAGE"
t_attr: .res 1
t_line: .res 2
t_off:  .res 2
t_cnt:  .res 1
t_rows: .res 1
t_type: .res 1
t_w:    .res 1
t_seen: .res 1
t_val:  .res 2
t_dig:  .res 5

.segment "CODE"
.a8
.i16

txt_clear:
    ldx #$0000
@l:
    stz txt_map,x
    inx
    cpx #2048
    bne @l
    lda #$01
    sta txt_dirty
    rtl

; txt_print: ptr0 = zero-terminated string, X = cell (row*32+col), A = attr.
; $0A starts a new line under the first column. Codes 96+ reach the icon
; tiles (code = tile + 32). txt_bg is added to every tile.
txt_print:
    sta t_attr
    stx t_line
    A16
    txa
    asl a
    tax
    A8
    ldy #$0000
@loop:
    lda [ptr0],y
    beq @done
    iny
    cmp #$0A
    bne @char
    A16
    lda t_line
    clc
    adc #32
    sta t_line
    asl a
    tax
    A8
    bra @loop
@char:
    sec
    sbc #$20
    clc
    adc txt_bg
    sta txt_map,x
    lda t_attr
    sta txt_map+1,x
    inx
    inx
    bra @loop
@done:
    lda #$01
    sta txt_dirty
    rtl

; txt_print_centre: like txt_print but X = row*32; centres the first line
txt_print_centre:
    pha
    ldy #$0000
@len:
    lda [ptr0],y
    beq @got
    cmp #$0A
    beq @got
    iny
    cpy #32
    bne @len
@got:
    A16
    tya
    eor #$FFFF
    sec
    adc #32
    lsr a
    sta t_off
    txa
    clc
    adc t_off
    tax
    A8
    pla
    jml txt_print

; txt_num: tmp1 = value, X = cell, A = attr, Y = width (1-5; +$80 = zero pad)
txt_num:
    sta t_attr
    tya
    sta t_w
    A16
    txa
    asl a
    sta t_off
    lda tmp1
    sta t_val
    A8
    ldx #$0000
@div:
    A16
    lda t_val
    sta WRDIVL
    A8
    lda #10
    sta WRDIVB
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    lda RDMPYL
    sta t_dig,x
    A16
    lda RDDIVL
    sta t_val
    A8
    inx
    cpx #5
    bne @div
    lda t_w
    and #$07
    TAXB
    ldy t_off
    stz t_seen
@out:
    dex
    lda t_dig,x
    bne @nz
    cpx #$0000
    beq @nz
    lda t_seen
    bne @zero
    bit t_w
    bmi @zero
    lda #TXT_SPACE
    bra @put
@zero:
    lda #$00
@nz:
    pha
    lda #$01
    sta t_seen
    pla
    clc
    adc #('0' - 32)
@put:
    clc
    adc txt_bg
    sta txt_map,y
    lda t_attr
    sta txt_map+1,y
    iny
    iny
    cpx #$0000
    bne @out
    lda #$01
    sta txt_dirty
    rtl

; txt_char: X = cell, A = attr, tmp2 low = tile (keeps X)
txt_char:
    phx
    pha
    A16
    txa
    asl a
    tax
    A8
    lda tmp2
    sta txt_map,x
    pla
    sta txt_map+1,x
    lda #$01
    sta txt_dirty
    plx
    rtl

; txt_fill: X = top-left cell, tmp1 = width (lo) / height (hi), tmp2 = tile, A = attr
txt_fill:
    sta t_attr
    A16
    txa
    asl a
    sta t_off
    A8
    lda tmp1+1
    sta t_rows
@row:
    ldx t_off
    lda tmp1
    sta t_cnt
@col:
    lda tmp2
    sta txt_map,x
    lda t_attr
    sta txt_map+1,x
    inx
    inx
    dec t_cnt
    bne @col
    A16
    lda t_off
    clc
    adc #64
    sta t_off
    A8
    dec t_rows
    bne @row
    lda #$01
    sta txt_dirty
    rtl

; txt_box: X = top-left cell, tmp1 = width (lo) / height (hi), A = attr.
; Frame tiles TXT_BOX+0..8 (TL T TR / L fill R / BL B BR).
txt_box:
    sta t_attr
    A16
    txa
    asl a
    sta t_off
    A8
    lda tmp1+1
    sta t_rows
    stz t_type                  ; 0 top, 3 middle, 6 bottom
@row:
    lda t_rows
    cmp #$01
    bne @not_last
    lda #6
    sta t_type
@not_last:
    ldx t_off
    lda tmp1
    sta t_cnt
    lda t_type
    clc
    adc #TXT_BOX
    jsr @put
@mid:
    lda t_cnt
    cmp #$02
    bcc @right
    lda t_type
    clc
    adc #(TXT_BOX+1)
    jsr @put
    bra @mid
@right:
    lda t_type
    clc
    adc #(TXT_BOX+2)
    jsr @put
    A16
    lda t_off
    clc
    adc #64
    sta t_off
    A8
    lda #3
    sta t_type
    dec t_rows
    bne @row
    lda #$01
    sta txt_dirty
    rtl
@put:
    sta txt_map,x
    lda t_attr
    sta txt_map+1,x
    inx
    inx
    dec t_cnt
    rts
