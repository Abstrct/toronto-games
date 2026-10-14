; Event intro card, score card, event standings + medal table, final table,
; the shared "lock input, then PRESS A / choose" wait, and the countdown
.p816
.smart -
.include "globals.inc"
.include "screens.inc"

.import rank_place, g_choice, par_calc, par_g, par_s, par_b, practice_back
.export c_order, c_place, c_champs, c_buf, card_wait, champ_names, why_line
.export records_board, pick_one

CARD_LOCK = 40                  ; frames every card ignores input for
INTRO_LOCK = 105                ; UP NOW card in a multiplayer game (after the fade-in):
                                ; ~2 s from the card showing to PRESS A, time to hand the pad over
STAND_LOCK = 90                 ; a field's standings and the medal table: everyone gets a look

REC_ROW = 16 * NUM_EVENTS        ; records: rank-major, 5 rows of (5 events x 16 bytes)

.segment "BSS"
c_rank:       .res 1            ; score_card: place on the Toronto board, $FF = none
c_brk:        .res 1            ; score_card: 1 = ev_break adds up, show the sum
c_floor:      .res 1            ; break_ok: 1 = the sum is below 0 and the score is 0 (NEVER BELOW 0)
c_forf:       .res 1            ; break_ok: 1 = a failed run forfeits the bonus (grey FORFEIT row)
c_si:         .res 1            ; score_card: ev_stat index of the line being drawn
c_margin:     .res 2            ; score_card: lead over the old record
c_y:          .res 1            ; score_card: row being drawn
c_nst:        .res 1            ; score_card: stat lines shown (card_plan)
c_note:       .res 1            ; score_card: reason lines shown (0-2, c_noteptr)
c_noteptr:    .res 2
c_short:      .res 1            ; score_card: 1 = no room for WE THE NORTH!
c_rr1:        .res 1            ; score_card: rows that flash for a new record (0 = none)
c_rr2:        .res 1
c_n:          .res 1            ; card_plan rows / card_nav option count
c_cell:       .res 2
c_val:        .res 2
c_li:         .res 2
c_fdef:       .res 1            ; final_table: where the cursor starts
c_order:      .res MAX_PLAYERS  ; final_sort: players by medal points, golds, total
c_place:      .res MAX_PLAYERS  ; final_sort: 0-based place, shared by equal keys
c_champs:     .res 1            ; players sharing first place (0 = nobody medalled)
c_tie:        .res 1            ; final_sort: what put first place first (tie_reason)
c_bot:        .res 1            ; draw_table: the box's bottom row
c_next:       .res 1            ; next event in this competition ($FF = none)
c_done:       .res 1            ; events finished / in this competition
c_total:      .res 1
c_mk:         .res 1
c_page:       .res 1            ; records_board page (event)            ; draw_table: jersey marker / palette counter
; card_wait inputs
c_row:        .res 1            ; prompt row
c_opts:       .res 1            ; 0 = single prompt, 1 = RETRY/OTHER/MENU, 2 = REMATCH/1 EVENT/NEW GAME
c_hook:       .res 1            ; per-frame extras: 1 backdrop, 2 champion hop, 4 ticker
c_bg:         .res 1            ; txt_bg for the prompt
c_blink:      .res 1            ; single prompt blinks
c_lock:       .res 1            ; frames of lockout left
c_relc:       .res 1            ; quiet frames still needed before arming
c_relq:       .res 1            ; quiet frames a card needs (card_setup: REL_FRAMES)
c_hint:       .res 1            ; LET GO OF THE BUTTONS is showing (frames, to 255)
c_esc:        .res 1            ; 1 = a tapper may get through once LET GO has been up a while
c_chain:      .res 1            ; the last card was tapped through: the next one needs a real let-go
c_viaesc:     .res 1            ; this card_wait armed through the tapper's way out
c_seen:       .res 1            ; a button went down during this card_wait
c_bok:        .res 1            ; 1 = B leaves (card_wait -> $FF): Practice, the intro card
c_pre:        .res 3            ; grey line on the prompt row while locked (address 0 = none)
c_rattr:      .res 1            ; row_line: attr
c_def:        .res 1            ; c_opts: the choice the cursor starts on
c_prompt:     .res 2            ; single prompt string (this bank)
c_sel:        .res 1
c_len:        .res 2
c_tpos:       .res 2            ; ticker scroll position in c_buf
c_tick:       .res 1            ; frames to the next ticker step
c_ti:         .res 2
c_tn:         .res 1
; countdown
c_cd:         .res 2
c_cw:         .res 1
c_ccol:       .res 1
c_cattr:      .res 1
c_ct:         .res 1
c_cr:         .res 1
c_ck:         .res 1

.segment "HIBSS"                ; bank $7E: long addressing only
; text buffer: doubled line breaks, champions' names, the medal ticker
c_buf:        .res 160
c_bumped:     .res 9            ; score_card: the name that fell off the board

.segment "SCREENS"
.a8
.i16

; helper: ptr0 = entry A of the .addr table at ptr1 (same bank as table)
table_ptr:
    A16
    and #$00FF
    asl a
    tay
    lda [ptr1],y
    sta ptr0
    A8
    lda ptr1+2
    sta ptr0+2
    rts

; X = cell -> print event string table entry (ptr1 table, event_idx), A = attr
print_ev_entry:
    pha
    phx
    lda event_idx
    jsr table_ptr
    plx
    pla
    jsl txt_print
    rts

print_ev_entry_c:
    pha
    phx
    lda event_idx
    jsr table_ptr
    plx
    pla
    jsl txt_print_centre
    rts

; like print_ev_entry, with a blank line between lines (16 px pitch)
print_ev_entry16:
    pha
    phx
    lda event_idx
    jsr table_ptr
    jsr dbl_lines
    plx
    pla
    jsl txt_print
    rts

; copy the string at ptr0 into c_buf with every line break doubled; ptr0 = c_buf
dbl_lines:
    ldy #$0000
    ldx #$0000
@l:
    lda [ptr0],y
    sta f:c_buf,x
    inx
    cmp #$0A
    bne @n
    sta f:c_buf,x
    inx
@n:
    iny
    cmp #$00
    bne @l
    LDPTR0 c_buf
    rts

; ------------------------------------------------------------------
; event_card: the event has loaded its scene (screen may be dark).
; Draws the briefing, fades in, waits for A, clears the text layer.
event_card:
    stz pause_ok
    jsl txt_clear
    ldx #(1*32 + 1)
    A16
    lda #$191E                  ; 30 x 25
    sta tmp1
    A8
    lda #$20
    jsl txt_box
    lda #TXT_WIN
    sta txt_bg
    LDPTR1 ev_names
    ldx #(2*32)
    lda #($20 | (TP_YELLOW << 2))
    jsr print_ev_entry_c
    LDPTR1 ev_places
    ldx #(4*32)
    lda #($20 | (TP_CYAN << 2))
    jsr print_ev_entry_c
    LDPTR1 ev_blurbs
    ldx #(6*32 + 3)
    lda #($20 | (TP_WHITE << 2))
    jsr print_ev_entry16
    LDPTR1 ev_controls
    ldx #(10*32 + 3)
    lda #($20 | (TP_GREEN << 2))
    jsr print_ev_entry16
    ; who is up
    PRINT 3, 16, TP_GREY, str_up
    lda #($20 | (TP_YELLOW << 2))
    sta tmp6
    lda cur_player
    ldx #(16*32 + 10)
    jsl print_player_name
    PRINT 3, 18, TP_GREY, str_for
    lda cur_player
    jsl player_offset
    lda players+PL_SPONSOR,x
    pha
    lda #($20 | (TP_CYAN << 2))
    sta tmp6
    pla
    ldx #(18*32 + 10)
    jsl print_sponsor_name
    ; record
    PRINT 3, 20, TP_GREY, str_record
    jsr record_ptr
    A16
    lda records,x
    sta tmp1
    txa
    clc
    adc #.loword(records + 2)
    sta ptr0
    A8
    stz ptr0+2
    phx
    ldx #(20*32 + 10)
    lda #($20 | (TP_WHITE << 2))
    jsl txt_print
    plx
    ldx #(20*32 + 22)
    ldy #5
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_num
    ; going solo: the medal lines
    lda num_players
    cmp #$01
    bne @nopar
    jsl par_calc
    ldx #(22*32)
    stx tmp5
    jsr par_line
@nopar:
    stz txt_bg
    jsl fade_in
    ; Practice, the first player's card: B goes back to the event list
    LDPTR0 str_ready
    stz c_bok
    lda game_mode
    cmp #GM_PRACTICE
    bne @prompt
    lda cur_player
    ora demo_on                 ; (a demo has no event list to go back to)
    bne @prompt
    inc c_bok
    LDPTR0 str_ready_b
@prompt:
    ldx #((CARD_LOCK - 16) << 8)   ; the fade-in counts towards the lockout
    lda num_players
    cmp #$02
    bcc @solo
    ldx #(INTRO_LOCK << 8)      ; a new player is up: the last one's mashing must not start it
@solo:
    lda #24
    jsr card_setup
    lda #$01
    sta c_blink
    lda #TXT_WIN
    sta c_bg
    lda num_players
    cmp #$02
    bcc @w
    lda #REL_NEXT               ; and the last one's rhythm of taps must stop
    sta c_relq
    stz c_esc                   ; however long they keep tapping
    ; what the wait is for: "HAND THE PAD TO KEV"
    jsr buf_reset
    LDPTR0 str_pass
    jsr buf_str
    lda cur_player
    jsr buf_name
    jsr buf_term
    A16
    lda #.loword(c_buf)
    sta c_pre
    A8
    lda #^c_buf
    sta c_pre+2
@w:
    jsl card_wait
    stz c_bok
    cmp #$FF
    bne @go
    jml practice_back           ; game.s: unwinds the event, back to the list
@go:
    jsl txt_clear
    rtl

; card_setup: ptr0 = single prompt (this bank), A = row, X lo = hook, X hi = lockout
card_setup:
    sta c_row
    A16
    lda ptr0
    sta c_prompt
    txa
    A8
    sta c_hook
    xba
    sta c_lock
    stz c_opts
    stz c_def
    stz c_blink
    stz c_bg
    lda #REL_FRAMES
    sta c_relq
    lda #$01
    sta c_esc
    A16
    stz c_pre
    A8
    rts

; X = byte offset of records[event_idx]
record_ptr:
    lda event_idx
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    tax
    A8
    rts

; par_line: tmp5 = cell at the start of a row inside a window ->
; "SOLO  [gold] 2500  [silver] 1667  [bronze] 833" (par_calc first)
par_line:
    A16
    lda tmp5
    clc
    adc #3
    tax
    A8
    LDPTR0 str_solo
    lda #($20 | (TP_GREY << 2))
    jsl txt_print
    stz tmp6
@k:
    lda tmp6
    TAXB
    lda f:medal_tp,x
    sta tmp7
    lda #(TXT_MEDAL + TXT_WIN)
    sta tmp2
    lda tmp6                    ; column 9 + k*7
    asl a
    asl a
    asl a
    sec
    sbc tmp6
    clc
    adc #9
    A16
    and #$00FF
    clc
    adc tmp5
    tax
    A8
    lda tmp7
    jsl txt_char
    inx
    phx
    lda tmp6
    asl a
    TAYB
    A16
    lda par_g,y
    sta tmp1
    A8
    plx
    ldy #5
    lda #($20 | (TP_WHITE << 2))
    jsl txt_num
    inc tmp6
    lda tmp6
    cmp #3
    bne @k
    rts

str_up:          .byte "UP NOW", 0
str_for:         .byte "FOR", 0
str_record:      .byte "RECORD", 0
str_ready:       .byte "PRESS A WHEN READY", 0
str_ready_b:     .byte "A READY    B OTHER EVENT", 0
str_pass:        .byte "HAND THE PAD TO ", 0
str_solo:        .byte "SOLO", 0

