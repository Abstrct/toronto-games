"""Dev helper: run the ROM headless with a button script and save PNGs.
    python3 tools/run.py "w200 s:title pSTART w60 s:menu"
Screenshots land in build/shots/<name>.png (2x)."""
import os
import subprocess
import sys
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), '..')
EMU = os.path.join(ROOT, 'build', 'emu')
CORE = os.path.join(EMU, 'snes9x', 'libretro', 'snes9x_libretro.dylib')
HARNESS = os.path.join(EMU, 'harness')
SHOTS = os.path.join(ROOT, 'build', 'shots')


def ensure_harness():
    src = os.path.join(ROOT, 'tools', 'harness', 'harness.c')
    if not os.path.exists(HARNESS) or os.path.getmtime(HARNESS) < os.path.getmtime(src):
        subprocess.check_call(['cc', '-O2', '-o', HARNESS, src,
                               '-I', os.path.join(EMU, 'snes9x', 'libretro')])


def main():
    ensure_harness()
    os.makedirs(SHOTS, exist_ok=True)
    toks = []
    names = []
    for t in sys.argv[1].split():
        if t.startswith('s:'):
            name = t[2:]
            names.append(name)
            toks.append('s:' + os.path.join(SHOTS, name + '.ppm'))
        else:
            toks.append(t)
    rom = os.path.join(ROOT, 'toronto_games.sfc')
    r = subprocess.run([HARNESS, CORE, rom, ' '.join(toks)], capture_output=True, text=True)
    sys.stdout.write(r.stdout)
    sys.stderr.write(r.stderr[-2000:])
    for n in names:
        p = os.path.join(SHOTS, n + '.ppm')
        if os.path.exists(p):
            img = Image.open(p)
            img = img.resize((img.width * 2, img.height * 2), Image.NEAREST)
            img.save(os.path.join(SHOTS, n + '.png'))
            os.remove(p)


if __name__ == '__main__':
    main()
