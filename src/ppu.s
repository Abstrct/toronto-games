; Video helpers: VRAM/CGRAM loads, fades, display setup, sprites
.p816
.smart -
.include "globals.inc"

.segment "CODE"
.a8
.i16

; ------------------------------------------------------------------
; vram_load: X = VRAM word address, ptr0 = source, tmp0 = bytes.
; Immediate DMA on channel 1: only during forced blank or vblank.
vram_load:
    lda #$80
    sta VMAIN
    stx VMADDL
    lda #$01
    sta $4310
    lda #<VMDATAL
    sta $4311
    ldx ptr0
    stx $4312
    lda ptr0+2
    sta $4314
    ldx tmp0
    stx $4315
    lda #$02
    sta MDMAEN
    rtl

; vram_fill: X = VRAM word address, tmp0 = words (0 = 64K bytes), tmp1 = fill word
vram_fill:
    phx
    stz VMAIN               ; increment after low byte
    stx VMADDL
    lda #$08
    sta $4310
    lda #<VMDATAL
    sta $4311
    ldx #tmp1
    stx $4312
    stz $4314
    ldx tmp0
    stx $4315
    lda #$02
    sta MDMAEN
    plx
    lda #$80                ; increment after high byte
    sta VMAIN
    stx VMADDL
    lda #<VMDATAH
    sta $4311
    ldx #(tmp1+1)
    stx $4312
    ldx tmp0
    stx $4315
    lda #$02
    sta MDMAEN
    rtl

vram_clear_all:
    ldx #$0000
    stx tmp0
    stx tmp1
    jsl vram_fill
    rtl

; pal_load: X = first colour, Y = count, ptr0 = source
pal_load:
    A16
    txa
    asl
    tax
    tya
    asl
    sta tmp1
    ldy #$0000
@l:
    lda [ptr0],y
    sta pal_buf,x
    inx
    inx
    iny
    iny
    cpy tmp1
    bne @l
    A8
    lda #$01
    sta pal_dirty
    rtl

pal_clear:
    ldx #$0000
@l:
    stz pal_buf,x
    inx
    cpx #512
    bne @l
    lda #$01
    sta pal_dirty
    rtl

; ------------------------------------------------------------------
ppu_off:
    lda #$80
    sta inidisp_sh
    jsl wait_frame
    rtl

fade_in:
    lda #$00
@l:
    sta inidisp_sh
    pha
    jsl wait_frame
    pla
    inc a
    cmp #$10
    bne @l
    rtl

fade_out:
    lda #$0F
@l:
    sta inidisp_sh
    pha
    jsl wait_frame
    pla
    dec a
    bpl @l
    lda #$80
    sta inidisp_sh
    jsl wait_frame
    rtl

hdma_off:
    stz hdma_sh
    rtl

; ------------------------------------------------------------------
; Mode 1 layout used by every screen. Call during forced blank.
set_mode1_defaults:
    stz hdma_sh
    stz HDMAEN
    lda #$09                ; mode 1, BG3 on top
    sta BGMODE
    lda #((VRAM_BG1MAP >> 8) | 1)
    sta BG1SC
    lda #((VRAM_BG2MAP >> 8) | 1)
    sta BG2SC
    lda #(VRAM_BG3MAP >> 8)
    sta BG3SC
    lda #$00
    sta BG12NBA
    lda #(VRAM_TXTTILES >> 12)
    sta BG34NBA
    lda #(VRAM_OBJTILES >> 13)
    sta OBSEL               ; 8x8 + 16x16
    lda #$17
    sta tm_sh
    stz ts_sh
    lda #$30
    sta cgwsel_sh
    stz cgadsub_sh
    stz mosaic_sh
    ldx #$0000
    stx bg1x
    stx bg1y
    stx bg2x
    stx bg2y
    stx bg3x
    stx bg3y
    jsl oam_clear
    jsl txt_clear
    ; blank BG1/BG2 maps
    ldx #2048
    stx tmp0
    ldx #$0000
    stx tmp1
    ldx #VRAM_BG1MAP
    jsl vram_fill
    ldx #2048
    stx tmp0
    ldx #VRAM_BG2MAP
    jsl vram_fill
    rtl

; ------------------------------------------------------------------
; Sprites. oam_clear parks all 128 off-screen; oam_put adds one.
oam_clear:
    ldx #$0000
    lda #$F0
