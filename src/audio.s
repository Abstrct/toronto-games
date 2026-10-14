; Sound. The SPC700 runs a tiny driver that only writes DSP registers the
; CPU hands it through the APU ports; the music sequencer and sound effects
; run here on the 65816 once a frame.
;   voices 0-3: music (lead, harmony, bass, drums)   4-6: effects   7: noise effects
; Uses its own zero-page scratch so game code's tmp0-tmp7 survive.
.p816
.smart -
.include "globals.inc"

.import spc_blob, spc_blob_end, pitch_table, music_data, song_table, instruments
.export sfx_result

SONG_JINGLE = 11            ; songs 11-13: the result jingles (tools/songs.py)

.segment "ZEROPAGE"
a0:         .res 2
a1:         .res 2
a2:         .res 2
a3:         .res 2      ; lo = voice, hi = voice*16
a4:         .res 2      ; srcn, adsr1
a5:         .res 2      ; adsr2, volume
a6:         .res 2      ; lo = slot / id
aptr:       .res 3

.segment "BSS"
apu_cnt:    .res 1
apu_ok:     .res 1
non_sh:     .res 1
kon_mask:   .res 1
kof_mask:   .res 1
mus_song:   .res 2
mus_id:     .res 1      ; song playing (valid while music_on)
pan_v:      .res 2      ; voice_setup: volume / 4, volume
mus_len:    .res 2
mus_loop:   .res 2
mus_step:   .res 2
mus_chofs:  .res 8      ; music_data offset of each channel's steps
mus_tempo:  .res 2      ; frames per even step, per odd step
mus_wait:   .res 1
sfx_next:   .res 1
sfx_id:     .res 4
sfx_t:      .res 4
sfx_pitch:  .res 8
mus_inst:   .res 4      ; each music voice's instrument (put back after a fade)
mus_faded:  .res 1      ; music_stop faded the music voices out (GAIN mode)
mus_mv:     .res 1      ; master volume now (climbs to mus_mvt: the podium swell)
mus_mvt:    .res 1      ; the song's master volume (song_mvol)

.segment "CODE"
.a8
.i16

DSP_KON = $4C
DSP_KOF = $5C
DSP_FLG = $6C
DSP_NON = $3D

spc_driver:
    .byte $E4,$F4, $C4,$00                  ; mov a,$F4 / mov $00,a
    .byte $E4,$F4, $64,$00, $F0,$FA         ; loop: mov a,$F4 / cmp a,$00 / beq loop
    .byte $C4,$00                           ; mov $00,a
    .byte $FA,$F5,$F2, $FA,$F6,$F3          ; DSP[port1] = port2
    .byte $C4,$F4, $2F,$EE                  ; echo port0, bra loop
spc_driver_end:

; ------------------------------------------------------------------
audio_init:
    stz apu_ok
    stz music_on
    stz sfx_next
    lda #$FF
    sta sfx_id
    sta sfx_id+1
    sta sfx_id+2
    sta sfx_id+3
    ldy #$0000
@ipl:
    ldx APUIO0
    cpx #$BBAA
    beq @ready
    dey
    bne @ipl
    rtl                     ; no APU answering: stay silent
@ready:
    ldx #$0200
    stx APUIO2
    lda #$01
    sta APUIO1
    lda #$CC
    sta APUIO0
