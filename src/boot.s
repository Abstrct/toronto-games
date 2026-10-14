; Reset, hardware init, NMI handler, frame sync and joypads
.p816
.smart -
.include "globals.inc"

.export reset_stub, nmi_stub, irq_stub
.import game_main
.import __ZP_START__
.import demo_abort, demo_blob

.segment "HIBSS"                ; bank $7E: long addressing only
p_txt:      .res 7*64           ; text rows under the PAUSED box
p_zp:       .res 25

.segment "BSS"
p_bg:       .res 1
p_mosaic:   .res 1
p_music:    .res 1
p_sel:      .res 1              ; pause menu: 0 play on, 1 call it a day

.segment "CODE"

; ---- vectors land in bank $00; hop to the $80 mirror straight away ----
reset_stub:
    sei
    clc
    xce
    jml reset

nmi_stub:
    jml nmi_handler

irq_stub:
    rti

; ------------------------------------------------------------------
reset:
    rep #$38                ; A16 XY16, binary mode
    .a16
    .i16
    ldx #$1FFF
    txs
    lda #$0000
    tcd
    A8
    phk
    plb                     ; DB = $80

    lda #$80
    sta INIDISP             ; forced blank
    stz NMITIMEN
    stz HDMAEN
    stz MDMAEN

    ; --- PPU registers to known values ---
    ldx #$2101
@ppu_clear:
    stz $00,x
    inx
    cpx #$210D
    bne @ppu_clear
@scroll_clear:              ; $210D-$2114 are write-twice
    stz $00,x
    stz $00,x
    inx
    cpx #$2115
    bne @scroll_clear
    lda #$80
    sta VMAIN
    stz VMADDL
    stz VMADDH
    stz M7SEL
    ldx #$2123
@win_clear:
    stz $00,x
    inx
    cpx #$2134
    bne @win_clear
    lda #$30
    sta CGWSEL
    lda #$E0
    sta COLDATA
    lda #$FF
    sta WRIO
    stz MEMSEL

    ; --- clear all 128 KB of WRAM with a fixed-source DMA (stack is empty) ---
    stz WMADDL
    stz WMADDM
    stz WMADDH
    lda #$08                ; fixed source, one register
    sta $4310
    lda #<WMDATA
    sta $4311
    ldx #.loword(zero_byte)
    stx $4312
    lda #^zero_byte
    sta $4314
    ldx #$0000              ; 64 KB
    stx $4315
    lda #$02
    sta MDMAEN
    ldx #$0000
    stx $4315
    lda #$02
    sta MDMAEN

    ; --- clear VRAM, CGRAM, OAM ---
    jsl vram_clear_all
    stz CGADD
    ldx #512
@cg:
    stz CGDATA
    dex
    bne @cg
    stz OAMADDL
    stz OAMADDH
    ldx #512
@oam_lo:
    lda #$F0
    sta OAMDATA
    dex
    bne @oam_lo
    ldx #32
@oam_hi:
    stz OAMDATA
    dex
    bne @oam_hi

    ; --- engine state ---
    lda #$80
    sta inidisp_sh
    A16
    lda #$ACE1
    sta rng
    A8
    jsl oam_clear
    jsl txt_clear
    jsl audio_init

    lda #$81                ; NMI on, auto joypad read on
    sta NMITIMEN
    cli
    jml game_main

zero_byte:
    .byte $00

; ------------------------------------------------------------------
; NMI: push OAM, palette, text map and the DMA queue, then set scroll
; and display registers from their shadows. Only does the uploads when
; the main loop has finished a frame (nmi_ready = 1).
nmi_handler:
    rep #$30
    .a16
    .i16
    pha
    phx
    phy
    phd
    phb
    lda #$0000
    tcd
    A8
    lda #$80
    pha
    plb
    lda RDNMI

    lda nmi_ready
    bne @upload
    inc lag
    jmp @regs

