; Sign-up: roster, name entry on a letter grid, sponsor pick
.p816
.smart -
.include "globals.inc"
.include "screens.inc"

.global roster_resume           ; menu.s: B on the event picker comes back here
.global reg_fade_out_q          ; menu.s: the main menu's way into sign-up

R_QMAX = 12                     ; presses kept for the name grid
R_ALOCK = 30                    ; frames A must be up before a full roster's START! takes it

.segment "BSS"
r_cx:       .res 1      ; grid cursor
r_cy:       .res 1
r_len:      .res 1      ; name length
r_name:     .res 10
r_sp:       .res 1      ; highlighted sponsor
r_btmr:     .res 1      ; frames since the last delete: B on a blank name
                        ; only backs out once you've stopped deleting
r_rsel:     .res 1      ; roster cursor, kept between visits
r_keep:     .res 1      ; name_entry: keep the name (back from the sponsors)
r_rm:       .res 1      ; remove confirm: 0 NO, 1 YES
r_qn:       .res 1      ; presses queued on the way into the name grid
r_q:        .res R_QMAX
r_alock:    .res 1      ; roster: frames before A on START! counts (a full roster)

.segment "SCREENS"
.a8
.i16

GRID_ROW0 = 12

; carry set = backed out to the main menu
register_players:
    stz num_players
    stz r_rsel
reg_flow:
@again:
    lda num_players
    bne @roster
    jsr add_player
    bcc @again
    rtl                         ; carry still set
@roster:
    jsr roster_screen           ; A: 0 add, 1 emptied, 2 start, $FF back
    cmp #$FF
    beq @back
    cmp #2
    beq @start
    cmp #1
    beq @remove
    lda num_players
    cmp #MAX_PLAYERS
    bcs @roster
    jsr add_player
    bra @again
@remove:
    bra @again                  ; removed the last one: sign someone up
@start:
    clc
    rtl
@back:
    sec
    rtl

; ------------------------------------------------------------------
add_player:
    stz r_keep
@name:
    jsr name_entry
    bcs @cancel
    jsr sponsor_select
    bcc @signed
    lda #$01                    ; B on the sponsors: the name is still there
    sta r_keep
    bra @name
@signed:
    inc num_players
    clc
    rts
@cancel:
    sec
    rts

; ------------------------------------------------------------------
; roster: one competitor per 16 px row, the three actions side by side
roster_screen:
    jsr menu_setup
    PRINTC 1, TP_YELLOW, str_competitors
    ldx #(3*32 + 1)
    A16
    lda #$111E                  ; 30 x 17
    sta tmp1
    A8
    lda #$20
    jsl txt_box
    ldx #(20*32 + 1)
    A16
    lda #$031E                  ; 30 x 3
    sta tmp1
    A8
    lda #$20
    jsl txt_box
    jsr draw_roster_list
    jmp roster_live

; the competitors, one per 16 px row (txt_bg ends 0)
draw_roster_list:
    lda #TXT_WIN
    sta txt_bg
    ; blank rows 4..18 first: a removed player leaves nothing behind
    ldx #(4*32 + 2)
    A16
    lda #$0F1C                  ; 28 x 15
    sta tmp1
    A8
    lda #(TXT_SPACE + TXT_WIN)
    sta tmp2
    lda #$20
    jsl txt_fill
    stz tmp7
@pl:
    lda tmp7
    cmp num_players
    bcs @listed
    ; row 4 + i*2
    A16
    lda tmp7
    and #$00FF
    asl a
    clc
    adc #4
    asl a
    asl a
    asl a
    asl a
    asl a
    sta tmp5                    ; row cell base
    clc
    adc #3
    tax
    lda tmp7
    and #$00FF
    inc a
    sta tmp1
    A8
    ldy #1
    lda #($20 | (TP_CYAN << 2))
    jsl txt_num
    A16
    lda tmp5
    clc
    adc #5
    tax
    A8
    lda #($20 | (TP_WHITE << 2))
    sta tmp6
    lda tmp7
    jsl print_player_name
    lda tmp7
    jsl player_offset
    lda players+PL_SPONSOR,x
    pha
    A16
    lda tmp5
    clc
    adc #14
    tax
    A8
    lda #($20 | (TP_YELLOW << 2))
    sta tmp6
    pla
    jsr print_sponsor_short
    inc tmp7
    bra @pl
@listed:
    stz txt_bg
    rts

roster_live:
    ; the cursor stays where it was, except that a full roster parks it on
    ; START! rather than the dead ROSTER FULL; then A only counts once it
    ; has been let go for R_ALOCK frames, so the A that picked the eighth
    ; sponsor (or a mash after it) can't start the games
    stz r_alock
    lda r_rsel
    sta m_sel
    bne @drawn
    lda num_players
    cmp #MAX_PLAYERS
    bcc @drawn
    lda #2
    sta m_sel
    lda #R_ALOCK
    sta r_alock
