; Cartridge header and interrupt vectors at $00:FFC0
.p816
.include "globals.inc"

.import reset_stub, nmi_stub, irq_stub

.segment "HEADER"
    .byte "TORONTO GAMES        "   ; 21-byte title
    .byte $20                       ; LoROM, slow ROM
    .byte $02                       ; ROM + SRAM + battery (records)
    .byte $09                       ; 512 KB ROM
    .byte $01                       ; 2 KB SRAM
    .byte $01                       ; North America
    .byte $00                       ; licensee
    .byte $00                       ; version 1.0
    .word $FFFF, $0000              ; checksum complement, checksum (patched by tools/fixsum.py)

    ; native-mode vectors
    .word 0, 0
    .word .loword(irq_stub)         ; COP
    .word .loword(irq_stub)         ; BRK
    .word .loword(irq_stub)         ; ABORT
    .word .loword(nmi_stub)         ; NMI
    .word 0
    .word .loword(irq_stub)         ; IRQ

    ; emulation-mode vectors
    .word 0, 0
    .word .loword(irq_stub)         ; COP
    .word 0
    .word .loword(irq_stub)         ; ABORT
    .word .loword(irq_stub)         ; NMI
    .word .loword(reset_stub)       ; RESET
    .word .loword(irq_stub)         ; IRQ / BRK
