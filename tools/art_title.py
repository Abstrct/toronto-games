"""Title screen: dusk skyline seen from the Islands, CN Tower, lake
reflection, island trees (BG2); chunky logo (BG1); sky gradient (HDMA)."""
import math
import random
from PIL import Image, ImageDraw
from snes import (TileSet, convert_bg, map_bytes, pal_bytes, hexrgb, snap,
                  out, preview, sprite_from_rows, sheet_tiles)

W, H = 256, 224
HORIZON = 152

# --- palettes (index 0 transparent) ---
P_LOGO = ['#000000', '#101028', '#283070', '#f8f8f8', '#f85838', '#e02818', '#b01010', '#780808',
          '#f8f070', '#f8c820', '#e09000', '#a85800', '#f8a8a0']
P_CITY = ['#000000', '#141428', '#20203c', '#2c2c54', '#3c3c6c', '#555588', '#9898b8', '#d0c088',
          '#c89838', '#805818', '#a83030', '#601818', '#f8e070', '#f8a040', '#6c6c90']
# CN Tower gets its own palette; it shares tiles with the dome and condos,
# so their colours are in here too
P_TOWER = ['#000000', '#f0e0d4', '#ccc0c4', '#a49cb0', '#7e7898', '#5c5878', '#403c58', '#242438',
           '#d83030', '#f8f8f8', '#20203c', '#2c2c54', '#3c3c6c', '#6c6c90', '#f8e070', '#f8a040']
P_LAKE = ['#000000', '#d07898', '#a85888', '#704880', '#483870', '#303064', '#202450', '#141838',
          '#f8c070', '#f8f0b0', '#0c1c14', '#16301e', '#20462a', '#2e5e36', '#f8e070']


def pal(lst):
    return [(0, 0, 0)] + [snap(hexrgb(c)) for c in lst[1:]]


def C(lst, i):
    return snap(hexrgb(lst[i])) + (255,)


# ------------------------------------------------------------------ logo
BIG = {
    'T': ['#######', '#######', '..###..', '..###..', '..###..', '..###..', '..###..', '..###..', '..###..'],
    'O': ['.#####.', '#######', '###.###', '###.###', '###.###', '###.###', '###.###', '#######', '.#####.'],
    'R': ['######.', '#######', '###.###', '###.###', '######.', '#####..', '###.##.', '###.###', '###.###'],
    'N': ['##...##', '###..##', '####.##', '#######', '##.####', '##..###', '##...##', '##...##', '##...##'],
    'G': ['.#####.', '#######', '###....', '###....', '###.###', '###.###', '###..##', '#######', '.#####.'],
    'A': ['.#####.', '#######', '###.###', '###.###', '#######', '#######', '###.###', '###.###', '###.###'],
    'M': ['##...##', '###.###', '#######', '#######', '##.#.##', '##...##', '##...##', '##...##', '##...##'],
    'E': ['#######', '#######', '###....', '###....', '######.', '###....', '###....', '#######', '#######'],
    'S': ['.######', '#######', '###....', '######.', '.######', '....###', '....###', '#######', '######.'],
}


def draw_word(img, word, x0, y0, sx, sy, face):
    """face: list of 4 colour indices top->bottom in P_LOGO."""
    px = img.load()
    mask = set()
    x = x0
    for ch in word:
        rows = BIG[ch]
        for gy, r in enumerate(rows):
            for gx, c in enumerate(r):
                if c == '#':
                    for yy in range(sy):
                        for xx in range(sx):
                            mask.add((x + gx * sx + xx, y0 + gy * sy + yy))
        x += 7 * sx + 3
    h = 9 * sy
    # drop shadow
    for (mx, my) in mask:
        for d in range(1, 4):
            p = (mx + d, my + d)
            if p not in mask and 0 <= p[0] < W and 0 <= p[1] < H:
                px[p] = C(P_LOGO, 2)
    # outline
    for (mx, my) in mask:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                p = (mx + dx, my + dy)
                if p not in mask and 0 <= p[0] < W and 0 <= p[1] < H:
                    px[p] = C(P_LOGO, 1)
    # face: banded gradient with a bright top edge
    for (mx, my) in mask:
        t = (my - y0) / h
        band = min(3, int(t * 4))
        idx = face[band]
        if (mx, my - 1) not in mask:
            idx = 3 if band == 0 else face[0]
        elif (mx - 1, my) not in mask and band < 2:
            idx = face[0]
        px[mx, my] = C(P_LOGO, idx)


def logo_layer():
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    # TORONTO is 165 px wide (+4 px shadow): x=76 keeps the last O and its
    # shadow 12 px clear of the right edge; GAMES is centred under it
    draw_word(img, 'TORONTO', 76, 14, 3, 3, [4, 5, 6, 7])
    draw_word(img, 'GAMES', 100, 52, 3, 3, [8, 9, 10, 11])
    return img