; ------------------------------------------------------------------
; score_card: overlay with the result of the turn (ev_score, ev_fail, ev_stat,
; ev_break). ev_fail: 0 finished, 1 the event's own wipe-out line, 2 out of
; time, 3 gave up (pause menu), 4 the event's second fail line (ev_fails2).
; The event decides ev_fail itself, give-ups included: a CALL IT A DAY that
; lands after the run was already over (won or lost) changes nothing.
; A score that makes the event's top 5 goes on the Toronto board; a new #1
; gets the full moment.
; Every text row sits 16 px apart (rows 3, 5, then CARD_TOP.. in steps of 2,
; PRESS A on 23), whatever the result, a 0 included:
;     WIPED OUT!                  (red: why the run ended; a finish is
;                                  green, card_finish: DELIVERED!)
;     PLAYER 1
;     METRES             812      (the event's picked stats, card_stat_pick,
;     WIPEOUTS             3       card_stat_pick_fail for a failed run)
;     RIDE               220      (ev_break: base, always shown)
;   + TIPS                60      (bonus / penalty rows only when not 0)
;   - TACKLES            450      (the true cost, never clamped)
;   = SCORE                0
;     FORFEIT TIPS+STYLE 260      (grey: card_forfeit, a failed run)
;   SCORES NEVER GO BELOW 0       (grey: the sum is under 0)
;   NO DELIVERY, NO 1000 FEE      (a failed run: card_fail_note)
;     #3 ON THE TORONTO BOARD!    (and who fell off it, or a new record)
; When ev_break doesn't add up to ev_score (break_ok) the sum rows are left
; out and SCORE stands alone under the stats. The board lines need the room
; first: one stat instead of two, then WE THE NORTH! goes.
CARD_TOP  = 7                   ; first content row
CARD_ROWS = 8                   ; content rows 7, 9 .. 21
COL_L = 4                       ; stat labels and the + - = signs
COL_S = 6                       ; sum labels
COL_V = 23                      ; numbers, 5 wide (ends in column 27)
REL_NEXT = 45                   ; quiet frames before a card hands over to the next player

score_card:
    stz pause_ok
    stz ev_giveup
    jsr rec_insert
    jsr break_ok
    lda #$00
    rol a
    sta c_brk                   ; 1 = show the arithmetic
    ; the card hides the event's text edge to edge on its rows, so no HUD
    ; letters peek out beside the box
    ldx #(2*32)
    A16
    lda #$1820                  ; 32 x 24
    sta tmp1
    A8
    stz tmp2
    lda #$00
    jsl txt_fill
    ldx #(2*32 + 1)
    A16
    lda #$181E                  ; 30 x 24
    sta tmp1
    A8
    lda #$20
    jsl txt_box
    lda #TXT_WIN
    sta txt_bg
    lda ev_fail
    beq @finished
    cmp #$02
    beq @timeout
    cmp #$03
    beq @gaveup
    LDPTR1 ev_fails             ; 1: the event's own line
    lda ev_fail
    cmp #$04
    bcc @own
    LDPTR1 ev_fails2            ; 4: its second one
@own:
    ldx #(3*32)
    lda #($20 | (TP_RED << 2))
    jsr print_ev_entry_c
    bra @name
@gaveup:
    PRINTC 3, TP_ORANGE, str_gave_up
    bra @name
@timeout:
    PRINTC 3, TP_ORANGE, str_out_of_time
    bra @name
@finished:
    LDPTR1 card_finish          ; the event's own finish line
    ldx #(3*32)
    lda #($20 | (TP_GREEN << 2))
    jsr print_ev_entry_c
@name:
    lda #($20 | (TP_YELLOW << 2))
    sta tmp6
    lda cur_player
    ldx #(5*32 + COL_L)
    jsl print_player_name
    jsr card_plan               ; -> c_y: the block sits in the middle
    ; the event's picked stats, c_nst of them (a label of 0 = unused)
    stz tmp7
@stat:
    lda tmp7
    cmp c_nst
    bcs @stats_done
    lda event_idx
    asl a
    clc
    adc tmp7
    TAXB
    lda ev_fail
    bne @spf
    lda f:card_stat_pick,x
    bra @sp
@spf:
    lda f:card_stat_pick_fail,x ; a failed run shows what still counted
@sp:
    sta c_si
    lda event_idx
    asl a
    asl a
    clc
    adc c_si
    A16
    and #$00FF
    asl a
    tax
    lda f:card_stat_labels,x
    beq @nostat
    sta ptr0
    A8
    lda #^card_stat_labels
    sta ptr0+2
    lda #COL_L
    jsr cy_cell
    lda #($20 | (TP_WHITE << 2))
    jsl txt_print
    lda c_si
    asl a
    TAYB
    A16
    lda ev_stat,y
    sta tmp1
    A8
    lda #COL_V
    jsr cy_cell
    ldy #5
    lda #($20 | (TP_CYAN << 2))
    jsl txt_num
    jsr next_row
@nostat:
    A8
    inc tmp7
    bra @stat
@stats_done:
    lda c_brk
    beq @plain
    jsr break_lines             ; base, then bonus / penalty unless 0
    lda #('=' - 32 + TXT_WIN)
    sta tmp2
    lda #COL_L
    jsr cy_cell
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_char
    lda #COL_S
    bra @score
@plain:
    lda #COL_L
@score:
    jsr cy_cell
    LDPTR0 str_score
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_print
    A16
    lda ev_score
    sta tmp1
    A8
    lda #COL_V
    jsr cy_cell
    ldy #5
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_num
    jsr next_row
    lda c_brk
    beq @why
    jsr forfeit_line            ; FORFEIT TIPS+STYLE 260 (grey, not in the sum)
    lda c_floor
    beq @why
    lda c_y                     ; base + bonus - penalty < 0: the score stops at 0
    jsr row_cell
    LDPTR0 str_floor
    lda #($20 | (TP_GREY << 2))
    jsl txt_print_centre
    jsr next_row
@why:
    ; a failed run: why it scored what it did (one or two lines)
    lda c_note
    beq @rec
    A16
    lda c_noteptr
    sta ptr0
    A8
    lda #^card_fail_note
    sta ptr0+2
    ldy #$0000
    jsr note_line
    lda c_note
    cmp #$02
    bcc @rec
    jsr note_line
@rec:
    ; the Toronto board
    stz c_rr1
    stz c_rr2
    lda c_rank
    jmi @sfx
    jne @board
    lda c_y
    sta c_rr1
    jsr row_cell
    LDPTR0 str_new_record
    lda #($20 | (TP_PINK << 2))
    jsl txt_print_centre
    jsr next_row
    ; "+214 OVER SUITGUY": the old #1 is now #2
    jsr buf_reset
    lda #'+'
    jsr buf_ch
    A16
    lda c_margin
    sta tmp1
    A8
    jsr buf_num
    LDPTR0 str_over
    jsr buf_str
    jsr record_ptr
    A16
    txa
    clc
    adc #.loword(records + REC_ROW + 2)
    sta ptr0
    A8
    stz ptr0+2
    jsr buf_str
    jsr buf_term
    lda c_y
    jsr row_cell
    LDPTR0 c_buf
    lda #($20 | (TP_CYAN << 2))
    jsl txt_print_centre
    jsr next_row
    lda c_short
    jne @sfx
    lda c_y
    sta c_rr2
    jsr row_cell
    LDPTR0 str_we_north
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_print_centre
    jmp @sfx
@board:
    ; "#3 ON THE TORONTO BOARD!" and whoever fell off it
    jsr buf_reset
    lda #'#'
    jsr buf_ch
    lda c_rank
    inc a
    jsr buf_byte
    LDPTR0 str_on_board
    jsr buf_str
    jsr buf_term
    lda c_y
    jsr row_cell
    LDPTR0 c_buf
    lda #($20 | (TP_GREEN << 2))
    jsl txt_print_centre
    jsr next_row
    lda f:c_bumped
    beq @sfx
    jsr buf_reset
    LDPTR0 str_so_long
    jsr buf_str
    LDPTR0 c_bumped
    jsr buf_str
    lda #'!'
    jsr buf_ch
    jsr buf_term
    lda c_y
    jsr row_cell
    LDPTR0 c_buf
    lda #($20 | (TP_GREY << 2))
    jsl txt_print_centre
@sfx:
    stz txt_bg
    lda c_rank
    beq @cheer
    bpl @bell
    lda ev_fail
    cmp #$03
    beq @groan
    SFX SFX_COIN
    bra @w
@groan:
    SFX SFX_GROAN
    bra @w
@bell:
    SFX SFX_BELL
    bra @w
@cheer:
    SFX SFX_CHEER
@w:
    LDPTR0 str_press_a
    ldx #(CARD_LOCK << 8)
    lda c_rank
    bne @nf
    ldx #((CARD_LOCK << 8) | 8)  ; the record banner flashes
@nf:
    lda #23
    jsr card_setup
    lda #TXT_WIN
    sta c_bg
    ; someone else is up next: a rhythm of taps from this run must stop
    ; before the card goes (the next one asks the same)
    lda cur_player
    inc a
    cmp num_players
    bcs @last
    lda #REL_NEXT
    sta c_relq
@last:
    jsl card_wait
    jsl fade_out
    rtl

; card_plan: how many rows the sum, the note and the board lines take, so
; c_nst (stats shown: 2, or 1 when space is short), c_note / c_noteptr,
; c_short (1 = no room for WE THE NORTH!)
card_plan:
    lda #$01                    ; the SCORE row
    sta c_n
    lda c_brk
    beq @note
    inc c_n                     ; the base
    A16
    lda ev_break+2
    A8
    beq @nb
    inc c_n
@nb:                            ; (a forfeit bonus takes its row below the sum)
    A16
    lda ev_break+4
    A8
    beq @fl
    inc c_n
@fl:
    lda c_floor
    beq @note
    inc c_n                     ; NEVER BELOW 0
@note:
    stz c_note
    lda ev_fail
    jeq @board
    ; nothing earned by an event that pays for moving: say so, in the
    ; event's own words, for the fail codes it names (card_still)
    lda c_brk
    beq @own
    A16
    lda ev_break
    A8
    bne @own
    lda event_idx
    TAXB
    lda ev_fail
    and #$07
    TAYB
    lda f:card_still,x
@bit:
    lsr a
    dey
    bpl @bit
    bcc @own
    lda event_idx
    A16
    and #$00FF
    asl a
    tax
    lda f:card_still_ln,x
    sta c_noteptr
    A8
    bra @lines
@own:
    lda ev_fail
    dec a
    and #$03
    sta c_si
    lda event_idx
    asl a
    asl a
    clc
    adc c_si
    A16
    and #$00FF
    asl a
    tax
    lda f:card_fail_note,x
    sta c_noteptr
    A8
    beq @board
@lines:
    ; one line, or two when it has a line break
    inc c_note
    inc c_n
    A16
    lda c_noteptr
    sta ptr0
    A8
    lda #^card_fail_note
    sta ptr0+2
    ldy #$0000
@nl:
    lda [ptr0],y
    beq @board
    iny
    cmp #$0A
    bne @nl
    inc c_note
    inc c_n
@board:
    lda c_rank
    bmi @fit
    inc c_n                     ; #N ON THE BOARD / NEW TORONTO RECORD!
    lda c_rank
    bne @bump
    inc c_n                     ; + OVER, WE THE NORTH
    inc c_n
    bra @fit
@bump:
    lda f:c_bumped
    beq @fit
    inc c_n                     ; SO LONG
@fit:
    stz c_short
@try:
    lda #CARD_ROWS
    sec
    sbc c_n
    beq @tight
    bmi @tight
    cmp #$03
    bcc @set
    lda #$02
@set:
    sta c_nst
    bra @centre
@tight:
    ; no room for even one stat: WE THE NORTH! gives way, then a reason's
    ; second line
    lda c_rank
    bne @n2
    lda c_short
    bne @n2
    inc c_short
    dec c_n
    bra @try
@n2:
    lda c_note
    cmp #$02
    bcc @one
    dec c_note
    dec c_n
    bra @try
@one:
    lda #$01
    sta c_nst
@centre:
    ; first row: CARD_TOP + half the spare rows (whole 16 px steps)
    lda c_n
    clc
    adc c_nst
    sta c_n
    lda #CARD_ROWS
    sec
    sbc c_n
    and #$FE
    clc
    adc #CARD_TOP
    sta c_y
    rts

; the reason line at ptr0 + Y up to a line break or the end, centred on
; row c_y (orange); -> Y past the break, c_y on the next row
note_line:
    ldx #$0000
@c:
    lda [ptr0],y
    beq @end
    iny
    cmp #$0A
    beq @end
    sta f:c_buf,x
    inx
    bra @c
