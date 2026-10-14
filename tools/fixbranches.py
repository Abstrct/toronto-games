"""Dev helper: run make, turn out-of-range short branches into long ones
(ca65 longbranch macros), repeat until none are left."""
import re
import subprocess

LONG = {'bne': 'jne', 'beq': 'jeq', 'bcc': 'jcc', 'bcs': 'jcs', 'bpl': 'jpl',
        'bmi': 'jmi', 'bvc': 'jvc', 'bvs': 'jvs', 'bra': 'jmp'}

for _ in range(40):
    r = subprocess.run(['make'], capture_output=True, text=True)
    errs = re.findall(r'^(src/\S+?)\((\d+)\): Error: Range error', r.stdout + r.stderr, re.M)
    if not errs:
        print((r.stdout + r.stderr)[-3000:])
        break
    fixed = 0
    for path, line in set(errs):
        lines = open(path).read().split('\n')
        i = int(line) - 1
        m = re.match(r'^(\s*)(b[a-z]{2})(\s+)(.*)$', lines[i])
        if m and m.group(2) in LONG:
            lines[i] = m.group(1) + LONG[m.group(2)] + m.group(3) + m.group(4)
            fixed += 1
            open(path, 'w').write('\n'.join(lines))
        else:
            print('not a branch:', path, line, lines[i])
    if not fixed:
        print((r.stdout + r.stderr)[-3000:])
        break
