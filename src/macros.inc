; Register-width macros. Game code runs A8 / XY16 unless a routine says otherwise.
.macpack longbranch

.macro A8
    sep #$20
    .a8
.endmacro

.macro A16
    rep #$20
    .a16
.endmacro

.macro I8
    sep #$10
    .i8
.endmacro

.macro I16
    rep #$10
    .i16
.endmacro

.macro AXY8
    sep #$30
    .a8
    .i8
.endmacro

.macro AXY16
    rep #$30
    .a16
    .i16
.endmacro

.macro A8I16
    sep #$20
    rep #$10
    .a8
    .i16
.endmacro

; X/Y = A & $FF from 8-bit A. (A plain TAX/TAY with 16-bit index registers
; also copies the hidden high byte B, which is usually garbage.)
.macro TAXB
    rep #$20
    .a16
    and #$00FF
    tax
    sep #$20
    .a8
.endmacro

.macro TAYB
    rep #$20
    .a16
    and #$00FF
    tay
    sep #$20
    .a8
.endmacro

; set DB to the bank this code lives in (save the caller's on the stack)
.macro ENTER_BANK
    phb
    phk
    plb
.endmacro

.macro LEAVE_BANK
    plb
.endmacro

; ptr0 = long address of label
.macro LDPTR0 label
    A16
    lda #.loword(label)
    sta ptr0
    A8
    lda #^label
    sta ptr0+2
.endmacro

.macro LDPTR1 label
    A16
    lda #.loword(label)
    sta ptr1
    A8
    lda #^label
    sta ptr1+2
.endmacro

; PRINT col, row, palette, label   (A8/XY16)
.macro PRINT col, row, pal, label
    LDPTR0 label
    ldx #((row)*32 + (col))
    lda #($20 | ((pal) << 2))
    jsl txt_print
.endmacro

; PRINTC row, palette, label   — centred on a 32-column line
.macro PRINTC row, pal, label
    LDPTR0 label
    ldx #((row)*32)
    lda #($20 | ((pal) << 2))
    jsl txt_print_centre
.endmacro

; immediate VRAM load during forced blank: VLOAD vram_word_addr, label, bytes
.macro VLOAD vaddr, label, bytes
    LDPTR0 label
    A16
    lda #(bytes)
    sta tmp0
    A8
    ldx #(vaddr)
    jsl vram_load
.endmacro

; copy a palette block into the CGRAM shadow: PLOAD first_colour, label, colours
.macro PLOAD first, label, count
    LDPTR0 label
    ldx #(first)
    ldy #(count)
    jsl pal_load
.endmacro

; play a sound effect by id
.macro SFX id
    lda #(id)
    jsl sfx_play
.endmacro

; text palettes (BG3)
TP_WHITE  = 0
TP_YELLOW = 1
TP_RED    = 2
TP_CYAN   = 3
TP_GREEN  = 4
TP_GREY   = 5
TP_ORANGE = 6
TP_PINK   = 7