@end:
    lda #$00
    sta f:c_buf,x
    phy
    lda ptr0+2
    pha
    A16
    lda ptr0
    pha
    A8
    lda c_y
    jsr row_cell
    LDPTR0 c_buf
    lda #($20 | (TP_ORANGE << 2))
    jsl txt_print_centre
    A16
    pla
    sta ptr0
    A8
    pla
    sta ptr0+2
    ply
    jmp next_row

; X = c_y * 32 + A (column); keeps ptr0 and the tmps
cy_cell:
    sta c_cell
    stz c_cell+1
    lda c_y
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    clc
    adc c_cell
    tax
    A8
    rts

next_row:
    inc c_y
    inc c_y
    rts

; Y = length of the string at ptr0
strlen:
    ldy #$0000
@l:
    lda [ptr0],y
    beq @x
    iny
    bra @l
@x:
    rts

; the two stat lines shown on the card: ev_stat indices per event, the first
; one kept when there is room for only one
card_stat_pick:
    .byte 1, 3                  ; bike: TTC TOKENS, STYLE
    .byte 0, 2                  ; bay: TIME LEFT, SPILLS
    .byte 1, 2                  ; park: DOGS DODGED, TACKLES
    .byte 0, 2                  ; cops: SIP 'N' HOPS, HURDLES
    .byte 1, 2                  ; sail: MARKS ROUNDED, BUMPS
    .byte 0, 2                  ; parking: SPOTS PARKED, TICKETS
    .byte 1, 0                  ; subway: STATIONS, GERMS
; the same for a failed run (ev_fail 1-4): only stats that still count
card_stat_pick_fail:
    .byte 0, 2                  ; bike: METRES, WIPEOUTS (tokens and style are forfeit)
    .byte 0, 2                  ; bay: TIME LEFT, SPILLS
    .byte 1, 2                  ; park: DOGS DODGED, TACKLES
    .byte 0, 2                  ; cops: SIP 'N' HOPS, HURDLES
    .byte 1, 2                  ; sail: MARKS ROUNDED, BUMPS
    .byte 0, 2                  ; parking: SPOTS PARKED, TICKETS
    .byte 1, 0                  ; subway: STATIONS, GERMS

; 1 = a failed run forfeits the bonus: the event leaves it in ev_break+2,
; keeps it out of ev_score, and the card shows it as a grey FORFEIT row
card_forfeit: .byte 1, 0, 0, 0, 0, 0, 0    ; bike bay park cops sail parking subway

; carry set = the card can show ev_break's sum. One rule for every event:
; - base + bonus - penalty = ev_score (0 + 0 - 0 = 0 counts: a score of
;   nothing still shows its sum);
; - or the sum is below 0 and ev_score is 0: c_floor = 1, the card shows the
;   true penalty and adds NEVER BELOW 0;
; - a failed run in a card_forfeit event leaves the bonus out of the sum:
;   c_forf = 1, and the bonus shows under the score as a grey FORFEIT row.
break_ok:
    stz c_floor
    stz c_forf
    A16
    lda ev_break+2
    sta c_val
    A8
    beq @sum
    lda ev_fail
    beq @sum
    lda event_idx
    TAXB
    lda f:card_forfeit,x
    beq @sum
    inc c_forf
    A16
    stz c_val
    A8
@sum:
    A16
    lda ev_break
    clc
    adc c_val
    bcs @no
    sec
    sbc ev_break+4
    bcc @under
    cmp ev_score
    bne @no
    A8
    sec
    rts
@under:
    lda ev_score
    bne @no
    A8
    inc c_floor
    sec
    rts
@no:
    A8
    clc
    rts

; under the score: a failed run's forfeit bonus, grey and unsigned, so it
; can't be read as part of the sum ("FORFEIT TIPS+STYLE    260")
forfeit_line:
    lda c_forf
    beq @x
    LDPTR0 str_forfeit
    lda #COL_L
    jsr cy_cell
    lda #($20 | (TP_GREY << 2))
    jsl txt_print
    lda event_idx
    asl a
    clc
    adc event_idx
    inc a                       ; the bonus label
    A16
    and #$00FF
    asl a
    tax
    lda f:card_break_labels,x
    sta ptr0
    A8
    lda #^card_break_labels
    sta ptr0+2
    lda #(COL_L + 8)
    jsr cy_cell
    lda #($20 | (TP_GREY << 2))
    jsl txt_print
    A16
    lda ev_break+2
    sta tmp1
    A8
    lda #COL_V
    jsr cy_cell
    ldy #5
    lda #($20 | (TP_GREY << 2))
    jsl txt_num
    jsr next_row
@x:
    rts

; the sum rows from c_y: base (always), + bonus and - penalty (only when not
; 0), each under the event's label (card_break_labels) with its rate after
; it when the event has one (card_rate / card_rate_fail)
break_lines:
    stz tmp7
@l:
    lda tmp7
    asl a
    TAYB
    A16
    lda ev_break,y
    sta c_val
    A8
    lda tmp7
    beq @show
    A16
    lda c_val
    A8
    jeq @next                   ; nothing added or taken: no row
    lda tmp7
    cmp #$01
    bne @sign
    lda c_forf
    jne @next                   ; a forfeit bonus goes under the score instead
@sign:
    lda tmp7
    dec a
    TAXB
    lda f:brk_op,x
    sta tmp2
    lda f:brk_opcol,x
    pha
    lda #COL_L
    jsr cy_cell
    pla
    jsl txt_char
@show:
    lda event_idx
    asl a
    clc
    adc event_idx
    clc
    adc tmp7
    A16
    and #$00FF
    asl a
    sta c_li
    tax
    lda f:card_break_labels,x
    sta ptr0
    A8
    lda #^card_break_labels
    sta ptr0+2
    lda #COL_S
    jsr cy_cell
    lda #($20 | (TP_WHITE << 2))
    jsl txt_print
    jsr strlen
    ldx c_li
    lda ev_fail
    bne @rf
    A16
    lda f:card_rate,x
    bra @rr
@rf:
    A16
    lda f:card_rate_fail,x
@rr:
    beq @norate
    sta ptr0
    A8
    lda #^card_rate
    sta ptr0+2
    tya
    clc
    adc #(COL_S + 1)
    jsr cy_cell
    lda #($20 | (TP_GREY << 2))
    jsl txt_print
@norate:
    A8
    A16
    lda c_val
    sta tmp1
    A8
    lda tmp7
    TAXB
    lda f:brk_col,x
    pha
    lda #COL_V
    jsr cy_cell
    pla
    ldy #5
    jsl txt_num
    jsr next_row
@next:
    inc tmp7
    lda tmp7
    cmp #3
    jne @l
    rts

brk_col:   .byte ($20 | (TP_WHITE << 2)), ($20 | (TP_GREEN << 2)), ($20 | (TP_RED << 2))
brk_op:    .byte '+' - 32 + TXT_WIN, '-' - 32 + TXT_WIN
brk_opcol: .byte ($20 | (TP_GREEN << 2)), ($20 | (TP_RED << 2))

str_floor:       .byte "SCORES NEVER GO BELOW 0", 0
str_forfeit:     .byte "FORFEIT", 0
str_out_of_time: .byte "OUT OF TIME!", 0
str_gave_up:     .byte "CALLED IT A DAY", 0
str_score:       .byte "SCORE", 0
str_new_record:  .byte "NEW TORONTO RECORD!", 0
str_over:        .byte " OVER ", 0
str_we_north:    .byte "WE THE NORTH!", 0
str_on_board:    .byte " ON THE TORONTO BOARD!", 0
str_so_long:     .byte "SO LONG, ", 0
str_press_a:     .byte "PRESS A", 0

; rec_insert: ev_score onto event_idx's top-5 board (never from a demo or
; for 0; a tie stays under the score it ties). -> c_rank 0-4 or $FF,
; c_margin = lead over the old #1, c_bumped = the name that fell off
rec_insert:
    lda #$FF
    sta c_rank
    lda #$00
    sta f:c_bumped
    lda demo_on
    bne @x
    A16
    lda ev_score
    A8
    beq @x
    jsr record_ptr
    stz tmp7
@find:
    A16
    lda ev_score
    cmp records,x
    A8
    beq @next
    bcs @found
@next:
    A16
    txa
    clc
    adc #REC_ROW
    tax
    A8
    inc tmp7
    lda tmp7
    cmp #5
    bne @find
@x:
    rts
@found:
    stx tmp4                    ; the new entry's slot
    A16
    lda ev_score
    sec
    sbc records,x
    sta c_margin
    A8
    ; the old #5 falls off the board
    jsr record_ptr
    A16
    txa
    clc
    adc #(REC_ROW * 4)
    sta tmp3
    tax
    A8
    ldy #$0000
@bn:
    lda records+2,x
    tyx
    sta f:c_bumped,x
    ldx tmp3
    inx
    stx tmp3
    iny
    cpy #9
    bne @bn
    lda #$00
    sta f:c_bumped+8
    ; shift ranks down from #5 to the new slot
    jsr record_ptr
    A16
    txa
    clc
    adc #(REC_ROW * 4)
    tax
    A8
@sh:
    cpx tmp4
    beq @put
    ldy #16
@c:
    lda records-REC_ROW,x
    sta records,x
    inx
    dey
    bne @c
    A16
    txa
    sec
    sbc #(16 + REC_ROW)
    tax
    A8
    bra @sh
@put:
    A16
    lda ev_score
    sta records,x
    A8
    lda cur_player
    jsl player_offset
    txy
    ldx tmp4
    lda #9
    sta tmp0
@cp:
    lda players+PL_NAME,y
    sta records+2,x
    inx
    iny
    dec tmp0
    bne @cp
    lda #5
    sta tmp0
@z:
    stz records+2,x
    inx
    dec tmp0
    bne @z
    lda tmp7
    sta c_rank
    jsl records_save
    rts

; ------------------------------------------------------------------
; event_standings: everyone's score on this event, medals (shared on equal
; scores, none for 0), then RETRY / MENU in Practice, or the running medal
; table when more events follow in a multiplayer competition.
event_standings:
    jsr menu_setup
    LDPTR1 ev_names
    ldx #(1*32)
    lda #($20 | (TP_YELLOW << 2))
    jsr print_ev_entry_c
    PRINTC 3, TP_CYAN, str_results
    ; the box: a field's fits its players, a solo one has the medal lines
    lda num_players
    cmp #$02
    bcc @tall
    asl a
    clc
    adc #3
    bra @bh
@tall:
    lda game_mode
    cmp #GM_PRACTICE
    lda #15                     ; rows 5-19: the lines end on 17
    bcs @bh
    lda #17                     ; and the medals so far on 19
@bh:
    sta tmp1+1
    sta c_bot
    lda #30
    sta tmp1
    ldx #(5*32 + 1)
    lda #$20
    jsl txt_box
    lda #TXT_WIN
    sta txt_bg
    stz tmp7                    ; rank
@row:
    lda tmp7
    cmp num_players
    bcc @more
    jmp @shown
@more:
    ; row cell = (7 + rank*2) * 32
    lda tmp7
    asl a
    clc
    adc #7
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    sta tmp5
    A8
    ; the player and their score on this event
    lda tmp7
    TAXB
    lda rank_order,x
    jsl player_offset
    stx tmp4
    A16
    lda event_idx
    and #$00FF
    asl a
    clc
    adc tmp4
    tax
    lda players+PL_SCORES,x
    sta tmp3
    A8
    ; medal, place (equal scores share it), or a dash for nothing scored
    lda tmp7
    TAXB
    lda rank_medal,x
    cmp #3
    bcc @medal
    A16
    lda tmp3
    A8
    beq @dash
    lda num_players
    cmp #$01
    beq @dash                   ; solo and under par: no place to speak of
    lda rank_place,x
    inc a
    A16
    and #$00FF
    sta tmp1
    lda tmp5
    clc
    adc #4
    tax
    A8
    ldy #1
    lda #($20 | (TP_GREY << 2))
    jsl txt_num
    bra @name
@dash:
    LDPTR0 str_dash
    A16
    lda tmp5
    clc
    adc #4
    tax
    A8
    lda #($20 | (TP_GREY << 2))
    jsl txt_print
    bra @name
@medal:
    jsr standings_medal
@name:
    lda tmp7
    TAXB
    lda rank_order,x
    pha
    A16
    lda tmp5
    clc
    adc #7
    tax
    A8
    lda #($20 | (TP_WHITE << 2))
    sta tmp6
    pla
    jsl print_player_name
    A16
    lda tmp3
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
    jmp @row