# ------------------------------------------------------------------ city
def building(d, rnd, x, w, top, body, side, lit, roof=None):
    d.rectangle([x, top, x + w - 1, HORIZON - 1], fill=body)
    d.rectangle([x, top, x + 1, HORIZON - 1], fill=side)
    if roof:
        d.rectangle([x, top, x + w - 1, top + 1], fill=roof)
    for yy in range(top + 4, HORIZON - 2, 4):
        for xx in range(x + 3, x + w - 2, 3):
            if rnd.random() < 0.38:
                d.point((xx, yy), fill=lit[rnd.randrange(len(lit))])


def city_layer():
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rnd = random.Random(416)
    c = lambda i: C(P_CITY, i)
    lit = [c(12), c(13), c(7)]

    # Harbourfront condos behind everything
    for (x, w, top) in [(0, 12, 128), (10, 10, 120), (68, 10, 126), (238, 18, 122), (226, 12, 130)]:
        building(d, rnd, x, w, top, c(2), c(3), lit)

    # Rogers Centre dome
    for xx in range(2, 44):
        t = (xx - 23) / 21.0
        hh = int(12 * math.sqrt(max(0, 1 - t * t)))
        d.line([xx, HORIZON - 8 - hh, xx, HORIZON - 1], fill=c(4))
        if xx % 5 == 0:
            d.line([xx, HORIZON - 8 - hh, xx, HORIZON - 9], fill=c(14))
    d.rectangle([2, HORIZON - 8, 43, HORIZON - 1], fill=c(3))
    for xx in range(4, 42, 3):
        d.point((xx, HORIZON - 5), fill=c(13))

    # Bay St towers (left to right): x, w, top, body, side, roof
    towers = [
        (66, 12, 110, 3, 4, None),
        (78, 14, 100, 1, 2, None),           # TD black
        (92, 10, 112, 3, 5, None),
        (102, 16, 86, 6, 5, 6),              # First Canadian Place, white
        (118, 14, 98, 8, 9, 7),              # Royal Bank, gold
        (132, 12, 94, 10, 11, None),         # Scotia, red
        (144, 16, 92, 1, 2, None),           # TD tower
        (160, 12, 104, 4, 3, None),
        (172, 18, 96, 3, 5, 14),             # Commerce Court
        (190, 10, 108, 2, 4, None),
        (200, 16, 100, 4, 5, None),
        (216, 12, 112, 3, 4, None),
    ]
    for (x, w, top, b, s, r) in towers:
        building(d, rnd, x, w, top, c(b), c(s), lit, c(r) if r else None)
    # Royal Bank glints
    for yy in range(100, HORIZON - 2, 3):
        d.line([120, yy, 130, yy], fill=c(7))

    cn_tower(img, 50)
    return img


