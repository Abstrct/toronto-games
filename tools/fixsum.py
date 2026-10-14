"""Patch the SNES header checksum (LoROM header at file offset $7FC0)."""
import sys

path = sys.argv[1]
rom = bytearray(open(path, 'rb').read())
assert len(rom) % 0x8000 == 0, 'ROM size must be a multiple of 32 KB'
rom[0x7FDC:0x7FE0] = b'\xff\xff\x00\x00'
total = sum(rom) & 0xFFFF
rom[0x7FDC] = (total ^ 0xFFFF) & 0xFF
rom[0x7FDD] = (total ^ 0xFFFF) >> 8
rom[0x7FDE] = total & 0xFF
rom[0x7FDF] = total >> 8
open(path, 'wb').write(rom)
print('%s: %d KB, checksum %04X' % (path, len(rom) // 1024, total))