@shown:
    lda num_players
    cmp #$01
    beq @solo
    ; a field: the event's Toronto Record under the box, if there's room
    stz txt_bg
    cmp #7
    bcs @notsolo
    lda c_bot
    clc
    adc #6                      ; box rows 5..4+c_bot, a row clear of it
    jsr rec_line
    bra @notsolo
@solo:
    jsr solo_lines
@notsolo:
    stz txt_bg
    jsl fade_in
    lda #SONG_STANDINGS
    jsl music_keep
    LDPTR0 str_press_a
    lda #25
    ldx #((CARD_LOCK << 8) | 1)
    jsr card_setup
    jsr field_wait              ; a field: everyone gets a look
    lda game_mode
    cmp #GM_PRACTICE
    bne @plain
    lda #$01
    sta c_opts                  ; RETRY / OTHER EVENT / MENU
    jsl card_wait
    sta g_choice
    bra @out
@plain:
    jsl card_wait
@out:
    jsl fade_out
    jsr medal_table
    jsl music_stop
    rtl

; after card_setup: in a field of two or more, the standings and the medal
; table stay up STAND_LOCK frames and want the long let-go of a hand-over
field_wait:
    lda num_players
    cmp #$02
    bcc @x
    lda #STAND_LOCK
    sta c_lock
    lda #REL_NEXT
    sta c_relq
@x:
    rts

; medal icon at row cell tmp5 + 4, colour by rank_medal (A = 0..2)
standings_medal:
    TAXB
    lda f:medal_tp,x
    pha
    lda #(TXT_MEDAL + TXT_WIN)
    sta tmp2
    A16
    lda tmp5
    clc
    adc #4
    tax
    A8
    pla
    jsl txt_char
    rts

medal_tp:
    .byte ($20 | (TP_YELLOW << 2)), ($20 | (TP_GREY << 2)), ($20 | (TP_ORANGE << 2))

str_results:    .byte "RESULTS", 0
str_dash:       .byte "-", 0
str_solo_rule:  .byte "MEDALS VS THE RECORD", 0

; going solo, inside the box under the score (row 7): how far to the next
; medal, the medal lines against the Toronto Record, the record itself, the
; board, and the medals won so far in a competition
solo_lines:
    jsr gap_line
    PRINTC 11, TP_CYAN, str_solo_rule
    ldx #(13*32)
    stx tmp5
    jsr par_line
    lda #15
    jsr rec_line
    jsr board_line
    lda game_mode
    cmp #GM_PRACTICE
    beq @x
    jsr haul_line
@x:
    rts

; row 9: "214 MORE FOR SILVER", or gold
gap_line:
    lda event_idx
    A16
    and #$00FF
    asl a
    tax
    lda players+PL_SCORES,x     ; player 0
    sta c_val
    A8
    lda rank_medal
    bne @short
    LDPTR0 str_gap_gold
    bra @say
@short:
    ; the next medal up: none -> bronze, bronze -> silver, silver -> gold
    cmp #3
    bcc @m
    lda #3
@m:
    dec a
    asl a
    TAXB
    A16
    lda f:gap_par,x
    tay
    lda a:$0000,y               ; par_g / par_s / par_b
    sec
    sbc c_val
    sta tmp1
    A8
    jsr buf_reset
    jsr buf_num
    LDPTR0 str_gap_more
    jsr buf_str
    lda rank_medal
    cmp #3
    bcc @n
    lda #3
@n:
    dec a
    asl a
    TAXB
    A16
    lda f:gap_name,x
    sta ptr0
    A8
    lda #^gap_name
    sta ptr0+2
    jsr buf_str
    jsr buf_term
    LDPTR0 c_buf
@say:
    ldx #(9*32)
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_print_centre
    rts

gap_par:  .addr par_g, par_s, par_b
gap_name: .addr str_m_gold, str_m_silver, str_m_bronze
str_gap_gold: .byte "GOLD! THAT'S RECORD PACE", 0
str_gap_more: .byte " MORE FOR ", 0
str_m_gold:   .byte "GOLD", 0
str_m_silver: .byte "SILVER", 0
str_m_bronze: .byte "BRONZE", 0

; A = row: "RECORD: SUITGUY 3000" centred (event_idx's #1)
rec_line:
    pha
    jsr buf_reset
    LDPTR0 str_rec_colon
    jsr buf_str
    jsr record_ptr
    A16
    txa
    clc
    adc #.loword(records + 2)
    sta ptr0
    A8
    stz ptr0+2
    jsr buf_str
    lda #' '
    jsr buf_ch
    jsr record_ptr
    A16
    lda records,x
    sta tmp1
    A8
    jsr buf_num
    jsr buf_term
    pla
    jsr row_cell
    LDPTR0 c_buf
    lda #($20 | (TP_WHITE << 2))
    jsl txt_print_centre
    rts

; row 17: where this score sits on the Toronto board (c_rank from the
; score card), or what it takes to get on it
board_line:
    lda c_rank
    bmi @off
    bne @on
    PRINTC 17, TP_PINK, str_new_record
    rts
@on:
    jsr buf_reset
    lda #'#'
    jsr buf_ch
    lda c_rank
    inc a
    jsr buf_byte
    LDPTR0 str_on_board
    jsr buf_str
    jsr buf_term
    LDPTR0 c_buf
    ldx #(17*32)
    lda #($20 | (TP_GREEN << 2))
    jsl txt_print_centre
    rts
@off:
    jsr buf_reset
    LDPTR0 str_top5
    jsr buf_str
    jsr record_ptr
    A16
    lda records + REC_ROW*4,x   ; #5
    sta tmp1
    A8
    jsr buf_num
    jsr buf_term
    LDPTR0 c_buf
    ldx #(17*32)
    lda #($20 | (TP_GREY << 2))
    jsl txt_print_centre
    rts

; row 19: "MEDALS SO FAR  [g] 1  [s] 0  [b] 2"
haul_line:
    PRINT 4, 19, TP_GREY, str_so_far
    stz tmp6
@k:
    lda tmp6
    TAXB
    lda f:medal_tp,x
    sta tmp7
    lda #(TXT_MEDAL + TXT_WIN)
    sta tmp2
    lda tmp6                    ; column 18 + k*4
    asl a
    asl a
    clc
    adc #(19*32 + 18) & $FF
    A16
    and #$00FF
    clc
    adc #(19*32) & $FF00
    tax
    A8
    lda tmp7
    jsl txt_char
    inx
    phx
    lda tmp6
    TAXB
    lda players+PL_GOLD,x       ; player 0
    A16
    and #$00FF
    sta tmp1
    A8
    plx
    ldy #1
    lda #($20 | (TP_WHITE << 2))
    jsl txt_num
    inc tmp6
    lda tmp6
    cmp #3
    bne @k
    rts

str_rec_colon: .byte "RECORD: ", 0
str_top5:      .byte "THE BOARD STARTS AT ", 0
str_so_far:    .byte "MEDALS SO FAR", 0

; ------------------------------------------------------------------
; medal_table: between events of a multiplayer competition, the running
; medal table under a CN Tower LED ticker. Skipped after the last event
; (the ceremony follows), in Practice and for a single player.
medal_table:
    lda game_mode
    cmp #GM_PRACTICE
    bne @mode_ok
    rts
@mode_ok:
    lda num_players
    cmp #$02
    bcs @players_ok
    rts
@players_ok:
    ; next event and how many are done
    lda #$FF
    sta c_next
    stz c_done
    stz c_total
    ldx #$0000
@count:
    lda event_on,x
    beq @cn
    inc c_total
    txa
    cmp event_idx
    beq @done
    bcs @later
@done:
    inc c_done
    bra @cn
@later:
    lda c_next
    bpl @cn
    txa
    sta c_next
@cn:
    inx
    cpx #NUM_EVENTS
    bne @count
    lda c_next
    bpl @show
    rts
@show:
    jsl final_sort
    jsr menu_setup
    PRINTC 1, TP_YELLOW, str_medal_table
    jsr draw_table
    ; the ticker: "EVENT 2 OF 4 DONE +++ KEV LEADS ON 8 PTS +++ NEXT UP: ..."
    jsr buf_reset
    LDPTR0 str_tk_after
    jsr buf_str
    lda c_done
    jsr buf_byte
    LDPTR0 str_tk_of
    jsr buf_str
    lda c_total
    jsr buf_byte
    LDPTR0 str_tk_events
    jsr buf_str
    lda c_champs
    bne @lead
    LDPTR0 str_tk_none
    jsr buf_str
    bra @nextup
@lead:
    cmp #$01
    beq @one
    LDPTR0 str_tk_tied
    jsr buf_str
    bra @pts
@one:
    lda c_order
    jsr buf_name
    lda c_tie
    beq @clear
    LDPTR0 str_tk_leads_on      ; level on points: say what splits them
    jsr buf_str
    jsr why_append
    LDPTR0 str_tk_sep
    jsr buf_str
    bra @nextup
@clear:
    LDPTR0 str_tk_leads
    jsr buf_str
@pts:
    lda c_order
    jsl player_offset
    A16
    lda players+PL_POINTS,x
    sta tmp1
    A8
    jsr buf_num
    LDPTR0 str_tk_pts
    jsr buf_str
@nextup:
    LDPTR0 str_tk_next
    jsr buf_str
    LDPTR1 ev_names
    lda c_next
    jsr table_ptr
    jsr buf_str
    LDPTR0 str_tk_sep
    jsr buf_str
    ; anyone who scored nothing on this one gets a line (the first of them)
    stz c_mk
@zero:
    lda c_mk
    cmp num_players
    bcs @tkdone
    jsl player_offset
    stx tmp4
    A16
    lda event_idx
    and #$00FF
    asl a
    clc
    adc tmp4
    tax
    lda players+PL_SCORES,x
    A8
    beq @zfound
    inc c_mk
    bra @zero
@zfound:
    lda c_mk
    jsr buf_name
    lda event_idx
    cmp #EV_SAIL
    bne @leafs
    LDPTR0 str_tk_onplace
    bra @zline
@leafs:
    LDPTR0 str_tk_leafs
@zline:
    jsr buf_str
@tkdone:
    ldx #(22*32 + 1)
    A16
    lda #$031E                  ; 30 x 3
    sta tmp1
    stz c_tpos
    A8
    lda #$20
    jsl txt_box
    jsr ticker_draw
    jsl fade_in
    LDPTR0 str_press_a
    lda #26
    ldx #((CARD_LOCK << 8) | 5)
    jsr card_setup
    jsr field_wait
    jsl card_wait
    jsl fade_out
    rts

str_medal_table: .byte "MEDAL TABLE", 0
str_tk_after:    .byte "EVENT ", 0
str_tk_of:       .byte " OF ", 0
str_tk_events:   .byte " DONE +++ ", 0
str_tk_none:     .byte "NO MEDALS YET. ANYONE? +++ ", 0
str_tk_tied:     .byte "TIED AT THE TOP ON ", 0
str_tk_leads:    .byte " LEADS ON ", 0
str_tk_leads_on: .byte " LEADS, ", 0
str_tk_pts:      .byte " PTS +++ ", 0
str_tk_next:     .byte "NEXT UP: ", 0
str_tk_sep:      .byte " +++ ", 0
str_tk_leafs:    .byte ": 0 PTS. A REAL LEAFS PLAYOFF RUN +++ ", 0
str_tk_onplace:  .byte " STILL AT ONTARIO PLACE +++ ", 0

; ------------------------------------------------------------------
; draw_table: rows 3..21, the medal table in final_sort order
;   place [jersey] name    G S B  PTS SCORE
; The jersey is a sprite in the player's sponsor colours (sprite palette =
; row), so two PLAYER 1s can still be told apart.
MARK_TILE = 240                 ; spare OBJ tile on the menu screens
draw_table:
    VLOAD (VRAM_OBJTILES + MARK_TILE*16), mark_tile, 32
    stz c_mk
@pal:
    lda c_mk
    cmp num_players
    bcs @paldone
    TAXB
    lda c_order,x
    ldy c_mk
    jsl player_palette
    inc c_mk
    bra @pal
