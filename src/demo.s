; Attract-demo joypad streams (recorded by tools/pt/demo_export.py from the
; harness bots; see game.s demo_play). Bank $8E, read with long addressing.
.p816
.smart -
.include "globals.inc"

.export demo_blob, demo_start

.segment "GFX9"
.include "demo_data.inc"