@upload:
    ; OAM: 544 bytes from oam_buf on channel 0
    stz OAMADDL
    stz OAMADDH
    lda #$00
    sta DMAP0
    lda #<OAMDATA
    sta BBAD0
    ldx #.loword(oam_buf)
    stx A1T0L
    stz A1B0
    ldx #544
    stx DAS0L
    lda #$01
    sta MDMAEN

    ; CGRAM shadow
    lda pal_dirty
    beq @no_pal
    stz CGADD
    lda #$00
    sta DMAP0
    lda #<CGDATA
    sta BBAD0
    ldx #.loword(pal_buf)
    stx A1T0L
    stz A1B0
    ldx #512
    stx DAS0L
    lda #$01
    sta MDMAEN
    stz pal_dirty
@no_pal:

    ; BG3 text map
    lda txt_dirty
    beq @no_txt
    lda #$80
    sta VMAIN
    ldx #VRAM_BG3MAP
    stx VMADDL
    lda #$01
    sta DMAP0
    lda #<VMDATAL
    sta BBAD0
    ldx #.loword(txt_map)
    stx A1T0L
    stz A1B0
    ldx #2048
    stx DAS0L
    lda #$01
    sta MDMAEN
    stz txt_dirty
@no_txt:

    ; queued VRAM transfers
    ldx #$0000
@q_loop:
    cpx dmaq_len
    bcs @q_done
    lda dmaq+7,x
    sta VMAIN
    A16
    lda dmaq,x
    sta VMADDL
    lda dmaq+2,x
    sta A1T0L
    lda dmaq+5,x
    sta DAS0L
    A8
    lda dmaq+4,x
    sta A1B0
    lda #$01
    sta DMAP0
    lda #<VMDATAL
    sta BBAD0
    lda #$01
    sta MDMAEN
    A16
    txa
    clc
    adc #8
    tax
    A8
    bra @q_loop
@q_done:
    ldx #$0000
    stx dmaq_len
    stz nmi_ready

@regs:
    lda bg1x
    sta BG1HOFS
    lda bg1x+1
    sta BG1HOFS
    lda bg1y
    sta BG1VOFS
    lda bg1y+1
    sta BG1VOFS
    lda bg2x
    sta BG2HOFS
    lda bg2x+1
    sta BG2HOFS
    lda bg2y
    sta BG2VOFS
    lda bg2y+1
    sta BG2VOFS
    lda bg3x
    sta BG3HOFS
    lda bg3x+1
    sta BG3HOFS
    lda bg3y
    sta BG3VOFS
    lda bg3y+1
    sta BG3VOFS
    lda tm_sh
    sta TM
    lda ts_sh
    sta TS
    lda cgwsel_sh
    sta CGWSEL
    lda cgadsub_sh
    sta CGADSUB
    lda mosaic_sh
    sta MOSAIC
    lda hdma_sh
    sta HDMAEN
    lda inidisp_sh
    sta INIDISP

    ; joypads (auto-read finishes a few lines into vblank)
@joy_wait:
    lda HVBJOY
    and #$01
    bne @joy_wait
    ldx JOY1L
    stx pad1
    ldx JOY2L
    stx pad2

    A16
    inc frame
    rep #$30
    plb
    pld
    ply
    plx
    pla
    rti

; ------------------------------------------------------------------
; wait_frame: hand the finished frame to NMI, wait for it, update pads.
; During event play (pause_ok, armed by event_countdown and cleared by
; score_card) START pauses the game right here, inside the event's frame.
.a8
.i16
wait_frame:
    jsr frame_sync
    lda pause_ok
    beq @tick
    A16
    lda pad_new
    and #PAD_START
    A8
    beq @tick
    jsr pause_game
@tick:
    jsl audio_tick
    rtl

; hand over the frame, wait for the NMI, read the pads (keeps X Y)
frame_sync:
    lda #$01
    sta nmi_ready
@w:
    lda nmi_ready
    bne @w
    lda demo_on
    bne demo_pads
    A16
    lda pad
    sta pad_prev
    lda pad1
    ora pad2
    sta pad
    eor pad_prev
    and pad
    sta pad_new
    A8
    rts

