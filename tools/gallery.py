"""Dev helper: capture showcase screenshots from the ROM into build/gallery
(3x, nearest-neighbour)."""
import os
import subprocess
import sys
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), '..')
OUT = os.path.join(ROOT, 'build', 'gallery')
SHOTS = os.path.join(ROOT, 'build', 'shots')

MENU = 'w200 pSTART w40 '
SIGNUP = 'pDOWN pDOWN pA w40 pSTART w40 pA w60 pSTART w60 '   # practice, default name, Honest Ed's
EV = {k: SIGNUP + ('pDOWN ' * k) + 'pA w60 pA w170 ' for k in range(5)}

def alt(n):
    return ' '.join('pLEFT pRIGHT' for _ in range(n))

SCENES = {
    'title': 'w260',
    'sponsors': MENU + 'pA w40 pA pRIGHT pA pRIGHT pRIGHT pA pSTART w40 pDOWN pDOWN pDOWN pLEFT w30',
    'bike': MENU + EV[0] + 'hA w100',
    'bay': MENU + EV[1] + alt(30) + ' pA w2',
    'park': MENU + EV[2] + 'hUP w160',
    'cops': MENU + EV[3] + ' '.join(['pA w44'] * 12) + ' hB w110',
    'sail': MENU + EV[4] + 'w200',
}


def main():
    os.makedirs(OUT, exist_ok=True)
    names = sys.argv[1:] or list(SCENES)
    for n in names:
        subprocess.check_call([sys.executable, os.path.join(ROOT, 'tools', 'run.py'),
                               SCENES[n] + ' s:g_' + n], stdout=subprocess.DEVNULL)
        img = Image.open(os.path.join(SHOTS, 'g_' + n + '.png'))
        img = img.resize((768, 672), Image.NEAREST)
        img.save(os.path.join(OUT, n + '.png'))
        print('saved', n)


if __name__ == '__main__':
    main()
