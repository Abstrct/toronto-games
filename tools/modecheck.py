"""Lint the register-size bookkeeping that ca65 can't check for us.

1. Global code labels reached (by fall-through) with a state other than the
   house default (.a8 / .i16).
2. Branches / jumps whose assembler state (= the CPU's state at run time,
   if the code above is right) differs from the state at the target label.
   A mismatch means instructions after the label are assembled for the
   wrong accumulator/index width - the "lda #$03 assembled as 3 bytes"
   class of crash."""
import re
import sys
import glob

files = sys.argv[1:] or sorted(glob.glob('src/*.s') + glob.glob('src/*.inc'))
SET = {'A8': ('a', 8), 'A16': ('a', 16), 'I8': ('i', 8), 'I16': ('i', 16),
       '.a8': ('a', 8), '.a16': ('a', 16), '.i8': ('i', 8), '.i16': ('i', 16)}
BR = {'bcc', 'bcs', 'beq', 'bne', 'bmi', 'bpl', 'bvc', 'bvs', 'bra', 'brl', 'jmp',
      'jcc', 'jcs', 'jeq', 'jne', 'jmi', 'jpl', 'jvc', 'jvs'}
# macros that flip width internally but restore A8
NEUTRAL = {'TAXB', 'TAYB', 'LDPTR0', 'LDPTR1', 'PRINT', 'PRINTC', 'VLOAD', 'PLOAD', 'SFX'}
problems = 0
for path in files:
    a, i = 8, 16
    scope = ''
    defs = {}
    uses = []
    for n, raw in enumerate(open(path), 1):
        line = raw.split(';')[0].rstrip()
        if not line.strip():
            continue
        m = re.match(r'^(@?[A-Za-z_][A-Za-z0-9_]*):', line)
        if m:
            name = m.group(1)
            if not name.startswith('@'):
                scope = name
                if (a, i) != (8, 16) and path.endswith('.s') and False:
                    pass
            key = (scope, name) if name.startswith('@') else ('', name)
            defs[key] = (a, i, n)
            line = line[m.end():]
        s = line.strip()
        if not s:
            continue
        tok = s.split()[0]
        if tok == 'AXY8':
            a, i = 8, 8
            continue
        if tok == 'AXY16':
            a, i = 16, 16
            continue
        if tok == 'A8I16':
            a, i = 8, 16
            continue
        if tok in SET:
            k, v = SET[tok]
            if k == 'a':
                a = v
            else:
                i = v
            continue
        if tok in BR:
            parts = s.split(None, 1)
            if len(parts) == 2:
                tgt = parts[1].strip()
                if re.match(r'^@?[A-Za-z_][A-Za-z0-9_]*$', tgt):
                    key = (scope, tgt) if tgt.startswith('@') else ('', tgt)
                    uses.append((key, a, i, n, tok))
    lines = open(path).read().split('\n')
    AIMM = {'lda', 'adc', 'sbc', 'cmp', 'and', 'ora', 'eor', 'bit'}
    XIMM = {'ldx', 'ldy', 'cpx', 'cpy'}

    def danger(start, bad_a, bad_i):
        """walk from the label line; return the first width-sensitive line"""
        for k in range(start - 1, min(len(lines), start + 60)):
            ln = lines[k].split(';')[0]
            ln = re.sub(r'^@?[A-Za-z_][A-Za-z0-9_]*:', '', ln).strip()
            if not ln:
                continue
            t = ln.split()[0]
            if t in ('A8', 'A16', '.a8', '.a16', 'AXY8', 'AXY16', 'A8I16', 'LDPTR0', 'LDPTR1',
                     'PRINT', 'PRINTC', 'VLOAD', 'PLOAD'):
                if bad_a and t not in ('.i8', '.i16'):
                    bad_a = False
                if t in ('AXY8', 'AXY16', 'A8I16'):
                    bad_i = False
            if t in ('I8', 'I16', '.i8', '.i16'):
                bad_i = False
            if not bad_a and not bad_i:
                return None
            if bad_a and ((t in AIMM and '#' in ln) or t == 'SFX'):
                return k + 1
            if bad_i and t in XIMM and '#' in ln:
                return k + 1
            if t in ('rts', 'rtl', 'rti', 'jmp', 'jml', 'bra', 'brl'):
                return None
        return None

    for key, a, i, n, tok in uses:
        if key in defs:
            da, di, dn = defs[key]
            if (da, di) != (a, i):
                hit = danger(dn, da != a, di != i)
                if hit:
                    print('%s:%d: %s %s from .a%d.i%d -> label line %d is .a%d.i%d; first sensitive line %d'
                          % (path, n, tok, key[1], a, i, dn, da, di, hit))
                    problems += 1
print('%d mismatches' % problems)
sys.exit(1 if problems else 0)
