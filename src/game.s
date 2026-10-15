; Game director: title -> menu -> sign-up -> events -> ceremony.
; Also shared helpers for screens and events (all jsl/rtl, A8 XY16).
.p816
.smart -
.include "globals.inc"
.include "screens.inc"

.define RGB(r,g,b) ((((b)>>3)<<10)|(((g)>>3)<<5)|((r)>>3))



.export rank_place, g_choice, par_calc, par_g, par_s, par_b
.import records_board, pick_one, demo_start
.import d_trick                 ; boot.s: WATCH THAT MOVE! frames
.export demo_abort, practice_back

.segment "BSS"
rank_order: .res MAX_PLAYERS
rank_medal: .res MAX_PLAYERS     ; 0 gold 1 silver 2 bronze 3+ none
rank_place: .res MAX_PLAYERS     ; 0-based place, shared by equal scores
g_choice:   .res 1               ; practice results: 0 retry, 1 other event, 2 menu
par_g:      .res 2               ; solo medal lines for event_idx (par_calc)
par_s:      .res 2
par_b:      .res 2
g_sp:       .res 2               ; run_event: the stack to unwind to (practice_back)
g_back:     .res 1               ; 1 = B on a Practice intro card: back to the event list

.segment "SCREENS"
.a8
.i16

game_main:
    phk
    plb
    jsl records_load
@title:
    jsl title_screen            ; A = $FF: the attract cycle wants a demo
    cmp #$FF
    beq @demo
    lda demo_force              ; harness hook: 1 play a demo, 2 record one
    beq @menu
@demo:
    jsl demo_play
    bra @title
@menu:
    jsl main_menu               ; A = 0 all, 1 some, 2 practice, 3 records
    cmp #3
    bne @play
    jsl records_board
    bra @menu
@play:
    sta game_mode
    jsl register_players        ; carry set = backed out
    bcs @menu
    lda game_mode
    cmp #GM_ALL
    bne @choose
    ldx #$0000
    lda #$01
@all:
    sta event_on,x
    inx
    cpx #NUM_EVENTS
    bne @all
    bra @go
@choose:
    jsl pick_events             ; carry set = backed out
    bcs @menu
@go:
    jsl clear_scores
    stz event_idx
@ev_loop:
    lda event_idx
    TAXB
    lda event_on,x
    beq @next_ev
    jsr run_event
    lda g_back
    beq @next_ev
    ; B on the intro card (Practice): the event list, on this event
    stz pause_ok
    stz ev_giveup
    jsl music_stop
    jsl fade_out
    jsl hdma_off
    lda event_idx
    bra @oe
@next_ev:
    inc event_idx
    lda event_idx
    cmp #NUM_EVENTS
    bne @ev_loop
    lda game_mode
    cmp #GM_PRACTICE
    bne @ceremony
    lda g_choice                ; practice results: 0 retry, 1 other event, 2 menu
    jeq @go
    cmp #$01
    jne @menu
    ; same crew, another event (cursor starts on the next one)
    jsr played_event
    inc a
    cmp #NUM_EVENTS
    bcc @oe
    lda #$00
@oe:
    ldx #.loword(str_other_ev)
    jsl pick_one
    jcs @menu
    jsr only_event
    jmp @go
@ceremony:
    jsl ceremony                ; A = 0 rematch, 1 one more event, 2 new game
@chose:
    cmp #$00
    jeq @go
    cmp #$01
    jne @title
    ; one more event with the same crew: a one-event competition
    jsr played_event
    ldx #.loword(str_one_more)
    jsl pick_one
    bcc @one
    lda #$01                    ; changed their mind: back to the final table,
    jsl final_table             ; the cursor where they left it
    bra @chose
@one:
    jsr only_event
    lda #GM_SOME
    sta game_mode
    jmp @go

str_other_ev: .byte "PRACTICE WHICH EVENT?", 0
str_one_more: .byte "ONE MORE EVENT!", 0

; A = the first event in this competition
played_event:
    ldx #$0000
@f:
    lda event_on,x
    bne @x
    inx
    cpx #NUM_EVENTS
    bne @f
    ldx #$0000
@x:
    txa
    rts

; A = event -> event_on holds just that one
only_event:
    ldx #$0000
@c:
    stz event_on,x
    inx
    cpx #NUM_EVENTS
    bne @c
    TAXB
    lda #$01
    sta event_on,x
    rts

