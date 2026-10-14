"""Menu art: scrolling maple-leaf backdrop (BG2), the 12 sponsor badges
(BG1), menu sprites (cursor, medals, athlete), sponsor jersey colours."""
import math
from PIL import Image, ImageDraw
from snes import (TileSet, convert_bg, build_palettes, map_bytes, pal_bytes, hexrgb,
                  snap, out, preview, sprite_from_rows, sheet_tiles)

# name lines (micro font), bg, fg, accent, jersey (primary, shade, secondary).
# Every jersey has its own colour, and it's the colour of the badge you pick:
# yellow, black, navy, orange, cream, lettuce green, red, brown, sky blue,
# maroon, bottle green, pink.
SPONSORS = [
    ('honest',  ['HONEST', "ED'S"],     '#f8d020', '#c81800', '#f87800', ('#f8d020', '#c89810', '#c81800')),
    # Sam's: black vinyl, red label
    ('sam',     ['SAM THE', 'RECORD MAN'], '#282828', '#f8f8f8', '#e02020', ('#383838', '#202020', '#e02020')),
    ('eatons',  ["EATON'S"],            '#182c70', '#e8c870', '#f8f8f8', ('#3050b8', '#1c3080', '#f0c850')),  # brighter than the navy backdrop + pants; gold trim (Laura has white)
    ('pizza',   ['PIZZA', 'PIZZA'],     '#f07000', '#f8f8f8', '#a83800', ('#f07000', '#b05000', '#f8f8f8')),
    # Swiss Chalet: the white chalet under a red roof
    ('chalet',  ['SWISS', 'CHALET'],    '#f0e4c0', '#a81010', '#c89848', ('#f0e4c0', '#c0a878', '#a81010')),
    # Mr. Sub: lettuce green, mustard trim
    ('mrsub',   ['MR. SUB'],            '#50a828', '#f8f8f8', '#f8d020', ('#50a828', '#307818', '#f8d020')),
    ('tire',    ['CANADIAN', 'TIRE'],   '#d80010', '#f8f8f8', '#20a040', ('#d80010', '#900008', '#20a040')),
    ('roots',   ['ROOTS'],              '#5a3018', '#f8e8c8', '#a87040', ('#5a3018', '#3a1c0c', '#f8e8c8')),
    # Laura Secord: cameo blue, not Eaton's navy
    ('laura',   ['LAURA', 'SECORD'],    '#4878c8', '#f8f8f8', '#f8d0d8', ('#4878c8', '#2c5090', '#f8f8f8')),
    # Shopsy's: deli maroon, mustard
    ('shopsys', ["SHOPSY'S"],           '#801028', '#f8c830', '#f86030', ('#801028', '#580818', '#f8c830')),
    ('steam',   ['STEAM', 'WHISTLE'],   '#1e6e3a', '#f8f8f8', '#a8e0b0', ('#1e6e3a', '#104824', '#f8f8f8')),
    ('much',    ['MUCH', 'MUSIC'],      '#e01890', '#f8f8f8', '#181818', ('#f0189a', '#a00c68', '#181818')),
]

MICRO = {
    'A': ['.#.', '#.#', '###', '#.#', '#.#'], 'B': ['##.', '#.#', '##.', '#.#', '##.'],
    'C': ['.##', '#..', '#..', '#..', '.##'], 'D': ['##.', '#.#', '#.#', '#.#', '##.'],
    'E': ['###', '#..', '##.', '#..', '###'], 'F': ['###', '#..', '##.', '#..', '#..'],
    'G': ['.##', '#..', '#.#', '#.#', '.##'], 'H': ['#.#', '#.#', '###', '#.#', '#.#'],
    'I': ['###', '.#.', '.#.', '.#.', '###'], 'J': ['..#', '..#', '..#', '#.#', '.#.'],
    'K': ['#.#', '#.#', '##.', '#.#', '#.#'], 'L': ['#..', '#..', '#..', '#..', '###'],
    'M': ['#.#', '###', '###', '#.#', '#.#'], 'N': ['##.', '#.#', '#.#', '#.#', '#.#'],
    'O': ['.#.', '#.#', '#.#', '#.#', '.#.'], 'P': ['##.', '#.#', '##.', '#..', '#..'],
    'Q': ['.#.', '#.#', '#.#', '##.', '.##'], 'R': ['##.', '#.#', '##.', '#.#', '#.#'],
    'S': ['.##', '#..', '.#.', '..#', '##.'], 'T': ['###', '.#.', '.#.', '.#.', '.#.'],
    'U': ['#.#', '#.#', '#.#', '#.#', '###'], 'V': ['#.#', '#.#', '#.#', '#.#', '.#.'],
    'W': ['#.#', '#.#', '###', '###', '#.#'], 'X': ['#.#', '#.#', '.#.', '#.#', '#.#'],
    'Y': ['#.#', '#.#', '.#.', '.#.', '.#.'], 'Z': ['###', '..#', '.#.', '#..', '###'],
    "'": ['.#.', '.#.', '...', '...', '...'], '.': ['...', '...', '...', '...', '.#.'],
    ' ': ['...'] * 5,
}