@w0:
    cmp APUIO0
    bne @w0
    A16
    lda #.loword(spc_driver)
    sta aptr
    A8
    lda #^spc_driver
    sta aptr+2
    ldx #(spc_driver_end - spc_driver)
    stx a1
    jsr upload_bytes

    ldx #$3000
    stx APUIO2
    lda #$01
    sta APUIO1
    jsr kick
    A16
    lda #.loword(spc_blob)
    sta aptr
    A8
    lda #^spc_blob
    sta aptr+2
    ldx #.loword(spc_blob_end - spc_blob)
    stx a1
    jsr upload_bytes

    ldx #$0200
    stx APUIO2
    stz APUIO1
    jsr kick
    sta apu_cnt
    lda #$01
    sta apu_ok

    ldx #$6D                ; ESA: echo buffer at $E000
    lda #$E0
    jsr dsp_write
    ldx #$7D                ; EDL: 2 x 2 KB = 4 KB of echo, 32 ms
    lda #$02
    jsr dsp_write
    ldx #$0D                ; EFB: no feedback yet
    lda #$00
    jsr dsp_write
    ldx #$0F                ; FIR C0-C3: a gentle low-pass, C4-C7 zero
    lda #$58
    jsr dsp_write
    ldx #$1F
    lda #$20
    jsr dsp_write
    ldx #$2F
    lda #$10
    jsr dsp_write
    ldx #$3F
    lda #$08
    jsr dsp_write
    lda #$00
    ldx #$4F
    jsr dsp_write
    ldx #$5F
    jsr dsp_write
    ldx #$6F
    jsr dsp_write
    ldx #$7F
    jsr dsp_write
    ldx #DSP_FLG
    lda #$00                ; echo writes on, not muted
    jsr dsp_write
    ldx #$0C
    lda #$7F                ; master volume full: voice volumes leave mix headroom
    jsr dsp_write
    ldx #$1C
    jsr dsp_write
    lda #$00
    ldx #$2C
    jsr dsp_write
    ldx #$3C
    jsr dsp_write
    ldx #$2D
    jsr dsp_write
    ldx #DSP_NON
    jsr dsp_write
    stz non_sh
    ldx #$4D
    jsr dsp_write
    ldx #DSP_KOF
    jsr dsp_write
    ldx #$5D
    lda #$30                ; sample directory page $30 -> $3000
    jsr dsp_write
    rtl

; a1 = byte count, aptr = source; port counter runs 0,1,2...
upload_bytes:
    ldy #$0000
@l:
    lda [aptr],y
    sta APUIO1
    tya
    sta APUIO0
@w:
    cmp APUIO0
    bne @w
    iny
    cpy a1
    bne @l
    dey
    tya
    sta a2
    rts

; next-block / execute kick: last index + 2, never 0. Returns A = kick value.
kick:
    lda a2
    clc
    adc #$02
    bne @nz
    lda #$01
@nz:
    sta APUIO0
@w:
    cmp APUIO0
    bne @w
    rts

; dsp_write: X low byte = DSP register, A = value. Keeps A, X, Y.
dsp_write:
    pha
    sta APUIO2
    txa
    sta APUIO1
    inc apu_cnt
    lda apu_cnt
    sta APUIO0
    phy
    ldy #$0800
@w:
    cmp APUIO0
    beq @ok
    dey
    bne @w
@ok:
    ply
    pla
    rts

; voice_pitch: A = voice, a0 = pitch word
voice_pitch:
    asl a
    asl a
    asl a
    asl a
    ora #$02
    tax
    lda a0
    jsr dsp_write
    inx
    lda a0+1
    jsr dsp_write
    rts

; voice_setup: a3 lo = voice; a4/a5 = srcn adsr1 adsr2 volume
voice_setup:
    lda a3
    asl a
    asl a
    asl a
    asl a
    sta a3+1
    tax
    lda a5+1
    sta pan_v+1
    lsr a
    sta pan_v                ; pan_v lo = volume / 2
    lda a3
    cmp #$01
    beq @right
    lda a5+1
    jsr dsp_write           ; vol L
    inx
    lda a3
    bne @centre
    lda pan_v+1                ; voice 0 (lead): R = 1/2
    sec
    sbc pan_v
    bra @r
@right:
    lda pan_v+1                ; voice 1 (harmony): L = 1/2
    sec
    sbc pan_v
    jsr dsp_write
    inx
    lda pan_v+1
    bra @r
@centre:
    lda pan_v+1
@r:
    jsr dsp_write           ; vol R
    lda a3+1
    ora #$04
    tax
    lda a4
    jsr dsp_write           ; srcn
    inx
    lda a4+1
    jsr dsp_write           ; adsr1
    inx
    lda a5
    jsr dsp_write           ; adsr2
    rts

; ------------------------------------------------------------------
; music_play: A = song id
; Song: tempo even, tempo odd, length.w, loop step.w, 4 instrument ids,
; then 4 channels x length steps.
music_play:
    phx
    phy
    pha
    lda apu_ok
    bne @go
    pla
    ply
    plx
    rtl
@go:
    pla
    sta mus_id
    jsr echo_on
    ; per-song master volume: evens out loudness and leaves headroom for effects
    lda mus_id
    A16
    and #$00FF
    tax
    A8
    lda f:song_mvol,x
    sta mus_mvt
    lda f:song_swell,x      ; a swell starts lower and climbs a step a frame
    bne @mv
    lda mus_mvt
