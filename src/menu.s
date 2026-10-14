; Main menu and event picker (the records board is cards.s records_board)
.p816
.smart -
.include "globals.inc"
.include "screens.inc"

.global roster_resume           ; register.s
.global t_demo                  ; title.s
.global reg_fade_out_q          ; register.s: fade out, keeping presses for the grid

.segment "BSS"
m_sel:      .res 1
m_count:    .res 1
m_col:      .res 2      ; text column for draw_list
pk_sel:     .res 1      ; event-picker cursor, kept across a trip back to the roster

.segment "SCREENS"
.a8
.i16

; menu_screen_setup: menu backdrop, BG1 off, text window frame
menu_setup:
    ldx #7
    stx m_col
    jsl ppu_off
    jsl set_mode1_defaults
    jsl load_menu_gfx
    ; the backdrop map is 64 wide: fill the right half too, or the
    ; diagonal scroll runs off into an empty screen
    VLOAD (VRAM_BG2MAP + $400), menu_bg2, 2048
    lda #$16                    ; BG2, BG3, OBJ (badges hidden)
    sta tm_sh
    rts

; draw a list of strings (ptr table at tmp table) with an arrow on m_sel
; ptr1 = .addr table (bank ^ptr1), m_count entries, first row in tmp7, column 6
draw_list:
    stz tmp5
@row:
    ; text pointer
    lda tmp5
    A16
    and #$00FF
    asl a
    tay
    lda [ptr1],y
    sta ptr0
    A8
    lda ptr1+2
    sta ptr0+2
    ; cell = (row0 + i*2) * 32 + 7
    lda tmp5
    asl a
    clc
    adc tmp7
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    clc
    adc m_col
    tax
    A8
    phx
    lda tmp5
    cmp m_sel
    bne @plain
    lda #($20 | (TP_YELLOW << 2))
    bra @pr
@plain:
    lda #($20 | (TP_WHITE << 2))
@pr:
    jsl txt_print
    plx
    ; arrow or blank two cells to the left
    A16
    txa
    sec
    sbc #2
    tax
    A8
    lda tmp5
    cmp m_sel
    bne @noarrow
    lda #(TXT_ARROW_R + TXT_WIN)
    bra @put
@noarrow:
    lda #(TXT_SPACE + TXT_WIN)
@put:
    sta tmp2
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_char
    inc tmp5
    lda tmp5
    cmp m_count
    bne @row
    rts

; up/down on m_sel within m_count; returns carry set if it moved
list_nav:
    A16
    lda pad_new
    bit #PAD_UP
    bne @up
    bit #PAD_DOWN
    bne @down
    A8
    clc
    rts
@up:
    A8
    lda m_sel
    bne @u1
    lda m_count
@u1:
    dec a
    sta m_sel
    bra @moved
@down:
    A8
    lda m_sel
    inc a
    cmp m_count
    bcc @d1
    lda #$00
@d1:
    sta m_sel
@moved:
    SFX SFX_BLIP
    sec
    rts

; ------------------------------------------------------------------
main_menu:
    stz t_demo                  ; the next title is a fresh one (logo slides in)
    jsr menu_setup
    PRINTC 3, TP_YELLOW, str_title
    PRINTC 5, TP_CYAN, str_sub
    ldx #(8*32 + 3)
    A16
    lda #$0A1A                  ; 26 wide, 10 tall
    sta tmp1
    A8
    lda #$20
    jsl txt_box
    ldx #6
    stx m_col
    lda #TXT_WIN
    sta txt_bg
    stz m_sel
    lda #4
    sta m_count
    LDPTR1 menu_items
    lda #10
    sta tmp7
    jsr draw_list
    stz txt_bg
    PRINTC 25, TP_GREY, str_hint
    jsl fade_in
    lda #SONG_MENU
    jsl music_play
@loop:
    jsl wait_frame
    jsl menu_backdrop_tick
    jsr list_nav
    bcc @nomove
    lda #TXT_WIN
    sta txt_bg
    LDPTR1 menu_items
    lda #10
    sta tmp7
    jsr draw_list
    stz txt_bg
@nomove:
    A16
    lda pad_new
    and #(PAD_A | PAD_START)
    A8
    beq @loop
    SFX SFX_SELECT
    lda m_sel
    cmp #3
    beq @plain
    jsr reg_fade_out_q          ; on to sign-up: presses carry into the name grid
    bra @out