@paldone:
    jsl oam_clear
    jsr draw_markers
    ; the box fits the field: 30 wide, 3 + 2 per player high (rows 3..c_bot)
    lda num_players
    asl a
    clc
    adc #3
    sta tmp1+1
    clc
    adc #2
    sta c_bot
    lda #30
    sta tmp1
    ldx #(3*32 + 1)
    lda #$20
    jsl txt_box
    lda #TXT_WIN
    sta txt_bg
    ; header: medal icons, PTS, SCORE
    lda #(TXT_MEDAL + TXT_WIN)
    sta tmp2
    ldx #(4*32 + 15)
    lda f:medal_tp
    jsl txt_char
    ldx #(4*32 + 17)
    lda f:medal_tp+1
    jsl txt_char
    ldx #(4*32 + 19)
    lda f:medal_tp+2
    jsl txt_char
    PRINT 21, 4, TP_GREY, str_cols
    stz tmp7
@row:
    lda tmp7
    cmp num_players
    bcc @r
    jmp @listed
@r:
    lda tmp7
    asl a
    clc
    adc #6
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    sta tmp5
    A8
    ; place (equal keys share it)
    lda tmp7
    TAXB
    lda c_place,x
    inc a
    A16
    and #$00FF
    sta tmp1
    lda tmp5
    clc
    adc #2
    tax
    A8
    ldy #1
    lda #($20 | (TP_GREY << 2))
    jsl txt_num
    ; a see-through cell in the window for the jersey sprite (BG3 sits on top)
    stz tmp2
    A16
    lda tmp5
    clc
    adc #4
    tax
    A8
    lda #$20
    jsl txt_char
    ; name: champions in yellow
    lda tmp7
    TAXB
    lda c_order,x
    sta tmp4
    lda #($20 | (TP_WHITE << 2))
    sta tmp6
    lda c_champs
    beq @nc
    lda c_place,x
    bne @nc
    lda #($20 | (TP_YELLOW << 2))
    sta tmp6
@nc:
    A16
    lda tmp5
    clc
    adc #6                      ; a cell clear of the jersey
    tax
    A8
    lda tmp4
    jsl print_player_name
    ; gold silver bronze (columns 15, 17, 19), each in its medal's colour,
    ; a cell clear of the longest name
    lda tmp4
    jsl player_offset
    stx tmp4
    ldy #$0000
@g:
    phy
    tyx
    lda f:medal_tp,x
    sta tmp6
    A16
    tya
    clc
    adc tmp4
    tax
    lda players+PL_GOLD,x
    and #$00FF
    sta tmp1
    tya
    asl a
    clc
    adc tmp5
    adc #15
    tax
    A8
    lda tmp6
    ldy #1
    jsl txt_num
    ply
    iny
    cpy #3
    bne @g
    ldx tmp4
    A16
    lda players+PL_POINTS,x
    sta tmp1
    lda tmp5
    clc
    adc #21
    tax
    A8
    ldy #3
    lda #($20 | (TP_CYAN << 2))
    jsl txt_num
    ldx tmp4
    A16
    lda players+PL_TOTAL,x
    sta tmp1
    lda tmp5
    clc
    adc #25
    tax
    A8
    ldy #5
    lda #($20 | (TP_WHITE << 2))
    jsl txt_num
    inc tmp7
    jmp @row
@listed:
    stz txt_bg
    rts

; the jersey markers (sprites), one per table row
draw_markers:
    stz c_mk
@m:
    lda c_mk
    cmp num_players
    bcs @x
    asl a
    clc
    adc #6
    asl a
    asl a
    asl a
    dec a
    A16
    and #$00FF
    sta spr_y
    lda #32
    sta spr_x
    lda #MARK_TILE
    sta spr_tile
    A8
    lda c_mk
    asl a
    ora #$30
    sta spr_attr
    stz spr_size
    jsl oam_put
    inc c_mk
    bra @m
@x:
    rts

str_cols: .byte "PTS SCORE", 0

; 8x8 jersey, 4bpp: 1 outline, 5 jersey, 6 shade, 7 trim
mark_tile:
    .byte $66, $00, $FF, $00, $FF, $18, $7E, $00, $7E, $18, $7E, $00, $42, $3C, $3C, $00
    .byte $00, $00, $66, $00, $7E, $00, $3C, $00, $3C, $00, $3C, $00, $3C, $00, $00, $00

; ------------------------------------------------------------------
; final_sort: c_order = players by medal points, then golds, silvers,
; bronzes (cmp_keys); c_place = their places (equal on all four = shared
; place); c_champs = how many share first (0 if nobody won a medal);
; c_tie = what split the top two (tie_reason)
final_sort:
    ldx #$0000
@init:
    txa
    sta c_order,x
    inx
    cpx #MAX_PLAYERS
    bne @init
    stz tmp7                    ; i
@outer:
    lda tmp7
    sta tmp6                    ; best
    inc a
    sta tmp6+1                  ; j
@inner:
    lda tmp6+1
    cmp num_players
    bcs @take
    TAXB
    lda c_order,x
    jsl player_offset
    stx tmp4
    lda tmp6
    TAXB
    lda c_order,x
    jsl player_offset
    txy
    ldx tmp4
    jsr cmp_keys                ; j beats best?
    bcc @nj
    beq @nj
    lda tmp6+1
    sta tmp6
@nj:
    inc tmp6+1
    bra @inner
@take:
    ; move best to slot i, shifting the others down (equal keys keep player order)
    lda tmp6
    TAXB
    lda c_order,x
    sta tmp5
@sh:
    txa
    cmp tmp7
    beq @put
    lda c_order-1,x
    sta c_order,x
    dex
    bra @sh
@put:
    lda tmp5
    sta c_order,x
    inc tmp7
    lda tmp7
    cmp num_players
    bcc @outer
    ; places
    stz c_place
    ldx #$0001
@pl:
    txa
    cmp num_players
    bcs @champs
    stx tmp4
    lda c_order,x
    jsl player_offset
    stx tmp3
    ldx tmp4
    lda c_order-1,x
    jsl player_offset
    txy
    ldx tmp3
    jsr cmp_keys
    php
    ldx tmp4
    plp
    bne @new
    lda c_place-1,x
    bra @st
@new:
    txa
@st:
    sta c_place,x
    inx
    bra @pl
@champs:
    stz c_champs
    lda c_order
    jsl player_offset
    A16
    lda players+PL_POINTS,x
    A8
    beq @x
    ldx #$0000
@ch:
    txa
    cmp num_players
    bcs @x
    lda c_place,x
    bne @x
    inc c_champs
    inx
    bra @ch
@x:
    jsr tie_reason
    rtl

; X, Y = player offsets -> flags of "X's key vs Y's key" (C = X >= Y, Z = equal)
; Key: medal points, then golds, silvers, bronzes. Never raw scores: every
; event scores on its own scale, so a sum of them would let the widest one
; decide a tied competition.
cmp_keys:
    A16
    lda players+PL_POINTS,x
    cmp players+PL_POINTS,y
    A8
    bne @d
    lda players+PL_GOLD,x
    cmp players+PL_GOLD,y
    bne @d
    lda players+PL_SILVER,x
    cmp players+PL_SILVER,y
    bne @d
    lda players+PL_BRONZE,x
    cmp players+PL_BRONZE,y
@d:
    rts

; c_tie: why first place is first, once someone has a medal and there are
; two or more players: 0 clear on points, 1 more golds, 2 more silvers,
; 3 more bronzes, 4 level on everything (a shared title)
tie_reason:
    stz c_tie
    lda c_champs
    beq @x
    lda num_players
    cmp #$02
    bcc @x
    lda c_order+1
    jsl player_offset
    txy
    lda c_order
    jsl player_offset
    A16
    lda players+PL_POINTS,x
    cmp players+PL_POINTS,y
    A8
    bne @x
    lda players+PL_GOLD,x
    cmp players+PL_GOLD,y
    bne @g
    lda players+PL_SILVER,x
    cmp players+PL_SILVER,y
    bne @s
    lda players+PL_BRONZE,x
    cmp players+PL_BRONZE,y
    bne @b
    lda #$04
    bra @set
@g:
    lda #$01
    bra @set
@s:
    lda #$02
    bra @set
@b:
    lda #$03
@set:
    sta c_tie
@x:
    rts

; why_line (jsl): A = 1 to explain a clear win too ("13 PTS TO 8"), 0 for
; ties only ("TIED ON 13 PTS: MORE GOLD", "TIED ON 13 PTS AND MEDALS")
; -> carry set and ptr0 = the line (c_buf), or carry clear for none
why_line:
    sta tmp6
    lda c_champs
    beq @none
    lda num_players
    cmp #$02
    bcc @none
    lda c_tie
    bne @say
    lda tmp6
    beq @none
@say:
    jsr buf_reset
    jsr why_append
    jsr buf_term
    LDPTR0 c_buf
    sec
    rtl
@none:
    clc
    rtl

; append the reason for first place (c_tie) to c_buf
why_append:
    lda c_tie
    beq @clear
    LDPTR0 str_why_tied
    jsr buf_str
    jsr lead_pts
    jsr buf_num
    lda c_tie
    dec a
    asl a
    TAXB
    A16
    lda f:why_end,x
    sta ptr0
    A8
    lda #^why_end
    sta ptr0+2
    jmp buf_str
@clear:
    jsr lead_pts
    jsr buf_num
    LDPTR0 str_why_to
    jsr buf_str
    lda c_order+1
    jsl player_offset
    A16
    lda players+PL_POINTS,x
    sta tmp1
    A8
    jmp buf_num

; tmp1 = first place's medal points
lead_pts:
    lda c_order
    jsl player_offset
    A16
    lda players+PL_POINTS,x
    sta tmp1
    A8
    rts

str_why_tied: .byte "TIED ON ", 0
str_why_to:   .byte " PTS TO ", 0
why_end:      .addr str_why_g, str_why_s, str_why_b, str_why_all
str_why_g:    .byte " PTS: MORE GOLD", 0
str_why_s:    .byte " PTS: MORE SILVER", 0
str_why_b:    .byte " PTS: MORE BRONZE", 0
str_why_all:  .byte " PTS AND MEDALS", 0

; A = row -> X = row * 32 (keeps ptr0)
row_cell:
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    tax
    A8
    rts

; final_table: the overall standings, then REMATCH / 1 EVENT / TITLE.
; A = where the cursor starts (0 REMATCH after the podium, 1 back from
; 1 EVENT) -> A = 0 / 1 / 2. TITLE throws the roster away, so it asks first
; (cursor on NO); A wants a real let-go first, so a player still tapping A
; through the podium neither starts a whole new set nor loses the crew.
final_table:
    sta c_fdef
    jsr menu_setup
    PRINTC 1, TP_YELLOW, str_final
    jsr draw_table
    jsr final_lines
    lda c_order
    ldy #$0000
    jsl player_palette
    lda #25
    ldx #((CARD_LOCK << 8) | 1)
    jsr card_setup
    lda c_champs
    cmp #$01
    bne @nohop
    lda #$03                    ; backdrop + the champion hops
    sta c_hook
@nohop:
    lda #$02
    sta c_opts                  ; REMATCH / 1 EVENT / TITLE
    lda c_fdef
    sta c_def
    ; the cursor starts on REMATCH: a tap carried through the podium must
    ; stop (the long let-go, no tapping through) before A starts a new set
    lda #REL_NEXT
    sta c_relq
    stz c_esc
    jsr card_fade_in            ; the cursor moves during the fade
    lda #SONG_STANDINGS
    jsl music_keep
@ask:
    jsl card_wait
    cmp #$02
    bne @go
    jsr title_confirm
    bcs @title
    ; NO: back to the choices, the cursor still on TITLE
    lda #$02
    sta c_opts
    sta c_def
    lda #16
    sta c_lock
    bra @ask
@title:
    lda #$02
@go:
    pha
    jsl fade_out
    jsl music_stop
    pla
    rtl

; under the final table's box: the champion, then how first place was
; decided when points alone didn't
final_lines:
    jsr buf_reset
    lda c_champs
    bne @won
    LDPTR0 str_nobody
    jsr buf_str
    bra @line
@won:
    cmp #$01
    beq @one
    LDPTR0 str_cochamps
    jsr buf_str
    bra @line
@one:
    LDPTR0 str_champ
    jsr buf_str
    lda c_order
    jsr buf_name
@line:
    jsr buf_term
    lda c_bot
    clc
    adc #2
    jsr row_cell
    LDPTR0 c_buf
    lda #($20 | (TP_PINK << 2))
    jsl txt_print_centre
    lda #$00
    jsl why_line
    bcc @x
    ; 16 px under the champion line; a full field of eight has no room, so
    ; it takes the champion line's place (the champions are yellow above)
    ldy #4
    lda num_players
    cmp #MAX_PLAYERS
    bcc @w4
    lda c_bot
    clc
    adc #2
    jsr blank_row
    ldy #2