@drawn:
    jsr draw_roster_menu
    PRINTC 26, TP_GREY, str_roster_hint
    ; fade in from inside the loop: the pad is live from the first visible
    ; frame, so no tap is dropped (pad_new is edge-triggered: a button still
    ; held from the last screen does nothing)
    stz inidisp_sh
@loop:
    jsl wait_frame
    jsr fade_step
    jsl menu_backdrop_tick
    lda r_alock
    beq @live
    A16
    lda pad
    and #PAD_A
    A8
    beq @quiet
    lda #R_ALOCK                ; A still down: the let-go starts again
    sta r_alock
    bra @live
@quiet:
    dec r_alock
@live:
    A16
    lda pad_new
    bit #(PAD_LEFT | PAD_UP)
    bne @prev
    bit #(PAD_RIGHT | PAD_DOWN)
    bne @next
    bit #PAD_B
    jne @back
    bit #PAD_START
    bne @start
    bit #PAD_A
    bne @pick
    A8
    bra @loop
    ; no wrap: LEFT from ADD PLAYER must never land on START!
@prev:
    A8
    lda m_sel
    jeq @loop
    dec a
    bne @moved
    lda num_players             ; (never back onto ROSTER FULL)
    cmp #MAX_PLAYERS
    jcs @loop
    lda #$00
    bra @moved
@next:
    A8
    lda m_sel
    cmp #2
    jcs @loop
    inc a
@moved:
    sta m_sel
    SFX SFX_BLIP
    jsr draw_roster_menu
    bra @loop
@start:
    A8
    lda #2
    sta m_sel
    bra @pick8
@pick:
    A8
    lda r_alock                 ; a full roster's START!: not until A is let go
    jne @loop
@pick8:
    lda m_sel
    bne @ok
    lda num_players
    cmp #MAX_PLAYERS
    bcc @ok
    SFX SFX_BACK
    PRINTC 26, TP_RED, str_roster_full
    jmp @loop
@ok:
    lda m_sel
    cmp #1
    beq @remove
    sta r_rsel
    SFX SFX_SELECT
    lda m_sel
    bne @plain_out
    jsr reg_fade_out_q          ; ADD PLAYER: presses carry into the grid
    lda #$00
    rts
@plain_out:
    jsl fade_out
    lda m_sel
    rts
@remove:
    ; REMOVE: "REMOVE 4 JEN?  NO  YES", the cursor on NO, so a second A
    ; from a mash keeps everyone. Done in place: no fade, no dropped tap.
    SFX SFX_SELECT
    jsr remove_confirm
    bcs @gone
    jmp @loop
@gone:
    dec num_players
    stz r_rsel                  ; back on ADD PLAYER, never on REMOVE
    lda num_players
    bne @still
    ; nobody left: straight to PLAYER 1's name
    jsl fade_out
    lda #$01
    rts
@still:
    jsr draw_roster_list
    stz m_sel
    jsr roster_bar_clear
    stz txt_bg
    jsr draw_roster_menu
    PRINTC 26, TP_GREY, str_wipe30
    PRINTC 26, TP_GREY, str_roster_hint
    jmp @loop
@back:
    A8
    SFX SFX_BACK
    ; leaving loses everyone signed up: ask first (B, the overshoot key, says no)
    jsr roster_confirm
    bcs @leave
    jmp @loop
@leave:
    jsl fade_out
    lda #$FF
    rts

; "LEAVE AND LOSE n PLAYERS?  A YES  B NO" on the action bar.
; Carry set = yes, leave; clear = stay (the bar and hint are redrawn).
roster_confirm:
    jsr roster_bar_clear
    LDPTR0 str_leave
    ldx #(21*32 + 3)
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_print
    lda num_players
    A16
    and #$00FF
    sta tmp1
    A8
    ldx #(21*32 + 18)
    ldy #1
    lda #($20 | (TP_RED << 2))
    jsl txt_num
    LDPTR0 str_leave_pl
    lda num_players
    cmp #2
    bcs @pl
    LDPTR0 str_leave_1
@pl:
    ldx #(21*32 + 19)
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_print
    stz txt_bg
    PRINTC 26, TP_GREY, str_wipe30
    PRINTC 26, TP_YELLOW, str_yes_no
@w:
    jsl wait_frame
    jsl menu_backdrop_tick
    A16
    lda pad_new
    bit #PAD_A
    bne @yes
    bit #(PAD_B | PAD_START)
    bne @no
    A8
    bra @w
@yes:
    A8
    SFX SFX_SELECT
    sec
    rts
@no:
    A8
    SFX SFX_BLIP
    jsr roster_bar_clear
    stz txt_bg
    jsr draw_roster_menu
    PRINTC 26, TP_GREY, str_wipe30
    PRINTC 26, TP_GREY, str_roster_hint
    clc
    rts