@plain:
    jsl fade_out
@out:
    lda m_sel
    rtl

menu_items:
    .addr mi0, mi1, mi2, mi3
mi0: .byte "COMPETE IN ALL EVENTS", 0
mi1: .byte "COMPETE IN SOME", 0
mi2: .byte "PRACTICE ONE EVENT", 0
mi3: .byte "TORONTO RECORDS", 0
str_title: .byte "TORONTO GAMES", 0
str_sub:   .byte "THE OLYMPICS WE CAN AFFORD", 0
str_hint:  .byte "A SELECT    ", TXT_ARROW_U+32, TXT_ARROW_D+32, " MOVE", 0

; ------------------------------------------------------------------
; pick_events: GM_SOME toggles any events (none start ticked, so one event
; is A then START; SELECT ticks all, or none once all are on), GM_PRACTICE
; picks one. B goes back ONE step, to the competitors with the roster kept;
; carry is set only if the player then leaves the roster for the main menu.
TXT_TICK_OFF = 89               ; font.py: empty / crossed tick boxes
TXT_TICK_ON  = 90
PK_ROW0 = 6                     ; first event row (16 px pitch, seven rows)

pick_events:
    ldx #$0000                  ; nothing ticked until you pick
@f1:
    stz event_on,x
    inx
    cpx #NUM_EVENTS
    bne @f1
    stz pk_sel
pick_show:
    jsr menu_setup
    lda game_mode
    cmp #GM_PRACTICE
    beq @t1
    PRINTC 3, TP_YELLOW, str_pick_some
    bra @t2
@t1:
    PRINTC 3, TP_YELLOW, str_pick_one
@t2:
    ldx #(5*32 + 2)
    A16
    lda #$111C                  ; 28 x 17: seven event rows + the count line
    sta tmp1
    A8
    lda #$20
    jsl txt_box
    lda pk_sel
    sta m_sel
    lda #NUM_EVENTS
    sta m_count
    jsr draw_events
    lda game_mode
    cmp #GM_PRACTICE
    beq @hint1
    PRINTC 24, TP_GREY, str_pick_hint
    bra @hinted
@hint1:
    PRINTC 24, TP_GREY, str_pick_hint1
@hinted:
    jsl fade_in
@loop:
    jsl wait_frame
    jsl menu_backdrop_tick
    jsr list_nav
    bcc @nm
    jsr draw_events
@nm:
    A16
    lda pad_new
    bit #PAD_B
    jne @back
    bit #PAD_START
    jne @start
    bit #PAD_A
    bne @toggle
    bit #PAD_SELECT
    bne @all
    A8
    bra @loop
@all:
    ; SELECT: every event on, or (all on already) every event off
    A8
    lda game_mode
    cmp #GM_PRACTICE
    beq @loop
    ldx #$0000
    lda #$01
@a1:
    and event_on,x
    inx
    cpx #NUM_EVENTS
    bne @a1
    eor #$01                    ; 1 = turn them all on
    ldx #$0000
@a2:
    sta event_on,x
    inx
    cpx #NUM_EVENTS
    bne @a2
    cmp #$00
    beq @off_sfx
    SFX SFX_SELECT
    bra @toggled
@toggle:
    A8
    lda game_mode
    cmp #GM_PRACTICE
    beq @single
    lda m_sel
    TAXB
    lda event_on,x
    eor #$01
    sta event_on,x
    beq @off_sfx
    SFX SFX_SELECT
    bra @toggled
@off_sfx:
    SFX SFX_BLIP
@toggled:
    jsr draw_events
    PRINTC 22, TP_RED, str_pick_wipe
    jmp @loop
@single:
    lda m_sel
    TAXB
    lda #$01
    sta event_on,x
    bra @done
@start:
    A8
    ; practice: START plays the highlighted event
    lda game_mode
    cmp #GM_PRACTICE
    beq @single
    ; some: at least one event has to be ticked
    ldx #$0000
@any:
    lda event_on,x
    bne @done
    inx
    cpx #NUM_EVENTS
    bne @any
    SFX SFX_BACK
    PRINTC 22, TP_RED, str_pick_none
    jmp @loop
@done:
    SFX SFX_SELECT
    jsl fade_out
    clc
    rtl
@back:
    A8
    SFX SFX_BACK
    lda m_sel
    sta pk_sel
    jsl fade_out
    jsl roster_resume           ; carry set = left for the main menu
    bcc @again
    rtl
