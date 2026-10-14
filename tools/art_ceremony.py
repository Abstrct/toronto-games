"""Closing ceremony: Nathan Phillips Square at night. BG2 City Hall towers,
council chamber, Freedom Arches over the pool and the TORONTO sign; BG1 the
podium; sprites for victorious athletes and fireworks."""
import math
from PIL import Image, ImageDraw
from snes import (TileSet, convert_bg, build_palettes, map_bytes, pal_bytes, hexrgb, snap,
                  out, preview, hdma_gradient, tile_bytes)
from sprites import Sheet, render
import people as P


SIGN_Y = 147                  # top of the TORONTO letters (15 px tall)
# podium step tops (ceremony.s STEP*_Y must match): 1st, 2nd, 3rd
STEP1_Y, STEP2_Y, STEP3_Y = 198, 206, 210


def rgb(h):
    return snap(hexrgb(h)) + (255,)


def square():
    img = Image.new('RGBA', (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    conc = rgb('#c8c8d0')
    conc2 = rgb('#9898a8')
    conc3 = rgb('#e8e8f0')
    win = rgb('#f8d878')
    dark = rgb('#30304a')
    # curved towers: flat tops, shading across the face suggests the curve
    shades = [rgb('#e8e8f0'), rgb('#d8d8e0'), rgb('#c8c8d0'), rgb('#b8b8c4'), rgb('#a8a8b8')]
    for (x0, x1, top, flip) in ((40, 100, 52, False), (156, 224, 30, True)):
        w = x1 - x0
        for x in range(x0, x1):
            t = (x - x0) / (w - 1)
            k = int(abs(t - (0.25 if flip else 0.75)) * 6)
            d.line([x, top, x, 150], fill=shades[min(4, k)])
        d.line([x0, top, x1 - 1, top], fill=conc3)
        for x in range(x0 + 3, x1 - 2, 3):
            for y in range(top + 4, 146, 4):
                lit = ((x // 3) * 5 + (y // 4) * 3) % 7 != 0
                d.point((x, y), fill=win if lit else dark)
    # council chamber: the saucer between the towers
    d.ellipse([92, 118, 164, 150], fill=conc3)
    d.ellipse([92, 128, 164, 150], fill=conc)
    d.rectangle([116, 140, 140, 156], fill=conc2)
    # podium base of city hall
    d.rectangle([24, 148, 232, 158], fill=conc2)
    d.line([24, 148, 232, 148], fill=conc3)
    # plaza
    d.rectangle([0, 158, 255, 255], fill=rgb('#6a6a7a'))
    for y in range(160, 256, 8):
        d.line([0, y, 255, y], fill=rgb('#5a5a6a'))
    # reflecting pool + Freedom Arches
    d.rectangle([12, 162, 243, 176], fill=rgb('#2848a0'))
    d.line([12, 164, 243, 164], fill=rgb('#4878d0'))
    for (a, b) in ((12, 88), (90, 166), (168, 243)):
        d.arc([a, 150, b, 190], 180, 360, fill=conc3, width=3)
        d.rectangle([a, 168, a + 3, 178], fill=conc3)
        d.rectangle([b - 3, 168, b, 178], fill=conc3)
    # the TORONTO sign: up in the pool, clear of the podium athletes' heads
    letters = 'TORONTO'
    cols = ['#f83838', '#f8a020', '#f8e030', '#48d848', '#38b8f8', '#a868f8', '#f868c8']
    glyphs = {
        'T': ['#####', '..#..', '..#..', '..#..', '..#..'],
        'O': ['.###.', '#...#', '#...#', '#...#', '.###.'],
        'R': ['####.', '#...#', '####.', '#..#.', '#...#'],
        'N': ['#...#', '##..#', '#.#.#', '#..##', '#...#'],
    }
    x = 62
    for i, ch in enumerate(letters):
        c = rgb(cols[i])
        for gy, row in enumerate(glyphs[ch]):
            for gx, v in enumerate(row):
                if v == '#':
                    d.rectangle([x + gx * 3, SIGN_Y + gy * 3, x + gx * 3 + 2, SIGN_Y + gy * 3 + 2], fill=c)
        x += 19
    return img


NUM35 = {
    '1': ['.#.', '##.', '.#.', '.#.', '###'],
    '2': ['##.', '..#', '.#.', '#..', '###'],
    '3': ['##.', '..#', '.#.', '..#', '##.'],
}


def podium():
    img = Image.new('RGBA', (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    top = rgb('#f8f8f8')
    side = rgb('#c8c8d8')
    dark = rgb('#888898')
    gold = rgb('#f8c820')
    # blocks: 2nd (left), 1st (centre), 3rd (right)
    for (x0, x1, y0, n) in ((80, 112, STEP2_Y, '2'), (112, 144, STEP1_Y, '1'), (144, 176, STEP3_Y, '3')):
        d.rectangle([x0, y0, x1 - 1, 223], fill=side)
        d.rectangle([x0, y0, x1 - 1, y0 + 2], fill=top)
        d.line([x1 - 1, y0, x1 - 1, 223], fill=dark)
        # numeral: a 3x5 glyph at 2x
        cx = (x0 + x1) // 2
        for gy, row in enumerate(NUM35[n]):
            for gx, v in enumerate(row):
                if v == '#':
                    px, py = cx - 3 + gx * 2, y0 + 3 + gy * 2
                    d.rectangle([px, py, px + 1, py + 1], fill=gold if n == '1' else dark)
    return img


FIRE = [
    ['#000000', '#101018', '#f83838', '#f8c020', '#fff0c0'],
    ['#000000', '#101018', '#38d8f8', '#68f878', '#e8fff8'],
    ['#000000', '#101018', '#f868c8', '#c888f8', '#ffffff'],
]


# Ceremony sprites all use the athletes' palettes (player_palette: index 5
# jersey, 6 shade, 7 trim, 10 white, 12/13 yellow, 14/15 grey, 1 outline),
# so each firework bursts in a champion's sponsor colours and eight athletes
# can share the eight sprite palettes.
MEDAL_ROWS = ['5.....7.', '.5...7..', '..5.7...', '..1111..', '.1ffh1..', '.1fff1..', '.1fff1..', '..111...']


def burst(d, cx, cy, rays, r0, r1, cols, step=1.0, droop=0.0):
    for a in range(0, 360, 360 // rays):
        for k, r in enumerate(range(r0, r1 + 1)):
            x = cx + r * math.cos(math.radians(a))
            y = cy + r * math.sin(math.radians(a)) + droop * (r - r0) ** 2 / max(1, r1 - r0)
            col = cols[min(len(cols) - 1, k * len(cols) // (r1 - r0 + 1))]
            d.point((round(x), round(y)), fill=col)


def build_sprites():
    sh = Sheet(32)
    victory = dict(P.STAND, arms=(-160, -170), elbows=(0, 10))
    wave = dict(P.STAND, arms=(-140, -175), elbows=(-30, 10))
    P.draw_person(sh, 0, 0, **victory)
    P.draw_person(sh, 16, 0, **wave)
    d = sh.draw()
    # rising rocket 8x8 at (32,0): white head, yellow trail
    d.point((35, 1), fill=10)
    d.point((35, 2), fill=12)
    d.point((35, 4), fill=13)
    d.point((35, 6), fill=13)
    # medals 8x8 at (32,8) gold, (40,8) silver, (32,16) bronze; ribbon in jersey colours
    for (mx, my, face, hi) in ((32, 8, 12, 10), (40, 8, 14, 10), (32, 16, 13, 12)):
        for yy, row in enumerate(MEDAL_ROWS):
            for xx, ch in enumerate(row):
                c = {'5': 5, '7': 7, '1': 1, 'f': face, 'h': hi}.get(ch)
                if c is not None:
                    d.point((mx + xx, my + yy), fill=c)
    # small burst 16x16 at (48,0)
    burst(d, 55.5, 7.5, 8, 2, 5, [10, 5])
    d.point((55, 7), fill=10)
    # big burst 32x32 at (64,0): white core, jersey rays, trim tips
    burst(d, 79.5, 15.5, 16, 3, 14, [10, 10, 5, 5, 5, 7, 7])
    burst(d, 79.5, 15.5, 8, 2, 7, [10])
    # fading sparkle 32x32 at (96,0): drooping trails, dotted
    for a in range(0, 360, 24):
        for r in range(9, 16, 2):
            x = 111.5 + r * math.cos(math.radians(a))
            y = 15.5 + r * math.sin(math.radians(a)) + (r - 9) * 0.6
            if 96 <= x < 128 and 0 <= y < 32:
                d.point((round(x), round(y)), fill=7 if r < 13 else 6)
    sh.obj('victory', 0, 0, 16, 32, 8, 31)
    sh.obj('wave', 16, 0, 16, 32, 8, 31)
    sh.obj('rocket', 32, 0, 8, 8)
    sh.obj('medal_g', 32, 8, 8, 8)
    sh.obj('medal_s', 40, 8, 8, 8)
    sh.obj('medal_b', 32, 16, 8, 8)
    sh.obj('fw1', 48, 0, 16, 16)
    sh.obj('fw2', 64, 0, 32, 32)
    sh.obj('fw3', 96, 0, 32, 32)
    out('cer_spr.bin', sh.tiles())
    with open('build/cer_meta.inc', 'w') as f:
        f.write(sh.meta_inc())
    data = bytearray()
    for p in FIRE:
        data += pal_bytes([hexrgb(c) for c in p], 16)
    out('cer_spr_pal.bin', data)       # (unused since the athlete palettes took over)
    return sh


def build():
    bg = square()
    fg = podium()
    both = Image.new('RGBA', (256, 512), (0, 0, 0, 0))
    both.paste(bg, (0, 0))
    both.paste(fg, (0, 256))
    pals = build_palettes(both, 6)
    ts = TileSet(4)
    m2 = convert_bg(bg, pals, 2, ts)
    m1 = convert_bg(fg, pals, 2, ts, priority=True)
    out('cer_tiles.bin', ts.data())
    out('cer_bg1.bin', map_bytes(m1)[:2048])
    out('cer_bg2.bin', map_bytes(m2)[:2048])
    data = bytearray()
    for p in pals:
        data += pal_bytes(p, 16)
    data += bytes(32 * (6 - len(pals)))
    out('cer_pal.bin', data)
    hdma_gradient([(0, '#080820'), (80, '#201848'), (150, '#482860')], 'cer_sky.bin')
    sh = build_sprites()
    view = Image.new('RGBA', (256, 224), rgb('#201848'))
    view.alpha_composite(bg.crop((0, 0, 256, 224)))
    view.alpha_composite(fg.crop((0, 0, 256, 224)))
    view.alpha_composite(render(sh, (0, 0, 16, 32), P.ATHLETE), (120, STEP1_Y - 31))
    view.alpha_composite(render(sh, (32, 8, 8, 8), P.ATHLETE), (124, STEP1_Y - 20))
    view.alpha_composite(render(sh, (16, 0, 16, 32), P.CROWD[0]), (88, STEP2_Y - 31))
    view.alpha_composite(render(sh, (40, 8, 8, 8), P.CROWD[0]), (92, STEP2_Y - 20))
    view.alpha_composite(render(sh, (0, 0, 16, 32), P.CROWD[2]), (152, STEP3_Y - 31))
    view.alpha_composite(render(sh, (32, 16, 8, 8), P.CROWD[2]), (156, STEP3_Y - 20))
    view.alpha_composite(render(sh, (64, 0, 32, 32), P.CROWD[1]), (40, 50))
    view.alpha_composite(render(sh, (96, 0, 32, 32), P.CROWD[3]), (190, 60))
    view.alpha_composite(render(sh, (48, 0, 16, 16), P.ATHLETE), (120, 90))
    preview(view, 'ceremony.png')
    build_countdown()
    return '%d tiles, %d pals' % (len(ts), len(pals))


# ---------------------------------------------------------------- countdown
# Big 3 / 2 / 1 / GO! for event_countdown (cards.s). BG3 2bpp tiles in the
# font's colours: 1 = text colour of the palette, 2 = dark outline, 0 = clear.
# Each glyph is drawn on a 10x14 grid, outlined by one cell and doubled, so a
# digit is 24x32 px = 3x4 tiles. Output: '3', '2', '1' (12 tiles each, row
# major) then 'GO!' (7x4 = 28 tiles): 64 tiles, 1 KB.
CD_GLYPHS = {
    '3': ['.########.', '##########', '###....###', '.......###', '.......###', '.......###',
          '...######.', '...######.', '.......###', '.......###', '.......###', '###....###',
          '##########', '.########.'],
    '2': ['.########.', '##########', '###....###', '.......###', '.......###', '......###.',
          '.....###..', '....###...', '...###....', '..###.....', '.###......', '###.......',
          '##########', '##########'],
    '1': ['....###...', '...####...', '..#####...', '.######...', '....###...', '....###...',
          '....###...', '....###...', '....###...', '....###...', '....###...', '....###...',
          '.#########', '.#########'],
    'G': ['.########.', '##########', '###....###', '###.......', '###.......', '###.......',
          '###..#####', '###..#####', '###....###', '###....###', '###....###', '###....###',
          '##########', '.########.'],
    'O': ['.########.', '##########'] + ['###....###'] * 10 + ['##########', '.########.'],
    '!': ['##'] * 9 + ['..', '..'] + ['##'] * 3,
}


def cd_glyph(ch):
    rows = CD_GLYPHS[ch]
    w, h = len(rows[0]) + 2, len(rows) + 2
    on = {(x + 1, y + 1) for y, r in enumerate(rows) for x, c in enumerate(r) if c == '#'}
    grid = [[0] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            if (x, y) in on:
                grid[y][x] = 1
            elif any((x + dx, y + dy) in on for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                grid[y][x] = 2
    return [[grid[y // 2][x // 2] for x in range(w * 2)] for y in range(h * 2)]


def cd_tiles(pix):
    out_ = b''
    for ty in range(len(pix) // 8):
        for tx in range(len(pix[0]) // 8):
            out_ += tile_bytes([pix[ty * 8 + y][tx * 8 + x] for y in range(8) for x in range(8)], 2)
    return out_


def build_countdown():
    data = b''.join(cd_tiles(cd_glyph(c)) for c in '321')
    go = [a + b + c for a, b, c in zip(cd_glyph('G'), cd_glyph('O'), cd_glyph('!'))]
    data += cd_tiles(go)
    assert len(data) == 64 * 16, len(data)
    out('cd_big.bin', data)
    img = Image.new('RGBA', (len(go[0]), 32), (60, 120, 60, 255))
    for y, r in enumerate(go):
        for x, v in enumerate(r):
            if v:
                img.putpixel((x, y), (248, 216, 48, 255) if v == 1 else (16, 16, 48, 255))
    preview(img, 'countdown.png', 4)


if __name__ == '__main__':
    print(build())
