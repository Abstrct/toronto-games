; Symbols shared by the menu/screen code (bank $81) and the events

.global title_tiles, title_bg1, title_bg2, title_pal, title_sky, spr_title, spr_title_pal
.global txt_tiles, txt_pal, menu_tiles, menu_bg2, badges_bg1, menu_pal, spr_menu, spr_menu_pal, jerseys

; game.s
.global game_main, load_text_gfx, load_menu_gfx, player_palette, player_offset
.global print_player_name, print_sponsor_name, sponsor_names, sponsor_tags
.global ev_names, ev_places, records_load, records_save, wait_button, menu_backdrop_tick
.global clear_scores, award_medals

; screens
.global title_screen, main_menu, pick_events, records_screen
.global register_players
.global event_card, score_card, event_standings, ceremony, event_countdown, event_popup, event_popup_clear

; events
.global ev_bike, ev_bay, ev_park, ev_cops, ev_sail, ev_parking, ev_subway

; event_card / score_card helpers read these
.global card_stat_labels

; menu.s helpers shared with register.s / cards.s (same bank, jsr/rts)
.global menu_setup, draw_list, list_nav, m_sel, m_count
.global rank_order, rank_medal

; ceremony
.global final_sort, final_table
.global cer_tiles, cer_bg1, cer_bg2, cer_pal, cer_spr, cer_spr_pal, cer_sky