@w4:
    tya
    clc
    adc c_bot
    jsr row_cell
    lda #($20 | (TP_CYAN << 2))
    jsl txt_print_centre
@x:
    rts

; "LEAVE AND LOSE 4 PLAYERS?" on row 23 (over the lines under the table for
; now), NO / YES on the choices' row 25, on NO after a short lockout and a
; let-go -> carry set = YES
title_confirm:
    jsr buf_reset
    LDPTR0 str_leave
    jsr buf_str
    lda num_players
    jsr buf_byte
    LDPTR0 str_lose_n
    lda num_players
    cmp #$02
    bcs @pl
    LDPTR0 str_lose_1
@pl:
    jsr buf_str
    jsr buf_term
    lda #23
    jsr blank_row
    lda #24
    jsr blank_row
    lda #23
    jsr row_cell
    LDPTR0 c_buf
    lda #($20 | (TP_ORANGE << 2))
    jsl txt_print_centre
    lda #$03
    sta c_opts
    stz c_def                   ; NO
    lda #16
    sta c_lock
    lda #REL_FRAMES             ; a deliberate choice: the short let-go
    sta c_relq
    jsl card_wait
    pha
    lda #23
    jsr blank_row
    jsr final_lines
    pla
    cmp #$01
    rts

; A = row: blank columns 2-29
blank_row:
    jsr row_cell
    inx
    inx
    A16
    lda #$011C
    sta tmp1
    A8
    stz tmp2
    lda #$20
    jsl txt_fill
    rts

str_leave:  .byte "LEAVE AND LOSE ", 0
str_lose_n: .byte " PLAYERS?", 0
str_lose_1: .byte " PLAYER?", 0

str_final:    .byte "FINAL STANDINGS", 0
str_champ:    .byte "CHAMPION: ", 0
str_cochamps: .byte "CO-CHAMPIONS OF TORONTO!", 0
str_nobody:   .byte "WE'LL GET 'EM NEXT YEAR", 0

; ------------------------------------------------------------------
; records_board: the Toronto board, the top five of one event per page;
; LEFT / RIGHT turn the page, A / B / START go back.
records_board:
    stz c_page
    jsr menu_setup
    PRINTC 1, TP_YELLOW, str_records
    PRINTC 26, TP_GREY, str_rb_hint
    jsr rb_draw
    jsl fade_in
    lda #SONG_MENU
    jsl music_keep
@w:
    jsl wait_frame
    jsl menu_backdrop_tick
    A16
    lda pad_new
    bit #(PAD_A | PAD_B | PAD_START)
    bne @out
    bit #(PAD_LEFT | PAD_UP)
    bne @prev
    bit #(PAD_RIGHT | PAD_DOWN | PAD_SELECT)
    bne @next
    A8
    bra @w
@prev:
    A8
    lda c_page
    bne @p1
    lda #NUM_EVENTS
@p1:
    dec a
    bra @flip
@next:
    A8
    lda c_page
    inc a
    cmp #NUM_EVENTS
    bcc @flip
    lda #$00
@flip:
    sta c_page
    SFX SFX_BLIP
    jsr rb_draw
    bra @w
@out:
    A8
    SFX SFX_BACK
    jsl fade_out
    rtl

rb_draw:
    lda c_page
    sta event_idx
    ldx #(3*32 + 1)
    A16
    lda #$141E                  ; 30 x 20
    sta tmp1
    A8
    lda #$20
    jsl txt_box
    lda #TXT_WIN
    sta txt_bg
    LDPTR1 ev_names
    ldx #(4*32)
    lda #($20 | (TP_YELLOW << 2))
    jsr print_ev_entry_c
    LDPTR1 ev_places
    ldx #(6*32)
    lda #($20 | (TP_CYAN << 2))
    jsr print_ev_entry_c
    stz tmp7                    ; rank
@rank:
    ; tmp5 = row cell (9 + rank*2) * 32
    lda tmp7
    asl a
    clc
    adc #9
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    sta tmp5
    A8
    lda tmp7
    cmp #3
    bcs @digit
    TAXB
    lda f:medal_tp,x
    pha
    lda #(TXT_MEDAL + TXT_WIN)
    sta tmp2
    A16
    lda tmp5
    clc
    adc #5
    tax
    A8
    pla
    jsl txt_char
    bra @who
@digit:
    inc a
    A16
    and #$00FF
    sta tmp1
    lda tmp5
    clc
    adc #5
    tax
    A8
    ldy #1
    lda #($20 | (TP_GREY << 2))
    jsl txt_num
@who:
    ; entry = records + rank*REC_ROW + event*16
    lda tmp7
    sta WRMPYA
    lda #REC_ROW
    sta WRMPYB
    jsr record_ptr
    A16
    txa
    clc
    adc RDMPYL
    sta tmp4
    clc
    adc #.loword(records + 2)
    sta ptr0
    A8
    stz ptr0+2
    A16
    lda tmp5
    clc
    adc #8
    tax
    A8
    lda tmp7
    beq @first
    lda #($20 | (TP_WHITE << 2))
    bra @nm
@first:
    lda #($20 | (TP_YELLOW << 2))
@nm:
    jsl txt_print
    ldx tmp4
    A16
    lda records,x
    sta tmp1
    lda tmp5
    clc
    adc #20
    tax
    A8
    ldy #5
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_num
    inc tmp7
    lda tmp7
    cmp #5
    jne @rank
    ; a solo player's medal lines come from #1
    jsl par_calc
    ldx #(20*32)
    stx tmp5
    jsr par_line
    stz txt_bg
    ; page: < 2 OF 5 >
    jsr buf_reset
    lda #(TXT_ARROW_L + 32)
    jsr buf_ch
    lda #' '
    jsr buf_ch
    lda c_page
    inc a
    jsr buf_byte
    LDPTR0 str_rb_of
    jsr buf_str
    lda #NUM_EVENTS
    jsr buf_byte
    lda #' '
    jsr buf_ch
    lda #(TXT_ARROW_R + 32)
    jsr buf_ch
    jsr buf_term
    LDPTR0 c_buf
    ldx #(24*32)
    lda #($20 | (TP_CYAN << 2))
    jsl txt_print_centre
    rts

str_records:  .byte "TORONTO RECORDS", 0
str_rb_hint:  .byte TXT_ARROW_L+32, TXT_ARROW_R+32, " EVENT     A BACK", 0
str_rb_of:    .byte " OF ", 0

; ------------------------------------------------------------------
; pick_one: one event from the list. A = event under the cursor at first,
; X = title string (this bank) -> carry clear, A = event; carry set = B
pick_one:
    sta m_sel
    stx c_prompt
    jsr menu_setup
    A16
    lda c_prompt
    sta ptr0
    A8
    lda #^pick_one
    sta ptr0+2
    ldx #(3*32)
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_print_centre
    ldx #(6*32 + 3)
    A16
    lda #(((NUM_EVENTS*2 + 3) << 8) | 26)
    sta tmp1
    A8
    lda #$20
    jsl txt_box
    lda #NUM_EVENTS
    sta m_count
    jsr pk_draw
    PRINTC 25, TP_GREY, str_pk_hint
    jsl fade_in
@loop:
    jsl wait_frame
    jsl menu_backdrop_tick
    jsr list_nav
    bcc @nm
    jsr pk_draw
@nm:
    A16
    lda pad_new
    bit #PAD_B
    bne @back
    bit #(PAD_A | PAD_START)
    bne @go
    A8
    bra @loop
@go:
    A8
    SFX SFX_SELECT
    jsl fade_out
    lda m_sel
    clc
    rtl
@back:
    A8
    SFX SFX_BACK
    jsl fade_out
    sec
    rtl

pk_draw:
    lda #TXT_WIN
    sta txt_bg
    LDPTR1 ev_names
    lda #8
    sta tmp7
    jsr draw_list
    stz txt_bg
    rts

str_pk_hint:  .byte "A PLAY    B BACK", 0

; ------------------------------------------------------------------
; text buffer (c_buf / c_len)
buf_reset:
    A16
    stz c_len
    A8
    rts

; A = character (keeps X Y)
buf_ch:
    phx
    ldx c_len
    cpx #159
    bcs @full
    sta f:c_buf,x
    inx
    stx c_len
@full:
    plx
    rts

; append the string at ptr0
buf_str:
    ldy #$0000
@l:
    lda [ptr0],y
    beq @x
    jsr buf_ch
    iny
    bra @l
@x:
    rts

; A = player -> append their name
buf_name:
    jsl player_offset
    ldy #8
@l:
    lda players+PL_NAME,x
    beq @x
    jsr buf_ch
    inx
    dey
    bne @l
@x:
    rts

; A = 0..255 -> append in decimal
buf_byte:
    A16
    and #$00FF
    sta tmp1
    A8
    ; fall through
; tmp1 = value -> append in decimal
buf_num:
    ldy #$0000
@d:
    A16
    lda tmp1
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
    lda RDMPYL                  ; remainder
    pha
    A16
    lda RDDIVL
    sta tmp1
    A8
    iny
    A16
    lda tmp1
    A8
    bne @d
@o:
    pla
    clc
    adc #'0'
    jsr buf_ch
    dey
    bne @o
    rts

; zero-terminate (not counted)
buf_term:
    ldx c_len
    lda #$00
    sta f:c_buf,x
    rts

; champ_names (jsl): ptr0 = the players sharing first place (c_champs of
; them, from final_sort): "KEV & DANA", "KEV, DANA & MO", or a dead heat
champ_names:
    jsr buf_reset
    lda c_champs
    cmp #$04
    bcc @list
    LDPTR0 str_dead_heat
    rtl
@list:
    stz tmp7
@n:
    lda tmp7
    TAXB
    lda c_order,x
    jsr buf_name
    inc tmp7
    lda tmp7
    cmp c_champs
    beq @end
    inc a
    cmp c_champs
    beq @amp
    LDPTR0 str_comma
    bra @sep
@amp:
    LDPTR0 str_amp
@sep:
    jsr buf_str
    bra @n
@end:
    jsr buf_term
    LDPTR0 c_buf
    rtl

str_dead_heat: .byte "A DEAD HEAT AT THE TOP!", 0
str_comma:     .byte ", ", 0
str_amp:       .byte " & ", 0

; ------------------------------------------------------------------
; card_wait (jsl from the screen, so pt still sees which screen it is):
; ignore A for c_lock frames, and until every button has been let go
; for c_relq frames in a row (a mash from the last turn can't carry
; over; REL_NEXT when the card hands over to another player, so even a
; steady rhythm of taps has to stop), then show the prompt and wait for a
; fresh press of A or START.
; The d-pad doesn't count: a thumb resting on it is not a mash. If buttons
; are still down when the timed lockout ends, the prompt row says so
; (LET GO OF THE BUTTONS) instead of the card looking hung; mashing never
; extends the timed part, only the short quiet spell, and once LET GO has
; been up for four quiet spells' worth of frames the next fresh A counts
; (c_esc: not on a hand-over or the final table). That way out works once:
; the card after one that was tapped through (c_chain) needs a real let-go,
; so one long mash can't run through a card, the standings and the medal
; table. c_pre (if not 0) shows in grey on the prompt row while locked.
; c_opts 1/2 offer three choices instead, 3 a NO / YES; the d-pad or SELECT
; moves the cursor (from c_def) at once, only A waits for the lockout.
; c_bok: B, once armed, leaves with A = $FF.
; Runs the c_hook extras every frame. -> A = choice
REL_FRAMES = 20
QUIET_MASK = PAD_A | PAD_B | PAD_X | PAD_Y | PAD_START | PAD_SELECT | PAD_L | PAD_R
card_wait:
    lda c_def
    sta c_sel
    stz c_tick
    stz c_hint
    stz c_viaesc
    stz c_seen
    lda c_relq
    sta c_relc
    lda c_chain
    beq @esc
    stz c_esc                   ; the last card was tapped through
@esc:
    lda c_opts
    bne @menu
    A16
    lda c_pre
    A8
    beq @lock
    jsr card_pre
    bra @lock
@menu:
    jsr card_prompt             ; a menu shows at once
