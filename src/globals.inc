; Shared symbols. Every source file includes this; ca65 turns each .global
; into an export where it is defined and an import everywhere else.

.include "regs.inc"
.include "macros.inc"

; ---------- zero page ----------
.globalzp tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7
.globalzp ptr0, ptr1, ptr2
.globalzp frame, nmi_ready, lag
.globalzp pad, pad_prev, pad_new, pad1, pad2
.globalzp rng
.globalzp inidisp_sh, tm_sh, ts_sh, hdma_sh, cgwsel_sh, cgadsub_sh, mosaic_sh
.globalzp bg1x, bg1y, bg2x, bg2y, bg3x, bg3y
.globalzp txt_dirty, pal_dirty, dmaq_len
.globalzp oam_idx, music_on
.globalzp spr_x, spr_y, spr_tile, spr_attr, spr_size

; ---------- low RAM ----------
.global oam_buf, oam_hi, txt_map, pal_buf, dmaq
.global players, num_players, cur_player, game_mode
.global event_on, event_idx, ev_score, ev_fail, ev_stat, ev_giveup
.global records, ev_ram, pause_ok
; attract demo (game.s demo_play, boot.s demo_pads)
.global demo_on, demo_off, demo_left, demo_mask, demo_real, demo_sp, demo_ev, demo_force

PL_SIZE    = 32
PL_NAME    = 0      ; 8 chars + 0
PL_SPONSOR = 9
PL_SCORES  = 10     ; 7 words
PL_POINTS  = 24     ; medal points (word)
PL_GOLD    = 26
PL_SILVER  = 27
PL_BRONZE  = 28
PL_TOTAL   = 30     ; total event points (word)
MAX_PLAYERS = 8
NUM_EVENTS  = 7
NUM_SPONSORS = 12
EV_RAM_SIZE = 2048

; event ids
EV_BIKE = 0
EV_BAY  = 1
EV_PARK = 2
EV_COPS = 3
EV_SAIL = 4
EV_PARKING = 5
EV_SUBWAY  = 6

; game modes
GM_ALL      = 0
GM_SOME     = 1
GM_PRACTICE = 2

; ---------- engine routines (bank $80, all jsl/rtl, A8 XY16 in & out) ----------
.global wait_frame, ppu_off, fade_in, fade_out, wait_frames
.global vram_load, vram_fill, vram_clear_all, pal_load, pal_clear, dma_queue
.global oam_clear, oam_put, oam_meta, oam_finish
.global txt_clear, txt_print, txt_print_centre, txt_num, txt_box, txt_fill, txt_char
.global rand, rand_range, sin8, cos8, div16, mul8
.global set_mode1_defaults, hdma_off
.global sfx_play, music_play, music_keep, music_stop, audio_tick, audio_init

; text tile numbers inside the BG3 tileset (add 128 = same tile on window fill)
TXT_SPACE   = 0
TXT_BOX     = 64    ; 64..72: TL T TR / L fill R / BL B BR
TXT_METER   = 73    ; 73..77 meter 0/4 .. 4/4
TXT_ARROW_R = 78
TXT_ARROW_L = 79
TXT_HEART   = 80
TXT_MEDAL   = 81
TXT_SOLID1  = 82
TXT_SOLID2  = 83
TXT_FILL    = 84
TXT_ARROW_U = 85
TXT_ARROW_D = 86
TXT_LEAF    = 87
TXT_DOT     = 88
TXT_WIN     = 128   ; txt_bg value for text inside windows

.globalzp txt_bg

; sound effects
SFX_BLIP    = 0
SFX_SELECT  = 1
SFX_BACK    = 2
SFX_JUMP    = 3
SFX_CRASH   = 4
SFX_COIN    = 5
SFX_WHISTLE = 6
SFX_HORN    = 7
SFX_BARK    = 8
SFX_SPLASH  = 9
SFX_BELL    = 10
SFX_GO      = 11
SFX_READY   = 12
SFX_STEP    = 13
SFX_SIP     = 14
SFX_CHEER   = 15
SFX_TICK    = 16
SFX_GROAN   = 17     ; crowd groan: no medals, a Leafs-style collapse

; songs
SONG_TITLE     = 0     ; KC Incidental
SONG_MENU      = 1     ; Bobcaygeese
SONG_BIKE      = 2     ; Gold Guns Gulls
SONG_STANDINGS = 3     ; Ahead by a Centimetre: event standings, final table
SONG_BAY       = 4     ; Whelp, I'm Alive
SONG_CHASE     = 5     ; Hay, Officer (Tallboy Trot)
SONG_SAIL      = 6     ; Brother Downwind
SONG_PARK      = 7     ; If I Had a Million Collars
SONG_PODIUM    = 8     ; KC Incidental (Podium Reprise)
SONG_PARKING   = 9     ; Green P Shuffle
SONG_SUBWAY    = 10    ; Please Stand Clear
NUM_SONGS      = 11