; every player takes a turn at event_idx, then medals + standings
; (g_back = 1: the first player backed out of a Practice intro card)
run_event:
    stz cur_player
    stz g_back
@pl:
    jsr turn_reset
    tsx
    stx g_sp
    jsl call_event
    jsr store_score
    inc cur_player
    lda cur_player
    cmp num_players
    bne @pl
    jsl award_medals
    jsl event_standings
    rts

; a clean slate for the turn: no give-up, no score, no stats, no arithmetic
; (nothing carries over from the last player or the last event). An event
; that never fills ev_break gets a card with SCORE alone under its stats.
turn_reset:
    stz ev_giveup
    stz ev_fail
    A16
    stz ev_score
    stz ev_stat
    stz ev_stat+2
    stz ev_stat+4
    stz ev_stat+6
    stz ev_break
    stz ev_break+2
    stz ev_break+4
    ldx #$0000
@sty:
    stz ev_style,x              ; no style sources (cards.s ITEMISED STYLE)
    inx
    inx
    cpx #10
    bne @sty
    A8
    rts

; call_event: jump into the event_idx entry point (it returns to our caller)
call_event:
    lda event_idx
    A16
    and #$00FF
    asl a
    asl a
    tax
    lda f:ev_entry,x
    sta ptr2
    lda f:ev_entry+1,x
    sta ptr2+1
    A8
    jml [ptr2]

; ------------------------------------------------------------------
; demo_play: the attract demo. The next event in rotation in Practice with
; one default player, driven by a recorded joypad stream: while demo_on is
; set, wait_frame (boot.s demo_pads) swaps the stream in for pad. A real
; button press, or the end of the stream, unwinds the stack to demo_sp and
; lands in demo_abort; either way we go back to the title.
; Events are deterministic from their first frame given rng and frame, so
; both are fixed here. demo_force = 2 records instead (tools/pt/demo_export.py).
DEMO_SEED = $5EED
demo_play:
    ldy #NUM_EVENTS             ; events without a recorded stream are skipped
@pick:
    lda demo_ev
    cmp #NUM_EVENTS
    bcc @ok
    lda #$00
@ok:
    sta event_idx
    inc a
    cmp #NUM_EVENTS
    bcc @nx
    lda #$00
@nx:
    sta demo_ev
    lda event_idx
    A16
    and #$00FF
    asl a
    tax
    lda f:demo_start,x
    cmp #$FFFF
    A8
    bne @have
    lda demo_force              ; recording needs no stream
    cmp #$02
    beq @have
    dey
    bne @pick
    rtl                         ; nothing recorded at all
@have:
    lda #$00
    sta f:d_trick               ; no caption left over from the last demo
    lda #$01
    sta num_players
    stz cur_player
    lda #GM_PRACTICE
    sta game_mode
    ldx #$0000
@nm:
    lda f:demo_name,x
    sta players+PL_NAME,x
    inx
    cpx #9
    bne @nm
    stz players+PL_SPONSOR
    jsl clear_scores
    lda event_idx
    jsr only_event
    lda event_idx
    A16
    and #$00FF
    asl a
    tax
    lda f:demo_start,x
    sta demo_off
    stz demo_left
    stz demo_mask
    lda pad
    sta demo_real
    lda #DEMO_SEED
    sta rng
    stz frame
    A8
    lda demo_force
    cmp #$02
    beq @mode
    lda #$01
@mode:
    sta demo_on
    stz demo_force
    cmp #$02
    bne @go
    ldx #$0000
    stx demo_off                ; recording: the log starts at $7F:0000
@go:
    jsr turn_reset
    stz pause_ok
    tsx
    stx demo_sp
    jsl call_event
demo_end:
    stz demo_on
    stz pause_ok
    stz ev_giveup
    jsl music_stop
    jsl fade_out
    jsl hdma_off
    rtl

; boot.s demo_pads jumps here with the stack back at demo_sp
demo_abort:
    rep #$10
    sep #$20
    .a8
    .i16
    phk
    plb
    bra demo_end

demo_name: .byte "PLAYER 1", 0

; practice_back (jml from cards.s event_card): B on the first player's intro
; card in Practice. The event has only loaded its scene, so, as with a demo
; abort, its state can simply be dropped: back into run_event with the stack
; it had before call_event, and out to the event list.
practice_back:
    rep #$10
    sep #$20
    .a8
    .i16
    phk
    plb
    ldx g_sp
    txs
    lda #$01
    sta g_back
    rts                         ; from run_event, to game_main (which tidies up)

