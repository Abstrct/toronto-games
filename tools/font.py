"""BG3 text tiles (2bpp): 5x7 font with drop shadow, window frame, HUD icons.
Colour 1 = text, 2 = shadow, 3 = window fill. Tiles 128+ are the same set
with the window fill behind them (for text inside boxes)."""
from snes import tile_bytes, pal_bytes, hexrgb, out

G = {}
def g(ch, *rows):
    G[ch] = rows

g(' ', *['.....'] * 7)
g('!', '..#..', '..#..', '..#..', '..#..', '..#..', '.....', '..#..')
g('"', '.#.#.', '.#.#.', '.....', '.....', '.....', '.....', '.....')
g('#', '.#.#.', '#####', '.#.#.', '.#.#.', '.#.#.', '#####', '.#.#.')
g('$', '..#..', '.####', '#.#..', '.###.', '..#.#', '####.', '..#..')
g('%', '##...', '##..#', '...#.', '..#..', '.#...', '#..##', '...##')
g('&', '.##..', '#..#.', '#.#..', '.#...', '#.#.#', '#..#.', '.##.#')
g("'", '..#..', '..#..', '.#...', '.....', '.....', '.....', '.....')
g('(', '...#.', '..#..', '.#...', '.#...', '.#...', '..#..', '...#.')
g(')', '.#...', '..#..', '...#.', '...#.', '...#.', '..#..', '.#...')
g('*', '.....', '..#..', '#.#.#', '.###.', '#.#.#', '..#..', '.....')
g('+', '.....', '..#..', '..#..', '#####', '..#..', '..#..', '.....')
g(',', '.....', '.....', '.....', '.....', '.##..', '..#..', '.#...')
g('-', '.....', '.....', '.....', '#####', '.....', '.....', '.....')
g('.', '.....', '.....', '.....', '.....', '.....', '.##..', '.##..')
g('/', '.....', '....#', '...#.', '..#..', '.#...', '#....', '.....')
g('0', '.###.', '#...#', '#..##', '#.#.#', '##..#', '#...#', '.###.')
g('1', '..#..', '.##..', '..#..', '..#..', '..#..', '..#..', '.###.')
g('2', '.###.', '#...#', '....#', '...#.', '..#..', '.#...', '#####')
g('3', '#####', '...#.', '..#..', '...#.', '....#', '#...#', '.###.')
g('4', '...#.', '..##.', '.#.#.', '#..#.', '#####', '...#.', '...#.')
g('5', '#####', '#....', '####.', '....#', '....#', '#...#', '.###.')
g('6', '..##.', '.#...', '#....', '####.', '#...#', '#...#', '.###.')
g('7', '#####', '....#', '...#.', '..#..', '.#...', '.#...', '.#...')
g('8', '.###.', '#...#', '#...#', '.###.', '#...#', '#...#', '.###.')
g('9', '.###.', '#...#', '#...#', '.####', '....#', '...#.', '.##..')
g(':', '.....', '.##..', '.##..', '.....', '.##..', '.##..', '.....')
g(';', '.....', '.##..', '.##..', '.....', '.##..', '..#..', '.#...')
g('<', '...#.', '..#..', '.#...', '#....', '.#...', '..#..', '...#.')
g('=', '.....', '.....', '#####', '.....', '#####', '.....', '.....')
g('>', '.#...', '..#..', '...#.', '....#', '...#.', '..#..', '.#...')
g('?', '.###.', '#...#', '....#', '...#.', '..#..', '.....', '..#..')
g('@', '.###.', '#...#', '....#', '.##.#', '#.#.#', '#.#.#', '.###.')
g('A', '.###.', '#...#', '#...#', '#####', '#...#', '#...#', '#...#')
g('B', '####.', '#...#', '#...#', '####.', '#...#', '#...#', '####.')
g('C', '.###.', '#...#', '#....', '#....', '#....', '#...#', '.###.')
g('D', '###..', '#..#.', '#...#', '#...#', '#...#', '#..#.', '###..')
g('E', '#####', '#....', '#....', '####.', '#....', '#....', '#####')
g('F', '#####', '#....', '#....', '####.', '#....', '#....', '#....')
g('G', '.###.', '#...#', '#....', '#.###', '#...#', '#...#', '.####')
g('H', '#...#', '#...#', '#...#', '#####', '#...#', '#...#', '#...#')
g('I', '.###.', '..#..', '..#..', '..#..', '..#..', '..#..', '.###.')
g('J', '..###', '...#.', '...#.', '...#.', '...#.', '#..#.', '.##..')
g('K', '#...#', '#..#.', '#.#..', '##...', '#.#..', '#..#.', '#...#')
g('L', '#....', '#....', '#....', '#....', '#....', '#....', '#####')
g('M', '#...#', '##.##', '#.#.#', '#.#.#', '#...#', '#...#', '#...#')
g('N', '#...#', '#...#', '##..#', '#.#.#', '#..##', '#...#', '#...#')
g('O', '.###.', '#...#', '#...#', '#...#', '#...#', '#...#', '.###.')
g('P', '####.', '#...#', '#...#', '####.', '#....', '#....', '#....')
g('Q', '.###.', '#...#', '#...#', '#...#', '#.#.#', '#..#.', '.##.#')
g('R', '####.', '#...#', '#...#', '####.', '#.#..', '#..#.', '#...#')
g('S', '.####', '#....', '#....', '.###.', '....#', '....#', '####.')
g('T', '#####', '..#..', '..#..', '..#..', '..#..', '..#..', '..#..')
g('U', '#...#', '#...#', '#...#', '#...#', '#...#', '#...#', '.###.')
g('V', '#...#', '#...#', '#...#', '#...#', '#...#', '.#.#.', '..#..')
g('W', '#...#', '#...#', '#...#', '#.#.#', '#.#.#', '#.#.#', '.#.#.')
g('X', '#...#', '#...#', '.#.#.', '..#..', '.#.#.', '#...#', '#...#')
g('Y', '#...#', '#...#', '.#.#.', '..#..', '..#..', '..#..', '..#..')
g('Z', '#####', '....#', '...#.', '..#..', '.#...', '#....', '#####')
g('[', '.###.', '.#...', '.#...', '.#...', '.#...', '.#...', '.###.')
g('\\', '.....', '#....', '.#...', '..#..', '...#.', '....#', '.....')
g(']', '.###.', '...#.', '...#.', '...#.', '...#.', '...#.', '.###.')
g('^', '..#..', '.#.#.', '#...#', '.....', '.....', '.....', '.....')
g('_', '.....', '.....', '.....', '.....', '.....', '.....', '#####')