@mv:
    sta mus_mv
    jsr set_mvol
    lda mus_id
    A16
    and #$00FF
    asl a
    tax
    lda f:song_table,x
    sta mus_song
    tax
    lda f:music_data,x
    sta mus_tempo
    lda f:music_data+2,x
    sta mus_len
    lda f:music_data+4,x
    sta mus_loop
    txa
    clc
    adc #10
    sta mus_chofs
    clc
    adc mus_len
    sta mus_chofs+2
    clc
    adc mus_len
    sta mus_chofs+4
    clc
    adc mus_len
    sta mus_chofs+6
    A8
    ldx #DSP_KOF
    lda #$0F
    jsr dsp_write
    stz a3
@inst:
    A16
    lda a3
    and #$00FF
    clc
    adc mus_song
    tax
    A8
    lda f:music_data+6,x
    jsr load_inst
    inc a3
    lda a3
    cmp #$04
    bne @inst
    stz mus_faded           ; load_inst put every voice back on its ADSR
    lda non_sh
    and #$F7
    sta non_sh
    ldx #DSP_NON
    jsr dsp_write
    stz mus_step
    stz mus_step+1
    lda #$01
    sta mus_wait
    sta music_on
    ply
    plx
    rtl

; load_inst: A = instrument id, a3 lo = voice (0-3)
; set_mvol: master volume L and R = A
set_mvol:
    ldx #$0C                ; MVOL L
    jsr dsp_write
    ldx #$1C                ; MVOL R
    jmp dsp_write

load_inst:
    pha
    lda a3
    TAXB
    pla
    sta mus_inst,x
    A16
    and #$00FF
    asl a
    asl a
    tax
    lda f:instruments,x
    sta a4
    lda f:instruments+2,x
    sta a5
    A8
    jmp voice_setup

; music_keep: like music_play, but leaves song A running if it already is
music_keep:
    pha
    lda music_on
    beq @play
    pla
    cmp mus_id
    bne @p2
    rtl
@play:
    pla
@p2:
    jml music_play

; music_stop: the music fades out over about 130 ms (a key-off drops in 8 ms,
; which steps on real speakers). Sound effects carry on.
music_stop:
    phx
    stz music_on
    lda apu_ok
    beq @x
    jsr mus_fade
@x:
    plx
    rtl

; mus_fade: voices 0-3 leave their ADSR for GAIN "linear decrease", rate 16
; (-32 every 64 samples: full scale to silence in 128 ms), from wherever each
; envelope is. GAIN goes first so the switch never sees a stale direct gain.
mus_fade:
    lda #$01
    sta mus_faded
    ldx #$0007              ; voice 0 GAIN
@v:
    lda #$90
    jsr dsp_write
    dex
    dex                     ; ADSR1
    lda #$00                ; bit 7 clear: the envelope follows GAIN
    jsr dsp_write
    A16
    txa
    clc
    adc #$0012              ; the next voice's GAIN
    tax
    A8
    cpx #$0047
    bne @v
    rts

; mus_reinst: after a fade, music_on came back on (the pause menu resumes the
; song where it stopped): every music voice gets its instrument, so its ADSR, back
mus_reinst:
    stz mus_faded
    stz a3
@l:
    lda a3
    TAXB
    lda mus_inst,x
    jsr load_inst
    inc a3
    lda a3
    cmp #$04
    bne @l
    rts

; ------------------------------------------------------------------
; sfx_result: the result card's jingle, under two seconds, on the music voices
; (it replaces whatever song is on; the card is otherwise silent), then it
; fades out by itself.  A = 0 finished, 1 failed, 2 new record (anything
; else plays the finish). Keeps X and Y.
sfx_result:
    cmp #$03
    bcc @ok
    lda #$00
@ok:
    clc
    adc #SONG_JINGLE
    jml music_play

; ------------------------------------------------------------------
audio_tick:
    lda apu_ok
    bne @on
    rtl
@on:
    phx
    phy
    stz kon_mask
    stz kof_mask
    lda music_on
    beq @sfx
    lda mus_faded
    beq @swell
    jsr mus_reinst
@swell:
    lda mus_mv
    cmp mus_mvt
    bcs @run
    inc a
    sta mus_mv
    jsr set_mvol
