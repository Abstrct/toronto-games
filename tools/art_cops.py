"""Tallboy Trot: Kensington Market side-scroller. BG2 rooftops + distant CN
Tower, BG1 Victorian shopfronts + sidewalk + street, sprites for the runner,
the bike cop, raccoons, bins, crates and benches."""
import random
from PIL import Image, ImageDraw
from snes import (TileSet, convert_bg, build_palettes, map_bytes, pal_bytes, hexrgb, snap,
                  out, preview, hdma_gradient)
from sprites import Sheet, render
import people as P

GROUND = 192        # the runner's feet (ev_cops.s GROUND)
LIFT = 12           # everything above the sidewalk sits this much higher than it used to


def rgb(h):
    return snap(hexrgb(h)) + (255,)


def far_layer():
    img = Image.new('RGBA', (512, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rnd = random.Random(3)
    roof = rgb('#6a4a6a')
    roof2 = rgb('#583a58')
    win = rgb('#f8c860')
    x = 0
    while x < 512:
        w = rnd.choice([24, 32, 40])
        top = rnd.randrange(56, 84) - LIFT
        d.rectangle([x, top, x + w - 1, 140 - LIFT], fill=roof)
        d.polygon([(x, top), (x + w // 2, top - 10), (x + w - 1, top)], fill=roof2)
        if rnd.random() < 0.6:
            d.rectangle([x + 4, top + 8, x + 6, top + 11], fill=win)
        x += w
    # CN Tower far away: tapered legs, disc pod, SkyPod, antenna (lit on the left)
    cx = 400
    tower = rgb('#8a7a9a')
    light = rgb('#b8a8c4')
    glass = rgb('#3a3050')
    L = LIFT
    for y in range(52 - L, 110 - L):
        f = (y - 52 + L) / 58.0
        half = 1 + 3.5 * f ** 2.6
        d.line([cx - half, y, cx + half, y], fill=tower)
        d.point((cx - int(half), y), fill=light)
    d.rectangle([cx - 1, 34 - L, cx + 1, 46 - L], fill=tower)
    d.point((cx - 1, 40 - L), fill=light)
    for (y, half, col) in ((44, 4, tower), (45, 7, light), (46, 8, glass), (47, 8, light),
                           (48, 7, tower), (49, 3, tower), (50, 2, tower), (51, 2, tower)):
        d.line([cx - half, y - L, cx + half, y - L], fill=col)
    d.line([cx - 3, 31 - L, cx + 3, 31 - L], fill=tower)
    d.line([cx - 3, 32 - L, cx + 3, 32 - L], fill=glass)
    d.line([cx - 2, 33 - L, cx + 2, 33 - L], fill=tower)
    d.line([cx, 24 - L, cx, 30 - L], fill=light)
    d.point((cx, 23 - L), fill=rgb('#f86048'))
    return img


HOUSE = ['#e86888', '#38b0a8', '#f0c040', '#8858c0', '#e88838', '#58a048', '#d84040', '#4878d0']
BASE = 148 - LIFT   # house fronts end here; the sidewalk (the play lane) runs to the curb at CURB
CURB = 204

# 3x5 sign letters (same micro font as the sponsor badges)
MICRO = {
    'A': ['.#.', '#.#', '###', '#.#', '#.#'], 'B': ['##.', '#.#', '##.', '#.#', '##.'],
    'C': ['.##', '#..', '#..', '#..', '.##'], 'D': ['##.', '#.#', '#.#', '#.#', '##.'],
    'E': ['###', '#..', '##.', '#..', '###'], 'F': ['###', '#..', '##.', '#..', '#..'],
    'G': ['.##', '#..', '#.#', '#.#', '.##'], 'H': ['#.#', '#.#', '###', '#.#', '#.#'],
    'I': ['###', '.#.', '.#.', '.#.', '###'], 'K': ['#.#', '#.#', '##.', '#.#', '#.#'],
    'N': ['##.', '#.#', '#.#', '#.#', '#.#'], 'O': ['.#.', '#.#', '#.#', '#.#', '.#.'],
    'R': ['##.', '#.#', '##.', '#.#', '#.#'], 'S': ['.##', '#..', '.#.', '..#', '##.'],
    'T': ['###', '.#.', '.#.', '.#.', '.#.'], 'U': ['#.#', '#.#', '#.#', '#.#', '###'],
    'V': ['#.#', '#.#', '#.#', '#.#', '.#.'], 'Y': ['#.#', '#.#', '.#.', '.#.', '.#.'],
    'Z': ['###', '..#', '.#.', '#..', '###'], ' ': ['...'] * 5,
}
# one Kensington shop per house: sign, window display
SHOPS = [('FRUIT', 'fruit'), ('VINTAGE', 'rack'), ('CHEESE', 'cheese'), ('RECORDS', 'lps'),
         ('BAKERY', 'bread'), ('FISH', 'fish'), ('TACOS', 'fruit2'), ('BIKES', 'wheels')]


def micro_text(d, x, y, text, col):
    for ch in text:
        for yy, row in enumerate(MICRO.get(ch, MICRO[' '])):
            for xx, c in enumerate(row):
                if c == '#':
                    d.point((x + xx, y + yy), fill=col)
        x += 4


def window_display(d, kind, x0, y0, x1, y1, i):
    """Goods behind the shop glass (x0..x1, y0..y1)."""
    red, orange, yellow, green = (rgb(c) for c in ('#d84040', '#e88838', '#f0c040', '#58a048'))
    trim = rgb('#f0e8d8')
    dark = rgb('#201828')
    wood = rgb('#a8743c')
    if kind in ('fruit', 'fruit2'):
        cols = (red, orange, green, yellow) if kind == 'fruit' else (green, yellow, red, orange)
        for row in range(3):
            yy = y1 - 3 - row * 6
            d.line([x0, yy + 2, x1, yy + 2], fill=wood)
            for k in range(x0 + 1 + (row % 2) * 2, x1 - 1, 4):
                d.ellipse([k, yy - 1, k + 2, yy + 1], fill=cols[(k // 4 + row) % 4])
    elif kind == 'rack':
        d.line([x0 + 1, y0 + 4, x1 - 1, y0 + 4], fill=trim)
        cols = (red, yellow, green, HOUSE_RGB[3], orange, HOUSE_RGB[1])
        for n, k in enumerate(range(x0 + 2, x1 - 3, 5)):
            c = cols[n % len(cols)]
            d.polygon([(k, y0 + 6), (k + 4, y0 + 6), (k + 4, y0 + 18 + (n % 2) * 4), (k, y0 + 18 + (n % 2) * 4)], fill=c)
            d.point((k + 2, y0 + 5), fill=trim)
    elif kind == 'cheese':
        d.line([x0, y1 - 1, x1, y1 - 1], fill=wood)
        for k in range(x0 + 1, x1 - 6, 9):
            d.ellipse([k, y1 - 9, k + 7, y1 - 2], fill=yellow)
            d.line([k + 1, y1 - 6, k + 6, y1 - 6], fill=orange)
        for k in range(x0 + 3, x1 - 6, 10):
            d.polygon([(k, y1 - 12), (k + 7, y1 - 12), (k, y1 - 17)], fill=yellow)
    elif kind == 'lps':
        for n, k in enumerate(range(x0 + 1, x1 - 8, 10)):
            yy = y0 + 4 + (n % 2) * 10
            d.rectangle([k, yy, k + 8, yy + 8], fill=(red, yellow, HOUSE_RGB[1])[n % 3])
            d.ellipse([k + 1, yy + 1, k + 7, yy + 7], fill=dark)
            d.point((k + 4, yy + 4), fill=trim)
    elif kind == 'bread':
        d.line([x0, y1 - 1, x1, y1 - 1], fill=wood)
        for k in range(x0 + 1, x1 - 7, 8):
            d.ellipse([k, y1 - 6, k + 7, y1 - 2], fill=orange)
            d.line([k + 2, y1 - 5, k + 3, y1 - 3], fill=yellow)
        for k in range(x0 + 4, x1 - 7, 8):
            d.ellipse([k, y1 - 10, k + 6, y1 - 6], fill=wood)
    elif kind == 'fish':
        d.rectangle([x0, y1 - 5, x1, y1], fill=trim)
        for n, k in enumerate(range(x0 + 1, x1 - 7, 7)):
            yy = y1 - 8 - (n % 2) * 2
            d.ellipse([k, yy, k + 5, yy + 3], fill=rgb('#5878a8'))
            d.polygon([(k + 5, yy + 1), (k + 7, yy - 1), (k + 7, yy + 4)], fill=rgb('#5878a8'))
    elif kind == 'wheels':
        for k in (x0 + 2, x0 + 15):
            d.ellipse([k, y1 - 13, k + 11, y1 - 2], outline=trim)
            d.point((k + 5, y1 - 8), fill=trim)
        d.line([x0 + 8, y1 - 8, x0 + 14, y1 - 12, x0 + 20, y1 - 8], fill=red)


HOUSE_RGB = [rgb(c) for c in HOUSE]


def near_layer():
    img = Image.new('RGBA', (512, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    trim = rgb('#f0e8d8')
    dark = rgb('#201828')
    glass = rgb('#283858')
    glass2 = rgb('#5878a8')
    for i in range(8):
        x0 = i * 64
        body = rgb(HOUSE[i])
        shade = tuple(max(0, c - 40) for c in body[:3]) + (255,)
        top = 58 - LIFT + (i % 3) * 4
        d.rectangle([x0, top, x0 + 63, BASE - 1], fill=body)
        d.polygon([(x0, top), (x0 + 32, top - 16), (x0 + 63, top)], fill=shade)
        d.line([x0, top, x0 + 63, top], fill=trim)
        d.rectangle([x0 + 62, top, x0 + 63, BASE - 1], fill=shade)
        # bay window upstairs
        d.rectangle([x0 + 18, top + 6, x0 + 45, top + 26], fill=trim)
        d.rectangle([x0 + 21, top + 9, x0 + 30, top + 23], fill=glass)
        d.rectangle([x0 + 33, top + 9, x0 + 42, top + 23], fill=glass)
        d.line([x0 + 23, top + 10, x0 + 23, top + 21], fill=glass2)
        # shop at street level: sign, awning, window display, door
        d.rectangle([x0 + 6, BASE - 38, x0 + 57, BASE - 1], fill=dark)
        d.rectangle([x0 + 8, BASE - 34, x0 + 36, BASE - 3], fill=glass)
        d.rectangle([x0 + 40, BASE - 34, x0 + 54, BASE - 1], fill=shade)
        d.point((x0 + 42, BASE - 18), fill=trim)
        name, kind = SHOPS[i]
        window_display(d, kind, x0 + 8, BASE - 34, x0 + 36, BASE - 3, i)
        aw = rgb(HOUSE[(i + 3) % 8])
        for k in range(x0 + 4, x0 + 60, 6):
            d.polygon([(k, BASE - 44), (k + 6, BASE - 44), (k + 6, BASE - 38), (k, BASE - 38)],
                      fill=aw if (k // 6) % 2 else trim)
        d.rectangle([x0 + 10, BASE - 54, x0 + 53, BASE - 46], fill=trim)
        micro_text(d, x0 + 32 - (len(name) * 4 - 1) // 2, BASE - 52, name, dark)
    # sidewalk + curb + street
    sw = rgb('#a8a0a0')
    d.rectangle([0, BASE, 511, CURB - 1], fill=sw)
    for x in range(0, 512, 24):
        d.line([x, BASE, x - 17, CURB - 1], fill=rgb('#908888'))
    d.line([0, BASE, 511, BASE], fill=rgb('#c8c0c0'))
    d.rectangle([0, CURB, 511, CURB + 3], fill=rgb('#d0d0d0'))
    d.rectangle([0, CURB + 4, 511, 255], fill=rgb('#48444c'))
    # the HUD bar covers 208-215; the road's dashes show under it (lost to overscan on a CRT, and that's fine)
    for x in range(0, 512, 32):
        d.rectangle([x, 219, x + 15, 220], fill=rgb('#e8d040'))
    return img


COP = ['#000000', '#101018', '#e8b888', '#b88858', '#182040', '#0c1430', '#e8f020', '#b8c010',
       '#d8d8e0', '#383840', '#f8f8f8', '#202020', '#888890']
COP_ALT = ['#2850c0', '#183080', '#f8f8f8']
PROPS = ['#000000', '#101018', '#9a9aa8', '#5a5a68', '#202028', '#f0f0f0', '#2a8a3a', '#1a5a28',
         '#a8743c', '#6a4420', '#e02818', '#f88820', '#68c030', '#f8e040', '#c89848', '#c8c8d0']


def draw_cop(sh, x0, y0, frame):
    d = sh.draw()
    # bike
    for cx in (x0 + 7, x0 + 24):
        d.ellipse([cx - 6, y0 + 20, cx + 6, y0 + 31], outline=11)
        d.ellipse([cx - 5, y0 + 21, cx + 5, y0 + 30], outline=12)
        a = frame * 2
        d.line([cx - 4 + a, y0 + 25, cx + 4 - a, y0 + 26], fill=12)
    d.line([x0 + 7, y0 + 26, x0 + 15, y0 + 26, x0 + 24, y0 + 26], fill=11, width=1)
    d.line([x0 + 15, y0 + 26, x0 + 12, y0 + 19, x0 + 22, y0 + 19, x0 + 24, y0 + 26], fill=11)
    d.line([x0 + 22, y0 + 19, x0 + 22, y0 + 16], fill=11)
    # rider
    k = (0, 3)[frame]
    d.line([x0 + 12, y0 + 18, x0 + 15 + k, y0 + 23 - k // 2, x0 + 15, y0 + 27], fill=4, width=2)
    d.line([x0 + 12, y0 + 18, x0 + 18 - k, y0 + 22, x0 + 17 - k, y0 + 27], fill=5, width=2)
    d.polygon([(x0 + 9, y0 + 8), (x0 + 16, y0 + 7), (x0 + 15, y0 + 18), (x0 + 10, y0 + 18)], fill=6)
    d.line([x0 + 9, y0 + 13, x0 + 15, y0 + 13], fill=8)
    d.line([x0 + 9, y0 + 9, x0 + 9, y0 + 17], fill=7)
    d.line([x0 + 15, y0 + 9, x0 + 21, y0 + 15], fill=6, width=2)
    d.point((x0 + 22, y0 + 16), fill=2)
    d.ellipse([x0 + 12, y0 + 0, x0 + 19, y0 + 7], fill=2)
    d.chord([x0 + 11, y0 - 1, x0 + 20, y0 + 5], 180, 360, fill=10)
    d.line([x0 + 11, y0 + 2, x0 + 20, y0 + 2], fill=11)
    d.point((x0 + 18, y0 + 4), fill=1)
    sh.outline(x0, y0, 32, 32)


def draw_raccoon(sh, x0, y0, frame):
    d = sh.draw()
    legs = [(3, 8), (5, 6)][frame]
    for lx in legs:
        d.rectangle([x0 + lx, y0 + 12, x0 + lx + 1, y0 + 15], fill=4)
    d.ellipse([x0 + 2, y0 + 6, x0 + 13, y0 + 13], fill=2)
    d.ellipse([x0 + 4, y0 + 6, x0 + 11, y0 + 9], fill=15)
    for k in range(3):
        d.line([x0 + 12 + k, y0 + 7 + k, x0 + 15, y0 + 7 + k], fill=4 if k % 2 == 0 else 2)
    d.ellipse([x0 - 1 + 1, y0 + 4, x0 + 6, y0 + 10], fill=2)
    d.rectangle([x0 + 1, y0 + 6, x0 + 5, y0 + 7], fill=4)
    d.point((x0 + 2, y0 + 6), fill=5)
    d.point((x0 + 1, y0 + 4), fill=3)
    d.point((x0 + 5, y0 + 4), fill=3)
    sh.outline(x0, y0, 16, 16)



# ---------------------------------------------------------------------------
# The big runner: 32x40 cells (about 38 px tall, the old one was 28), drawn
# from joint angles like people.py but with chunkier limbs and a body that
# can pitch forward for the trip tumble. Athlete colour layout (people.py):
# 1 outline 2 skin 3 skin shade 4 hair 5 top 6 top shade 7 accent 8 pants
# 9 pants shade 10 white 11 shoes 13 can 14 can top
import math

RW, RH = 32, 40


def _pt(x, y, ang, length):
    return (x + math.sin(math.radians(ang)) * length, y + math.cos(math.radians(ang)) * length)


def big_person(sh, x0, y0, legs=(20, -20), knees=(0, 0), arms=(-20, 20), elbows=(0, 0), bob=0,
               tilt=0, hip=(14, 26), head_back=0, can=None, eyes='open'):
    """legs/arms: (front, back) world angles from straight down, + = forward (right).
    tilt: torso angle from upright, + = pitching forward. can: None, 'hand', 'mouth'."""
    d = sh.draw()
    hx, hy = x0 + hip[0], y0 + hip[1] + bob
    sx, sy = _pt(hx, hy, 180 - tilt, 11)            # shoulders, 11 px up the spine
    nx, ny = _pt(hx, hy, 180 - tilt, 13)
    cx, cy = _pt(hx, hy, 180 - tilt - head_back * 0.3, 18)   # head centre

    def leg(front):
        i = 0 if front else 1
        col = 8 if front else 9
        kx, ky = _pt(hx, hy, legs[i], 7)
        fx, fy = _pt(kx, ky, legs[i] - knees[i], 7)
        d.line([hx, hy, kx, ky], fill=col, width=3)
        d.line([kx, ky, fx, fy], fill=col, width=3)
        # shoe: toe points along the shin's normal, forward
        d.line([fx - 1, fy, fx + 3, fy], fill=11, width=2)

    def arm(front):
        i = 0 if front else 1
        col = 5 if front else 6
        ex, ey = _pt(sx, sy + 1, arms[i], 5)
        wx, wy = _pt(ex, ey, arms[i] + elbows[i], 5)
        d.line([sx, sy + 1, ex, ey], fill=col, width=2)
        d.line([ex, ey, wx, wy], fill=2, width=2)
        return wx, wy

    arm(False)
    leg(False)
    # torso: thick spine line, back shade, accent stripe down the front
    d.line([hx, hy, sx, sy], fill=5, width=7)
    bx, by = _pt(hx - 3 * math.cos(math.radians(tilt)), hy - 3 * math.sin(math.radians(tilt)), 180 - tilt, 0)
    bsx, bsy = _pt(sx - 3 * math.cos(math.radians(tilt)), sy - 3 * math.sin(math.radians(tilt)), 180 - tilt, 0)
    d.line([bx, by, bsx, bsy], fill=6, width=1)
    fx_, fy_ = _pt(hx + 2 * math.cos(math.radians(tilt)), hy + 2 * math.sin(math.radians(tilt)), 180 - tilt, 3)
    fsx, fsy = _pt(sx + 2 * math.cos(math.radians(tilt)), sy + 2 * math.sin(math.radians(tilt)), 180 - tilt, 0)
    d.line([fx_, fy_, fsx, fsy], fill=7, width=1)
    # waistband
    d.line([hx - 3, hy, hx + 3, hy], fill=9)
    leg(True)
    # neck + head (9x10), hair cap on the back/top, ear, eye, mouth
    d.line([sx, sy, nx, ny], fill=2, width=3)
    hxl, hyt = round(cx - 4), round(cy - 5)
    d.ellipse([hxl, hyt, hxl + 8, hyt + 9], fill=2)
    d.chord([hxl - 1, hyt - 1, hxl + 8, hyt + 6], 180 + head_back, 360 + head_back, fill=4)
    d.rectangle([hxl - 1, hyt + 1, hxl + 1, hyt + 5], fill=4)
    d.point((hxl + 3, hyt + 5), fill=3)
    ey = hyt + 4 - (1 if head_back > 20 else 0)
    if eyes == 'shut':
        d.line([hxl + 6, ey, hxl + 7, ey], fill=1)
    elif eyes == 'wide':
        d.rectangle([hxl + 6, ey - 1, hxl + 7, ey], fill=10)
        d.point((hxl + 7, ey), fill=1)
    else:
        d.point((hxl + 7, ey), fill=1)
        d.point((hxl + 6, ey), fill=1)
    hand = arm(True)
    if can == 'hand':
        x, y = hand
        d.rectangle([x - 1, y - 8, x + 1, y + 1], fill=13)
        d.line([x - 1, y - 8, x + 1, y - 8], fill=14)
        d.line([x - 1, y - 4, x + 1, y - 4], fill=12)
        d.point((x - 1, y - 6), fill=12)
    elif can == 'mouth':
        # can tipped up to the lips, bottom high: the full tallboy tilt
        mx, my = hxl + 9, hyt + 6
        d.polygon([(mx - 1, my), (mx + 1, my + 1), (mx + 8, my - 7), (mx + 6, my - 9), (mx - 1, my - 2)], fill=13)
        d.line([mx + 6, my - 9, mx + 8, my - 7], fill=14)
        d.line([mx + 2, my - 3, mx + 4, my - 5], fill=12)
        d.line([hand[0], hand[1], mx + 3, my - 3], fill=2, width=2)
    sh.outline(x0, y0, RW, RH)


def big_fallen(sh, x0, y0):
    """Face down on the sidewalk, 48 long (feet left), in a 64x40 cell, hands behind
    the back (the cop's been)."""
    d = sh.draw()
    by = y0 + 33
    d.line([x0 + 6, by + 1, x0 + 18, by], fill=9, width=3)
    d.line([x0 + 6, by + 4, x0 + 18, by + 3], fill=8, width=3)
    d.line([x0 + 4, by - 1, x0 + 6, by + 1], fill=11, width=2)
    d.line([x0 + 4, by + 3, x0 + 6, by + 5], fill=11, width=2)
    d.rectangle([x0 + 18, by - 3, x0 + 32, by + 4], fill=5)
    d.line([x0 + 18, by - 3, x0 + 32, by - 3], fill=6)
    d.line([x0 + 22, by - 4, x0 + 28, by - 4], fill=2, width=2)       # wrists up on the back
    d.rectangle([x0 + 24, by - 6, x0 + 26, by - 4], fill=14)           # cuffs
    d.ellipse([x0 + 32, by - 3, x0 + 41, by + 5], fill=2)
    d.chord([x0 + 32, by - 4, x0 + 41, by + 3], 180, 360, fill=4)
    d.point((x0 + 39, by + 2), fill=1)
    # the tallboy, rolling away
    d.rectangle([x0 + 50, by + 1, x0 + 56, by + 4], fill=13)
    d.line([x0 + 56, by + 1, x0 + 56, by + 4], fill=14)
    for (x, y) in ((x0 + 46, by + 5), (x0 + 44, by + 3), (x0 + 48, by + 6)):
        d.point((x, y), fill=12)
    sh.outline(x0, y0, 64, RH)


RUN6 = [dict(legs=(45, -35), knees=(10, 60), arms=(-40, 45), elbows=(90, 80), bob=0),
        dict(legs=(25, -10), knees=(15, 95), arms=(-20, 25), elbows=(90, 80), bob=-1),
        dict(legs=(0, 20), knees=(40, 100), arms=(5, 0), elbows=(90, 80), bob=-2),
        dict(legs=(-35, 45), knees=(60, 10), arms=(45, -40), elbows=(80, 90), bob=0),
        dict(legs=(-10, 25), knees=(95, 15), arms=(25, -20), elbows=(80, 90), bob=-1),
        dict(legs=(20, 0), knees=(100, 40), arms=(0, 5), elbows=(80, 90), bob=-2)]
for f in RUN6:
    f['tilt'] = 8
BIG_POSES = [
    ('brun0', dict(RUN6[0], can='hand')), ('brun1', dict(RUN6[1], can='hand')),
    ('brun2', dict(RUN6[2], can='hand')), ('brun3', dict(RUN6[3], can='hand')),
    ('brun4', dict(RUN6[4], can='hand')), ('brun5', dict(RUN6[5], can='hand')),
    # take-off / rising: knees up, can arm flung high
    ('bjump', dict(legs=(70, -20), knees=(110, 70), arms=(-130, 150), elbows=(10, 30), bob=-3, tilt=6,
                   can='hand')),
    # falling: legs reach for the ground
    ('bfall', dict(legs=(35, -15), knees=(20, 50), arms=(-110, 120), elbows=(20, 40), bob=-1, tilt=2,
                   can='hand', eyes='wide')),
    # walking sip: head back, can up, legs mid-stride
    ('bsip0', dict(legs=(22, -18), knees=(0, 25), arms=(-15, 140), elbows=(0, 50), tilt=-6, head_back=30,
                   can='mouth', eyes='shut')),
    ('bsip1', dict(legs=(-14, 16), knees=(25, 0), arms=(-5, 140), elbows=(0, 50), tilt=-6, head_back=30,
                   bob=-1, can='mouth', eyes='shut')),
    # air sip: tucked jump, chugging
    ('bairsip', dict(legs=(80, 10), knees=(120, 110), arms=(-60, 140), elbows=(40, 50), bob=-3, tilt=-4,
                     head_back=30, can='mouth', eyes='shut')),
    # trip: toe caught, pitching forward, arms out
    ('btrip0', dict(legs=(10, -60), knees=(0, -20), arms=(150, 110), elbows=(10, 0), tilt=35, bob=1,
                    eyes='wide')),
    # mid-tumble: nearly flat, diving
    ('btrip1', dict(legs=(-80, -100), knees=(0, -30), arms=(120, 100), elbows=(0, 0), tilt=75, hip=(10, 32),
                    eyes='wide')),
    # back up on one knee, shaking it off
    ('btrip2', dict(legs=(60, -80), knees=(100, -10), arms=(40, 60), elbows=(30, 30), tilt=25, hip=(13, 30),
                    eyes='shut')),
]


def build_runner():
    """Second sprite sheet (160 rows, 320 tiles) loaded after the props sheet;
    it lives in the event's code bank (the graphics bank is full)."""
    sh = Sheet(160)
    cells = []
    for n, (name, pose) in enumerate(BIG_POSES):
        x, y = (n % 4) * RW, (n // 4) * RH
        big_person(sh, x, y, **pose)
        cells.append((name, x, y, RW, RH, 15, RH - 1))
    n = len(BIG_POSES)
    x, y = (n % 4) * RW, (n // 4) * RH
    big_fallen(sh, x, y)
    cells.append(('bfallen', x, y, 64, RH, 30, RH - 1))
    for c in cells:
        sh.obj(*c)
    out('cops_run.bin', sh.tiles())
    return sh


def build_sprites():
    sh = Sheet(96)
    d = sh.draw()
    for i, f in enumerate(P.RUN):
        P.draw_person(sh, i * 16, 0, item=P.tallboy, **f)
    P.draw_person(sh, 64, 0, item=P.tallboy, **P.JUMP)
    P.draw_person(sh, 80, 0, item=P.tallboy, **P.SIP)
    P.draw_person(sh, 96, 0, **P.STUMBLE)
    draw_cop(sh, 0, 32, 0)
    draw_cop(sh, 32, 32, 1)
    draw_raccoon(sh, 64, 32, 0)
    draw_raccoon(sh, 80, 32, 1)
    # green bin 16x32 at (96,32): a full-height Toronto green bin (too tall to hop: big jump)
    d.rectangle([98, 37, 109, 63], fill=6)
    d.rectangle([98, 37, 100, 63], fill=7)
    d.rectangle([97, 33, 110, 37], fill=7)
    d.rectangle([102, 32, 105, 33], fill=7)
    d.rectangle([101, 44, 106, 48], fill=5)
    d.line([101, 52, 106, 52], fill=7)
    d.ellipse([99, 61, 102, 63], fill=4)
    d.ellipse([106, 61, 109, 63], fill=4)
    sh.outline(96, 32, 16, 32)
    # crates of fruit 32x16 at (0,64)
    for k in range(2):
        x = 2 + k * 14
        d.rectangle([x, 70, x + 12, 79], fill=8)
        d.line([x, 74, x + 12, 74], fill=9)
        fr = (10, 11)[k]
        for j in range(4):
            d.ellipse([x + 1 + j * 3, 66, x + 4 + j * 3, 69], fill=fr)
    d.rectangle([9, 64, 21, 69], fill=8)
    for j in range(4):
        d.ellipse([10 + j * 3, 61 if False else 64, 13 + j * 3, 67], fill=12)
    sh.outline(0, 64, 32, 16)
    # bench 32x16 at (32,64)
    d.rectangle([33, 68, 62, 70], fill=8)
    d.rectangle([33, 72, 62, 73], fill=9)
    d.rectangle([35, 74, 36, 79], fill=4)
    d.rectangle([59, 74, 60, 79], fill=4)
    d.rectangle([33, 65, 62, 66], fill=9)
    sh.outline(32, 64, 32, 16)
    P.draw_fallen(sh, 64, 64)
    # can icon, siren, splash
    d.rectangle([97, 65, 102, 71], fill=13)
    d.line([97, 65, 102, 65], fill=15)
    d.rectangle([106, 66, 109, 69], fill=10)
    d.point((107, 65), fill=5)
    for (x, y) in ((116, 70), (120, 66), (124, 71), (118, 74), (122, 76)):
        d.ellipse([x - 1, y - 1, x + 1, y + 1], fill=13)
    # obstacle warnings at the right edge: "!" sign (hop it), red up-arrow (big jump)
    d.polygon([(7, 81), (14, 88), (14, 89), (7, 96 - 1), (1, 89), (1, 88)], fill=13)
    d.rectangle([7, 84, 8, 89], fill=4)
    d.rectangle([7, 91, 8, 92], fill=4)
    sh.outline(0, 80, 16, 16)
    d.polygon([(23, 81), (30, 88), (26, 88), (26, 94), (20, 94), (20, 88), (16 + 0, 88)], fill=10)
    d.line([(21, 89), (21, 93)], fill=11)
    d.line([(23, 83), (27, 87)], fill=11)
    sh.outline(16, 80, 16, 16)
    # chalk take-off marks on the pavement (jump when you reach one): a fat
    # yellow chevron = tap A (hop), two red ones = hold A (big jump)
    def chevron(x0, y0, fill, edge):
        for i in range(7):
            for dy in range(3):
                d.point((x0 + i, y0 + 7 - i + dy), fill=fill)
                d.point((x0 + 14 - i, y0 + 7 - i + dy), fill=fill)
        d.point((x0 + 7, y0), fill=fill)
        d.point((x0 + 7, y0 + 1), fill=fill)
        d.point((x0 + 7, y0 + 2), fill=fill)
        for i in range(7):
            d.point((x0 + i, y0 + 7 - i), fill=edge)
            d.point((x0 + 14 - i, y0 + 7 - i), fill=edge)
        d.point((x0 + 7, y0), fill=edge)
    chevron(32, 83, 13, 11)
    chevron(48, 80, 10, 11)
    chevron(48, 86, 10, 11)
    names = [('run0', 0), ('run1', 16), ('run2', 32), ('run3', 48), ('jump', 64), ('sip', 80), ('stumble', 96)]
    for n, x in names:
        sh.obj(n, x, 0, 16, 32, 8, 31)
    sh.obj('cop0', 0, 32, 32, 32, 16, 31)
    sh.obj('cop1', 32, 32, 32, 32, 16, 31)
    sh.obj('coon0', 64, 32, 16, 16, 8, 15)
    sh.obj('coon1', 80, 32, 16, 16, 8, 15)
    sh.obj('bin', 96, 32, 16, 32, 8, 31)
    sh.obj('crates', 0, 64, 32, 16, 16, 15)
    sh.obj('bench', 32, 64, 32, 16, 16, 15)
    sh.obj('fallen', 64, 64, 32, 16, 16, 15)
    sh.obj('can', 96, 64, 8, 8, 4, 4)
    sh.obj('siren', 104, 64, 8, 8, 4, 4)
    sh.obj('splash', 112, 64, 16, 16, 8, 8)
    sh.obj('warn_lo', 0, 80, 16, 16, 8, 15)
    sh.obj('warn_hi', 16, 80, 16, 16, 8, 15)
    sh.obj('mark_lo', 32, 80, 16, 16, 8, 8)
    sh.obj('mark_hi', 48, 80, 16, 16, 8, 8)
    out('cops_spr.bin', sh.tiles())
    run = build_runner()
    base2 = (sh.img.size[1] // 8) * 16          # the runner sheet's first tile
    meta2 = []
    for line in run.meta_inc().splitlines():
        if line.endswith('_BASE = ' + line.split(' = ')[-1]) and line.startswith('MS_'):
            k, v = line.split(' = ')
            line = '%s = %d' % (k, int(v) + base2)
        meta2.append(line)
    with open('build/cops_meta.inc', 'w') as f:
        f.write(sh.meta_inc())
        f.write('RUN_VRAM = $%04X\n' % (0x6000 + base2 * 16))
        f.write('\n'.join(meta2) + '\n')
    pv = Image.new('RGBA', (128, 160), rgb('#a8a0a0'))
    pv.alpha_composite(render(run, (0, 0, 128, 160), P.ATHLETE))
    preview(pv, 'cops_runner.png', 4)
    data = pal_bytes([hexrgb(c) for c in COP], 16) + pal_bytes([hexrgb(c) for c in PROPS], 16)
    out('cops_spr_pal.bin', data)       # sprite palettes 1, 2
    # COP_ALT (navy patrol jacket for players in yellow) lives in ev_cops.s as cop_alt_pal
    return sh


def build():
    far = far_layer()
    near = near_layer()
    both = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    both.paste(far, (0, 0))
    both.paste(near, (0, 256))
    pals = build_palettes(both, 6)
    ts = TileSet(4)
    m_far = convert_bg(far, pals, 2, ts)
    m_near = convert_bg(near, pals, 2, ts)
    out('cops_tiles.bin', ts.data())
    out('cops_bg1.bin', map_bytes(m_near)[:4096])
    out('cops_bg2.bin', map_bytes(m_far)[:4096])
    data = bytearray()
    for p in pals:
        data += pal_bytes(p, 16)
    data += bytes(32 * (6 - len(pals)))
    out('cops_pal.bin', data)
    hdma_gradient([(0, '#f07848'), (60, '#f8a868'), (110, '#f8d8a0'), (140, '#f8e8c0')], 'cops_sky.bin')
    sh = build_sprites()
    view = Image.new('RGBA', (256, 224), rgb('#f8b070'))
    view.alpha_composite(far.crop((0, 0, 256, 224)))
    view.alpha_composite(near.crop((0, 0, 256, 224)))
    view.alpha_composite(render(sh, (0, 0, 16, 32), P.ATHLETE), (110, GROUND - 31))
    view.alpha_composite(render(sh, (0, 32, 32, 32), COP), (20, GROUND - 31))
    view.alpha_composite(render(sh, (64, 32, 16, 16), PROPS), (170, GROUND - 15))
    view.alpha_composite(render(sh, (96, 32, 16, 32), PROPS), (200, GROUND - 31))
    view.alpha_composite(render(sh, (0, 64, 32, 16), PROPS), (225, GROUND - 15))
    preview(view, 'cops.png')
    return '%d tiles, %d pals' % (len(ts), len(pals))


if __name__ == '__main__':
    print(build())