def glyph_tile(rows):
    """5x7 rows -> 8x8 indices, glyph at (1,0), shadow right/below."""
    on = set()
    for y, r in enumerate(rows):
        for x, c in enumerate(r):
            if c == '#':
                on.add((x + 1, y))
    pix = [0] * 64
    for (x, y) in on:
        for dx, dy in ((1, 0), (0, 1), (1, 1)):
            sx, sy = x + dx, y + dy
            if sx < 8 and sy < 8 and (sx, sy) not in on:
                pix[sy * 8 + sx] = 2
    for (x, y) in on:
        pix[y * 8 + x] = 1
    return pix


def art_tile(rows):
    """8x8 art: '1' text colour, '2' shadow, '3' fill, '.' transparent."""
    pix = []
    for r in rows:
        for c in r:
            pix.append({'1': 1, '2': 2, '3': 3}.get(c, 0))
    return pix


BOX = {
    'TL': ['..2222..', '.211112.', '21133333', '21333333', '21333333', '21333333', '21333333', '21333333'],
    'T':  ['22222222', '11111111', '33333333', '33333333', '33333333', '33333333', '33333333', '33333333'],
    'L':  ['21333333'] * 8,
    'C':  ['33333333'] * 8,
}


def hflip(rows):
    return [r[::-1] for r in rows]


def vflip(rows):
    return list(reversed(rows))


def specials():
    tl = BOX['TL']
    t = BOX['T']
    l = BOX['L']
    c = BOX['C']
    tiles = [tl, t, hflip(tl), l, c, hflip(l), vflip(tl), vflip(t), vflip(hflip(tl))]
    # meter: 0..4 quarters filled
    for q in range(5):
        fill = q * 2
        rows = ['22222222']
        for _ in range(6):
            rows.append(''.join('1' if x < fill else '3' for x in range(8)))
        rows.append('22222222')
        tiles.append(rows)
    tiles.append(['.1......', '.11.....', '.1112...', '.11112..', '.1112...', '.112....', '.12.....', '..2.....'])  # arrow right
    tiles.append(['......1.', '.....11.', '...1112.', '..11112.', '...1112.', '....112.', '.....12.', '......2.'])  # arrow left
    tiles.append(['.11.11..', '1111111.', '11111112', '11111112', '.1111122', '..11122.', '...122..', '....2...'])  # heart
    tiles.append(['.2...2..', '.12.12..', '..121...', '.11111..', '1111111.', '1111111.', '.11111..', '..1112..'])  # medal
    tiles.append(['11111111'] * 8)
    tiles.append(['22222222'] * 8)
    tiles.append(['33333333'] * 8)
    tiles.append(['...1....', '..111...', '.11111..', '1111111.', '..111...', '..111...', '..111...', '...22...'])  # up
    tiles.append(['..111...', '..111...', '..111...', '1111111.', '.11111..', '..111...', '...1....', '...2....'])  # down
    tiles.append(['...1....', '.1.1.1..', '.11111..', '1111111.', '.11111..', '..111...', '...1....', '...1....'])  # maple leaf
    tiles.append(['........', '........', '........', '...11...', '...112..', '....22..', '........', '........'])  # dot
    out_ = [art_tile(r) for r in tiles]
    # 89 / 90: event-picker tick boxes (empty / crossed); 91: copyright sign
    out_.append(glyph_tile(['#######', '#.....#', '#.....#', '#.....#', '#.....#', '#.....#', '#######']))
    out_.append(glyph_tile(['#######', '##...##', '#.#.#.#', '#..#..#', '#.#.#.#', '##...##', '#######']))
    out_.append(glyph_tile(['..###..', '.#...#.', '#.###.#', '#.#...#', '#.###.#', '.#...#.', '..###..']))
    return out_