; Attract demo (game.s demo_play). demo_on 1: pad comes from the recorded
; stream at demo_blob + demo_off, runs of (mask word, frames byte), frames
; 0 = the end; a real press (pad1 / pad2, read apart from the stream) or the
; end of the stream unwinds to demo_abort. demo_on 2 records: the real pads
; pass through and are logged as words at $7F:0000 (demo_off = bytes).
demo_pads:
    phx
    cmp #$02
    beq @rec
    A16
    lda pad1
    ora pad2
    tax
    lda demo_real
    eor #$FFFF
    stx demo_real
    and demo_real               ; buttons pressed this frame for real
    bne @abort
    lda demo_left
    bne @have
    ldx demo_off
    lda f:demo_blob+2,x
    and #$00FF
    beq @abort                  ; end of the stream
    sta demo_left
    lda f:demo_blob,x
    sta demo_mask
    inx
    inx
    inx
    stx demo_off
@have:
    dec demo_left
    lda pad
    sta pad_prev
    lda demo_mask
    bra @set
@rec:
    A16
    lda pad
    sta pad_prev
    lda pad1
    ora pad2
    ldx demo_off
    cpx #$FFF0
    bcs @set
    sta f:$7F0000,x
    inx
    inx
    stx demo_off
@set:
    sta pad
    eor pad_prev
    and pad
    sta pad_new
    A8
    jsr demo_banner
    plx
    rts
@abort:
    A8
    ldx demo_sp
    txs
    jml demo_abort

; " DEMO - PRESS START " on a solid strip (window tiles, so traffic passes
; under it) on a text row the running event leaves alone, rewritten every 16
; frames in case the event cleared the layer; only in play (pause_ok), so
; the intro and score cards stay clean
demo_banner:
    lda pause_ok
    beq @x
    lda frame
    and #$0F
    bne @x
    phy
    lda event_idx
    A16
    and #$00FF
    tax
    A8
    lda f:demo_rows,x
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    clc
    adc #(6*2)
    tay
    A8
    ldx #$0000
@l:
    lda f:str_demo,x
    beq @d
    sec
    sbc #32
    clc
    adc #TXT_WIN
    sta txt_map,y
    lda #($20 | (TP_YELLOW << 2))
    sta txt_map+1,y
    iny
    iny
    inx
    bra @l
@d:
    lda #$01
    sta txt_dirty
    ply
@x:
    rts

str_demo:  .byte " DEMO - PRESS START ", 0
; per event: the banner row (BIKE BAY PARK COPS SAIL PARKING SUBWAY)
demo_rows: .byte 4, 4, 4, 4, 26, 25, 26
.assert * - demo_rows = NUM_EVENTS, error, "demo_rows: one banner row per event"

; ------------------------------------------------------------------
; pause_game: freeze the event until START is pressed again. The music stops
; (and picks up where it was), BG1/BG2 go to mosaic and a PAUSED box sits in
; the middle of the text layer; everything the event had there comes back.
; The box is a menu: PLAY ON, or CALL IT A DAY (sets ev_giveup: the event
; ends itself as a give-up, ev_fail = 3). START always plays on.
PAUSE_ROW  = 10                 ; box rows 10..16
PAUSE_ROWS = 7
PZP_LEN    = 25                 ; tmp0..tmp7, ptr0..ptr2

pause_game:
    phx
    phy
    ldx #$0000
@sz:
    lda tmp0,x
    sta f:p_zp,x
    inx
    cpx #PZP_LEN
    bne @sz
    ldx #$0000