@run:
    dec mus_wait
    bne @sfx
    jsr music_step
    lda mus_step            ; next step odd = this one was even
    lsr a
    lda mus_tempo
    bcs @wait
    lda mus_tempo+1
@wait:
    sta mus_wait
@sfx:
    jsr sfx_update
    lda kof_mask
    ldx #DSP_KOF
    jsr dsp_write           ; also clears last frame's key-offs
    lda kon_mask
    beq @done
    ldx #DSP_KON
    jsr dsp_write
@done:
    ply
    plx
    rtl

music_step:
    stz a3
@ch:
    A16
    lda a3
    and #$00FF
    asl a
    tax
    lda mus_chofs,x
    clc
    adc mus_step
    tax
    A8
    lda f:music_data,x
    beq @next               ; hold
    cmp #$01
    bne @not_off
    lda a3
    TAXB
    lda f:voice_bit,x
    ora kof_mask
    sta kof_mask
    bra @next
@not_off:
    cmp #$90
    bcc @not_inst
    and #$0F                ; $90+n: switch to instrument n
    jsr load_inst
    bra @next
@not_inst:
    cmp #$80
    bcs @drum
    sec
    sbc #$02
    A16
    and #$00FF
    asl a
    tax
    lda f:pitch_table,x
    sta a0
    A8
    lda a3
    jsr voice_pitch
    bra @kon
@drum:
    jsr drum_hit
@kon:
    lda a3
    TAXB
    lda f:voice_bit,x
    ora kon_mask
    sta kon_mask
@next:
    inc a3
    lda a3
    cmp #$04
    jne @ch
    A16
    inc mus_step
    lda mus_step
    cmp mus_len
    bcc @x
    lda mus_loop
    cmp #$FFFF
    beq @end                ; a jingle: no loop
    sta mus_step
@x:
    A8
    rts
@end:
    A8
    stz music_on
    jmp mus_fade

; A = $80.. drum id (voice 3): kick, snare, hat, open hat, crash, low tom, high tom, rim
drum_hit:
    sec
    sbc #$80
    asl a
    asl a
    TAXB
    lda f:drum_tab+3,x
    sta a2
    lda f:drum_tab+2,x
    sta a1+1
    lda f:drum_tab+1,x
    sta a1
    lda f:drum_tab,x
    cmp #$FF
    beq @noise
    pha
    lda non_sh
    and #$F7
    sta non_sh
    ldx #DSP_NON
    jsr dsp_write
    pla
    ldx #$34
    jsr dsp_write           ; drum sample
    stz a0
    lda a1
    sta a0+1
    lda #$03
    jsr voice_pitch
    bra @env
@noise:
    lda non_sh
    ora #$08
    sta non_sh
    ldx #DSP_NON
    jsr dsp_write
    lda a1
    and #$1F                ; noise clock only: keep echo writes on (bit 5 clear)
    ldx #DSP_FLG
    jsr dsp_write           ; noise clock
@env:
    lda a1+1
    ldx #$36
    jsr dsp_write           ; adsr2 sets the decay
    lda a2
    ldx #$30
    jsr dsp_write
    inx
    jsr dsp_write           ; volume
    rts

; srcn ($FF = noise), pitch hi / FLG, adsr2, volume
drum_tab:
    .byte $05, $10, $E0, $36    ; $80 kick
    .byte $FF, $3C, $14, $33    ; $81 snare
    .byte $FF, $3F, $1C, $24    ; $82 hat
    .byte $FF, $3E, $38, $24    ; $83 open hat
    .byte $FF, $3D, $4E, $2D    ; $84 crash
    .byte $08, $0E, $E0, $3C    ; $85 low tom
    .byte $08, $15, $E0, $38    ; $86 high tom
    .byte $08, $34, $E0, $2A    ; $87 rim click

voice_bit:
    .byte $01,$02,$04,$08,$10,$20,$40,$80

; ------------------------------------------------------------------
; sfx_play: A = effect id. Keeps X, Y and the game's tmp registers.
sfx_play:
    phx
    phy
    pha
    lda apu_ok
    bne @go
    pla
    ply
    plx
    rtl
@go:
    pla
    sta a6
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    tax
    A8
    lda f:sfx_table+12,x
    beq @tonal
    lda #$03
    bra @have
@tonal:
    lda sfx_next
    inc a
    cmp #$03
    bcc @ok
    lda #$00
@ok:
    sta sfx_next