; "REMOVE 4 JEN?   NO   YES" on the action bar, cursor on NO. LEFT / RIGHT
; (or UP / DOWN) move it, A picks, B or START is no.
; Carry set = remove the last player; clear = keep (bar and hint redrawn).
remove_confirm:
    stz r_rm                    ; 0 = NO, 1 = YES
    jsr roster_bar_clear
    LDPTR0 str_remove_q
    ldx #(21*32 + 3)
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_print
    lda num_players
    A16
    and #$00FF
    sta tmp1
    A8
    ldx #(21*32 + 10)
    ldy #1
    lda #($20 | (TP_CYAN << 2))
    jsl txt_num
    lda #($20 | (TP_WHITE << 2))
    sta tmp6
    lda num_players
    dec a
    ldx #(21*32 + 12)
    jsl print_player_name
    ; "?" right after the name
    lda num_players
    dec a
    jsl player_offset
    ldy #$0000
@len:
    lda players+PL_NAME,x
    beq @got
    inx
    iny
    cpy #8
    bne @len
@got:
    tya
    clc
    adc #12
    A16
    and #$00FF
    clc
    adc #(21*32)
    tax
    A8
    lda #('?' - 32 + TXT_WIN)
    sta tmp2
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_char
    stz txt_bg
    PRINTC 26, TP_GREY, str_wipe30
    PRINTC 26, TP_GREY, str_remove_hint
    jsr rm_draw
@w:
    jsl wait_frame
    jsl menu_backdrop_tick
    A16
    lda pad_new
    bit #(PAD_LEFT | PAD_RIGHT | PAD_UP | PAD_DOWN)
    bne @flip
    bit #(PAD_B | PAD_START)
    bne @no
    bit #PAD_A
    bne @pick
    A8
    bra @w
@flip:
    A8
    lda r_rm
    eor #$01
    sta r_rm
    SFX SFX_BLIP
    jsr rm_draw
    bra @w
@pick:
    A8
    lda r_rm
    beq @no8
    SFX SFX_BACK
    sec
    rts
@no:
    A8
@no8:
    SFX SFX_BLIP
    jsr roster_bar_clear
    stz txt_bg
    jsr draw_roster_menu
    PRINTC 26, TP_GREY, str_wipe30
    PRINTC 26, TP_GREY, str_roster_hint
    clc
    rts

; NO / YES with the arrow on r_rm
rm_draw:
    lda #TXT_WIN
    sta txt_bg
    ldx #(21*32 + 22)
    lda #(TXT_SPACE + TXT_WIN)
    sta tmp2
    lda r_rm
    bne @a0
    lda #(TXT_ARROW_R + TXT_WIN)
    sta tmp2
@a0:
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_char
    ldx #(21*32 + 26)
    lda #(TXT_SPACE + TXT_WIN)
    sta tmp2
    lda r_rm
    beq @a1
    lda #(TXT_ARROW_R + TXT_WIN)
    sta tmp2
@a1:
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_char
    LDPTR0 str_rm_no
    ldx #(21*32 + 23)
    lda r_rm
    bne @n0
    lda #($20 | (TP_YELLOW << 2))
    bra @n1
@n0:
    lda #($20 | (TP_WHITE << 2))
@n1:
    jsl txt_print
    LDPTR0 str_rm_yes
    ldx #(21*32 + 27)
    lda r_rm
    beq @y0
    lda #($20 | (TP_YELLOW << 2))
    bra @y1
@y0:
    lda #($20 | (TP_WHITE << 2))
@y1:
    jsl txt_print
    stz txt_bg
    rts

; blank the inside of the action bar (row 21); leaves txt_bg = window
roster_bar_clear:
    lda #TXT_WIN
    sta txt_bg
    ldx #(21*32 + 2)
    A16
    lda #$011C                  ; 28 x 1
    sta tmp1
    A8
    lda #(TXT_SPACE + TXT_WIN)
    sta tmp2
    lda #$20
    jsl txt_fill
    rts

; the three roster actions on row 21; ADD greys out at 8 players
draw_roster_menu:
    lda #TXT_WIN
    sta txt_bg
    stz tmp4
@it:
    lda tmp4
    A16
    and #$00FF
    asl a
    tax
    lda f:roster_items,x
    sta ptr0
    lda f:roster_cells,x
    tax
    A8
    lda #^roster_items
    sta ptr0+2
    ; at 8 players ADD PLAYER reads ROSTER FULL
    lda tmp4
    bne @lbl
    lda num_players
    cmp #MAX_PLAYERS
    bcc @lbl
    A16
    lda #.loword(ri0_full)
    sta ptr0
    A8
@lbl:
    ; arrow cell
    dex
    lda #(TXT_SPACE + TXT_WIN)
    sta tmp2
    lda tmp4
    cmp m_sel
    bne @na
    lda #(TXT_ARROW_R + TXT_WIN)
    sta tmp2
@na:
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_char
    inx
    ; colour: a full roster's ADD stays grey even under the cursor
    lda tmp4
    bne @live
    lda num_players
    cmp #MAX_PLAYERS
    bcc @live
    lda #($20 | (TP_GREY << 2))
    bra @pr