def rgb(h):
    return snap(hexrgb(h)) + (255,)


def micro_text(d, x, y, text, fg, shadow):
    for ch in text:
        rows = MICRO[ch]
        for gy, r in enumerate(rows):
            for gx, c in enumerate(r):
                if c == '#' and shadow:
                    d.point((x + gx + 1, y + gy + 1), fill=shadow)
        for gy, r in enumerate(rows):
            for gx, c in enumerate(r):
                if c == '#':
                    d.point((x + gx, y + gy), fill=fg)
        x += 4


def icon(d, key, x, y, bg, fg, acc):
    """16x16 icon area at x,y."""
    blk = rgb('#101010')
    wht = rgb('#f8f8f8')
    if key == 'honest':
        pts = []
        for i in range(16):
            a = i * math.pi / 8
            r = 7.5 if i % 2 == 0 else 4
            pts.append((x + 8 + r * math.cos(a), y + 8 + r * math.sin(a)))
        d.polygon(pts, fill=fg)
        d.ellipse([x + 5, y + 5, x + 10, y + 10], fill=acc)
    elif key == 'sam':
        d.ellipse([x + 1, y + 1, x + 14, y + 14], fill=blk, outline=rgb('#787878'))
        d.ellipse([x + 3, y + 3, x + 12, y + 12], outline=rgb('#484848'))
        d.ellipse([x + 5, y + 5, x + 10, y + 10], fill=acc)
        d.point((x + 7, y + 7), fill=wht)
        d.point((x + 4, y + 4), fill=wht)
    elif key == 'eatons':
        d.rectangle([x + 2, y + 1, x + 13, y + 14], outline=fg)
        d.rectangle([x + 5, y + 4, x + 10, y + 5], fill=fg)
        d.rectangle([x + 5, y + 4, x + 6, y + 11], fill=fg)
        d.rectangle([x + 5, y + 7, x + 9, y + 8], fill=fg)
        d.rectangle([x + 5, y + 10, x + 10, y + 11], fill=fg)
    elif key == 'pizza':
        d.polygon([(x + 1, y + 2), (x + 14, y + 2), (x + 8, y + 15)], fill=rgb('#f8d060'))
        d.rectangle([x + 1, y + 1, x + 14, y + 3], fill=rgb('#c87830'))
        for (px_, py_) in ((5, 6), (9, 5), (8, 10), (11, 7)):
            d.ellipse([x + px_ - 1, y + py_ - 1, x + px_ + 1, y + py_ + 1], fill=acc)
    elif key == 'chalet':
        d.polygon([(x + 1, y + 8), (x + 8, y + 1), (x + 15, y + 8)], fill=fg)
        d.rectangle([x + 3, y + 8, x + 13, y + 14], fill=rgb('#a86830'))
        d.rectangle([x + 7, y + 10, x + 9, y + 14], fill=bg)
        d.rectangle([x + 4, y + 9, x + 5, y + 10], fill=bg)
        d.rectangle([x + 11, y + 9, x + 12, y + 10], fill=bg)
    elif key == 'mrsub':
        d.ellipse([x + 0, y + 4, x + 15, y + 12], fill=rgb('#d89848'), outline=rgb('#704010'))
        d.rectangle([x + 2, y + 7, x + 13, y + 8], fill=rgb('#b8f060'))
        d.rectangle([x + 2, y + 9, x + 13, y + 9], fill=rgb('#c83020'))
        d.line([x + 3, y + 5, x + 12, y + 5], fill=rgb('#f8c878'))
    elif key == 'tire':
        d.polygon([(x + 0, y + 1), (x + 15, y + 1), (x + 8, y + 15)], fill=acc)
        d.polygon([(x + 3, y + 3), (x + 12, y + 3), (x + 8, y + 11)], fill=wht)
        d.point((x + 8, y + 5), fill=bg)
        d.rectangle([x + 7, y + 6, x + 9, y + 7], fill=bg)
    elif key == 'roots':
        leaf(d, x, y, fg)
    elif key == 'laura':
        d.ellipse([x + 2, y + 0, x + 13, y + 15], fill=fg)
        d.ellipse([x + 4, y + 2, x + 11, y + 13], fill=acc)
        d.ellipse([x + 6, y + 4, x + 10, y + 9], fill=bg)
        d.rectangle([x + 6, y + 9, x + 9, y + 12], fill=bg)
    elif key == 'shopsys':
        d.ellipse([x + 0, y + 4, x + 15, y + 12], fill=rgb('#e8b868'))
        d.ellipse([x + 1, y + 6, x + 14, y + 10], fill=rgb('#b84828'))
        for k in range(3, 13, 3):
            d.point((x + k, y + 7), fill=rgb('#f8e020'))
            d.point((x + k + 1, y + 8), fill=rgb('#f8e020'))
    elif key == 'steam':
        d.rectangle([x + 6, y + 1, x + 9, y + 5], fill=rgb('#0c3c1c'))
        d.rectangle([x + 4, y + 6, x + 11, y + 15], fill=rgb('#0c3c1c'))
        d.rectangle([x + 5, y + 9, x + 10, y + 12], fill=wht)
        d.point((x + 7, y + 2), fill=acc)
    elif key == 'much':
        d.rectangle([x + 1, y + 3, x + 14, y + 14], fill=rgb('#606060'))
        d.rectangle([x + 3, y + 5, x + 12, y + 12], fill=acc)
        d.rectangle([x + 3, y + 5, x + 7, y + 8], fill=rgb('#28c8f8'))
        d.rectangle([x + 8, y + 9, x + 12, y + 12], fill=rgb('#f8e020'))
        d.line([x + 5, y + 0, x + 7, y + 3], fill=wht)
        d.line([x + 10, y + 0, x + 8, y + 3], fill=wht)