@l:
    sta oam_buf+1,x
    stz oam_buf,x
    inx
    inx
    inx
    inx
    cpx #512
    bne @l
    ldx #$0000
@h:
    stz oam_hi,x
    inx
    cpx #32
    bne @h
    ldx #$0000
    stx oam_idx
    rtl

oam_finish:
    rtl

; oam_put: spr_x, spr_y (signed words), spr_tile (9 bits), spr_attr, spr_size (0/1)
oam_put:
    A16
    lda spr_x
    clc
    adc #16
    cmp #(256+16)
    bcs @skip
    lda spr_y
    clc
    adc #32
    cmp #(224+32)
    bcs @skip
    ldx oam_idx
    cpx #512
    bcs @skip
    A8
    lda spr_x
    sta oam_buf,x
    lda spr_y
    sta oam_buf+1,x
    lda spr_tile
    sta oam_buf+2,x
    lda spr_tile+1
    and #$01
    ora spr_attr
    sta oam_buf+3,x
    ; high table: 2 bits per sprite (x bit 8, size)
    lda spr_x+1
    and #$01
    sta tmp7
    lda spr_size
    and #$01
    asl a
    ora tmp7
    sta tmp7                ; v = 0..3
    A16
    txa
    lsr a
    lsr a
    and #$0003
    asl a
    asl a
    ora tmp7
    and #$000F
    sta tmp7                ; table index (word)
    txa
    lsr a
    lsr a
    lsr a
    lsr a
    tay                     ; byte in oam_hi
    ldx tmp7
    A8
    lda f:hi_bits,x
    ora oam_hi,y
    sta oam_hi,y
    A16
    lda oam_idx
    clc
    adc #4
    sta oam_idx
@skip:
    A8
    rtl

hi_bits:
    .byte $00, $01, $02, $03
    .byte $00, $04, $08, $0C
    .byte $00, $10, $20, $30
    .byte $00, $40, $80, $C0

; oam_meta: draw a metasprite.
;   ptr1  = piece list: dx(s8) dy(s8) tile(u8) attr(u8) size(u8), ends with dx=$80
;   spr_x, spr_y = origin; tmp6 = tile base (word); tmp5 low = attr OR mask
;   tmp5 high: bit 6 = mirror horizontally, bit 7 = flip vertically
oam_meta:
    A16
    lda spr_x
    sta tmp3
    lda spr_y
    sta tmp4
    A8
    ldy #$0000
@piece:
    lda [ptr1],y
    cmp #$80
    bne @go
    jmp @done
@go:
    ; size first (needed to mirror)
    phy
    iny
    iny
    iny
    iny
    lda [ptr1],y
    sta spr_size
    ply
    ; piece width/height (8 or 16) in tmp2+1.. via tmp7 high
    lda #8
    bit spr_size
    beq @sz
    lda #16
@sz:
    sta tmp7+1
    ; dx
    lda [ptr1],y
    jsr @sext
    sta tmp2
    A8
    bit tmp5+1
    bvc @noflip
    jsr @mirror
@noflip:
    A16
    lda tmp2
    clc
    adc tmp3
    sta spr_x
    A8
    iny
    ; dy
    lda [ptr1],y
    jsr @sext
    sta tmp2
    A8
    bit tmp5+1
    bpl @novf
    jsr @mirror
@novf:
    A16
    lda tmp2
    clc
    adc tmp4
    sta spr_y
    A8
    iny
    ; tile
    lda [ptr1],y
    A16
    and #$00FF
    clc
    adc tmp6
    sta spr_tile
    A8
    iny
    ; attr
    lda [ptr1],y
    ora tmp5
    bit tmp5+1
    bvc @nh
    eor #$40
@nh:
    bit tmp5+1
    bpl @nv
    eor #$80
@nv:
    sta spr_attr
    iny
    iny
    phy
    jsl oam_put
    ply
    jmp @piece
@done:
    A16
    lda tmp3
    sta spr_x
    lda tmp4
    sta spr_y
    A8
    rtl

; sign-extend A (8-bit) into 16-bit A; returns in A16 mode
@sext:
    A16
    and #$00FF
    cmp #$0080
    bcc @se
    ora #$FF00
@se:
    rts

; tmp2 = -(tmp2 + piece size)
@mirror:
    A16
    lda tmp7+1
    and #$00FF
    clc
    adc tmp2
    eor #$FFFF
    inc a
    sta tmp2
    A8
    rts