@have:
    sta a6+1                ; slot 0-3
    TAYB
    lda a6
    sta sfx_id,y
    lda #$00
    sta sfx_t,y
    lda a6+1
    clc
    adc #$04
    sta a3                  ; voice
    A16
    lda f:sfx_table,x
    sta a4
    lda f:sfx_table+2,x
    sta a5
    lda f:sfx_table+4,x
    sta a0
    A8
    phx
    jsr voice_setup
    plx
    lda f:sfx_table+12,x
    beq @tone
    and #$1F                ; noise clock; echo writes stay on
    ldx #DSP_FLG
    jsr dsp_write
    lda non_sh
    ora #$80
    sta non_sh
    ldx #DSP_NON
    jsr dsp_write
@tone:
    lda a6+1
    asl a
    TAYB
    A16
    lda a0
    sta sfx_pitch,y
    A8
    lda a3
    jsr voice_pitch
    lda a3
    TAXB
    lda f:voice_bit,x
    ldx #DSP_KON
    jsr dsp_write
    ply
    plx
    rtl

sfx_update:
    stz a6
@slot:
    lda a6
    TAYB
    lda sfx_id,y
    cmp #$FF
    jeq @next
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    tax
    A8
    lda sfx_t,y
    inc a
    sta sfx_t,y
    cmp f:sfx_table+9,x
    bcc @alive
    lda #$FF
    sta sfx_id,y
    lda a6
    TAXB
    lda f:voice_bit+4,x
    ora kof_mask
    sta kof_mask
    bra @next
@alive:
    sta a2                  ; this effect's frame
    lda f:sfx_table+13,x
    and #$7F
    beq @two
    cmp a2
    beq @third
@two:
    lda a2
    cmp f:sfx_table+8,x
    bne @slide
    jsr sfx_rekey
    A16
    lda f:sfx_table+6,x
    bra @store
@third:
    jsr sfx_rekey
    A16
    lda f:sfx_table+14,x
    bra @store
@slide:
    A16
    lda a6
    and #$00FF
    asl a
    tay
    lda sfx_pitch,y
    clc
    adc f:sfx_table+10,x
@store:
    sta a0
    lda a6
    and #$00FF
    asl a
    tay
    lda a0
    sta sfx_pitch,y
    A8
    lda a6
    clc
    adc #$04
    jsr voice_pitch
@next:
    inc a6
    lda a6
    cmp #$04
    jne @slot
    rts

; sfx_rekey: a chime's next note strikes again (the row's fsw2 bit 7):
; the effect's voice keys on this frame. X = the row, a6 = the slot.
sfx_rekey:
    lda f:sfx_table+13,x
    bpl @x
    phx
    lda a6
    TAXB
    lda f:voice_bit+4,x
    ora kon_mask
    sta kon_mask
    plx
@x:
    rts

; effect table: 16-byte rows ----------------------------------------
; source, ADSR1, ADSR2, volume, pitch 1, pitch 2 from frame fsw, length in
; frames, pitch slide per frame, noise clock (0 = tone), then optionally a
; third pitch from frame fsw2 (bit 7 of fsw2: key on again at fsw and fsw2,
; so each pitch is a new strike)
.macro FX fsrc, fad1, fad2, fvol, fp1, fp2, fsw, flen, fsl, fnz, fsw2, fp3
    .byte fsrc, fad1, fad2, fvol
    .word fp1, fp2
    .byte fsw, flen
    .word (fsl) & $FFFF
    .byte fnz
    .ifblank fsw2
    .byte 0
    .word 0
    .else
    .byte fsw2
    .word fp3
    .endif
.endmacro