def leaf(d, x, y, col):
    rows = ['.......#........', '......###.......', '...#..###..#....', '...##.###.##....',
            '#..#########..#.', '.#############..', '..###########...', '#############...',
            '.###########....', '...#######......', '....#####.......', '.......#........',
            '.......#........', '.......#........']
    for gy, r in enumerate(rows):
        for gx, c in enumerate(r):
            if c == '#':
                d.point((x + gx, y + gy + 1), fill=col)


def badge(d, x, y, sp):
    key, lines, bg, fg, acc, _ = sp
    B, F, A = rgb(bg), rgb(fg), rgb(acc)
    out_ = rgb('#080810')
    d.rounded_rectangle([x, y, x + 63, y + 23], radius=3, fill=out_)
    d.rounded_rectangle([x + 1, y + 1, x + 62, y + 22], radius=2, fill=B)
    d.rectangle([x + 3, y + 3, x + 60, y + 3], fill=A)
    d.rectangle([x + 3, y + 20, x + 60, y + 20], fill=A)
    icon(d, key, x + 4, y + 4, B, F, A)
    ty = y + 9 if len(lines) == 1 else y + 6
    lum = lambda c: c[0] * 3 + c[1] * 6 + c[2]
    shadow = out_ if lum(F) > lum(B) else None
    for i, ln in enumerate(lines):
        micro_text(d, x + 22, ty + i * 7, ln, F, shadow)


BADGE_X = [16, 96, 176]
BADGE_Y = [40, 72, 104, 136]