@st:
    lda txt_map+PAUSE_ROW*64,x
    sta f:p_txt,x
    inx
    cpx #(PAUSE_ROWS*64)
    bne @st
    lda txt_bg
    sta p_bg
    lda mosaic_sh
    sta p_mosaic
    lda music_on
    sta p_music
    jsl music_stop
    lda #SFX_BLIP
    jsl sfx_play
    lda #$73                    ; mosaic 8x8 on BG1 + BG2
    sta mosaic_sh
    ldx #(PAUSE_ROW*32 + 6)
    A16
    lda #((PAUSE_ROWS << 8) | 20)
    sta tmp1
    A8
    lda #$20
    jsl txt_box
    lda #TXT_WIN
    sta txt_bg
    LDPTR0 str_paused
    ldx #((PAUSE_ROW+1)*32)
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_print_centre
    stz p_sel
    jsr p_draw
@wait:
    jsr frame_sync
    jsl audio_tick
    A16
    lda pad_new
    bit #(PAD_START | PAD_B)
    bne @resume
    bit #(PAD_UP | PAD_DOWN | PAD_SELECT)
    bne @move
    bit #PAD_A
    bne @pick
    A8
    bra @wait
@move:
    A8
    lda p_sel
    eor #$01
    sta p_sel
    lda #SFX_BLIP
    jsl sfx_play
    jsr p_draw
    bra @wait
@pick:
    A8
    lda p_sel
    beq @resume
    lda #$01
    sta ev_giveup
    lda #SFX_BACK
    jsl sfx_play
@resume:
    A8
    ldx #$0000
@rt:
    lda f:p_txt,x
    sta txt_map+PAUSE_ROW*64,x
    inx
    cpx #(PAUSE_ROWS*64)
    bne @rt
    lda #$01
    sta txt_dirty
    lda p_bg
    sta txt_bg
    lda p_mosaic
    sta mosaic_sh
    lda ev_giveup
    bne @quiet
    lda #SFX_BLIP
    jsl sfx_play
@quiet:
    lda p_music
    sta music_on                ; the sequencer carries on from its step
    ldx #$0000
@rz:
    lda f:p_zp,x
    sta tmp0,x
    inx
    cpx #PZP_LEN
    bne @rz
    A16
    stz pad_new                 ; the press that resumed is not the event's
    A8
    ply
    plx
    rts

; the two choices, the arrow on p_sel
p_draw:
    stz tmp6
@o:
    lda tmp6
    asl a
    clc
    adc #(PAUSE_ROW + 3)
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    clc
    adc #8
    tax
    A8
    lda tmp6
    cmp p_sel
    bne @blank
    lda #(TXT_ARROW_R + TXT_WIN)
    bra @ar
@blank:
    lda #(TXT_SPACE + TXT_WIN)
@ar:
    sta tmp2
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_char
    inx
    inx
    phx
    lda tmp6
    asl a
    A16
    and #$00FF
    tax
    lda f:p_opts,x
    sta ptr0
    A8
    lda #^p_opts
    sta ptr0+2
    plx
    lda tmp6
    cmp p_sel
    bne @grey
    lda #($20 | (TP_YELLOW << 2))
    bra @pr
@grey:
    lda #($20 | (TP_GREY << 2))
@pr:
    jsl txt_print
    inc tmp6
    lda tmp6
    cmp #2
    bne @o
    rts

str_paused: .byte "PAUSED", 0
p_opts:     .addr str_playon, str_giveup
str_playon: .byte "PLAY ON", 0
str_giveup: .byte "CALL IT A DAY", 0

; X = number of frames
wait_frames:
@l:
    phx
    jsl wait_frame
    plx
    dex
    bne @l
    rtl

; ------------------------------------------------------------------
; dma_queue: X = VRAM word address, ptr0 = source (long), tmp0 = bytes,
; A = VMAIN value ($80 rows, $81 columns). Dropped if the queue is full.
dma_queue:
    pha
    phy
    ldy dmaq_len
    cpy #(8*24)
    bcs @full
    sta dmaq+7,y
    A16
    txa
    sta dmaq,y
    lda ptr0
    sta dmaq+2,y
    lda tmp0
    sta dmaq+5,y
    A8
    lda ptr0+2
    sta dmaq+4,y
    A16
    tya
    clc
    adc #8
    sta dmaq_len
    A8
@full:
    ply
    pla
    rtl