# ---------------------------------------------------------------- the intro card's pad map
# A 22x8-tile SNES pad drawn in text tiles: 1 = outline / button / d-pad
# (the cell's palette colour), 2 = the dark body, 3 = window fill. The base map
# is all grey; event_card repaints a part's cells in its colour to light it.
PAD_W, PAD_H = 22, 8
PAD_TILE0 = 100            # 28 tiles DMA'd by event_card (the countdown's slots: free until it runs)
PAD_SPARE = [92, 93, 94, 222, 223]   # overflow, kept in txt_tiles for good
PAD_CHALK = 220            # boxed half: printable as code 124 inside a window
PAD_LINE = 221             # leader line, 2 px at the right edge (hflip for the left)
PAD_PAL_GREY, PAD_PAL = 5, {'U': 0, 'D': 0, 'L': 0, 'R': 0, 'C': 0, 'A': 2, 'B': 1, 'X': 3, 'Y': 4}
PAD_BTN = {'X': (17, 1), 'Y': (15, 3), 'A': (19, 3), 'B': (17, 5)}


def pad_bitmap():
    W, H = PAD_W * 8, PAD_H * 8
    def inside(x, y):
        cx, cy = x + 0.5, y + 0.5
        for lx in (32, W - 32):
            if (cx - lx) ** 2 + (cy - 32) ** 2 <= 31.5 ** 2:
                return True
        return 32 <= cx <= W - 32 and 4 <= cy <= H - 4
    px = [[3] * W for _ in range(H)]
    for y in range(H):
        for x in range(W):
            if inside(x, y):
                edge = any(not (0 <= x + dx < W and 0 <= y + dy < H) or not inside(x + dx, y + dy)
                           for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                px[y][x] = 1 if edge else 2
    # d-pad: a 48 px cross on the left lobe, each arm 2x2 tiles, a notch pointing out
    for y in range(8, 56):
        for x in range(8, 56):
            if 24 <= x < 40 or 24 <= y < 40:
                px[y][x] = 1
    for x, y in ((24, 8), (39, 8), (24, 55), (39, 55), (8, 24), (8, 39), (55, 24), (55, 39)):
        px[y][x] = 2
    for i in range(3):
        for d in range(-i, i + 2):
            px[13 + i][31 + d] = 2          # up
            px[50 - i][31 + d] = 2          # down
            px[31 + d][13 + i] = 2          # left
            px[31 + d][50 - i] = 2          # right
    for y in range(29, 35):
        for x in range(29, 35):
            if (x - 31.5) ** 2 + (y - 31.5) ** 2 <= 7:
                px[y][x] = 2
    # buttons: 16 px discs, the letter cut out in the body colour
    for name, (tx, ty) in PAD_BTN.items():
        ox, oy = tx * 8, ty * 8
        for y in range(16):
            for x in range(16):
                px[oy + y][ox + x] = 1 if (x + 0.5 - 8) ** 2 + (y + 0.5 - 8) ** 2 <= 56 else 2
        for gy, row in enumerate(G[name]):
            for gx, c in enumerate(row):
                if c == '#':
                    px[oy + 4 + gy][ox + 6 + gx] = 2
    # select / start: two slanted pills between the halves
    for tx in (9, 12):
        for y, (a, b) in enumerate(((5, 7), (3, 6), (1, 4), (0, 2))):
            for x in range(a, b + 1):
                px[30 + y][tx * 8 + x] = 1
    return px


def pad_build():
    """-> (tiles [(slot, pix)], base map words, region cell lists)"""
    px = pad_bitmap()
    uniq = []                       # (pix tuple)
    words = []
    for ty in range(PAD_H):
        for tx in range(PAD_W):
            pix = tuple(px[ty * 8 + y][tx * 8 + x] for y in range(8) for x in range(8))
            hit = None
            for i, u in enumerate(uniq):
                for h in (0, 1):
                    for v in (0, 1):
                        f = tuple(u[(7 - y if v else y) * 8 + (7 - x if h else x)] for y in range(8) for x in range(8))
                        if f == pix and hit is None:
                            hit = (i, h, v)
            if hit is None:
                uniq.append(pix)
                hit = (len(uniq) - 1, 0, 0)
            words.append(hit)
    slots = list(range(PAD_TILE0, 128)) + PAD_SPARE
    if len(uniq) > len(slots):
        raise SystemExit('pad map: %d tiles, room for %d' % (len(uniq), len(slots)))
    tiles = [(slots[i], list(u)) for i, u in enumerate(uniq)]
    base = [slots[i] | (PAD_PAL_GREY << 10) | 0x2000 | (h << 14) | (v << 15) for i, h, v in words]
    cells = {}
    for k, (x0, y0) in {'U': (3, 1), 'D': (3, 5), 'L': (1, 3), 'R': (5, 3), 'C': (3, 3)}.items():
        cells[k] = [(y0 + dy) * 32 + x0 + dx for dy in (0, 1) for dx in (0, 1)]
    for k, (x0, y0) in PAD_BTN.items():
        cells[k] = [(y0 + dy) * 32 + x0 + dx for dy in (0, 1) for dx in (0, 1)]
    return tiles, base, cells, len(uniq)


def pad_inc(base, cells):
    s = ['; generated by tools/font.py: the intro card\'s pad map', '',
         'PAD_W = %d' % PAD_W, 'PAD_H = %d' % PAD_H, 'PAD_TILE0 = %d' % PAD_TILE0,
         'PAD_NDMA = %d' % (128 - PAD_TILE0), 'PAD_LINE = %d' % PAD_LINE,
         'TXT_CHALK = %d            ; string code (inside a window)' % (PAD_CHALK - 128 + 32), '',
         'pad_base:']
    for r in range(PAD_H):
        s.append('    .word ' + ', '.join('$%04X' % w for w in base[r * PAD_W:(r + 1) * PAD_W]))
    order = 'UDLRABXYC'
    s.append('; four cells a part (offsets from the pad\'s top-left cell, 32 a row), in the')
    s.append('; order U D L R A B X Y (an event\'s mask bits 0-7), then C: the hub, lit with any arm')
    s.append('pad_part_attr: .byte ' + ', '.join('$%02X' % (0x20 | (PAD_PAL[k] << 2)) for k in order))
    s.append('pad_cells:')
    for k in order:
        s.append('    .word %s     ; %s' % (', '.join(str(c) for c in cells[k]), k))
    return '\n'.join(s) + '\n'


TEXT_COLOURS = ['#f8f8f8', '#f8d830', '#f86048', '#68d8f8', '#78e060', '#a8b0c8', '#f89838', '#f888c8']
SHADOW = '#101030'
WINDOW = '#1c3088'


def build():
    plain = []
    for code in range(32, 96):
        plain.append(glyph_tile(G[chr(code)]))
    plain += specials()
    plain += [[0] * 64] * (128 - len(plain))
    boxed = []
    for i, t in enumerate(plain):
        if 64 <= i <= 72:            # frame tiles are the same in both sets
            boxed.append(t)
        else:
            boxed.append([3 if v == 0 else v for v in t])
    full = plain + boxed
    full[PAD_CHALK] = art_tile(['33333333', '33333333', '31111133', '31111123', '33222223',
                                '33333333', '33333333', '33333333'])
    full[PAD_LINE] = art_tile(['33333311'] * 8)
    tiles, base, cells, n = pad_build()
    dma = [[3] * 64 for _ in range(128 - PAD_TILE0)]
    for slot, pix in tiles:
        if slot >= PAD_TILE0 and slot < 128:
            dma[slot - PAD_TILE0] = pix
        else:
            full[slot] = pix
    out('pad_tiles.bin', b''.join(tile_bytes(t, 2) for t in dma))
    out('pad.inc', pad_inc(base, cells).encode())
    data = b''.join(tile_bytes(t, 2) for t in full)
    out('txt_tiles.bin', data)
    pal = []
    for i, c in enumerate(TEXT_COLOURS):
        pal += [(0, 0, 0), hexrgb(c), hexrgb(SHADOW), hexrgb(WINDOW)]
    out('txt_pal.bin', pal_bytes(pal))


if __name__ == '__main__':
    build()
