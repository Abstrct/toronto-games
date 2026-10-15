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
t_song:     .res 1      ; sound test: the song on the MUSIC line
t_sfx:      .res 1      ; sound test: the effect on the SOUND line
t_strow:    .res 1      ; sound test: 0 MUSIC line, 1 SOUND line
t_st:       .res 1      ; sound test panel open (no attract while it is)
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
NUM_SFX   = 21          ; the sound test's SOUND list (audio.s sfx_table)
TP_PROMPT = TP_PINK     ; the title never uses pink: PRESS START's strip palette
PROMPT_ROW = 22
.define RGB(r,g,b) ((((b)>>3)<<10)|(((g)>>3)<<5)|((r)>>3))

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
    ; PRESS START sits on its own dark strip (window-fill tiles in the pink
    ; palette, recoloured): the gold tower's reflection can't show through
    ; the gap between the words
    A16
    lda #RGB($f8, $d8, $30)
    sta pal_buf + (TP_PROMPT*4 + 1)*2
    lda #RGB($10, $10, $30)
    sta pal_buf + (TP_PROMPT*4 + 2)*2
    lda #RGB($18, $14, $40)
    sta pal_buf + (TP_PROMPT*4 + 3)*2
    A8

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
    stz t_sfx
    stz t_strow
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
    lda #TXT_WIN
    sta txt_bg
    lda frame
    and #$20
    beq @hide
    PRINTC PROMPT_ROW, TP_PROMPT, str_press
    bra @shown
@hide:
    PRINTC PROMPT_ROW, TP_PROMPT, str_blank
@shown:
    stz txt_bg

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
    lda t_st
    beq @no_st
    ; sound test open: it has the pad; START still starts the games
    jsr st_input
    A16
    lda pad_new
    and #PAD_START
    A8
    jeq @loop
    bra @start
@no_st:
    A16
    lda pad_new
    and #PAD_SELECT
    A8
    beq @no_sel
    jsr st_open
    jmp @loop
@no_sel:
    A16
    lda pad_new
    and #(PAD_START | PAD_A)
    A8
    jeq @loop
@start:
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
    lda t_st
    bne @x
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

; clear the panel and its frame (rows 2-20, columns 2-29)
attract_off:
    stz t_att
    lda tm_sh
    ora #$01                    ; the logo back
    sta tm_sh
    ldx #(2*32 + 2)
    A16
    lda #$131C                  ; 28 x 19
    sta tmp1
    A8
    stz tmp2
    lda #$00
    jsl txt_fill
    rts

; rows 2-20: one clear row above PRESS START
attract_box:
    ldx #(2*32 + 2)
    A16
    lda #$131C                  ; 28 x 19
    sta tmp1
    A8
    lda #$20
    jsl txt_box
    lda #TXT_WIN
    sta txt_bg
    lda tm_sh
    and #$FE                    ; logo off: no sliver of it above the frame
    sta tm_sh
    rts

attract_howto:
    lda #$01
    sta t_att
    jsr attract_box
    PRINTC 4, TP_YELLOW, str_how
    PRINTC 6, TP_WHITE, str_how1
    PRINTC 8, TP_WHITE, str_how2
    PRINTC 10, TP_WHITE, str_how3
    PRINTC 12, TP_WHITE, str_how4
    PRINTC 14, TP_WHITE, str_how5
    PRINTC 16, TP_WHITE, str_how6
    PRINTC 18, TP_WHITE, str_how7
    stz txt_bg
    rts

attract_records:
    lda #$02
    sta t_att
    jsr attract_box
    PRINTC 3, TP_YELLOW, str_att_rec
    stz tmp7
@ev:
    ; row 5 + ev*2
    lda tmp7
    A16
    and #$00FF
    asl a
    clc
    adc #5
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
    PRINTC 19, TP_WHITE, str_att_rec2
    stz txt_bg
    rts

; ------------------------------------------------------------------
; Sound test: a panel over the title (SELECT). Two lines: MUSIC (the 11
; songs) and SOUND (the effects). UP / DOWN pick the line, LEFT / RIGHT
; browse and play, A plays the selection again, SELECT is always "next
; song", B closes the panel, START still starts the games.
ST_MUS_ROW = 8
ST_SFX_ROW = 15

; SELECT on the title: open the panel on the next song
st_open:
    lda #$01
    sta t_st
    stz t_strow
    jsr attract_box             ; leaves txt_bg = window
    PRINTC 4, TP_YELLOW, str_st_title
    LDPTR0 str_st_music
    ldx #(6*32 + 4)
    lda #($20 | (TP_CYAN << 2))
    jsl txt_print
    LDPTR0 str_st_sound
    ldx #(13*32 + 4)
    lda #($20 | (TP_CYAN << 2))
    jsl txt_print
    PRINTC 18, TP_GREY, str_st_keys
    stz txt_bg
    PRINTC 26, TP_GREY, str_wipe
    PRINTC 26, TP_GREY, str_st_hint
    lda #$01
    jmp st_song_step            ; plays it and draws everything