def badges_layer():
    img = Image.new('RGBA', (256, 224), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for i, sp in enumerate(SPONSORS):
        badge(d, BADGE_X[i % 3], BADGE_Y[i // 3], sp)
    return img


def pattern_layer():
    img = Image.new('RGBA', (256, 256), rgb('#141a40'))
    d = ImageDraw.Draw(img)
    for ty in range(0, 256, 32):
        for tx in range(0, 256, 32):
            off = 16 if (ty // 32) % 2 else 0
            leaf(d, tx + off, ty + 1, rgb('#1e2658'))
    for k in range(-256, 256, 16):
        d.line([k, 0, k + 256, 256], fill=rgb('#182050'))
    return img


# --- sprites: cursor corners, medals, athlete (jersey palette layout) ---
# index 7 (jersey trim) must not share a colour with index 10 (shoe white), or
# the converter maps the trim stripe to the shoes and the trim never shows
ATHLETE_PAL = ['#000000', '#101018', '#f8c890', '#c88850', '#483018', '#e02818', '#901010',
               '#f0f0f0', '#283878', '#182450', '#f8f8f8', '#605858', '#f8d020', '#a87810', '#d8d8e8', '#787890']
MEDAL = {'g': ('#f8d020', '#b07808', '#fff8a0'), 's': ('#d8d8e8', '#787890', '#ffffff'),
         'b': ('#d88040', '#884018', '#f8c090')}


def menu_sprites():
    sheet = Image.new('RGBA', (128, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(sheet)
    white = rgb('#f8f8f8')
    yel = rgb('#f8d020')
    blk = rgb('#101018')
    # cursor corner (8x8) at tile 0 (top-left); flips make the others
    for (x, y) in [(0, 0), (1, 0), (2, 0), (3, 0), (4, 0), (0, 1), (0, 2), (0, 3), (0, 4),
                   (1, 1), (2, 1), (3, 1), (1, 2), (1, 3)]:
        d.point((x, y), fill=yel)
    for (x, y) in [(5, 0), (4, 1), (2, 2), (1, 4), (0, 5), (2, 3), (3, 2)]:
        d.point((x, y), fill=blk)
    # medals 16x16 at tiles 2, 4, 6 (gold silver bronze)
    for i, k in enumerate('gsb'):
        face, dark, hi = (rgb(c) for c in MEDAL[k])
        x0 = 16 + i * 16
        d.polygon([(x0 + 4, 0), (x0 + 7, 0), (x0 + 9, 6), (x0 + 6, 6)], fill=rgb('#e02818'))
        d.polygon([(x0 + 9, 0), (x0 + 12, 0), (x0 + 10, 6), (x0 + 7, 6)], fill=rgb('#283878'))
        d.ellipse([x0 + 3, 5, x0 + 13, 15], fill=dark)
        d.ellipse([x0 + 3, 5, x0 + 12, 14], fill=face)
        d.ellipse([x0 + 5, 7, x0 + 10, 12], outline=dark)
        d.point((x0 + 5, 7), fill=hi)
        d.point((x0 + 6, 6), fill=hi)
    # athlete standing, 16x32 at tiles 16 (row 2) — palette index art
    rows = [
        '................', '.....11111......', '....1444441.....', '...144444441....',
        '...144222221....', '...142212221....', '...122222221....', '....1222231.....',
        '.....12231......', '....11111111....', '...1555775551...', '..155557755551..',
        '..155557755551..', '..12555775552 1.', '..12556666552 1.', '..1225666652221.',
        '..1221666612 21.', '...11888888111..', '....18888881....', '....18899881....',
        '....1889 9881...', '....1889.1881...', '....1889.1881...', '....1889.1881...',
        '....1889.1881...', '....1889.1881...', '....1222.1222...', '...1aaaa.1aaa1..',
        '...1bbbb.1bbbb1.', '....1111..1111..', '................', '................']
    rows = [r.replace(' ', '.') for r in rows]
    colmap = {'1': 1, '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9, 'a': 10, 'b': 11}
    px = sheet.load()
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch in colmap:
                px[x, 16 + y] = rgb(ATHLETE_PAL[colmap[ch]])
    return sheet


def build():
    pat = pattern_layer()
    badges = badges_layer()
    pals = build_palettes(Image.alpha_composite(Image.new('RGBA', (256, 224)), badges), 5)
    pat_pal = [(0, 0, 0)] + sorted({snap(c) for c in pat.convert('RGB').getdata()})
    ts = TileSet(4)
    m_pat = convert_bg(pat, [pat_pal], 7, ts)
    m_bad = convert_bg(badges, pals, 2, ts)
    out('menu_tiles.bin', ts.data())
    out('menu_bg2.bin', map_bytes(m_pat)[:2048])
    out('badges_bg1.bin', map_bytes(m_bad)[:2048])
    data = bytearray()
    for p in pals:
        data += pal_bytes(p, 16)
    data += pal_bytes([(0, 0, 0)] * 16, 16) * (5 - len(pals))
    data += pal_bytes(pat_pal, 16)
    out('menu_pal.bin', data)            # BG palettes 2..7
    # menu sprites (palette 0: athlete layout; medals/cursor colours added)
    sheet = menu_sprites()
    spal = [snap(hexrgb(c)) for c in ATHLETE_PAL]
    extra = set()
    for c in sheet.crop((0, 0, 128, 16)).getdata():
        if c[3]:
            extra.add(snap(c))
    medal_pal = [(0, 0, 0)] + sorted(extra)
    assert len(medal_pal) <= 16, len(medal_pal)
    # medals + cursor use sprite palette 1; athlete uses palette 0
    top = sheet.crop((0, 0, 128, 16))
    bottom = sheet.crop((0, 16, 128, 64))
    data = sheet_tiles(top, medal_pal) + sheet_tiles(bottom, [(0, 0, 0)] + spal[1:])
    out('spr_menu.bin', data)
    out('spr_menu_pal.bin', pal_bytes([(0, 0, 0)] + spal[1:], 16) + pal_bytes(medal_pal, 16))
    # jersey colours: 12 x (primary, shade, secondary) as BGR555
    jer = bytearray()
    for sp in SPONSORS:
        jer += pal_bytes([hexrgb(c) for c in sp[5]])
    out('jerseys.bin', jer)
    prev = Image.alpha_composite(pat.crop((0, 0, 256, 224)), badges)
    preview(prev, 'sponsors.png')
    return len(ts)


if __name__ == '__main__':
    print(build())