def cn_tower(img, cx):
    """The CN Tower, lit from the sunset on the left. Proportions follow the
    real one: main pod at ~62% of the height, SkyPod ~80%, antenna the top 18%."""
    d = ImageDraw.Draw(img)
    t = lambda i: C(P_TOWER, i)
    HL, LT, MD, SH, DP, XD, GL, RED, WH = 1, 2, 3, 4, 5, 6, 7, 8, 9
    LIT = 14

    def span(y, x0, x1, ramp=(HL, LT, LT, MD, MD, SH, DP)):
        """one row of a lit cylinder: bright on the left, dark on the right"""
        w = x1 - x0 + 1
        for i in range(w):
            k = int(i * len(ramp) / w)
            d.point((x0 + i, y), fill=t(ramp[k]))

    # --- legs + core: a tri-leg base flaring out toward the ground
    top_y, base_y = 69, HORIZON - 7
    for y in range(top_y, base_y + 1):
        f = (y - top_y) / (base_y - top_y)
        half = 3.5 + 6.5 * f ** 2.8
        x0, x1 = int(round(cx - half)), int(round(cx + half))
        span(y, x0, x1)
        # the front leg's ridge and the groove beside it
        if f > 0.08:
            d.point((cx - 1, y), fill=t(HL))
            d.point((cx + 1, y), fill=t(SH))
        # glass elevator track on the shaded side
        if y < base_y - 4:
            d.point((cx + 2, y), fill=t(GL))
            if y % 23 == 5:
                d.point((cx + 2, y), fill=t(LIT))
    # podium at the foot
    d.rectangle([cx - 12, base_y, cx + 11, HORIZON - 1], fill=t(MD))
    d.line([cx - 12, base_y, cx + 11, base_y], fill=t(LT))
    d.rectangle([cx + 5, base_y, cx + 11, HORIZON - 1], fill=t(SH))
    for x in range(cx - 10, cx + 10, 3):
        d.point((x, base_y + 3), fill=t(LIT))

    # --- main pod: a wide stacked disc (burger), y 56..68
    rows = [
        (56, 5, (LT, MD, SH)),                          # top bun: domed
        (57, 8, (HL, LT, MD, MD, SH)),
        (58, 10, (HL, LT, LT, MD, MD, SH, DP)),
        (59, 11, (HL, HL, LT, LT, MD, MD, SH, DP)),
        (60, 12, None), (61, 12, None), (62, 12, None),  # patty: window band
        (63, 12, (WH, HL, LT, LT, MD, MD, SH)),          # rim
        (64, 12, (HL, LT, LT, MD, MD, SH, DP)),          # bottom bun: flat
        (65, 11, (LT, MD, MD, SH, SH, DP)),
        (66, 9, (MD, MD, SH, SH, DP)),
    ]
    for (y, half, ramp) in rows:
        if ramp is None:
            for x in range(cx - half, cx + half + 1):
                d.point((x, y), fill=t(GL))
            if y == 61:
                for x in range(cx - half + 1, cx + half, 2):
                    d.point((x, y), fill=t(LIT))
        else:
            span(y, cx - half, cx + half, ramp)
    # ribs under the bottom bun
    for y in (65, 66):
        half = 11 if y == 65 else 9
        for x in range(cx - half + 1, cx + half):
            if (x - cx) % 3 == 0:
                d.point((x, y), fill=t(SH if x < cx + 3 else DP))
    # short neck down into the shaft
    for y in (67, 68):
        span(y, cx - 5 + (y - 67), cx + 5 - (y - 67), (LT, MD, SH, DP))

    # --- upper shaft between the pods
    for y in range(44, 56):
        span(y, cx - 2, cx + 2, (HL, LT, MD, SH, DP))

    # --- SkyPod (y 38..44)
    for (y, half, ramp) in [(38, 2, (LT, MD, SH)), (39, 4, (HL, LT, MD, SH, DP)),
                            (40, 4, None), (41, 4, None),
                            (42, 4, (LT, MD, MD, SH, DP)), (43, 3, (MD, SH, DP))]:
        if ramp is None:
            for x in range(cx - half, cx + half + 1):
                d.point((x, y), fill=t(GL))
            if y == 40:
                for x in range(cx - half + 1, cx + half, 2):
                    d.point((x, y), fill=t(LIT))
        else:
            span(y, cx - half, cx + half, ramp)

    # --- antenna: white, tapering, two red aviation bands
    for y in range(12, 38):
        if y >= 30:
            x0, x1 = cx - 1, cx + 1
        elif y >= 20:
            x0, x1 = cx - 1, cx
        else:
            x0, x1 = cx, cx
        for x in range(x0, x1 + 1):
            d.point((x, y), fill=t(WH if x < x1 or x0 == x1 else MD))
    for y in (24, 25, 16):
        d.point((cx, y), fill=t(RED))
        if y >= 20:
            d.point((cx - 1, y), fill=t(RED))


def lake_layer(city):
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    px = img.load()
    cpx = city.load()
    rnd = random.Random(7)
    l = lambda i: C(P_LAKE, i)
    bands = [(HORIZON, 1), (HORIZON + 4, 2), (HORIZON + 10, 3), (HORIZON + 18, 4),
             (HORIZON + 28, 5), (HORIZON + 40, 6), (HORIZON + 56, 7)]
    for y in range(HORIZON, H):
        idx = 1
        for (by, bi) in bands:
            if y >= by:
                idx = bi
        for x in range(W):
            px[x, y] = l(idx)
        # reflection of the skyline: darker, wavy, squashed
        depth = y - HORIZON
        sy = HORIZON - 1 - int(depth * 1.7)
        wob = int(2 * math.sin(y * 0.9))
        if sy > 60 and depth < 44:
            for x in range(W):
                sx = min(W - 1, max(0, x + wob))
                cp = cpx[sx, sy]
                if cp[3] > 0:
                    window = cp[0] > 200 and cp[1] > 140 and cp[2] < 150
                    # lit windows only shimmer near the shore: further out
                    # (PRESS START's row) the water stays dark, or a gold
                    # smear sits in the gap between the words
                    if window and depth < 16 and rnd.random() < 0.55:
                        px[x, y] = l(8 if depth < 10 else 14)
                    else:
                        px[x, y] = l(min(7, idx + 2))
        # glints
        if y % 3 == 0:
            for _ in range(6 if depth < 16 else 3):
                x = rnd.randrange(W - 6)
                ln = rnd.randrange(2, 7)
                for k in range(ln):
                    px[x + k, y] = l(9 if depth < 12 else 1)
    # island trees in front
    rnd = random.Random(99)
    top = [204 + int(4 * math.sin(x * 0.11) + 3 * math.sin(x * 0.37 + 1)) for x in range(W)]
    for x in range(W):
        for y in range(top[x], H):
            k = y - top[x]
            idx = 13 if k < 2 else (12 if k < 5 else (11 if k < 10 else 10))
            if rnd.random() < 0.12 and k > 1:
                idx = max(10, idx - 1)
            px[x, y] = l(idx)
    return img