sfx_table:
    FX 1, $FF, $E0, $3C, 5401, 5401,  0,  3,    0,  0   ; 0 blip
    FX 1, $FF, $E0, $43, 4286, 6423,  4,  9,    0,  0   ; 1 select
    FX 1, $FF, $E0, $3C, 3211, 2143,  3,  7,    0,  0   ; 2 back
    FX 0, $FF, $E0, $3C, 2143, 2143,  0, 10,   90,  0   ; 3 jump
    FX 0, $FF, $16, $60, 1000, 1000,  0, 30,    0, $10  ; 4 crash
    FX 1, $FF, $E0, $3C, 4046, 5401,  3, 12,    0,  0   ; 5 coin
    FX 2, $FF, $E0, $36, 7209, 6800,  6, 24,    0,  0   ; 6 whistle
    FX 4, $FF, $E0, $49,  536,  715, 10, 22,    0,  0   ; 7 horn
    FX 0, $FF, $E0, $49, 1802, 1802,  0,  8,  -90,  0   ; 8 bark
    FX 0, $FF, $14, $49, 1000, 1000,  0, 18,    0, $18  ; 9 splash
    FX 3, $FF, $F2, $49, 8573, 8573,  0, 20,    0,  0   ; 10 bell
    FX 1, $FF, $E0, $43, 3604, 3604,  0, 16,    0,  0   ; 11 go
    FX 1, $FF, $E0, $3C, 1802, 1802,  0, 10,    0,  0   ; 12 ready
    FX 0, $FF, $1F, $24, 1000, 1000,  0,  2,    0, $1E  ; 13 step
    FX 3, $FF, $E0, $49, 2700, 2700,  0,  7,  -60,  0   ; 14 sip
    FX 0, $FF, $10, $30, 1000, 1000,  0, 40,    0, $14  ; 15 cheer
    FX 2, $FF, $E0, $30, 8573, 8573,  0,  2,    0,  0   ; 16 tick
    FX 4, $FF, $E0, $49, 1430, 1350,  8, 48,  -14,  0   ; 17 groan (wah-wah, sliding down)
    ; 18 chime: the TTC's three-note "please stand clear of the doors", E6 C6 G5
    FX 3, $FF, $6E, $55, 5401, 4286, 14, 60,    0,  0, $80 | 28, 3211
    ; 19 ferry: the Island ferry's deep horn, a low swoop up into a long blast
    FX 4, $FA, $E9, $55,  380,  420,  6, 80,    0,  0
    ; 20 firework: a low boom for the podium bursts, softer than the splash so
    ; the podium reprise can sit above the events without the bursts clipping
    FX 0, $FF, $15, $30, 1000, 1000,  0, 24,    0, $12
sfx_table_end:
.assert sfx_table_end - sfx_table = 21 * 16, error, "sfx_table rows must be 16 bytes"

; echo_on: first song turns the echo up (lead + harmony only)
echo_on:
    lda apu_ok
    beq @x
    ldx #$2C                ; EVOL L
    lda #$24
    jsr dsp_write
    ldx #$3C                ; EVOL R
    jsr dsp_write
    ldx #$0D                ; EFB
    lda #$38
    jsr dsp_write
    ldx #$4D                ; EON: voices 0 and 1
    lda #$03
    jsr dsp_write
@x:
    rts

; master volume per song (SONG_* order). $7F is full scale; the event songs
; sit under it (-16 to -18 dBFS AC RMS) so stacked sound effects don't clip.
; The podium reprise is the one song above the events (about -16 dBFS with
; the fireworks on top; peaks 0.5 dB under clipping with SFX_SPLASH bursts,
; 1.2 dB with SFX_FIREWORK ones) and swells into it.
song_mvol:
    .byte $6C   ; 0 title       KC Incidental
    .byte $70   ; 1 menu        Bobcaygeese
    .byte $6C   ; 2 bike        Gold Guns Gulls
    .byte $70   ; 3 standings   Ahead by a Centimetre
    .byte $64   ; 4 bay         Whelp, I'm Alive
    .byte $78   ; 5 tallboy     Hay, Officer
    .byte $6A   ; 6 regatta     Brother Downwind (the start horn rides on top)
    .byte $70   ; 7 off-leash   If I Had a Million Collars
    .byte $76   ; 8 podium      Podium Reprise: a lift over the events (see below)
    .byte $6C   ; 9 parking     Green P Shuffle
    .byte $6A   ; 10 subway     Please Stand Clear
    .byte $7A   ; 11 jingle     finished
    .byte $7A   ; 12 jingle     failed
    .byte $7A   ; 13 jingle     new record
song_mvol_end:
.assert song_mvol_end - song_mvol = SONG_JINGLE + 3, error, "song_mvol: one per song"

; where a song's master volume starts (0 = at song_mvol): the podium fanfare
; climbs $3F -> $76 a step a frame, a one-second swell out of its snare roll
song_swell:
    .byte 0, 0, 0, 0, 0, 0, 0, 0
    .byte $3F   ; 8 podium
    .byte 0, 0, 0, 0, 0
.assert * - song_swell = SONG_JINGLE + 3, error, "song_swell: one per song"
