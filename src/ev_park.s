; EVENT 3: OFF-LEASH ALERT — Trinity Bellwoods, 3/4 top-down.
; Walk from the Queen St gate to the Dundas gate. Off-leash dogs spot you
; (one at a time, only from on screen) and charge; B on the "!" gets you set
; and you sidestep as he lunges (B by hand at the last moment = CLOSE SHAVE),
; or throw a tennis ball (A). A dodged dog skids, sits and waits: walk up and
; pat him for DODGE 'N' PAT (20 x the chain, up to x5; a tackle breaks it).
; Tree canopies are on BG2 (high priority) so dogs and you go behind them.
.p816
.smart -
.include "globals.inc"
.include "screens.inc"

.import park_tiles, park_map, park_solid, park_pal, park_spr, park_spr_pal

PARK_H     = 2560
START_Y    = 2532
FINISH_Y   = 40
MAX_Y      = START_Y + 2     ; feet and shadow stay clear of the bottom HUD bar
TIME_LIMIT = 120*60           ; a careful walk fits: the clock isn't the hard part
PAR_LEFT   = 30              ; seconds left that earn no time bonus (par 90 s)
HURRY_T    = 20*60           ; TIME goes red, one HURRY! line
DOWN_T     = 120             ; frames on your back after a tackle
WALK       = $00E0
SPOT_R     = 80              ; a dog this close (manhattan) spots you
SPOT_TOP   = 40              ; ... but only from where you can see it
SPOT_BOT   = 192             ; (screen y of its feet: never from off-screen)
DASH       = $0300
ALERT_T    = 36              ; "!" tell before a dog charges (+0..19)
DODGE_R    = 40              ; a charging dog this close when B goes = DODGE
SHAVE_R    = 22              ; ... this close, pressed by hand = CLOSE SHAVE
HAND_BONUS = 25              ; style for a dodge timed by hand (B with him in range)
SHAVE_BONUS = 75             ; ... and for a CLOSE SHAVE (got set early = no bonus)
SHAVE_RUN  = 4               ; CLOSE SHAVEs in a row pay x2, x3, x4 (any other dodge or a tackle resets)
BACK_R     = 40              ; walk this close to a barking dog and he backs off
DODGE_PTS  = 50              ; base points a dodge
HEAL_RUN   = 3               ; dogs beaten in a row that win back a heart
DASH_WHIFF = 70              ; sidestep cooldown when nothing was dodged
DASH_HIT   = 12              ; ... and after a clean dodge
STUMBLE    = 48              ; a sidestep with no dog about leaves you off balance
WHIFF_WIN  = 36              ; ... another this soon after you're steady again: x2, then x3 (mashing B crawls)
IDLE_T     = 15*60           ; no ground gained for this long: a nap, CALLED IT A DAY
DOG_CD     = 255             ; frames a dodged / fetching / tackling dog leaves you be
SLIDE_R    = 160             ; how far to look for a way round an obstacle (the courts)
CALM_DODGE = 75              ; after a dodge nobody new starts on you for this long
CALM_END   = 40              ; ... after any other charge ends
PAST_T     = 22              ; a dodged dog skids on this long ...
SIT_T      = 160             ; ... then sits, tail going, waiting for a pat
PAT_R      = 16              ; walk this close to a sitting dog = GOOD BOY!
CHAIN_MAX  = 5

ST_WALK   = 0
ST_DOWN   = 1
ST_FINISH = 2
ST_DONE   = 3

k_x      = ev_ram + 0        ; 8.8
k_y      = ev_ram + 2
k_yf     = ev_ram + 4
k_dir    = ev_ram + 6        ; 0 down 1 up 2 left 3 right
k_anim   = ev_ram + 8
k_state  = ev_ram + 10
k_timer  = ev_ram + 12
k_inv    = ev_ram + 14
k_dash   = ev_ram + 16
k_dashcd = ev_ram + 18
k_dvx    = ev_ram + 20
k_dvy    = ev_ram + 22
k_time   = ev_ram + 24
k_balls  = ev_ram + 26
k_tackle = ev_ram + 28
k_dodged = ev_ram + 30
k_popup  = ev_ram + 32
k_cam    = ev_ram + 34
k_top    = ev_ram + 36       ; first map row held in VRAM
k_moving = ev_ram + 38
k_cur    = ev_ram + 40
k_tmpx   = ev_ram + 42
k_tmpy   = ev_ram + 44
k_fetch  = ev_ram + 46       ; charging dogs sent after a ball
k_fin    = ev_ram + 66       ; 1 = reached the Dundas gate
k_side   = ev_ram + 68       ; sidestep velocity picked by threat_side
sq_state = ev_ram + 70       ; white squirrel: 0 none, 1 running
sq_x     = ev_ram + 72       ; 8.8
sq_y     = ev_ram + 74
sq_next  = ev_ram + 76       ; next trigger in sq_trig
sq_vx    = ev_ram + 78
k_stum   = ev_ram + 288      ; frames left of a whiffed sidestep's stumble
k_live   = ev_ram + 540      ; dogs alerted on / charging you (one at a time)
k_calm   = ev_ram + 542      ; global grace: no dog starts on you while > 0
k_armed  = ev_ram + 544      ; B pressed during an alert: the step goes as he lunges
k_armdx  = ev_ram + 546      ; walk x held when it was armed (0 = step away from him)
k_chain  = ev_ram + 548      ; DODGE 'N' PAT chain (0..CHAIN_MAX)
k_style  = ev_ram + 550      ; DODGE 'N' PAT points: pats + close shaves
k_pats   = ev_ram + 552
k_shaves = ev_ram + 554
k_quit   = ev_ram + 556      ; gave up from the pause menu
k_shok   = ev_ram + 558      ; 1 = this sidestep was pressed by hand (can be a shave)
k_wx     = ev_ram + 560      ; walk velocity this frame (saved over dog scans)
k_wy     = ev_ram + 562
k_prio   = ev_ram + 564      ; OBJ priority for the sprite being drawn
k_patf   = ev_ram + 568      ; frames of the pat pose
k_xmv    = ev_ram + 572      ; 1 = this frame's x step went through
k_canlr  = ev_ram + 574      ; slide: 1 = a step left is open where you stand, 2 = right
k_sdir   = ev_ram + 576      ; the way we're sliding round something (sticks till clear)
k_scd    = ev_ram + 578      ; frames before the gap search runs again (it's dear)
k_hand   = ev_ram + 580      ; dodges timed by hand (B with him in range), shaves included
k_hurt   = ev_ram + 582      ; hearts lost (3 = out); k_tackle counts every tackle
k_streak = ev_ram + 584      ; dogs beaten since the last tackle / heart back
k_coach  = ev_ram + 586      ; 1 once the first dog's "press B" coaching has shown
k_hurry  = ev_ram + 588      ; 1 = HURRY! line due (shown when no dog is on you), 2 = shown
k_srun   = ev_ram + 590      ; CLOSE SHAVEs in a row (1..SHAVE_RUN): each pays SHAVE_BONUS x this
k_best   = ev_ram + 592      ; furthest north reached (y)
k_still  = ev_ram + 594      ; frames since k_best last moved: IDLE_T = a nap, the walk's over
k_wrun   = ev_ram + 596      ; whiffs in quick succession (1..3): each stumbles longer
k_wcool  = ev_ram + 598      ; frames in which another whiff counts as "in succession"
k_cbuf   = ev_ram + 640      ; 64 bytes: one BG2 canopy row, unpacked for DMA
EV_SEED  = ev_ram + 510

; thrown ball
b_state  = ev_ram + 48       ; 0 none 1 flying 2 resting
b_x      = ev_ram + 50       ; 8.8
b_y      = ev_ram + 52
b_yf     = ev_ram + 54
b_vx     = ev_ram + 56
b_vy     = ev_ram + 58
b_z      = ev_ram + 60       ; 8.8 height
b_vz     = ev_ram + 62
b_timer  = ev_ram + 64

; active dogs (word arrays, X = slot*2)
NUM_ENT = 8
D_SLOT  = ev_ram + 80        ; index into the dog table, $FF = free
E_TYPE  = D_SLOT
D_X     = ev_ram + 96
D_Y     = ev_ram + 112
D_YF    = ev_ram + 128
D_VX    = ev_ram + 144
D_VY    = ev_ram + 160
D_STATE = ev_ram + 176
D_TIMER = ev_ram + 192
D_KIND  = ev_ram + 208
D_HX    = ev_ram + 224
D_HY    = ev_ram + 240
D_CD    = ev_ram + 256
D_FLAGS = ev_ram + 272       ; 1 = charge counted

DS_WANDER = 0
DS_ALERT  = 1
DS_CHARGE = 2
DS_BALL   = 3
DS_RETURN = 4
DS_PAST   = 5                ; dodged: carries on past you, then goes home
DS_SQUIRREL = 6              ; WHITE SQUIRREL!
DS_SIT    = 7                ; dodged, skidded, sat: pat me! (DODGE 'N' PAT)
DS_LICK   = 8                ; tackled you: on top of you, licking

; dog table (16) and ground balls (8)
NUM_DOGS = 16
DT_X    = ev_ram + 320
DT_Y    = ev_ram + 352
DT_KIND = ev_ram + 384
DT_DONE = ev_ram + 416
NUM_GB  = 8
GB_X    = ev_ram + 448
GB_Y    = ev_ram + 464
GB_TAKEN = ev_ram + 480
k_order = ev_ram + 512       ; draw order scratch
k_cnt   = ev_ram + 530

.segment "EVENTS2"
.a8
.i16

ev_park:
    phb
    phk
    plb
    jsr park_init
    jsr park_draw
    jsl event_card
    jsr park_hud_now            ; the bars are up through 3-2-1-GO
    jsl event_countdown
    jsr park_hud_now
    lda #SONG_PARK
    jsl music_play
@loop:
    jsl wait_frame
    lda ev_giveup               ; pause menu: GIVE UP ends the walk now
    beq @play
    lda #1
    sta k_quit
    bra @end
@play:
    jsr park_update
    jsr stream_rows
    jsr park_draw
    jsr park_hud
    lda k_state
    cmp #ST_DONE
    bne @loop
@end:
    jsl music_stop
    jsr park_score
    jsl score_card
    plb
    rtl

.include "evcommon.inc"

park_init:
    jsl ppu_off
    jsl set_mode1_defaults
    jsl load_text_gfx
    VLOAD VRAM_BGTILES, park_tiles, (park_solid - park_tiles)
    PLOAD 32, park_pal, 96
    VLOAD VRAM_OBJTILES, park_spr, (park_spr_pal - park_spr)
    VLOAD (VRAM_OBJTILES + 128*16), park_spr2, (park_spr2_end - park_spr2)
    PLOAD 144, park_spr_pal, 80
    lda cur_player
    ldy #$0000
    jsl player_palette
    lda #$17                    ; BG1 ground, BG2 tree canopies, BG3 text, OBJ
    sta tm_sh
    stz txt_bg
    jsr ev_clear
    ldx #(128*256)
    stx k_x
    ldx #START_Y
    stx k_y
    stx k_best
    lda #1
    sta k_dir
    ldx #TIME_LIMIT
    stx k_time
    ldx #3
    stx k_balls
    ldx #$7B31
    stx EV_SEED
    ldx #$00FF
    ldy #$0000
@free:
    txa
    sta D_SLOT,y
    iny
    iny
    cpy #(NUM_ENT*2)
    bne @free
    jsr make_dogs
    jsr camera
    ; fill the VRAM map with the rows around the camera
    A16
    lda k_cam
    lsr a
    lsr a
    lsr a
    dec a
    bpl @t
    lda #$0000
@t:
    cmp #(PARK_H/8 - 32)
    bcc @t2
    lda #(PARK_H/8 - 32)
@t2:
    sta k_top
    sta tmp4
    A8
    ldy #32
@row:
    phy
    jsr row_source              ; ptr0 / X for row tmp4
    A16
    lda #64
    sta tmp0
    A8
    jsl vram_load
    jsr canopy_source
    A16
    lda #64
    sta tmp0
    A8
    jsl vram_load
    A16
    inc tmp4
    A8
    ply
    dey
    bne @row
    rts

; row tmp4 -> ptr0 = source in park_map, X = VRAM address
row_source:
    A16
    lda tmp4
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a                       ; *64 bytes
    clc
    adc #.loword(park_map)
    sta ptr0
    lda tmp4
    and #$001F
    asl a
    asl a
    asl a
    asl a
    asl a
    clc
    adc #VRAM_BG1MAP
    tax
    A8
    lda #^park_map
    sta ptr0+2
    rts

; dogs along the park + spare tennis balls (same for every player):
; placed by tools/art_park.py round the landmarks (x, kind, y)
make_dogs:
    ldx #$0000
    ldy #$0000
@d:
    lda f:park_dogs,x
    sta DT_X,y
    lda #$00
    sta DT_X+1,y
    lda f:park_dogs+1,x
    sta DT_KIND,y
    lda #$00
    sta DT_KIND+1,y
    sta DT_DONE,y
    A16
    lda f:park_dogs+2,x
    sta DT_Y,y
    A8
    inx
    inx
    inx
    inx
    iny
    iny
    cpy #(NUM_DOGS*2)
    bne @d
    ldy #$0000
@b:
    lda f:park_dogs,x
    sta GB_X,y
    lda #$00
    sta GB_X+1,y
    sta GB_TAKEN,y
    A16
    lda f:park_dogs+2,x
    sta GB_Y,y
    A8
    inx
    inx
    inx
    inx
    iny
    iny
    cpy #(NUM_GB*2)
    bne @b
    rts

; camera follows the walker
camera:
    A16
    lda k_y
    sec
    sbc #140
    bpl @a
    lda #$0000
@a:
    cmp #(PARK_H - 224)
    bcc @b
    lda #(PARK_H - 224)
@b:
    sta k_cam
    sta bg1y
    sta bg2y
    stz bg1x
    stz bg2x
    A8
    rts

; keep the 32 VRAM rows around the camera loaded
stream_rows:
    A16
    lda k_cam
    lsr a
    lsr a
    lsr a
    sta tmp6                    ; camera row
    ; scrolling up: need row cam-1 loaded
    dec a
    bmi @down
    cmp k_top
    bcs @down
    dec k_top
    lda k_top
    sta tmp4
    A8
    jsr queue_row
    A16
    bra @x
@down:
    lda tmp6
    clc
    adc #29
    sec
    sbc k_top
    cmp #32
    bcc @x
    lda k_top
    clc
    adc #32
    cmp #(PARK_H/8)
    bcs @x
    sta tmp4
    inc k_top
    A8
    jsr queue_row
    A16
@x:
    A8
    rts

queue_row:
    jsr row_source
    A16
    lda #64
    sta tmp0
    A8
    lda #$80
    jsl dma_queue
    jsr canopy_source
    A16
    lda #64
    sta tmp0
    A8
    lda #$80
    jsl dma_queue
    rts

; row tmp4 -> its BG2 canopy row unpacked into k_cbuf; ptr0 = k_cbuf,
; X = VRAM address. Packed: a bit per cell (4 bytes a row), then each row's
; offset into the list of its non-blank map words.
canopy_source:
    A16
    lda tmp4
    asl a
    tax
    lda f:park_can_row,x
    tax                         ; X = this row's first word
    lda tmp4
    asl a
    asl a
    sta tmp6                    ; mask byte
    ldy #$0000
@byte:
    phx
    ldx tmp6
    A8
    lda f:park_can_mask,x
    sta tmp5
    A16
    plx
    lda #8
    sta tmp7
@bit:
    A8
    asl tmp5
    A16
    bcc @blank
    lda f:park_can_cells,x
    inx
    inx
    bra @put
@blank:
    lda #$0000
@put:
    sta k_cbuf,y
    iny
    iny
    dec tmp7
    bne @bit
    inc tmp6
    cpy #64
    bne @byte
    lda #.loword(k_cbuf)
    sta ptr0
    lda tmp4
    and #$001F
    asl a
    asl a
    asl a
    asl a
    asl a
    clc
    adc #VRAM_BG2MAP
    tax
    A8
    lda #^k_cbuf
    sta ptr0+2
    rts

; ------------------------------------------------------------------
park_update:
    lda k_state
    cmp #ST_WALK
    beq @walk
    cmp #ST_DOWN
    beq @down
    ; finish: keep walking north for a moment (into the gate, not past row 0)
    A16
    lda k_y
    cmp #16
    bcc @fstop
    dec k_y
    inc k_anim
@fstop:
    dec k_timer
    A8
    bne @common
    lda #ST_DONE
    sta k_state
    rts
@down:
    A16
    dec k_timer
    A8
    bne @common
    lda k_quit                  ; the nap: that's the walk
    bne @dn
    lda k_hurt
    cmp #3
    bcc @up
@dn:
    lda #ST_DONE
    sta k_state
    rts
@up:
    lda #ST_WALK
    sta k_state
    ldx #180                    ; three seconds' grace to get clear
    stx k_inv
    bra @common
@walk:
    jsr walk_input
    A16
    lda k_y                     ; ground gained? (a nap ends the walk)
    cmp k_best
    bcs @nb
    sta k_best
    stz k_still
    bra @nn
@nb:
    inc k_still
    lda k_still
    cmp #IDLE_T
    bcc @nn
    A8
    lda #1
    sta k_quit                  ; CALLED IT A DAY (ev_fail 3)
    lda #ST_DOWN                ; lie down for a beat, then the card
    sta k_state
    ldx #90
    stx k_timer
    LDPTR0 str_nap
    lda #TP_ORANGE
    jsr popup
    ldx #90
    stx k_popup
@nn:
    A8
@common:
    jsr camera
    A16
    lda k_inv
    beq @i
    dec k_inv
@i:
    lda k_patf
    beq @pf
    dec k_patf
@pf:
    lda k_calm
    beq @cl
    dec k_calm
@cl:
    lda k_dashcd
    beq @c
    dec k_dashcd
@c:
    lda k_wcool
    beq @wc
    dec k_wcool
@wc:
    lda k_popup
    beq @p
    dec k_popup
    bne @p
    A8
    jsl event_popup_clear
    A16
@p:
    lda k_state
    and #$00FF
    cmp #ST_FINISH
    bcs @noclock
    lda k_time
    bne @tick
    A8
    lda #ST_DONE
    sta k_state
    rts
@tick:
    .a16
    dec k_time
    lda k_time
    cmp #HURRY_T
    bne @nh
    A8
    inc k_hurry
    A16
@nh:
    lda k_y
    cmp #FINISH_Y
    bcs @noclock
    A8
    lda #ST_FINISH
    sta k_state
    lda #1
    sta k_fin
    ldx #60
    stx k_timer
    SFX SFX_CHEER
    LDPTR0 str_made
    lda #TP_GREEN
    jsr popup
    ldx #200
    stx k_popup
    A16
@noclock:
    A8
    jsr spawn_dogs
    jsr squirrel_update
    jsr dogs_update
    jsr ball_update
    jsr pickups
    lda k_hurry                 ; 20 s left: say so, once nobody's on you
    cmp #1
    bne @x
    lda k_state
    cmp #ST_WALK
    bne @x
    lda k_live
    ora k_popup
    bne @x
    inc k_hurry
    SFX SFX_BLIP
    LDPTR0 str_hurry
    lda #TP_ORANGE
    jsr popup
    ldx #90
    stx k_popup
@x:
    rts

str_made: .byte " MADE IT TO DUNDAS! ", 0
str_nap:  .byte " ZZZ... CALLED IT A DAY. ", 0
str_hurry: .byte " HURRY! 20 SECONDS LEFT! ", 0

; ptr0 = message, A = text palette: banner on row 9 with a solid backing
; so it reads over sprites and busy grass
popup:
    pha
    jsl event_popup_clear
    lda #TXT_WIN
    sta txt_bg
    pla
    jsl event_popup
    stz txt_bg
    rts

walk_input:
    ; dash in progress?
    A16
    lda k_dash
    beq @normal
    dec k_dash
    bne @dashing
    ; step over: if it dodged nothing you stumble (mashing B doesn't pay)
    lda k_dashcd
    cmp #(DASH_HIT + 1)
    bcc @dashing
    lda k_wcool                 ; whiffed again straight away? off balance longer
    beq @w1
    lda k_wrun
    cmp #3
    bcs @w2
    inc k_wrun
    bra @w2
@w1:
    lda #1
    sta k_wrun
@w2:
    lda k_wrun
    dec a
    asl a
    tax
    lda f:whiff_stum,x
    sta k_stum
    clc
    adc #WHIFF_WIN
    sta k_wcool
    lda k_popup
    bne @dashing
    A8
    LDPTR0 str_oops
    lda k_wrun
    cmp #2
    bcc @o1
    LDPTR0 str_oops2
@o1:
    lda #TP_ORANGE
    jsr popup
    ldx #50
    stx k_popup
    A16
@dashing:
    lda k_dvx
    sta tmp1
    lda k_dvy
    sta tmp2
    jmp @move
@normal:
    stz tmp1
    stz tmp2
    stz k_moving
    lda k_stum
    beq @steady
    dec k_stum
    stz k_wx                    ; (an armed step goes away from him)
    lda pad_new
    bit #PAD_B
    beq @stumx
    A8
    jsr try_arm                 ; a whiff costs you the stumble, not the dog
    A16
@stumx:
    jmp @ydone
@steady:
    ; an armed sidestep goes off by itself as the dog lunges
    A8
    jsr armed_fire
    A16
    lda k_dash
    bne @dashing
    lda pad
    bit #PAD_LEFT
    beq @nl
    lda #($10000 - WALK)
    sta tmp1
    ldx #2
    stx k_dir
    bra @v
@nl:
    bit #PAD_RIGHT
    beq @v
    lda #WALK
    sta tmp1
    ldx #3
    stx k_dir
@v:
    lda pad
    bit #PAD_UP
    beq @nu
    lda #($10000 - WALK)
    sta tmp2
    ldx #1
    stx k_dir
    bra @act
@nu:
    bit #PAD_DOWN
    beq @act
    lda #WALK
    sta tmp2
    ldx #0
    stx k_dir
@act:
    lda tmp1
    sta k_wx
    ora tmp2
    beq @still
    inc k_moving
@still:
    lda tmp2
    sta k_wy
    ; B: a dog lunging at you right now = sidestep it (late = CLOSE SHAVE).
    ; A dog on its way (the "!") = get set: the step goes off as it lunges.
    ; Nobody about = a whiff and a stumble.
    lda pad_new
    bit #PAD_B
    beq @nob
    lda k_dashcd
    beq @bpress
    A8                          ; on cooldown: no step, but you can get set
    jsr try_arm
    A16
@nob:
    jmp @nodash
@bpress:
    A8
    jsr near_charger            ; clobbers tmp1-tmp3
    bcs @step
    lda k_live
    beq @step
    jsr try_arm
@held:
    A16
    lda k_wx
    sta tmp1
    lda k_wy
    sta tmp2
    bra @nodash
@step:
    A16
    lda #10
    sta k_dash
    lda #DASH_WHIFF
    sta k_dashcd
    lda k_wy
    sta k_dvy                   ; keep walking up/down while stepping aside
    lda k_wx
    beq @auto
    bmi @dl
    lda #DASH
    bra @ds
@dl:
    lda #($10000 - DASH)
    bra @ds
@auto:
    A8
    jsr threat_side             ; clobbers tmp1-tmp3
    A16
    lda k_side
@ds:
    sta k_dvx
    A8
    stz k_armed
    lda #1
    sta k_shok
    SFX SFX_JUMP
    jsr dodge_check
    A16
    lda k_dvx
    sta tmp1
    lda k_dvy
    sta tmp2
@nodash:
    lda pad_new
    bit #PAD_A
    beq @move
    lda tmp1
    pha
    lda tmp2
    pha
    A8
    jsr throw_ball
    A16
    pla
    sta tmp2
    pla
    sta tmp1
@move:
    ; x then y, each blocked by solid tiles at the feet
    stz k_xmv
    lda tmp1
    beq @noxmove
    lda k_x
    clc
    adc tmp1
    sta k_tmpx
    xba
    and #$00FF
    sta tmp3
    lda k_y
    sta tmp4
    A8
    jsr feet_free
    bcs @noxmove
    ldx k_tmpx
    stx k_x
    A16
    inc k_xmv
@noxmove:
    A16
    ; y (integer + fraction)
    lda tmp2
    bne @y
    jmp @ydone
@y:
    lda k_yf
    and #$00FF
    clc
    adc tmp2
    pha
    and #$00FF
    sta tmp5
    pla
    xba
    and #$00FF
    cmp #$0080
    bcc @yp
    ora #$FF00
@yp:
    clc
    adc k_y
    cmp #(MAX_Y + 1)            ; no walking off the bottom under the HUD
    bcc @yin
    lda #MAX_Y
@yin:
    sta tmp4
    lda k_x
    xba
    and #$00FF
    sta tmp3
    A8
    jsr feet_free
    bcs @blocked
    ldx tmp4
    stx k_y
    ldx tmp5
    stx k_yf
    ldx #$0000
    stx k_sdir
    stx k_scd
    jmp @ydone8
@blocked:
    ; a bench or tree in the way: slide round it. Steering one way, you go
    ; that way if there's a gap within reach, else the other; not steering,
    ; toward the nearer gap
    A16
    lda k_scd                   ; searched a moment ago: keep sliding that way
    beq @full
    dec k_scd
    lda k_sdir
    jeq @ydone8
    lda tmp1
    beq @cached
    eor k_sdir
    bpl @cached
    lda k_xmv                   ; steering the other way: take back the step
    beq @cached
    lda k_x
    sec
    sbc tmp1
    sta k_x
    stz k_xmv
@cached:
    lda k_sdir
    bra @found
@full:
    lda #8
    sta k_scd
    lda tmp1
    sta k_wx
    lda tmp3
    sta k_tmpy                  ; feet x
    lda tmp4
    sta k_tmpx                  ; (the blocked y)
    lda #3
    sta k_canlr                 ; both ways open till a search hits a wall
    lda k_wx                    ; not steering: keep going the way we were
    bne @srch
    lda k_sdir
    sta k_wx
@srch:
    jsr @search
    bcc @found
    lda k_wx
    beq @fail
    eor #$FFFF
    inc a
    sta k_wx
    jsr @search
    bcs @fail
    pha
    lda k_xmv                   ; the other way after all: take back the step
    beq @nb
    lda k_x
    sec
    sbc tmp1
    sta k_x
    stz k_xmv
@nb:
    pla
    bra @found
@fail:
    stz k_sdir
    bra @ydone8
@found:
    sta k_sdir
    ldy k_xmv
    bne @ydone8                 ; already stepping that way
    clc
    adc k_x
    sta k_tmpx
    xba
    and #$00FF
    sta tmp3
    lda k_y
    sta tmp4
    A8
    jsr feet_free
    bcs @ydone8
    ldx k_tmpx
    stx k_x
    inc k_moving
@ydone8:
    A16
@ydone:
    lda k_moving
    ora k_dash
    beq @noanim
    inc k_anim
@noanim:
    A8
    rts

; A16: look for a gap (k_wx < 0 left only, > 0 right only, 0 both, nearer
; first) -> carry clear, A = slide velocity
@search:
    .a16
    lda #1
    sta tmp6
@sl:
    lda k_wx
    bmi @sll
    jsr @try_r
    bcc @gr
    lda k_wx
    bne @sn
@sll:
    jsr @try_l
    bcc @gl
@sn:
    lda tmp6
    clc
    adc #8                      ; feet span two tiles: 8 px steps find any gap
    sta tmp6
    cmp #(SLIDE_R + 1)
    bcc @sl
    sec
    rts
@gl:
    lda #($10000 - WALK)
    clc
    rts
@gr:
    lda #WALK
    clc
    rts

; A16: carry clear if the feet would fit tmp6 px left / right of k_tmpy
; at the blocked y (k_tmpx), and you can walk there along where you stand;
; a wall where you stand shuts that side for the rest of the search
@try_l:
    .a16
    lda k_canlr
    and #$0001
    beq @no
    lda k_tmpy
    sec
    sbc tmp6
    bmi @no
    cmp #8
    bcc @no
    sta tmp3
    lda #$0001
    bra @try
@try_r:
    .a16
    lda k_canlr
    and #$0002
    beq @no
    lda k_tmpy
    clc
    adc tmp6
    cmp #248
    bcs @no
    sta tmp3
    lda #$0002
@try:
    sta tmp5
    lda k_y
    sta tmp4
    A8
    jsr feet_free
    A16
    bcs @shut
    lda k_tmpx
    sta tmp4
    A8
    jsr feet_free
    A16
    rts
@shut:
    lda tmp5
    trb k_canlr
@no:
    .a16
    sec
    rts
.a8

str_oops: .byte " OOPS! NO DOG THERE ", 0
str_oops2: .byte " OOPS! B WHEN ! SHOWS ", 0
whiff_stum: .word STUMBLE, STUMBLE*2, STUMBLE*3
str_coach_b: .byte " DOG! PRESS B TO GET SET! ", 0

; B with a dog on its way ("!" or charging, not yet in range): get set, and
; the step goes off by itself as he lunges (a plain DODGE, never a shave)
try_arm:
    lda k_live
    beq @x
    lda k_armed
    bne @x
    lda #1
    sta k_armed
    A16
    lda k_wx
    sta k_armdx
    A8
    SFX SFX_BLIP
@x:
    rts

; carry set if a charging dog is within DODGE_R (clobbers tmp1-tmp3)
near_charger:
    ldx #$0000
@d:
    lda D_SLOT,x
    cmp #$FF
    beq @n
    lda D_STATE,x
    cmp #DS_CHARGE
    bne @n
    jsr dog_dist
    A16
    lda tmp1
    cmp #DODGE_R
    A8
    bcs @n
    sec
    rts
@n:
    inx
    inx
    cpx #(NUM_ENT*2)
    bne @d
    clc
    rts

; armed (B during the "!"): step aside the moment he's in range
armed_fire:
    lda k_armed
    beq @x
    lda k_state
    cmp #ST_WALK
    bne @x
    lda k_live
    bne @on
    stz k_armed                 ; he went for a ball / the squirrel: stand down
@x:
    rts
@on:
    jsr near_charger
    bcc @x
    stz k_armed
    stz k_shok                  ; set early: a plain DODGE, never a shave
    A16
    lda #10
    sta k_dash
    lda #DASH_WHIFF
    sta k_dashcd
    stz k_dvy
    lda k_armdx
    beq @auto
    bmi @l
    lda #DASH
    bra @s
@l:
    lda #($10000 - DASH)
    bra @s
@auto:
    A8
    jsr threat_side
    A16
    lda k_side
@s:
    sta k_dvx
    A8
    SFX SFX_JUMP
    jmp dodge_check

; B just pressed: every charging dog within DODGE_R right now is DODGED
; (it has to be the last moment: mashing B gets you nothing but a stumble)
dodge_check:
    ldx #$0000
@d:
    stx k_cur
    lda D_SLOT,x
    cmp #$FF
    beq @n
    lda D_STATE,x
    cmp #DS_CHARGE
    bne @n
    jsr dog_dist
    A16
    lda tmp1
    cmp #DODGE_R
    A8
    bcs @n
    jsr dodged
@n:
    ldx k_cur
    inx
    inx
    cpx #(NUM_ENT*2)
    bne @d
@x:
    rts

; -> k_side = sidestep velocity away from the nearest alerted/charging dog
; (toward the middle of the park when nobody's about or it's dead ahead)
threat_side:
    A16
    lda #$7FFF
    sta k_tmpy                  ; best distance so far
    stz k_side
    A8
    ldx #$0000
@d:
    lda D_SLOT,x
    cmp #$FF
    beq @n
    lda D_STATE,x
    cmp #DS_ALERT
    beq @t
    cmp #DS_CHARGE
    bne @n
@t:
    jsr dog_dist                ; tmp1 = distance, tmp2 = player x - dog x
    A16
    lda tmp1
    cmp k_tmpy
    bcs @n16
    sta k_tmpy
    lda tmp2
    sta k_side
@n16:
    A8
@n:
    inx
    inx
    cpx #(NUM_ENT*2)
    bne @d
    A16
    lda k_tmpy
    cmp #$7FFF
    beq @mid
    lda k_side
    bpl @pos
    cmp #($10000 - 3)
    bcs @mid                    ; -3..-1: dead ahead
    lda #($10000 - DASH)        ; dog on your right: step left
    bra @s
@pos:
    cmp #4
    bcc @mid
    lda #DASH                   ; dog on your left: step right
    bra @s
@mid:
    lda k_x
    cmp #(128*256)
    bcc @r
    lda #($10000 - DASH)
    bra @s
@r:
    lda #DASH
@s:
    sta k_side
    A8
    rts

; tmp3 = x, tmp4 = y (feet) -> carry set if either foot is in a solid tile
feet_free:
    A16
    lda tmp3
    sec
    sbc #4
    jsr solid_at
    bcs @x
    lda tmp3
    clc
    adc #4
    jsr solid_at
@x:
    A8
    rts

; A16 = x, tmp4 = y -> carry set if solid (stays A16)
solid_at:
    .a16
    lsr a
    lsr a
    lsr a
    sta tmp0                    ; tile x
    lda tmp4
    cmp #PARK_H
    bcs @clear
    lsr a
    lsr a
    lsr a
    asl a
    asl a                       ; row * 4 bytes
    sta tmp7
    lda tmp0
    lsr a
    lsr a
    lsr a
    clc
    adc tmp7
    tax
    lda tmp0
    and #$0007
    tay
    A8
    lda f:park_solid,x
    and bit_mask,y
    A16
    beq @clear
    sec
    rts
@clear:
    clc
    rts
.a8

bit_mask: .byte $80, $40, $20, $10, $08, $04, $02, $01

throw_ball:
    lda b_state
    bne @no
    lda k_balls
    beq @no
    dec k_balls
    lda #1
    sta b_state
    ldx k_x
    stx b_x
    A16
    lda k_y
    sta b_y
    stz b_yf
    stz b_vx
    stz b_vy
    lda #$0800
    sta b_z
    lda #$0180
    sta b_vz
    lda k_dir
    and #$00FF
    asl a
    tax
    lda f:throw_vx,x
    sta b_vx
    lda f:throw_vy,x
    sta b_vy
    A8
    SFX SFX_JUMP
    LDPTR0 str_fetch
    lda #TP_YELLOW
    jsr popup
    ldx #40
    stx k_popup
@no:
    rts

throw_vx: .word 0, 0, $10000 - $0280, $0280
throw_vy: .word $0280, $10000 - $0280, 0, 0
str_fetch: .byte " FETCH! ", 0

ball_update:
    lda b_state
    bne @on
    rts
@on:
    cmp #1
    beq @fly
    ; resting: dogs come for it; it fades after a while
    A16
    dec b_timer
    A8
    bne @x
    stz b_state
@x:
    rts
@fly:
    A16
    lda b_x
    clc
    adc b_vx
    sta b_x
    lda b_vy
    beq @ny
    lda b_yf
    and #$00FF
    clc
    adc b_vy
    pha
    and #$00FF
    sta b_yf
    pla
    xba
    and #$00FF
    cmp #$0080
    bcc @p
    ora #$FF00
@p:
    clc
    adc b_y
    sta b_y
@ny:
    lda b_vz
    sec
    sbc #$0010
    sta b_vz
    clc
    adc b_z
    sta b_z
    bpl @air
    stz b_z
    lda #90                     ; a ball only holds a dog's interest so long
    sta b_timer
    A8
    lda #2
    sta b_state
    SFX SFX_STEP
    rts
@air:
    A8
    rts

; walk over a spare ball to pick it up
pickups:
    ldx #$0000
@g:
    lda GB_TAKEN,x
    bne @n
    lda GB_X,x
    sec
    sbc k_x+1
    bcs @a
    eor #$FF
    inc a
@a:
    cmp #10
    bcs @n
    A16
    lda GB_Y,x
    sec
    sbc k_y
    bpl @b
    eor #$FFFF
    inc a
@b:
    cmp #10
    A8
    bcs @n
    lda k_balls
    cmp #5
    bcs @n
    inc k_balls
    lda #1
    sta GB_TAKEN,x
    SFX SFX_COIN
@n:
    inx
    inx
    cpx #(NUM_GB*2)
    bne @g
    rts

; ------------------------------------------------------------------
; The Trinity Bellwoods white squirrel: twice a crossing it dashes across
; just ahead of you and every dog near it forgets you exist.
sq_trig: .word 1880, 960, 0     ; walker y that sets it off (0 = no more)

squirrel_update:
    lda sq_state
    bne @run
    lda k_state
    cmp #ST_WALK
    bne @x
    lda k_live                  ; a dog's "!" always wins over the squirrel:
    bne @x                      ; it waits till nobody's winding up ...
    lda k_popup                 ; ... and the last line has had its say
    bne @x
    A16
    lda sq_next
    asl a
    tax
    lda f:sq_trig,x
    beq @x16
    cmp k_y
    bcc @x16                    ; not there yet
    inc sq_next
    lda k_y
    sec
    sbc #56
    sta sq_y
    lda k_x
    cmp #(128*256)
    bcs @fromleft               ; walker on the right: it comes from the left
    lda #(244*256)
    sta sq_x
    lda #($10000 - $0180)
    sta sq_vx
    bra @go
@fromleft:
    lda #(12*256)
    sta sq_x
    lda #$0180
    sta sq_vx
@go:
    A8
    lda #1
    sta sq_state
    LDPTR0 str_squirrel
    lda #TP_WHITE
    jsr popup
    ldx #80
    stx k_popup
    rts
@x16:
    A8
@x:
    rts
@run:
    A16
    lda sq_x
    clc
    adc sq_vx
    sta sq_x
    cmp #(8*256)
    bcc @gone
    cmp #(248*256)
    bcs @gone
    A8
    rts
@gone:
    A8
    stz sq_state
    rts

str_squirrel: .byte " THE WHITE SQUIRREL! ", 0

; bring dogs in as the camera reaches them
spawn_dogs:
    ldx #$0000
@t:
    lda DT_DONE,x
    bne @next
    A16
    lda DT_Y,x
    sec
    sbc k_cam
    cmp #($10000 - 80)
    bcs @near
    cmp #300
    bcs @next16
@near:
    A8
    stx tmp5
    ; free slot?
    ldy #$0000
@s:
    lda D_SLOT,y
    cmp #$FF
    beq @got
    iny
    iny
    cpy #(NUM_ENT*2)
    bne @s
    ldx tmp5
    bra @next
@got:
    ldx tmp5
    lda #1
    sta DT_DONE,x
    txa
    sta D_SLOT,y
    lda DT_X,x
    sta D_X+1,y
    sta D_HX+1,y
    lda #$00
    sta D_X,y
    sta D_HX,y
    lda DT_KIND,x
    sta D_KIND,y
    A16
    lda DT_Y,x
    sta D_Y,y
    sta D_HY,y
    lda #$0000
    sta D_YF,y
    sta D_VX,y
    sta D_VY,y
    sta D_STATE,y
    sta D_TIMER,y
    sta D_CD,y
    sta D_FLAGS,y
@next16:
    A8
@next:
    inx
    inx
    cpx #(NUM_DOGS*2)
    bne @t
    rts

; per-kind: max speed, acceleration
kind_max: .word $01A0, $0180, $0200, $01C0
kind_acc: .word $0018, $0012, $0020, $0028

dogs_update:
    ; how many dogs are on you right now (only one at a time may be)
    stz k_live
    ldx #$0000
@cnt:
    lda D_SLOT,x
    cmp #$FF
    beq @cn
    lda D_STATE,x
    cmp #DS_ALERT
    beq @on
    cmp #DS_CHARGE
    bne @cn
@on:
    inc k_live
@cn:
    inx
    inx
    cpx #(NUM_ENT*2)
    bne @cnt
    ldx #$0000
@d:
    lda D_SLOT,x
    cmp #$FF
    bne @live
    jmp @next
@live:
    stx k_cur
    ; despawn far below the camera
    A16
    lda D_Y,x
    sec
    sbc k_cam
    bmi @keep
    cmp #400
    bcc @keep
    A8
    lda #$FF
    sta D_SLOT,x
    jmp @next
@keep:
    A8
    jsr dog_think
    ldx k_cur
    jsr dog_move
    ldx k_cur
@next:
    inx
    inx
    cpx #(NUM_ENT*2)
    beq @x
    jmp @d
@x:
    rts

; X = dog slot
dog_think:
    lda D_CD,x
    beq @nocd
    dec D_CD,x
@nocd:
    ; the white squirrel beats everything a dog was doing on your account
    lda sq_state
    beq @nosq
    lda D_STATE,x
    cmp #DS_BALL
    bcs @nosq                   ; wander / alert / charge only
    jsr squirrel_near
    bcc @nosq
    lda #DS_SQUIRREL
    sta D_STATE,x
@nosq:
    lda D_STATE,x
    cmp #DS_WANDER
    bne @not_w
    jmp think_wander
@not_w:
    cmp #DS_ALERT
    bne @not_a
    jmp think_alert
@not_a:
    cmp #DS_CHARGE
    bne @not_c
    jmp think_charge
@not_c:
    cmp #DS_BALL
    bne @not_b
    jmp think_ball
@not_b:
    cmp #DS_PAST
    bne @not_p
    jmp think_past
@not_p:
    cmp #DS_SQUIRREL
    bne @not_s
    jmp think_squirrel
@not_s:
    cmp #DS_SIT
    bne @not_t
    jmp think_sit
@not_t:
    cmp #DS_LICK
    bne @not_l
    jmp think_lick
@not_l:
    jmp think_return

; |player - dog| (manhattan) -> A16 in tmp1; dx -> tmp2, dy -> tmp3 (signed)
dog_dist:
    A16
    lda k_x
    xba
    and #$00FF
    sta tmp2
    lda D_X,x
    xba
    and #$00FF
    eor #$FFFF
    sec
    adc tmp2
    sta tmp2                    ; dx = player - dog
    lda k_y
    sec
    sbc D_Y,x
    sta tmp3                    ; dy
    lda tmp2
    bpl @a
    eor #$FFFF
    inc a
@a:
    sta tmp1
    lda tmp3
    bpl @b
    eor #$FFFF
    inc a
@b:
    clc
    adc tmp1
    sta tmp1
    A8
    rts

think_wander:
    ; (a dog busy sniffing ignores balls: you can't pre-empt every dog)
    lda k_state
    cmp #ST_WALK
    jne @amble
    ldy k_inv                   ; nobody starts on you while you get clear
    jne @amble
    ldy k_calm                  ; ... or just after the last one
    jne @amble
    lda k_live                  ; one dog at a time
    jne @amble
    lda D_CD,x
    bne @amble
    ; only a dog you can see: never from off-screen or behind the HUD
    A16
    lda D_Y,x
    sec
    sbc k_cam
    cmp #SPOT_TOP
    bcc @far16
    cmp #(SPOT_BOT + 1)
    bcs @far16
    A8
    jsr dog_dist
    A16
    lda tmp1
    cmp #SPOT_R
    bcc @spot
@far16:
    A8
    bra @amble
@spot:
    A8
    inc k_live
    ; spotted you!
    lda #DS_ALERT
    sta D_STATE,x
    lda #20                     ; the tell: ALERT_T..ALERT_T+19 frames
    jsr ev_range
    clc
    adc #ALERT_T
    ldx k_cur
    sta D_TIMER,x
    A16
    stz D_VX,x
    stz D_VY,x
    A8
    SFX SFX_BARK
    lda k_coach                 ; the first dog teaches the move
    bne @shout
    inc k_coach
    LDPTR0 str_coach_b
    lda #TP_YELLOW
    jsr popup
    ldx #150
    stx k_popup
    ldx k_cur
    rts
@shout:
    jsr owner_shout             ; the warning beats any banner that's up
    ldx k_cur
@x:
    rts
@amble:
    ; wander: new random heading now and then
    dec D_TIMER,x
    bpl @x
    lda #50
    jsr ev_range
    clc
    adc #30
    ldx k_cur
    sta D_TIMER,x
    lda #3
    jsr ev_range
    asl a
    TAYB
    ldx k_cur
    A16
    lda amble_v,y
    sta D_VX,x
    A8
    lda #3
    jsr ev_range
    asl a
    TAYB
    ldx k_cur
    A16
    lda amble_v+6,y
    sta D_VY,x
    ; drift back toward home if too far
    lda D_HY,x
    sec
    sbc D_Y,x
    bpl @h
    eor #$FFFF
    inc a
@h:
    cmp #28
    bcc @ok
    lda D_HY,x
    sec
    sbc D_Y,x
    bmi @hu
    lda #$0060
    bra @hs
@hu:
    lda #($10000 - $0060)
@hs:
    sta D_VY,x
@ok:
    A8
    rts

amble_v: .word $10000 - $0070, $0070, 0, $10000 - $0040, $0040, 0

think_alert:
    jsr ball_near
    bcc @noball
    jmp go_ball
@noball:
    ; walk right up to a barking dog and he bounces back out of your way:
    ; the lunge always comes from a few strides out, so it can be timed
    jsr dog_dist                ; tmp1 = distance, tmp2/tmp3 = you - him
    A16
    stz D_VX,x
    stz D_VY,x
    lda tmp1
    cmp #BACK_R
    bcs @stay
    lda tmp3
    beq @bx
    bmi @bs
    lda #($10000 - $0100)       ; you're south of him: he backs north
    bra @by
@bs:
    lda #$0100
@by:
    sta D_VY,x
@bx:
    lda tmp2
    beq @stay
    bmi @bxr
    lda #($10000 - $0080)
    bra @bxs
@bxr:
    lda #$0080
@bxs:
    sta D_VX,x
@stay:
    A8
    dec D_TIMER,x
    bne @x
    lda #DS_CHARGE
    sta D_STATE,x
    lda #120
    sta D_TIMER,x
    lda D_FLAGS,x
    and #$FE
    sta D_FLAGS,x
@x:
    rts

think_charge:
    jsr ball_near
    bcc @noball
    jmp go_ball
@noball:
    jsr dog_dist
    dec D_TIMER,x
    bne @chase
    ; ran out of puff (no points: you didn't do anything)
    lda #DOG_CD
    sta D_CD,x
    lda #CALM_END
    sta k_calm
    jmp go_home
@chase:
    ; tackle?
    lda k_state
    cmp #ST_WALK
    bne @steer
    ldy k_inv
    bne @steer
    ldy k_dash
    bne @steer
    A16
    lda tmp1
    cmp #10
    A8
    bcs @steer
    jmp tackle
@steer:
    ; accelerate toward the player; an axis that has overshot stops dead
    ; (no orbiting round you: if you don't sidestep, you're tackled)
    lda D_KIND,x
    asl a
    TAYB
    A16
    lda kind_acc,y
    sta tmp4
    lda kind_max,y
    sta tmp5
    lda D_VX,x
    eor tmp2
    bpl @samex
    stz D_VX,x
@samex:
    lda D_VY,x
    eor tmp3
    bpl @samey
    stz D_VY,x
@samey:
    lda tmp2
    jsr steer_axis
    ldx k_cur
    lda D_VX,x
    clc
    adc tmp6
    jsr clamp_v
    sta D_VX,x
    lda tmp3
    jsr steer_axis
    ldx k_cur
    lda D_VY,x
    clc
    adc tmp6
    jsr clamp_v
    sta D_VY,x
    A8
    rts

; A16 = delta -> tmp6 = +acc / -acc / 0
steer_axis:
    .a16
    cmp #$0000
    beq @z
    bmi @n
    lda tmp4
    sta tmp6
    rts
@n:
    lda tmp4
    eor #$FFFF
    inc a
    sta tmp6
    rts
@z:
    stz tmp6
    rts

; A16 = velocity -> clamped to +-tmp5
clamp_v:
    .a16
    bmi @neg
    cmp tmp5
    bcc @ok
    lda tmp5
@ok:
    rts
@neg:
    eor #$FFFF
    inc a
    cmp tmp5
    bcc @ok2
    lda tmp5
@ok2:
    eor #$FFFF
    inc a
    rts
.a8

tackle:
    A16
    inc k_tackle
    inc k_hurt
    stz k_streak
    stz D_VX,x
    stz D_VY,x
    A8
    lda #ST_DOWN
    sta k_state
    ldx #DOWN_T                 ; a good long face-lick
    stx k_timer
    SFX SFX_CRASH
    LDPTR0 str_tackled
    lda #TP_RED
    jsr popup
    ldx #60
    stx k_popup
    ; every owner finally grabs a collar: the other dogs after you go home
    ldx #$0000
@calm:
    lda D_SLOT,x
    cmp #$FF
    beq @cn
    lda D_STATE,x
    cmp #DS_ALERT
    beq @home
    cmp #DS_CHARGE
    bne @cn
@home:
    lda #DOG_CD
    sta D_CD,x
    lda #DS_RETURN
    sta D_STATE,x
@cn:
    inx
    inx
    cpx #(NUM_ENT*2)
    bne @calm
    ; the chain's over, and he's on top of you for a good lick
    stz k_chain
    stz k_srun
    stz k_armed
    ldx k_cur
    lda #DOG_CD
    sta D_CD,x
    lda #DS_LICK
    sta D_STATE,x
    lda #(DOWN_T - 20)
    sta D_TIMER,x
    A16
    lda k_x                     ; beside you, facing you, licking
    cmp #(200*256)
    bcs @lft
    clc
    adc #$0F00
    sta D_X,x
    lda #$FFFF                  ; (a hair of leftward drift: he faces you)
    bra @lk
@lft:
    sec                         ; by the east fence: from the other side
    sbc #$0F00
    sta D_X,x
    lda #$0001
@lk:
    sta D_VX,x
    stz D_VY,x
    lda k_y
    inc a
    sta D_Y,x
    A8
    rts

; X = dog slot, tmp1 = its distance: you sidestepped it. It skids past,
; then sits down wagging for a pat (DODGE 'N' PAT).
dodged:
    A16
    inc k_dodged
    stz k_wrun
    A8
    lda #DS_PAST
    sta D_STATE,x
    lda #PAST_T
    sta D_TIMER,x
    lda #DOG_CD
    sta D_CD,x
    ldy #DASH_HIT
    sty k_dashcd
    ldy #CALM_DODGE
    sty k_calm
    SFX SFX_COIN
    ; got set early (armed): a plain DODGE. Timed by hand with him in range:
    ; +HAND_BONUS, and right on you: CLOSE SHAVE, +SHAVE_BONUS
    lda k_shok
    beq @plain
    A16
    inc k_hand
    lda tmp1
    cmp #SHAVE_R
    bcc @shave
    lda k_style
    clc
    adc #HAND_BONUS
    sta k_style
    A8
    stz k_srun
    LDPTR0 str_timed
    lda #TP_GREEN
    bra @say
@shave:
    .a16
    inc k_shaves
    A8
    lda k_srun                  ; shaves in a row: x2, x3, x4
    cmp #SHAVE_RUN
    bcs @sr
    inc k_srun
@sr:
    lda k_srun
    dec a
    asl a
    TAYB
    A16
    lda shave_msgs,y
    sta ptr0
    lda shave_pts,y
    clc
    adc k_style
    sta k_style
    A8
    lda #^shave_msgs
    sta ptr0+2
    lda #TP_YELLOW
    bra @say
@plain:
    stz k_srun
    LDPTR0 str_dodge
    lda #TP_WHITE
@say:
    jsr popup
    ldx #50
    stx k_popup
    ldx k_cur
    jmp beat_dog

; a dog beaten (dodged or fetched): every HEAL_RUN in a row since the last
; tackle wins back a lost heart (keeps X)
beat_dog:
    A16
    inc k_streak
    lda k_streak
    cmp #HEAL_RUN
    bcc @x
    lda k_hurt
    beq @x
    dec k_hurt
    stz k_streak
    A8
    SFX SFX_CHEER
    rts
@x:
    A8
    rts

str_dodge: .byte " DODGE! ", 0
str_timed: .byte " NICE TIMING! +25 ", 0
shave_msgs: .addr str_shave, str_shave2, str_shave3, str_shave4
shave_pts:  .word SHAVE_BONUS, SHAVE_BONUS*2, SHAVE_BONUS*3, SHAVE_BONUS*4
str_shave:  .byte " CLOSE SHAVE! +75 ", 0
str_shave2: .byte " CLOSE SHAVE X2! +150 ", 0
str_shave3: .byte " CLOSE SHAVE X3! +225 ", 0
str_shave4: .byte " CLOSE SHAVE X4!! +300 ", 0

; skidding past: slow down, then sit
think_past:
    A16
    lda D_VX,x
    jsr @fric
    sta D_VX,x
    lda D_VY,x
    jsr @fric
    sta D_VY,x
    A8
    dec D_TIMER,x
    bne @x
    lda #DS_SIT
    sta D_STATE,x
    lda #SIT_T
    sta D_TIMER,x
    A16
    stz D_VX,x
    stz D_VY,x
    A8
@x:
    rts
; A16: v - v/16 (arithmetic)
@fric:
    .a16
    sta tmp0
    cmp #$8000
    ror a
    cmp #$8000
    ror a
    cmp #$8000
    ror a
    cmp #$8000
    ror a
    eor #$FFFF
    sec
    adc tmp0
    rts
.a8

; sat down after a dodge: walk up to him for a pat before he loses interest
think_sit:
    lda k_state
    cmp #ST_WALK
    bne @wait
    jsr dog_dist
    A16
    lda tmp1
    cmp #PAT_R
    A8
    bcc pat_dog
@wait:
    dec D_TIMER,x
    bne @x
    jmp go_home
@x:
    rts

; GOOD BOY! The chain grows; each pat is worth 20 x the chain
pat_dog:
    ldy #24
    sty k_patf
    ldy #3                      ; face him
    lda D_X+1,x
    cmp k_x+1
    bcs @fr
    dey
@fr:
    sty k_dir
    lda #DS_RETURN
    sta D_STATE,x
    lda #DOG_CD
    sta D_CD,x
    lda k_chain
    cmp #CHAIN_MAX
    bcs @top
    inc k_chain
@top:
    A16
    inc k_pats
    lda k_chain
    and #$00FF
    sta tmp0
    asl a
    asl a
    clc
    adc tmp0                    ; x5
    asl a
    asl a                       ; x20
    sta tmp1
    clc
    adc k_style
    sta k_style
    lda k_calm
    cmp #30
    bcs @c
    lda #30
    sta k_calm
@c:
    A8
    SFX SFX_BARK
    lda k_chain
    dec a
    asl a
    TAYB
    A16
    lda pat_msgs,y
    sta ptr0
    A8
    lda #^pat_msgs
    sta ptr0+2
    lda k_live                  ; another dog's winding up: his warning stays
    bne @q                      ; (the HUD's PAT X still counts it)
    lda #TP_YELLOW
    jsr popup
    ldx #70
    stx k_popup
@q:
    ldx k_cur
    rts

pat_msgs: .addr pm1, pm2, pm3, pm4, pm5
pm1: .byte " GOOD BOY! DODGE 'N' PAT +20 ", 0
pm2: .byte " DODGE 'N' PAT X2! +40 ", 0
pm3: .byte " DODGE 'N' PAT X3! +60 ", 0
pm4: .byte " DODGE 'N' PAT X4! +80 ", 0
pm5: .byte " DODGE 'N' PAT X5!! +100 ", 0

; tackled you: stay on top, tail going, till you're back up
think_lick:
    lda k_state
    cmp #ST_DOWN
    bne @off
    dec D_TIMER,x
    bne @x
@off:
    jmp go_home
@x:
    rts

; chase the white squirrel (never quite catching it) until it's up a tree
think_squirrel:
    lda sq_state
    bne @chase
    lda #DOG_CD
    sta D_CD,x
    jmp go_home
@chase:
    A16
    lda sq_x
    xba
    and #$00FF
    sta tmp2
    lda D_X,x
    xba
    and #$00FF
    eor #$FFFF
    sec
    adc tmp2
    sta tmp2
    lda sq_y
    sec
    sbc D_Y,x
    sta tmp3
    lda #$0028
    sta tmp4
    lda #$0180
    sta tmp5
    jmp steer_dog

; A16 in: tmp2/tmp3 = dx/dy to target, tmp4 = accel, tmp5 = top speed
steer_dog:
    .a16
    lda tmp2
    jsr steer_axis
    ldx k_cur
    lda D_VX,x
    clc
    adc tmp6
    jsr clamp_v
    sta D_VX,x
    lda tmp3
    jsr steer_axis
    ldx k_cur
    lda D_VY,x
    clc
    adc tmp6
    jsr clamp_v
    sta D_VY,x
    A8
    rts

; carry set if the running squirrel is within 80 px of dog X
squirrel_near:
    lda sq_x+1
    sec
    sbc D_X+1,x
    bcs @a
    eor #$FF
    inc a
@a:
    cmp #80
    bcs @no
    A16
    lda sq_y
    sec
    sbc D_Y,x
    bpl @b
    eor #$FFFF
    inc a
@b:
    cmp #80
    A8
    bcs @no
    sec
    rts
@no:
    clc
    rts

str_tackled: .byte " TACKLED! (HE'S FRIENDLY) ", 0

think_ball:
    lda b_state
    bne @chase
    ; someone else got it
    lda #DOG_CD
    sta D_CD,x
    jmp go_home
@chase:
    ; run to the ball
    A16
    lda b_x
    xba
    and #$00FF
    sta tmp2
    lda D_X,x
    xba
    and #$00FF
    eor #$FFFF
    sec
    adc tmp2
    sta tmp2
    lda b_y
    sec
    sbc D_Y,x
    sta tmp3
    lda tmp2
    bpl @a
    eor #$FFFF
    inc a
@a:
    sta tmp1
    lda tmp3
    bpl @b
    eor #$FFFF
    inc a
@b:
    clc
    adc tmp1
    cmp #8
    bcs @run
    A8
    lda b_state
    cmp #2
    bne @wait                   ; still in the air: wait under it
    ; got it: off to show the owner, ball in mouth
    stz b_state
    lda D_FLAGS,x
    ora #$02
    sta D_FLAGS,x
    lda #DOG_CD
    sta D_CD,x
    SFX SFX_BARK
    ldx k_cur
    jmp go_home
@wait:
    A16
    stz D_VX,x
    stz D_VY,x
    A8
    rts
@run:
    .a16
    lda #$0030
    sta tmp4
    lda #$0200
    sta tmp5
    lda tmp2
    jsr steer_axis
    ldx k_cur
    lda D_VX,x
    clc
    adc tmp6
    jsr clamp_v
    sta D_VX,x
    lda tmp3
    jsr steer_axis
    ldx k_cur
    lda D_VY,x
    clc
    adc tmp6
    jsr clamp_v
    sta D_VY,x
    A8
    rts

think_return:
    A16
    lda D_HX,x
    xba
    and #$00FF
    sta tmp2
    lda D_X,x
    xba
    and #$00FF
    eor #$FFFF
    sec
    adc tmp2
    sta tmp2
    lda D_HY,x
    sec
    sbc D_Y,x
    sta tmp3
    lda tmp2
    bpl @a
    eor #$FFFF
    inc a
@a:
    sta tmp1
    lda tmp3
    bpl @b
    eor #$FFFF
    inc a
@b:
    clc
    adc tmp1
    cmp #10
    bcs @walk
    A8
    stz D_STATE,x
    lda D_FLAGS,x
    and #$FD
    sta D_FLAGS,x
    lda D_CD,x
    cmp #160
    bcs @cd
    lda #160
    sta D_CD,x
@cd:
    A16
    stz D_VX,x
    stz D_VY,x
    A8
    rts
@walk:
    .a16
    lda #$0020
    sta tmp4
    lda #$00C0
    sta tmp5
    lda tmp2
    jsr steer_axis
    ldx k_cur
    lda D_VX,x
    clc
    adc tmp6
    jsr clamp_v
    sta D_VX,x
    lda tmp3
    jsr steer_axis
    ldx k_cur
    lda D_VY,x
    clc
    adc tmp6
    jsr clamp_v
    sta D_VY,x
    A8
    rts

go_home:
    lda #DS_RETURN
    sta D_STATE,x
    rts

go_ball:
    lda D_STATE,x
    cmp #DS_ALERT
    bcc @n
    cmp #(DS_CHARGE + 1)
    bcs @n
    A16
    inc k_fetch                 ; a dog that was coming for you: fetch!
    lda #CALM_END
    sta k_calm
    A8
    jsr beat_dog
@n:
    lda #DS_BALL
    sta D_STATE,x
    rts

; carry set if the thrown ball (flying or resting) is within 112 px of dog X
ball_near:
    lda b_state
    beq @no
    lda b_x+1
    sec
    sbc D_X+1,x
    bcs @a
    eor #$FF
    inc a
@a:
    cmp #112
    bcs @no
    A16
    lda b_y
    sec
    sbc D_Y,x
    bpl @b
    eor #$FFFF
    inc a
@b:
    cmp #112
    A8
    bcs @no
    sec
    rts
@no:
    clc
    rts

owner_shout:
    lda #5
    jsr ev_range
    A16
    and #$00FF
    asl a
    tax
    lda f:shouts,x
    sta ptr0
    A8
    lda #^shouts
    sta ptr0+2
    lda #TP_CYAN
    jsr popup
    ldx #70
    stx k_popup
    rts

shouts: .addr sh0, sh1, sh2, sh3, sh4
sh0: .byte " HE'S FRIENDLY! ", 0
sh1: .byte " SHE JUST WANTS TO PLAY! ", 0
sh2: .byte " HE'S NEVER DONE THIS! ", 0
sh3: .byte " HE'S A GOOD BOY! ", 0
sh4: .byte " SORRY, HE'S A RESCUE! ", 0

; integrate velocity
dog_move:
    A16
    lda D_X,x
    clc
    adc D_VX,x
    cmp #(16*256)
    bcs @l
    lda #(16*256)
@l:
    cmp #(240*256)
    bcc @r
    lda #(240*256)
@r:
    sta D_X,x
    lda D_VY,x
    beq @x
    lda D_YF,x
    and #$00FF
    clc
    adc D_VY,x
    pha
    and #$00FF
    sta D_YF,x
    pla
    xba
    and #$00FF
    cmp #$0080
    bcc @p
    ora #$FF00
@p:
    clc
    adc D_Y,x
    sta D_Y,x
@x:
    A8
    rts

; ------------------------------------------------------------------
; draw everything sorted by y (lower on screen = nearer = drawn first)
park_draw:
    jsl oam_clear
    ; collect: dogs 0..7, player = 8, ball = 9 (if any)
    ldy #$0000
    ldx #$0000
@c:
    lda D_SLOT,x
    cmp #$FF
    beq @nc
    txa
    sta k_order,y
    iny
@nc:
    inx
    inx
    cpx #(NUM_ENT*2)
    bne @c
    lda #$80                    ; player marker
    sta k_order,y
    iny
    sty k_cnt                   ; count
    ; selection sort by y, descending
    ldx #$0000
@o:
    cpx k_cnt
    bcs @sorted
    stx tmp5
    txy
@i:
    iny
    cpy k_cnt
    bcs @sw
    phx
    lda k_order,y
    jsr order_y
    sta tmp1
    lda tmp0+1
    sta tmp1+1
    plx
    phx
    lda k_order,x
    jsr order_y
    plx
    A16
    lda tmp1
    cmp tmp0
    A8
    bcc @i
    ; y item is lower on screen: swap into x
    lda k_order,x
    pha
    lda k_order,y
    sta k_order,x
    pla
    sta k_order,y
    bra @i
@sw:
    ldx tmp5
    inx
    bra @o
@sorted:
    ldx #$0000
@dr:
    cpx k_cnt
    bcs @ball
    phx
    lda k_order,x
    bmi @pl
    TAXB
    stx k_cur
    jsr draw_dog
    bra @nd
@pl:
    jsr draw_player
@nd:
    plx
    inx
    bra @dr
@ball:
    jsr draw_squirrel
    jsr draw_ball
    jsr draw_ground_balls
    jsr draw_pshadow            ; last = under every other sprite
    rts

; a dark ground shadow under the walker so they read on any blanket
draw_pshadow:
    lda k_state
    cmp #ST_DOWN
    beq @x
    A16
    lda k_x
    xba
    and #$00FF
    sta spr_x
    lda k_y
    jsr screen_y
    A8
    ldx #$FFFF
    jsr prio_at
    lda k_prio
    ora #$0A
    sta tmp5
    stz tmp5+1
    LDPTR1 ms_pshadow
    ldx #MS_PSHADOW_BASE
    stx tmp6
    jsl oam_meta
@x:
    rts

draw_squirrel:
    lda sq_state
    bne @on
    rts
@on:
    A16
    lda sq_x
    xba
    and #$00FF
    sta spr_x
    lda sq_y
    jsr screen_y
    lda frame
    and #$0004
    lsr a
    eor #$FFFF
    sec
    adc spr_y                   ; hop
    sta spr_y
    A8
    lda #$3A
    sta tmp5
    stz tmp5+1
    lda sq_vx+1
    bpl @r
    lda #$40
    sta tmp5+1
@r:
    lda frame
    and #$04
    beq @f0
    LDPTR1 ms_sq1
    ldx #MS_SQ1_BASE
    bra @d
@f0:
    LDPTR1 ms_sq0
    ldx #MS_SQ0_BASE
@d:
    stx tmp6
    jsl oam_meta
    rts

; A = order entry -> tmp0 = world y (A8 out)
order_y:
    bmi @p
    TAXB
    lda D_Y,x
    sta tmp0
    lda D_Y+1,x
    sta tmp0+1
    rts
@p:
    lda k_y
    sta tmp0
    lda k_y+1
    sta tmp0+1
    rts

; screen y from world y in A16 -> spr_y
screen_y:
    .a16
    sec
    sbc k_cam
    sta spr_y
    rts
.a8

draw_player:
    lda k_inv
    beq @show
    lda frame
    and #$02
    beq @show
    rts
@show:
    A16
    lda k_x
    xba
    and #$00FF
    sta spr_x
    lda k_y
    jsr screen_y
    A8
    ldx #$FFFF
    jsr prio_at                 ; behind a tree canopy?
    lda k_prio
    sta tmp5
    stz tmp5+1
    lda k_state
    cmp #ST_DOWN
    bne @up
    ; tackled: a cartwheel, then flat out kicking while he licks
    A16
    lda #150
    sec
    sbc k_timer
    A8
    cmp #24
    bcs @lying
    lsr a
    lsr a
    lsr a
    clc
    adc #PF_TUMB1
    bra @put
@lying:
    lda frame
    lsr a
    lsr a
    lsr a
    lsr a
    and #$01
    clc
    adc #PF_DOWN
    bra @put
@up:
    ; facing: left = the side frames mirrored
    lda k_dir
    cmp #2
    bne @nf
    lda #$40
    sta tmp5+1
@nf:
    lda k_patf
    beq @np
    lda #PF_PAT
    bra @put
@np:
    lda k_dash
    beq @nd
    ; mid-sidestep: a side stride the way you're stepping
    stz tmp5+1
    lda k_dvx+1
    bpl @dr
    lda #$40
    sta tmp5+1
@dr:
    lda #PF_S0
    bra @put
@nd:
    lda k_armed
    beq @walk
    lda #PF_READY
    bra @put
@walk:
    lda k_anim
    lsr a
    lsr a
    lsr a
    and #$03
    sta tmp0
    lda k_dir
    cmp #3
    bcc @g
    lda #2                      ; right = side
@g:
    asl a
    asl a
    clc
    adc tmp0
    TAXB
    lda walk_seq,x
@put:
    asl a
    TAXB
    lda pl_ptrs,x
    sta ptr1
    lda pl_ptrs+1,x
    sta ptr1+1
    lda #^pl_ptrs
    sta ptr1+2
    lda pl_bases,x
    sta tmp6
    stz tmp6+1
    jsl oam_meta
    rts

PF_S0    = 6
PF_READY = 9
PF_PAT   = 10
PF_TUMB1 = 11
PF_DOWN  = 14
pl_ptrs:  .addr ms_walk_d0, ms_walk_dp, ms_walk_d1, ms_walk_u0, ms_walk_up, ms_walk_u1
          .addr ms_walk_s0, ms_walk_sp, ms_walk_s1, ms_ready, ms_pat
          .addr ms_tumb1, ms_tumb2, ms_tumb3, ms_down, ms_downk
pl_bases: .word MS_WALK_D0_BASE, MS_WALK_DP_BASE, MS_WALK_D1_BASE
          .word MS_WALK_U0_BASE, MS_WALK_UP_BASE, MS_WALK_U1_BASE
          .word MS_WALK_S0_BASE, MS_WALK_SP_BASE, MS_WALK_S1_BASE, MS_READY_BASE, MS_PAT_BASE
          .word MS_TUMB1_BASE, MS_TUMB2_BASE, MS_TUMB3_BASE, MS_DOWN_BASE, MS_DOWNK_BASE
walk_seq: .byte 0, 1, 2, 1,  3, 4, 5, 4,  6, 7, 8, 7

; dog frames (+9 for the corgi)
DF_RUN   = 0
DF_STAND = 4
DF_LUNGE = 6
DF_SIT   = 7

draw_dog:
    ldx k_cur
    A16
    lda D_X,x
    xba
    and #$00FF
    sta spr_x
    lda D_Y,x
    jsr screen_y
    A8
    ; after you but off the bottom / top of the screen: a "!" pinned to the edge
    lda D_STATE,x
    cmp #DS_ALERT
    beq @threat
    cmp #DS_CHARGE
    bne @vis0
@threat:
    A16
    lda spr_y
    bmi @vis16
    cmp #(SPOT_BOT + 8)
    bcc @vis16
    lda #(SPOT_BOT + 2)
    sta spr_y
    A8
    jmp draw_warn
@vis16:
    A8
@vis0:
    A16
    lda spr_y
    cmp #($10000 - 24)
    bcs @vis
    cmp #240
    bcc @vis
    A8
    rts
@vis:
    A8
    ldx k_cur
    jsr prio_at
    ; palette by kind (1-4)
    lda D_KIND,x
    inc a
    asl a
    ora k_prio
    sta tmp5
    stz tmp5+1
    lda D_STATE,x
    cmp #DS_ALERT
    bne @fv
    lda k_x+1                   ; barking (even backing off): he faces you
    cmp D_X+1,x
    bcs @r
    bra @fl
@fv:
    lda D_VX+1,x
    bpl @r
@fl:
    lda #$40
    sta tmp5+1
@r:
    lda D_STATE,x
    cmp #DS_SIT
    bne @nsit
    lda frame
    lsr a
    lsr a
    lsr a
    and #$01
    clc
    adc #DF_SIT
    jmp @f
@nsit:
    cmp #DS_LICK
    bne @nlick
    lda frame
    lsr a
    lsr a
    and #$01
    clc
    adc #DF_STAND
    bra @f
@nlick:
    cmp #DS_ALERT
    bne @nalert
    lda frame
    lsr a
    lsr a
    and #$01
    clc
    adc #DF_STAND
    bra @f
@nalert:
    cmp #DS_CHARGE
    bne @move
    jsr dog_dist                ; lunging when he's nearly on you
    ldx k_cur
    A16
    lda tmp1
    cmp #28
    A8
    bcs @fast
    lda #DF_LUNGE
    bra @f
@move:
    A16
    lda D_VX,x
    ora D_VY,x
    A8
    beq @idle
    lda D_STATE,x
    cmp #DS_WANDER
    beq @slow
    cmp #DS_RETURN
    beq @slow
@fast:
    lda frame
    lsr a
    lsr a
    and #$03
    bra @f
@slow:
    lda frame
    lsr a
    lsr a
    lsr a
    and #$03
    bra @f
@idle:
    lda frame
    lsr a
    lsr a
    lsr a
    lsr a
    and #$01
    clc
    adc #DF_STAND
@f:
    sta tmp0
    lda D_KIND,x
    cmp #3                      ; corgis are the small ones
    bne @big
    lda tmp0
    clc
    adc #9
    sta tmp0
@big:
    lda tmp0
    asl a
    TAYB
    lda dog_ptrs,y
    sta ptr1
    lda dog_ptrs+1,y
    sta ptr1+1
    lda #^dog_ptrs
    sta ptr1+2
    lda dog_bases,y
    sta tmp6
    stz tmp6+1
    jsl oam_meta
    ; a tennis ball in the mouth, carried home
    ldx k_cur
    lda D_FLAGS,x
    and #$02
    beq @noball
    jsr dog_mouth
    LDPTR1 ms_ball
    ldx #MS_BALL_BASE
    stx tmp6
    jsl oam_meta
@noball:
    ; "!" over alerted dogs, a blinking heart over a sitting one
    ldx k_cur
    lda D_STATE,x
    cmp #DS_SIT
    beq @heart
    cmp #DS_ALERT
    bne @x
    A16
    lda spr_y
    sec
    sbc #16
    sta spr_y
    A8
    lda #$3A
    sta tmp5
    stz tmp5+1
    LDPTR1 ms_bang
    ldx #MS_BANG_BASE
    stx tmp6
    jsl oam_meta
@x:
    rts
@heart:
    lda frame
    and #$10
    beq @x
    A16
    lda spr_y
    sec
    sbc #17
    sta spr_y
    A8
    lda #$3A
    sta tmp5
    stz tmp5+1
    LDPTR1 ms_heart
    ldx #MS_HEART_BASE
    stx tmp6
    jsl oam_meta
    rts

; spr_x/spr_y -> the ball's spot at a dog's mouth (tmp5+1 = its flip)
dog_mouth:
    A16
    lda spr_y
    sec
    sbc #7
    sta spr_y
    lda tmp5
    and #$4000
    beq @rt
    lda spr_x
    sec
    sbc #11
    bra @x
@rt:
    lda spr_x
    clc
    adc #11
@x:
    sta spr_x
    A8
    lda k_prio
    ora #$0A
    sta tmp5
    stz tmp5+1
    rts

; spr_y = SPOT_BOT + 2: a blinking "!" and an arrow pinned to the bottom edge
draw_warn:
    lda frame
    and #$08
    beq @x
    lda #$3A
    sta tmp5
    stz tmp5+1
    LDPTR1 ms_bang
    ldx #MS_BANG_BASE
    stx tmp6
    jsl oam_meta
    A16
    lda spr_y
    inc a
    sta spr_y
    A8
    LDPTR1 ms_arrow
    ldx #MS_ARROW_BASE
    stx tmp6
    jsl oam_meta
@x:
    rts

dog_ptrs:  .addr ms_dog0, ms_dog1, ms_dog2, ms_dog3, ms_dog4, ms_dog5, ms_dog6, ms_dog7, ms_dog8
           .addr ms_pup0, ms_pup1, ms_pup2, ms_pup3, ms_pup4, ms_pup5, ms_pup6, ms_pup7, ms_pup8
dog_bases: .word MS_DOG0_BASE, MS_DOG1_BASE, MS_DOG2_BASE, MS_DOG3_BASE, MS_DOG4_BASE
           .word MS_DOG5_BASE, MS_DOG6_BASE, MS_DOG7_BASE, MS_DOG8_BASE
           .word MS_PUP0_BASE, MS_PUP1_BASE, MS_PUP2_BASE, MS_PUP3_BASE, MS_PUP4_BASE
           .word MS_PUP5_BASE, MS_PUP6_BASE, MS_PUP7_BASE, MS_PUP8_BASE

; X = dog slot, or the walker if called from draw_player: k_prio = $30
; (in front of everything) or $20 (behind a tree canopy: feet in its shade)
prio_at:
    phx
    A16
    cpx #$FFFF
    beq @pl
    lda D_Y,x
    sta tmp4
    lda D_X,x
    bra @go
@pl:
    lda k_y
    sta tmp4
    lda k_x
@go:
    xba
    and #$00FF
    jsr behind_at
    A8
    lda #$30
    bcc @f
    lda #$20
@f:
    sta k_prio
    plx
    rts

; A16 = x, tmp4 = y (feet) -> carry set if that's behind a canopy (stays A16)
behind_at:
    .a16
    lsr a
    lsr a
    lsr a
    sta tmp0
    lda tmp4
    cmp #PARK_H
    bcs @no
    lsr a
    lsr a
    lsr a
    asl a
    asl a
    sta tmp7
    lda tmp0
    lsr a
    lsr a
    lsr a
    clc
    adc tmp7
    tax
    lda tmp0
    and #$0007
    tay
    A8
    lda f:park_behind,x
    and bit_mask,y
    A16
    beq @no
    sec
    rts
@no:
    clc
    rts
.a8

draw_ball:
    lda b_state
    bne @on
    rts
@on:
    A16
    lda b_x
    xba
    and #$00FF
    sta spr_x
    lda b_y
    jsr screen_y
    A8
    lda #$3A
    sta tmp5
    stz tmp5+1
    LDPTR1 ms_shadow
    ldx #MS_SHADOW_BASE
    stx tmp6
    jsl oam_meta
    A16
    lda b_z
    xba
    and #$00FF
    eor #$FFFF
    sec
    adc spr_y
    sec
    sbc #3
    sta spr_y
    A8
    LDPTR1 ms_ball
    ldx #MS_BALL_BASE
    stx tmp6
    jsl oam_meta
    rts

draw_ground_balls:
    ldx #$0000
@g:
    lda GB_TAKEN,x
    bne @n
    stx k_cur
    A16
    lda GB_Y,x
    jsr screen_y
    cmp #($10000 - 8)
    bcs @v
    cmp #232
    bcs @n16
@v:
    lda GB_X,x
    and #$00FF
    sta spr_x
    A8
    lda #$3A
    sta tmp5
    stz tmp5+1
    LDPTR1 ms_ball
    ldx #MS_BALL_BASE
    stx tmp6
    jsl oam_meta
    ldx k_cur
@n16:
    A8
@n:
    inx
    inx
    cpx #(NUM_GB*2)
    bne @g
    rts

; ------------------------------------------------------------------
park_hud:
    lda frame
    and #$03
    beq park_hud_now
    rts
park_hud_now:
    ; solid HUD bars (rows 0-1 and 26-28) so sprites never muddle the numbers;
    ; the progress row is 26, clear of the last 8 lines (CRT overscan)
    ldx #(0*32)
    A16
    lda #$0220                  ; 32 x 2
    sta tmp1
    A8
    lda #TXT_WIN
    sta tmp2
    lda #$20
    jsl txt_fill
    ldx #(26*32)
    A16
    lda #$0320                  ; 32 x 3: row 28 covers the last scanline
    sta tmp1
    A8
    lda #TXT_WIN
    sta tmp2
    lda #$20
    jsl txt_fill
    lda #TXT_WIN
    sta txt_bg
    PRINT 1, 1, TP_WHITE, str_time
    A16
    lda k_time
    sta tmp0
    A8
    lda #60
    jsl div16
    ldx tmp0
    stx tmp1
    ldx #(1*32 + 6)
    ldy #3
    A16
    lda k_time
    cmp #HURRY_T
    A8
    lda #($20 | (TP_YELLOW << 2))
    bcs @tn
    lda #($20 | (TP_RED << 2))
@tn:
    jsl txt_num
    PRINT 10, 1, TP_WHITE, str_balls
    ldx k_balls
    stx tmp1
    ldx #(1*32 + 16)
    ldy #1
    lda #($20 | (TP_GREEN << 2))
    jsl txt_num
    ; hearts
    ldx #$0000
@heart:
    phx
    lda #(TXT_HEART + TXT_WIN)
    sta tmp2
    txa
    cmp k_hurt
    lda #($20 | (TP_GREY << 2))
    bcc @lost
    lda #($20 | (TP_RED << 2))
@lost:
    pha
    A16
    lda 2,s
    clc
    adc #(1*32 + 26)
    tax
    A8
    pla
    jsl txt_char
    plx
    inx
    cpx #3
    bne @heart
    ; DODGE 'N' PAT chain: "PATx3" while it's live
    lda k_chain
    beq @nochain
    PRINT 19, 1, TP_YELLOW, str_patx
    ldx k_chain
    stx tmp1
    ldx #(1*32 + 24)
    ldy #1
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_num
@nochain:
    ; progress north, row 26
    A16
    lda #START_Y
    sec
    sbc k_y
    bpl @in
    lda #$0000
@in:
    cmp #(START_Y - FINISH_Y)
    bcc @in2
    lda #(START_Y - FINISH_Y)
@in2:
    sta tmp0
    A8
    lda #36                     ; 2500 / (17 cells x 4)
    jsl div16
    lda tmp0
    sta tmp3
    ldx #$0000
@pc:
    lda tmp3
    cmp #4
    bcc @pp
    sbc #4
    sta tmp3
    lda #(TXT_METER + 4)
    bra @pput
@pp:
    clc
    adc #TXT_METER
    stz tmp3
@pput:
    sta tmp2
    phx
    A16
    txa
    clc
    adc #(26*32 + 7)
    tax
    A8
    lda #($20 | (TP_GREEN << 2))
    jsl txt_char
    plx
    inx
    cpx #17
    bne @pc
    PRINT 1, 26, TP_GREY, str_q
    PRINT 25, 26, TP_YELLOW, str_d
    stz txt_bg
    rts

str_time:  .byte "TIME", 0
str_balls: .byte "BALLS", 0
str_q:     .byte "QUEEN", 0
str_d:     .byte "DUNDAS", 0
str_patx:  .byte "PAT X", 0

; ------------------------------------------------------------------
park_score:
    A16
    lda k_time
    sta tmp0
    A8
    lda #60
    jsl div16
    A16
    lda tmp0
    sta ev_stat
    sta k_tmpx                  ; seconds left
    lda k_dodged
    clc
    adc k_fetch
    sta ev_stat+2               ; DOGS DODGED counts fetches too
    lda k_tackle
    sta ev_stat+4
    lda k_style
    sta ev_stat+6               ; DODGE 'N' PAT: pats + timing bonuses
    ; Every run reads the same way on the card:
    ;   CROSSING  finished: 750 + 15/s left under par (90 s) + 25/ball left
    ;             short of Dundas: up to 750 for the ground covered (the
    ;             square of the share walked: the last stretch counts most)
    ;             + 50 a dog dodged or fetched, either way
    ;   STYLE     DODGE 'N' PAT (pats, NICE TIMING, CLOSE SHAVE), either way
    ;   TACKLES   150 a tackle, either way; never takes a finish under 750
    ;             or anything under 0
    lda k_fin                   ; through the gate: a finish, even if GIVE UP
    and #$00FF                  ; came during the walk-in
    beq @failed
    lda #750
    sta tmp4
    lda k_tmpx
    sec
    sbc #PAR_LEFT
    bcc @nt
    ldy #15
    jsr madd
@nt:
    lda k_balls
    and #$00FF
    ldy #25
    jsr madd
    lda #750                    ; the floor a finish keeps
    bra @sum
@failed:
    .a16
    lda #START_Y
    sec
    sbc k_y
    bpl @p
    lda #$0000
@p:
    cmp #(START_Y - FINISH_Y)
    bcc @p2
    lda #(START_Y - FINISH_Y - 1)
@p2:
    sta tmp0
    A8
    lda #10
    jsl div16                   ; q = metres-ish, 0..249
    lda tmp0
    sta WRMPYA
    sta WRMPYB
    nop
    nop
    nop
    nop
    ldx RDMPYL
    stx tmp0
    lda #83
    jsl div16                   ; q^2 / 83: 0..747
    A16
    lda tmp0
    sta tmp4
    lda #$0000                  ; a run that didn't finish has no floor
@sum:
    .a16
    sta tmp5
    lda k_dodged
    clc
    adc k_fetch
    ldy #DODGE_PTS
    jsr madd
    lda tmp4
    sta ev_break                ; base
    lda k_style
    sta ev_break+2              ; bonus
    clc
    adc tmp4
    sta tmp4                    ; base + bonus
    sec
    sbc tmp5
    bcs @room
    lda #$0000
@room:
    sta tmp0                    ; the most the tackles can take
    lda #$0000
    ldy k_tackle
    beq @pz
@pl:
    clc
    adc #150                    ; 150 a tackle
    dey
    bne @pl
@pz:
    cmp tmp0
    bcc @pen
    lda tmp0
@pen:
    sta ev_break+4              ; penalty
    eor #$FFFF
    sec
    adc tmp4
    sta ev_score
    A8
    lda k_fin
    bne @ok
    lda k_quit
    bne @gq
    lda k_hurt
    cmp #3
    lda #$01                    ; TACKLED!
    bcs @f
    inc a                       ; OUT OF TIME!
    bra @f
@gq:
    lda #3                      ; gave up
    bra @f
@ok:
    lda #0
@f:
    sta ev_fail
    rts

; A16: tmp4 += A * Y (Y small)
madd:
    .a16
    cpy #$0000
    beq @x
    sta tmp0
@l:
    lda tmp4
    clc
    adc tmp0
    sta tmp4
    dey
    bne @l
@x:
    rts

.a8

.include "park_meta.inc"

; ------------------------------------------------------------------
; data built by tools/art_park.py that the shared assets.s doesn't carry
.segment "GFX5"
park_spr2:     .incbin "park_spr2.bin"      ; the dogs' half of the sprite sheet
park_spr2_end:
park_canopy:   .incbin "park_canopy.bin"
park_can_mask  = park_canopy
park_can_row   = park_canopy + 1280
park_can_cells = park_canopy + 1920
park_behind:   .incbin "park_behind.bin"
park_dogs:     .incbin "park_dogs.bin"
