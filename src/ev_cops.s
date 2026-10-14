; EVENT 4: TALLBOY TROT — Kensington Market side-scroller.
; Auto-run; A jumps (tap: hop the low stuff, hold: big jump for green bins),
; hold B to sip the tallboy. Sipping on the ground slows you down, so every
; sip spends some of your lead on the bike cop; in the air you keep your
; momentum, and a sip goes down twice as fast: one press of B mid-air
; commits to it. Sips only score while the cop can't see you (off-screen).
; Every hurdle has a chalk take-off mark on the pavement ahead of it: a
; yellow chevron (tap A) or red ones (hold A), with a chalk strip on from it.
; Take-off points (style) for every hop: 40 right on the chevron, a point
; less every 1.6 px either side, nothing 64 px past it (or 9 short). DEAD ON
; (within a frame of the chevron) and ON THE CHALK (8 px short to 20 px past:
; the strip) name it; past the strip it's BIT LATE, BUD.
; A sip finished mid-air over a hurdle is a SIP 'N' HOP. It pays
;   base x chain x chalk
; base 8 + a point for every 16 BUZZ you had before the sip (nobody tells you:
; from 128 up it's LIQUID COURAGE and the base takes 4 more, but the sip takes
; you into the red), doubled over a green bin (BIG SIP 'N' HOP) or a raccoon
; (RACCOON RUN); chain X1..X5 (one more for each SIP 'N' HOP in a
; row); chalk X1, X2 ON THE CHALK, X3 DEAD ON. The banner's second line
; spells out the parts that multiply. A dry hop that paid take-off points
; holds the chain; one way off the chalk ends it (so does a spill, a
; scramble, a seen or a sloshed sip). Sip on the ground next to a green bin
; and a raccoon nicks your can. Run into a hurdle and you stop dead against
; it (STUCK! TAP A TO SCRAMBLE): A then scrambles you over (no spill, the
; hurdle's 50 but no take-off points), else you go down. The first 30 s are a warm-up: the cop hangs back,
; can't bust you, and the game tells you what each obstacle needs; you stand
; against a hurdle longer, and hopping at nothing only gets a word, not
; WINDED. Then he finds his legs over 4 s.
; BUZZ is the sip budget: each sip adds to it and it wears off slowly. In the
; red (TIPSY) the cop gains on you until he's on screen, watching, and a sip
; is SLOSHED: no points, chain over. So a top run picks its sips (the big
; hurdles, DEAD ON take-offs) and rides the BUZZ high without going red.
; From COURAGE to TIPSY the BUZZ meter turns gold and the runner's can glows
; (pulsing): the tell that a SIP 'N' HOP now pays the bigger base, and the
; banner's sum line starts GOLD.
; Score (ev_break): RUN (50 a hurdle hopped or scrambled over) + STYLE (take-offs, sips, SIP 'N'
; HOPs). The finish tally and the card add it up the same way.
; A spill costs no points (bar that hop's take-off and its 50): it costs
; ground on the cop and your chain. Busted: the COP'S FINE takes a quarter of
; run + style; make Spadina and there's no fine. The HUD's PTS is run + style.
.p816
.smart -
.include "globals.inc"
.include "screens.inc"

.import cops_tiles, cops_bg1, cops_bg2, cops_pal, cops_spr, cops_spr_pal, cops_sky, sine_table
.import trick_seen          ; boot.s: the attract demo's WATCH THAT MOVE! cue

GROUND     = 192
PLAYER_SX  = 104
COURSE_LEN = 7200
RUN_SPD    = $0200
SIP_SPD    = $00E0
TRIP_SPD   = $0080
JUMP_V     = $03C0
GRAVITY    = $0020
MIN_HOP    = 8               ; air frames before letting go of A cuts the jump
HOP_CUT    = $0180           ; ...to this rise speed: a tap is a hop, a hold a big jump
JUMP_LOCK  = 12              ; frames on your feet after a landing before A jumps again
COP_WARM   = $0180           ; cop speed in the warm-up
COP_START  = $01C0           ; ...and after it
COP_RAMP   = $3F             ; then 1/256 px/frame faster every 64 frames
WARM_T     = 1800            ; 30 s warm-up: the cop can't bust you yet
GAP_START  = 176
GAP_MAX    = 176
GAP_BUST   = 22
GAP_WARM   = 80              ; closest the cop gets in the warm-up
COP_SEEN   = 110             ; gap below this = the cop is on screen (a third of his bike shows)
TRIP_TIME  = 33
TRIP_LUNGE = 16              ; px the cop gains on top of the stumble
SEEN_LUNGE = 10              ; px the cop gains when he catches you sipping
;  a callout stays up at least this long before coaching may replace it
POP_MIN    = 40
BUMP_T     = 40              ; frames up against a hurdle: A scrambles over, else a spill
                             ; (STUCK! TAP A TO SCRAMBLE comes up at once: long enough for
                             ; a 25-frame hand that reads it to act)
BUMP_WARM  = 90              ; ...in the warm-up: it teaches before it punishes
WASTE_MAX  = 3               ; jumps in a row over nothing and you're winded...
WIND_T     = 150             ; ...for this long: sipping pace, and no jumping
SIP_PTS    = 8               ; a lucky sip (style)
HURDLE_PTS = 50              ; a hurdle hopped (run: the card's 50 A HURDLE)
COMBO_PTS  = 8               ; SIP 'N' HOP over crates or a bench: x chain x chalk (style),
                             ; + a point for every 16 BUZZ you had before the sip (the
                             ; base shows it; nobody tells you), double over a green bin
                             ; (BIG SIP 'N' HOP) or a raccoon (RACCOON RUN)
COURAGE    = 128             ; ...BUZZ this high before it: LIQUID COURAGE,
COURAGE_PTS = 4              ; ...and the base takes this much more
; the chalk: a chevron (the mark) with a chalk strip on to the hurdle. Take
; off on it and the hop pays TAKE-OFF points (style), graded by how close to
; the chevron you were, and a SIP 'N' HOP on it pays X2 (X3 DEAD ON)
CHALK_EARLY = 8              ; px before the mark that still counts as on it (X2)
CHALK_LATE = 20              ; ...and after it (the strip)
DEAD_EARLY = 2               ; DEAD ON (X3): within a frame of the mark
DEAD_LATE  = 3
TO_MAX     = 40              ; take-off points DEAD ON the chevron...
TO_ZERO    = 64              ; ...falling a point every 1.6 px to nothing this far past it

BUZZ_TIPSY = 176             ; BUZZ meter in the red: TIPSY. The cop gains on you, and a
                             ; sip now is SLOSHED (no points, chain over)
TIPSY_GAIN = $0060           ; ...this much a frame (8.8)
TIPSY_NEAR = 96              ; ...until he's this close: on screen, watching your sips
SIP_BUZZ   = 56              ; each sip; it wears off 1 every 4 frames
CHAIN_MAX  = 5

ST_RUN     = 0
ST_TRIP    = 1
ST_ESCAPE  = 2
ST_BUSTED  = 3
ST_DONE    = 4

c_dist   = ev_ram + 0
c_distf  = ev_ram + 2
c_speed  = ev_ram + 4
c_h      = ev_ram + 6        ; height above ground, 8.8
c_vy     = ev_ram + 8        ; 8.8, up is +
c_air    = ev_ram + 10
c_state  = ev_ram + 12
c_timer  = ev_ram + 14
c_sips   = ev_ram + 16       ; lucky sips (scored)
c_prog   = ev_ram + 18
c_buzz   = ev_ram + 20
c_can    = ev_ram + 22
c_gap    = ev_ram + 24       ; cop distance, 8.8
c_copspd = ev_ram + 26
c_jumps  = ev_ram + 28       ; hurdles cleared
c_popup  = ev_ram + 30
c_anim   = ev_ram + 32
c_nextsp = ev_ram + 34
c_cur    = ev_ram + 36
c_sipping = ev_ram + 38
c_amp    = ev_ram + 40
c_whistle = ev_ram + 42
c_pts    = ev_ram + 44       ; the running score (HUD PTS)
c_hold   = ev_ram + 46       ; frames since take-off
c_jclr   = ev_ram + 48       ; this jump cleared a hurdle
c_jsip   = ev_ram + 50       ; lucky sips finished during this jump
c_t      = ev_ram + 52       ; frames of running
c_chain  = ev_ram + 54       ; SIP 'N' HOP multiplier (0 = no chain)
c_combos = ev_ram + 58       ; SIP 'N' HOPs landed
c_spills = ev_ram + 60
c_taught = ev_ram + 62       ; coaching shown: 1<<type, $20 sip, $40 air sip, $80 cop
c_jcoon  = ev_ram + 200      ; this jump cleared a raccoon
c_coons  = ev_ram + 202      ; RACCOON RUNs
c_fine   = ev_ram + 204
c_best   = ev_ram + 210      ; best chain
c_quit   = ev_ram + 212      ; gave up from the pause menu
c_ppal   = ev_ram + 214
c_pend   = ev_ram + 216      ; text work for the next quiet slot: 1/6/5 popup (clear, line 1, line 2), 2/8/3/7 tally, 4 clear
c_pptr   = ev_ram + 218      ; the popup's message (3 bytes)
c_buf    = ev_ram + 224      ; 32-byte banner buffer
c_hpts   = ev_ram + 256      ; run: hurdle points
c_wasbz  = ev_ram + 264      ; the buzz before the sip that just went down
c_lock   = ev_ram + 266      ; frames after a landing before you can jump again
c_style  = ev_ram + 258      ; style points so far
c_spill  = ev_ram + 260      ; spill points lost
c_base   = ev_ram + 262      ; run points (cops_score)
c_bump   = ev_ram + 268      ; frames left up against a hurdle (0 = not)
c_bumpe  = ev_ram + 270      ; ...which one (entity offset)
c_jchalk = ev_ram + 272      ; this jump took off on the chalk
c_chalks = ev_ram + 274      ; chalk SIP 'N' HOPs
c_asip   = ev_ram + 276      ; B went down mid-air: this sip is committed
c_scram  = ev_ram + 278      ; scrambles
c_jscr   = ev_ram + 282      ; this jump is a scramble
c_waste  = ev_ram + 284      ; jumps in a row that cleared nothing
c_wind   = ev_ram + 286      ; frames left winded (bunny-hopping)
c_tipsy  = ev_ram + 288      ; 1: told them they're weaving (until the BUZZ drops)
c_plow   = ev_ram + 290      ; the popup up is coaching: a hurdle coming up clears it
c_pline2 = ev_ram + 292      ; the popup has a second line (c_buf2)
c_deads  = ev_ram + 294      ; DEAD ON take-offs
c_buf2   = ev_ram + 296      ; 32-byte second banner line
c_jbin   = ev_ram + 328      ; this jump cleared a green bin
c_pmin   = ev_ram + 330      ; frames the popup up has left before coaching may replace it
c_told   = ev_ram + 332      ; 1: the warm-up's-over line has been shown
c_drytip = ev_ram + 334      ; times we've said what a sip off the chalk would pay
c_jto    = ev_ram + 336      ; take-off points this jump (taken back if it spills)
c_jbz    = ev_ram + 338      ; the BUZZ before this jump's sip
c_brave  = ev_ram + 340      ; LIQUID COURAGE SIP 'N' HOPs
c_hchain = ev_ram + 342      ; the chain the HUD shows ($FF: redraw)
c_cansv  = ev_ram + 344      ; the runner's can colours (palette 0: 12, 13, 14), 6 bytes
c_glow   = ev_ram + 350      ; 1: the can's lit up (the BUZZ is gold)
c_hopwarn = ev_ram + 352     ; 1: the warm-up's said HOPS AT NOTHING WIND YOU once
EV_SEED  = ev_ram + 510

NUM_ENT = 10
E_TYPE  = ev_ram + 64
E_WX    = ev_ram + 84
E_WXF   = ev_ram + 104
E_V     = ev_ram + 124
E_FLAGS = ev_ram + 144       ; 1 hit, 2 counted, 4 fresh, 8 raccoon has your can, $10 bumped
E_REL   = ev_ram + 164

T_CRATES  = 1
T_BENCH   = 2
T_BIN     = 3
T_COON    = 4

.segment "HIBSS"
wob1: .res 200
wob2: .res 200

.segment "EVENTS2"
.a8
.i16

ev_cops:
    phb
    phk
    plb
    jsr cops_init
    jsr cops_draw
    jsl event_card
    jsr hud_static
    jsr cops_hud
    jsl event_countdown
    lda #SONG_CHASE
    jsl music_play
@loop:
    jsl wait_frame
    lda ev_giveup
    beq @play
    ; gave up from the pause menu: a failed run (unless it's already decided)
    lda c_state
    cmp #ST_ESCAPE
    bcs @end
    lda #$01
    sta c_quit
    bra @end
@play:
    jsr cops_update
    jsr cops_draw
    jsr wobble
    ; text is slow: a callout or the tally takes the HUD's turn
    lda c_pend
    beq @hud
    jsr pend_draw
    bra @chk
@hud:
    jsr cops_hud
@chk:
    lda c_state
    cmp #ST_DONE
    bne @loop
@end:
    jsl music_stop
    ; keep the sunset sky (HDMA ch 7) under the score card, drop the wobble
    lda hdma_sh
    and #$80
    sta hdma_sh
    jsr cops_score
    jsr panel_clear
    jsl score_card
    jsl hdma_off
    plb
    rtl

.include "evcommon.inc"

cops_init:
    jsl ppu_off
    jsl set_mode1_defaults
    jsl load_text_gfx
    VLOAD VRAM_BGTILES, cops_tiles, (cops_bg1 - cops_tiles)
    VLOAD VRAM_BG1MAP, cops_bg1, 4096
    VLOAD VRAM_BG2MAP, cops_bg2, 4096
    PLOAD 32, cops_pal, 96
    VLOAD VRAM_OBJTILES, cops_spr, (cops_spr_pal - cops_spr)
    VLOAD RUN_VRAM, cops_run_spr, (cops_run_end - cops_run_spr)
    PLOAD 144, cops_spr_pal, 32
    lda cur_player
    ldy #$0000
    jsl player_palette
    ; a player in yellow gets the cop in his navy jacket, so they never blend
    lda cur_player
    jsl player_offset
    lda players+PL_SPONSOR,x
    TAXB
    lda cop_alt_for,x
    beq @std
    A16
    lda cop_alt_pal
    sta pal_buf+(144+6)*2
    lda cop_alt_pal+2
    sta pal_buf+(144+7)*2
    lda cop_alt_pal+4
    sta pal_buf+(144+8)*2
    A8
    lda #$01
    sta pal_dirty
@std:
    lda #$17
    sta tm_sh
    stz txt_bg
    LDPTR0 cops_sky
    jsr ev_sky
    jsr ev_clear
    jsl cops_glow_init
    ldx #RUN_SPD
    stx c_speed
    ldx #(GAP_START*256)
    stx c_gap
    ldx #COP_WARM
    stx c_copspd
    ldx #6
    stx c_can
    ldx #$3E65                  ; the course: C B K R C K B C R C K R C B R C B R C K C B C K K C
    stx EV_SEED
    ldx #220
    stx c_nextsp
    ; wobble HDMA tables: channel 6 -> BG1HOFS, channel 5 -> BG2HOFS (mode 2)
    lda #$02
    sta $4360
    sta $4350
    lda #<BG1HOFS
    sta $4361
    lda #<BG2HOFS
    sta $4351
    ldx #.loword(wob1)
    stx $4362
    ldx #.loword(wob2)
    stx $4352
    lda #^wob1
    sta $4364
    sta $4354
    rts

; sponsors whose jersey is yellow (Honest Ed's, Mr. Sub): navy cop jacket
cop_alt_for: .byte 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0
cop_alt_pal: .word $6145, $40C3, $7FFF      ; jacket, jacket shade, stripe

; ------------------------------------------------------------------
cops_update:
    lda c_state
    cmp #ST_RUN
    beq @run
    cmp #ST_TRIP
    beq @trip
    cmp #ST_ESCAPE
    beq @escape
    ; busted: freeze on the tally, then done
    A16
    stz c_speed
    dec c_timer
    A8
    bne @x
    lda #ST_DONE
    sta c_state
@x:
    rts
@escape:
    stz c_sipping
    ldx #RUN_SPD
    stx c_speed
    A16
    dec c_timer
    A8
    bne @move
    lda #ST_DONE
    sta c_state
    rts
@trip:
    A16
    dec c_timer
    A8
    bne @tgt
    lda #ST_RUN
    sta c_state
    bra @tgt
@run:
    jsr cops_input
    lda c_bump
    beq @nbm
    dec c_bump
@nbm:
    lda c_wind
    beq @tgt
    dec c_wind
@tgt:
    jsr approach_speed
    jsr running_clock
@move:
    ; distance
    A16
    lda c_distf
    and #$00FF
    clc
    adc c_speed
    pha
    and #$00FF
    sta c_distf
    pla
    xba
    and #$00FF
    clc
    adc c_dist
    sta c_dist
    A8
    jsr jump_physics
    jsr cop_chase
    jsr spawn_ahead
    jsr ents_update
    ; buzz wears off slowly
    lda frame
    and #$03
    bne @nb
    lda c_buzz
    beq @nb
    dec c_buzz
@nb:
    lda c_pmin
    beq @npm
    dec c_pmin
@npm:
    A16
    lda c_popup
    beq @np
    dec c_popup
    bne @np
    A8
    lda c_pend                  ; (unless the tally's on its way)
    cmp #2
    beq @np8
    cmp #3
    beq @np8
    cmp #6                      ; (or a callout's half drawn)
    beq @np8
    cmp #7
    beq @np8
    cmp #8
    beq @np8
    lda #4
    sta c_pend
@np8:
    A16
@np:
    ; escaped?
    lda c_state
    and #$00FF
    cmp #ST_ESCAPE
    bcs @ne
    lda c_dist
    cmp #COURSE_LEN
    bcc @ne
    A8
    lda #ST_ESCAPE
    sta c_state
    stz c_sipping
    stz c_asip
    stz c_bump
    ldx #170
    stx c_timer
    SFX SFX_CHEER
    jsr tally_req
    A16
@ne:
    A8
    rts

; the clock while you're running: warm-up hints, and the BUZZ warning
running_clock:
    A16
    inc c_t
    A8
    ; coaching up and a jump coming: take it down, so it never talks over one
    lda c_plow
    beq @nl
    lda c_popup
    ora c_popup+1
    beq @nl
    jsr next_mark
    A16
    lda tmp0
    cmp #70
    A8
    bcs @nl
    stz c_plow
    ldx #$0001
    stx c_popup
@nl:
    ; stopped dead against a hurdle: STUCK! TAP A TO SCRAMBLE is up, and
    ; nothing talks over it
    lda c_bump
    jne @x
    ; the warm-up's over: say so (once the panel's free)
    lda c_told
    bne @nw
    A16
    lda c_t
    cmp #WARM_T
    A8
    bcc @nw
    lda c_pmin
    bne @nw
    inc c_told
    LDPTR0 str_warm
    lda #TP_ORANGE
    ldx #80
    jmp popup_t
@nw:
    ; weaving: once each time the BUZZ climbs into the red (on your feet,
    ; once the panel's free: never under a SIP 'N' HOP's banner)
    lda c_buzz
    cmp #BUZZ_TIPSY
    bcs @tip
    cmp #(BUZZ_TIPSY - 32)
    bcs @nt
    stz c_tipsy
    bra @nt
@tip:
    lda c_tipsy
    bne @nt
    lda c_pmin
    ora c_state
    ora c_air
    bne @nt
    inc c_tipsy
    LDPTR0 str_tipsy
    lda #TP_ORANGE
    ldx #80
    jmp popup_t
@nt:
    lda c_popup
    ora c_popup+1
    jne @x
    lda c_state
    jne @x
    lda c_air
    jne @x
    ; nobody sipped yet, and the cop's well back: tell them
    lda c_taught
    and #$20
    bne @h2
    lda c_sips
    beq @ns
    lda c_taught                ; they worked it out themselves
    ora #$20
    sta c_taught
    bra @h2
@ns:
    A16
    lda c_t
    cmp #200
    A8
    bcc @x
    lda c_gap+1
    cmp #(COP_SEEN + 20)
    bcc @x
    ; ...and only with the road clear for the whole of the hint
    jsr next_mark
    A16
    lda tmp0
    cmp #220
    A8
    bcc @x
    lda c_taught
    ora #$20
    sta c_taught
    LDPTR1 str_c_sip2
    jsr set_line2
    LDPTR0 str_c_sip
    lda #TP_YELLOW
    ldx #100
    jsr popup_low
    lda #$01
    sta c_pline2
    rts
@h2:
    ; first lucky sip went down: now do it in the air
    lda c_taught
    and #$40
    bne @x
    lda c_sips
    beq @x
    jsr next_mark
    A16
    lda tmp0
    cmp #120
    A8
    bcc @x
    lda c_taught
    ora #$40
    sta c_taught
    LDPTR0 str_c_air
    lda #TP_YELLOW
    ldx #100
    jmp popup_low
@x:
    rts

; tmp0 (16-bit) = px from the runner to the nearest chalk mark ahead: live
; hurdles (0 once you're past the mark), and the next one still to come
next_mark:
    A16
    lda c_nextsp
    cmp #$FFFF
    beq @none
    clc
    adc #(260 - 54)             ; its mark is at least this far along
    sec
    sbc c_dist
    bpl @st
    lda #$0000
    bra @st
@none:
    lda #$7FFF
@st:
    sta tmp0
    A8
    ldx #$0000
@e:
    lda E_TYPE,x
    beq @n
    lda E_FLAGS,x
    and #$1B
    bne @n
    lda E_TYPE,x
    TAYB
    lda mk_d,y
    A16
    and #$00FF
    sta tmp2
    lda E_WX,x
    sec
    sbc c_dist
    cmp #($10000 - 16)
    bcs @on                     ; just about level with it
    cmp #$8000
    bcs @n16                    ; behind you
    sec
    sbc tmp2
    bpl @d
@on:
    lda #$0000
@d:
    cmp tmp0
    bcs @n16
    sta tmp0
@n16:
    A8
@n:
    inx
    inx
    cpx #(NUM_ENT*2)
    bne @e
    rts


cops_input:
    stz c_sipping
    lda c_air
    bne @air
    ; winded: no legs left to jump with
    lda c_wind
    bne @sip
    ; up against a hurdle: A scrambles you over it
    lda c_bump
    beq @nb
    A16
    lda pad_new
    and #PAD_A
    A8
    beq @sip
    jsr scramble
    bra @sip
@nb:
    ; on the ground: A jumps (once you've found your feet after a landing)
    lda c_lock
    beq @free
    dec c_lock
    bra @sip
@free:
    A16
    lda pad_new
    and #PAD_A
    A8
    beq @sip
    jsr take_off
    jsr chalk_check
    bra @sip
@air:
    ; let go of A early (after a minimum hop) for a short hop
    A16
    inc c_hold
    lda pad
    and #PAD_A
    bne @hold
    lda c_hold
    cmp #MIN_HOP
    bcc @hold
    lda c_vy
    bmi @hold
    cmp #HOP_CUT
    bcc @hold
    lda #HOP_CUT
    sta c_vy
@hold:
    A8
@sip:
    ; hold B: sip (on the ground or mid-air), which slows you down on the
    ; ground. Mid-air one press commits you to one sip: it goes down twice as
    ; fast and finishes even if you let go (at the latest as you land).
    lda c_asip
    cmp #2
    beq @x                      ; had this jump's sip
    A16
    lda pad
    and #PAD_B
    A8
    beq @nob
    lda c_air
    beq @go
    lda #$01
    sta c_asip
    bra @go
@nob:
    lda c_asip
    beq @x
@go:
    lda #$01
    sta c_sipping
    lda #3
    ldx c_air
    beq @rate
    lda #6
@rate:
    clc
    adc c_prog
    sta c_prog
    cmp #60
    bcc @x
    stz c_prog
    lda c_air
    beq @gs
    lda #2                      ; that's the one for this jump
@gs:
    sta c_asip
    jsr sip_done
@x:
    rts

; A on your feet: up you go
take_off:
    lda #$01
    sta c_air
    ldx #JUMP_V
    stx c_vy
    ldx #$0000
    stx c_hold
    stx c_jclr
    stx c_jsip
    stx c_jcoon
    stx c_jchalk
    stx c_jbin
    stx c_bump
    stx c_jto
    stx c_jbz
    stz c_asip
    stz c_jscr
    SFX SFX_JUMP
    rts

; A while you're up against a hurdle: over it you go, the hard way. No spill,
; and it's a hurdle got over (the run's 50, and HURDLES counts it: the screen
; told you to, so doing it pays more than mashing), but no take-off points,
; no chalk, and the chain's gone.
scramble:
    ldx c_bumpe
    lda E_FLAGS,x
    ora #$13                    ; out of play: never hits, never scores
    sta E_FLAGS,x
    lda E_TYPE,x
    cmp #T_COON
    bne @nc
    A16
    lda #($10000 - $00A0)       ; the raccoon carries on his way
    sta E_V,x
    A8
@nc:
    jsr take_off
    ldx #(RUN_SPD / 2)          ; you vault it with a bit of way on
    stx c_speed
    lda #$01
    sta c_jscr
    stz c_chain
    A16
    inc c_scram
    inc c_jumps
    lda c_hpts
    clc
    adc #HURDLE_PTS
    sta c_hpts
    A8
    LDPTR1 str_scram2
    jsr set_line2
    LDPTR0 str_scram
    lda #TP_ORANGE
    ldx #80
    jmp popup_t2

; copy the string at ptr1 into the banner's second line (c_buf2)
set_line2:
    ldy #$0000
@l:
    lda [ptr1],y
    sta c_buf2,y
    beq @x
    iny
    cpy #31
    bne @l
    lda #$00
    sta c_buf2,y
@x:
    rts

; just took off: is the next hurdle's chalk mark under your feet?
chalk_check:
    A16
    lda #$7FFF
    sta tmp0                    ; nearest hurdle ahead (px)
    stz tmp1                    ; ...its kind
    A8
    ldx #$0000
@e:
    lda E_TYPE,x
    beq @n
    lda E_FLAGS,x
    and #$1B
    bne @n
    A16
    lda E_WX,x
    sec
    sbc c_dist
    bmi @n16
    cmp tmp0
    bcs @n16
    sta tmp0
    A8
    lda E_TYPE,x
    sta tmp1
    bra @n
@n16:
    A8
@n:
    inx
    inx
    cpx #(NUM_ENT*2)
    bne @e
    A16
    lda tmp0
    cmp #$7FFF
    A8
    jeq @x
    ; e = px short of the mark (+ = early, - = past it): on the chalk if
    ; -CHALK_LATE .. +CHALK_EARLY, DEAD ON if -DEAD_LATE .. +DEAD_EARLY. Take-off
    ; points (to_tbl) for anything from CHALK_EARLY short to TO_ZERO past
    ldy tmp1
    lda mk_d,y
    A16
    and #$00FF
    eor #$FFFF
    sec
    adc tmp0                    ; e
    sta tmp2
    bmi @late
    cmp #(CHALK_EARLY + 1)
    jcs @x16                    ; too early: off the chalk
    bra @abs
@late:
    eor #$FFFF
    inc a                       ; |e|
    cmp #TO_ZERO
    jcs @x16                    ; too late for any
@abs:
    tax
    lda f:to_tbl,x
    and #$00FF
    jeq @x16
    sta c_jto
    clc
    adc c_style
    sta c_style
    ; the tier
    lda tmp2
    clc
    adc #DEAD_LATE
    cmp #(DEAD_LATE + DEAD_EARLY + 1)
    bcc @dead
    lda tmp2
    clc
    adc #CHALK_LATE
    cmp #(CHALK_LATE + CHALK_EARLY + 1)
    A8
    bcs @close
    lda #$01
    sta c_jchalk
    LDPTR0 str_chalk
    bra @say
@close:
    LDPTR0 str_close
    bra @say
@dead:
    A8
    lda #$02
    sta c_jchalk
    A16
    inc c_deads
    A8
    LDPTR0 str_dead
@say:
    ; "ON THE CHALK! +24"
    ldy #$0000
    jsr buf_str
    LDPTR0 str_plus
    jsr buf_str
    A16
    lda c_jto
    A8
    jsr buf_num
    lda #$00
    sta c_buf,y
    jsr buf_ptr
    lda #TP_GREEN
    ldx c_jchalk
    bne @g
    lda #TP_YELLOW
@g:
    ldx #40
    jmp popup_t
@x16:
    A8
@x:
    rts

; take-off points by px from the chevron (0 .. TO_ZERO-1): TO_MAX right on
; it, down a point every 1.6 px (so every px of precision shows in the score)
to_tbl:
.repeat TO_ZERO, I
    .byte (TO_MAX * (TO_ZERO - I) + TO_ZERO / 2) / TO_ZERO
.endrepeat

; a sip went down: buzz, a fresh can every 6, and points if the cop missed it
sip_done:
    SFX SFX_SIP
    lda c_buzz
    sta c_wasbz
    clc
    adc #SIP_BUZZ
    bcc @b
    lda #$FF
@b:
    sta c_buzz
    dec c_can
    bne @can
    lda #6
    sta c_can
    ; a fresh can is only news on your feet: mid-air the SIP 'N' HOP's banner
    ; is on its way, and the two together read as one reward
    lda c_air
    bne @can
    LDPTR0 str_crack
    lda #TP_WHITE
    ldx #40
    jsr popup_t
@can:
    ; on the ground next to a green bin? a raccoon pops out and takes the can
    lda c_air
    bne @look
    jsr bin_near
    bcc @look
    jmp coon_steal
@look:
    ; BUZZ in the red: SLOSHED. No points, no SIP 'N' HOP, and the chain's over
    lda c_wasbz
    cmp #BUZZ_TIPSY
    bcc @look2
    stz c_chain
    LDPTR0 str_buzzed
    lda #TP_PINK
    ldx #70
    jmp popup_t
@look2:
    A16
    lda c_gap
    cmp #(COP_SEEN*256)
    bcs @lucky
    ; he saw that: no points, the chain's gone, and he puts his head down
    sec
    sbc #(SEEN_LUNGE*256)
    bcs @g
    lda #$0000
@g:
    sta c_gap
    A8
    stz c_chain
    SFX SFX_WHISTLE
    LDPTR0 str_seen
    lda #TP_RED
    ldx #60
    jmp popup_t
@lucky:
    .a16
    inc c_sips
    lda c_style
    clc
    adc #SIP_PTS
    sta c_style
    A8
    lda c_air
    beq @x
    inc c_jsip
    lda c_wasbz
    sta c_jbz
@x:
    rts


; carry set (and X = the bin) if a green bin is within reach of the runner
bin_near:
    ldx #$0000
@e:
    lda E_TYPE,x
    cmp #T_BIN
    bne @n
    A16
    lda E_REL,x
    clc
    adc #24
    cmp #72                     ; -24 .. +47 px
    A8
    bcc @y
@n:
    inx
    inx
    cpx #(NUM_ENT*2)
    bne @e
    clc
    rts
@y:
    sec
    rts

; X = the green bin: a raccoon jumps out of it with your can
coon_steal:
    A16
    lda E_WX,x
    sta tmp1
    A8
    stz c_prog
    lda #6
    sta c_can
    stz c_chain
    jsr ev_alloc
    bcs @full
    lda #T_COON
    sta E_TYPE,x
    stz E_TYPE+1,x
    A16
    lda tmp1
    sta E_WX,x
    stz E_WXF,x
    lda #$0300                  ; legging it up the street, faster than you
    sta E_V,x
    lda #$000B                  ; already hit + counted: he's not a hurdle
    sta E_FLAGS,x
    stz E_REL,x
    A8
@full:
    SFX SFX_BARK
    LDPTR0 str_binc
    lda #TP_ORANGE
    ldx #70
    jmp popup_t


approach_speed:
    ; up against a hurdle: stopped dead
    lda c_bump
    beq @go
    ldx #$0000
    stx c_speed
    rts
@go:
    A16
    lda #RUN_SPD
    ldx c_wind                  ; winded: sipping pace
    bne @w
    ldx c_sipping
    beq @t
@w:
    ldx c_air                   ; mid-air you keep your momentum
    bne @t
    lda #SIP_SPD
@t:
    ldx c_state
    cpx #ST_TRIP
    bne @t2
    lda #TRIP_SPD
@t2:
    sta tmp0
    lda c_speed
    cmp tmp0
    beq @x
    bcs @down
    clc
    adc #$0010
    cmp tmp0
    bcc @s
    lda tmp0
    bra @s
@down:
    sec
    sbc #$0018
    cmp tmp0
    bcs @s
    lda tmp0
@s:
    sta c_speed
@x:
    A8
    rts

jump_physics:
    lda c_air
    jeq @x
    A16
    lda c_vy
    sec
    sbc #GRAVITY
    sta c_vy
    clc
    adc c_h
    sta c_h
    jpl @up
    stz c_h
    stz c_vy
    A8
    ; a sip you committed to mid-air goes down as you land (still an air sip)
    lda c_asip
    stz c_asip
    cmp #1
    bne @land
    lda c_state
    cmp #ST_RUN
    bne @land
    lda c_prog
    beq @land
    stz c_prog
    jsr sip_done
@land:
    stz c_air
    lda #JUMP_LOCK
    sta c_lock
    SFX SFX_STEP
    ; landed: sipped over a hurdle on the way?
    lda c_state
    cmp #ST_RUN
    jne @x
    lda c_jclr
    ora c_jscr
    bne @used
    ; a jump over nothing: a few of those in a row and you're out of puff
    inc c_waste
    lda c_waste
    cmp #WASTE_MAX
    jcc @x
    stz c_waste
    ; in the warm-up the first time it's only a word of advice; after that
    ; it does what the word said
    A16
    lda c_t
    cmp #WARM_T
    A8
    bcs @wnd
    lda c_hopwarn
    bne @wnd
    inc c_hopwarn
    LDPTR1 str_hop2
    jsr set_line2
    LDPTR0 str_hop1
    lda #TP_ORANGE
    ldx #90
    jmp popup_t2
@wnd:
    lda #WIND_T
    sta c_wind
    LDPTR0 str_wind
    lda #TP_ORANGE
    ldx #90
    jmp popup_t
@used:
    stz c_waste
    lda c_jclr
    jeq @x
    lda c_jsip
    beq @dry
    jmp sip_n_hop
@dry:
    ; hopped a hurdle without a sip. On the chalk (or a bit late: any take-off
    ; that paid) the chain holds (it doesn't grow); way off it, it's over
    lda c_jto
    beq @off
    lda c_chain
    beq @tip
    LDPTR0 str_held
    lda c_jchalk
    bne @hl
    LDPTR0 str_held2
@hl:
    lda #TP_GREEN
    ldx #50
    jmp popup_t
@tip:
    ; no chain yet: say what a sip would have paid (the first few times)
    lda c_jchalk
    beq @x
    lda c_drytip
    cmp #3
    bcs @x
    inc c_drytip
    lda c_jchalk
    cmp #2
    beq @tipd
    LDPTR0 str_c_dry
    bra @tp
@tipd:
    LDPTR0 str_c_dry3
@tp:
    lda #TP_YELLOW
    ldx #70
    jmp popup_t
@off:
    lda c_chain
    stz c_chain
    cmp #2
    bcc @x
    LDPTR0 str_c_chain
    lda #TP_ORANGE
    ldx #70
    jmp popup_t
@up:
    A8
@x:
    rts

; a SIP 'N' HOP landed: chain it, score it, shout about it.
; Pays base (8, or 16 over a bin or a raccoon) x chain (X1..X5) x chalk (X1
; off it, X2 on it, X3 DEAD ON), and the banner shows that sum on its second
; line: "RACCOON RUN! +240" over "16 X5 CHAIN X3 DEAD ON".
sip_n_hop:
    lda c_chain
    cmp #CHAIN_MAX
    bcs @m
    inc c_chain
@m:
    lda c_chain
    cmp c_best
    bcc @b
    sta c_best
@b:
    A16
    inc c_combos
    A8
    lda c_jchalk
    beq @nch
    A16
    inc c_chalks
    A8
@nch:
    ; the base: 8 + BUZZ/16 (+ COURAGE_PTS from 128 up: LIQUID COURAGE, and
    ; the sip on top of it takes you into the red: TIPSY, the cop closes in,
    ; and your next sips are SLOSHED until it wears off), doubled for the big
    ; ones
    lda c_jbz
    cmp #COURAGE
    lda #0
    bcc @nc
    lda #COURAGE_PTS
@nc:
    sta tmp4
    lda c_jbz
    lsr a
    lsr a
    lsr a
    lsr a
    clc
    adc #COMBO_PTS
    adc tmp4
    ldx c_jcoon
    bne @big
    ldx c_jbin
    beq @bs
@big:
    asl a
@bs:
    sta tmp4                    ; base
    ; chain x chalk (<= 15), then x base (<= 44: 660)
    lda c_jchalk
    inc a
    sta WRMPYA
    lda c_chain
    sta WRMPYB
    nop
    nop
    nop
    nop
    lda RDMPYL
    sta WRMPYA
    lda tmp4
    sta WRMPYB
    nop
    nop
    nop
    nop
    A16
    lda RDMPYL
    sta tmp3
    clc
    adc c_style
    sta c_style
    A8
    SFX SFX_COIN
    ; line 1: "SIP 'N' HOP! +120"
    ldy #$0000
    lda c_jbz
    cmp #COURAGE
    bcc @sn0
    A16
    inc c_brave
    A8
    jsl trick_seen
    LDPTR0 str_brave
    bra @pre
@sn0:
    lda c_jcoon
    beq @sn
    LDPTR0 str_rrun
    bra @pre
@sn:
    lda c_jbin
    beq @sn2
    LDPTR0 str_bsnh
    bra @pre
@sn2:
    LDPTR0 str_snh
@pre:
    jsr buf_str
    LDPTR0 str_plus
    jsr buf_str
    A16
    lda tmp3
    A8
    jsr buf_num
    lda #$00
    sta c_buf,y
    ; line 2, when there's a sum to show: "20 X5 CHAIN X3 DEAD ON" (the parts
    ; that multiply: no "X1 CHAIN", and nothing at all for a plain base)
    jsr buf_ptr
    lda c_jbz
    cmp #COURAGE
    bcs @two
    lda c_chain
    cmp #2
    bcs @two
    lda c_jchalk
    bne @two
    lda #TP_GREEN
    ldx #70
    jmp popup_t
@two:
    ldy #(c_buf2 - c_buf)
    ; off a gold BUZZ the base says so: "GOLD 21 X3 CHAIN"
    lda c_jbz
    cmp #COURAGE
    bcc @ng
    LDPTR0 str_gold
    jsr buf_str
@ng:
    A16
    lda tmp4
    and #$00FF
    A8
    jsr buf_num
    lda c_chain
    cmp #2
    bcc @l1
    lda #' '
    jsr buf_ch
    lda #'X'
    jsr buf_ch
    lda c_chain
    clc
    adc #'0'
    jsr buf_ch
    LDPTR0 str_chn
    jsr buf_str
@l1:
    lda c_jchalk
    beq @l2
    cmp #2
    beq @l2d
    LDPTR0 str_x2c
    bra @l2s
@l2d:
    LDPTR0 str_x3d
@l2s:
    jsr buf_str
@l2:
    lda #$00
    sta c_buf,y
    jsr buf_ptr
    lda #TP_GREEN
    ldx #70
    jmp popup_t2


; banner buffer helpers (Y = write index)
buf_str:
    phy
    sty tmp2
    ldy #$0000
@l:
    lda [ptr0],y
    beq @d
    phy
    ldy tmp2
    sta c_buf,y
    iny
    sty tmp2
    ply
    iny
    bra @l
@d:
    ply
    ldy tmp2
    rts

buf_ch:
    sta c_buf,y
    iny
    rts

; A16 value on entry (A8 call), appended in decimal without leading zeros
buf_num:
    A16
    sta tmp1
    A8
    ldx #$0000
@div:
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
    lda RDMPYL
    pha
    inx
    A16
    lda RDDIVL
    sta tmp1
    A8
    bne @div
    lda tmp1+1
    bne @div
@out:
    pla
    clc
    adc #'0'
    sta c_buf,y
    iny
    dex
    bne @out
    rts

buf_ptr:
    A16
    lda #.loword(c_buf)
    sta ptr0
    A8
    lda #^c_buf
    sta ptr0+2
    rts

; the bike cop closes in at a steady (slowly rising) speed
cop_chase:
    lda c_state
    cmp #ST_ESCAPE
    bcc @go
    rts
@go:
    ; after the warm-up he picks up speed over 4 s (from COP_WARM to
    ; COP_START), then 1/256 px a frame faster every 64 frames
    A16
    lda c_t
    cmp #WARM_T
    bcc @warm
    lda c_copspd
    cmp #COP_START
    bcs @ramp
    lda c_t
    and #$0003
    bne @warm
    inc c_copspd
    bra @warm
@ramp:
    lda c_t
    and #COP_RAMP
    bne @warm
    inc c_copspd
@warm:
    lda c_gap
    clc
    adc c_speed
    sec
    sbc c_copspd
    bcc @z
    ; weaving (BUZZ in the red): he gains on you that bit more, until he's
    ; close enough to watch you (on screen: your sips stop paying until you
    ; sober up and pull away; he can't bust you for being tipsy alone)
    sta tmp0
    A8
    lda c_buzz
    cmp #BUZZ_TIPSY
    A16
    lda tmp0
    bcc @p
    cmp #(TIPSY_NEAR*256)
    bcc @p
    sec
    sbc #TIPSY_GAIN
    cmp #(TIPSY_NEAR*256)
    bcs @p
    lda #(TIPSY_NEAR*256)
    bra @p
@z:
    lda #$0000
@p:
    cmp #(GAP_MAX*256)
    bcc @c
    lda #(GAP_MAX*256)
@c:
    sta c_gap
    ; in the warm-up he hangs back
    ldx c_t
    cpx #WARM_T
    bcs @nw
    cmp #(GAP_WARM*256)
    bcs @nw
    lda #(GAP_WARM*256)
    sta c_gap
@nw:
    cmp #(GAP_BUST*256)
    bcs @free
    A8
    ; busted
    lda #ST_BUSTED
    sta c_state
    stz c_sipping
    ldx #170
    stx c_timer
    SFX SFX_WHISTLE
    jmp tally_req
@free:
    .a16
    cmp #(COP_SEEN*256)
    bcs @far
    ; first time he's on screen: say so (not over STUCK!: that waits)
    A8
    lda c_bump
    bne @nh
    lda c_taught
    bmi @nh
    ora #$80
    sta c_taught
    LDPTR0 str_c_cop
    lda #TP_ORANGE
    ldx #90
    jsr popup_low
@nh:
    A16
    lda c_gap
@far:
    cmp #(56*256)
    A8
    bcs @x
    ; whistle when close
    A16
    dec c_whistle
    bpl @x16
    lda #45
    sta c_whistle
    A8
    SFX SFX_WHISTLE
    rts
@x16:
    A8
@x:
    rts

; ------------------------------------------------------------------
spawn_ahead:
@l:
    A16
    lda c_nextsp
    cmp #$FFFF
    beq @d
    lda c_dist
    clc
    adc #40
    cmp c_nextsp
    bcc @d
    A8
    jsr spawn_one
    bra @l
@d:
    A8
    rts

spawn_one:
    A16
    lda c_nextsp
    cmp #(COURSE_LEN - 100)
    A8
    bcc @go
    ldx #$FFFF
    stx c_nextsp
    rts
@go:
    jsr ev_alloc
    bcs @gap
    lda #13
    jsr ev_range
    TAYB
    lda kinds,y
    ; the first stretch is a warm-up: no bins (the big jump) yet
    cmp #T_BIN
    bne @k
    A16
    lda c_nextsp
    cmp #900
    A8
    bcs @kb
    lda #T_CRATES
    bra @k
@kb:
    lda #T_BIN
@k:
    sta E_TYPE,x
    stz E_TYPE+1,x
    A16
    lda c_nextsp
    clc
    adc #260
    sta E_WX,x
    stz E_WXF,x
    stz E_V,x
    lda #$0004
    sta E_FLAGS,x
    stz E_REL,x
    A8
    lda E_TYPE,x
    cmp #T_COON
    bne @gap
    A16
    lda #($10000 - $00A0)
    sta E_V,x
    A8
@gap:
    ; spacing: 170-270 px, plus up to 110 px of breathing room early on
    lda #100
    jsr ev_range
    A16
    and #$00FF
    clc
    adc #170
    sta tmp0
    lda c_dist
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    cmp #110
    bcc @t
    lda #110
@t:
    eor #$FFFF
    sec
    adc #110                    ; 110 - dist/64
    clc
    adc tmp0
    clc
    adc c_nextsp
    sta c_nextsp
    A8
    rts

kinds: .byte T_CRATES, T_CRATES, T_CRATES, T_BENCH, T_BENCH, T_BENCH, T_BIN, T_BIN, T_BIN, T_COON, T_COON, T_COON, T_CRATES

; hit box: half width (a little inside the sprite), height (a tap-hop clears
; all but the bin, whose lid is out of a hop's reach)
ob_hw: .byte 0, 10, 10, 8, 8
ob_h:  .byte 0, 12, 10, 30, 9

ents_update:
    ldx #$0000
@e:
    lda E_TYPE,x
    bne @live
    jmp @next
@live:
    stx c_cur
    A16
    lda E_V,x
    beq @nm
    clc
    adc E_WXF,x
    pha
    and #$00FF
    sta E_WXF,x
    pla
    xba
    and #$00FF
    cmp #$0080
    bcc @p
    ora #$FF00
@p:
    clc
    adc E_WX,x
    sta E_WX,x
@nm:
    lda E_WX,x
    sec
    sbc c_dist
    sta tmp0
    cmp #($10000 - 140)
    bcs @ok
    cmp #400
    bcc @ok
    stz E_TYPE,x
    A8
    jmp @next
@ok:
    A8
    ; only while running (no free hurdles on the victory lap)
    lda c_state
    cmp #ST_ESCAPE
    bcc @live2
    jmp @store
@live2:
    ; first of its kind coming on screen: coach it (once the callout up has
    ; been read: it's 200 px out, so there's time)
    lda c_pmin
    ora c_bump
    bne @nocoach
    lda E_FLAGS,x
    and #$03
    bne @nocoach
    lda E_TYPE,x
    TAYB
    lda coach_bit,y
    and c_taught
    bne @nocoach
    lda tmp0+1
    bne @nocoach
    lda tmp0
    cmp #200
    bcs @nocoach
    lda coach_bit,y
    ora c_taught
    sta c_taught
    tya
    asl a
    TAXB
    A16
    lda f:coach_ptrs,x
    sta ptr0
    A8
    lda #^coach_ptrs
    sta ptr0+2
    ldx c_cur
    lda E_TYPE,x
    cmp #T_BIN
    lda #TP_ORANGE
    bcs @cb
    lda #TP_YELLOW
@cb:
    ldx #100
    jsr popup_t
    ldx c_cur
@nocoach:
    ; passed it cleanly?
    lda E_FLAGS,x
    and #$07
    bne @nopass
    lda E_REL+1,x
    bmi @nopass
    lda tmp0+1
    bpl @nopass
    lda E_FLAGS,x
    ora #$02
    sta E_FLAGS,x
    A16
    inc c_jumps
    lda c_hpts
    clc
    adc #HURDLE_PTS
    sta c_hpts
    A8
    lda c_air
    beq @nopass
    sta c_jclr
    lda E_TYPE,x
    cmp #T_BIN
    bne @npb
    sta c_jbin
@npb:
    cmp #T_COON
    bne @nopass
    sta c_jcoon
@nopass:
    ; hit?
    lda E_FLAGS,x
    and #$01
    jne @store
    ; a late take-off still makes it while you're rising and not yet past its
    ; middle: a press that lands a few frames late is a close one, not a spill
    lda c_air
    beq @gnd
    lda c_vy+1
    bmi @gnd
    lda tmp0+1
    jpl @store
@gnd:
    lda E_TYPE,x
    TAYB
    lda tmp0+1
    bne @far
    lda tmp0
    bra @dx
@far:
    cmp #$FF
    jne @store
    lda tmp0
    eor #$FF
    inc a
@dx:
    cmp ob_hw,y
    bcs @store
    ; feet below the top of it?
    lda c_h+1
    cmp ob_h,y
    bcs @store
    lda c_air
    bne @hit
    ; on your feet: you stop dead against it, and A gets you over (scramble).
    ; Not straight off a landing, though: bunny-hopping into it is a spill
    lda c_lock
    bne @hit
    lda E_FLAGS,x
    and #$10
    bne @against
    lda E_FLAGS,x
    ora #$10
    sta E_FLAGS,x
    stx c_bumpe
    A16
    lda c_t
    cmp #WARM_T
    A8
    lda #BUMP_T
    bcs @bt
    lda #BUMP_WARM              ; the warm-up gives you longer to read it
@bt:
    sta c_bump
    lda E_TYPE,x
    cmp #T_COON
    bne @bs
    A16
    stz E_V,x                   ; a raccoon stops too: nose to nose
    A8
@bs:
    SFX SFX_STEP
    ; say what to do, at once: it outranks any coaching
    LDPTR0 str_stuck
    lda #TP_ORANGE
    ldx #BUMP_WARM
    jsr popup_t
    ldx c_cur
    bra @store
@against:
    lda c_bump
    bne @store
@hit:
    lda E_FLAGS,x
    ora #$01
    sta E_FLAGS,x
    jsr trip
    ldx c_cur
@store:
    A16
    lda tmp0
    sta E_REL,x
    lda E_FLAGS,x
    and #$FFFB
    sta E_FLAGS,x
    A8
@next:
    inx
    inx
    cpx #(NUM_ENT*2)
    jne @e
    rts

coach_bit:  .byte 0, $02, $04, $08, $10

; X = the entity you ran into
trip:
    lda #ST_TRIP
    sta c_state
    ldx #TRIP_TIME
    stx c_timer
    stz c_prog
    stz c_sipping
    stz c_jclr
    stz c_jsip
    stz c_jcoon
    stz c_jchalk
    stz c_jbin
    stz c_asip
    stz c_bump
    stz c_chain
    ; a take-off that ends in a spill pays nothing
    lda c_air
    beq @ta
    A16
    lda c_style
    sec
    sbc c_jto
    sta c_style
    stz c_jto
    A8
@ta:
    ; spilled some: the cop gains on you (and the no-spill bonus is gone)
    A16
    inc c_spills
    lda c_gap
    sec
    sbc #(TRIP_LUNGE*256)
    bcs @g
    lda #$0000
@g:
    sta c_gap
    A8
    SFX SFX_CRASH
    ldx c_cur
    lda E_TYPE,x
    cmp #T_COON
    bne @oof
    ; the raccoon makes off with your can
    lda E_FLAGS,x
    ora #$08
    sta E_FLAGS,x
    A16
    lda #$0300
    sta E_V,x
    A8
    lda #6
    sta c_can
    LDPTR0 str_coon
    bra @pop
@oof:
    ; a spill that teaches: under it, what would have got you over
    lda E_FLAGS,x
    and #$10
    beq @nst
    LDPTR1 str_oof_stuck        ; stood against it and never pressed A
    bra @two
@nst:
    lda E_TYPE,x
    cmp #T_BIN
    bne @plain
    LDPTR1 str_oof_bin          ; a hop into a green bin
@two:
    jsr set_line2
    LDPTR0 str_oof
    lda #TP_RED
    ldx #70
    jmp popup_t2
@plain:
    LDPTR0 str_oof
@pop:
    lda #TP_RED
    ldx #60
    jmp popup_t


; ------------------------------------------------------------------
; callouts: centred on row 9 inside a solid 3-row panel, so they read over
; the roofs. ptr0 = message, A = text palette, X = frames to keep it up.
; Drawn in the next frame's text slot (pend_draw).
popup_t:
    stz c_pline2
    stz c_plow
    pha
    lda c_state
    cmp #ST_ESCAPE
    pla
    bcs @x                      ; the tally owns the panel now
    stx c_popup
    sta c_ppal
    lda #POP_MIN
    sta c_pmin
    ldx ptr0
    stx c_pptr
    lda ptr0+2
    sta c_pptr+2
    lda #$01
    sta c_pend
@x:
    rts

; ...with a second line (c_buf2) under the first
popup_t2:
    jsr popup_t
    lda #$01
    sta c_pline2
    rts

; coaching: a hurdle coming up takes it down (so it never talks over a jump)
popup_low:
    jsr popup_t
    lda #$01
    sta c_plow
    rts

pend_draw:
    lda c_pend
    stz c_pend
    cmp #1
    bne @n1
    ; a callout: blank the panel this frame, draw it in the next
    jsr popup_clear
    lda #6
    sta c_pend
    rts
@n1:
    cmp #6
    beq popup_draw
    cmp #2
    beq @box
    cmp #3
    bne @l7
    jmp tally_text
@l7:
    cmp #7
    bne @l8
    jmp tally_text2
@l8:
    cmp #8
    bne @l2
    jsr tally_box
    lda #3
    sta c_pend
    rts
@l2:
    cmp #5
    bne @clr
    jmp line2_draw
@clr:
    jmp popup_clear
@box:
    ; the tally: clear the callout panel this frame, the box in the next
    jsr popup_clear
    lda #8
    sta c_pend
    rts

popup_draw:
    ldx c_pptr
    stx ptr0
    lda c_pptr+2
    sta ptr0+2
    ldy #$0000
@len:
    lda [ptr0],y
    beq @got
    iny
    bra @len
@got:
    sty tmp3
    lda #3
    sta tmp1+1
    lda c_pline2
    beq @one
    ; two lines: as wide as the longer one, two rows taller (a blank row
    ; between them for leading)
    inc tmp1+1
    inc tmp1+1
    ldy #$0000
@len2:
    lda c_buf2,y
    beq @got2
    iny
    bra @len2
@got2:
    cpy tmp3
    bcc @one
    sty tmp3
@one:
    lda tmp3
    clc
    adc #4
    sta tmp1
    lda #32
    sec
    sbc tmp1
    lsr a
    A16
    and #$00FF
    clc
    adc #(8*32)
    tax
    A8
    lda #$20
    jsl txt_box
    lda #TXT_WIN
    sta txt_bg
    lda c_ppal
    asl a
    asl a
    ora #$20
    ldx #(9*32)
    jsl txt_print_centre
    stz txt_bg
    ; the second line goes in the next frame's text slot
    lda c_pline2
    beq @x
    lda #5
    sta c_pend
@x:
    rts

line2_draw:
    lda #TXT_WIN
    sta txt_bg
    jsr buf2_ptr
    lda #(TP_WHITE << 2) | $20
    ldx #(11*32)
    jsl txt_print_centre
    stz txt_bg
    rts

buf2_ptr:
    A16
    lda #.loword(c_buf2)
    sta ptr0
    A8
    lda #^c_buf2
    sta ptr0+2
    rts

; blank rows 8-12
popup_clear:
    ldx #(8*32)
    A16
    lda #$0520
    sta tmp1
    A8
    stz tmp2
    lda #$20
    jsl txt_fill
    rts

; blank rows 6-16 (the tally)
panel_clear:
    ldx #(6*32)
    A16
    lda #$0B20
    sta tmp1
    A8
    stz tmp2
    lda #$20
    jsl txt_fill
    rts

; ------------------------------------------------------------------
; the reckoning, on screen before the card: points, fine or bonuses, score
tally_req:
    stz c_buzz                  ; sobered up: the wobble stops for the reckoning
    jsr cops_score
    ldx #$0000
    stx c_popup
    lda #2
    sta c_pend
    rts

tally_box:
    ldx #(6*32 + 3)
    A16
    lda #$0B1A                  ; 26 x 11
    sta tmp1
    A8
    lda #$20
    jsl txt_box
    rts

; (in two frames' text slots: it's too much text for one). The same sum as
; the card: RUN 50 A HURDLE + STYLE (- COP'S FINE) = SCORE
tally_text:
    lda #TXT_WIN
    sta txt_bg
    lda ev_fail
    bne @bust
    PRINTC 7, TP_GREEN, str_t_won
    bra @run
@bust:
    PRINTC 7, TP_RED, str_t_bust
@run:
    PRINT 6, 9, TP_WHITE, str_t_run
    PRINT 10, 9, TP_GREY, str_t_rate
    stz tmp7
    ldx ev_break
    ldy #(9*32 + 21)
    lda #TP_YELLOW
    jsr tnum
    PRINT 6, 10, TP_WHITE, str_t_style
    lda #'+'
    sta tmp7
    ldx ev_break+2
    ldy #(10*32 + 21)
    lda #TP_GREEN
    jsr tnum
    stz txt_bg
    lda #7
    sta c_pend
    rts

; ...the rest of it, a frame later
tally_text2:
    lda #TXT_WIN
    sta txt_bg
    lda ev_fail
    bne @fine
    PRINTC 13, TP_GREY, str_t_spa
    bra @score
@fine:
    PRINT 6, 11, TP_WHITE, str_t_fine
    lda #'-'
    sta tmp7
    ldx c_fine
    ldy #(11*32 + 21)
    lda #TP_RED
    jsr tnum
    ; one framing, as the card's: the fine is a quarter (or there was nothing
    ; to fine: not one hurdle cleared)
    A16
    lda ev_break
    A8
    bne @fq
    PRINTC 13, TP_GREY, str_t_none
    bra @score
@fq:
    PRINTC 13, TP_GREY, str_t_half
@score:
    PRINT 6, 15, TP_WHITE, str_t_score
    stz tmp7
    ldx ev_score
    ldy #(15*32 + 21)
    lda #TP_YELLOW
    jsr tnum
    stz txt_bg
    rts

; X = value, Y = cell, A = palette: 5-digit number on the window fill,
; with the sign char in tmp7 (0 = none) hard up against the first digit
tnum:
    stx tmp1
    sty tmp6
    asl a
    asl a
    ora #$20
    sta tmp5
    tyx
    ldy #5
    jsl txt_num
    lda tmp7
    beq @x
    clc
    adc #(TXT_WIN - 32)
    sta tmp7
    A16
    inc tmp6
    inc tmp6
    inc tmp6                    ; one digit: the sign sits in cell + 3
    ldx #$0000
    lda tmp1
@dg:
    cmp f:pow10,x
    bcc @sg
    dec tmp6
    inx
    inx
    cpx #8
    bne @dg
@sg:
    ldx tmp6
    A8
    lda tmp7
    sta tmp2
    lda tmp5
    jsl txt_char
@x:
    rts

pow10: .word 10, 100, 1000, 10000


; ------------------------------------------------------------------
cops_draw:
    jsl oam_clear
    A16
    lda c_dist
    sta bg1x
    lsr a
    lsr a
    sta bg2x
    A8
    jsr draw_runner
    jsl cops_glow
    jsr draw_cop
    jsr draw_obstacles
    jmp draw_marks

; runner frames (big runner sheet): index -> metasprite, tile base
F_RUN0   = 0
F_JUMP   = 6
F_FALL   = 7
F_SIP0   = 8
F_AIRSIP = 10
F_TRIP0  = 11
F_FALLEN = 14

draw_runner:
    A16
    lda #PLAYER_SX
    sta spr_x
    lda c_h
    xba
    and #$00FF
    eor #$FFFF
    sec
    adc #GROUND
    sta spr_y
    ; legs keep time with the pavement
    lda c_anim
    clc
    adc c_speed
    cmp #$3000
    bcc @a
    sbc #$3000
@a:
    sta c_anim
    A8
    lda #$20
    sta tmp5
    stz tmp5+1
    lda c_state
    cmp #ST_BUSTED
    bne @nb
    ldx #GROUND
    stx spr_y
    lda #F_FALLEN
    bra @go
@nb:
    ldx c_bump
    beq @nbump
    lda #F_TRIP0                ; up against it: pitched forward
    bra @go
@nbump:
    lda c_state
    cmp #ST_TRIP
    bne @nt
    ; the tumble: pitch, dive, back up (with a splash of tallboy)
    lda c_timer
    cmp #23
    lda #F_TRIP0
    bcs @go
    lda c_timer
    cmp #12
    lda #(F_TRIP0 + 2)
    bcc @go
    jsr draw_splash
    lda #(F_TRIP0 + 1)
    bra @go
@nt:
    lda c_sipping
    beq @nosip
    lda c_air
    beq @gsip
    lda #F_AIRSIP
    bra @go
@gsip:
    lda c_anim+1
    lsr a
    lsr a
    lsr a
    lsr a
    and #$01
    clc
    adc #F_SIP0
    bra @go
@nosip:
    lda c_air
    beq @runf
    lda c_vy+1
    bmi @fall
    lda #F_JUMP
    bra @go
@fall:
    lda #F_FALL
    bra @go
@runf:
    lda c_anim+1
    lsr a
    lsr a
    lsr a                       ; 0..5
@go:
    asl a
    TAXB
    A16
    lda f:big_ptrs,x
    sta ptr1
    lda f:big_bases,x
    sta tmp6
    A8
    lda #^big_ptrs
    sta ptr1+2
    jsl oam_meta
    rts

big_ptrs:  .addr ms_brun0, ms_brun1, ms_brun2, ms_brun3, ms_brun4, ms_brun5, ms_bjump, ms_bfall
           .addr ms_bsip0, ms_bsip1, ms_bairsip, ms_btrip0, ms_btrip1, ms_btrip2, ms_bfallen
big_bases: .word MS_BRUN0_BASE, MS_BRUN1_BASE, MS_BRUN2_BASE, MS_BRUN3_BASE, MS_BRUN4_BASE
           .word MS_BRUN5_BASE, MS_BJUMP_BASE, MS_BFALL_BASE, MS_BSIP0_BASE, MS_BSIP1_BASE
           .word MS_BAIRSIP_BASE, MS_BTRIP0_BASE, MS_BTRIP1_BASE, MS_BTRIP2_BASE, MS_BFALLEN_BASE

; beer on the pavement in front of a tumbling runner (keeps spr_x/spr_y)
draw_splash:
    A16
    lda spr_x
    pha
    lda spr_y
    pha
    clc
    adc #($10000 - 4)
    sta spr_y
    lda spr_x
    clc
    adc #18
    sta spr_x
    A8
    lda #$24
    sta tmp5
    LDPTR1 ms_splash
    ldx #MS_SPLASH_BASE
    stx tmp6
    jsl oam_meta
    lda #$20
    sta tmp5
    A16
    pla
    sta spr_y
    pla
    sta spr_x
    A8
    rts

draw_cop:
    A16
    lda c_gap
    xba
    and #$00FF
    eor #$FFFF
    sec
    adc #PLAYER_SX
    sta spr_x
    cmp #($10000 - 20)
    bcs @vis
    cmp #250
    bcc @vis
    A8
    rts
@vis:
    .a16
    lda #GROUND
    sta spr_y
    A8
    lda #$22
    sta tmp5
    stz tmp5+1
    lda frame
    and #$08
    bne @f1
    LDPTR1 ms_cop0
    ldx #MS_COP0_BASE
    bra @go
@f1:
    LDPTR1 ms_cop1
    ldx #MS_COP1_BASE
@go:
    stx tmp6
    jsl oam_meta
    ; flashing light when close
    A16
    lda c_gap
    cmp #(70*256)
    A8
    bcs @x
    lda frame
    and #$04
    bne @x
    A16
    lda spr_x
    clc
    adc #6
    sta spr_x
    lda #(GROUND - 34)
    sta spr_y
    A8
    lda #$24
    sta tmp5
    LDPTR1 ms_siren
    ldx #MS_SIREN_BASE
    stx tmp6
    jsl oam_meta
@x:
    rts

draw_obstacles:
    ldx #$0000
@e:
    lda E_TYPE,x
    bne @live
    jmp @n
@live:
    stx c_cur
    A16
    lda E_WX,x
    sec
    sbc c_dist
    clc
    adc #PLAYER_SX
    sta spr_x
    clc
    adc #32
    cmp #(256 + 64)
    bcc @show
    ; still off to the right: flash a warning at the edge for the last stretch
    cmp #(256 + 64 + 100)
    jcs @skip
    lda frame
    and #$0008
    jne @skip
    lda #244
    sta spr_x
    lda #(GROUND - 30)
    sta spr_y
    A8
    lda #$24
    sta tmp5
    stz tmp5+1
    lda E_TYPE,x
    cmp #T_BIN
    beq @hi
    LDPTR1 ms_warn_lo
    ldx #MS_WARN_LO_BASE
    bra @wgo
@hi:
    LDPTR1 ms_warn_hi
    ldx #MS_WARN_HI_BASE
@wgo:
    stx tmp6
    jsl oam_meta
    jmp @skip
@show:
    .a16
    lda #GROUND
    sta spr_y
    A8
    lda #$24
    sta tmp5
    stz tmp5+1
    lda E_FLAGS,x
    and #$08
    beq @nf
    lda #$40                    ; a thieving raccoon runs off the other way
    sta tmp5+1
@nf:
    lda E_TYPE,x
    asl a
    TAYB
    cpy #(T_COON*2)
    bne @static
    lda frame
    and #$08
    beq @static
    ldy #10
@static:
    lda ob_ptrs,y
    sta ptr1
    lda ob_ptrs+1,y
    sta ptr1+1
    lda #^ms_crates
    sta ptr1+2
    lda ob_bases,y
    sta tmp6
    lda ob_bases+1,y
    sta tmp6+1
    jsl oam_meta
    ; ...holding your tallboy over its head
    ldx c_cur
    lda E_FLAGS,x
    and #$08
    beq @skip
    A16
    lda E_WX,x
    sec
    sbc c_dist
    clc
    adc #(PLAYER_SX + 4)
    sta spr_x
    lda #(GROUND - 14)
    sta spr_y
    A8
    stz tmp5+1
    LDPTR1 ms_can
    ldx #MS_CAN_BASE
    stx tmp6
    jsl oam_meta
@skip:
    A8
    ldx c_cur
@n:
    inx
    inx
    cpx #(NUM_ENT*2)
    beq @d
    jmp @e
@d:
    rts

; chalk take-off marks: for each hurdle still ahead, a chevron on the pavement
; where to jump (reach it, press A), and a chalk strip on from it (ON THE
; CHALK). They sit early in the jump window, so a press that lands up to ~22
; frames after you reach the chevron still clears it.
draw_marks:
    lda c_state
    cmp #ST_ESCAPE
    bcc @go0
    rts
@go0:
    ldx #$0000
@e:
    lda E_TYPE,x
    beq @n
    lda E_FLAGS,x
    and #$1B                    ; hit, counted, a thief or bumped: no mark
    bne @n
    stx c_cur
    lda E_TYPE,x
    TAYB
    lda mk_d,y
    A16
    and #$00FF
    sta tmp0
    lda E_WX,x
    sec
    sbc c_dist
    sec
    sbc tmp0
    clc
    adc #PLAYER_SX
    sta spr_x
    ; from the end of its strip passing under the runner to the right edge
    sec
    sbc #(PLAYER_SX - CHALK_LATE - 4)
    cmp #(264 - (PLAYER_SX - CHALK_LATE - 4))
    bcs @skip
    lda #(GROUND + 4)
    sta spr_y
    A8
    lda #$24
    sta tmp5
    stz tmp5+1
    cpy #T_BIN
    beq @hi
    LDPTR1 ms_mark_lo
    ldx #MS_MARK_LO_BASE
    bra @go
@hi:
    LDPTR1 ms_mark_hi
    ldx #MS_MARK_HI_BASE
@go:
    stx tmp6
    jsl oam_meta
@skip:
    A8
    ldx c_cur
@n:
    inx
    inx
    cpx #(NUM_ENT*2)
    jne @e
    rts

; take-off distance (px between you and it) for each kind: tap marks for the
; low stuff, a big-jump mark for the bin, further out for an oncoming raccoon
mk_d: .byte 0, 54, 56, 76, 79

ob_ptrs:  .addr 0, ms_crates, ms_bench, ms_bin, ms_coon0, ms_coon1
ob_bases: .word 0, MS_CRATES_BASE, MS_BENCH_BASE, MS_BIN_BASE, MS_COON0_BASE, MS_COON1_BASE

; ------------------------------------------------------------------
; buzz wobble: per-4-line horizontal offsets for BG1 and BG2 via HDMA
wobble:
    lda c_buzz
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    sta c_amp
    bne @on
    lda hdma_sh
    and #$9F
    sta hdma_sh
    rts
@on:
    ldx #$0000                  ; table offset
    ldy #$0000                  ; line group
@g:
    lda #4
    sta f:wob1,x
    sta f:wob2,x
    ; angle = frame*3 + group*10
    tya
    sta tmp0
    asl a
    asl a
    asl a
    clc
    adc tmp0
    adc tmp0
    sta tmp0
    lda frame
    asl a
    clc
    adc frame
    clc
    adc tmp0
    phx
    TAXB
    lda f:sine_table,x
    plx
    ; signed (sine * amp) >> 7
    pha
    cmp #$80                    ; sign of the sine (plx set the flags from X)
    bcc @pos
    eor #$FF
    inc a
@pos:
    sta WRMPYA
    lda c_amp
    sta WRMPYB
    nop
    nop
    nop
    nop
    A16
    lda RDMPYL
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    sta tmp1
    A8
    pla
    bpl @add
    A16
    lda tmp1
    eor #$FFFF
    inc a
    sta tmp1
    A8
@add:
    A16
    lda bg1x
    clc
    adc tmp1
    sta f:wob1+1,x
    lda bg2x
    clc
    adc tmp1
    sta f:wob2+1,x
    A8
    inx
    inx
    inx
    iny
    cpy #56
    jne @g
    lda #$00
    sta f:wob1,x
    sta f:wob2,x
    lda hdma_sh
    ora #$60
    sta hdma_sh
    rts

; ------------------------------------------------------------------
cops_hud:
    lda frame
    and #$03
    beq @go
    rts
@go:
    jsr calc_pts
    ldx c_pts
    stx tmp1
    ldx #(1*32 + 5)
    ldy #4
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_num
    ; SIP 'N' HOP chain, on its own row under PTS, read like it: "CHAIN X3"
    ; (it lasts until a spill, a scramble or a dry hop off the chalk)
    lda c_chain
    cmp c_hchain
    beq @buzz
    sta c_hchain
    lda c_chain
    beq @noch
    PRINT 1, 2, TP_WHITE, str_hchain
    lda #('X' - 32)
    sta tmp2
    ldx #(2*32 + 7)
    lda #($20 | (TP_GREEN << 2))
    jsl txt_char
    lda c_chain
    clc
    adc #('0' - 32)
    sta tmp2
    ldx #(2*32 + 8)
    lda #($20 | (TP_GREEN << 2))
    jsl txt_char
    bra @buzz
@noch:
    ldx #(2*32 + 1)
    A16
    lda #$0108                  ; 8 x 1
    sta tmp1
    A8
    stz tmp2
    lda #$20
    jsl txt_fill
@buzz:
    ; buzz meter 4 cells (0-255 -> 16 quarters)
    lda c_buzz
    lsr a
    lsr a
    lsr a
    lsr a
    sta tmp3
    ; pink; gold from COURAGE (a SIP 'N' HOP now pays a bigger base); red
    ; once you're TIPSY (a sip now is SLOSHED)
    lda c_buzz
    cmp #BUZZ_TIPSY
    bcs @red
    cmp #COURAGE
    lda #($20 | (TP_PINK << 2))
    bcc @bc
    lda #($20 | (TP_YELLOW << 2))
    bra @bc
@red:
    lda #($20 | (TP_RED << 2))
@bc:
    ldx #(1*32 + 16)
    stz tmp7
    jsr meter4
    ; cop meter: fuller = closer (gap GAP_MAX -> GAP_BUST = 0 -> 16 quarters)
    A16
    lda c_gap
    xba
    and #$00FF
    eor #$FFFF
    sec
    adc #GAP_MAX                ; 0 .. GAP_MAX
    sta tmp3
    asl a
    asl a
    sta tmp4                    ; x4
    asl a                       ; x8
    clc
    adc tmp4
    clc
    adc tmp3                    ; x13
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a                       ; x13/128 ~ x16/154
    cmp #17
    bcc @c16
    lda #16
@c16:
    A8
    sta tmp3
    ldx #(1*32 + 26)
    lda #($20 | (TP_RED << 2))
    stz tmp7
    jsr meter4
    ; progress, row 26 (row 27 is lost to overscan on a CRT)
    A16
    lda c_dist
    cmp #COURSE_LEN
    bcc @in
    lda #COURSE_LEN
@in:
    sta tmp0
    A8
    lda #164                    ; COURSE_LEN / 44 quarters
    jsl div16
    lda tmp0
    sta tmp3
    ldx #(26*32 + 12)
    lda #($20 | (TP_GREEN << 2))
    ldy #TXT_WIN
    sty tmp7
    jmp meter11

; the HUD's labels, once: row 1, and rows 26-27 on a solid panel (as Bike's)
; so the road's yellow dashes can't scroll through KENSINGTON .. SPADINA;
; a cell clear of each side for the CRT's horizontal overscan
hud_static:
    PRINT 1, 1, TP_WHITE, str_pts
    PRINT 11, 1, TP_WHITE, str_buzz
    lda #$FF
    sta c_hchain
    PRINT 22, 1, TP_WHITE, str_cops
    ldx #(26*32)
    A16
    lda #$0220
    sta tmp1
    A8
    lda #TXT_WIN
    sta tmp2
    lda #$20
    jsl txt_fill
    lda #TXT_WIN
    sta txt_bg
    PRINT 1, 26, TP_GREY, str_km
    PRINT 24, 26, TP_YELLOW, str_spa
    stz txt_bg
    rts

; 4-cell meter at X, tmp3 = quarters (0-16), A = attr, tmp7 = tile offset
meter4:
    ldy #4
    bra meter_n
meter11:
    ldy #11
meter_n:
    sty tmp6
    sta tmp4
    ldy #$0000
@cell:
    lda tmp3
    cmp #4
    bcc @part
    sbc #4
    sta tmp3
    lda #(TXT_METER + 4)
    bra @put
@part:
    clc
    adc #TXT_METER
    stz tmp3
@put:
    clc
    adc tmp7
    sta tmp2
    lda tmp4
    jsl txt_char
    inx
    iny
    cpy tmp6
    bne @cell
    rts


; ------------------------------------------------------------------
; run points so far -> c_base: 50 a hurdle hopped or scrambled over (a spill
; pays none), the card's RUN 50 A HURDLE
calc_base:
    ldx c_hpts
    stx c_base
    rts

; the HUD's PTS: run + style so far
calc_pts:
    lda c_state
    cmp #ST_ESCAPE
    bcc @run
    ldx ev_score                ; it's decided: show what the tally says
    stx c_pts
    rts
@run:
    jsr calc_base
    A16
    lda c_base
    clc
    adc c_style
    sta c_pts
    A8
    rts

; ev_stat: SIP 'N' HOPs, lucky sips, hurdles, spills
; ev_break: run, style, the cop's fine; base + bonus - penalty = ev_score
; finish: run + style, no fine (the tally and the card add it up the same way)
; busted / gave up: the fine is a quarter of run + style (the true cost: no
; cap, so a greedy run busted near Spadina still beats a timid finish, but
; loses the quarter)
cops_score:
    A16
    lda c_combos
    sta ev_stat
    lda c_sips
    sta ev_stat+2
    lda c_jumps
    sta ev_stat+4
    lda c_spills
    sta ev_stat+6
    stz c_fine
    stz ev_break+4
    A8
    jsr calc_base
    stz ev_fail
    lda c_quit
    bne @caught
    A16
    lda c_dist
    cmp #COURSE_LEN
    bcc @caught16
    lda c_base
    sta ev_break
    lda c_style
    sta ev_break+2
    clc
    adc ev_break
    sta ev_score
    A8
    rts
@caught:
    A16
@caught16:
    lda c_base
    sta ev_break
    lda c_style
    sta ev_break+2
    clc
    adc c_base
    sta tmp1                    ; run + style
    lsr a
    lsr a
    eor #$FFFF
    sec
    adc tmp1                    ; keep 3/4
    sta ev_score
    eor #$FFFF
    sec
    adc tmp1
    sta c_fine                  ; the rest
    sta ev_break+4
    A8
    lda #$01
    ldx c_quit
    beq @f
    lda #$03
@f:
    sta ev_fail
    rts

; ------------------------------------------------------------------
; text: the event bank ($83, shared with Off-Leash) is tight, so the strings
; live in the menu graphics bank. Everything reaches them through 24-bit
; pointers (LDPTR0 / PRINT), never DB-relative.
.segment "GFX1"
coach_ptrs: .addr 0, str_k_crates, str_k_bench, str_k_bin, str_k_coon
str_k_crates: .byte "CRATES! TAP A AT THE CHALK", 0
str_k_bench:  .byte "BENCH! TAP A AT THE CHALK", 0
str_k_bin:    .byte "GREEN BIN! HOLD A AT RED", 0
str_k_coon:   .byte "RACCOON! TAP A AT THE CHALK", 0
str_c_chain:  .byte "WAY OFF CHALK: CHAIN OVER", 0
str_held:     .byte "ON THE CHALK: CHAIN HELD", 0
str_held2:    .byte "CLOSE ENOUGH: CHAIN HELD", 0
str_buzzed:   .byte "SLOSHED! 0 PTS, CHAIN OVER", 0
str_tipsy:    .byte "TIPSY! THE COP'S GAINING", 0
str_warm:     .byte "WARM-UP OVER: HE'S COMING!", 0
str_c_sip: .byte "COP CAN'T SEE! HOLD B: SIP", 0
str_c_sip2: .byte "RED BUZZ = SLOSHED, 0 PTS", 0
str_c_air: .byte "B MID-AIR = SIP 'N' HOP!", 0
str_c_dry: .byte "CHALK! B MID-AIR PAYS X2", 0
str_c_dry3: .byte "DEAD ON! B MID-AIR PAYS X3", 0
str_chalk: .byte "ON THE CHALK", 0
str_dead:  .byte "DEAD ON THE CHALK", 0
str_close: .byte "BIT LATE, BUD", 0
str_scram: .byte "SCRAMBLED OVER IT! +50", 0     ; HURDLE_PTS
str_scram2: .byte "NEXT TIME: A AT THE CHALK", 0
str_brave: .byte "LIQUID COURAGE", 0
str_wind:  .byte "WINDED! STOP BUNNY-HOPPING", 0
str_c_cop: .byte "COP'S WATCHING! DON'T SIP!", 0
str_seen:  .byte "OI! THE COP SAW THAT!", 0
str_binc: .byte "RACCOON! HE NICKED YOUR CAN", 0
str_snh:  .byte "SIP 'N' HOP", 0
str_rrun: .byte "RACCOON RUN", 0
str_bsnh: .byte "BIG SIP 'N' HOP", 0
str_plus: .byte "! +", 0
str_chn:  .byte " CHAIN", 0
str_x2c:  .byte " X2 CHALK", 0
str_x3d:  .byte " X3 DEAD ON", 0
str_oof:  .byte "OOF! SPILLED! HE'S GAINING", 0
str_coon: .byte "OOF! RACCOON STOLE THE CAN", 0
str_t_bust:  .byte "BUSTED BY THE BIKE COP!", 0
str_t_won:   .byte "SPADINA! YOU LOST HIM!", 0
str_t_run:   .byte "RUN", 0
str_t_style: .byte "STYLE", 0
str_t_fine:  .byte "COP'S FINE", 0
str_t_half:  .byte "FINE IS 1/4 OF RUN+STYLE", 0
str_t_none:  .byte "NOT ONE HURDLE CLEARED", 0
str_t_spa:   .byte "MADE SPADINA: NO FINE", 0
str_t_rate:  .byte "50 A HURDLE", 0      ; HURDLE_PTS
str_t_score: .byte "SCORE", 0
str_pts:  .byte "PTS", 0
str_hchain: .byte "CHAIN", 0
str_buzz: .byte "BUZZ", 0
str_cops: .byte "COP", 0
str_km:   .byte "KENSINGTON", 0
str_spa:  .byte "SPADINA", 0

.segment "EVENTS2"
.include "cops_meta.inc"

; the big runner's tiles: GFX6 (cops art) and EVENTS2 (shared with Off-Leash) are
; both full, so they live in the menu graphics bank
.segment "GFX1"
cops_run_spr: .incbin "cops_run.bin"
cops_run_end:

; sprint 7's lines: GFX1 is nearly full, so they live in bank $80 (CODE), read
; through 24-bit pointers like the rest
.segment "CODE"
str_stuck:     .byte "STUCK! TAP A TO SCRAMBLE", 0
str_oof_stuck: .byte "STUCK? TAP A TO SCRAMBLE", 0
str_oof_bin:   .byte "GREEN BIN: HOLD A AT RED", 0
str_hop1:      .byte "HOP AT THE CHALK, BUD!", 0
str_hop2:      .byte "HOPS AT NOTHING WIND YOU", 0
str_crack:     .byte "*CRACK* NEW CAN: 6 SIPS", 0
str_gold:      .byte "GOLD ", 0

; ------------------------------------------------------------------
; the tell: from COURAGE up to TIPSY the BUZZ meter is gold (cops_hud), and
; the runner's can glows with it, pulsing (8 frames lit, 8 not) so it reads
; at a glance on the runner, not just up in the HUD. Runner palette 0
; (CGRAM 128..143): 12 can stripe, 13 can, 14 can top.
CAN_PAL = pal_buf + (128 + 12) * 2

.a8
.i16
cops_glow_init:
    A16
    lda CAN_PAL
    sta c_cansv
    lda CAN_PAL+2
    sta c_cansv+2
    lda CAN_PAL+4
    sta c_cansv+4
    A8
    stz c_glow
    rtl

.a8
.i16
cops_glow:
    lda c_state
    cmp #ST_ESCAPE
    bcs @off
    lda c_buzz
    cmp #COURAGE
    bcc @off
    cmp #BUZZ_TIPSY
    bcs @off
    lda frame
    and #$08
    beq @off
    lda #$01
    bra @set
@off:
    lda #$00
@set:
    cmp c_glow
    beq @x
    sta c_glow
    lda c_glow                  ; (Z: lit or not; A16 leaves Z alone)
    A16
    beq @dim
    lda #$03BF                  ; stripe: gold
    sta CAN_PAL
    lda #$7FFF                  ; can: white, foaming over (reads on any jersey)
    sta CAN_PAL+2
    lda #$7FFF                  ; top: white foam
    sta CAN_PAL+4
    bra @dirty
@dim:
    lda c_cansv
    sta CAN_PAL
    lda c_cansv+2
    sta CAN_PAL+2
    lda c_cansv+4
    sta CAN_PAL+4
@dirty:
    A8
    lda #$01
    sta pal_dirty
@x:
    rtl