ev_entry:
    .faraddr ev_bike
    .byte 0
    .faraddr ev_bay
    .byte 0
    .faraddr ev_park
    .byte 0
    .faraddr ev_cops
    .byte 0
    .faraddr ev_sail
    .byte 0
    .faraddr ev_parking
    .byte 0
    .faraddr ev_subway
    .byte 0

store_score:
    lda cur_player
    jsl player_offset
    stx tmp0
    A16
    lda event_idx
    and #$00FF
    asl a
    clc
    adc tmp0
    tax
    lda ev_score
    sta players+PL_SCORES,x
    ldx tmp0
    lda players+PL_TOTAL,x
    clc
    adc ev_score
    sta players+PL_TOTAL,x
    A8
    rts

; ------------------------------------------------------------------
; player_offset: A = player -> X = player * 32
player_offset:
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    tax
    A8
    rtl

clear_scores:
    ldx #$0000
@p:
    phx
    ldy #(PL_TOTAL + 2 - PL_SCORES)
@b:
    stz players+PL_SCORES,x
    inx
    dey
    bne @b
    plx
    A16
    txa
    clc
    adc #PL_SIZE
    tax
    A8
    cpx #(PL_SIZE*MAX_PLAYERS)
    bne @p
    rtl

; award_medals: rank players on event_idx, fill rank_order / rank_place /
; rank_medal, add medals and points (5 / 3 / 1).
; Equal scores share a place (and its medal; the next place is skipped, as at
; the Olympics). A score of 0 never wins a medal. A solo player has nobody to
; beat, so they race the Toronto Record instead (par_calc): gold for matching
; it, silver for 2/3 of it, bronze for 1/3.
award_medals:
    jsl par_calc
    php
    AXY8
    ldx #$00
@init:
    txa
    sta rank_order,x
    inx
    cpx num_players
    bne @init
    ; selection sort, highest score first (equal scores keep player order)
    ldx #$00
@outer:
    stx tmp2                    ; i
    stx tmp3                    ; best
    lda rank_order,x
    jsr score_of
    lda tmp0
    sta tmp4
    lda tmp0+1
    sta tmp4+1
    ldx tmp2
@inner:
    inx
    cpx num_players
    bcs @swap
    stx tmp5
    lda rank_order,x
    jsr score_of
    ldx tmp5
    A16
    lda tmp0
    cmp tmp4
    A8
    bcc @inner
    beq @inner
    stx tmp3
    lda tmp0
    sta tmp4
    lda tmp0+1
    sta tmp4+1
    bra @inner
@swap:
    ; move the best to slot i, shifting the rest down (keeps ties in order)
    ldx tmp3
    lda rank_order,x
    sta tmp5
@shift:
    cpx tmp2
    beq @put
    lda rank_order-1,x
    sta rank_order,x
    dex
    bra @shift
@put:
    lda tmp5
    sta rank_order,x
    inx
    cpx num_players
    bcc @outer
    ; places and medals
    ldx #$00
@medal:
    stx tmp2
    lda rank_order,x
    jsr score_of
    ldx tmp2
    beq @newplace
    A16
    lda tmp0
    cmp tmp4
    A8
    beq @same
@newplace:
    stx tmp6                    ; place = index of the first of equal scores
@same:
    lda tmp0
    sta tmp4
    lda tmp0+1
    sta tmp4+1
    lda tmp6
    sta rank_place,x
    lda #$03
    sta rank_medal,x
    A16
    lda tmp0
    A8
    beq @no_medal               ; nothing scored, nothing won
    lda num_players
    cmp #$01
    beq @solo
    lda tmp6
    cmp #$03
    bcs @no_medal
    bra @give
@solo:
    jsr par_medal
    cmp #$03
    bcs @no_medal
@give:
    sta rank_medal,x
    sta tmp7                    ; medal 0..2
    ; player offset in Y
    lda rank_order,x
    asl a
    asl a
    asl a
    asl a
    asl a
    sta tmp5
    clc
    adc tmp7
    tay
    lda players+PL_GOLD,y
    inc a
    sta players+PL_GOLD,y
    ldy tmp5
    ldx tmp7
    lda players+PL_POINTS,y
    clc
    adc f:medal_points,x
    sta players+PL_POINTS,y
    lda players+PL_POINTS+1,y
    adc #$00
    sta players+PL_POINTS+1,y
    ldx tmp2