; the pad while the panel is open (START is the caller's)
st_input:
    A16
    lda pad_new
    bit #PAD_SELECT
    bne @select
    bit #PAD_B
    bne @close
    bit #(PAD_UP | PAD_DOWN)
    bne @row
    bit #PAD_RIGHT
    bne @right
    bit #PAD_LEFT
    bne @left
    bit #PAD_A
    bne @play
    A8
    rts
@select:
    A8
    stz t_strow
    lda #$01
    jmp st_song_step
@close:
    A8
    stz t_st
    SFX SFX_BACK
    jsr attract_off
    PRINTC 26, TP_GREY, str_wipe
    PRINTC 26, TP_GREY, str_players
    rts
@row:
    A8
    lda t_strow
    eor #$01
    sta t_strow
    jmp st_draw
@right:
    A8
    lda #$01
    bra @step
@left:
    A8
    lda #$FF
@step:
    pha
    lda t_strow
    beq @mus
    pla
    jmp st_sfx_step
@mus:
    pla
    jmp st_song_step
@play:
    A8
    lda t_strow
    bne @fx
    lda t_song
    jsl music_play
    rts
@fx:
    lda t_sfx
    jsl sfx_play
    rts

; A = +1 / $FF: the next / previous song, played and drawn
st_song_step:
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
    jsl music_play
    jmp st_draw

; A = +1 / $FF: the next / previous effect, played and drawn
st_sfx_step:
    clc
    adc t_sfx
    bpl @nowrap
    lda #(NUM_SFX - 1)
@nowrap:
    cmp #NUM_SFX
    bcc @ok
    lda #$00
@ok:
    sta t_sfx
    jsl sfx_play
    jmp st_draw

; both lines: the counters, the names (the picked line yellow, with
; arrows), the song's band underneath
st_draw:
    lda #TXT_WIN
    sta txt_bg
    ; MUSIC  n OF 11
    lda t_song
    inc a
    A16
    and #$00FF
    sta tmp1
    A8
    ldx #(6*32 + 20)
    ldy #2
    lda #($20 | (TP_WHITE << 2))
    jsl txt_num
    LDPTR0 str_st_of_mus
    ldx #(6*32 + 22)
    lda #($20 | (TP_GREY << 2))
    jsl txt_print
    ; SOUND  n OF 18
    lda t_sfx
    inc a
    A16
    and #$00FF
    sta tmp1
    A8
    ldx #(13*32 + 20)
    ldy #2
    lda #($20 | (TP_WHITE << 2))
    jsl txt_num
    LDPTR0 str_st_of_sfx
    ldx #(13*32 + 22)
    lda #($20 | (TP_GREY << 2))
    jsl txt_print
    ; the song
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
    ldx #(ST_MUS_ROW*32)
    lda t_strow
    eor #$01                    ; 1 = this line is picked
    jsr st_line
    ; its band
    lda t_song
    A16
    and #$00FF
    asl a
    tax
    lda f:song_after,x
    sta ptr0
    A8
    lda #^song_after
    sta ptr0+2
    ldx #((ST_MUS_ROW + 2)*32)
    jsr st_clear
    lda #($20 | (TP_GREY << 2))
    jsl txt_print_centre
    ; the effect
    lda t_sfx
    A16
    and #$00FF
    asl a
    tax
    lda f:sfx_names,x
    sta ptr0
    A8
    lda #^sfx_names
    sta ptr0+2
    ldx #(ST_SFX_ROW*32)
    lda t_strow                 ; 1 = this line is picked
    jsr st_line
    stz txt_bg
    rts

; X = row * 32: blank the inside of the panel on that row (keeps X)
st_clear:
    phx
    A16
    txa
    clc
    adc #3
    tax
    lda #$011A                  ; 26 x 1
    sta tmp1
    A8
    lda #(TXT_SPACE + TXT_WIN)
    sta tmp2
    lda #$20
    jsl txt_fill
    plx
    rts

; ptr0 = name, X = row * 32, A = 1 picked / 0 not: the name centred, and
; on the picked line yellow between arrows. txt_bg = window.
st_line:
    sta tmp3
    jsr st_clear
    stx tmp4
    lda tmp3
    beq @white
    lda #($20 | (TP_YELLOW << 2))
    bra @col
@white:
    lda #($20 | (TP_WHITE << 2))
@col:
    jsl txt_print_centre
    lda tmp3
    beq @x
    ; start = (32 - len) / 2; arrows one blank either side of the name
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
    adc tmp4
    tax
    A8
    lda #(TXT_ARROW_L + TXT_WIN)
    sta tmp2
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_char
    tya
    sec                         ; + 1: one blank cell after the name
    adc tmp0
    A16
    and #$00FF
    clc
    adc tmp4
    tax
    A8
    lda #(TXT_ARROW_R + TXT_WIN)
    sta tmp2
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_char
@x:
    rts

song_names:
    .word .loword(str_s0), .loword(str_s1), .loword(str_s2), .loword(str_s3)
    .word .loword(str_s4), .loword(str_s5), .loword(str_s6), .loword(str_s7)
    .word .loword(str_s8), .loword(str_s9), .loword(str_s10)
song_after:
    .word .loword(str_a0), .loword(str_a1), .loword(str_a2), .loword(str_a1)
    .word .loword(str_a2), .loword(str_a5), .loword(str_a6), .loword(str_a7)
    .word .loword(str_a8), .loword(str_a9), .loword(str_a9)
str_s0:      .byte "KC INCIDENTAL", 0
str_s1:      .byte "BOBCAYGEESE", 0
str_s2:      .byte "GOLD GUNS GULLS", 0
str_s3:      .byte "AHEAD BY A CENTIMETRE", 0
str_s4:      .byte "WHELP, I'M ALIVE", 0
str_s5:      .byte "HAY, OFFICER", 0
str_s6:      .byte "BROTHER DOWNWIND", 0
str_s7:      .byte "A MILLION COLLARS", 0
str_s8:      .byte "PODIUM REPRISE", 0
str_s9:      .byte "PARK THE PAIN AWAY", 0
str_s10:     .byte "THE WAIT", 0
str_a0:      .byte "AFTER BROKEN SOCIAL SCENE", 0
str_a1:      .byte "AFTER THE TRAGICALLY HIP", 0
str_a2:      .byte "AFTER METRIC", 0
str_a5:      .byte "AFTER MOTHER MOTHER", 0
str_a6:      .byte "AFTER SAM ROBERTS", 0
str_a7:      .byte "AFTER BARENAKED LADIES", 0
str_a8:      .byte "THE TITLE THEME, FANFARED", 0
str_a9:      .byte "A TORONTO ORIGINAL", 0
sfx_names:
    .word .loword(fx0), .loword(fx1), .loword(fx2), .loword(fx3), .loword(fx4)
    .word .loword(fx5), .loword(fx6), .loword(fx7), .loword(fx8), .loword(fx9)
    .word .loword(fx10), .loword(fx11), .loword(fx12), .loword(fx13)
    .word .loword(fx14), .loword(fx15), .loword(fx16), .loword(fx17)
    .word .loword(fx18), .loword(fx19), .loword(fx20)
fx0:  .byte "BLIP", 0
fx1:  .byte "SELECT", 0
fx2:  .byte "BACK", 0
fx3:  .byte "JUMP", 0
fx4:  .byte "CRASH", 0
fx5:  .byte "COIN", 0
fx6:  .byte "WHISTLE", 0
fx7:  .byte "HORN", 0
fx8:  .byte "BARK", 0
fx9:  .byte "SPLASH", 0
fx10: .byte "STREETCAR BELL", 0
fx11: .byte "GO!", 0
fx12: .byte "READY", 0
fx13: .byte "FOOTSTEP", 0
fx14: .byte "SIP", 0
fx15: .byte "CHEER", 0
fx16: .byte "TICK", 0
fx17: .byte "GROAN", 0
fx18: .byte "DOOR CHIME", 0
fx19: .byte "FERRY HORN", 0
fx20: .byte "FIREWORK", 0
str_st_title:  .byte "SOUND TEST", 0
str_st_music:  .byte "MUSIC", 0
str_st_sound:  .byte "SOUND", 0
str_st_of_mus: .byte " OF 11", 0
str_st_of_sfx: .byte " OF 18", 0
str_st_keys:   .byte TXT_ARROW_U+32, TXT_ARROW_D+32, " PICK  ", TXT_ARROW_L+32, TXT_ARROW_R+32, " CHANGE  A PLAY", 0
str_st_hint:   .byte "B CLOSE    START MENU", 0

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

str_press:   .byte " PRESS START ", 0
str_blank:   .byte "             ", 0
str_wipe:    .byte "                              ", 0
str_players: .byte "1-8 PLAYERS  ", TXT_DOT + 32, "  TAKE TURNS", 0
str_sel_hint: .byte "SELECT: SOUND TEST", 0
str_how:     .byte "HOW TO PLAY", 0
str_how1:    .byte "1-8 PLAYERS TAKE TURNS", 0
str_how2:    .byte "AT SEVEN TORONTO EVENTS.", 0
str_how3:    .byte "EACH EVENT'S CARD SHOWS", 0
str_how4:    .byte "ITS CONTROLS: READ IT!", 0
str_how5:    .byte "START PAUSES THE EVENT.", 0
str_how6:    .byte "MEDALS DECIDE WHO TOPS", 0
str_how7:    .byte "THE PODIUM AT CITY HALL.", 0
str_att_rec: .byte "TORONTO RECORDS", 0
str_att_rec2: .byte "THINK YOU CAN BEAT 'EM?", 0
str_copy:    .byte 91+32, " 2026 TORONTO GAMES", 0     ; font.py tile 91 = (C)
