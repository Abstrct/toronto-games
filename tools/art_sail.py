"""Harbour Regatta: top-down Toronto harbour, 512x512 (64x64 tile map).

The city's condo wall and the CN Tower along the north shore, the Western
breakwater and Billy Bishop to the west, the Port Lands quay (with a laker
tied up) to the east, the Islands to the south. Water colours sit at fixed
CGRAM slots for palette cycling; a land bitmap drives collision.

Sprites: the dinghy in 16 headings x 2 tacks, numbered marks, the Island
ferry (double-ended, runs Bay St <-> Centre Island), Canada geese, kayaks,
cat's-paw gust ripples, the no-go wedge ticks; plus 2bpp wind-arrow tiles
for the HUD panel and build/sail_layout.inc (course constants for the asm).
"""
import math
import os
import random
from PIL import Image, ImageDraw
from snes import (TileSet, convert_bg, build_palettes, map_bytes, pal_bytes, hexrgb, snap,
                  tile_bytes, out, preview, BUILD)
from sprites import Sheet, render
import people as P

W = H = 512
WATER = ['#1850a8', '#2464b8', '#3c80d0', '#78b4e8']   # base + 3 cycling wave colours (dark, mid, glint)

# ---------------------------------------------------------------- layout
CITY_Y = 96          # first water row under the seawall
WEST_X = 32          # breakwater
EAST_X = 480         # Port Lands quay
FERRY_X = 356        # ferry lane: Bay St slip <-> Centre Island dock
FERRY_Y0, FERRY_Y1 = 122, 418
# leg 1 is a reach (mark 1 is in view from the start), leg 2 the beat (tacking),
# leg 3 the run past the ferry lane (surf its wake), leg 4 a reach to the line
MARKS = [(300, 300), (270, 128), (410, 388)]   # reach, windward, leeward
LINE_X, LINE_Y, LINE_HALF = 184, 380, 40
START = (112, 308)                               # open water, sea room all round
FREIGHTER = (456, 168, 479, 327)


def island_top(x):
    return 468 + int(5 * math.sin(x / 40.0) + 3 * math.sin(x / 13.0))


def rgb(h):
    return snap(hexrgb(h)) + (255,)


C = {k: rgb(v) for k, v in {
    'sand': '#e8d498', 'sand2': '#d0b878', 'wet': '#b8a070',
    'grass': '#4c9a3c', 'grass2': '#3e8634', 't1': '#1e5a26', 't2': '#2c7432', 't3': '#46923e',
    'wall': '#a8a8b0', 'wall2': '#787880', 'deck': '#a07040', 'deck2': '#6a4420',
    'white': '#f0f0f0', 'red': '#d03030', 'path': '#d8c8a0',
    # city
    'far': '#56647e', 'far2': '#46526c', 'farlit': '#8898b4',
    'glass': '#3c7890', 'glass2': '#2c5870', 'glasshi': '#78b0c0',
    'blue': '#4c64a0', 'blue2': '#36487c', 'conc': '#b8b4a8', 'conc2': '#8c887c',
    'brick': '#9c4c38', 'brick2': '#743428', 'lit': '#c8e0f0', 'dark': '#182030',
    'cn': '#c8c0b0', 'cn2': '#8c8478', 'dome': '#e0e0e8', 'dome2': '#a0a0b0',
    'prom': '#c8bca0', 'prom2': '#a89c80',
    # edges
    'rock': '#7c7880', 'rock2': '#5a5660', 'rock3': '#a0a0a8',
    'tarmac': '#58585c', 'tarmac2': '#6c6c70',
    'hull': '#8c2c20', 'hull2': '#601c14', 'hatch': '#38383c', 'bridge': '#e8e8e8',
}.items()}
# keep the land to 6 palettes: share colours between features
for a, b in (('cn', 'conc'), ('cn2', 'conc2'), ('dome', 'white'), ('dome2', 'conc2'), ('glasshi', 'farlit'),
             ('hull', 'brick'), ('hull2', 'brick2'), ('tarmac', 'rock2'), ('tarmac2', 'rock'),
             ('prom', 'path'), ('prom2', 'sand2'), ('hatch', 'dark'), ('bridge', 'white')):
    C[a] = C[b]
solid = set()