@no_medal:
    inx
    cpx num_players
    jcc @medal
    plp
    rtl

medal_points:
    .byte 5, 3, 1

; tmp0 = score -> A = solo medal against par (0 gold .. 3 none); clobbers Y
.a8
.i8
par_medal:
    ldy #$00
    A16
    lda tmp0
    cmp par_g
    bcs @d
    iny
    cmp par_s
    bcs @d
    iny
    cmp par_b
    bcs @d
    iny
@d:
    A8
    tya
    rts

; par_calc: solo medal lines for event_idx from its Toronto Record (#1):
; par_b = record/3 and par_s = record - par_b, both rounded to the nearest
; (2000 -> 1333 / 667, 2200 -> 1467 / 733); par_b at least 1
.a8
.i16
par_calc:
    lda event_idx
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    tax
    lda records,x
    sta par_g
    inc a                       ; (record + 1) / 3 rounds to the nearest
    bne @div
    dec a
@div:
    sta WRDIVL
    A8
    lda #3
    sta WRDIVB
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    A16
    lda RDDIVL
    bne @nz
    inc a
@nz:
    sta par_b
    lda par_g
    sec
    sbc par_b
    bcs @ok
    lda #$0001
@ok:
    sta par_s
    A8
    rtl

; A = player (AXY8) -> tmp0 = that player's score on event_idx; clobbers X
.a8
.i8
score_of:
    asl a
    asl a
    asl a
    asl a
    asl a
    clc
    adc #PL_SCORES
    sta tmp1
    lda event_idx
    asl a
    clc
    adc tmp1
    tax
    lda players,x
    sta tmp0
    lda players+1,x
    sta tmp0+1
    rts
.a8
.i16

; ------------------------------------------------------------------
load_text_gfx:
    VLOAD VRAM_TXTTILES, txt_tiles, 4096
    PLOAD 0, txt_pal, 32
    rtl

load_menu_gfx:
    VLOAD VRAM_BGTILES, menu_tiles, (menu_bg2 - menu_tiles)
    VLOAD VRAM_BG2MAP, menu_bg2, 2048
    VLOAD VRAM_BG1MAP, badges_bg1, 2048
    PLOAD 32, menu_pal, 96
    VLOAD VRAM_OBJTILES, spr_menu, (spr_menu_pal - spr_menu)
    PLOAD 128, spr_menu_pal, 32
    jsl load_text_gfx
    A16
    lda #RGB($10, $14, $38)
    sta pal_buf
    A8
    rtl

menu_backdrop_tick:
    lda frame
    and #$01
    bne @x
    A16
    inc bg2x
    inc bg2y
    A8
@x:
    rtl

; wait for A/START (A = 0) or B (A = 1)
wait_button:
@w:
    jsl wait_frame
    A16
    lda pad_new
    bit #(PAD_A | PAD_START)
    bne @a
    bit #PAD_B
    bne @b
    A8
    bra @w
@a:
    A8
    lda #$00
    rtl
@b:
    A8
    lda #$01
    rtl

; ------------------------------------------------------------------
; print_player_name: A = player, X = cell, tmp6 low = attr
print_player_name:
    phx
    jsl player_offset
    A16
    txa
    clc
    adc #.loword(players)
    sta ptr0
    A8
    stz ptr0+2
    plx
    lda tmp6
    jsl txt_print
    rtl

; print_sponsor_name: A = sponsor, X = cell, tmp6 low = attr
print_sponsor_name:
    phx
    A16
    and #$00FF
    asl a
    tax
    lda f:sponsor_names,x
    sta ptr0
    A8
    lda #^sponsor_names
    sta ptr0+2
    plx
    lda tmp6
    jsl txt_print
    rtl

; player_palette: A = player, Y = sprite palette slot -> athlete colours in
; that player's sponsor jersey and their own skin / hair
player_palette:
    sta tmp4
    sty tmp5
    A16
    lda tmp5
    and #$0007
    asl a
    asl a
    asl a
    asl a
    asl a
    clc
    adc #256
    sta tmp3
    ldx #$0000
    ldy tmp3
@c:
    lda f:spr_menu_pal,x
    sta pal_buf,y
    inx
    inx
    iny
    iny
    cpx #32
    bne @c
    A8
    lda tmp4
    jsl player_offset
    lda players+PL_SPONSOR,x
    A16
    and #$00FF
    sta tmp0
    asl a
    adc tmp0
    asl a
    tax
    ldy tmp3
    lda f:jerseys,x
    sta pal_buf+10,y
    lda f:jerseys+2,x
    sta pal_buf+12,y
    lda f:jerseys+4,x
    sta pal_buf+14,y
    lda tmp4
    and #$0007
    asl a
    asl a
    asl a
    tax
    lda f:skins,x
    sta pal_buf+4,y
    lda f:skins+2,x
    sta pal_buf+6,y
    lda f:skins+4,x
    sta pal_buf+8,y
    A8
    lda #$01
    sta pal_dirty
    rtl

skins:
    .word RGB($f8,$c8,$90), RGB($c8,$88,$50), RGB($48,$30,$18), 0
    .word RGB($d0,$90,$60), RGB($90,$58,$28), RGB($18,$10,$10), 0
    .word RGB($8a,$55,$30), RGB($5a,$34,$18), RGB($10,$10,$10), 0
    .word RGB($f8,$d8,$b0), RGB($d0,$a0,$70), RGB($c8,$90,$40), 0
    .word RGB($b8,$78,$48), RGB($78,$48,$20), RGB($28,$18,$10), 0
    .word RGB($f0,$b8,$88), RGB($b8,$78,$48), RGB($a0,$38,$18), 0
    .word RGB($60,$38,$20), RGB($3c,$20,$10), RGB($10,$10,$10), 0
    .word RGB($e8,$b0,$80), RGB($b0,$78,$48), RGB($70,$70,$70), 0

; ------------------------------------------------------------------
; Records live in battery SRAM at $70:0000: the signature (REC_SIG), then the Toronto board:
; 5 ranks x NUM_EVENTS events x 16 bytes (score word, name 9, pad 5), rank-major, so
; records + event*16 is still each event's #1 and records + rank*16*NUM_EVENTS + event*16
; its rank-th. Each event's five stay sorted, highest first.
REC_BYTES = 16 * NUM_EVENTS * 5
; bump the last character whenever default_records changes: carts with the
; old signature are re-seeded (and lose their saved board) on the next boot
.define REC_SIG "TG16"
records_load:
    ldx #$0000
@sig:
    lda f:$700000,x
    cmp f:rec_sig,x
    bne @fresh
    inx
    cpx #4
    bne @sig
    bra @copy
@fresh:
    ; default_records is event-major (five per event); the board is rank-major
    ldx #$0000                  ; source
    ldy #$0000                  ; destination: rank 0 of event 0
@def:
    phy
    lda #16
    sta tmp0
@b:
    lda f:default_records,x
    sta records,y
    inx
    iny
    dec tmp0
    bne @b
    ply
    A16
    tya
    clc
    adc #(16 * NUM_EVENTS)      ; next rank, same event
    cmp #REC_BYTES
    bcc @nr
    sbc #(REC_BYTES - 16)       ; past #5: next event's #1
@nr:
    tay
    A8
    cpx #REC_BYTES
    bne @def
    jsl records_save
    rtl
@copy:
    ldx #$0000
@c:
    lda f:$700004,x
    sta records,x
    inx
    cpx #REC_BYTES
    bne @c
    rtl

records_save:
    lda demo_on                 ; a demo never touches the cart's battery
    bne @x
    ldx #$0000
@sig:
    lda f:rec_sig,x
    sta f:$700000,x
    inx
    cpx #4
    bne @sig
    ldx #$0000
@c:
    lda records,x
    sta f:$700004,x
    inx
    cpx #REC_BYTES
    bne @c
@x:
    rtl

rec_sig: .byte REC_SIG

; ==================================================================
; DEFAULT TORONTO RECORDS: the ghost rivals seeded into SRAM the first time
; the cart boots (or whenever the REC_SIG signature is missing). Five per
; event, highest first, events in event order (records_load deals them out
; into the rank-major board). #1 is the bar a good player should clear and a
; solo player's medal lines (gold = #1, silver 2/3, bronze 1/3).
; A cart that already has saved records keeps them; bump REC_SIG to force a
; re-seed. Names: 8 characters max.
; Seeding: every event aims at the same scale (a skilled finish 2500-4500,
; an average finish 1200-2500, no-skill input under 400, any finish above any
; failed run), so #5 sits where an average finish lands, out of reach of a
; failed or abandoned run. #1 also sets the solo medal lines.
; A new event adds five lines here (the .assert checks the count).
.macro REC score, name
    .word score
    .byte name
    .res 14 - .strlen(name), 0
.endmacro

default_records:
    ; EV_BIKE  Bike Courier
    REC 6000, "COURIER"
    REC 4900, "FIXIE"
    REC 3900, "TTC GUS"
    REC 2900, "PEDICAB"
    REC 2000, "SALMON"
    ; EV_BAY   Bay St Power Walk
    REC 3200, "SUITGUY"
    REC 2700, "BAYBANKR"
    REC 2200, "MEL"
    REC 1700, "INTERN"
    REC 1300, "TIMBIT"
    ; EV_PARK  Off-Leash Alert
    REC 10200, "DOODLE"
    REC 8600, "GOLDIE"
    REC 7000, "FRISBEE"
    REC 5600, "HIPSTER"
    REC 4200, "SQUIRREL"
    ; EV_COPS  Tallboy Trot
    REC 6600, "RACCOON"
    REC 5200, "BIKE COP"
    REC 3900, "BANDIT"
    REC 2700, "BUSKER"
    REC 1700, "NANA"
    ; EV_SAIL  Harbour Regatta
    REC 3900, "GOOSE"
    REC 3300, "SKIPPER"
    REC 2800, "FERRYMAN"
    REC 2400, "KAYAKER"
    REC 2000, "SEAGULL"
    ; EV_PARKING  Parallel Parking
    REC 5500, "GREEN P"
    REC 4400, "VALET"
    REC 3500, "CABBIE"
    REC 2600, "LEARNER"
    REC 1700, "TOWTRUCK"
    ; EV_SUBWAY   TTC Surfing
    REC 6100, "HANDRAIL"
    REC 5000, "COMMUTER"
    REC 3800, "TOURIST"
    REC 2900, "STROLLER"
    REC 2200, "LINE 1"
default_records_end:
.assert default_records_end - default_records = REC_BYTES, error, "default_records: five REC lines per event"
; ==================================================================

; ------------------------------------------------------------------
sponsor_names:
    .addr sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11
sponsor_tags:
    .addr st0, st1, st2, st3, st4, st5, st6, st7, st8, st9, st10, st11
sn0:  .byte "HONEST ED'S", 0
sn1:  .byte "SAM THE RECORD MAN", 0
sn2:  .byte "EATON'S", 0
sn3:  .byte "PIZZA PIZZA", 0
sn4:  .byte "SWISS CHALET", 0
sn5:  .byte "MR. SUB", 0
sn6:  .byte "CANADIAN TIRE", 0
sn7:  .byte "ROOTS", 0
sn8:  .byte "LAURA SECORD", 0
sn9:  .byte "SHOPSY'S", 0
sn10: .byte "STEAM WHISTLE", 0
sn11: .byte "MUCHMUSIC", 0
st0:  .byte "COME IN AND GET LOST!", 0
st1:  .byte "SPINNING ON YONGE ST", 0
st2:  .byte "EST. 1869", 0
st3:  .byte "967-11-11", 0
st4:  .byte "QUARTER DARK, PLEASE", 0
st5:  .byte "FOOTLONG FUEL", 0
st6:  .byte "PAID IN TIRE MONEY", 0
st7:  .byte "BEAVER APPROVED", 0
st8:  .byte "SWEET SINCE 1913", 0
st9:  .byte "FRANKLY, THE BEST", 0
st10: .byte "BREWED AT THE ROUNDHOUSE", 0
st11: .byte "LIVE FROM QUEEN WEST", 0

ev_names:
    .addr en0, en1, en2, en3, en4, en5, en6
ev_places:
    .addr ep0, ep1, ep2, ep3, ep4, ep5, ep6
en0: .byte "BIKE COURIER", 0
en1: .byte "BAY ST POWER WALK", 0
en2: .byte "OFF-LEASH ALERT", 0
en3: .byte "TALLBOY TROT", 0
en4: .byte "HARBOUR REGATTA", 0
en5: .byte "PARALLEL PARKING", 0
en6: .byte "TTC SURFING", 0
ep0: .byte "QUEEN STREET WEST", 0
ep1: .byte "BAY ST AT KING", 0
ep2: .byte "TRINITY BELLWOODS", 0
ep3: .byte "KENSINGTON MARKET", 0
ep4: .byte "TORONTO HARBOUR", 0
ep5: .byte "THE ANNEX", 0
ep6: .byte "LINE 1 YONGE-UNIVERSITY", 0
