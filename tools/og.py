"""Share images for the web page, cut from the ROM's own title screen.
    python3 tools/og.py
Runs the ROM headless (needs build/emu, like tools/run.py) and writes
web/og.png (1200x630, the link preview), web/icon.png (180x180, home
screen) and web/favicon.png (32x32). The files are committed, so CI
doesn't need the emulator; run this again when the title art changes."""
import os
import subprocess
import sys
from PIL import Image

import font

ROOT = os.path.join(os.path.dirname(__file__), '..')
SHOTS = os.path.join(ROOT, 'build', 'shots')
WEB = os.path.join(ROOT, 'web')

TEXT = '#f8f8f8'
GOLD = '#f8d830'
SHADOW = '#101030'


def title_frame():
    # frame 360: the logo and skyline are up, and the sailboat is clear of the tower
    subprocess.check_call([sys.executable, os.path.join(ROOT, 'tools', 'run.py'), 'w360 s:og_title'],
                          stdout=subprocess.DEVNULL)
    im = Image.open(os.path.join(SHOTS, 'og_title.png')).convert('RGB')
    return im.resize((im.width // 2, im.height // 2), Image.NEAREST)   # back to 256x224


def text(im, x, y, s, colour):
    """the game's 5x7 font with its drop shadow, 6 px a character, at 1x"""
    for i, ch in enumerate(s):
        for yy, row in enumerate(font.G[ch]):
            for xx, c in enumerate(row):
                if c == '#':
                    im.putpixel((x + i * 6 + xx + 1, y + yy + 1), _rgb(SHADOW))
        for yy, row in enumerate(font.G[ch]):
            for xx, c in enumerate(row):
                if c == '#':
                    im.putpixel((x + i * 6 + xx, y + yy), _rgb(colour))


def _rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def og(frame):
    # 240x126 of the title (logo, tower, skyline, water) at exactly 5x = 1200x630
    card = frame.crop((8, 4, 248, 130))
    lines = [('PLAY IN YOUR BROWSER', GOLD), ('TORONTO.AD', TEXT)]
    y = 126 - 9 * len(lines) - 3
    for s, colour in lines:
        w = len(s) * 6 - 1
        band = Image.new('RGB', (w + 6, 10), _rgb(SHADOW))
        card.paste(band, ((240 - w) // 2 - 3, y - 1))
        text(card, (240 - w) // 2, y, s, colour)
        y += 9
    return card.resize((1200, 630), Image.NEAREST)


def icon(frame):
    # the CN Tower from the beacon down past the pod, 60x60 at 3x
    return frame.crop((14, 8, 74, 68)).resize((180, 180), Image.NEAREST)


def favicon(frame):
    # the pod, 1:1
    return frame.crop((34, 33, 66, 65))


def main():
    frame = title_frame()
    og(frame).save(os.path.join(WEB, 'og.png'), optimize=True)
    icon(frame).save(os.path.join(WEB, 'icon.png'), optimize=True)
    favicon(frame).save(os.path.join(WEB, 'favicon.png'), optimize=True)
    print('web/og.png, web/icon.png, web/favicon.png')


if __name__ == '__main__':
    main()
