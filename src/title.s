; Title screen: skyline at dusk, logo slides in, PRESS START
.p816
.smart -
.include "globals.inc"
.include "screens.inc"

.global t_demo                  ; menu.s clears it (a demo cut short to the menu)

.segment "BSS"
t_slide:    .res 2      ; logo distance still to travel (px)
t_boat:     .res 2
t_gull:     .res 2
t_ready:    .res 1
t_song:     .res 1      ; sound test: SELECT / LEFT / RIGHT pick the song
t_st:       .res 1      ; sound test in use: the bottom line shows the song
t_idle:     .res 2      ; frames without a button press (attract mode)
t_att:      .res 1      ; attract panel on screen: 0 none, 1 how to, 2 records
t_demo:     .res 1      ; set when we asked for a demo: the next title starts settled

; Attract loop: title, HOW TO PLAY, RECORDS, then title_screen returns
; A = $FF and game_main plays a gameplay demo and comes back here.
; START returns A = 0 (on to the main menu).
ATT_WAIT  = 1200        ; 20 s of title before the first panel
ATT_BACK  = 600         ; after a demo: 10 s of title before the panels
ATT_SHOW  = 480         ; each panel stays up 8 s
TITLE_DEMO = $FF

.segment "SCREENS"
.a8
.i16

title_screen:
    jsl ppu_off
    jsl set_mode1_defaults
    VLOAD VRAM_BGTILES, title_tiles, (title_bg1 - title_tiles)
    VLOAD VRAM_BG1MAP, title_bg1, 2048
    VLOAD VRAM_BG2MAP, title_bg2, 2048
    PLOAD 32, title_pal, 64
    VLOAD VRAM_OBJTILES, spr_title, (spr_title_pal - spr_title)
    PLOAD 128, spr_title_pal, 16
    jsl load_text_gfx
    stz txt_bg

    ; HDMA channel 7: sky gradient into colour 0
    lda #$03
    sta $4370
    lda #<CGADD
    sta $4371
    ldx #.loword(title_sky)
    stx $4372
    lda #^title_sky
    sta $4374
    lda #$80
    sta hdma_sh

    ; logo parked on the empty right half of BG1
    ldx #256
    stx t_slide
    stx bg1x
    ldx #$FFF0
    stx t_boat
    ldx #300
    stx t_gull
    stz t_ready
    stz t_song
    stz t_st
    stz t_att
    ldx #$0000
    stx t_idle
    ; back from a demo: logo already in place, shorter wait for the panels
    lda t_demo
    beq @fresh
    stz t_demo
    stx t_slide
    stx bg1x
    lda #$01
    sta t_ready
    ldx #(ATT_WAIT - ATT_BACK)
    stx t_idle
@fresh:

    PRINTC 26, TP_GREY, str_players
    PRINTC 24, TP_GREY, str_copy
    jsl fade_in
    lda #SONG_TITLE
    jsl music_play

@loop:
    jsl wait_frame
    jsl oam_clear
    jsr title_sprites

    ; logo slide: ease out
    A16
    lda t_slide
    beq @slid
    lsr a
    lsr a
    lsr a
    bne @step
    lda #$0001
@step:
    sta tmp0
    lda t_slide
    sec
    sbc tmp0
    sta t_slide
    eor #$FFFF
    inc a
    clc
    adc #512
    and #$01FF
    sta bg1x
    lda t_slide
    bne @not_yet
    stz bg1x
    A8
    SFX SFX_SELECT
    lda #$01
    sta t_ready
    bra @blink
@not_yet:
@slid:
    A8
    lda t_ready
    beq @input
@blink:
    lda frame
    and #$20
    beq @hide
    PRINTC 22, TP_YELLOW, str_press
    bra @input
@hide:
    PRINTC 22, TP_YELLOW, str_blank

@input:
    jsr title_ticker
    A16
    lda pad_new
    A8
    bne @pressed
    jsr attract_tick
    jcs @demo
    jmp @loop
@pressed:
    ldx #$0000
    stx t_idle
    lda t_att
    beq @awake
    ; the first press only wakes the title (START still starts)
    jsr attract_off
    A16
    lda pad_new
    and #PAD_START
    A8
    jeq @loop
@awake:
    A16
    lda pad_new
    and #(PAD_SELECT | PAD_RIGHT)
    A8
    beq @no_next
    lda #$01
    jsr title_jukebox
    bra @no_sel
@no_next:
    A16
    lda pad_new
    and #PAD_LEFT
    A8
    beq @no_sel
    lda #$FF
    jsr title_jukebox
@no_sel:
    A16
    lda pad_new
    and #(PAD_START | PAD_A)
    A8
    jeq @loop
    lda t_ready
    bne @go
    ; skip the slide
    ldx #$0000
    stx t_slide
    stx bg1x
    lda #$01
    sta t_ready
    jmp @loop