def mark(x0, y0, x1, y1):
    for ty in range(max(0, y0 // 8), min(H // 8, y1 // 8 + 1)):
        for tx in range(max(0, x0 // 8), min(W // 8, x1 // 8 + 1)):
            solid.add((tx, ty))


def water(img):
    px = img.load()
    w = [rgb(c) for c in WATER]
    for y in range(H):
        for x in range(W):
            c = w[0]
            u = (x + 2 * (y // 16)) % 32
            v = y % 16
            if v == 4 and 4 <= u < 13:
                c = w[1 + ((u - 4) // 3) % 3]
            elif v == 12 and 20 <= u < 29:
                c = w[1 + ((u - 20) // 3) % 3]
            px[x, y] = c


def tree(d, cx, cy, r=8):
    d.ellipse([cx - r, cy - r, cx + r, cy + r - 2], fill=C['t1'])
    d.ellipse([cx - r + 1, cy - r, cx + r - 3, cy + r - 5], fill=C['t2'])
    d.ellipse([cx - r // 2, cy - r + 1, cx, cy - r // 4], fill=C['t3'])


# window patterns: 8x8 facade cells, so towers tile well
def facade(d, x0, y0, x1, y1, base, shade, win, lit, rnd, edge=True):
    d.rectangle([x0, y0, x1, y1], fill=base)
    for y in range(y0 + 8, y1 - 3, 4):
        for x in range(x0 + 2, x1 - 1, 4):
            c = lit if rnd.random() < 0.18 else win
            d.rectangle([x, y, x + 1, y + 1], fill=c)
    if edge:
        d.rectangle([x1 - 1, y0, x1, y1], fill=shade)
    d.rectangle([x0, y0, x1, y0 + 3], fill=shade)


def city(img):
    d = ImageDraw.Draw(img)
    rnd = random.Random(416)
    base_y = 79
    d.rectangle([0, 0, W - 1, base_y], fill=C['far'])
    # back row: dim towers all the way up
    x = 0
    while x < W:
        w = rnd.choice((16, 24, 32))
        top = 12 + rnd.randrange(0, 28) // 4 * 4
        facade(d, x, top, x + w - 1, base_y, C['far'], C['dark'], C['far2'], C['farlit'], rnd)
        x += w
    # front row: the condo wall, glass and concrete, bases on the water
    styles = [('glass', 'glass2', 'glasshi'), ('blue', 'blue2', 'glasshi'), ('conc', 'conc2', 'glass2'),
              ('glass', 'glass2', 'dark'), ('brick', 'brick2', 'dark')]
    x = 0
    while x < W:
        w = rnd.choice((24, 32, 32, 40))
        if 96 <= x < 200:          # leave room for the dome and the CN Tower
            x += 8
            continue
        top = 40 + rnd.randrange(0, 24) // 8 * 8
        b, s, wn = styles[rnd.randrange(len(styles))]
        facade(d, x, top, x + w - 1, base_y, C[b], C[s], C[wn], C['lit'], rnd)
        x += w + rnd.choice((0, 0, 8))
    # Rogers Centre dome (west of the tower, as seen from the lake)
    dx0 = 98
    d.ellipse([dx0 + 4, 50, dx0 + 60, 96], fill=C['dome2'])
    d.ellipse([dx0 + 6, 50, dx0 + 58, 92], fill=C['dome'])
    for k in range(4):
        d.arc([dx0 + 6 + k * 7, 50, dx0 + 58 - k * 7, 92], 180, 360, fill=C['dome2'])
    d.rectangle([dx0, 72, dx0 + 64, base_y], fill=C['conc2'])
    d.rectangle([dx0, 72, dx0 + 64, 73], fill=C['dark'])
    # the CN Tower: shaft, main pod, SkyPod, antenna
    cx = 182
    d.polygon([(cx - 6, base_y), (cx + 6, base_y), (cx + 2, 18), (cx - 2, 18)], fill=C['cn'])
    d.polygon([(cx + 1, base_y), (cx + 6, base_y), (cx + 2, 18), (cx + 1, 18)], fill=C['cn2'])
    d.ellipse([cx - 12, 52, cx + 12, 64], fill=C['cn2'])
    d.ellipse([cx - 12, 50, cx + 12, 61], fill=C['cn'])
    d.rectangle([cx - 11, 55, cx + 11, 57], fill=C['dark'])
    d.ellipse([cx - 4, 36, cx + 4, 42], fill=C['cn'])
    d.line([cx, 14, cx, 36], fill=C['white'])
    d.point((cx, 14), fill=C['red'])
    # Redpath: a long low sugar warehouse with the red sign band
    d.rectangle([408, 56, 463, base_y], fill=C['conc'])
    d.rectangle([408, 56, 463, 59], fill=C['conc2'])
    d.rectangle([412, 64, 459, 68], fill=C['red'])
    # promenade and seawall
    d.rectangle([0, 80, W - 1, 91], fill=C['prom'])
    for x in range(0, W, 8):
        d.point((x + 3, 82), fill=C['prom2'])
    d.rectangle([0, 92, W - 1, 95], fill=C['wall2'])
    d.line([0, 92, W - 1, 92], fill=C['wall'])
    for x in range(16, W, 48):
        if not (330 <= x <= 380):
            tree(d, x, 87, 5)
    mark(0, 0, W - 1, CITY_Y - 1)
    # Jack Layton ferry terminal slip
    d.rectangle([FERRY_X - 22, 80, FERRY_X - 17, 103], fill=C['deck'])
    d.rectangle([FERRY_X + 17, 80, FERRY_X + 22, 103], fill=C['deck'])
    d.line([FERRY_X - 17, 80, FERRY_X - 17, 103], fill=C['deck2'])
    d.line([FERRY_X + 22, 80, FERRY_X + 22, 103], fill=C['deck2'])
    mark(FERRY_X - 22, 80, FERRY_X - 17, 103)
    mark(FERRY_X + 17, 80, FERRY_X + 22, 103)


def rocks(d, x0, y0, x1, y1, rnd):
    d.rectangle([x0, y0, x1, y1], fill=C['rock2'])
    for _ in range((x1 - x0) * (y1 - y0) // 30):
        x = rnd.randrange(x0, x1)
        y = rnd.randrange(y0, y1)
        r = rnd.randrange(2, 5)
        if x - r < x0 or x + r > x1 or y - r < y0 or y + r > y1:
            continue
        d.ellipse([x - r, y - r, x + r, y + r], fill=C['rock'])
        d.point((x - 1, y - 1), fill=C['rock3'])


def harbour():
    img = Image.new('RGBA', (W, H), (0, 0, 0, 255))
    water(img)
    d = ImageDraw.Draw(img)
    rnd = random.Random(8)
    city(img)
    # the Islands along the bottom
    for x in range(W):
        t = island_top(x)
        for y in range(t, H):
            k = y - t
            col = C['wet'] if k < 2 else (C['sand'] if k < 12 else (C['sand2'] if k < 14 else C['grass']))
            d.point((x, y), fill=col)
    for x in range(140, W, 28):
        tree(d, x + rnd.randrange(-4, 5), 498 + rnd.randrange(-3, 4))
    for x in range(W):
        mark(x, island_top(x) + 2, x, H - 1)
    # Gibraltar Point lighthouse
    d.ellipse([150, 488, 162, 500], fill=C['white'])
    d.ellipse([153, 491, 159, 497], fill=C['red'])
    # Centre Island ferry dock
    d.rectangle([FERRY_X - 22, 444, FERRY_X - 17, 476], fill=C['deck'])
    d.rectangle([FERRY_X + 17, 444, FERRY_X + 22, 476], fill=C['deck'])
    d.rectangle([FERRY_X - 22, 470, FERRY_X + 22, 478], fill=C['deck'])
    d.line([FERRY_X - 22, 444, FERRY_X + 22, 444], fill=C['deck2'])
    mark(FERRY_X - 22, 444, FERRY_X - 17, 476)
    mark(FERRY_X + 17, 444, FERRY_X + 22, 476)
    # Western breakwater
    rocks(d, 0, CITY_Y, WEST_X - 1, H - 1, rnd)
    d.line([WEST_X - 1, CITY_Y, WEST_X - 1, H - 1], fill=C['rock3'])
    mark(0, CITY_Y, WEST_X - 1, H - 1)
    # Billy Bishop: runway end in the south-west
    d.rectangle([0, 424, 111, H - 1], fill=C['tarmac'])
    d.rectangle([0, 424, 111, 427], fill=C['rock2'])
    d.rectangle([108, 424, 111, H - 1], fill=C['rock2'])
    for x in range(4, 100, 16):
        d.rectangle([x, 462, x + 7, 463], fill=C['white'])
    for x in range(8, 100, 8):
        d.point((x, 440), fill=C['tarmac2'])
        d.point((x + 4, 486), fill=C['tarmac2'])
    mark(0, 424, 111, H - 1)
    # Port Lands quay and a laker tied up alongside
    d.rectangle([EAST_X, CITY_Y, W - 1, H - 1], fill=C['conc2'])
    d.rectangle([EAST_X, CITY_Y, EAST_X + 2, H - 1], fill=C['conc'])
    for y in range(CITY_Y + 12, H, 24):
        d.rectangle([EAST_X + 6, y, EAST_X + 8, y + 2], fill=C['dark'])
    for cy in (140, 360, 400):
        d.ellipse([EAST_X + 10, cy - 10, EAST_X + 30, cy + 10], fill=C['conc'])
        d.ellipse([EAST_X + 13, cy - 7, EAST_X + 27, cy + 7], fill=C['wall'])
    x0, y0, x1, y1 = FREIGHTER
    d.rounded_rectangle([x0, y0, x1, y1], radius=10, fill=C['hull2'])
    d.rounded_rectangle([x0 + 1, y0 + 1, x1 - 1, y1 - 1], radius=9, fill=C['hull'])
    for y in range(y0 + 14, y1 - 40, 20):
        d.rectangle([x0 + 6, y, x1 - 6, y + 13], fill=C['hatch'])
    d.rectangle([x0 + 5, y1 - 30, x1 - 5, y1 - 12], fill=C['bridge'])
    d.rectangle([x0 + 8, y1 - 26, x1 - 8, y1 - 24], fill=C['dark'])
    mark(x0, y0, W - 1, y1)
    mark(EAST_X, CITY_Y, W - 1, H - 1)
    return img


# ---------------------------------------------------------------- sprites
SP_MARKS = ['#000000', '#101018', '#f87818', '#c04808', '#f8f8f8', '#f8e040', '#283048', '#a0a0b0',
            '#d03030', '#60a0e0', '#f8b878', '#202020']
SP_FERRY = ['#000000', '#101018', '#f0f0f0', '#b8b8c8', '#2850a0', '#182c60', '#e8c040', '#d03030',
            '#383848', '#f8b080', '#7890b0']
SP_CRITTERS = ['#000000', '#101018', '#8c7458', '#5c4834', '#f0f0f0', '#181818', '#f8d020', '#e83820',
               '#a02010', '#80b8e8', '#f8c890', '#c89838']
SP_ARROWS = ['#000000', '#101018', '#f8f8f8', '#a8b8c8', '#f8e040', '#c09010', '#f84030', '#0c3478',
             '#1a4890', '#a8d0f8', '#f8f8f8']


def rot(x, y, a):
    return (x * math.cos(a) - y * math.sin(a), x * math.sin(a) + y * math.cos(a))


def _reduce(sh, big, x0, y0, n, S):
    """Majority-vote an n*S square 'P' image down to n x n onto the sheet."""
    bp = big.load()
    for y in range(n):
        for x in range(n):
            votes = {}
            for yy in range(S):
                for xx in range(S):
                    v = bp[x * S + xx, y * S + yy]
                    votes[v] = votes.get(v, 0) + 1
            nz = sum(k for v, k in votes.items() if v)
            if nz * 2 >= S * S:
                v = max((k, v) for v, k in votes.items() if v)[1]
                sh.px(x0 + x, y0 + y, v)


BOAT_FRAMES = 9          # headings 0..8 (N..S through E) per sail side; W headings are mirrors


def draw_boat(sh, x0, y0, heading, side):
    """A Laser-ish dinghy filling a 32x32 cell, seen from above. The hull is the
    big shape, in the jersey colour, with a sharp bow, a white foredeck that
    points forward, a square transom with the rudder sticking out astern. The
    sail is a thin curved white band from the mast out to leeward (side +1 =
    starboard), so it never reads as the bow. The helmsman is a separate sprite.
    Drawn at 4x and reduced (majority vote), then outlined."""
    S = 4
    N = 32
    big = Image.new('P', (N * S, N * S), 0)
    d = ImageDraw.Draw(big)
    a = heading * math.pi / 8
    c = N // 2 * S
    R = lambda pts: [(c + p[0] * S, c + p[1] * S) for p in (rot(x, y, a) for x, y in pts)]
    hull = [(0, -14.5), (1.7, -12), (3.5, -8), (4.9, -3), (5.5, 2), (5.4, 7), (4.9, 11.5),
            (-4.9, 11.5), (-5.4, 7), (-5.5, 2), (-4.9, -3), (-3.5, -8), (-1.7, -12)]
    inner = [(x * 0.74, y * 0.9 - 0.4) for x, y in hull]
    d.line(R([(0, 11), (0, 15.2)]), fill=1, width=int(1.6 * S))               # rudder astern
    d.polygon(R(hull), fill=6)                                                # gunwale (shade)
    d.polygon(R(inner), fill=5)                                               # deck, jersey colour
    d.polygon(R([(0, -13.2), (2.4, -7.5), (2.9, -4.8), (-2.9, -4.8), (-2.4, -7.5)]), fill=10)  # white foredeck
    d.polygon(R([(2.3, 2.5), (2.5, 8.5), (1.8, 10.0), (-1.8, 10.0), (-2.5, 8.5), (-2.3, 2.5)]), fill=11)  # cockpit
    d.polygon(R([(-4.6, 11.0), (4.6, 11.0), (4.6, 12.0), (-4.6, 12.0)]), fill=1)  # transom
    # sail: a curved band from the mast to the boom end, out to leeward
    m = (0, -2.6)
    ba = -side * math.radians(42)
    band = []
    for k in range(9):
        t = k / 8
        bx, by = rot(side * 3.4 * math.sin(math.pi * t), 13.0 * t, ba)
        band.append((m[0] + bx, m[1] + by))
    inner_edge = []
    for k in range(9):
        t = k / 8
        bx, by = rot(side * (3.4 * math.sin(math.pi * t) - 2.6 * math.sin(math.pi * t) ** 0.5), 13.0 * t, ba)
        inner_edge.append((m[0] + bx, m[1] + by))
    d.polygon(R(band + inner_edge[::-1]), fill=10)                            # white sail
    d.line(R(inner_edge), fill=15, width=S)                                   # boom / shadow
    d.ellipse([p - S * 1.2 for p in R([m])[0]] + [p + S * 1.2 for p in R([m])[0]], fill=1)  # mast
    _reduce(sh, big, x0, y0, N, S)
    sh.outline(x0, y0, N, N, 1)


def draw_crew(sh, x0, y0, k):
    """The helmsman from above: hair on top, navy buoyancy aid round the
    shoulders (round, so it works at every heading). k=1: hiking, stretched."""
    d = sh.draw()
    cx, cy = x0 + 8, y0 + 8
    if k == 0:
        d.ellipse([cx - 3, cy - 3, cx + 2, cy + 2], fill=8)
    else:                                    # hiking: stretched out, hands on the sheet
        d.ellipse([cx - 4, cy - 3, cx + 3, cy + 2], fill=8)
        d.point((cx - 4, cy - 1), fill=2)
        d.point((cx + 3, cy - 1), fill=2)
    d.ellipse([cx - 2, cy - 2, cx + 1, cy + 1], fill=4)
    d.point((cx - 1, cy - 1), fill=3)
    sh.outline(x0, y0, 16, 16, 1)


def draw_arrow(sh, x0, y0, k, fill, outline):
    d = sh.draw()
    a = k * math.pi / 8
    shape = [(0, -7), (6, 0), (2, 0), (2, 6), (-2, 6), (-2, 0), (-6, 0)]
    pts = [(x0 + 7.5 + p[0], y0 + 7.5 + p[1]) for p in (rot(x, y, a) for x, y in shape)]
    d.polygon(pts, fill=fill, outline=outline)


DIGITS = {1: ['.#.', '##.', '.#.', '.#.', '###'],
          2: ['##.', '..#', '.#.', '#..', '###'],
          3: ['##.', '..#', '.#.', '..#', '##.']}


def build_sprites():
    """Sheet 128x256 = all 512 OBJ tiles:
    y 0-159   boat: 18 frames of 32x32 (9 headings x 2 sail sides)
    (64..127, 128..159)  crew x2, foam x2, 8x8 helpers
    y 160     marks, geese, kayaks, pin, splash
    y 176-207 pointer arrows, 16 directions
    y 208-255 ferry, committee boat, cat's paws, ferry wake"""
    sh = Sheet(256)
    d = sh.draw()
    for side_i, side in enumerate((1, -1)):
        for h in range(BOAT_FRAMES):
            n = side_i * BOAT_FRAMES + h
            draw_boat(sh, (n % 4) * 32, (n // 4) * 32, h, side)
    for k in range(2):
        draw_crew(sh, 64 + k * 16, 128, k)
    # wake foam (marks palette: 4 white, 9 light blue), big and fading
    for (x, y, c) in ((99, 134, 9), (102, 132, 4), (104, 134, 4), (106, 132, 9), (101, 136, 4),
                      (105, 137, 9), (103, 135, 9), (100, 131, 9), (107, 135, 4)):
        sh.px(x, y, c)
    for (x, y, c) in ((118, 134, 9), (120, 133, 4), (121, 135, 9), (119, 136, 9)):
        sh.px(x, y, c)
    # 8x8 helpers on row 144: tick, tickred, ldot, fleck, num1..3
    d.rectangle([66, 146, 69, 149], fill=2, outline=1)
    d.rectangle([74, 146, 77, 149], fill=6, outline=1)
    d.rectangle([83, 147, 84, 148], fill=2)
    d.point((84, 148), fill=1)
    d.line([89, 148, 92, 148], fill=9)
    d.point((90, 147), fill=10)
    for n in (1, 2, 3):
        x0 = 96 + (n - 1) * 8
        d.rectangle([x0 + 1, 144, x0 + 5, 150], fill=4)
        d.rectangle([x0, 145, x0 + 6, 149], fill=4)
        for yy, r in enumerate(DIGITS[n]):
            for xx, ch in enumerate(r):
                if ch == '#':
                    sh.px(x0 + 2 + xx, 145 + yy, 1)
    Y = 160
    # marks: a big orange inflatable buoy seen from above, 2 bob frames
    for k in range(2):
        x0 = k * 16
        d.ellipse([x0 + 1, Y + 2, x0 + 14, Y + 15], fill=11)
        d.ellipse([x0 + 1, Y + 1 + k, x0 + 14, Y + 13 + k], fill=2, outline=1)
        d.ellipse([x0 + 3, Y + 3 + k, x0 + 10, Y + 8 + k], fill=10)
        d.line([x0 + 2, Y + 7 + k, x0 + 13, Y + 7 + k], fill=4)
        d.ellipse([x0 + 0, Y + 11, x0 + 15, Y + 15], outline=9)
    # Canada geese, top-down: brown body, black neck, white chinstrap, V-wake
    for k in range(2):
        x0 = 32 + k * 16
        d.line([x0 + 3, Y + 15, x0 + 7, Y + 11], fill=9)
        d.line([x0 + 12, Y + 15, x0 + 8, Y + 11], fill=9)
        d.ellipse([x0 + 4, Y + 5, x0 + 11, Y + 13], fill=3)
        d.ellipse([x0 + 5, Y + 5, x0 + 10, Y + 11], fill=2)
        d.line([x0 + 6 + k, Y + 6, x0 + 7 + k, Y + 1], fill=5, width=2)
        d.point((x0 + 7 + k, Y + 2), fill=4)
        d.point((x0 + 8 + k, Y + 2), fill=4)
        d.point((x0 + 7 + k, Y + 0), fill=5)
    # kayak, horizontal (paddles east), red with a yellow-shirted paddler
    for k in range(2):
        x0 = 64 + k * 16
        d.ellipse([x0 + 0, Y + 6, x0 + 15, Y + 9], fill=7, outline=8)
        d.ellipse([x0 + 6, Y + 6, x0 + 9, Y + 9], fill=6)
        d.point((x0 + 8, Y + 7), fill=10)
        if k == 0:
            d.line([x0 + 5, Y + 2, x0 + 10, Y + 13], fill=5)
        else:
            d.line([x0 + 10, Y + 2, x0 + 5, Y + 13], fill=5)
        d.line([x0 + 1, Y + 10, x0 + 4, Y + 11], fill=9)
    # pin buoy, splash
    d.ellipse([99, Y + 3, 107, Y + 11], fill=5, outline=1)
    d.ellipse([101, Y + 5, 105, Y + 9], fill=8)
    for (x, y) in ((116, 6), (120, 3), (123, 8), (118, 11)):
        d.point((x, Y + y), fill=4)
    # mark pointer: yellow arrows, 16 directions
    for k in range(16):
        draw_arrow(sh, (k % 8) * 16, 176 + (k // 8) * 16, k, 4, 1)
    # the Island ferry, double-ended, 32x48 at (0,208), bow up/down
    F = 208 - 96
    d.rounded_rectangle([5, 97 + F, 26, 142 + F], radius=8, fill=2, outline=1)
    d.rectangle([6, 108 + F, 25, 131 + F], fill=4)
    d.rectangle([9, 104 + F, 22, 135 + F], fill=3, outline=1)
    d.rectangle([12, 110 + F, 19, 129 + F], fill=2, outline=10)
    d.rectangle([14, 116 + F, 17, 123 + F], fill=7)
    for y in range(106, 136, 3):
        d.point((9, y + F), fill=9)
        d.point((22, y + F), fill=9)
    d.rectangle([13, 99 + F, 18, 100 + F], fill=6)
    d.rectangle([13, 139 + F, 18, 140 + F], fill=6)
    # paddle boxes amidships (the Trillium is a sidewheeler)
    d.rectangle([3, 114 + F, 5, 125 + F], fill=8, outline=1)
    d.rectangle([26, 114 + F, 28, 125 + F], fill=8, outline=1)
    # committee boat 32x16 at (32,208)
    d.rounded_rectangle([33, 211, 62, 221], radius=4, fill=4, outline=1)
    d.rectangle([42, 213, 54, 219], fill=2)
    d.line([48, 210, 48, 212], fill=1)
    d.rectangle([49, 208, 53, 210], fill=8)
    # cat's paw ripples (gusts): dark patches of short arcs, 2 frames (arrows palette)
    for k in range(2):
        x0 = 64 + k * 16
        r2 = random.Random(5 + k)
        for _ in range(9):
            x = x0 + r2.randrange(1, 13)
            y = 209 + r2.randrange(1, 13)
            d.line([x, y, x + 2, y], fill=7)
            d.point((x + 1, y - 1), fill=8)
        for _ in range(3):
            x = x0 + r2.randrange(2, 13)
            y = 209 + r2.randrange(2, 13)
            d.point((x, y), fill=9)
    # ferry wake (ferry palette: 2 white, 10 grey-blue): a churned V astern of
    # the paddle wheels, 32x16, 2 frames; drawn below a northbound ferry
    for k in range(2):
        x0, y0 = 32 + k * 32, 224
        for j in range(16):
            spread = 5 + j * 0.68
            ph = (j // 2 + k) % 2
            for sgn in (-1, 1):
                x = int(round(x0 + 15.5 + sgn * spread))
                if x0 <= x < x0 + 32:
                    sh.px(x, y0 + j, 2 if ph == 0 else 10)
                    if j < 11:
                        sh.px(x - sgn, y0 + j, 10)
            if j < 10 and (j + k) % 3 == 0:
                sh.px(x0 + 14 + (j // 2) % 3, y0 + j, 2)
                sh.px(x0 + 17 - (j // 2) % 3, y0 + j, 10)
    # (96,224)-(127,255) spare
    for n in range(2 * BOAT_FRAMES):
        sh.obj('boat%d' % n, (n % 4) * 32, (n // 4) * 32, 32, 32)
    sh.obj('crew0', 64, 128, 16, 16)
    sh.obj('crew1', 80, 128, 16, 16)
    sh.obj('foam0', 96, 128, 16, 16)
    sh.obj('foam1', 112, 128, 16, 16)
    sh.obj('tick', 64, 144, 8, 8)
    sh.obj('tickred', 72, 144, 8, 8)
    sh.obj('ldot', 80, 144, 8, 8)
    sh.obj('fleck', 88, 144, 8, 8)
    for n in (1, 2, 3):
        sh.obj('num%d' % n, 96 + (n - 1) * 8, 144, 8, 8)
    sh.obj('mark0', 0, 160, 16, 16)
    sh.obj('mark1', 16, 160, 16, 16)
    sh.obj('goose0', 32, 160, 16, 16)
    sh.obj('goose1', 48, 160, 16, 16)
    sh.obj('kayak0', 64, 160, 16, 16)
    sh.obj('kayak1', 80, 160, 16, 16)
    sh.obj('pin', 96, 160, 16, 16)
    sh.obj('splash', 112, 160, 16, 16)
    for k in range(16):
        sh.obj('arrow%d' % k, (k % 8) * 16, 176 + (k // 8) * 16, 16, 16)
    sh.obj('ferry', 0, 208, 32, 48)
    sh.obj('committee', 32, 208, 32, 16)
    sh.obj('paw0', 64, 208, 16, 16)
    sh.obj('paw1', 80, 208, 16, 16)
    sh.obj('fwake0', 32, 224, 32, 16, 16, 0)
    sh.obj('fwake1', 64, 224, 32, 16, 16, 0)
    out('sail_obj.bin', sh.tiles())
    with open(os.path.join(BUILD, 'sail_meta.inc'), 'w') as f:
        f.write(sh.meta_inc())
    out('sail_spr.bin', b'')            # superseded by sail_obj.bin (lives in the event's bank)
    data = bytearray()
    for p in (SP_MARKS, SP_FERRY, SP_CRITTERS, SP_ARROWS):
        data += pal_bytes([hexrgb(c) for c in p], 16)
    out('sail_spr_pal.bin', data)        # sprite palettes 1..4
    return sh


# ---------------------------------------------------------------- HUD wind vane
def wind_tiles():
    """8 directions x 2x2 tiles of 2bpp BG3 art (1 arrow, 2 shadow, 3 panel),
    loaded over unused window-fill text tiles 224..255."""
    data = bytearray()
    for k in range(8):
        img = Image.new('P', (16, 16), 3)
        d = ImageDraw.Draw(img)
        a = k * math.pi / 4
        shape = [(0, -7), (6, 0), (2, 0), (2, 7), (-2, 7), (-2, 0), (-6, 0)]
        sh_pts = [(8.5 + p[0], 8.5 + p[1]) for p in (rot(x, y, a) for x, y in shape)]
        pts = [(7.5 + p[0], 7.5 + p[1]) for p in (rot(x, y, a) for x, y in shape)]
        d.polygon(sh_pts, fill=2)
        d.polygon(pts, fill=1)
        px = img.load()
        for ty in range(2):
            for tx in range(2):
                pix = [px[tx * 8 + x, ty * 8 + y] for y in range(8) for x in range(8)]
                data += tile_bytes(pix, 2)
    return data


def layout_inc():
    lines = ['; generated by tools/art_sail.py: course layout',
             'CITY_Y = %d' % CITY_Y, 'FERRY_X = %d' % FERRY_X,
             'FERRY_Y0 = %d' % FERRY_Y0, 'FERRY_Y1 = %d' % FERRY_Y1,
             'LINE_X = %d' % LINE_X, 'LINE_Y = %d' % LINE_Y, 'LINE_HALF = %d' % LINE_HALF,
             'START_X = %d' % START[0], 'START_Y = %d' % START[1],
             '.define MARK_XS %s' % ', '.join(str(m[0]) for m in MARKS),
             '.define MARK_YS %s' % ', '.join(str(m[1]) for m in MARKS)]
    with open(os.path.join(BUILD, 'sail_layout.inc'), 'w') as f:
        f.write('\n'.join(lines) + '\n')


PALS = [   # (has water, colours)
    (1, ['sand', 'sand2', 'wet', 'grass', 't1', 't2', 't3', 'deck', 'deck2', 'white', 'red']),   # Islands
    (0, ['far', 'far2', 'farlit', 'dark', 'glass', 'glass2', 'blue', 'blue2', 'conc', 'conc2', 'brick',
         'brick2', 'lit', 'white', 'red']),                                                     # the city
    (0, ['path', 'sand2', 'wall', 'wall2', 't1', 't2', 't3', 'deck', 'deck2']),                 # seawall
    (0, ['rock', 'rock2', 'rock3', 'white', 'wall', 'red']),                                    # edges
    (1, ['brick', 'brick2', 'dark', 'white', 'conc', 'conc2', 'wall', 'rock2']),                # Port Lands
]


def build():
    solid.clear()
    img = harbour()
    # hand-packed palettes; water first in palette 0, in a fixed order, so the
    # code can cycle CGRAM 34-36
    pals = [[(0, 0, 0)] + ([snap(hexrgb(c)) for c in WATER] if w else []) + [C[k][:3] for k in p]
            for w, p in PALS]
    for p in pals:
        assert len(p) <= 16, len(p)
    ts = TileSet(4)
    m = convert_bg(img, pals, 2, ts, allow_flip=True)
    out('sail_tiles.bin', ts.data())
    out('sail_map.bin', map_bytes(m))                 # 64x64 = 4 screens, 8 KB
    bits = bytearray(H // 8 * 8)
    for (tx, ty) in solid:
        bits[ty * 8 + tx // 8] |= 0x80 >> (tx % 8)
    out('sail_solid.bin', bits)
    data = bytearray()
    for p in pals:
        data += pal_bytes(p, 16)
    data += bytes(32 * (6 - len(pals)))
    out('sail_pal.bin', data)
    out('sail_wind.bin', wind_tiles())
    layout_inc()
    sh = build_sprites()
    # previews: the whole harbour with the course, and a close-up with sprites
    full = img.copy()
    fd = ImageDraw.Draw(full)
    for (mx, my) in MARKS:
        full.alpha_composite(render(sh, (0, 160, 16, 16), SP_MARKS), (mx - 8, my - 8))
    fd.line([LINE_X - LINE_HALF, LINE_Y, LINE_X + LINE_HALF, LINE_Y], fill=(255, 255, 255, 255))
    full.alpha_composite(render(sh, (0, 208, 32, 48), SP_FERRY), (FERRY_X - 16, 260))
    full.alpha_composite(render(sh, (32, 224, 32, 16), SP_FERRY), (FERRY_X - 16, 284))
    full.alpha_composite(render(sh, (0, 0, 32, 32), P.ATHLETE), (START[0] - 16, START[1] - 16))
    preview(full, 'sail_full.png', 2)
    # every heading, both sail sides (west headings are mirrored frames), crew on top
    view = Image.new('RGBA', (16 * 36, 2 * 40), WATER[0])
    for side_i in range(2):
        for h in range(16):
            if h <= 8:
                f, fl = h + side_i * BOAT_FRAMES, False
            else:
                f, fl = (16 - h) + (1 - side_i) * BOAT_FRAMES, True
            im = render(sh, ((f % 4) * 32, (f // 4) * 32, 32, 32), P.ATHLETE, fliph=fl)
            view.alpha_composite(im, (h * 36 + 2, side_i * 40 + 4))
    preview(view, 'sail.png', 3)
    return '%d tiles, %d pals' % (len(ts), len(pals))


if __name__ == '__main__':
    print(build())