@again:
    jmp pick_show

; one row per event: arrow, tick box, name (grey when off), ON / OFF
draw_events:
    lda #TXT_WIN
    sta txt_bg
    stz tmp5
@row:
    lda tmp5
    A16
    and #$00FF
    asl a
    clc
    adc #PK_ROW0
    asl a
    asl a
    asl a
    asl a
    asl a
    sta tmp6                    ; cell of column 0
    clc
    adc #3
    tax
    A8
    ; arrow
    lda #(TXT_SPACE + TXT_WIN)
    sta tmp2
    lda tmp5
    cmp m_sel
    bne @na
    lda #(TXT_ARROW_R + TXT_WIN)
    sta tmp2
@na:
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_char
    ; tmp7: 0 off, 1 on (practice lists every event as on)
    lda #$01
    sta tmp7
    lda game_mode
    cmp #GM_PRACTICE
    beq @name
    lda tmp5
    TAXB
    lda event_on,x
    sta tmp7
    ; tick box at column 5
    A16
    lda tmp6
    clc
    adc #5
    tax
    A8
    lda tmp7
    beq @boxoff
    lda #(TXT_TICK_ON + TXT_WIN)
    sta tmp2
    lda #($20 | (TP_GREEN << 2))
    bra @box
@boxoff:
    lda #(TXT_TICK_OFF + TXT_WIN)
    sta tmp2
    lda #($20 | (TP_GREY << 2))
@box:
    jsl txt_char
    ; ON / OFF at column 26
    A16
    lda tmp6
    clc
    adc #26
    tax
    A8
    lda tmp7
    beq @stoff
    LDPTR0 str_on
    lda #($20 | (TP_GREEN << 2))
    bra @st
@stoff:
    LDPTR0 str_off
    lda #($20 | (TP_GREY << 2))
@st:
    jsl txt_print
@name:
    ; name at column 7: yellow under the cursor, white when on, grey when off
    lda tmp5
    A16
    and #$00FF
    asl a
    tax
    lda f:ev_names,x
    sta ptr0
    lda tmp6
    clc
    adc #7
    tax
    A8
    lda #^ev_names
    sta ptr0+2
    lda tmp5
    cmp m_sel
    bne @nsel
    lda #($20 | (TP_YELLOW << 2))
    bra @npr
@nsel:
    lda tmp7
    beq @ngrey
    lda #($20 | (TP_WHITE << 2))
    bra @npr
@ngrey:
    lda #($20 | (TP_GREY << 2))
@npr:
    jsl txt_print
    inc tmp5
    lda tmp5
    cmp #NUM_EVENTS
    jne @row
    ; how many are on (some mode)
    lda game_mode
    cmp #GM_PRACTICE
    beq @x
    stz tmp7
    ldx #$0000
@cnt:
    lda event_on,x
    beq @c0
    inc tmp7
@c0:
    inx
    cpx #NUM_EVENTS
    bne @cnt
    lda tmp7
    pha
    A16
    and #$00FF
    sta tmp1
    A8
    ldx #(20*32 + 4)
    ldy #1
    lda #($20 | (TP_CYAN << 2))
    jsl txt_num
    LDPTR0 str_pick_count
    ldx #(20*32 + 5)
    lda #($20 | (TP_CYAN << 2))
    jsl txt_print
    ; what SELECT does next: ALL, or NONE when every event is on
    LDPTR0 str_pick_all
    pla
    cmp #NUM_EVENTS
    bne @sel
    LDPTR0 str_pick_nonea
@sel:
    ldx #(20*32 + 16)
    lda #($20 | (TP_GREY << 2))
    jsl txt_print
@x:
    stz txt_bg
    rts

str_pick_some: .byte "PICK YOUR EVENTS", 0
str_pick_one:  .byte "PRACTICE WHICH EVENT?", 0
str_pick_hint: .byte "A ON/OFF  START GO  B BACK", 0
str_pick_hint1: .byte "A OR START PLAY  B BACK", 0
str_pick_none: .byte "TICK AT LEAST ONE EVENT!", 0
str_pick_wipe: .byte "                        ", 0
str_pick_count: .byte " OF 7 ON", 0
str_pick_all:   .byte "SELECT: ALL ", 0
str_pick_nonea: .byte "SELECT: NONE", 0
str_on:        .byte "ON ", 0
str_off:       .byte "OFF", 0
