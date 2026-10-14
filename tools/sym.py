"""Dev helper: nearest symbol for addresses (hex) using build/map.txt."""
import re, sys
syms = {}
for m in re.finditer(r'(\w+)\s+([0-9A-F]{6}) RLA', open('build/map.txt').read()):
    syms[int(m.group(2), 16)] = m.group(1)
keys = sorted(syms)
for a in sys.argv[1:]:
    v = int(a, 16)
    best = max((k for k in keys if k <= v), default=None)
    print(a, '->', syms.get(best), '+%X' % (v - best) if best is not None else '')