@lock:
    jsl wait_frame
    jsr card_hook
    jsr card_nav
    A16
    lda pad
    and #QUIET_MASK
    A8
    beq @quiet
    lda c_relq                  ; something held: the quiet spell starts again
    sta c_relc
    sta c_seen
    bra @locked
@quiet:
    lda c_relc
    beq @locked
    dec c_relc
@locked:
    lda c_lock
    beq @free
    dec c_lock
    bra @lock
@free:
    lda c_relc
    beq @armed
    lda c_seen                  ; nothing pressed on this card: the rest of the
    beq @lock                   ; quiet spell is just more lockout
    lda c_hint                  ; still mashing: tell them what we're waiting for
    bne @mash
    inc c_hint
    jsr card_hint
    bra @lock
@mash:
    lda c_hint                  ; (stops counting at 255)
    inc a
    beq @lock
    sta c_hint
    lda c_esc                   ; LET GO has been up for four quiet spells and
    beq @lock                   ; they're still tapping: that's a player trying
    lda c_relq                  ; to move on, not a carried-over mash, so the
    asl a                       ; next fresh A goes through
    asl a
    cmp c_hint
    bcs @lock
    inc c_viaesc
@armed:
    lda c_viaesc
    sta c_chain                 ; the next card wants a real let-go
    stz c_hint
    jsr card_prompt
@w:
    jsl wait_frame
    jsr card_hook
    lda c_blink
    beq @nb
    jsr card_prompt
@nb:
    jsr card_nav
    A16
    lda pad_new
    bit #PAD_B
    beq @nob
    A8
    lda c_bok
    beq @w
    SFX SFX_BACK
    lda #$FF
    rtl
@nob:
    .a16
    and #(PAD_A | PAD_START)
    A8
    beq @w
    SFX SFX_SELECT
    lda c_sel
    rtl

; a menu's cursor: LEFT / UP back, RIGHT / DOWN / SELECT on, wrapping
; (the row is redrawn unless LET GO OF THE BUTTONS is up)
card_nav:
    lda c_opts
    beq @x
    TAXB
    lda f:opt_cnt-1,x
    sta c_n
    A16
    lda pad_new
    and #(PAD_LEFT | PAD_UP)
    A8
    beq @fwd
    lda c_sel
    bne @p1
    lda c_n
@p1:
    dec a
    sta c_sel
    bra @moved
@fwd:
    A16
    lda pad_new
    and #(PAD_RIGHT | PAD_DOWN | PAD_SELECT)
    A8
    beq @x
    lda c_sel
    inc a
    cmp c_n
    bcc @f1
    lda #$00
@f1:
    sta c_sel
@moved:
    SFX SFX_BLIP
    lda c_hint
    bne @x
    jsr card_prompt
@x:
    rts

; fade a menu card in with its cursor already live (card_setup and c_opts
; first): a d-pad press during the fade isn't lost
card_fade_in:
    lda c_def
    sta c_sel
    stz c_hint
    jsr card_prompt
    lda #$00
@l:
    sta inidisp_sh
    pha
    jsl wait_frame
    jsr card_nav
    pla
    inc a
    cmp #$10
    bne @l
    lda c_sel
    sta c_def
    rts

card_hook:
    lda c_hook
    and #$08
    beq @h1
    jsr rec_flash
@h1:
    lda c_hook
    and #$01
    beq @h2
    jsl menu_backdrop_tick
@h2:
    lda c_hook
    and #$02
    beq @h4
    jsr champ_hop
@h4:
    lda c_hook
    and #$04
    beq @x
    lda c_tick
    beq @step
    dec c_tick
@x:
    rts
@step:
    lda #8
    sta c_tick
    A16
    inc c_tpos
    lda c_tpos
    cmp c_len
    bcc @ok
    stz c_tpos
@ok:
    A8
    jmp ticker_draw

; new record: the banner (row c_rr1) flashes pink / yellow, WE THE NORTH
; (row c_rr2, if there was room) red / white
rec_flash:
    lda frame
    and #$07
    bne @x
    lda frame
    and #$08
    beq @y
    lda #($20 | (TP_WHITE << 2))
    sta tmp6
    lda #($20 | (TP_PINK << 2))
    sta tmp6+1
    bra @s
@y:
    lda #($20 | (TP_RED << 2))
    sta tmp6
    lda #($20 | (TP_YELLOW << 2))
    sta tmp6+1
@s:
    lda c_rr2
    beq @b
    jsr @row
@b:
    lda tmp6+1
    sta tmp6
    lda c_rr1
    beq @x
    jsr @row
    lda #$01
    sta txt_dirty
@x:
    rts
@row:
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    clc
    adc #3
    asl a
    tax
    A8
    lda tmp6
    ldy #26
@l:
    sta txt_map+1,x
    inx
    inx
    dey
    bne @l
    rts

; the prompt row while buttons are still held after the lockout
card_hint:
    LDPTR0 str_let_go
    lda #($20 | (TP_ORANGE << 2))
    bra row_line

; the prompt row during the lockout: c_pre in grey
card_pre:
    A16
    lda c_pre
    sta ptr0
    A8
    lda c_pre+2
    sta ptr0+2
    lda #($20 | (TP_GREY << 2))
    ; fall through
; the prompt row blanked, then the string at ptr0 centred on it in attr A
row_line:
    sta c_rattr
    lda txt_bg
    pha
    lda c_bg
    sta txt_bg
    sta tmp2
    lda c_row
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    sta tmp5
    clc
    adc #2
    tax
    lda #$011C                  ; 28 x 1
    sta tmp1
    A8
    lda #$20
    jsl txt_fill
    ldx tmp5
    lda c_rattr
    jsl txt_print_centre
    pla
    sta txt_bg
    rts

str_let_go: .byte "LET GO OF THE BUTTONS", 0

; the prompt row: blank it, then the prompt or the choices
card_prompt:
    lda txt_bg
    pha
    lda c_bg
    sta txt_bg
    lda c_row
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    sta tmp5
    clc
    adc #2
    tax
    lda #$011C                  ; 28 x 1
    sta tmp1
    A8
    lda c_bg
    sta tmp2
    lda #$20
    jsl txt_fill
    lda c_opts
    bne @choice
    A16
    lda c_prompt
    sta ptr0
    A8
    lda #^card_prompt
    sta ptr0+2
    ldx tmp5
    lda c_blink
    beq @grey
    ; it pulses green / white rather than blinking off: the line is always
    ; there to read
    lda frame
    and #$10
    beq @pw
    lda #($20 | (TP_GREEN << 2))
    bra @pr
@pw:
    lda #($20 | (TP_WHITE << 2))
    bra @pr
@grey:
    lda #($20 | (TP_GREY << 2))
@pr:
    jsl txt_print_centre
    jmp @x
@choice:
    stz tmp6                    ; option 0, 1, 2
@opt:
    ; table entry: (c_opts-1)*3 + k
    lda c_opts
    dec a
    sta tmp7
    asl a
    clc
    adc tmp7
    clc
    adc tmp6
    TAXB
    lda f:opt_col,x
    sta tmp7
    txa
    asl a
    TAXB
    A16
    lda f:opt_str,x
    sta ptr0
    A8
    lda #^opt_str
    sta ptr0+2
    lda tmp7
    A16
    and #$00FF
    clc
    adc tmp5
    tax
    A8
    lda tmp6
    cmp c_sel
    bne @off
    ; selected: arrow, yellow
    phx
    dex
    dex
    lda #TXT_ARROW_R
    clc
    adc c_bg
    sta tmp2
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_char
    plx
    lda #($20 | (TP_YELLOW << 2))
    bra @print
@off:
    lda #($20 | (TP_GREY << 2))
@print:
    jsl txt_print
    inc tmp6
    lda c_opts
    TAXB
    lda tmp6
    cmp f:opt_cnt-1,x
    bne @opt
@x:
    pla
    sta txt_bg
    rts

; c_opts 1: practice results, 2: final standings, 3: NO / YES (arrow sits 2
; cells left; TITLE ends by column 27, clear of the champion hopping at the
; right)
opt_cnt: .byte 3, 3, 2
opt_col: .byte 4, 12, 26, 4, 13, 23, 11, 18, 0
opt_str: .addr str_retry, str_other, str_menu, str_rematch, str_onemore, str_newgame, str_no, str_yes, str_no
str_retry:   .byte "RETRY", 0
str_other:   .byte "OTHER EVENT", 0
str_menu:    .byte "MENU", 0
str_rematch: .byte "REMATCH", 0
str_onemore: .byte "1 EVENT", 0
str_newgame: .byte "TITLE", 0
str_no:      .byte "NO", 0
str_yes:     .byte "YES", 0

; the champion's athlete hops beside the final table
champ_hop:
    jsl oam_clear
    jsr draw_markers
    lda frame
    asl a
    asl a
    jsl sin8
    A16
    and #$00FF
    cmp #$0080
    bcc @up
    lda #$0000
@up:
    lsr a
    lsr a
    lsr a
    lsr a
    eor #$FFFF
    inc a
    clc
    adc #192
    sta spr_y
    lda #234
    sta spr_x
    lda #32
    sta spr_tile
    A8
    lda #$30
    sta spr_attr
    lda #$01
    sta spr_size
    jsl oam_put
    A16
    lda spr_y
    clc
    adc #16
    sta spr_y
    lda #64
    sta spr_tile
    A8
    jsl oam_put
    rts

; ticker: 28 characters of c_buf from c_tpos, LED orange, row 23
TICK_ROW = 23
ticker_draw:
    A16
    lda c_tpos
    sta c_ti
    A8
    ldy #((TICK_ROW*32 + 2)*2)
    lda #28
    sta c_tn
@l:
    ldx c_ti
    lda f:c_buf,x
    sec
    sbc #$20
    clc
    adc #TXT_WIN
    sta txt_map,y
    lda #($20 | (TP_ORANGE << 2))
    sta txt_map+1,y
    iny
    iny
    A16
    inx
    txa
    cmp c_len
    bcc @k
    lda #$0000
@k:
    sta c_ti
    A8
    dec c_tn
    bne @l
    lda #$01
    sta txt_dirty
    rts

; ------------------------------------------------------------------
; per-event text
ev_blurbs:   .addr eb0, eb1, eb2, eb3, eb4, eb5, eb6
ev_controls: .addr ec0, ec1, ec2, ec3, ec4, ec5, ec6
ev_fails:    .addr ef0, ef1, ef2, ef3, ef4, ef5_1, ef6
; the header of a finished run (green), 28 characters at most
card_finish: .addr fh0, fh1, fh2, fh3, fh4, fh5, fh6
fh0: .byte "DELIVERED!", 0
fh1: .byte "MADE THE 5:42!", 0
fh2: .byte "MADE THE DUNDAS GATE!", 0
fh3: .byte "MADE SPADINA!", 0
fh4: .byte "CROSSED THE LINE!", 0
fh5: .byte "PARKED!", 0
fh6: .byte "UNION! EVERYBODY OFF!", 0
eb0: .byte "DELIVER THE PACKAGE TO", $0A, "SPADINA. PREFERABLY ALIVE.", 0
eb1: .byte "MAKE THE 5:42 GO TRAIN.", $0A, "RED ! AHEAD? CHANGE LANES.", 0
eb2: .byte "QUEEN GATE TO DUNDAS GATE.", $0A, "DODGE DOGS, THEN PAT THEM!", 0
eb3: .byte "THE BIKE COP SAW THAT", $0A, "TALLBOY. RUN TO SPADINA!", 0
eb4: .byte "ROUND MARKS 1, 2 AND 3,", $0A, "THEN CROSS THE LINE.", 0
eb5: .byte "THREE SPOTS ON BRUNSWICK.", $0A, "PARK IT. DON'T DENT A BMW.", 0
eb6: .byte "SURF LINE 1 TO UNION.", $0A, "GRAB A POLE, GET GERMS.", 0
ec0: .byte "D-PAD STEER    A PEDAL", $0A, "B HOP          DOWN BRAKE", $0A, "HOP RAILS, DODGE LATE: X8", 0
ec1: .byte "LEFT, RIGHT ON BIG DOTS", $0A, "UP/DOWN LANE  A EXCUSE ME", $0A, "Y ON A GOLD DOT: PRESTO!", 0
ec2: .byte "D-PAD WALK   A THROW BALL", $0A, "B WHEN ! SHOWS: SIDESTEP", $0A, "B AS HE LUNGES: BONUS!", 0
ec3: .byte "TAP A AT CHALK. RED: HOLD", $0A, "B: SIP WHILE COP CAN'T SEE", $0A, "B MID-AIR = SIP 'N' HOP", 0
ec4: .byte "LEFT/RIGHT: TURN  A: HIKE", $0A, "WIND FROM TOP: ZIG-ZAG UP", $0A, "SURF THE FERRY'S WAKE!", 0
ec5: .byte "UP: REAR BUMPER TO LINE", $0A, "BACK IN: DOWN+RIGHT, THEN", $0A, "DOWN+LEFT. A: PARK IT!", 0
ec6: .byte "HOLLOW ARROW: GET READY", $0A, "SOLID: D-PAD THAT WAY NOW", $0A, "GOLD DOT ALL LEG: SURF X3", 0
ef0: .byte "WIPED OUT!", 0
ef1: .byte "MISSED THE TRAIN!", 0
ef2: .byte "TACKLED!", 0
ef3: .byte "BUSTED!", 0
ef4: .byte "ADRIFT!", 0
ef5: .byte "TOWED!", 0
ef5_1: .byte "NO CLEAN PARK!", 0
ef6: .byte "PATIENT ZERO!", 0
; ev_fail 4: an event's second way to fail (the bike's idle kick)
ev_fails2:   .addr ef2_0, ef1, ef2, ef3, ef4, ef5, ef6
ef2_0: .byte "YOU'RE FIRED!", 0