@go:
    SFX SFX_SELECT
    jsl fade_out
    jsl hdma_off
    jsl music_stop
    lda #$00
    rtl
@demo:
    ; idle cycle done: ask game_main for a gameplay demo
    lda #$01
    sta t_demo
    jsl fade_out
    jsl hdma_off
    jsl music_stop
    lda #TITLE_DEMO
    rtl

; sound test: A = +1 next song / $FF previous; its name on the bottom line
title_jukebox:
    clc
    adc t_song
    bpl @nowrap
    lda #(NUM_SONGS - 1)
@nowrap:
    cmp #NUM_SONGS
    bcc @ok
    lda #$00
@ok:
    sta t_song
    lda #$01
    sta t_st
    lda t_song
    jsl music_play
    PRINTC 26, TP_GREY, str_wipe
    lda t_song
    A16
    and #$00FF
    asl a
    tax
    lda f:song_names,x
    sta ptr0
    A8
    lda #^song_names
    sta ptr0+2
    ldx #(26*32)
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_print_centre
    ; arrows hugging the name: LEFT / RIGHT browse.  start = (32 - len) / 2
    ldy #$0000
@len:
    lda [ptr0],y
    beq @got
    iny
    bra @len
@got:
    tya
    eor #$FF
    sec
    adc #32
    lsr a
    sta tmp0                    ; first column of the name
    sec
    sbc #2
    A16
    and #$00FF
    clc
    adc #(26*32)
    tax
    A8
    lda #TXT_ARROW_L
    sta tmp2
    lda #($20 | (TP_GREY << 2))
    jsl txt_char
    tya
    sec                         ; + 1: one blank cell after the name
    adc tmp0
    A16
    and #$00FF
    clc
    adc #(26*32)
    tax
    A8
    lda #TXT_ARROW_R
    sta tmp2
    lda #($20 | (TP_GREY << 2))
    jsl txt_char
    rts

; bottom line: until the sound test is used, "1-8 PLAYERS" and the
; SELECT hint take turns every ~4 s
title_ticker:
    lda t_st
    bne @x
    lda frame
    bne @x
    PRINTC 26, TP_GREY, str_wipe
    lda frame+1
    and #$01
    bne @hint
    PRINTC 26, TP_GREY, str_players
    rts
@hint:
    PRINTC 26, TP_GREY, str_sel_hint
@x:
    rts

; attract mode: after 20 s idle, HOW TO PLAY, then the records, then a
; demo. Carry set = time for the demo.
attract_tick:
    lda t_ready
    beq @x
    A16
    inc t_idle
    lda t_idle
    cmp #ATT_WAIT
    beq @howto
    cmp #(ATT_WAIT + ATT_SHOW)
    beq @records
    cmp #(ATT_WAIT + 2*ATT_SHOW)
    beq @demo
    A8
@x:
    clc
    rts
@howto:
    A8
    jsr attract_howto
    clc
    rts
@records:
    A8
    jsr attract_records
    clc
    rts
@demo:
    stz t_idle
    A8
    sec
    rts

; clear the panel (rows 4-20, columns 2-29)
attract_off:
    stz t_att
    ldx #(4*32 + 2)
    A16
    lda #$111C                  ; 28 x 17
    sta tmp1
    A8
    stz tmp2
    lda #$00
    jsl txt_fill
    rts

attract_box:
    ldx #(3*32 + 2)
    A16
    lda #$141C                  ; 28 x 20
    sta tmp1
    A8
    lda #$20
    jsl txt_box
    lda #TXT_WIN
    sta txt_bg
    rts

attract_howto:
    lda #$01
    sta t_att
    jsr attract_box
    PRINTC 6, TP_YELLOW, str_how
    PRINTC 8, TP_WHITE, str_how1
    PRINTC 10, TP_WHITE, str_how2
    PRINTC 12, TP_WHITE, str_how3
    PRINTC 14, TP_WHITE, str_how4
    PRINTC 16, TP_WHITE, str_how5
    PRINTC 18, TP_WHITE, str_how6
    stz txt_bg
    rts

attract_records:
    lda #$02
    sta t_att
    jsr attract_box
    PRINTC 4, TP_YELLOW, str_att_rec
    stz tmp7
@ev:
    ; row 6 + ev*2
    lda tmp7
    A16
    and #$00FF
    asl a
    clc
    adc #6
    asl a
    asl a
    asl a
    asl a
    asl a
    sta tmp5
    lda tmp7
    and #$00FF
    asl a
    tax
    lda f:ev_names,x
    sta ptr0
    lda tmp5
    clc
    adc #4
    tax
    A8
    lda #^ev_names
    sta ptr0+2
    lda #($20 | (TP_CYAN << 2))
    jsl txt_print
    lda tmp7
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    tax
    lda records,x
    sta tmp1
    lda tmp5
    clc
    adc #23
    tax
    A8
    ldy #5
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_num
    inc tmp7
    lda tmp7
    cmp #NUM_EVENTS
    bne @ev
    PRINTC 20, TP_WHITE, str_att_rec2
    stz txt_bg
    rts

