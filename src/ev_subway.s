; EVENT 7: TTC SURFING — Line 1 southbound, Bloor-Yonge to Union, no hands.
;
; The ride is a course of lurches (course table below): each leg pulls out
; of a station, takes a curve or two and brakes into the next one. Legs 1-2
; never change (the lesson); from the TMU leg on every ride jitters the
; gaps, lengths and pushes and slips a GAG into three of the last four legs:
; SIGNAL PROBLEMS (the emergency brake: forward) or a BACKPACK that swings
; round into you from the right (back). Every lurch is TELEGRAPHED before it
; pushes (40 frames, a gag 30): a sound (the PLEASE STAND CLEAR door chime, a wheel
; squeal, the brake hiss, the horn, a blip), a status line ("CURVE AHEAD")
; and a HOLLOW blinking arrow by the ring: get ready. When the push starts
; the arrow goes SOLID and the status names the verb ("CURVE! TAP v X3"
; while the leg can be gold, else "CURVE! HOLD v"). The push then ramps in.
; On the hollow arrow a lean is half strength and the rider finds their feet
; (the dot settles back), so getting ready early never tips you over; between
; lurches nothing pushes at all. A held lean settles: full strength until the
; dot is LEAN_LIM px your way, then it fades and braces you back, so HOLDING
; the arrow's way parks the dot in the white past the middle and never
; carries it into the rim: safe. A TAP the arrow's way (a fresh press, with
; no other way pressed for 8 frames) catches you: the dot heads for 3 px past
; the middle, so TAPPING on the beat keeps it in the GOLD. While the leg can
; still be gold the ring's sweet spot glows, the solid arrow flashes white on
; the beat (4 frames in 16) and the status says TAP (else HOLD); losing the
; gold plays a bloop. Only the push's own axis tips you over: a wrong or late
; lean across it rights itself. From the third leg track joints throw the
; dot 5 px (a bump you see and hear); their slip is forgiven 8 frames longer.
; Every player in a competition rides the same train (sb_seed).
;
; The balance ring sits over the rider's head on a dark disc of its own.
; The dot (11 px, gold / white / pulsing red with a !) is the rider's
; balance: LEFT/RIGHT is the train's go/brake axis,
; UP/DOWN the curves. Dot physics are slow and heavily damped with a gentle
; tip-over while a push is on. Let the dot reach the red rim and you GRAB
; something, and the sprite acts the gag out: the sticky pole (back), a
; backpack face-first (forward), a stranger's lap (up), the floor (down).
;
; Scoring (ev_break = base, bonus, penalty):
;   finished at Union: RIDE 1000 + STYLE - GERMS x40 (the true cost; a
;   finish can't go below 1000 - 19x40 = 240)
;     STYLE, itemised on the card (ev_style, w_sty):
;       SURF CHAIN: a leg where you RODE every push (pressed the solid
;         arrow's way, and no longer against it from the middle: a blind
;         wiggle doesn't ride) with no grab pays 75 x the chain of clean legs
;         in a row (75, 150, ... 450);
;       GOLD SURF X3: the dot never left the gold middle from the STAND
;         CLEAR chime to the next stop: that leg's surf x3 (225 ... 1350). A
;         slip that stays inside 9 px and comes back within 8 frames is
;         forgiven (the dot flickers gold while it can still be saved);
;       DEAD CENTRE: while a lurch pushes, the leg can still be gold and
;         you're riding it, a point every 2 frames, every frame inside 2 px;
;       GAGS RIDDEN: +100 for each gag you rode out with the dot out of the
;         red;
;       NO HANDS, the one the card never mentions (an expert's trick): glide
;         into a stop off the D-pad. Its tell (nh_tell): 69 frames out on a
;         clean leg you've ridden, with the dot out of the red, the whole
;         ring blinks gold and ticks every 8 frames. 15 frames later the
;         window opens: let go of the pad in the next 14 frames and the brake
;         eases (the arrow goes, GLIDING IN..., a ding, the ring steady gold);
;         stay off the pad to the stop with the dot gold: +100.
;   ev_stat: GERMS, LEGS LEANED (legs you rode), GOLD SURFS, and 6 (the
;   "OF n" on both lines: the ride's six legs, on every card).
;   PATIENT ZERO (20 germs: the count stops there) or CALL IT A DAY: RIDE 40
;   per LEG LEANED (standing still earns nothing), no style (any finish
;   beats any failed run: 240 > 5x40). ev_fail 1 PATIENT ZERO, 3 gave up.
; Once the run is decided (20 germs, or the doors open at Union) the pause
; menu is shut and a give-up already in the pipe is ignored.
;
; The windows stream the outside a column at a time into BG2 (64x32): tunnel
; while moving, the station wall sliding in from the right as the train
; brakes, so arrivals decelerate instead of hard-cutting.
.p816
.smart -
.include "globals.inc"
.include "screens.inc"

.ifndef SFX_NEXT
SFX_NEXT = SFX_CHEER        ; the gold-surf chime (a next-stop ding-dong once audio.s has one)
.endif

.import subway_tiles, subway_bg1, subway_tunnel, subway_platform, subway_pal, subway_spr, subway_spr_pal
.import trick_seen          ; boot.s: the attract demo's WATCH THAT MOVE! cue

RIDER_X   = 128
RIDER_Y   = 210             ; feet
RING_X    = 128
RING_Y    = 132
ARROW_D   = 32              ; arrow centre distance from the ring centre
SIGN_ROW  = 7               ; station sign box rows 7-9, over the windows
POP_TOP   = 4               ; callouts: a padded panel in rows 4-6, under the
POP_ROW   = 5               ; HUD and over the sign (clear of every arrow)
RADIUS2   = 400             ; grab when bx^2 + by^2 > 20^2
DANGER2   = 256             ; dot turns red past 16 px
SWEET2    = 36              ; sweet spot (the dot turns gold): inside 6 px
GRACE2    = 81              ; a slip out of the gold that stays inside 9 px...
GOLD_SLIP = 8               ; ...and comes back within 8 frames keeps a GOLD SURF
KICK_PX   = $0400           ; a track joint throws the dot 4 px (8.8)...
KICK_GRACE = 10             ; ...and its slip is forgiven 10 frames longer
                            ; alive (the dot flickers gold while it can be saved)
NUM_SEG   = 6
LEAN      = $0013           ; D-pad lean, 8.8 px/frame^2
LEAN_LIM  = 4               ; px your way: past this a held lean fades, then braces
                            ; (4/256 px/frame^2 less per px: lean_amt)
VMAX      = $0090           ; dot speed cap, 8.8 px/frame
WARN      = 40              ; frames of telegraph before every lurch
WARN_GAG  = 30              ; a gag's telegraph (the passengers give less notice)
GAG_PAY   = 100             ; riding a gag out without grabbing anything
; the trick the card never mentions, in frames before the stop (the brake's w_lt):
NH_WARN   = 69              ; the tell starts: the ring blinks gold, a tick every 8 frames
NH_OPEN   = 54              ; 15 frames on, the window opens: let go of the pad...
NH_CLOSE  = 40              ; ...by here (a 14-frame window). Then the brake eases and
                            ; you glide in: no touch from here to the stop
NH_PAY    = 100
TAP_T     = $0300           ; a tap on the solid arrow (a fresh press) catches you:
                            ; the dot heads for 3 px your side of the middle (8.8)
CATCH_CLEAN = 8             ; ...if no other way was pressed in the last 8 frames
BEAT      = 16              ; the solid arrow flashes every 16 frames while the leg is
                            ; gold: tap on the flash
GRAB_T    = 64              ; frames a grab gag takes (lunge, hold, walk back)
BASE_RIDE = 1000
GERM_PEN  = 40              ; (x40 is done with shifts in sb_score)
FAIL_STN  = 40              ; (x40 by shifts too)

; lurch kinds (course table)
K_DEP     = 0               ; pull out: pushes the dot back (left)
K_CL      = 1               ; curve left: pushes the dot down (toward us)
K_CR      = 2               ; curve right: pushes the dot up
K_BRK     = 3               ; brake into the next station: pushes forward
K_SIG     = 4               ; gag: signal problems, the emergency brake: forward
K_PACK    = 5               ; gag: a backpack swings round into you: back

; lurch states
LS_GAP    = 0
LS_WARN   = 1
LS_ACT    = 2
LS_END    = 3               ; doors open at Union

w_bx     = ev_ram + 0       ; balance offset, 8.8 px (signed)
w_by     = ev_ram + 2
w_vx     = ev_ram + 4
w_vy     = ev_ram + 6
w_fx     = ev_ram + 8       ; train force now (8.8, ramps toward the target)
w_fy     = ev_ram + 10
w_tx     = ev_ram + 12      ; train force target
w_ty     = ev_ram + 14
w_seg    = ev_ram + 16      ; stations reached 0-6
w_speed  = ev_ram + 18      ; train speed 8.8 px/frame (window scroll)
w_frac   = ev_ram + 20      ; scroll fraction
w_lp     = ev_ram + 22      ; course offset of the current lurch
w_ls     = ev_ram + 24      ; lurch state
w_lt     = ev_ram + 26      ; frames left in the state
w_germs  = ev_ram + 28
w_grab   = ev_ram + 30      ; frames left in a grab gag
w_gkind  = ev_ram + 32      ; 0 pole 1 backpack 2 lap 3 floor
w_kind   = ev_ram + 34      ; current lurch kind
w_str    = ev_ram + 36      ; its strength
w_dur    = ev_ram + 38      ; its length
w_popup  = ev_ram + 40
w_status = ev_ram + 42
w_stat_old = ev_ram + 44
w_done   = ev_ram + 46
w_over   = ev_ram + 48      ; 1 = the run is decided: no pause, no give-up
w_cur    = ev_ram + 50
w_shake  = ev_ram + 52
w_pal    = ev_ram + 54      ; palette of the passenger who boards at each stop
w_chain  = ev_ram + 56      ; STANDING SURF chain
w_golds  = ev_ram + 58      ; GOLD SURFS this ride (ev_stat 2)
w_clean  = ev_ram + 60      ; 1 = no grab yet this leg
w_style  = ev_ram + 62      ; style points
w_sweet  = ev_ram + 64      ; sweet-spot frame counter
w_press  = ev_ram + 66      ; frames since the D-pad was last touched
w_jolt   = ev_ram + 68      ; frames to the next track joint
w_col    = ev_ram + 70      ; last BG2 column streamed
w_src    = ev_ram + 72      ; 0 tunnel, 1 platform
w_rx     = ev_ram + 74      ; rider offset from home (px, signed)
w_ry     = ev_ram + 76
w_end    = ev_ram + 78      ; frames left at Union
w_buf    = ev_ram + 80      ; column buffer toggle (0 / 64)
w_sx     = ev_ram + 82      ; BG2 scroll, integer px 0-511
w_walk   = ev_ram + 84      ; boarding passenger x
w_gx     = ev_ram + 86      ; gag target offset
w_gy     = ev_ram + 88
w_r2     = ev_ram + 90      ; dot distance^2 this frame
w_bx_old = ev_ram + 92
w_hseg   = ev_ram + 94      ; station the HUD shows
NUM_GERMS = 8
G_X      = ev_ram + 96      ; germ particles: x, y (words), life
G_Y      = ev_ram + 112
G_L      = ev_ram + 128
E_TYPE   = ev_ram + 144     ; (evcommon's ev_alloc is unused here)
NUM_ENT  = 1
w_touch  = ev_ram + 150     ; 1 = the D-pad was used this leg
w_earn   = ev_ram + 152     ; stations reached on legs you actually rode
w_gold   = ev_ram + 154     ; 1 = the dot has stayed gold all this leg
w_hide   = ev_ram + 156     ; 1 = no ring yet (the countdown sits there)
w_startle = ev_ram + 158    ; frames the passengers jump after a grab
w_hollow = ev_ram + 160     ; draw_arrow: 1 = the hollow (warning) arrow
w_gag    = ev_ram + 162     ; 1 = this lurch is a gag and you haven't grabbed yet
w_dodge  = ev_ram + 164     ; gags ridden out
w_leg    = ev_ram + 166     ; build_course: leg, gag slot, lurches left
w_slot   = ev_ram + 168
w_left   = ev_ram + 170
w_skip   = ev_ram + 172     ; the leg past TMU without a gag
w_plen   = ev_ram + 174     ; popup buffer length
w_built  = ev_ram + 176     ; 1 = this ride's course is drawn up
w_pend   = ev_ram + 178     ; 1 = a callout waits to be drawn (w_ppal)
w_ppal   = ev_ram + 180
w_nhq    = ev_ram + 182     ; 1 = a NO HANDS callout waits for the surf one
w_nohand = ev_ram + 184     ; stops glided into hands-free
w_gtouch = ev_ram + 186     ; 1 = you leaned the arrow's way during this push
w_fr     = ev_ram + 188     ; the ride's own frame counter (low byte)
w_ease   = ev_ram + 190     ; 1 = the brake has eased into this stop (the ring's gold)
w_slip   = ev_ram + 192     ; frames the dot has been out of the gold (GOLD_SLIP)
w_pway   = ev_ram + 194     ; frames this push you pressed the solid arrow's way...
w_pagn   = ev_ram + 196     ; ...and the other way from the middle (RIDDEN: way > 0, against <= way)
w_legbad = ev_ram + 198     ; 1 = a push this leg wasn't ridden (no STANDING SURF, not a LEG LEANED)
w_nhw    = ev_ram + 200     ; 1 = the tell is up (the ring blinks gold)
w_sty    = ev_ram + 202     ; STYLE by source, 5 words (ev_style): SURF CHAIN, GOLD SURF X3,
                            ; DEAD CENTRE, GAGS RIDDEN, NO HANDS (w_style = their sum)
w_gred   = ev_ram + 212     ; 1 = the dot went red during this push (a gag isn't ridden out)
w_slim   = ev_ram + 214     ; extra frames a slip is forgiven (a track joint's: KICK_GRACE)
w_oddf   = ev_ram + 216     ; frames since a way other than the solid arrow's was pressed
COLBUF   = ev_ram + 256     ; two 28-word column buffers (256, 320)
EV_SEED  = ev_ram + 510
COURSE   = ev_ram + 512     ; this run's course: 4 bytes a lurch (<= 26 lurches)
PBUF     = ev_ram + 640     ; popup text (<= 28 characters + 0)

ST_NONE   = 0
ST_CLEAR  = 1               ; warnings: what's coming, no lean yet
ST_CURVE  = 2
ST_BRAKE  = 3
ST_GO     = 4               ; pushes: name the lean, the way the arrow points
ST_LEANU  = 5
ST_LEAND  = 6
ST_LEANL  = 7
ST_CRUISE = 8
ST_DOORS  = 9
ST_UNION  = 10
ST_SIGW   = 11              ; gag warnings and pushes
ST_SIGP   = 12
ST_PACKW  = 13
ST_PACKP  = 14
ST_TMU    = 15
ST_GLIDE  = 16              ; the brake eased: nothing pushes into the stop

.segment "BSS"
sb_seed: .res 2             ; this competition's ride (player 1 draws it)

; code + tables live in a graphics bank with room to spare (bank $85)
.segment "GFX0"
.a8
.i16

ev_subway:
    phb
    phk
    plb
    jsr sb_init
    jsr sb_draw
    jsl event_card
    jsr sb_hud_full
    jsl event_countdown         ; (no ring or sign yet: the big digits sit there)
    stz w_hide
    lda #0
    jsr station_sign
    lda #SONG_SUBWAY
    jsl music_play
@loop:
    jsl wait_frame
    lda ev_giveup
    beq @play
    lda w_over                  ; already PATIENT ZERO / at Union: too late to call it
    beq @quit
    stz ev_giveup
@play:
    jsr sb_update
    jsr sb_draw
    jsr sb_hud
    lda w_done
    beq @loop
    jsl music_stop
    jsr sb_score
    bra @card
@quit:
    jsl music_stop
    jsr sb_score                ; scored like a failed run (ev_fail 3 from the card)
@card:
    A16
    stz bg1x
    stz bg1y
    A8
    jsl wait_frame
    ; nothing under the HUD's top row may peek out round the card
    ldx #(2*32)
    A16
    lda #$0D20                  ; 32 x 13: rows 2-14
    sta tmp1
    A8
    stz tmp2
    lda #$20
    jsl txt_fill
    jsl score_card
    plb
    rtl

.include "evcommon.inc"

sb_init:
    jsl ppu_off
    jsl set_mode1_defaults
    jsl load_text_gfx
    VLOAD VRAM_BGTILES, subway_tiles, (subway_bg1 - subway_tiles)
    VLOAD VRAM_BG1MAP, subway_bg1, 2048
    ; both halves of BG2 start as the Bloor-Yonge platform wall
    VLOAD VRAM_BG2MAP, subway_platform, 2048
    VLOAD (VRAM_BG2MAP + $400), subway_platform, 2048
    PLOAD 32, subway_pal, 96
    VLOAD VRAM_OBJTILES, subway_spr, (subway_spr_pal - subway_spr)
    PLOAD 144, subway_spr_pal, 112    ; sprite palettes 1-7 (6: the ring gone gold,
                                      ; 7: the gold leg's glow and the beat flash)
    lda cur_player
    ldy #$0000
    jsl player_palette
    lda #$17
    sta tm_sh
    stz txt_bg
    lda #((VRAM_BG2MAP >> 8) | 1)
    sta BG2SC
    ldx #$0000
@c:
    stz ev_ram,x
    inx
    cpx #1024
    bne @c
    jsr seed_course             ; (again on the first frame of the ride)
    ldx #((264 >> 3) & 63)
    stx w_col
    lda #1
    sta w_src
    sta w_clean
    sta w_gold
    sta w_hide
    lda #3
    sta w_pal
    ldx #232
    stx w_walk
    ldx #80
    stx w_jolt
    ldx #ST_DOORS
    stx w_status
    ldx #$FF
    stx w_stat_old
    ldx #$0000
    stx w_lp
    jsr load_lurch
    rts

; every ride is a little different: the seed comes from rng (which the
; attract demo fixes), taken again on the ride's first frame. Within one
; competition every player rides the same train: player 1 draws the ride and
; the others get it again (sb_seed outlives ev_ram), so a heat is decided by
; the riding, never by who drew the kinder ride.
seed_course:
    lda cur_player
    beq @draw
    A16
    lda sb_seed
    bra @set
@draw:
    A16
    lda rng
    eor #$2E6B
    bne @sd
    lda #$2E6B
@sd:
    sta sb_seed
@set:
    sta EV_SEED
    A8
    jmp build_course

; ------------------------------------------------------------------
sb_update:
    inc w_fr
    lda w_built
    bne @b
    inc w_built
    jsr seed_course             ; (legs 1-2 never change: the lurch loaded stands)
@b:
    jsr train
    jsr balance
    jsr gag_move
    jsr germs_update
    ; patient zero: the ride ends once the 20th germ's gag has played out
    A16
    lda w_germs
    cmp #20
    bcc @alive
    lda w_grab
    bne @alive
    A8
    lda #1
    sta w_done
@alive:
    A16
    lda w_popup
    beq @p
    dec w_popup
    bne @p
    A8
    jsr popup_clear
    lda w_nhq                   ; the surf callout is done: now the NO HANDS one
    beq @p8
    stz w_nhq
    jsr nohands_popup
@p8:
    A16
@p:
    A8
    rts

; ------------------------------------------------------------------
; the course: kind, gap (frames before the warning), strength (8.8 push), length
; Legs 1-2 are always these (the lesson). From the TMU leg on, every ride
; jitters the gaps, lengths and pushes a little and slips a gag into three of
; the last four legs (build_course), so no two rides are the same.
course:
    ; Bloor-Yonge -> Wellesley: pull out, pull in. Gentle.
    .byte K_DEP, 40, 7, 90
    .byte K_BRK, 60, 7, 100
    ; -> College
    .byte K_DEP, 70, 8, 90
    .byte K_CL, 30, 7, 70
    .byte K_BRK, 40, 8, 100
    ; -> TMU (it was Dundas)
    .byte K_DEP, 70, 8, 90
    .byte K_CR, 20, 8, 80
    .byte K_CL, 20, 8, 60
    .byte K_BRK, 30, 8, 100
    ; -> Queen
    .byte K_DEP, 70, 9, 90
    .byte K_CL, 20, 9, 70
    .byte K_CR, 10, 9, 70
    .byte K_BRK, 30, 9, 100
    ; -> King: the S-bend
    .byte K_DEP, 70, 10, 90
    .byte K_CR, 20, 10, 50
    .byte K_CL, 1, 10, 50
    .byte K_BRK, 30, 10, 100
    ; -> Union: the long curve into the loop
    .byte K_DEP, 70, 10, 90
    .byte K_CL, 30, 11, 120
    .byte K_BRK, 20, 10, 100
leg_len: .byte 2, 3, 4, 4, 4, 3

; course -> COURSE, with this ride's jitter and gags
build_course:
    lda #4
    jsr ev_range
    clc
    adc #2
    sta w_skip                  ; legs 2-5: one of them goes without a gag
    ldx #$0000                  ; source
    ldy #$0000                  ; destination
    stz w_leg
@leg:
    phx
    ldx w_leg
    lda f:leg_len,x
    plx
    sta w_left
    lda #$FF
    sta w_slot
    lda w_leg
    cmp #2
    bcc @lurch
    cmp w_skip
    beq @lurch
    lda w_left                  ; a gag before any lurch but the pull-out
    dec a
    jsr ev_range
    inc a
    sta w_slot
@lurch:
    lda w_slot
    bne @copy
    ; the gag: signal problems or a backpack, 15-44 frames after the last push
    lda #2
    jsr ev_range
    clc
    adc #K_SIG
    sta COURSE,y
    lda #30
    jsr ev_range
    clc
    adc #15
    sta COURSE+1,y
    lda #3
    jsr ev_range
    clc
    adc #12
    sta COURSE+2,y
    lda #16
    jsr ev_range
    clc
    adc #40
    sta COURSE+3,y
    iny
    iny
    iny
    iny
@copy:
    lda f:course,x
    sta COURSE,y
    lda f:course+2,x
    sta COURSE+2,y
    lda f:course+1,x
    sta COURSE+1,y
    lda f:course+3,x
    sta COURSE+3,y
    lda w_leg
    cmp #2
    bcc @next
    ; jitter: gap -4..+11 (at least 1), length -8..+7, push +0/+1 past TMU
    lda #16
    jsr ev_range
    clc
    adc COURSE+1,y
    sec
    sbc #4
    beq @g1
    bcs @g2
@g1:
    lda #1
@g2:
    sta COURSE+1,y
    lda #16
    jsr ev_range
    clc
    adc COURSE+3,y
    sec
    sbc #8
    sta COURSE+3,y
    lda w_leg
    cmp #3
    bcc @next
    lda #2
    jsr ev_range
    clc
    adc COURSE+2,y
    sta COURSE+2,y
@next:
    inx
    inx
    inx
    inx
    iny
    iny
    iny
    iny
    dec w_slot
    dec w_left
    jne @lurch
    inc w_leg
    lda w_leg
    cmp #NUM_SEG
    jne @leg
    rts

; read the lurch at w_lp, start its gap
load_lurch:
    ldx w_lp
    lda COURSE,x
    sta w_kind
    stz w_kind+1
    lda COURSE+1,x
    sta w_lt
    stz w_lt+1
    lda COURSE+2,x
    sta w_str
    stz w_str+1
    lda COURSE+3,x
    sta w_dur
    stz w_dur+1
    stz w_ls
    lda w_kind
    cmp #K_SIG
    bcc @x
    sta w_gag                   ; (a gag never follows a gag)
@x:
    rts

; the train: lurch state machine, forces, speed
train:
    lda w_ls
    cmp #LS_WARN
    bne @n1
    jmp tr_warn
@n1:
    cmp #LS_ACT
    bne @n2
    jmp tr_act
@n2:
    cmp #LS_END
    bne tr_gap
    jmp tr_end

tr_gap:
    ; doors open at a stop, cruising between lurches
    lda #ST_CRUISE
    ldx w_speed
    bne @mv
    lda #ST_DOORS
    ldx w_seg
    cpx #3
    bne @mv
    lda #ST_TMU                 ; the sign says TMU
@mv:
    sta w_status
    jsr recover
    jsr jolts
    ; a gag ridden out: paid once its push has let go and nothing was grabbed
    lda w_gag
    bpl @ng
    A16
    lda w_fx
    ora w_fy
    A8
    bne @ng
    jsr gag_paid
@ng:
    A16
    dec w_lt
    A8
    beq @warn
    rts
@warn:
    lda #LS_WARN
    sta w_ls
    ldx #WARN
    lda w_kind
    cmp #K_SIG
    bcc @w
    ldx #WARN_GAG
    bra @w2
@w:
    lda w_gag                   ; (the next lurch came before the push let go)
    bpl @w2
    phx
    jsr gag_paid
    plx
@w2:
    stx w_lt
    lda w_kind
    asl a
    TAXB
    lda f:warn_status,x
    sta w_status
    ldx w_kind
    lda f:warn_sfx,x
    jsl sfx_play
    lda w_kind
    bne @nd
    ; please stand clear of the doors: the gold leg starts with the chime
    lda #1
    sta w_gold
    stz w_slip
    rts
@nd:
    cmp #K_BRK
    bne @x
    lda #1                      ; brake hiss: the station wall starts to stream past
    sta w_src
@x:
    rts

; per kind: (warning, push) status, the warning's sound, the push's sound,
; and which way it pushes the dot (x, y: 1, -1 or 0)
warn_status: .byte ST_CLEAR, ST_GO, ST_CURVE, ST_LEANU, ST_CURVE, ST_LEAND, ST_BRAKE, ST_LEANL
             .byte ST_SIGW, ST_SIGP, ST_PACKW, ST_PACKP
warn_sfx:    .byte SFX_CHIME, SFX_WHISTLE, SFX_WHISTLE, SFX_SPLASH, SFX_HORN, SFX_BACK
push_sfx:    .byte SFX_GO, SFX_WHISTLE, SFX_WHISTLE, SFX_SPLASH, SFX_CRASH, SFX_STEP
push_sx:     .byte $FF, 0, 0, 1, 1, $FF
push_sy:     .byte 0, 1, $FF, 0, 0, 0

tr_warn:
    ; (pulling out: the door chime's three notes at 40, 26 and 12 frames
    ; out, PLEASE STAND CLEAR, then GO at the push)
    jsr recover
    jsr jolts
    A16
    dec w_lt
    A8
    beq @go
    rts
@go:
    lda #LS_ACT
    sta w_ls
    ldx #$0000                  ; (a push counts as ridden by how you lean into it)
    stx w_pway
    stx w_pagn
    stz w_gred
    ldx w_dur
    stx w_lt
    lda w_kind
    asl a
    inc a
    TAXB
    lda f:warn_status,x
    sta w_status
    ; the push
    ldx w_kind
    lda f:push_sx,x
    jsr signed_str
    sta w_tx
    A8
    ldx w_kind
    lda f:push_sy,x
    jsr signed_str
    sta w_ty
    A8
    ldx w_kind
    lda f:push_sfx,x
    jsl sfx_play
    lda w_kind
    bne @x
    stz w_src                   ; tunnel from here
    jsr sign_clear
@x:
    rts

; A8 = 1, 0 or -1 -> A16 = w_str, 0 or -w_str
signed_str:
    A16
    and #$00FF
    tay
    lda #$0000
    cpy #$0000
    beq @x
    lda w_str
    cpy #$0001
    beq @x
    eor #$FFFF
    inc a
@x:
    rts

; after the emergency brake the train winds back up to speed
recover:
    A16
    lda w_speed
    beq @x
    cmp #$0600
    bcs @x
    adc #$0008
    sta w_speed
@x:
    A8
    rts

tr_act:
    lda w_kind
    cmp #K_DEP
    bne @nd
    ; pulling out: speed up
    A16
    lda w_speed
    clc
    adc #$0011
    cmp #$0600
    bcc @s1
    lda #$0600
@s1:
    sta w_speed
    A8
    bra @tick
@nd:
    cmp #K_BRK
    beq @brk
    cmp #K_SIG
    bne @cruise
    ; signal problems: the emergency brake judders the car to a crawl
    ; (on the ride's own clock: the global frame differs player to player)
    lda w_fr
    and #$03
    bne @tick
    lda #1
    sta w_shake
    A16
    lda w_speed
    sec
    sbc #$0030
    cmp #$0180
    bcs @s4
    lda #$0180
@s4:
    sta w_speed
    A8
    bra @tick
@brk:
    lda frame                   ; the brakes bite: the car judders
    and #$07
    bne @nj
    lda #1
    sta w_shake
@nj:
    jsr nh_tell
    A16
    lda w_speed
    sec
    sbc #$000F
    bcs @s2
    lda #$0000
@s2:
    cmp #$0040                  ; creep the last few px in
    bcs @s3
    lda #$0040
@s3:
    sta w_speed
    A8
    bra @tick
@cruise:
    jsr recover
    jsr jolts
@tick:
    A16
    dec w_lt
    A8
    beq @end
    rts
@end:
    ; the push lets go (it ramps out)
    ldx #$0000
    stx w_tx
    stx w_ty
    jsr ridden
    lda w_gag                   ; a gag's push is over: arm its pay
    beq @ng
    ora #$80
    sta w_gag
@ng:
    lda w_kind
    cmp #K_BRK
    bne @next
    jsr arrive
    lda w_seg
    cmp #NUM_SEG
    bcc @next
    lda #LS_END
    sta w_ls
    ldx #100
    lda w_nhq
    beq @e
    ldx #120                    ; (time for the NO HANDS callout)
@e:
    stx w_end
    lda #ST_UNION
    sta w_status
    rts
@next:
    A16
    lda w_lp
    clc
    adc #4
    sta w_lp
    A8
    jmp load_lurch

; a gag ridden out with no grab: +100 and a callout (if you leaned
; into it: standing there with your hands in your pockets isn't riding it)
gag_paid:
    lda w_gtouch
    bne @pay
    stz w_gag
    rts
@pay:
    A16
    lda #GAG_PAY
    ldx #6                      ; GAGS RIDDEN
    jsr add_style
    A8
    inc w_dodge
    LDPTR0 str_dodge1
    lda w_gag
    and #$7F
    cmp #K_SIG
    beq @s
    LDPTR0 str_dodge2
@s:
    stz w_gag
    lda #^str_dodge1
    sta ptr0+2
    jsr pb_start
    ldx #GAG_PAY
    stx tmp1
    jsr pb_plus
    lda #TP_GREEN
    ldx #80
    jsr pop_show
    SFX SFX_COIN
    rts

;- A16 = points, X = the ev_style slot x 2: into that source and the total
add_style:
    .a16
    pha
    clc
    adc w_sty,x
    sta w_sty,x
    pla
    clc
    adc w_style
    sta w_style
    rts
.a8

; Was the push that just let go RIDDEN? You pressed the solid arrow's way,
; and no longer the other way from the middle (a blind left-right wiggle
; leans against the train as much as with it: that isn't riding it).
; Ridden: the leg has been leaned (w_touch) and a gag pays (w_gtouch). Not
; ridden: this leg is no STANDING SURF and no LEG LEANED (w_legbad).
ridden:
    .a8
    stz w_gtouch
    jsr riding
    bcc @no
    lda #1
    sta w_touch
    lda w_gred                  ; a gag pays only if the dot stayed out of the red
    bne @ng
    lda w_pagn                  ; and you never pressed the push's way from the middle
    ora w_pagn+1
    bne @ng
    lda #1
    sta w_gtouch
@ng:
    rts
@no:
    lda #1
    sta w_legbad
    rts

; carry set = so far this push you're riding it (way > 0, against <= way)
riding:
    .a8
    A16
    lda w_pway
    beq @no
    lda w_pagn
    cmp w_pway
    beq @yes
    bcs @no
@yes:
    A8
    sec
    rts
@no:
    A8
    clc
    rts

; The tell for the trick the card never mentions, run every frame of a brake
; push (w_lt = frames to the stop). NH_WARN frames out, on a clean leg where
; you've ridden every push and are riding this one, with the dot out of the
; red: the ring starts blinking gold, with a tick every 8 frames. Let go of
; the pad between NH_OPEN and NH_CLOSE (15 frames after the tell starts, a
; 14-frame window) and at NH_CLOSE the brake eases: the push lets go, the
; arrow goes, the status says GLIDING IN..., a ding, and the ring stays gold
; while you glide in off the pad. Let go too soon, or hang on, and the tell
; just ends at NH_CLOSE. Off the pad, the rider finds their feet.
nh_tell:
    .a8
    lda w_ease
    bne @x
    lda w_lt
    cmp #NH_WARN
    bne @on
    lda w_clean
    beq @x
    lda w_touch
    beq @x
    lda w_legbad
    bne @x
    jsr riding
    bcc @x
    A16
    lda w_r2
    cmp #DANGER2
    A8
    bcs @x
    lda #1
    sta w_nhw
    bra @tick
@on:
    lda w_nhw
    beq @x
    lda w_clean                 ; (a grab ends it)
    beq @off
    lda w_lt
    cmp #NH_CLOSE
    beq @judge
    and #$07
    cmp #(NH_WARN & 7)
    bne @x
@tick:
    SFX SFX_TICK
@x:
    rts
@judge:
    ; off the pad now, and since no sooner than the window opened?
    A16
    lda w_press
    beq @off16
    cmp #(NH_OPEN - NH_CLOSE)    ; (w_press counts to the end of last frame)
    bcs @off16
    A8
    lda #1
    sta w_ease
    ldx #$0000
    stx w_tx
    stx w_ty
    lda #ST_GLIDE
    sta w_status
    SFX SFX_SELECT
    rts
@off16:
    A8
@off:
    stz w_nhw
    rts

str_dodge1: .byte "RODE OUT THE E-BRAKE!", 0
str_dodge2: .byte "DODGED THE BACKPACK!", 0

tr_end:
    A16
    dec w_end
    A8
    bne @x
    lda #1
    sta w_done
@x:
    rts

; pulled into a station
arrive:
    ldx #$0000
    stx w_speed
    lda #2                      ; the stop: a big bump (the car only)
    sta w_shake
    SFX SFX_BELL
    lda w_seg
    inc a
    jsr station_sign
    inc w_seg
    ; someone boards: swap the door passenger, walk them in
    lda w_pal
    inc a
    cmp #5
    bcc @pp
    lda #1
@pp:
    sta w_pal
    ldx #280
    stx w_walk
    ; STANDING SURF: a whole leg you rode (every push) without grabbing anything
    lda w_legbad
    bne @broke
    lda w_touch
    beq @broke
    lda w_clean
    beq @broke
    inc w_chain
    jsr no_hands
    jsr surf_popup
    bra @leg
@broke:
    stz w_chain
@leg:
    lda w_legbad                ; partial credit only for legs you rode
    bne @nt
    lda w_touch
    beq @nt
    inc w_earn
@nt:
    stz w_touch
    stz w_legbad
    stz w_ease
    stz w_nhw
    stz w_gold                  ; (the next gold leg starts at the chime)
    lda #1
    sta w_clean
    lda w_seg
    cmp #NUM_SEG
    bcc @x
    ; doors open at Union: the ride is decided
    lda #1
    sta w_over
    stz pause_ok
@x:
    rts

; +75 x chain (x3 if the dot stayed gold all leg), and say so:
;   "STANDING SURF CHAIN 2 +150"  /  "GOLD SURF CHAIN 2 X3 +450"
surf_popup:
    A16
    lda w_chain
    and #$00FF
    sta tmp1                    ; c
    asl a                       ; 2c
    sta tmp3
    asl a
    asl a                       ; 8c
    sta tmp4
    asl a
    asl a
    asl a                       ; 64c
    clc
    adc tmp4
    clc
    adc tmp3
    clc
    adc tmp1                    ; 75c
    sta tmp3
    ldx #0                      ; SURF CHAIN
    ldy w_gold
    beq @one
    inc w_golds
    asl a
    clc
    adc tmp3                    ; 225c
    sta tmp3
    ldx #2                      ; GOLD SURF X3
@one:
    jsr add_style
    A8
    LDPTR0 str_surf
    lda w_gold
    beq @lab
    LDPTR0 str_gsurf
@lab:
    lda #^str_surf
    sta ptr0+2
    jsr pb_start
    ldx w_chain
    stx tmp1
    jsr pb_num
    lda w_gold
    beq @n3
    LDPTR0 str_x3
    jsr pb_cat
@n3:
    ldx tmp3
    stx tmp1
    jsr pb_plus
    ldx #90
    lda w_nhq
    beq @t
    ldx #60                     ; (a NO HANDS callout follows)
@t:
    lda #TP_YELLOW
    jsr pop_show
    lda w_gold
    beq @c
    SFX SFX_NEXT                ; gold: the next-stop chime
    rts
@c:
    SFX SFX_COIN
    rts

str_surf:  .byte "STANDING SURF CHAIN ", 0

; Not on the card (the coach never says it): glide into a stop hands-free.
; The brake eased for you (you let go in the window, nh_tell) and you've
; stayed off the D-pad since, with the dot gold at the stop, on a clean leg:
; +100. Judged at the stop, paid with its callout (after the surf one).
no_hands:
    lda w_ease
    beq @x8
    A16
    lda w_press
    cmp #NH_CLOSE
    bcc @x
    lda w_r2
    cmp #SWEET2
    bcs @x
    A8
    lda #1
    sta w_nhq
    rts
@x:
    A8
@x8:
    rts

nohands_popup:
    jsl trick_seen
    A16
    lda #NH_PAY
    ldx #8                      ; NO HANDS
    jsr add_style
    A8
    inc w_nohand
    LDPTR0 str_nohands
    jsr pb_start
    ldx #NH_PAY
    stx tmp1
    jsr pb_plus
    lda #TP_GREEN
    ldx #50
    jsr pop_show
    SFX SFX_CHEER
    rts

str_nohands: .byte "LOOK MA, NO HANDS!", 0
str_gsurf: .byte "GOLD SURF CHAIN ", 0
str_x3:    .byte " X3", 0

; ---- callouts: a line built in PBUF, shown in a padded panel (rows 4-6)
; PBUF = the string at ptr0 (pb_cat: PBUF += it; same bank as the label)
pb_start:
    ldx #$0000
    stx w_plen
pb_cat:
    ldy #$0000
    ldx w_plen
@c:
    lda [ptr0],y
    sta PBUF,x
    beq @x
    iny
    inx
    bra @c
@x:
    stx w_plen
    rts

; PBUF += " +" tmp1
pb_plus:
    ldy w_plen
    lda #' '
    sta PBUF,y
    iny
    lda #'+'
    sta PBUF,y
    iny
    sty w_plen
    ; fall through
; PBUF += tmp1 in decimal
pb_num:
    ldx #$0000
@d:
    A16
    lda tmp1
    sta WRDIVL
    A8
    lda #10
    sta WRDIVB
    nop                         ; 16 cycles for the divide
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    A16
    lda RDDIVL
    sta tmp1
    A8
    lda RDMPYL
    clc
    adc #'0'
    pha
    inx
    lda tmp1
    ora tmp1+1
    bne @d
    ldy w_plen
@p:
    pla
    sta PBUF,y
    iny
    dex
    bne @p
    lda #0
    sta PBUF,y
    sty w_plen
    rts

; A = text palette, X = frames: PBUF in a panel, centred. Drawn by sb_hud
; at the end of the frame (an arrival can bring the sign, a surf callout and
; a grab in one frame: the last callout wins)
pop_show:
    sta w_ppal
    stx w_popup
    lda #1
    sta w_pend
    rts

pop_draw:
    stz w_pend
    lda w_ppal
    pha
    jsr popup_clear
    lda w_plen
    clc
    adc #4
    sta tmp1                    ; width: the text + a 2-cell margin each side
    lda #3
    sta tmp1+1
    lda #32
    sec
    sbc tmp1
    lsr a
    A16
    and #$00FF
    clc
    adc #(POP_TOP*32)
    tax
    A8
    lda #$20
    jsl txt_box
    LDPTR0 PBUF
    stz ptr0+2
    lda #TXT_WIN
    sta txt_bg
    pla
    asl a
    asl a
    ora #$20
    ldx #(POP_ROW*32)
    jsl txt_print_centre
    stz txt_bg
    rts

; track joints: little random kicks while cruising, from the third leg on
jolts:
    lda w_seg
    cmp #2
    bcc @x
    A16
    lda w_speed
    cmp #$0600
    A8
    bcc @x
    A16
    dec w_jolt
    A8
    bne @x
    lda #70
    jsr ev_range
    A16
    and #$00FF
    clc
    adc #50
    sta w_jolt
    A8
    jsr kick
@x:
    rts

; a track joint throws the dot KICK_PX px one way (and a little more with
; its speed): out of the gold from the middle. The gold forgives a joint's
; slip KICK_GRACE frames longer: get it back quick
kick:
    lda #4
    jsr ev_range
    asl a
    TAXB
    lda w_grab
    bne @s
    A16
    lda f:kick_vx,x
    clc
    adc w_vx
    sta w_vx
    lda f:kick_vy,x
    clc
    adc w_vy
    sta w_vy
    lda f:kick_px,x
    clc
    adc w_bx
    sta w_bx
    lda f:kick_py,x
    clc
    adc w_by
    sta w_by
    A8
    lda #KICK_GRACE
    sta w_slim
@s:
    lda #1
    sta w_shake
    SFX SFX_STEP
    rts

KICK = $0040
kick_vx: .word KICK, $10000 - KICK, $0000, $0000
kick_vy: .word $0000, $0000, KICK, $10000 - KICK
kick_px: .word KICK_PX, $10000 - KICK_PX, $0000, $0000
kick_py: .word $0000, $0000, KICK_PX, $10000 - KICK_PX

; ------------------------------------------------------------------
; balance: train force + your lean + a gentle tip-over, heavily damped
balance:
    A16
    lda w_press
    cmp #999
    bcs @pc
    inc w_press
@pc:
    ; forces ramp toward their targets, 1/256 per frame
    lda w_fx
    cmp w_tx
    beq @rx
    bmi @ux
    dec w_fx
    bra @rx
@ux:
    inc w_fx
@rx:
    lda w_fy
    cmp w_ty
    beq @ry
    bmi @uy
    dec w_fy
    bra @ry
@uy:
    inc w_fy
@ry:
    A8
    lda w_ls
    cmp #LS_END
    bne @live
    rts                         ; doors open at Union: you made it
@live:
    A16
    lda w_grab
    beq @free
    dec w_grab
    A8
    rts
@free:
    .a16
    lda pad
    and #(PAD_LEFT | PAD_RIGHT | PAD_UP | PAD_DOWN)
    beq @nopad
    stz w_press
    ; while the SOLID arrow is up, count the frames you press its way and
    ; the frames you press against it (a push is RIDDEN by these: ridden),
    ; and a fresh press its way (a tap) catches you. A hold carried over from
    ; the last stop or made on the hollow arrow counts for nothing
    A8
    lda w_ls
    cmp #LS_ACT
    bne @nt
    lda w_ease                  ; (the brake eased: no arrow)
    bne @nt
    lda w_kind
    asl a
    TAXB
    A16
    lda f:lean_pad,x
    and pad
    beq @nw
    inc w_pway
    lda f:lean_pad,x            ; a tap its way, with nothing else pressed for
    and pad_new                 ; CATCH_CLEAN frames, catches you
    beq @nw
    lda w_oddf
    cmp #CATCH_CLEAN
    bcc @nw
    jsr catch
@nw:
    .a16
    lda f:lean_pad,x
    eor #(PAD_LEFT | PAD_RIGHT | PAD_UP | PAD_DOWN)
    and pad
    beq @nodd
    stz w_oddf                  ; (any other way: no catch for a while)
@nodd:
    lda f:opp_pad,x
    and pad
    beq @nt
    jsr against
@nt:
    A16
@nopad:
    lda w_oddf
    cmp #999
    bcs @oc
    inc w_oddf
@oc:
    ; on the hollow arrow a lean is half strength and you find your feet
    ; again: getting ready early never tips you over
    lda #LEAN
    ldx w_ls
    cpx #LS_WARN
    bne @full
    lsr a
@full:
    sta tmp4
    ; a held lean settles: full strength until the dot is LEAN_LIM px your
    ; way, then it fades, and further out holding on braces you back. So
    ; holding the arrow's way parks the dot in the white, a little past the
    ; middle, and never carries it into the rim (the gold takes taps)
    lda pad
    bit #PAD_LEFT
    beq @nl
    lda w_bx
    jsr int_part
    eor #$FFFF
    inc a
    jsr lean_amt
    eor #$FFFF
    inc a
    clc
    adc w_vx
    sta w_vx
@nl:
    lda pad
    bit #PAD_RIGHT
    beq @nr
    lda w_bx
    jsr int_part
    jsr lean_amt
    clc
    adc w_vx
    sta w_vx
@nr:
    lda pad
    bit #PAD_UP
    beq @nu
    lda w_by
    jsr int_part
    eor #$FFFF
    inc a
    jsr lean_amt
    eor #$FFFF
    inc a
    clc
    adc w_vy
    sta w_vy
@nu:
    lda pad
    bit #PAD_DOWN
    beq @nd
    lda w_by
    jsr int_part
    jsr lean_amt
    clc
    adc w_vy
    sta w_vy
@nd:
    ; v += force + offset/256: while a lurch pushes, an upright body tips
    ; further its way once it leans; otherwise (and across the push) the
    ; rider finds their feet (the same term, the other way)
    lda w_bx
    jsr int_part
    ldy w_tx
    jsr tip
    clc
    adc w_fx
    clc
    adc w_vx
    jsr damp
    sta w_vx
    clc
    adc w_bx
    sta w_bx
    lda w_by
    jsr int_part
    ldy w_ty
    jsr tip
    clc
    adc w_fy
    clc
    adc w_vy
    jsr damp
    sta w_vy
    clc
    adc w_by
    sta w_by
    ; distance^2 (integer px)
    lda w_bx
    jsr int_part
    jsr square
    sta tmp1
    lda w_by
    jsr int_part
    jsr square
    clc
    adc tmp1
    sta w_r2
    cmp #RADIUS2
    bcc @in
    A8
    jmp grab
@in:
    .a16
    cmp #DANGER2
    bcc @nred
    A8
    ldx #1
    stx w_gred
    A16
    lda w_r2
@nred:
    ; the dot left the gold middle: no GOLD SURF this leg, unless it was a
    ; slip (inside GRACE2, back within GOLD_SLIP frames: the dot flickers)
    cmp #SWEET2
    bcc @gold
    cmp #GRACE2
    A8
    bcs @lost
    inc w_slip
    lda w_slim
    clc
    adc #GOLD_SLIP
    cmp w_slip
    bcs @slip
@lost:
    lda w_gold                  ; the leg's gold just went: a sad bloop
    beq @slip
    stz w_gold
    SFX SFX_SIP
@slip:
    A16
    bra @x
@gold:
    A8
    stz w_slip
    stz w_slim
    A16
    ; DEAD CENTRE: in the gold while a lurch pushes and you're working it,
    ; a point every 2 frames; dead on the middle (inside 2 px), every frame
    lda w_fx
    ora w_fy
    beq @x
    lda w_press
    cmp #40
    bcs @x
    A8
    lda w_gold                  ; (only while the leg can still be gold)
    beq @x8
    jsr riding                  ; (wiggling against the train isn't working it)
    A16
    bcc @x
    lda w_r2
    cmp #4
    bcc @pt
    inc w_sweet
    lda w_sweet
    and #$0001
    bne @x
@pt:
    inc w_style
    inc w_sty+4                 ; DEAD CENTRE
@x:
    A8
@x8:
    rts

; per lurch kind: the way the solid arrow points (against the push), the
; other way, and for a catch: the axis (0 x, 2 y) and 1 if the arrow points
; the negative way (left, up)
lean_pad: .word PAD_RIGHT, PAD_UP, PAD_DOWN, PAD_LEFT, PAD_LEFT, PAD_RIGHT
opp_pad:  .word PAD_LEFT, PAD_DOWN, PAD_UP, PAD_RIGHT, PAD_RIGHT, PAD_LEFT
catch_ax: .word 0, 2, 2, 0, 0, 0
catch_ng: .word 0, 1, 0, 1, 1, 0

; Pressing against the solid arrow counts against riding the push only
; while the dot is neither over on the arrow's side nor heading that way:
; checking a dot that's running your way is balancing, pressing the push's
; way when nothing needs checking is a wiggle. X = kind x 2 (kept)
against:
    .a16
    phx
    lda f:catch_ng,x
    sta tmp3
    lda f:catch_ax,x
    tax
    lda w_vx,x
    ldy tmp3
    beq @v
    eor #$FFFF
    inc a
@v:
    cmp #$0001
    bpl @x                      ; heading the arrow's way: a check
    lda w_bx,x
    ldy tmp3
    beq @p
    eor #$FFFF
    inc a
@p:
    jsr int_part
    cmp #$0001
    bpl @x                      ; over on the arrow's side: a correction
    inc w_pagn
@x:
    plx
    rts

; A tap on the solid arrow (a fresh press its way, with no other way
; pressed for CATCH_CLEAN frames) catches you: on the push's axis the dot's
; speed your way becomes at least an eighth of the way to TAP_T past the
; middle, if it isn't past that already. So tapping on the beat keeps the dot
; in the gold whatever the push, while a hold parks it in the white (and
; mashing every way catches nothing). X = kind x 2 (kept)
catch:
    .a16
    phx
    lda f:catch_ng,x
    sta tmp3
    lda f:catch_ax,x
    tax
    lda w_bx,x
    ldy tmp3
    beq @p1
    eor #$FFFF
    inc a
@p1:
    eor #$FFFF
    inc a
    clc
    adc #TAP_T                  ; TAP_T - offset (the arrow's way +)
    bmi @x                      ; already past it
    jsr asr3
    sta tmp5
    lda w_vx,x
    ldy tmp3
    beq @p2
    eor #$FFFF
    inc a
@p2:
    sec
    sbc tmp5
    bpl @x                      ; already heading there faster
    lda tmp5
    ldy tmp3
    beq @p3
    eor #$FFFF
    inc a
@p3:
    sta w_vx,x
@x:
    plx
    rts

; A16 = how far the dot is the way you press (px, signed) -> A16 = the lean
; (8.8 px/frame^2): tmp4 up to LEAN_LIM px, then BRACE less per px, down to
; -tmp4 (holding on pulls you back toward the middle)
lean_amt:
    .a16
    sec
    sbc #LEAN_LIM
    bmi @full
    beq @full
    asl a
    asl a                       ; x BRACE (4)
    sta tmp3
    lda tmp4
    sec
    sbc tmp3
    bpl @x
    clc
    adc tmp4
    bmi @min
    sec
    sbc tmp4
    rts
@min:
    lda tmp4
    eor #$FFFF
    inc a
    rts
@full:
    lda tmp4
@x:
    rts

; A16: the tip-over term (offset px / 256), Y = the push on this axis.
; Only the way a lurch pushes tips you over; across it (a wrong lean, a
; late hold left over from the last arrow) and between lurches the rider
; finds their feet: the term is negated
tip:
    .a16
    ldx w_ls
    cpx #LS_ACT
    bne @feet
    cpy #$0000
    bne @x
@feet:
    eor #$FFFF
    inc a
@x:
    rts

; A16: v -> v - v/8, clamped to +-VMAX
damp:
    .a16
    sta tmp2
    jsr asr3
    eor #$FFFF
    inc a
    clc
    adc tmp2
    bmi @neg
    cmp #VMAX
    bcc @ok
    lda #VMAX
    rts
@neg:
    cmp #($10000 - VMAX)
    bcs @ok
    lda #($10000 - VMAX)
@ok:
    rts

; A16 helpers
asr3:
    .a16
    cmp #$8000
    ror a
asr2:
    cmp #$8000
    ror a
    cmp #$8000
    ror a
    rts

; signed 8.8 -> signed integer (A16)
int_part:
    .a16
    xba
    and #$00FF
    cmp #$0080
    bcc @p
    ora #$FF00
    rts
@p:
    and #$00FF                  ; N/Z from the result, not from the cmp
    rts

; A16 = |A| ^ 2, capped at $7FFF
square:
    .a16
    cmp #$0000
    bpl @p
    eor #$FFFF
    inc a
@p:
    cmp #128
    bcc @ok
    lda #$7FFF
    rts
@ok:
    A8
    sta WRMPYA
    sta WRMPYB
    nop
    nop
    nop
    nop
    A16
    lda RDMPYL
    rts
.a8

; blank the callout panel
popup_clear:
    ldx #(POP_TOP*32)
    A16
    lda #$0320
    sta tmp1
    A8
    stz tmp2
    lda #$20
    jsl txt_fill
    rts

; lost it: grab the nearest thing (and act it out)
grab:
    A16
    lda w_bx
    bpl @ax
    eor #$FFFF
    inc a
@ax:
    sta tmp1
    lda w_by
    bpl @ay
    eor #$FFFF
    inc a
@ay:
    cmp tmp1
    A8
    bcs @lateral
    lda w_bx+1
    bmi @back
    lda #1                      ; forward: face-first into the backpack
    ldy #2
    bra @set
@back:
    lda #0                      ; back: the sticky pole
    ldy #1
    bra @set
@lateral:
    lda w_by+1
    bmi @lap
    lda #3                      ; toward us: hands on the floor
    ldy #1
    bra @set
@lap:
    lda #2                      ; up, toward the seats: a stranger's lap
    ldy #2
@set:
    sta w_gkind
    stz w_clean
    stz w_gold
    stz w_gag                   ; (a gag that made you grab pays nothing)
    ldx #24
    stx w_startle
    A16
    tya
    clc
    adc w_germs
    cmp #20
    bcc @alive
    lda #20                     ; (a 2-germ grab at 19 still stops at twenty)
    sta w_germs
    A8
    lda #1                      ; PATIENT ZERO: decided, no pausing out of it
    sta w_over
    stz pause_ok
    A16
    bra @pz
@alive:
    sta w_germs
@pz:
    stz w_bx
    stz w_by
    stz w_vx
    stz w_vy
    lda #GRAB_T
    sta w_grab
    lda w_gkind
    and #$00FF
    asl a
    tax
    lda f:gag_dx,x
    sta w_gx
    lda f:gag_dy,x
    sta w_gy
    A8
    SFX SFX_GROAN
    lda w_gkind
    A16
    and #$00FF
    asl a
    tax
    lda f:grab_msgs,x
    sta ptr0
    A8
    lda #^grab_msgs
    sta ptr0+2
    lda w_over                  ; the twentieth germ: everyone keeps their distance
    beq @msg
    LDPTR0 str_pz
@msg:
    jsr pb_start
    lda #TP_GREEN
    ldx #70
    jmp pop_show

; where each gag takes the rider (offset from home, px)
gag_dx: .word $10000 - 22, 34, $10000 - 40, 4
gag_dy: .word 0, 0, $10000 - 60, 2

grab_msgs: .addr gm0, gm1, gm2, gm3
gm0: .byte "GRABBED THE STICKY POLE!", 0
gm1: .byte "FACE-FIRST IN A BACKPACK!", 0
gm2: .byte "SAT ON A STRANGER! SORRY!", 0
gm3: .byte "HANDS ON THE FLOOR. EW!", 0
str_pz: .byte "PATIENT ZERO! MIND THE GAP!", 0

; the rider's gag: lunge to the target, hold (germs!), walk back
gag_move:
    A16
    lda w_grab
    beq @home
    cmp #(GRAB_T - 14)
    bcs @lunge
    cmp #24
    bcs @hold
@home:
    ; walk back to the spot, 3 px a frame
    lda #$0000
    sta tmp1
    sta tmp2
    lda #3
    bra @step
@lunge:
    lda w_gx
    sta tmp1
    lda w_gy
    sta tmp2
    lda #5
    bra @step
@hold:
    cmp #(GRAB_T - 15)
    bne @x
    A8
    jsr spawn_germs
    A16
@x:
    A8
    rts
@step:
    .a16
    sta tmp3
    ; x toward tmp1
    lda w_rx
    sec
    sbc tmp1
    beq @dy
    bmi @xl
    cmp tmp3
    bcc @xs
    lda w_rx
    sec
    sbc tmp3
    sta w_rx
    bra @dy
@xl:
    eor #$FFFF
    inc a
    cmp tmp3
    bcc @xs
    lda w_rx
    clc
    adc tmp3
    sta w_rx
    bra @dy
@xs:
    lda tmp1
    sta w_rx
@dy:
    lda w_ry
    sec
    sbc tmp2
    beq @done
    bmi @yl
    cmp tmp3
    bcc @ys
    lda w_ry
    sec
    sbc tmp3
    sta w_ry
    bra @done
@yl:
    eor #$FFFF
    inc a
    cmp tmp3
    bcc @ys
    lda w_ry
    clc
    adc tmp3
    sta w_ry
    bra @done
@ys:
    lda tmp2
    sta w_ry
@done:
    A8
    rts

; a puff of germs around the hand
spawn_germs:
    ldx #$0000
@g:
    stx w_cur
    lda #24
    jsl rand_range
    ldx w_cur
    clc
    adc #(RIDER_X - 12)
    clc
    adc w_rx
    sta G_X,x
    stz G_X+1,x
    lda #16
    jsl rand_range
    ldx w_cur
    clc
    adc #(RIDER_Y - 40)
    clc
    adc w_ry
    sta G_Y,x
    stz G_Y+1,x
    lda #40
    sta G_L,x
    stz G_L+1,x
    inx
    inx
    cpx #(NUM_GERMS*2)
    bne @g
    rts

germs_update:
    ldx #$0000
@g:
    lda G_L,x
    beq @n
    dec G_L,x
    lda frame
    and #$01
    bne @n
    A16
    dec G_Y,x
    A8
@n:
    inx
    inx
    cpx #(NUM_GERMS*2)
    bne @g
    rts

; station A (0 Bloor-Yonge .. 6 Union) in a box over the windows, on the
; platform's white name band
station_sign:
    sta w_cur
    lda #TXT_WIN
    sta txt_bg
    ldx #(SIGN_ROW*32 + 8)
    A16
    lda #$0310
    sta tmp1
    A8
    lda #$20
    jsl txt_box
    lda w_cur
    A16
    and #$00FF
    asl a
    tax
    lda f:sign_names,x
    sta ptr0
    A8
    lda #^station_names
    sta ptr0+2
    ldx #((SIGN_ROW+1)*32)
    lda #($20 | (TP_WHITE << 2))
    jsl txt_print_centre
    stz txt_bg
    rts

sign_clear:
    ldx #(SIGN_ROW*32 + 8)
    A16
    lda #$0310
    sta tmp1
    A8
    stz tmp2
    lda #$20
    jsl txt_fill
    rts

sign_names:
    .addr sn_bloor
station_names:
    .addr sn_well, sn_coll, sn_dund, sn_queen, sn_king, sn_union, sn_union
sn_bloor: .byte "BLOOR-YONGE", 0
sn_well:  .byte "WELLESLEY", 0
sn_coll:  .byte "COLLEGE", 0
sn_dund:  .byte "TMU", 0         ; (it was Dundas until 2024)
sn_queen: .byte "QUEEN", 0
sn_king:  .byte "KING", 0
sn_union: .byte "UNION", 0

; ------------------------------------------------------------------
sb_draw:
    jsl oam_clear
    jsr scroll_bg2
    ; the car body sways with the push: back/forward on go/brake, a tilt on curves
    A16
    lda w_fx
    cmp #$8000
    ror a                       ; go/brake: up to 5 px
    sta bg1x
    lda w_fy
    jsr asr2
    sta tmp1
    ; rattle when fast
    lda w_speed
    cmp #$0300
    bcc @still
    lda frame
    and #$0006
    beq @still
    inc tmp1
@still:
    A8
    lda w_shake                 ; a bump: 2 px (track joint, brakes), 4 (the stop)
    beq @ns
    stz w_shake
    asl a
    A16
    and #$00FF
    clc
    adc tmp1
    sta tmp1
    A8
@ns:
    A16
    lda tmp1
    sta bg1y
    A8
    jsr draw_germs
    jsr draw_ring
    jsr draw_rider
    jsr draw_people
    rts

; BG2: scroll with the train; stream the column coming in at the right edge
scroll_bg2:
    A16
    lda w_frac
    and #$00FF
    clc
    adc w_speed
    pha
    and #$00FF
    sta w_frac
    pla
    xba
    and #$00FF
    clc
    adc w_sx
    and #$01FF
    sta w_sx
    sta bg2x
    stz bg2y
    clc
    adc #264
    lsr a
    lsr a
    lsr a
    and #$003F
    sta tmp4
    A8
@more:
    A16
    lda w_col
    cmp tmp4
    A8
    beq @x
    A16
    inc a
    and #$003F
    sta w_col
    A8
    jsr put_col
    bra @more
@x:
    rts

; queue BG2 column w_col (rows 0-27) from the tunnel or the platform map
put_col:
    A16
    lda w_buf
    eor #$0040
    sta w_buf
    tay                         ; destination offset in COLBUF
    lda #28
    sta tmp2
    lda w_col
    and #$001F
    asl a
    tax                         ; source byte offset (row 0)
    A8
    lda w_src
    bne @pl
    A16
    lda w_col
    and #$0020
    beq @tl
    txa
    clc
    adc #2048                   ; the right-hand 32x32 screen
    tax
@tl:
    lda f:subway_tunnel,x
    sta COLBUF,y
    txa
    clc
    adc #64
    tax
    iny
    iny
    dec tmp2
    bne @tl
    bra @q
@pl:
    A16
@pll:
    lda f:subway_platform,x
    sta COLBUF,y
    txa
    clc
    adc #64
    tax
    iny
    iny
    dec tmp2
    bne @pll
@q:
    .a16
    lda w_buf
    clc
    adc #.loword(COLBUF)
    sta ptr0
    lda #56
    sta tmp0
    lda w_col
    and #$0020
    beq @h0
    lda #$0400
@h0:
    sta tmp1
    lda w_col
    and #$001F
    clc
    adc tmp1
    clc
    adc #VRAM_BG2MAP
    tax
    A8
    lda #^COLBUF
    sta ptr0+2
    lda #$81                    ; VRAM +32 words per write: a column
    jsl dma_queue
    rts

draw_ring:
    lda w_hide
    beq @on
    rts
@on:
    ; arrow first (in front), then the dot, then the disc
    jsr draw_arrow
    A16
    lda w_bx
    jsr int_part
    clc
    adc #RING_X
    sta spr_x
    lda w_by
    jsr int_part
    clc
    adc #RING_Y
    sta spr_y
    A8
    lda #$3A
    sta tmp5
    stz tmp5+1
    lda w_grab
    ora w_grab+1
    beq @live
    LDPTR1 ms_dot_off
    ldx #MS_DOT_OFF_BASE
    bra @d
@live:
    A16
    lda w_r2
    cmp #DANGER2
    bcs @bad
    cmp #SWEET2
    A8
    bcs @ok
    LDPTR1 ms_dot_sweet
    ldx #MS_DOT_SWEET_BASE
    bra @d
@ok:
    ; a slip from a gold leg that can still be saved: it flickers gold
    lda w_gold
    beq @ok2
    lda frame
    and #$02
    beq @ok2
    LDPTR1 ms_dot_sweet
    ldx #MS_DOT_SWEET_BASE
    bra @d
@ok2:
    LDPTR1 ms_dot_ok
    ldx #MS_DOT_OK_BASE
    bra @d
@bad:
    A8
    LDPTR1 ms_dot_bad               ; red: it pulses, so the danger reads
    ldx #MS_DOT_BAD_BASE
    lda frame
    and #$08
    beq @d
    LDPTR1 ms_dot_bad2
    ldx #MS_DOT_BAD2_BASE
@d:
    stx tmp6
    jsl oam_meta
    ldx #RING_X
    stx spr_x
    ldx #RING_Y
    stx spr_y
    LDPTR1 ms_ring
    ldx #MS_RING_BASE
    stx tmp6
    lda #$3A
    sta tmp5
    stz tmp5+1
    jsr ring_pal
    jsl oam_meta
    rts

; The ring's palette. The tell (nh_tell): the whole ring blinks gold
; (sprite palette 6), then stays gold while you glide in off the pad.
; Otherwise, while this leg can still be a GOLD SURF (from the STAND CLEAR
; chime till the stop, while the dot hasn't left the gold), its sweet spot
; glows gold (palette 7).
ring_pal:
    .a8
    lda w_nhw
    beq @glow
    lda w_ease
    bne @eased
    lda w_lt
    and #$04
    bne @gold
    bra @glow
@eased:
    A16
    lda w_lt
    clc
    adc w_press                 ; off the pad since the brake eased?
    cmp #NH_CLOSE
    A8
    bcc @glow
@gold:
    lda #$3C
    sta tmp5
    rts
@glow:
    lda w_gold
    beq @x
    lda #$3E
    sta tmp5
@x:
    rts

; the lean arrow, pointing the way to press. Warning: a HOLLOW arrow that
; blinks (faster as it nears) = get ready. Push: SOLID = lean now.
draw_arrow:
    stz w_hollow                    ; 0 solid, 1 hollow
    lda w_ease                      ; the brake eased: nothing to lean against
    jne @x
    lda w_ls
    cmp #LS_ACT
    beq @show
    cmp #LS_WARN
    jne @x
    inc w_hollow
    lda w_lt
    cmp #16
    bcc @fast
    and #$08
    jeq @x
    bra @show
@fast:
    and #$04
    jeq @x
@show:
    lda w_kind
    asl a
    asl a
    TAXB
    A16
    lda f:arrow_tab,x
    clc
    adc #RING_X
    sta spr_x
    lda f:arrow_tab+2,x
    clc
    adc #RING_Y
    sta spr_y
    A8
    lda #$3A
    sta tmp5
    lda w_kind
    TAXB
    lda f:arrow_flip,x
    sta tmp5+1
    lda f:arrow_lr,x
    bne @r
    lda w_hollow
    bne @uo
    LDPTR1 ms_arrow_u
    ldx #MS_ARROW_U_BASE
    bra @d
@uo:
    LDPTR1 ms_arrow_uo
    ldx #MS_ARROW_UO_BASE
    bra @d
@r:
    lda w_hollow
    bne @ro
    LDPTR1 ms_arrow_r
    ldx #MS_ARROW_R_BASE
    bra @d
@ro:
    LDPTR1 ms_arrow_ro
    ldx #MS_ARROW_RO_BASE
@d:
    stx tmp6
    jsr beat_pal
    jsl oam_meta
    lda w_hollow
    bne @x
    ; solid: a second arrow further out, so "lean now" reads as a double
    ; chevron, never as the hollow warning
    lda w_kind
    asl a
    asl a
    TAXB
    A16
    lda f:arrow_step,x
    clc
    adc spr_x
    sta spr_x
    lda f:arrow_step+2,x
    clc
    adc spr_y
    sta spr_y
    A8
    jsl oam_meta
@x:
    rts

; While the leg can still be a GOLD SURF the solid arrow flashes white for
; 4 frames every BEAT, from the moment it goes solid: tap on the flash
beat_pal:
    .a8
    lda w_hollow
    bne @x
    lda w_gold
    beq @x
    lda w_dur
    sec
    sbc w_lt                    ; frames since the push started
    and #(BEAT - 1)
    cmp #4
    bcs @x
    lda #$3E
    sta tmp5
@x:
    rts

; per kind: x, y offsets; flips (bit 6 h, bit 7 v)
arrow_tab:  .word ARROW_D, 0,  0, $10000 - ARROW_D,  0, ARROW_D,  $10000 - ARROW_D, 0
            .word $10000 - ARROW_D, 0,  ARROW_D, 0
arrow_step: .word 11, 0,  0, $10000 - 11,  0, 11,  $10000 - 11, 0
            .word $10000 - 11, 0,  11, 0
arrow_flip: .byte 0, 0, $80, $40, $40, 0
arrow_lr:   .byte 1, 0, 0, 1, 1, 1      ; 1 = the left/right arrow art

draw_rider:
    A16
    lda #RIDER_X
    clc
    adc w_rx
    sta spr_x
    lda #RIDER_Y
    clc
    adc w_ry
    sta spr_y
    ; standing passengers and the rider lurch with the push (the car
    ; body moves the other way: see sb_draw)
    lda w_fx
    jsr asr3
    clc
    adc spr_x
    sta spr_x
    A8
    lda #$30
    sta tmp5
    stz tmp5+1
    lda w_grab
    beq @free
    cmp #24
    bcc @walk
    lda w_gkind
    clc
    adc #6                      ; pole, face, sit, floor
    bra @f
@walk:
    lda frame
    lsr a
    lsr a
    lsr a
    and #$01
    clc
    adc #10
    bra @f
@free:
    ; walking back still?
    A16
    lda w_rx
    ora w_ry
    A8
    beq @lean
    lda frame
    lsr a
    lsr a
    lsr a
    and #$01
    clc
    adc #10
    bra @f
@lean:
    ; lean frames from the balance offset
    A16
    lda w_by
    jsr int_part
    bpl @ay
    eor #$FFFF
    inc a
@ay:
    cmp #12
    A8
    bcc @lx
    lda #5                      ; arms flailing
    bra @f
@lx:
    A16
    lda w_bx
    jsr int_part
    A8
    cmp #$80
    bcs @neg
    cmp #10
    bcs @f2
    cmp #4
    bcs @f1
    lda #0
    bra @f
@f1:
    lda #3
    bra @f
@f2:
    lda #4
    bra @f
@neg:
    cmp #($100 - 9)
    bcc @b2
    cmp #($100 - 3)
    bcc @b1
    lda #0
    bra @f
@b1:
    lda #1
    bra @f
@b2:
    lda #2
@f:
    asl a
    TAXB
    lda f:rider_lo,x
    sta ptr1
    lda f:rider_lo+1,x
    sta ptr1+1
    lda #^ms_up
    sta ptr1+2
    lda f:rider_base,x
    sta tmp6
    lda f:rider_base+1,x
    sta tmp6+1
    jsl oam_meta
    rts

rider_lo:   .addr ms_up, ms_lb1, ms_lb2, ms_lf1, ms_lf2, ms_wobble, ms_pole, ms_face, ms_sit, ms_floor
            .addr ms_walk0, ms_walk1
rider_base: .word MS_UP_BASE, MS_LB1_BASE, MS_LB2_BASE, MS_LF1_BASE, MS_LF2_BASE
            .word MS_WOBBLE_BASE, MS_POLE_BASE, MS_FACE_BASE, MS_SIT_BASE, MS_FLOOR_BASE
            .word MS_WALK0_BASE, MS_WALK1_BASE

; seated and standing passengers (standing ones lurch with the push, seated
; ones nod along to the rattle)
NUM_PP = 6
draw_people:
    A16
    lda w_startle
    beq @s0
    dec w_startle
@s0:
    A8
    ldx #$0000
@p:
    stx w_cur
    A16
    lda f:pp_x,x
    sta spr_x
    lda f:pp_y,x
    sta spr_y
    ; a grab makes everyone jump (two hops)
    lda w_startle
    and #$0008
    beq @calm
    dec spr_y
    dec spr_y
@calm:
    lda f:pp_kind,x
    cmp #2
    bcc @seated
    ; standing: lurch with the push (the car goes the other way)
    lda w_fx
    jsr asr2
    clc
    adc spr_x
    sta spr_x
    lda w_fy
    jsr asr3
    clc
    adc spr_y
    sta spr_y
    ; PATIENT ZERO: they all step back and mind the gap
    lda w_germs
    cmp #20
    bcc @pos
    lda spr_x
    cmp #RIDER_X
    bcs @away
    sec
    sbc #12
    sta spr_x
    bra @pos
@away:
    clc
    adc #12
    sta spr_x
    bra @pos
@seated:
    lda w_speed
    beq @pos
    lda frame
    clc
    adc w_cur
    and #$0010
    beq @pos
    inc spr_y
@pos:
    A8
    ldx w_cur
    lda f:pp_pal,x
    cpx #((NUM_PP - 1) * 2)     ; the one by the door changes at each stop
    bne @np
    lda w_pal
@np:
    asl a
    ora #$30
    sta tmp5
    stz tmp5+1
    ; the backpack gag: he turns to face you on the warning, then turns
    ; back and his pack swings into you
    cpx #8
    bne @nt
    lda w_kind
    cmp #K_PACK
    bne @nt
    lda w_ls
    cmp #LS_WARN
    bne @sw
    lda #$40
    sta tmp5+1
    bra @nt
@sw:
    cmp #LS_ACT
    bne @nt
    A16
    lda spr_x
    sec
    sbc #6
    sta spr_x
    A8
@nt:
    lda f:pp_kind,x
    cpx #((NUM_PP - 1) * 2)
    bne @k
    ; the boarder walks in from the doors
    A16
    lda w_walk
    cmp #233
    bcc @stand
    dec w_walk
    sta spr_x
    A8
    lda frame
    lsr a
    lsr a
    lsr a
    and #$01
    clc
    adc #4
    bra @k
@stand:
    A8
    lda #2
@k:
    asl a
    TAXB
    lda f:pk_lo,x
    sta ptr1
    lda f:pk_lo+1,x
    sta ptr1+1
    lda #^ms_sit_phone
    sta ptr1+2
    lda f:pk_base,x
    sta tmp6
    stz tmp6+1
    lda f:pk_base+1,x
    sta tmp6+1
    jsl oam_meta
    ldx w_cur
    inx
    inx
    cpx #(NUM_PP*2)
    beq @x
    jmp @p
@x:
    rts

pp_x:    .word 40, 84, 212, 64, 178, 232
pp_y:    .word 151, 151, 151, 210, 210, 210
pp_pal:  .word 1, 3, 2, 4, 2, 3
pp_kind: .word 0, 1, 0, 2, 3, 2
pk_lo:   .addr ms_sit_phone, ms_sit_sleep, ms_strap, ms_backpack, ms_walk_a, ms_walk_b
pk_base: .word MS_SIT_PHONE_BASE, MS_SIT_SLEEP_BASE, MS_STRAP_BASE, MS_BACKPACK_BASE
         .word MS_WALK_A_BASE, MS_WALK_B_BASE

draw_germs:
    ldx #$0000
@g:
    lda G_L,x
    beq @n
    stx w_cur
    lda G_X,x
    sta spr_x
    stz spr_x+1
    A16
    lda G_Y,x
    sta spr_y
    A8
    lda #$3A
    sta tmp5
    stz tmp5+1
    lda frame
    and #$08
    beq @a
    LDPTR1 ms_germ1
    ldx #MS_GERM1_BASE
    bra @d
@a:
    LDPTR1 ms_germ0
    ldx #MS_GERM0_BASE
@d:
    stx tmp6
    jsl oam_meta
    ldx w_cur
@n:
    inx
    inx
    cpx #(NUM_GERMS*2)
    bne @g
    rts

; ------------------------------------------------------------------
; HUD: two rows at 16 px pitch on the dark band.
;   row 1: GERMS nn              NEXT: STATION
;   row 3: status (the cue)      STYLE nnnn
sb_hud_full:
    PRINT 1, 1, TP_WHITE, str_germs
    PRINT 15, 1, TP_WHITE, str_next
    PRINT 20, 3, TP_WHITE, str_style
    ldx #$FF
    stx w_stat_old
    lda #$FF
    sta w_hseg
    jsr sb_hud_now
    jsr hud_station
    rts

sb_hud:
    lda w_pend
    beq @np
    jmp pop_draw                ; (the rest of the HUD waits a frame)
@np:
    jsr hud_status
    lda frame
    and #$03
    beq sb_hud_now
    rts
sb_hud_now:
    ldx w_germs
    stx tmp1
    lda #($20 | (TP_GREEN << 2))
    cpx #15
    bcc @g
    lda #($20 | (TP_RED << 2))
@g:
    ldx #(1*32 + 7)
    ldy #2
    jsl txt_num
    ldx w_style
    stx tmp1
    ldx #(3*32 + 26)
    ldy #4
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_num
    ; next station changes on arrival
    lda w_seg
    cmp w_hseg
    beq @x
    jsr hud_station
@x:
    rts

hud_station:
    lda w_seg
    sta w_hseg
    ldx #(1*32 + 21)
    A16
    lda #$010A
    sta tmp1
    A8
    stz tmp2
    lda #$20
    jsl txt_fill
    lda w_seg
    cmp #NUM_SEG
    bcc @n
    lda #(NUM_SEG - 1)
@n:
    A16
    and #$00FF
    asl a
    tax
    lda f:station_names,x
    sta ptr0
    A8
    lda #^station_names
    sta ptr0+2
    ldx #(1*32 + 21)
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_print
    rts

hud_status:
    lda w_status
    TAXB
    A8
    lda w_gold                  ; while the leg can be a GOLD SURF a push says TAP
    beq @ng
    lda f:status_gold,x
    bne @st
@ng:
    lda w_status
@st:
    cmp w_stat_old
    beq @x
    sta w_stat_old
    ldx #(3*32 + 1)
    A16
    lda #$0112                  ; 18 x 1 (STYLE sits at column 20)
    sta tmp1
    A8
    stz tmp2
    lda #$20
    jsl txt_fill
    lda w_stat_old
    A16
    and #$00FF
    asl a
    tax
    lda f:status_msgs,x
    sta ptr0
    A8
    lda #^status_msgs
    sta ptr0+2
    lda w_stat_old
    TAXB
    lda f:status_tp,x
    ldx #(3*32 + 1)
    jsl txt_print
@x:
    rts

str_germs: .byte "GERMS", 0
str_next:  .byte "NEXT:", 0
str_style: .byte "STYLE", 0
status_msgs: .addr ss0, ss1, ss2, ss3, ss4, ss5, ss6, ss7, ss8, ss9, ss10
             .addr ss11, ss12, ss13, ss14, ss15, ss16
             .addr ss17, ss18, ss19, ss20, ss21, ss22
; a push's line while the leg can still be a GOLD SURF (0 = the same line)
status_gold: .byte 0, 0, 0, 0, 17, 18, 19, 20, 0, 0, 0, 0, 21, 0, 22, 0, 0
; warnings orange (get ready), pushes yellow like the solid arrow (lean now)
status_tp:   .byte ($20 | (TP_WHITE << 2))
             .byte ($20 | (TP_ORANGE << 2)), ($20 | (TP_ORANGE << 2)), ($20 | (TP_ORANGE << 2))
             .byte ($20 | (TP_YELLOW << 2)), ($20 | (TP_YELLOW << 2)), ($20 | (TP_YELLOW << 2))
             .byte ($20 | (TP_YELLOW << 2))
             .byte ($20 | (TP_WHITE << 2)), ($20 | (TP_WHITE << 2)), ($20 | (TP_GREEN << 2))
             .byte ($20 | (TP_ORANGE << 2)), ($20 | (TP_YELLOW << 2))
             .byte ($20 | (TP_ORANGE << 2)), ($20 | (TP_YELLOW << 2))
             .byte ($20 | (TP_WHITE << 2))
             .byte ($20 | (TP_GREEN << 2))
             .byte ($20 | (TP_YELLOW << 2)), ($20 | (TP_YELLOW << 2)), ($20 | (TP_YELLOW << 2))
             .byte ($20 | (TP_YELLOW << 2)), ($20 | (TP_YELLOW << 2)), ($20 | (TP_YELLOW << 2))
ss0:  .byte " ", 0
ss1:  .byte "STAND CLEAR!", 0
ss2:  .byte "CURVE AHEAD", 0
ss3:  .byte "STATION AHEAD", 0
ss4:  .byte "GO! HOLD ", TXT_ARROW_R + $20, 0
ss5:  .byte "CURVE! HOLD ", TXT_ARROW_U + $20, 0
ss6:  .byte "CURVE! HOLD ", TXT_ARROW_D + $20, 0
ss7:  .byte "BRAKES! HOLD ", TXT_ARROW_L + $20, 0
ss8:  .byte "CRUISING", 0
ss9:  .byte "DOORS OPEN", 0
ss10: .byte "OUT OF SERVICE", 0
ss11: .byte "SIGNAL PROBLEMS!", 0
ss12: .byte "E-BRAKE! HOLD ", TXT_ARROW_L + $20, 0
ss13: .byte "BACKPACK SWING!", 0
ss14: .byte "BACKPACK! HOLD ", TXT_ARROW_R + $20, 0
ss15: .byte "IT'S DUNDAS, BUD", 0
ss16: .byte "GLIDING IN...", 0
ss17: .byte "GO! TAP ", TXT_ARROW_R + $20, " FOR X3", 0
ss18: .byte "CURVE! TAP ", TXT_ARROW_U + $20, " X3", 0
ss19: .byte "CURVE! TAP ", TXT_ARROW_D + $20, " X3", 0
ss20: .byte "BRAKES! TAP ", TXT_ARROW_L + $20, " X3", 0
ss21: .byte "E-BRAKE! TAP ", TXT_ARROW_L + $20, " X3", 0
ss22: .byte "BACKPACK! TAP ", TXT_ARROW_R + $20, " X3", 0

; ------------------------------------------------------------------
; score. Finished at Union: RIDE 1000 + STYLE - 40 per germ.
; PATIENT ZERO or gave up: 40 per station reached on a leg you worked.
sb_score:
    A16
    lda w_germs
    sta ev_stat
    lda w_earn
    and #$00FF
    sta ev_stat+2               ; LEGS LEANED: the legs a failed ride pays for
    lda w_golds
    and #$00FF
    sta ev_stat+4               ; GOLD SURFS
    lda #NUM_SEG
    sta ev_stat+6               ; both lines' "OF n": the ride's six legs, on every card
    ldx #$0000                  ; STYLE by source: a failed run's is void (all 0)
@sty:
    stz ev_style,x
    inx
    inx
    cpx #10
    bne @sty
    lda w_germs
    cmp #20
    bcs @fail
    lda w_seg
    and #$00FF
    cmp #NUM_SEG
    bcc @fail
    ; finished
    ldx #$0000
@sc:
    lda w_sty,x
    sta ev_style,x
    inx
    inx
    cpx #10
    bne @sc
    lda #BASE_RIDE
    sta ev_break
    lda w_style
    sta ev_break+2
    lda w_germs
    asl a
    asl a
    asl a                       ; 8g
    sta tmp1
    asl a
    asl a                       ; 32g
    clc
    adc tmp1
    sta ev_break+4              ; 40g
    lda ev_break
    clc
    adc ev_break+2
    sec
    sbc ev_break+4
    sta ev_score
    A8
    stz ev_fail
    rts
@fail:
    .a16
    lda w_earn
    and #$00FF
    asl a
    asl a
    asl a                       ; 8s
    sta tmp1
    asl a
    asl a                       ; 32s
    clc
    adc tmp1                    ; 40s
    sta ev_break
    sta ev_score
    stz ev_break+2
    stz ev_break+4
    A8
    lda #$03
    ldx w_germs
    cpx #20
    bcc @q
    lda #$01
@q:
    sta ev_fail
    rts

.include "subway_meta.inc"