; result card arithmetic (ev_break): base, bonus, penalty labels per event,
; 12 characters at most. BASE + BONUS - PENALTY = SCORE.
card_break_labels:
    .addr bl_ride,  bl_tips,  bl_wipe       ; bike
    .addr bl_walk,  bl_style, bl_spill      ; bay
    .addr bl_cross, bl_style, bl_tackle     ; park
    .addr bl_run,   bl_style, bl_fine       ; cops
    .addr bl_course, bl_style, bl_bump      ; sail
    .addr bl_park,  bl_style, bl_dings      ; parking
    .addr bl_ride,  bl_style, bl_germs      ; subway
bl_tips:   .byte "TIPS+STYLE", 0
bl_walk:   .byte "WALK", 0
bl_course: .byte "COURSE", 0
bl_arrive: .byte "ARRIVAL", 0
bl_cross:  .byte "CROSSING", 0
bl_run:    .byte "RUN", 0
bl_race:   .byte "RACE", 0
bl_park:   .byte "PARKING", 0
bl_ride:   .byte "RIDE", 0
bl_style:  .byte "STYLE", 0
bl_pats:   .byte "PATS", 0
bl_wipe:   .byte "WIPEOUT X200", 0
bl_spill:  .byte "SPILLS", 0
bl_tackle: .byte "TACKLES", 0
bl_fine:   .byte "COP'S FINE", 0
bl_bump:   .byte "BUMPS", 0
bl_dings:  .byte "DINGS+FINES", 0
bl_germs:  .byte "GERMS", 0

; card_fail_note: the line under a failed run's sum, saying why it scored
; what it did (26 characters at most, centred; a $0A splits it into two lines,
; the second one dropped when the card is full). Per event, ev_fail 1 (its
; own fail), 2 (out of time), 3 (called it a day), 4 (its second fail);
; 0 = none. A base of 0 in a card_still event shows card_still_ln instead.
card_fail_note:
    .addr fn_bike,   fn_bike_n, fn_bike_n, fn_bike_s    ; bike
    .addr fn_bay,    fn_bay,    fn_bay_q,  fn_bay       ; bay
    .addr fn_park,   fn_park_t, fn_park_q, fn_park      ; park
    .addr fn_cops,   fn_cops,   fn_cops_q, fn_cops      ; cops
    .addr fn_sail,   fn_sail_t, fn_sail_t, fn_sail      ; sail
    .addr fn_pk,     fn_pk,     fn_pk_q,   fn_pk_i      ; parking
    .addr fn_sub,    fn_sub,    fn_sub_q,  fn_sub       ; subway
fn_bike:   .byte "THIRD WIPEOUT. NO TIPS!", 0
fn_bike_n: .byte "NOT DELIVERED. NO TIPS!", 0
fn_bike_s: .byte "STOPPED 8 SECONDS. NO TIPS", 0
fn_bay:    .byte "THE 5:42 LEFT WITHOUT YOU", 0
fn_bay_q:  .byte "GAVE UP: THE 5:42 LEFT", 0
fn_park:   .byte "THIRD TACKLE ENDS THE WALK", $0A, "CROSSING PAID BY DISTANCE", 0
fn_park_t: .byte "CROSSING PAID BY DISTANCE", 0
fn_park_q: .byte "GAVE UP: PAID BY DISTANCE", 0
fn_cops:   .byte "COP CAUGHT YOU: FINED 1/4", 0
fn_cops_q: .byte "GAVE UP: THE COP FINES 1/4", 0
fn_sail:   .byte "NOBODY STEERED FOR 10 S", 0
fn_sail_t: .byte "250 PER MARK ROUNDED", 0
fn_pk:     .byte "HALF IN OR TOWED, ALL 3", 0
fn_pk_i:   .byte "10 S WITHOUT DRIVING", 0
fn_pk_q:   .byte "QUITTERS KEEP 450 AT MOST", 0
fn_sub:    .byte "20 GERMS: STYLE IS VOID", $0A, "ONLY LEGS YOU LEANED PAY", 0
fn_sub_q:  .byte "GAVE UP: STYLE IS VOID", $0A, "ONLY LEGS YOU LEANED PAY", 0

; a failed run whose base is 0 says the event's card_still_ln instead of its
; reason line, for the ev_fail codes in card_still (bit n = ev_fail n: $1E all
; four, $02 the event's own fail only, 0 never). For events where only not
; playing earns a base of 0.
card_still:    .byte $1E, $1E, $1E, 0, $02, 0, $1E   ; bike bay park cops sail parking subway
card_still_ln: .addr sti0, sti1, sti2, 0, sti4, 0, sti6
sti0: .byte "STANDING STILL PAYS 0", 0
sti1: .byte "STANDING STILL PAYS 0", 0
sti2: .byte "STANDING STILL PAYS 0", 0
sti4: .byte "NO STEERING, NO POINTS", 0
sti6: .byte "NO LEANING, NO POINTS", 0

; card_rate / card_rate_fail: an optional rate printed in grey after a sum
; label ("TIPS 50 A TOKEN"), per event base, bonus, penalty; 0 = none. The
; first table is for a finished run, the second for a failed one. Label +
; space + rate fit in 16 characters.
card_rate:
    .addr 0, 0, 0               ; bike
    .addr 0, 0, 0               ; bay
    .addr 0, 0, 0               ; park
    .addr 0, 0, 0               ; cops
    .addr 0, 0, 0               ; sail
    .addr 0, 0, 0               ; parking
    .addr 0, 0, rt_sub_pen      ; subway
card_rate_fail:
    .addr 0, 0, 0               ; bike
    .addr 0, 0, 0               ; bay
    .addr 0, 0, 0               ; park
    .addr 0, 0, 0               ; cops
    .addr 0, 0, 0               ; sail
    .addr 0, 0, 0               ; parking
    .addr rt_sub_leg, 0, 0      ; subway
rt_sub_leg: .byte "40 A LEG", 0
rt_sub_pen: .byte "X40", 0

; stat labels: 4 per event (last is padding), 0 = unused
card_stat_labels:
    .addr sl_metres, sl_tokens, sl_wipe, sl_style
    .addr sl_time, sl_pass, sl_spill, sl_style
    .addr sl_time, sl_dodge, sl_tackle, sl_pat
    .addr sl_sipnhop, sl_lucky, sl_hurdles, sl_spill
    .addr sl_time, sl_buoys, sl_bump, sl_style
    .addr sl_parked, sl_kisses, sl_tickets, sl_towed
    .addr sl_germs, sl_stations, sl_chain, sl_style
sl_parked:   .byte "SPOTS PARKED", 0
sl_kisses:   .byte "CURB KISSES", 0
sl_tickets:  .byte "TICKETS", 0
sl_towed:    .byte "TOWED", 0
sl_germs:    .byte "GERMS", 0
sl_stations: .byte "LEGS LEANED", 0
sl_streak:   .byte "BEST STREAK", 0
sl_metres: .byte "METRES", 0
sl_sipnhop: .byte "SIP 'N' HOPS", 0
sl_chain:  .byte "SURF CHAIN", 0
sl_tokens: .byte "TTC TOKENS X50", 0
sl_style:  .byte "STYLE", 0
sl_pat:    .byte "DODGE 'N' PAT", 0
sl_fine:   .byte "COP'S FINE", 0
sl_wipe:   .byte "WIPEOUTS", 0
sl_time:   .byte "TIME LEFT", 0
sl_pass:   .byte "PASSED", 0
sl_spill:  .byte "SPILLS", 0
sl_dodge:  .byte "DOGS DODGED", 0
sl_tackle: .byte "TACKLES", 0
sl_lucky:  .byte "LUCKY SIPS", 0
sl_hurdles: .byte "HURDLES", 0
sl_buoys:  .byte "MARKS ROUNDED", 0
sl_bump:   .byte "BUMPS", 0

; ------------------------------------------------------------------
; ------------------------------------------------------------------
; event_countdown: a big 3, 2, 1, GO! (red, orange, yellow, green) in the
; middle of the frozen scene, then START may pause until the score card.
; The glyphs (tools/art_ceremony.py) go into spare BG3 font tiles 100-127.
CD_TILE = 100
CD_ROW  = 10

event_countdown:
    stz txt_bg
    ldx #$0000
@n:
    stx c_cd
    A16
    txa
    asl a
    tax
    lda f:cd_off,x
    clc
    adc #.loword(cd_big)
    sta ptr0
    lda f:cd_len,x
    sta tmp0
    A8
    lda #^cd_big
    sta ptr0+2
    ldx #(VRAM_TXTTILES + CD_TILE*8)
    lda #$80
    jsl dma_queue
    jsl wait_frame              ; the tiles land in this vblank
    jsr cd_clear
    jsr cd_draw
    ldx c_cd
    cpx #3
    beq @go
    SFX SFX_READY
    bra @wait
@go:
    SFX SFX_GO
@wait:
    ldx #40
    jsl wait_frames
    ldx c_cd
    inx
    cpx #4
    bne @n
    jsr cd_clear
    lda #$01
    sta pause_ok
    rtl

; blank the countdown area (rows CD_ROW..+3, columns 12..18)
cd_clear:
    ldx #(CD_ROW*32 + 12)
    A16
    lda #$0407
    sta tmp1
    A8
    stz tmp2
    lda #$20
    jsl txt_fill
    rts

; glyph c_cd into the text map
cd_draw:
    lda c_cd
    TAXB
    lda f:cd_w,x
    sta c_cw
    lda f:cd_col,x
    sta c_ccol
    lda f:cd_pal,x
    asl a
    asl a
    ora #$20
    sta c_cattr
    lda #CD_TILE
    sta c_ct
    stz c_cr
@row:
    lda c_cr
    clc
    adc #CD_ROW
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    sta tmp1
    lda c_ccol
    and #$00FF
    clc
    adc tmp1
    asl a
    tax
    A8
    lda c_cw
    sta c_ck
@col:
    lda c_ct
    sta txt_map,x
    lda c_cattr
    sta txt_map+1,x
    inc c_ct
    inx
    inx
    dec c_ck
    bne @col
    inc c_cr
    lda c_cr
    cmp #4
    bne @row
    lda #$01
    sta txt_dirty
    rts

cd_off: .word 0, 192, 384, 576
cd_len: .word 192, 192, 192, 448
cd_w:   .byte 3, 3, 3, 7
cd_col: .byte 14, 14, 14, 12
cd_pal: .byte TP_RED, TP_ORANGE, TP_YELLOW, TP_GREEN
cd_big: .incbin "cd_big.bin"

; event_popup: ptr0 = message, A = text palette -> centred on row 9
event_popup:
    asl a
    asl a
    ora #$20
    pha
    jsl event_popup_clear
    pla
    ldx #(9*32)
    jsl txt_print_centre
    rtl

; event_popup_clear: blank row 9 (keeps ptr0)
event_popup_clear:
    ldx #(9*32)
    A16
    lda #$0120
    sta tmp1
    A8
    stz tmp2
    lda #$20
    jsl txt_fill
    rtl
