; EVENT 4: TALLBOY TROT — Kensington Market side-scroller.
; Auto-run; A jumps (tap: hop the low stuff, hold: big jump for green bins),
; hold B to sip the tallboy. Sipping slows you down, so every sip spends some
; of your lead on the bike cop. Sips only score while the cop can't see you
; (he's off-screen). A sip finished mid-air over a hurdle is a SIP 'N' HOP;
; chain them inside a few seconds for a multiplier (x2 .. x5), and do one
; over a raccoon for a RACCOON RUN. Sip on the ground next to a green bin and
; a raccoon nicks your can. The first 20 s are a warm-up: the cop hangs back,
; can't bust you, and the game tells you what each obstacle needs.
; Score: the points you rack up (PTS on the HUD), plus the Spadina bonus and
; a no-spill bonus if you get there. Busted: the cop fines you half your
; points (you keep at most BUST_CAP), so any finish beats any bust.
.p816
.smart -
.include "globals.inc"
.include "screens.inc"

.import cops_tiles, cops_bg1, cops_bg2, cops_pal, cops_spr, cops_spr_pal, cops_sky, sine_table

GROUND     = 188
PLAYER_SX  = 104
COURSE_LEN = 7200
RUN_SPD    = $0200
SIP_SPD    = $00E0
TRIP_SPD   = $0080
JUMP_V     = $03C0
GRAVITY    = $0020
MIN_HOP    = 6               ; air frames before letting go of A cuts the jump
HOP_CUT    = $0180           ; ...to this rise speed: a tap is a hop, a hold a big jump
COP_WARM   = $0180           ; cop speed in the warm-up
COP_START  = $01C0           ; ...and after it
COP_RAMP   = $3F             ; then 1/256 px/frame faster every 64 frames
WARM_T     = 1200            ; 20 s warm-up: the cop can't bust you yet
GAP_START  = 176
GAP_MAX    = 176
GAP_BUST   = 22
GAP_WARM   = 44              ; closest the cop gets in the warm-up
COP_SEEN   = 110             ; gap below this = the cop is on screen (a third of his bike shows)
TRIP_TIME  = 33
TRIP_LUNGE = 30              ; px the cop gains on top of the stumble
SEEN_LUNGE = 10              ; px the cop gains when he catches you sipping
SIP_PTS    = 25
HURDLE_PTS = 20
COMBO_PTS  = 40              ; SIP 'N' HOP: x the chain multiplier
COON_PTS   = 100             ; RACCOON RUN: on top of the SIP 'N' HOP
SPILL_PTS  = 25
CHAIN_T    = 300             ; frames to land the next SIP 'N' HOP and keep the chain
CHAIN_MAX  = 5
FINISH_PTS = 600             ; reaching Spadina
CLEAN_PTS  = 300             ; ...without a single spill
BUST_CAP   = 550             ; a busted run keeps half its points, at most this

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
c_chaint = ev_ram + 56       ; frames left to extend it
c_combos = ev_ram + 58       ; SIP 'N' HOPs landed
c_spills = ev_ram + 60
c_taught = ev_ram + 62       ; coaching shown: 1<<type, $20 sip, $40 air sip, $80 cop
c_jcoon  = ev_ram + 200      ; this jump cleared a raccoon
c_coons  = ev_ram + 202      ; RACCOON RUNs
c_fine   = ev_ram + 204
c_bonus  = ev_ram + 206
c_clean  = ev_ram + 208
c_best   = ev_ram + 210      ; best chain
c_quit   = ev_ram + 212      ; gave up from the pause menu
c_ppal   = ev_ram + 214
c_pend   = ev_ram + 216      ; text work for the next quiet slot: 1 popup, 2/3 tally, 4 clear
c_pptr   = ev_ram + 218      ; the popup's message (3 bytes)
c_buf    = ev_ram + 224      ; 32-byte banner buffer
EV_SEED  = ev_ram + 510

NUM_ENT = 10
E_TYPE  = ev_ram + 64
E_WX    = ev_ram + 84
E_WXF   = ev_ram + 104
E_V     = ev_ram + 124
E_FLAGS = ev_ram + 144       ; 1 hit, 2 counted, 4 fresh, 8 raccoon has your can
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
    ldx #RUN_SPD
    stx c_speed
    ldx #(GAP_START*256)
    stx c_gap
    ldx #COP_WARM
    stx c_copspd
    ldx #6
    stx c_can
    ldx #$3C9D
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
    and #$07
    bne @nb
    lda c_buzz
    beq @nb
    dec c_buzz
@nb:
    A16
    lda c_popup
    beq @np
    dec c_popup
    bne @np
    A8
    lda c_pend
    bne @np8
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
    ldx #170
    stx c_timer
    SFX SFX_CHEER
    jsr tally_req
    A16
@ne:
    A8
    rts

; the clock while you're running: chain timer, warm-up hints
running_clock:
    A16
    inc c_t
    lda c_chaint
    beq @nc
    dec c_chaint
    bne @nc
    stz c_chain
@nc:
    A8
    lda c_popup
    ora c_popup+1
    bne @x
    lda c_state
    bne @x
    lda c_air
    bne @x
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
    lda c_taught
    ora #$20
    sta c_taught
    LDPTR0 str_c_sip
    lda #TP_YELLOW
    ldx #120
    jmp popup_t
@h2:
    ; first lucky sip went down: now do it in the air
    lda c_taught
    and #$40
    bne @x
    lda c_sips
    beq @x
    lda c_taught
    ora #$40
    sta c_taught
    LDPTR0 str_c_air
    lda #TP_YELLOW
    ldx #120
    jmp popup_t
@x:
    rts

str_c_sip: .byte "COP CAN'T SEE YOU: HOLD B!", 0
str_c_air: .byte "SIP MID-JUMP = SIP 'N' HOP!", 0
str_c_cop: .byte "COP'S WATCHING! DON'T SIP!", 0

cops_input:
    stz c_sipping
    lda c_air
    bne @air
    ; on the ground: A jumps
    A16
    lda pad_new
    and #PAD_A
    A8
    beq @sip
    lda #$01
    sta c_air
    ldx #JUMP_V
    stx c_vy
    ldx #$0000
    stx c_hold
    stx c_jclr
    stx c_jsip
    stx c_jcoon
    SFX SFX_JUMP
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
    ; hold B: sip (on the ground or mid-air), which slows you down
    A16
    lda pad
    and #PAD_B
    A8
    beq @x
    lda #$01
    sta c_sipping
    lda c_prog
    clc
    adc #3
    sta c_prog
    cmp #60
    bcc @x
    stz c_prog
    jsr sip_done
@x:
    rts

; a sip went down: buzz, a fresh can every 6, and points if the cop missed it
sip_done:
    SFX SFX_SIP
    lda c_buzz
    clc
    adc #20
    bcc @b
    lda #$FF
@b:
    sta c_buzz
    dec c_can
    bne @can
    lda #6
    sta c_can
    LDPTR0 str_crack
    lda #TP_YELLOW
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
    stz c_chain
    stz c_chaint
    A8
    SFX SFX_WHISTLE
    LDPTR0 str_seen
    lda #TP_RED
    ldx #60
    jmp popup_t
@lucky:
    .a16
    inc c_sips
    lda c_pts
    clc
    adc #SIP_PTS
    sta c_pts
    A8
    lda c_air
    beq @x
    inc c_jsip
@x:
    rts

str_crack: .byte "*CRACK* FRESH TALLBOY", 0
str_seen:  .byte "OI! THE COP SAW THAT!", 0

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
    stz c_chaint
    stz c_chaint+1
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

str_binc: .byte "RACCOON! HE NICKED YOUR CAN", 0

approach_speed:
    A16
    lda #RUN_SPD
    ldx c_sipping
    beq @t
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
    beq @x
    A16
    lda c_vy
    sec
    sbc #GRAVITY
    sta c_vy
    clc
    adc c_h
    sta c_h
    bpl @up
    stz c_h
    stz c_vy
    A8
    stz c_air
    SFX SFX_STEP
    ; landed: sipped over a hurdle on the way?
    lda c_state
    cmp #ST_RUN
    bne @x
    lda c_jclr
    beq @x
    lda c_jsip
    beq @x
    jmp sip_n_hop
@up:
    A8
@x:
    rts

; a SIP 'N' HOP landed: chain it, score it, shout about it
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
    ldx #CHAIN_T
    stx c_chaint
    A16
    inc c_combos
    ; COMBO_PTS x chain (+ COON_PTS over a raccoon)
    lda c_chain
    and #$00FF
    sta tmp0
    asl a
    asl a
    clc
    adc tmp0                    ; x5
    asl a
    asl a
    asl a                       ; x40
    sta tmp3
    A8
    lda c_jcoon
    beq @nc
    A16
    inc c_coons
    lda tmp3
    clc
    adc #COON_PTS
    sta tmp3
    A8
@nc:
    A16
    lda c_pts
    clc
    adc tmp3
    sta c_pts
    A8
    SFX SFX_COIN
    ; banner: "SIP 'N' HOP X3! +120" / "RACCOON RUN X2! +180"
    ldy #$0000
    lda c_jcoon
    beq @sn
    LDPTR0 str_rrun
    bra @pre
@sn:
    LDPTR0 str_snh
@pre:
    jsr buf_str
    lda c_chain
    cmp #2
    bcc @nox
    lda #' '
    jsr buf_ch
    lda #'X'
    jsr buf_ch
    lda c_chain
    clc
    adc #'0'
    jsr buf_ch
@nox:
    LDPTR0 str_plus
    jsr buf_str
    A16
    lda tmp3
    A8
    jsr buf_num
    lda #$00
    sta c_buf,y
    jsr buf_ptr
    lda #TP_GREEN
    ldx #70
    jmp popup_t

str_snh:  .byte "SIP 'N' HOP", 0
str_rrun: .byte "RACCOON RUN", 0
str_plus: .byte "! +", 0

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
    A16
    lda c_t
    cmp #WARM_T
    bcc @warm
    bne @ramp
    lda #COP_START
    sta c_copspd
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
    bcs @p
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
    ; first time he's on screen: say so
    A8
    lda c_taught
    bmi @nh
    ora #$80
    sta c_taught
    LDPTR0 str_c_cop
    lda #TP_ORANGE
    ldx #90
    jsr popup_t
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

; hit box: half width + 5, height (a tap-hop clears all but the bin)
ob_hw: .byte 0, 14, 14, 9, 9
ob_h:  .byte 0, 12, 10, 26, 9

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
    ; first of its kind coming on screen: coach it
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
    TAYB
    A16
    lda coach_ptrs,y
    sta ptr0
    A8
    lda #^coach_ptrs
    sta ptr0+2
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
    lda c_pts
    clc
    adc #HURDLE_PTS
    sta c_pts
    A8
    lda c_air
    beq @nopass
    sta c_jclr
    lda E_TYPE,x
    cmp #T_COON
    bne @nopass
    sta c_jcoon
@nopass:
    ; hit?
    lda E_FLAGS,x
    and #$01
    bne @store
    lda E_TYPE,x
    TAYB
    lda tmp0+1
    bne @far
    lda tmp0
    bra @dx
@far:
    cmp #$FF
    bne @store
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
coach_ptrs: .addr 0, str_k_crates, str_k_bench, str_k_bin, str_k_coon
str_k_crates: .byte "FRUIT CRATES! TAP A: HOP", 0
str_k_bench:  .byte "BENCH! TAP A: HOP", 0
str_k_bin:    .byte "GREEN BIN! HOLD A: BIG JUMP", 0
str_k_coon:   .byte "RACCOON! TAP A: HOP", 0

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
    stz c_chain
    ; spilled some: points, and the cop gains on you
    A16
    stz c_chaint
    inc c_spills
    lda c_pts
    sec
    sbc #SPILL_PTS
    bcs @p
    lda #$0000
@p:
    sta c_pts
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
    LDPTR0 str_oof
@pop:
    lda #TP_RED
    ldx #60
    jmp popup_t

str_oof:  .byte "OOF! SPILLED SOME! -25", 0
str_coon: .byte "A RACCOON STOLE YOUR CAN!", 0

; ------------------------------------------------------------------
; callouts: centred on row 9 inside a solid 3-row panel, so they read over
; the roofs. ptr0 = message, A = text palette, X = frames to keep it up.
; Drawn in the next frame's text slot (pend_draw).
popup_t:
    pha
    lda c_pend
    cmp #2
    pla
    bcs @x                      ; the tally owns the panel now
    stx c_popup
    sta c_ppal
    ldx ptr0
    stx c_pptr
    lda ptr0+2
    sta c_pptr+2
    lda #$01
    sta c_pend
@x:
    rts

pend_draw:
    lda c_pend
    stz c_pend
    cmp #1
    beq popup_draw
    cmp #2
    beq @box
    cmp #3
    bne @clr
    jmp tally_text
@clr:
    jmp popup_clear
@box:
    jsr tally_box
    lda #3
    sta c_pend
    rts

popup_draw:
    ldx c_pptr
    stx ptr0
    lda c_pptr+2
    sta ptr0+2
    jsr popup_clear
    ldy #$0000
@len:
    lda [ptr0],y
    beq @got
    iny
    bra @len
@got:
    tya
    clc
    adc #4
    sta tmp1
    lda #3
    sta tmp1+1
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
    rts

; blank rows 8-10
popup_clear:
    ldx #(8*32)
    A16
    lda #$0320
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
    jsr popup_clear
    ldx #(6*32 + 3)
    A16
    lda #$0B1A                  ; 26 x 11
    sta tmp1
    A8
    lda #$20
    jsl txt_box
    rts

tally_text:
    lda #TXT_WIN
    sta txt_bg
    lda ev_fail
    jeq @won
    PRINTC 7, TP_RED, str_t_bust
    PRINT 6, 9, TP_WHITE, str_t_pts
    stz tmp7
    ldx c_pts
    ldy #(9*32 + 21)
    lda #TP_YELLOW
    jsr tnum
    PRINT 6, 11, TP_WHITE, str_t_fine
    lda #'-'
    sta tmp7
    ldx c_fine
    ldy #(11*32 + 21)
    lda #TP_RED
    jsr tnum
    A16
    lda ev_score
    cmp #BUST_CAP
    A8
    bcs @cap
    PRINT 6, 13, TP_GREY, str_t_half
    jmp @score
@cap:
    PRINT 6, 13, TP_GREY, str_t_cap
    jmp @score
@won:
    PRINTC 7, TP_GREEN, str_t_won
    PRINT 6, 9, TP_WHITE, str_t_pts
    stz tmp7
    ldx c_pts
    ldy #(9*32 + 21)
    lda #TP_YELLOW
    jsr tnum
    PRINT 6, 11, TP_WHITE, str_t_spa
    lda #'+'
    sta tmp7
    ldx c_bonus
    ldy #(11*32 + 21)
    lda #TP_GREEN
    jsr tnum
    PRINT 6, 13, TP_WHITE, str_t_clean
    lda #'+'
    sta tmp7
    ldx c_clean
    ldy #(13*32 + 21)
    lda #TP_GREEN
    jsr tnum
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

str_t_bust:  .byte "BUSTED BY THE BIKE COP!", 0
str_t_won:   .byte "SPADINA! YOU LOST HIM!", 0
str_t_pts:   .byte "POINTS", 0
str_t_fine:  .byte "COP'S FINE", 0
str_t_half:  .byte "YOU KEEP HALF", 0
str_t_cap:   .byte "YOU KEEP 550 MAX", 0
str_t_spa:   .byte "MADE SPADINA", 0
str_t_clean: .byte "NO SPILLS", 0
str_t_score: .byte "SCORE", 0

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
    jsr draw_cop
    jsr draw_obstacles
    rts

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
    ldx c_pts
    stx tmp1
    ldx #(1*32 + 5)
    ldy #4
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_num
    ; SIP 'N' HOP chain: X2 .. X5, blinking as it runs out
    lda c_chain
    beq @noch
    A16
    lda c_chaint
    cmp #64
    A8
    bcs @show
    lda frame
    and #$08
    bne @noch
@show:
    lda #('X' - 32)
    sta tmp2
    ldx #(1*32 + 10)
    lda #($20 | (TP_GREEN << 2))
    jsl txt_char
    lda c_chain
    clc
    adc #('0' - 32)
    sta tmp2
    ldx #(1*32 + 11)
    lda #($20 | (TP_GREEN << 2))
    jsl txt_char
    bra @buzz
@noch:
    stz tmp2
    ldx #(1*32 + 10)
    lda #$20
    jsl txt_char
    ldx #(1*32 + 11)
    jsl txt_char
@buzz:
    ; buzz meter 4 cells (0-255 -> 16 quarters)
    lda c_buzz
    lsr a
    lsr a
    lsr a
    lsr a
    sta tmp3
    ldx #(1*32 + 17)
    lda #($20 | (TP_PINK << 2))
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
    ; progress, row 27
    A16
    lda c_dist
    cmp #COURSE_LEN
    bcc @in
    lda #COURSE_LEN
@in:
    sta tmp0
    A8
    lda #150                    ; COURSE_LEN / 48 quarters
    jsl div16
    lda tmp0
    sta tmp3
    ldx #(27*32 + 11)
    lda #($20 | (TP_GREEN << 2))
    ldy #TXT_WIN
    sty tmp7
    jmp meter12

; the HUD's labels, once: row 1, and row 27 on a solid bar so the road's
; yellow dashes can't scroll through KENSINGTON .. SPADINA
hud_static:
    PRINT 1, 1, TP_WHITE, str_pts
    PRINT 13, 1, TP_WHITE, str_buzz
    PRINT 22, 1, TP_WHITE, str_cops
    ldx #(27*32)
    A16
    lda #$0120
    sta tmp1
    A8
    lda #TXT_WIN
    sta tmp2
    lda #$20
    jsl txt_fill
    lda #TXT_WIN
    sta txt_bg
    PRINT 0, 27, TP_GREY, str_km
    PRINT 24, 27, TP_YELLOW, str_spa
    stz txt_bg
    rts

; 4-cell meter at X, tmp3 = quarters (0-16), A = attr, tmp7 = tile offset
meter4:
    ldy #4
    bra meter_n
meter12:
    ldy #12
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

str_pts:  .byte "PTS", 0
str_buzz: .byte "BUZZ", 0
str_cops: .byte "COP", 0
str_km:   .byte "KENSINGTON", 0
str_spa:  .byte "SPADINA", 0

; ------------------------------------------------------------------
; ev_stat: lucky sips, distance/4, hurdles, the cop's fine
; finish: PTS + FINISH_PTS + (no spills: CLEAN_PTS)
; busted / gave up: PTS - fine, where the fine leaves you half (BUST_CAP max)
cops_score:
    A16
    lda c_sips
    sta ev_stat
    lda c_dist
    cmp #COURSE_LEN
    bcc @d
    lda #COURSE_LEN
@d:
    lsr a
    lsr a
    sta ev_stat+2
    lda c_jumps
    sta ev_stat+4
    stz ev_stat+6
    stz c_fine
    stz c_bonus
    stz c_clean
    A8
    stz ev_fail
    lda c_quit
    bne @caught
    A16
    lda c_dist
    cmp #COURSE_LEN
    bcc @caught16
    lda #FINISH_PTS
    sta c_bonus
    lda c_spills
    bne @dirty
    lda #CLEAN_PTS
    sta c_clean
@dirty:
    lda c_pts
    clc
    adc c_bonus
    clc
    adc c_clean
    sta ev_score
    A8
    rts
@caught:
    A16
@caught16:
    lda c_pts
    lsr a
    cmp #BUST_CAP
    bcc @k
    lda #BUST_CAP
@k:
    sta ev_score
    eor #$FFFF
    sec
    adc c_pts
    sta c_fine
    sta ev_stat+6
    A8
    lda #$01
    ldx c_quit
    beq @f
    lda #$03
@f:
    sta ev_fail
    rts

.include "cops_meta.inc"

; the big runner's tiles: GFX6 (cops art) and EVENTS2 (shared with Off-Leash) are
; both full, so they live in the menu graphics bank
.segment "GFX1"
cops_run_spr: .incbin "cops_run.bin"
cops_run_end:
