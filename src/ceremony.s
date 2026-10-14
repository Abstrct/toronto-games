; Closing ceremony: Nathan Phillips Square, podium and fireworks,
; then the final standings table.
.p816
.smart -
.include "globals.inc"
.include "screens.inc"

.import c_order, c_place, c_champs, champ_names, why_line

NUM_FW  = 8
FW_LIFE = 56                    ; frames: rocket, small burst, big burst, sparkle
; podium step tops (tools/art_ceremony.py STEP*_Y) and the plaza
STEP1_Y = 198
STEP2_Y = 206
STEP3_Y = 210
GROUND_Y = 222
; Honest Ed's marquee round the headline: bulbs on rows 1 and 3, cols 2..29
MQ_L = 2
MQ_R = 29
BULB_TILE = 100                 ; spare BG3 tile (the countdown's, unused here)
PRESS_AT  = 240                 ; frames before PRESS A shows and A works (~4 s)
WIDE_MIN  = 5                   ; co-champions from here on share one wide top step

.segment "BSS"
fw_x:     .res NUM_FW*2
fw_y:     .res NUM_FW*2
fw_t:     .res NUM_FW*2
fw_pal:   .res NUM_FW*2
fw_next:  .res 2
cer_wait: .res 2
cer_i:    .res 2
cer_m:    .res 1
cer_k:    .res 1
cer_n:    .res 1                ; athletes on the podium (0-8)
cer_pr:   .res 1                ; PRESS A shown
cer_wide: .res 1                ; 1 = the podium is one wide gold step (a mass tie)
pod_step: .res MAX_PLAYERS      ; 0 gold step, 1 silver, 2 bronze
pod_x:    .res MAX_PLAYERS*2
pod_y:    .res MAX_PLAYERS*2

.segment "SCREENS"
.a8
.i16

; -> A = 0 rematch (same players, same events), 1 one more event, 2 new game
ceremony:
    jsl final_sort
    jsr podium_scene
    lda #$02                    ; the cursor on TITLE (which asks first)
    jsl final_table
    rtl

podium_scene:
    jsl ppu_off
    jsl set_mode1_defaults
    jsl load_text_gfx
    VLOAD VRAM_BGTILES, cer_tiles, (cer_bg1 - cer_tiles)
    VLOAD VRAM_BG1MAP, cer_bg1, 2048
    VLOAD VRAM_BG2MAP, cer_bg2, 2048
    PLOAD 32, cer_pal, 96
    VLOAD VRAM_OBJTILES, cer_spr, (cer_spr_pal - cer_spr)
    VLOAD (VRAM_TXTTILES + BULB_TILE*8), bulb_tile, 16
    jsr pod_layout              ; who stands where, in their sponsors' colours
    lda #$17
    sta tm_sh
    stz txt_bg
    ; night sky
    lda #$03
    sta $4370
    lda #<CGADD
    sta $4371
    ldx #.loword(cer_sky)
    stx $4372
    lda #^cer_sky
    sta $4374
    lda #$80
    sta hdma_sh
    ; headline in the marquee, the rest on dark strips (the towers are white)
    lda num_players
    cmp #$01
    bne @multi
    lda c_champs
    beq @nobody
    jmp @solo
@multi:
    lda c_champs
    bne @won
@nobody:
    LDPTR0 str_nobody
    jsr marquee_title
    LDPTR0 str_next_year
    ldx #(5*32)
    lda #($20 | (TP_WHITE << 2))
    jsr strip_line
    jmp @titled
@won:
    cmp #$01
    beq @one
    LDPTR0 str_cochamps
    jsr marquee_title
    jsl champ_names
    ldx #(5*32)
    lda #($20 | (TP_WHITE << 2))
    jsr strip_line
    lda #$00                    ; "TIED ON 13 PTS AND MEDALS"
    jsl why_line
    bcc @titled
    ldx #(7*32)
    lda #($20 | (TP_CYAN << 2))
    jsr strip_line
    jmp @titled
@one:
    LDPTR0 str_champ
    jsr marquee_title
    jsr champ_lines
    lda #$01                    ; why: "13 PTS TO 8", "TIED ON 13 PTS: MORE GOLD"
    jsl why_line
    bcc @titled
    ldx #(9*32)
    lda #($20 | (TP_CYAN << 2))
    jsr strip_line
    jmp @titled
@solo:
    ; going solo: no "champion" over nobody, just the haul
    LDPTR0 str_solo
    jsr marquee_title
    jsr champ_lines
    jsr haul_line
@titled:
    ; fireworks
    ldx #$0000
@clr:
    stz fw_t,x
    inx
    cpx #(NUM_FW*2)
    bne @clr
    ldx #6
    stx fw_next
    ldx #$0000
    stx cer_wait
    stz cer_pr
    jsr bulbs
    jsr draw_podium
    jsl fade_in
    lda #SONG_PODIUM
    jsl music_play
    lda c_champs
    bne @loop
    SFX SFX_GROAN               ; the Leafs-style sigh: nobody won a thing
@loop:
    jsl wait_frame
    lda cer_n
    beq @nofw
    jsr fireworks
@nofw:
    jsr draw_podium
    lda frame
    and #$03
    bne @nb
    jsr bulbs
@nb:
    A16
    inc cer_wait
    lda cer_wait
    cmp #PRESS_AT
    A8
    bcc @loop
    lda cer_pr
    bne @in
    inc cer_pr
    LDPTR0 str_press
    ldx #(11*32)
    lda #($20 | (TP_YELLOW << 2))
    jsr strip_line
@in:
    A16
    lda pad_new
    and #(PAD_A | PAD_START)
    A8
    beq @loop
    SFX SFX_SELECT
    jsl fade_out
    jsl hdma_off
    rts

str_champ:     .byte "CHAMPION OF TORONTO", 0
str_cochamps:  .byte "CO-CHAMPIONS OF TORONTO", 0
str_nobody:    .byte "NO MEDALS TODAY", 0
str_next_year: .byte "WE'LL GET 'EM NEXT YEAR", 0
str_solo:      .byte "TORONTO SALUTES YOU", 0
str_press:     .byte "PRESS A", 0

; the champion's name (row 5) and sponsor (row 7)
champ_lines:
    lda c_order
    jsl player_offset
    A16
    txa
    clc
    adc #.loword(players)
    sta ptr0
    A8
    stz ptr0+2
    ldx #(5*32)
    lda #($20 | (TP_WHITE << 2))
    jsr strip_line
    lda c_order
    jsl player_offset
    lda players+PL_SPONSOR,x
    A16
    and #$00FF
    asl a
    tax
    lda f:sponsor_names,x
    sta ptr0
    A8
    lda #^sponsor_names
    sta ptr0+2
    ldx #(7*32)
    lda #($20 | (TP_CYAN << 2))
    jsr strip_line
    rts

; solo: "[gold] 2  [silver] 1  [bronze] 0" on row 9, cols 9..22
haul_line:
    ldx #(9*32 + 9)
    A16
    lda #$010E
    sta tmp1
    A8
    lda #TXT_WIN
    sta tmp2
    lda #$20
    jsl txt_fill
    lda #TXT_WIN
    sta txt_bg
    stz cer_k
@m:
    lda cer_k
    asl a
    asl a
    A16
    and #$00FF
    clc
    adc #(9*32 + 10)            ; column 10 + k*4
    tax
    A8
    phx
    lda cer_k
    TAXB
    lda f:haul_tp,x
    pha
    lda #(TXT_MEDAL + TXT_WIN)
    sta tmp2
    pla
    plx
    jsl txt_char
    inx
    phx
    lda c_order
    jsl player_offset
    txa
    clc
    adc cer_k
    TAXB
    lda players+PL_GOLD,x
    A16
    and #$00FF
    sta tmp1
    A8
    plx
    inx
    ldy #1
    lda #($20 | (TP_WHITE << 2))
    jsl txt_num
    inc cer_k
    lda cer_k
    cmp #3
    bne @m
    stz txt_bg
    rts

; a marquee bulb on the window colour (2bpp: 1 lamp, 2 rim, 3 window)
bulb_tile:
    .byte $FF, $FF, $DB, $E7, $BD, $C3, $7E, $81, $7E, $81, $BD, $C3, $DB, $E7, $FF, $FF

haul_tp:
    .byte ($20 | (TP_YELLOW << 2)), ($20 | (TP_GREY << 2)), ($20 | (TP_ORANGE << 2))

; ptr0 = string, X = row*32, A = attr: centred on a dark strip one cell wider
; than the text each side, so it reads over the white towers
strip_line:
    sta tmp4
    stx tmp3
    ldy #$0000
@len:
    lda [ptr0],y
    beq @got
    iny
    cpy #30
    bne @len
@got:
    sty tmp1                    ; length
    A16
    lda #32
    sec
    sbc tmp1
    lsr a
    dec a                       ; first column of the strip
    clc
    adc tmp3
    tax
    lda tmp1
    clc
    adc #$0102                  ; width + 2, height 1
    sta tmp1
    A8
    lda #TXT_WIN
    sta tmp2
    lda #$20
    jsl txt_fill
    lda #TXT_WIN
    sta txt_bg
    ldx tmp3
    lda tmp4
    jsl txt_print_centre
    stz txt_bg
    rts

; the headline (ptr0) on row 2 inside the marquee
marquee_title:
    phb
    ldx #(2*32 + MQ_L + 1)
    A16
    lda #($0100 | (MQ_R - MQ_L - 1))
    sta tmp1
    A8
    lda #TXT_WIN
    sta tmp2
    lda #$20
    jsl txt_fill
    lda #TXT_WIN
    sta txt_bg
    ldx #(2*32)
    lda #($20 | (TP_YELLOW << 2))
    jsl txt_print_centre
    stz txt_bg
    plb
    rts

; Honest Ed's bulbs chase round the marquee: every third bulb lit
bulbs:
    lda frame
    lsr a
    lsr a
    sta cer_k                   ; phase
    ; top row left to right, bottom row right to left, and the two ends
    ldx #$0000                  ; bulb number
@b:
    stx cer_i
    ; cell for bulb n (n = 0..27 top, 28 right end, 29..56 bottom, 57 left end)
    cpx #28
    bcs @nt
    A16
    txa
    clc
    adc #(1*32 + MQ_L)
    bra @cell
@nt:
    cpx #28
    bne @nr
    A16
    lda #(2*32 + MQ_R)
    bra @cell
@nr:
    cpx #57
    bcs @nl
    A16
    txa
    eor #$FFFF
    clc
    adc #(3*32 + MQ_R + 29 + 1)  ; 3*32 + MQ_R - (n - 29)
    bra @cell
@nl:
    A16
    lda #(2*32 + MQ_L)
@cell:
    asl a
    tay
    A8
    lda cer_i
    clc
    adc cer_k
    sta WRDIVL
    stz WRDIVH
    lda #3
    sta WRDIVB
    lda #BULB_TILE
    sta txt_map,y
    nop
    nop
    nop
    nop
    nop
    nop
    lda RDMPYL
    bne @off
    lda #($20 | (TP_YELLOW << 2))
    bra @put
@off:
    lda #($20 | (TP_RED << 2))
@put:
    sta txt_map+1,y
    ldx cer_i
    inx
    cpx #58
    bne @b
    lda #$01
    sta txt_dirty
    rts

; ------------------------------------------------------------------
; pod_layout: everyone placed 1st-3rd who won a medal (up to all eight)
; goes on the step of their place; a solo player stands on the step of
; their best medal. Up to four share a step (two on 2nd / 3rd); a bigger
; crowd spills along the podium and onto the square. Palettes: slot = order.
pod_layout:
    stz cer_n
    stz cer_wide
    lda c_champs
    bne @any
    rts
@any:
    ; five or more co-champions: one wide gold step instead of 1-2-3, so
    ; nobody who tied for first stands on a 2 or a 3 (or on the pavement)
    cmp #WIDE_MIN
    bcc @steps
    lda num_players
    cmp #$02
    bcc @steps
    inc cer_wide
    VLOAD (VRAM_BG1MAP + 24*32), cer_wide_rows, (4*64)
@steps:
    stz cer_i
@who:
    lda cer_i
    cmp num_players
    bcs @placed
    TAXB
    lda c_order,x
    jsl player_offset
    A16
    lda players+PL_POINTS,x
    A8
    beq @placed
    lda num_players
    cmp #$01
    bne @rank
    ; solo: best medal
    lda players+PL_GOLD,x
    bne @s0
    lda players+PL_SILVER,x
    bne @s1
    lda #$02
    bra @st
@s1:
    lda #$01
    bra @st
@s0:
    lda #$00
    bra @st
@rank:
    lda cer_i
    TAXB
    lda c_place,x
    cmp #3
    bcs @placed
@st:
    pha
    lda cer_i
    TAXB
    pla
    sta pod_step,x
    lda c_order,x
    ldy cer_i
    jsl player_palette
    inc cer_n
    inc cer_i
    bra @who
@placed:
    ; positions
    stz cer_i
@pos:
    lda cer_i
    cmp cer_n
    bcc @p1
    rts
@p1:
    ; m = athletes on this step, k = this one's index among them
    TAXB
    lda pod_step,x
    sta tmp3                    ; step
    stz cer_m
    stz cer_k
    ldx #$0000
@cnt:
    txa
    cmp cer_n
    bcs @counted
    lda pod_step,x
    cmp tmp3
    bne @cn
    inc cer_m
    txa
    cmp cer_i
    bcs @cn
    inc cer_k
@cn:
    inx
    bra @cnt
@counted:
    lda tmp3
    beq @gold
    ; 2nd / 3rd: two fit on the step, more fan out away from the middle
    lda cer_m
    cmp #3
    bcs @fan
    jsr table_dx
    lda tmp3
    asl a
    TAXB
    A16
    lda f:step_x,x
    clc
    adc tmp0
    pha
    lda f:step_y,x
    jmp @set
@fan:
    A16
    lda cer_k
    and #$00FF
    asl a
    asl a
    asl a
    asl a                       ; k*16
    sta tmp0
    A8
    lda tmp3
    cmp #$01
    A16
    bne @right
    lda #104
    sec
    sbc tmp0
    jmp @surf
@right:
    lda #152
    clc
    adc tmp0
    bra @surf
@gold:
    .a8
    lda cer_wide
    bne @wide
    lda cer_m
    cmp #5
    bcs @crowd
    jsr table_dx
    A16
    lda #128
    clc
    adc tmp0
    pha
    lda #STEP1_Y
    bra @set
@wide:
    .a8
    ; x = wide_x0[m] + k * wide_sp[m], all on the wide top step
    lda cer_m
    sec
    sbc #WIDE_MIN
    TAXB
    lda f:wide_x0,x
    sta tmp0
    stz tmp0+1
    lda f:wide_sp,x
    sta tmp1
    ldx #$0000
@wk:
    txa
    cmp cer_k
    beq @wset
    lda tmp0
    clc
    adc tmp1
    sta tmp0
    inx
    bra @wk
@wset:
    A16
    lda tmp0
    pha
    lda #STEP1_Y
    jmp @set
@crowd:
    ; x = 128 - 8(m-1) + 16k, standing on whatever is under them
    A16
    lda cer_m
    and #$00FF
    dec a
    asl a
    asl a
    asl a
    eor #$FFFF
    inc a
    clc
    adc #128
    sta tmp0
    lda cer_k
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    clc
    adc tmp0
@surf:
    pha
    jsr surface_y
@set:
    .a16
    sta tmp0
    lda cer_i
    and #$00FF
    asl a
    tax
    lda tmp0
    sta pod_y,x
    pla
    sta pod_x,x
    A8
    inc cer_i
    jmp @pos

; A16 = x -> A16 = y of the top of whatever is under it
.a16
surface_y:
    cmp #80
    bcc @g
    cmp #112
    bcc @s2
    cmp #144
    bcc @s1
    cmp #176
    bcc @s3
@g:
    lda #GROUND_Y
    rts
@s1:
    lda #STEP1_Y
    rts
@s2:
    lda #STEP2_Y
    rts
@s3:
    lda #STEP3_Y
    rts
.a8

; tmp0 = podium_dx[m-1][k] (signed word)
table_dx:
    lda cer_m
    dec a
    asl a
    asl a
    clc
    adc cer_k
    asl a
    TAXB
    A16
    lda f:podium_dx,x
    sta tmp0
    A8
    rts

; the wide step (80..176): m = 5..8 co-champions
wide_x0: .byte 96, 88, 86, 86
wide_sp: .byte 16, 16, 14, 12
; BG1 rows 24-27 of the one-wide-step podium (tools/art_ceremony.py)
cer_wide_rows: .incbin "cer_bg1w.bin", 24*64, 4*64

step_x: .word 128, 96, 160
step_y: .word STEP1_Y, STEP2_Y, STEP3_Y
; x offset for the k-th of m athletes sharing a step: [m-1][k]
podium_dx: .word 0, 0, 0, 0
           .word $FFF8, 8, 0, 0
           .word $FFF4, 0, 12, 0
           .word $FFEE, $FFFA, 6, 18

; athletes waving, each with their medal on the chest; then the fireworks
draw_podium:
    jsl oam_clear
    stz cer_i
@p:
    lda cer_i
    cmp cer_n
    bcc @in
    jmp draw_fireworks
@in:
    asl a
    TAXB
    A16
    lda pod_x,x
    sta spr_x
    lda pod_y,x
    sta spr_y
    A8
    ; champions jump for joy
    lda cer_i
    TAXB
    lda pod_step,x
    sta tmp3
    bne @still
    lda frame
    clc
    adc cer_i
    and #$10
    beq @still
    A16
    lda spr_y
    sec
    sbc #3
    sta spr_y
    A8
@still:
    ; palette slot = order, priority 3 (in front of the podium)
    lda cer_i
    asl a
    ora #$30
    sta tmp5
    stz tmp5+1
    ; the medal first (lower OAM index = in front)
    A16
    lda spr_y
    pha
    sec
    sbc #14                     ; hangs to the belt: reads on any jersey
    sta spr_y
    A8
    lda tmp3
    asl a
    TAXB
    A16
    lda f:medal_meta,x
    sta ptr1
    lda f:medal_base,x
    sta tmp6
    A8
    lda #^ms_medal_g
    sta ptr1+2
    jsl oam_meta
    A16
    pla
    sta spr_y
    A8
    lda frame
    clc
    adc cer_i
    adc cer_i
    and #$08
    beq @v
    LDPTR1 ms_wave
    ldx #MS_WAVE_BASE
    bra @go
@v:
    LDPTR1 ms_victory
    ldx #MS_VICTORY_BASE
@go:
    stx tmp6
    jsl oam_meta
    inc cer_i
    jmp @p

medal_meta: .addr ms_medal_g, ms_medal_s, ms_medal_b
medal_base: .word MS_MEDAL_G_BASE, MS_MEDAL_S_BASE, MS_MEDAL_B_BASE

; launch, burst, fade: each firework in one of the podium athletes' colours
fireworks:
    A16
    dec fw_next
    A8
    jne @age
    lda #18
    jsl rand_range
    clc
    adc #8
    sta fw_next
    stz fw_next+1
    ; find a free burst
    ldx #$0000
@f:
    lda fw_t,x
    beq @new
    inx
    inx
    cpx #(NUM_FW*2)
    bne @f
    bra @age
@new:
    stx cer_i
    ; only where there is sky to see it: left of City Hall, the gap between
    ; the towers, right of it (a burst over a tower would sit on its roof)
    lda #3
    jsl rand_range
    TAXB
    lda f:fw_zx,x
    sta tmp0
    lda f:fw_zw,x
    jsl rand_range
    clc
    adc tmp0
    ldx cer_i
    sta fw_x,x
    stz fw_x+1,x
    lda #91                     ; y 40..130: above the arches
    jsl rand_range
    clc
    adc #40
    ldx cer_i
    sta fw_y,x
    stz fw_y+1,x
    ; and never over the marquee or a banner: try again in a moment
    jsr fw_clear
    bcc @launch
    lda #2
    sta fw_next
    bra @age
@launch:
    ldx cer_i
    lda #FW_LIFE
    sta fw_t,x
    lda cer_n
    jsl rand_range
    asl a
    ora #$10                    ; priority 1: behind the towers (BG2)
    ldx cer_i
    sta fw_pal,x
    SFX SFX_SPLASH
@age:
    ldx #$0000
@a:
    lda fw_t,x
    beq @n
    dec fw_t,x
@n:
    inx
    inx
    cpx #(NUM_FW*2)
    bne @a
    rts

; firework zones: first x, how many x (a burst is 32 x 32 round x, y)
fw_zx: .byte 14, 114, 238
fw_zw: .byte 11, 29, 8

; carry set = burst cer_i (fw_x, fw_y) would touch text: the marquee, a
; banner, or where PRESS A will go (cells x-16..x+15, y-16..y+21: the
; sparkle drifts down)
fw_clear:
    ldx cer_i
    A16
    lda fw_y,x
    sec
    sbc #16
    lsr a
    lsr a
    lsr a
    sta tmp1                    ; first row
    sta tmp6
    lda fw_y,x
    clc
    adc #21
    lsr a
    lsr a
    lsr a
    sta tmp2                    ; last row
    lda fw_x,x
    sec
    sbc #16
    bpl @l0
    lda #$0000
@l0:
    lsr a
    lsr a
    lsr a
    sta tmp3                    ; first column
    lda fw_x,x
    clc
    adc #15
    lsr a
    lsr a
    lsr a
    cmp #32
    bcc @r0
    lda #31
@r0:
    sta tmp4                    ; last column
@row:
    lda tmp1
    asl a
    asl a
    asl a
    asl a
    asl a
    clc
    adc tmp3
    asl a
    tax
    lda tmp3
    sta tmp5
@col:
    lda txt_map,x
    bne @hit
    inx
    inx
    lda tmp5
    inc a
    sta tmp5
    cmp tmp4
    bcc @col
    beq @col
    lda tmp1
    inc a
    sta tmp1
    cmp tmp2
    bcc @row
    beq @row
    ; PRESS A's strip (row 11, columns 11-20) before it shows
    lda tmp6
    cmp #12
    bcs @ok
    lda tmp2
    cmp #11
    bcc @ok
    lda tmp3
    cmp #21
    bcs @ok
    lda tmp4
    cmp #11
    bcs @hit
@ok:
    A8
    clc
    rts
@hit:
    A8
    sec
    rts

draw_fireworks:
    ldx #$0000
@d:
    lda fw_t,x
    bne @live
    jmp @n
@live:
    stx cer_i
    A16
    lda fw_x,x
    sta spr_x
    lda fw_y,x
    sta spr_y
    A8
    lda fw_pal,x
    sta tmp5
    stz tmp5+1
    ; by age: 56..48 rocket, 47..38 small, 37..20 big burst, 19..1 sparkle
    lda fw_t,x
    cmp #48
    bcc @f1
    ; rocket rising
    sec
    sbc #48
    asl a
    asl a
    asl a
    A16
    and #$00FF
    clc
    adc spr_y
    sta spr_y
    A8
    LDPTR1 ms_rocket
    ldx #MS_ROCKET_BASE
    bra @go
@f1:
    cmp #38
    bcc @f2
    LDPTR1 ms_fw1
    ldx #MS_FW1_BASE
    bra @go
@f2:
    cmp #20
    bcc @f3
    LDPTR1 ms_fw2
    ldx #MS_FW2_BASE
    bra @go
@f3:
    ; the sparkle drifts down as it fades
    eor #$FF
    clc
    adc #20
    lsr a
    lsr a
    A16
    and #$00FF
    clc
    adc spr_y
    sta spr_y
    A8
    LDPTR1 ms_fw3
    ldx #MS_FW3_BASE
@go:
    stx tmp6
    jsl oam_meta
    ldx cer_i
@n:
    inx
    inx
    cpx #(NUM_FW*2)
    beq @x
    jmp @d
@x:
    rts

.include "cer_meta.inc"