# ------------------------------------------------------------------ sky
def sky_hdma():
    """HDMA mode 3 table writing CGADD=0 twice + colour 0 (lo, hi), 2 lines per entry."""
    stops = [(0, '#080828'), (40, '#281a50'), (78, '#682c68'), (108, '#b8405c'),
             (130, '#f07048'), (HORIZON, '#f8c060')]
    data = bytearray()
    y = 0
    while y < 224:
        for i in range(len(stops) - 1):
            if stops[i][0] <= y < stops[i + 1][0] or i == len(stops) - 2:
                a, b = stops[i], stops[i + 1]
                break
        t = max(0.0, min(1.0, (y - a[0]) / max(1, b[0] - a[0])))
        ca, cb = hexrgb(a[1]), hexrgb(b[1])
        col = tuple(int(ca[k] + (cb[k] - ca[k]) * t) for k in range(3))
        r, g, bb = (v >> 3 for v in col)
        w = r | (g << 5) | (bb << 10)
        data += bytes((2, 0, 0, w & 0xFF, w >> 8))
        y += 2
    data.append(0)
    out('title_sky.bin', data)
    return data


# ------------------------------------------------------------------ sprites
SPR_PAL = ['#000000', '#f8f8f8', '#c8c8d8', '#e02818', '#801010', '#f8e070', '#383848', '#f87830',
           '#ff4040', '#ffb0b0', '#a0a0b0']
SPRITES = {
    # 16x16 sailboat at tile 0
    'boat': (0, 0, [
        '.......1........',
        '.......11.......',
        '.......121......',
        '.......1221.....',
        '.......12221....',
        '......1122221...',
        '.....11.12222...',
        '....111.122221..',
        '...1111.1222221.',
        '..11111.1111111.',
        '.......6........',
        '3333333333333333',
        '.33333333333333.',
        '..444444444444..',
        '................',
        '................']),
    # 8x8 gull frames at tiles 2, 3; beacon 4, 5; star 6, 7
    'gull0': (2, 0, ['........', '.6....6.', '..6..6..', '...66...', '........', '........', '........', '........']),
    'gull1': (3, 0, ['........', '........', '........', '666..666', '...66...', '........', '........', '........']),
    'beacon0': (4, 0, ['........', '...99...', '..9889..', '.988889.', '.988889.', '..9889..', '...99...', '........']),
    'beacon1': (5, 0, ['........', '........', '...88...', '..8888..', '..8888..', '...88...', '........', '........']),
    'star0': (6, 0, ['........', '...1....', '..121...', '...1....', '........', '........', '........', '........']),
    'star1': (7, 0, ['........', '........', '...2....', '........', '........', '........', '........', '........']),
}


def sprite_sheet():
    sheet = Image.new('RGBA', (128, 16), (0, 0, 0, 0))
    cols = {str(i): hexrgb(c) for i, c in enumerate(SPR_PAL) if i}
    cols.update({'1': hexrgb(SPR_PAL[1]), '2': hexrgb(SPR_PAL[2])})
    for name, (tx, ty, rows) in SPRITES.items():
        img = sprite_from_rows(rows, cols)
        sheet.paste(img, (tx * 8, ty * 8), img)
    palette = pal(SPR_PAL)
    out('spr_title.bin', sheet_tiles(sheet, palette))
    out('spr_title_pal.bin', pal_bytes(palette, 16))
    return sheet


def build():
    logo = logo_layer()
    city = city_layer()
    lake = lake_layer(city)
    back = Image.alpha_composite(city, lake)
    ts = TileSet(4)
    m1 = convert_bg(logo, [pal(P_LOGO)], 2, ts)
    m2 = convert_bg(back, [pal(P_CITY), pal(P_LAKE), pal(P_TOWER)], 3, ts)
    out('title_tiles.bin', ts.data())
    out('title_bg1.bin', map_bytes(m1)[:2048])
    out('title_bg2.bin', map_bytes(m2)[:2048])
    pals = (pal_bytes(pal(P_LOGO), 16) + pal_bytes(pal(P_CITY), 16) + pal_bytes(pal(P_LAKE), 16)
            + pal_bytes(pal(P_TOWER), 16))
    out('title_pal.bin', pals)
    sky_hdma()
    sprite_sheet()
    # preview with a flat sky
    prev = Image.new('RGBA', (W, H), hexrgb('#682c68') + (255,))
    prev = Image.alpha_composite(prev, back)
    prev = Image.alpha_composite(prev, logo)
    preview(prev, 'title.png')
    return len(ts)


if __name__ == '__main__':
    print('title tiles', build())