; boat, gulls, CN Tower beacon, stars
title_sprites:
    ; sailboat drifts left to right and bobs
    lda frame
    and #$03
    bne @nb
    A16
    inc t_boat
    lda t_boat
    cmp #272
    bmi @nb16
    lda #$FFF0
    sta t_boat
@nb16:
    A8
@nb:
    A16
    lda t_boat
    sta spr_x
    A8
    lda frame
    asl a
    jsl sin8
    A16
    and #$00FF
    cmp #$0080
    bcc @pos
    ora #$FF00
@pos:
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
    clc
    adc #155                    ; clear of PRESS START (row 22)
    sta spr_y
    stz spr_tile
    A8
    lda #$30
    sta spr_attr
    lda #$01
    sta spr_size
    jsl oam_put

    ; two gulls
    A16
    lda frame
    and #$0001
    bne @ng
    dec t_gull
    lda t_gull
    cmp #$FFE0
    bne @ng
    lda #300
    sta t_gull
@ng:
    lda t_gull
    sta spr_x
    lda #112
    sta spr_y
    lda frame
    lsr a
    lsr a
    lsr a
    and #$0001
    clc
    adc #2
    sta spr_tile
    A8
    lda #$30
    sta spr_attr
    stz spr_size
    jsl oam_put
    A16
    lda t_gull
    clc
    adc #14
    sta spr_x
    lda #120
    sta spr_y
    A8
    jsl oam_put

    ; beacon
    A16
    lda #46
    sta spr_x
    lda #9
    sta spr_y
    lda frame
    and #$0020
    beq @b0
    lda #5
    bra @b1
@b0:
    lda #4
@b1:
    sta spr_tile
    A8
    jsl oam_put

    ; stars
    ldx #$0000
@star:
    phx
    A16
    lda f:star_xy,x
    and #$00FF
    sta spr_x
    lda f:star_xy+1,x
    and #$00FF
    sta spr_y
    txa
    asl a
    asl a
    asl a
    clc
    adc frame
    and #$0040
    beq @s0
    lda #7
    bra @s1
@s0:
    lda #6
@s1:
    sta spr_tile
    A8
    jsl oam_put
    plx
    inx
    inx
    cpx #(star_end - star_xy)
    bne @star
    rts

star_xy:
    .byte 8, 10, 26, 34, 66, 24, 72, 4, 10, 62, 30, 84, 248, 2, 4, 100, 236, 96
star_end:

str_press:   .byte "PRESS START", 0
str_blank:   .byte "           ", 0
str_wipe:    .byte "                              ", 0
song_names:
    .word .loword(str_s0), .loword(str_s1), .loword(str_s2), .loword(str_s3)
    .word .loword(str_s4), .loword(str_s5), .loword(str_s6), .loword(str_s7)
    .word .loword(str_s8), .loword(str_s9), .loword(str_s10)
str_s0:      .byte "1 KC INCIDENTAL", 0
str_s1:      .byte "2 BOBCAYGEESE", 0
str_s2:      .byte "3 GOLD GUNS GULLS", 0
str_s3:      .byte "4 AHEAD BY A CENTIMETRE", 0
str_s4:      .byte "5 WHELP, I'M ALIVE", 0
str_s5:      .byte "6 HAY, OFFICER", 0
str_s6:      .byte "7 BROTHER DOWNWIND", 0
str_s7:      .byte "8 A MILLION COLLARS", 0
str_s8:      .byte "9 PODIUM REPRISE", 0
str_s9:      .byte "10 GREEN P SHUFFLE", 0
str_s10:     .byte "11 PLEASE STAND CLEAR", 0
str_players: .byte "1-8 PLAYERS  ", TXT_DOT + 32, "  TAKE TURNS", 0
str_sel_hint: .byte "SELECT: SOUND TEST", 0
str_how:     .byte "HOW TO PLAY", 0
str_how1:    .byte "1-8 PLAYERS TAKE TURNS", 0
str_how2:    .byte "AT FIVE TORONTO EVENTS.", 0
str_how3:    .byte "EACH EVENT'S CARD SHOWS", 0
str_how4:    .byte "ITS CONTROLS: READ IT!", 0
str_how5:    .byte "MEDALS DECIDE WHO TOPS", 0
str_how6:    .byte "THE PODIUM AT CITY HALL.", 0
str_att_rec: .byte "TORONTO RECORDS", 0
str_att_rec2: .byte "THINK YOU CAN BEAT 'EM?", 0
str_copy:    .byte 91+32, " 2026 TORONTO GAMES", 0     ; font.py tile 91 = (C)