@live:
    lda tmp4
    cmp m_sel
    bne @plain
    lda #($20 | (TP_YELLOW << 2))
    bra @pr
@plain:
@white:
    lda #($20 | (TP_WHITE << 2))
@pr:
    jsl txt_print
    inc tmp4
    lda tmp4
    cmp #3
    bne @it
    stz txt_bg
    rts

; A = sponsor, X = cell, tmp6 = attr: the sponsor name, short enough for
; the roster (Sam's full name runs into the frame)
print_sponsor_short:
    cmp #1
    beq @sam
    jsl print_sponsor_name
    rts
@sam:
    LDPTR0 str_sam_short
    lda tmp6
    jsl txt_print
    rts

roster_items:
    .addr ri0, ri1, ri2
roster_cells:
    .word (21*32 + 3), (21*32 + 16), (21*32 + 24)
ri0: .byte "ADD PLAYER", 0
ri0_full: .byte "ROSTER FULL", 0
ri1: .byte "REMOVE", 0
ri2: .byte "START!", 0
str_competitors: .byte "COMPETITORS", 0
str_roster_hint: .byte "A SELECT  START GO  B MENU", 0
str_roster_full: .byte "ROSTER FULL: 8 PLAYERS MAX", 0
str_sam_short:   .byte "SAM THE REC MAN", 0   ; a cell clear of the frame
str_leave:       .byte "LEAVE AND LOSE", 0
str_leave_pl:    .byte " PLAYERS?", 0
str_leave_1:     .byte " PLAYER?", 0
str_yes_no:      .byte "A YES, LEAVE    B NO, STAY", 0
str_wipe30:      .byte "                              ", 0
str_remove_q:    .byte "REMOVE", 0
str_remove_hint: .byte "A PICK     B NO", 0
str_rm_no:       .byte "NO", 0
str_rm_yes:      .byte "YES", 0

; ------------------------------------------------------------------
; name entry: carry set if cancelled
name_entry:
    jsr menu_setup
    jsr q_pad                   ; a tap on ppu_off's frame counts too
    lda r_keep
    bne @kept
    stz r_len
    stz r_cx
    stz r_cy
    ldx #$0000
@clr:
    stz r_name,x
    inx
    cpx #10
    bne @clr
@kept:
    PRINTC 2, TP_YELLOW, str_player
    lda num_players
    inc a
    A16
    and #$00FF
    sta tmp1
    A8
    ldx #(2*32 + 19)
    ldy #1
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_num
    PRINTC 4, TP_WHITE, str_enter
    ldx #(10*32 + 2)
    A16
    lda #$0C1C                  ; 28 x 12
    sta tmp1
    A8
    lda #$20
    jsl txt_box
    jsr draw_grid
    jsr draw_name
    PRINTC 24, TP_GREY, str_name_hint
    PRINTC 26, TP_GREY, str_name_hint2
    stz r_btmr
    ; fade in from inside the loop: the grid takes input from its first
    ; visible frame (pad_new is edge-triggered, so an A still held from the
    ; previous screen types nothing)
    stz inidisp_sh
@loop:
    jsl wait_frame
    jsr q_take                  ; taps from the way in, one per frame
    jsr fade_step
    jsl menu_backdrop_tick
    jsr name_cursor_blink
    lda r_btmr
    beq @bt0
    dec r_btmr
@bt0:
    A16
    lda pad_new
    bit #PAD_LEFT
    bne @left
    bit #PAD_RIGHT
    bne @right
    bit #PAD_UP
    bne @up
    bit #PAD_DOWN
    bne @down
    bit #PAD_A
    bne @press
    bit #PAD_B
    jne @del
    bit #PAD_START
    beq @none
    jmp @finish
@none:
    A8
    bra @loop
@left:
    A8
    lda r_cx
    bne @l1
    jsr row_width
@l1:
    dec a
    sta r_cx
    jmp @moved
@right:
    A8
    lda r_cx
    inc a
    pha
    jsr row_width
    sta tmp0
    pla
    cmp tmp0
    bcc @r1
    lda #$00
@r1:
    sta r_cx
    jmp @moved
@up:
    A8
    lda r_cy
    bne @u1
    lda #4
@u1:
    dec a
    sta r_cy
    jmp @fixcol
@down:
    A8
    lda r_cy
    inc a
    cmp #4
    bcc @d1
    lda #$00
@d1:
    sta r_cy
@fixcol:
    jsr row_width
    sta tmp0
    lda r_cx
    cmp tmp0
    bcc @moved
    lda tmp0
    dec a
    sta r_cx
@moved:
    SFX SFX_BLIP
    jsr draw_grid
    jmp @loop
@press:
    A8
    lda r_cy
    cmp #3
    beq @special
    ; char = grid_chars[cy*13 + cx]
    sta tmp0
    asl a
    asl a
    asl a
    asl a
    sec
    sbc tmp0
    sbc tmp0
    sbc tmp0                    ; cy * 13
    clc
    adc r_cx
    TAXB
    lda f:grid_chars,x
    jsr name_add
    jmp @loop
@special:
    lda r_cx
    beq @space
    cmp #1
    beq @delcell
    bra @finish8
@space:
    lda #' '
    jsr name_add
    jmp @loop
@delcell:
    ; the DEL cell only ever deletes
    lda r_len
    bne @dodel
    jmp @loop
@del:
    A8
    lda r_len
    bne @dodel
    ; B on a blank name backs out, unless it's the tail of a run of deletes
    lda r_btmr
    beq @cancel
    lda #20
    sta r_btmr
    jmp @loop
@cancel:
    stz r_qn
    SFX SFX_BACK
    jsl fade_out
    sec
    rts
@dodel:
    dec r_len
    lda r_len
    TAXB
    stz r_name,x
    lda #20
    sta r_btmr
    SFX SFX_BACK
    jsr draw_name
    jmp @loop
@finish:
    A8
@finish8:
    ; drop trailing spaces; a blank name becomes "PLAYER n"
@trim:
    lda r_len
    beq @blank
    dec a
    TAXB
    lda r_name,x
    cmp #' '
    bne @named
    stz r_name,x
    dec r_len
    bra @trim
@blank:
    ldx #$0000
@def:
    lda f:str_default,x
    sta r_name,x
    inx
    cpx #7
    bne @def
    lda num_players
    clc
    adc #'1'
    sta r_name+7
    stz r_name+8
@named:
    lda num_players
    jsl player_offset
    ldy #$0000
@copy:
    lda r_name,y
    sta players+PL_NAME,x
    inx
    iny
    cpy #9
    bne @copy
    stz r_qn
    SFX SFX_SELECT
    jsl fade_out
    clc
    rts

; reg_fade_out_q: fade_out (17 frames) that keeps every press made on the
; way out, in order, for the name grid: a quick hand that types B, C (RIGHT
; A RIGHT A) before the grid is up gets "BC". Only fresh presses count
; (pad_new is edge-triggered), so the A that picked this screen, still held,
; types nothing.
reg_fade_out_q:
    stz r_qn
    lda #$0F
@l:
    sta inidisp_sh
    pha
    jsl wait_frame
    jsr q_pad
    pla
    dec a
    bpl @l
    lda #$80
    sta inidisp_sh
    jsl wait_frame
    jsr q_pad
    rts

; this frame's presses as one queue entry (0 = none):
; bits 0-3 d-pad, $10 START, $40 B, $80 A
q_entry:
    lda pad_new+1
    and #$1F                    ; START + d-pad
    sta tmp0
    lda pad_new+1
    and #$80                    ; B -> $40
    lsr a
    ora tmp0
    sta tmp0
    lda pad_new
    and #$80                    ; A
    ora tmp0
    rts

; this frame's presses onto the back of the queue (a full queue drops them)
q_pad:
    jsr q_entry
    beq @x
    pha
    lda r_qn
    cmp #R_QMAX
    bcs @full
    TAXB
    pla
    sta r_q,x
    inc r_qn
    rts
@full:
    pla
@x:
    rts

; name grid, each frame. While presses from the way in are still queued,
; this frame's presses join the back of the queue and the oldest entry
; becomes this frame's press, so order is kept: RIGHT A RIGHT A types the
; letters one and two to the right even when they land mid-drain.
q_take:
    lda r_qn
    bne @queued
    rts
@queued:
    jsr q_pad
    ; this frame's press = the oldest entry
    lda r_q
    and #$80
    sta pad_new
    lda r_q
    and #$40
    asl a
    sta tmp0
    lda r_q
    and #$1F
    ora tmp0
    sta pad_new+1
    ldx #$0000
@sh:
    lda r_q+1,x
    sta r_q,x
    inx
    cpx #(R_QMAX - 1)
    bne @sh
    dec r_qn
    rts

; one step of a fade-in run from a screen's own loop
fade_step:
    lda inidisp_sh
    cmp #$0F
    bcs @x
    inc a
    sta inidisp_sh
@x:
    rts

; A = char
name_add:
    pha
    lda r_len
    cmp #8
    bcs @full
    bne @room
    lda 1,s                     ; no leading space
    cmp #' '
    bne @room
@full:
    pla
    SFX SFX_BACK
    rts
@room:
    TAXB
    pla
    sta r_name,x
    inc r_len
    SFX SFX_COIN
    jsr draw_name
    rts

; A = number of cells in the cursor's row
row_width:
    lda r_cy
    cmp #3
    beq @three
    lda #13
    rts
@three:
    lda #3
    rts

draw_name:
    ; 8 cells at row 7, cols 12-19: letters or underscores
    ldx #$0000
@c:
    phx
    txa
    cmp r_len
    bcc @letter
    lda #'_'
    bra @put
@letter:
    lda r_name,x
@put:
    sec
    sbc #32
    sta tmp2
    A16
    lda 1,s
    clc
    adc #(7*32 + 12)
    tax
    A8
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_char
    plx
    inx
    cpx #8
    bne @c
    rts

name_cursor_blink:
    lda r_len
    cmp #8
    bcs @x
    A16
    and #$00FF
    clc
    adc #(7*32 + 12)
    tax
    A8
    lda frame
    and #$10
    beq @under
    lda #(TXT_SOLID1)
    bra @put
@under:
    lda #('_' - 32)
@put:
    sta tmp2
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_char
@x:
    rts

; letter grid inside the window
draw_grid:
    lda #TXT_WIN
    sta txt_bg
    stz tmp6                    ; row
@row:
    lda tmp6
    cmp #3
    beq @specials
    stz tmp6+1                  ; col
@col:
    ; char
    lda tmp6
    sta tmp0
    asl a
    asl a
    asl a
    asl a
    sec
    sbc tmp0
    sbc tmp0
    sbc tmp0
    clc
    adc tmp6+1
    TAXB
    lda f:grid_chars,x
    sec
    sbc #32
    clc
    adc #TXT_WIN
    sta tmp2
    ; cell = (GRID_ROW0 + row*2)*32 + 4 + col*2
    jsr grid_cell
    lda tmp6
    cmp r_cy
    bne @plain
    lda tmp6+1
    cmp r_cx
    bne @plain
    lda #($20 | (TP_YELLOW << 2))
    bra @draw
@plain:
    lda #($20 | (TP_WHITE << 2))
@draw:
    pha
    jsl txt_char
    ; arrow cell to the left
    dex
    lda #(TXT_SPACE + TXT_WIN)
    sta tmp2
    pla
    cmp #($20 | (TP_YELLOW << 2))
    bne @na
    lda #(TXT_ARROW_R + TXT_WIN)
    sta tmp2
    lda #($20 | (TP_YELLOW << 2))
@na:
    jsr cell_char_x
    inc tmp6+1
    lda tmp6+1
    cmp #13
    bne @col
    inc tmp6
    bra @row
@specials:
    ldx #$0000
@sp:
    phx
    A16
    txa
    asl a
    tax
    lda f:special_labels,x
    sta ptr0
    lda f:special_cells,x
    tax
    A8
    lda #^special_labels
    sta ptr0+2
    lda 1,s
    cmp r_cx
    bne @spplain
    lda r_cy
    cmp #3
    bne @spplain
    lda #($20 | (TP_YELLOW << 2))
    bra @sppr
@spplain:
    lda #($20 | (TP_WHITE << 2))
@sppr:
    pha
    phx
    jsl txt_print
    plx
    pla
    ; arrow / blank before the label
    dex
    pha
    lda #(TXT_SPACE + TXT_WIN)
    sta tmp2
    pla
    cmp #($20 | (TP_YELLOW << 2))
    bne @spna
    lda #(TXT_ARROW_R + TXT_WIN)
    sta tmp2
    lda #($20 | (TP_YELLOW << 2))
@spna:
    jsr cell_char_x
    plx
    inx
    cpx #3
    bne @sp
    stz txt_bg
    rts

; X = grid cell index for (tmp6 row, tmp6+1 col)
grid_cell:
    A16
    lda tmp6
    and #$00FF
    asl a
    clc
    adc #GRID_ROW0
    asl a
    asl a
    asl a
    asl a
    asl a
    sta tmp0
    lda tmp6+1
    and #$00FF
    asl a
    clc
    adc #4
    clc
    adc tmp0
    tax
    A8
    rts

; txt_char at X (keeps X)
cell_char_x:
    phx
    jsl txt_char
    plx
    rts

grid_chars: .byte "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-'"
special_labels: .addr sl0, sl1, sl2
special_cells:  .word (19*32 + 6), (19*32 + 15), (19*32 + 23)
sl0: .byte "SPACE", 0
sl1: .byte "DEL", 0
sl2: .byte "END", 0
str_player:     .byte "PLAYER  ", 0
str_enter:      .byte "ENTER YOUR NAME", 0
str_default:    .byte "PLAYER "     ; + number: matches the "PLAYER n" heading
str_name_hint:  .byte "A ADD  B DELETE  START DONE", 0
str_name_hint2: .byte "B ON A BLANK NAME: GO BACK", 0

; ------------------------------------------------------------------
; sponsor select: carry set = back to the name
sponsor_select:
    jsr menu_setup
    lda #$17
    sta tm_sh                   ; badges on
    lda num_players
    jsl player_offset
    lda players+PL_SPONSOR,x
    cmp #NUM_SPONSORS
    bcc @have
    lda #$00
@have:
    sta r_sp
    ; one jersey per sponsor: start on the first one nobody wears
    jsr sp_owner
    cmp #$FF
    beq @free
    stz r_sp
@find:
    lda r_sp
    jsr sp_owner
    cmp #$FF
    beq @free
    inc r_sp
    bra @find
@free:
    jsr set_sponsor
    ; "KENJI, PICK A SPONSOR" centred on row 3 (24 scanlines down, clear
    ; of the overscan), the name in white
    lda num_players
    jsl player_offset
    ldy #$0000
@nlen:
    lda players+PL_NAME,x
    beq @ngot
    inx
    iny
    cpy #8
    bne @nlen
@ngot:
    tya
    sta tmp5                    ; name length
    stz tmp5+1
    lda #SP_HEAD_LEN
    sec
    sbc tmp5
    lsr a
    sta tmp7                    ; first column: (32 - length - 16) / 2
    stz tmp7+1
    lda #($20 | (TP_WHITE << 2))
    sta tmp6
    A16
    lda tmp7
    clc
    adc #(3*32)
    tax
    A8
    lda num_players
    jsl print_player_name
    A16
    lda tmp7
    clc
    adc tmp5
    adc #(3*32)
    tax
    A8
    LDPTR0 str_choose
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_print
    ; the info box, with your athlete standing in its right end
    ldx #(21*32 + 1)
    A16
    lda #$061E
    sta tmp1
    A8
    lda #$20
    jsl txt_box
    ; the athlete's cells: window tiles WITHOUT the priority bit, so he
    ; stands in front of them (BG3 priority tiles cover every sprite)
    ldx #(22*32 + SP_ATH_COL)
    A16
    lda #$0402                  ; 2 x 4
    sta tmp1
    A8
    lda #(TXT_SPACE + TXT_WIN)
    sta tmp2
    lda #$00
    jsl txt_fill
    jsr draw_taken_tags
    jsr draw_sponsor_info
    jsl fade_in
@loop:
    jsl wait_frame
    jsl oam_clear
    jsr draw_sponsor_cursor
    jsr draw_athlete
    A16
    lda pad_new
    bit #PAD_LEFT
    bne @left
    bit #PAD_RIGHT
    bne @right
    bit #PAD_UP
    bne @up
    bit #PAD_DOWN
    bne @down
    bit #(PAD_A | PAD_START)
    bne @choose
    bit #PAD_B
    bne @back
    A8
    bra @loop
@left:
    A8
    lda r_sp
    dec a
    bpl @set
    lda #(NUM_SPONSORS - 1)
    bra @set
@right:
    A8
    lda r_sp
    inc a
    cmp #NUM_SPONSORS
    bcc @set
    lda #$00
    bra @set
@up:
    A8
    lda r_sp
    sec
    sbc #3
    bpl @set
    clc
    adc #NUM_SPONSORS
    bra @set
@down:
    A8
    lda r_sp
    clc
    adc #3
    cmp #NUM_SPONSORS
    bcc @set
    sec
    sbc #NUM_SPONSORS
@set:
    sta r_sp
    SFX SFX_BLIP
    jsr set_sponsor
    jsr draw_sponsor_info
    bra @loop
@choose:
    A8
    lda r_sp
    jsr sp_owner
    cmp #$FF
    beq @untaken
    SFX SFX_BACK
    jmp @loop
@untaken:
    SFX SFX_CHEER
    ldx #20
    jsl wait_frames
    jsl fade_out
    clc
    rts
@back:
    A8
    SFX SFX_BACK
    jsl fade_out
    sec
    rts

set_sponsor:
    lda num_players
    jsl player_offset
    lda r_sp
    sta players+PL_SPONSOR,x
    lda num_players
    ldy #$0000
    jsl player_palette
    rts

draw_sponsor_info:
    lda #TXT_WIN
    sta txt_bg
    ; clear the two lines, short of the athlete's cells
    ldx #(22*32 + 2)
    A16
    lda #($0300 | (SP_ATH_COL - 2))
    sta tmp1
    A8
    lda #(TXT_SPACE + TXT_WIN)
    sta tmp2
    lda #$20
    jsl txt_fill
    lda #($20 | (TP_YELLOW << 2))
    sta tmp6
    lda r_sp
    ldx #(22*32 + 3)
    jsl print_sponsor_name
    lda r_sp
    jsr sp_owner
    cmp #$FF
    bne @taken
    lda r_sp
    A16
    and #$00FF
    asl a
    tax
    lda f:sponsor_tags,x
    sta ptr0
    A8
    lda #^sponsor_tags
    sta ptr0+2
    ldx #(24*32 + 3)
    lda #($20 | (TP_WHITE << 2))
    jsl txt_print
    stz txt_bg
    rts
@taken:
    pha
    LDPTR0 str_taken
    ldx #(24*32 + 3)
    lda #($20 | (TP_RED << 2))
    jsl txt_print
    lda #($20 | (TP_RED << 2))
    sta tmp6
    pla
    ldx #(24*32 + 12)
    jsl print_player_name
    stz txt_bg
    rts

; A = sponsor -> A = the player already wearing it, or $FF
; (only players already signed up count; clobbers X, Y, tmp0)
sp_owner:
    sta tmp0
    ldx #$0000
    ldy #$0000
@p:
    tya
    cmp num_players
    bcs @none
    lda players+PL_SPONSOR,x
    cmp tmp0
    beq @found
    A16
    txa
    clc
    adc #PL_SIZE
    tax
    A8
    iny
    bra @p
@found:
    tya
    rts
@none:
    lda #$FF
    rts

; a name plate over every badge that's already taken
draw_taken_tags:
    lda #TXT_WIN
    sta txt_bg
    stz tmp7
@tag:
    lda tmp7
    cmp num_players
    jcs @done
    jsl player_offset
    lda players+PL_SPONSOR,x
    cmp #NUM_SPONSORS
    jcs @skip
    ; cell = (badge_y/8)*32 + badge_x/8
    TAXB
    lda f:sp_row,x
    pha
    lda f:sp_col,x
    TAXB
    lda f:badge_x,x
    lsr a
    lsr a
    lsr a
    sta tmp5
    stz tmp5+1
    pla
    TAXB
    lda f:badge_y,x
    lsr a
    lsr a
    lsr a
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    clc
    adc tmp5
    tax
    clc
    adc #32
    sta tmp5                    ; the name row
    lda #$0308                  ; 8 x 3: the whole badge
    sta tmp1
    A8
    lda #(TXT_SPACE + TXT_WIN)
    sta tmp2
    lda #$20
    jsl txt_fill
    ; name, centred in the 8 cells
    lda tmp7
    jsl player_offset
    ldy #$0000
@len:
    lda players+PL_NAME,x
    beq @got
    inx
    iny
    cpy #8
    bne @len
@got:
    tya
    eor #$FF
    sec
    adc #8
    lsr a
    A16
    and #$00FF
    clc
    adc tmp5
    tax
    A8
    lda #($20 | (TP_YELLOW << 2))
    sta tmp6
    lda tmp7
    jsl print_player_name
@skip:
    inc tmp7
    jmp @tag
@done:
    stz txt_bg
    rts

; corner brackets around the highlighted badge
draw_sponsor_cursor:
    lda r_sp
    TAXB
    lda f:sp_col,x
    pha
    lda f:sp_row,x
    TAXB
    lda f:badge_y,x
    sta tmp1
    stz tmp1+1
    pla
    TAXB
    lda f:badge_x,x
    sta tmp0
    stz tmp0+1
    ; pulse 0/1 px
    lda frame
    lsr a
    lsr a
    lsr a
    lsr a
    and #$01
    sta tmp2
    stz tmp2+1
    stz spr_size
    A16
    stz spr_tile
    ; top-left
    lda tmp0
    sec
    sbc #4
    sbc tmp2
    sta spr_x
    lda tmp1
    sec
    sbc #4
    sbc tmp2
    sta spr_y
    A8
    lda #$32                    ; palette 1, priority 3
    sta spr_attr
    jsl oam_put
    ; top-right
    A16
    lda tmp0
    clc
    adc #60
    adc tmp2
    sta spr_x
    A8
    lda #$72
    sta spr_attr
    jsl oam_put
    ; bottom-right
    A16
    lda tmp1
    clc
    adc #20
    adc tmp2
    sta spr_y
    A8
    lda #$F2
    sta spr_attr
    jsl oam_put
    ; bottom-left
    A16
    lda tmp0
    sec
    sbc #4
    sbc tmp2
    sta spr_x
    A8
    lda #$B2
    sta spr_attr
    jsl oam_put
    rts

; athlete in the chosen colours, standing in the right end of the info box
; (inside rows 22-25: scanlines 176-207)
draw_athlete:
    A16
    lda #(SP_ATH_COL*8)
    sta spr_x
    lda #175
    sta spr_y
    lda #32
    sta spr_tile
    A8
    lda #$30
    sta spr_attr
    lda #$01
    sta spr_size
    jsl oam_put
    A16
    lda #191
    sta spr_y
    lda #64
    sta spr_tile
    A8
    jsl oam_put
    rts

sp_col:  .byte 0,1,2, 0,1,2, 0,1,2, 0,1,2
sp_row:  .byte 0,0,0, 1,1,1, 2,2,2, 3,3,3
badge_x: .byte 16, 96, 176
badge_y: .byte 40, 72, 104, 136
str_choose: .byte ", PICK A SPONSOR", 0
SP_HEAD_LEN = 32 - 16           ; the row less ", PICK A SPONSOR"
SP_ATH_COL  = 28                ; first of the athlete's two cells in the box
str_taken:  .byte "TAKEN BY", 0

; ------------------------------------------------------------------
; roster_resume: B on the event picker. The competitors screen again with
; everyone still signed up; returns like register_players. (Kept last in
; the file: pt names screens by the nearest exported label before the PC.)
roster_resume:
    jmp reg_flow
