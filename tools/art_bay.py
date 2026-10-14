"""Bay St Power Walk: side view, King St to Union Station.
BG2: the canyon of towers (1/4 parallax) under a dark HUD band.
BG1: rows 0-16 are one long strip of facades (TD, Royal Bank Plaza, Scotia,
First Canadian Place, ... then Union's colonnade) streamed in column by column
from bay_cols.bin / bay_colidx.bin; rows 17-31 (sidewalk, road) loop.
Union's columns and entablature are high priority so the GO train (sprites,
priority 2) shows only between them. Sprites: walker (with and without the
coffee), crowd, props, beat strip, grade words, GO coach."""
import math
import random
from PIL import Image, ImageDraw
from snes import (TileSet, convert_bg, map_bytes, pal_bytes, hexrgb, snap,
                  out, preview, hdma_gradient)
from sprites import Sheet, render
import people as P

SIDEWALK_TOP = 136
CURB = 191           # the curb, right under lane 2
PANEL_Y = 197       # bottom HUD panel from here down


def rgb(h):
    return snap(hexrgb(h)) + (255,)


HUD_H = 32          # dark HUD band at the top (BG2 rows 0-3): text rows 1 and 3
COURSE_LEN = 3600   # keep in step with src/ev_bay.s
MOD_W = 128
STREET = ['td', 'path', 'rbp', 'coffee', 'fcp', 'bank', 'scotia', 'stone', 'td', 'path',
          'fcp', 'coffee', 'rbp', 'bank', 'scotia', 'td', 'stone', 'path', 'fcp', 'coffee',
          'rbp', 'scotia', 'bank', 'td', 'stone', 'path', 'coffee']
UNION_X = len(STREET) * MOD_W        # 3456: Union's east pavilion starts here
STRIP_W = UNION_X + 4 * MOD_W        # 3968
TRAIN_Y = 80                         # top of the GO train seen between the columns


def far_towers():
    """512x256 BG2: the canyon of towers behind the street, with the dark
    HUD band across the top. Windows sit on the 8 px grid so they repeat."""
    img = Image.new('RGBA', (512, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rnd = random.Random(7)
    lit = rgb('#e8c060')
    styles = {
        'td':    ('#14161e', '#0c0e14', '#2c3448'),
        'gold':  ('#a07828', '#7a5818', '#d0a848'),
        'red':   ('#6c2a2a', '#4e1c1c', '#8c4444'),
        'stone': ('#7c7884', '#5e5a66', '#9c98a8'),
        'white': ('#a8acb8', '#888c9c', '#c8ccd8'),
        'glass': ('#34506c', '#243c54', '#5c7ca0'),
    }
    order = ['td', 'glass', 'stone', 'gold', 'td', 'white', 'red', 'glass', 'td', 'stone', 'white', 'td']
    x = 0
    i = 0
    while x < 512:
        w = rnd.choice([40, 48, 56, 64])
        if 512 - x < 64:
            w = 512 - x
        top = rnd.choice([0, 0, 0, 16, 32, 48])        # most run off the top: a canyon
        body, side, win = (rgb(c) for c in styles[order[i % len(order)]])
        x1 = x + w - 1
        if top and w >= 24:
            d.rectangle([x + 8, top - 8, x1 - 8, top - 1], fill=side)     # mechanical floor
        d.rectangle([x, top, x1, 150], fill=body)
        d.rectangle([x, top, x + 3, 150], fill=side)
        for ty in range(max(top, HUD_H) // 8, 150 // 8):
            for tx in range(x // 8 + 1, (x1 + 1) // 8):
                v = rnd.random()
                for (wx, wy) in ((1, 1), (5, 1), (1, 5), (5, 5)):
                    c = lit if v < 0.12 and (wx + wy) % 4 == 2 else win
                    d.rectangle([tx * 8 + wx, ty * 8 + wy, tx * 8 + wx + 1, ty * 8 + wy + 1], fill=c)
        x += w
        i += 1
    d.rectangle([0, 0, 511, HUD_H - 2], fill=rgb('#0c1020'))
    d.line([0, HUD_H - 1, 511, HUD_H - 1], fill=rgb('#384058'))
    return img


# ---------------------------------------------------------------- street strip
def C(h):
    return rgb(h)


def m_td(d, x0):
    """TD Centre: black steel and bronze glass, Mies grid, glass lobby."""
    blk, mul, gl, gl2 = C('#16161c'), C('#30303c'), C('#3a3a48'), C('#56525a')
    d.rectangle([x0, HUD_H, x0 + 127, 135], fill=blk)
    for y in range(HUD_H, 96, 8):
        for x in range(x0, x0 + 128, 8):
            d.rectangle([x + 2, y + 1, x + 7, y + 6], fill=gl)
            d.point((x + 3, y + 2), fill=gl2)
            d.line([x, y, x, y + 7], fill=mul)
    d.rectangle([x0, 96, x0 + 127, 103], fill=blk)
    lob, warm = C('#5c6474'), C('#c8a870')
    d.rectangle([x0, 104, x0 + 127, 135], fill=lob)
    d.rectangle([x0, 112, x0 + 127, 119], fill=warm)
    for x in range(x0, x0 + 128, 32):
        d.rectangle([x + 12, 104, x + 19, 135], fill=blk)


def m_rbp(d, x0):
    """Royal Bank Plaza: gold glass, saw-tooth folds."""
    g1, g2, g3, g4 = C('#c89830'), C('#a07820'), C('#e8c058'), C('#7a5810')
    d.rectangle([x0, HUD_H, x0 + 127, 135], fill=g2)
    for x in range(x0, x0 + 128, 16):
        d.rectangle([x, HUD_H, x + 7, 103], fill=g1)
        d.line([x + 1, HUD_H, x + 1, 103], fill=g3)
        for y in range(HUD_H, 104, 8):
            d.line([x, y + 7, x + 15, y + 7], fill=g4)
    d.rectangle([x0, 104, x0 + 127, 135], fill=C('#2c2418'))
    d.rectangle([x0, 104, x0 + 127, 107], fill=g4)
    for x in range(x0, x0 + 128, 32):
        d.rectangle([x + 8, 112, x + 23, 135], fill=C('#4a3c28'))
        d.rectangle([x + 15, 112, x + 16, 135], fill=g1)


def m_scotia(d, x0):
    """Scotia Plaza: red granite, slot windows."""
    r1, r2, r3, wn = C('#8c3030'), C('#6a2222'), C('#a84848'), C('#1c2434')
    d.rectangle([x0, HUD_H, x0 + 127, 135], fill=r1)
    for x in range(x0, x0 + 128, 16):
        d.rectangle([x + 9, HUD_H, x + 14, 95], fill=wn)
        d.line([x + 8, HUD_H, x + 8, 95], fill=r2)
        d.line([x + 15, HUD_H, x + 15, 95], fill=r3)
    d.rectangle([x0, 96, x0 + 127, 103], fill=r2)
    for x in range(x0, x0 + 128, 64):
        d.rectangle([x + 16, 108, x + 47, 135], fill=wn)
        d.chord([x + 16, 100, x + 47, 124], 180, 360, fill=wn)
        d.line([x + 32, 112, x + 32, 135], fill=r3)


def m_fcp(d, x0):
    """First Canadian Place: white marble, narrow windows."""
    w1, w2, w3, wn = C('#d0d0d8'), C('#b0b0bc'), C('#e8e8f0'), C('#384860')
    d.rectangle([x0, HUD_H, x0 + 127, 135], fill=w1)
    for x in range(x0, x0 + 128, 8):
        d.rectangle([x + 5, HUD_H, x + 7, 99], fill=wn)
        d.point((x + 4, HUD_H), fill=w3)
        d.line([x + 4, HUD_H, x + 4, 99], fill=w2)
    d.rectangle([x0, 100, x0 + 127, 103], fill=w2)
    d.rectangle([x0 + 8, 108, x0 + 119, 135], fill=C('#5c6474'))
    for x in range(x0 + 8, x0 + 120, 16):
        d.line([x, 108, x, 135], fill=w3)


def m_bank(d, x0):
    """Granite bank: tall windows between pilasters."""
    top = 48
    gr, gr2, gr3, gl, gl2 = C('#a89890'), C('#8c7c76'), C('#c8b8b0'), C('#2c3c58'), C('#4c6a90')
    d.rectangle([x0, top, x0 + 127, 135], fill=gr)
    d.rectangle([x0, top, x0 + 127, top + 3], fill=gr3)
    d.line([x0, top + 4, x0 + 127, top + 4], fill=gr2)
    for k in range(4):
        wx = x0 + 10 + k * 30
        d.rectangle([wx, top + 16, wx + 18, 127], fill=gl)
        d.rectangle([wx + 2, top + 18, wx + 4, 125], fill=gl2)
        d.rectangle([wx - 4, top + 10, wx - 2, 135], fill=gr3)


def m_path(d, x0):
    """Glass lobby, revolving door, PATH sign."""
    top = 40
    gr, gr2, gr3 = C('#a89890'), C('#8c7c76'), C('#c8b8b0')
    glass, glass2, metal = C('#2c3c58'), C('#4c6a90'), C('#b8b8c0')
    d.rectangle([x0, top, x0 + 127, 135], fill=gr)
    d.rectangle([x0, top, x0 + 127, top + 3], fill=gr3)
    d.line([x0, top + 4, x0 + 127, top + 4], fill=gr2)
    for y in range(top + 12, 88, 12):
        for x in range(x0 + 8, x0 + 120, 16):
            d.rectangle([x, y, x + 9, y + 7], fill=glass)
    d.rectangle([x0 + 4, 92, x0 + 123, 135], fill=glass)
    for k in range(x0 + 4, x0 + 124, 12):
        d.line([k, 92, k, 135], fill=metal)
    d.ellipse([x0 + 48, 103, x0 + 80, 135], fill=glass2, outline=metal)
    d.line([x0 + 64, 103, x0 + 64, 135], fill=metal)
    d.rectangle([x0 + 92, 96, x0 + 116, 112], fill=C('#f0f0f0'))
    d.rectangle([x0 + 94, 98, x0 + 100, 110], fill=C('#c82828'))
    for i, c in enumerate(['#f8c020', '#2878d0', '#28a048']):
        d.rectangle([x0 + 102 + i * 4, 100, x0 + 104 + i * 4, 108], fill=C(c))


def m_coffee(d, x0):
    """Low brick block: coffee shop with a striped awning."""
    top = 64
    br, br2, br3 = C('#8a4a34'), C('#6a3424'), C('#a86048')
    d.rectangle([x0, top, x0 + 127, 135], fill=br)
    d.rectangle([x0, top, x0 + 127, top + 3], fill=br3)
    for y in range(top + 8, 96, 4):
        d.line([x0, y, x0 + 127, y], fill=br2)
    for x in range(x0 + 8, x0 + 120, 24):
        d.rectangle([x, top + 10, x + 11, top + 25], fill=C('#2c3c58'))
    d.rectangle([x0 + 8, 100, x0 + 119, 135], fill=C('#6a4028'))
    d.rectangle([x0 + 14, 112, x0 + 70, 131], fill=C('#4c6a90'))
    d.rectangle([x0 + 84, 112, x0 + 104, 135], fill=C('#2c3c58'))
    for k in range(x0 + 6, x0 + 122, 8):
        d.rectangle([k, 98, k + 7, 107], fill=C('#2a6a3a') if (k // 8) % 2 else C('#f0f0f0'))


def m_stone(d, x0):
    """Old stone bank: arched windows, dark arched door, cornice."""
    top = 56
    st, st2, st3, gl, dk = C('#a89890'), C('#8c7c76'), C('#c8b8b0'), C('#2c3c58'), C('#181820')
    d.rectangle([x0, top, x0 + 127, 135], fill=st)
    d.rectangle([x0, top, x0 + 127, top + 3], fill=st3)
    d.rectangle([x0, top + 4, x0 + 127, top + 5], fill=st2)
    for k in range(3):
        wx = x0 + 12 + k * 40
        d.rectangle([wx, top + 18, wx + 20, top + 50], fill=gl)
        d.chord([wx, top + 10, wx + 20, top + 26], 180, 360, fill=gl)
    d.rectangle([x0 + 50, 106, x0 + 74, 135], fill=dk)
    d.chord([x0 + 50, 94, x0 + 74, 118], 180, 360, fill=dk)


MODULES = dict(td=m_td, rbp=m_rbp, scotia=m_scotia, fcp=m_fcp, bank=m_bank, path=m_path,
               coffee=m_coffee, stone=m_stone)

LIME, LIME2, LIME3, LIME4 = '#d8c8a0', '#b8a67c', '#ece0c0', '#8c7a58'
INSIDE, INSIDE2 = '#2a2018', '#3e3226'


def union(d, pri):
    """Union Station: east pavilion, then the colonnade: 16 px columns and
    16 px openings (dark concourse, where the GO train shows), the
    entablature carved UNION STATION. pri: rectangles drawn in front of the
    train (BG1 high priority)."""
    x0 = UNION_X
    l1, l2, l3, l4 = C(LIME), C(LIME2), C(LIME3), C(LIME4)
    # pavilion: solid block with a tall arched window
    d.rectangle([x0, HUD_H, x0 + 63, 135], fill=l1)
    d.rectangle([x0, HUD_H, x0 + 63, HUD_H + 3], fill=l3)
    for y in range(HUD_H + 8, 136, 8):
        d.line([x0, y, x0 + 63, y], fill=l2)
    d.rectangle([x0 + 20, 64, x0 + 43, 127], fill=C(INSIDE2))
    d.chord([x0 + 20, 52, x0 + 43, 76], 180, 360, fill=C(INSIDE2))
    d.line([x0 + 31, 56, x0 + 31, 127], fill=l4)
    d.line([x0 + 20, 96, x0 + 43, 96], fill=l4)
    pri.append((x0, HUD_H, x0 + 63, 135))
    c0 = x0 + 64
    # entablature
    d.rectangle([c0, HUD_H, STRIP_W - 1, 55], fill=l1)
    d.rectangle([c0, HUD_H, STRIP_W - 1, HUD_H + 3], fill=l3)
    d.line([c0, HUD_H + 4, STRIP_W - 1, HUD_H + 4], fill=l4)
    d.rectangle([c0, 52, STRIP_W - 1, 55], fill=l2)
    pri.append((c0, HUD_H, STRIP_W - 1, 55))
    # openings and columns
    d.rectangle([c0, 56, STRIP_W - 1, 135], fill=C(INSIDE))
    for x in range(c0, STRIP_W, 32):
        cx = x + 16
        d.rectangle([cx, 56, cx + 15, 63], fill=l3)            # capital
        d.rectangle([cx + 1, 60, cx + 14, 63], fill=l2)
        d.rectangle([cx + 2, 64, cx + 13, 123], fill=l1)       # shaft, fluted
        for fx in (cx + 4, cx + 7, cx + 10):
            d.line([fx, 64, fx, 123], fill=l2)
        d.line([cx + 12, 64, cx + 12, 123], fill=l4)
        d.line([cx + 3, 64, cx + 3, 123], fill=l3)
        d.rectangle([cx, 124, cx + 15, 135], fill=l3)          # base
        d.line([cx, 128, cx + 15, 128], fill=l2)
        pri.append((cx, 56, cx + 15, 135))
        # a warm lamp in the concourse over each opening
        d.rectangle([x + 6, 60, x + 9, 61], fill=C('#c89850'))
    # steps along the bottom of the openings
    d.rectangle([c0, 128, STRIP_W - 1, 131], fill=l2)
    d.rectangle([c0, 132, STRIP_W - 1, 135], fill=l3)
    pri.append((c0, 128, STRIP_W - 1, 135))
    # UNION STATION, carved, 2x font, centred over the finish
    import font
    text = 'UNION STATION'
    pitch = 12
    cx = COURSE_LEN + 128 - (len(text) * pitch) // 2
    for i, ch in enumerate(text):
        for yy, r in enumerate(font.G[ch]):
            for xx, c in enumerate(r):
                if c == '#':
                    px_, py = cx + i * pitch + xx * 2, 37 + yy * 2
                    d.rectangle([px_, py + 1, px_ + 1, py + 2], fill=l3)
                    d.rectangle([px_, py, px_ + 1, py + 1], fill=l4)


def street_strip():
    """STRIP_W x 136: every facade from King St to Union, plus a mask image of
    the tiles that sit in front of the train."""
    img = Image.new('RGBA', (STRIP_W, 136), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for i, name in enumerate(STREET):
        MODULES[name](d, i * MOD_W)
    pri = []
    union(d, pri)
    return img, pri


def street_floor():
    """512x120 (screen y 136-255): sidewalk, curb, road. Loops."""
    img = Image.new('RGBA', (512, 120), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    o = SIDEWALK_TOP
    sw, sw2, sw3 = rgb('#b4b0ac'), rgb('#9c9894'), rgb('#c8c4c0')
    d.rectangle([0, 0, 511, CURB - 1 - o], fill=sw)
    d.rectangle([0, 0, 511, 3], fill=sw2)
    for x in range(0, 512 + 8, 32):
        d.line([x, 4, x - 8, CURB - 1 - o], fill=sw2)
    for y in (158, 178):
        for x in range(0, 512, 4):
            d.point((x, y - o), fill=sw3)
    d.rectangle([0, CURB - o, 511, CURB + 3 - o], fill=rgb('#d8d8dc'))
    d.line([0, CURB + 4 - o, 511, CURB + 4 - o], fill=rgb('#383840'))
    d.rectangle([0, CURB + 5 - o, 511, 119], fill=rgb('#46464e'))
    # the bottom HUD panel (beat strip, GROOVE, combo), like the top band
    d.rectangle([0, PANEL_Y - o, 511, 119], fill=rgb('#0c1020'))
    d.line([0, PANEL_Y - o, 511, PANEL_Y - o], fill=rgb('#384058'))
    return img


# -------------------------------------------------------------- sprites
PROPS = ['#000000', '#101018', '#d82820', '#f8c818', '#f8f8f8', '#b0b0c0', '#505058', '#6a3c20',
         '#c89058', '#188040', '#0c5028', '#8c8c98', '#c0c0cc', '#7050a0', '#f88820', '#181818']


def word(sh, x, y, text, col):
    """5x7 font word with a dark drop shadow (props palette), 6 px pitch."""
    import font
    on = set()
    for i, ch in enumerate(text):
        for yy, r in enumerate(font.G[ch]):
            for xx, c in enumerate(r):
                if c == '#':
                    on.add((x + i * 6 + xx, y + yy))
    for (px_, py) in on:
        for dx, dy in ((1, 0), (0, 1), (1, 1)):
            if (px_ + dx, py + dy) not in on:
                sh.px(px_ + dx, py + dy, 1)
    for (px_, py) in on:
        sh.px(px_, py, col)


def beat_ui(sh, d):
    """Marker over the walker, the beat strip (target, ticks, foot arrows), grade words."""
    # 'you' marker: yellow down-arrow, dark outline (8x8 at 16,96)
    d.polygon([(17, 97), (23, 97), (20, 102)], fill=3)
    sh.outline(16, 96, 8, 8)
    # big tick (quarter note) at 24,96 / small tick (8th) at 16,104
    d.ellipse([25, 97, 30, 102], fill=4)
    sh.outline(24, 96, 8, 8)
    d.rectangle([19, 107, 21, 109], fill=5)
    sh.outline(16, 104, 8, 8)
    # foot arrows: left at 24,104, right at 64,96
    d.polygon([(25, 108), (29, 105), (29, 111)], fill=3)
    sh.outline(24, 104, 8, 8)
    d.polygon([(70, 100), (66, 97), (66, 103)], fill=3)
    sh.outline(64, 96, 8, 8)
    # target ring 16x16 at 32,96 and lit at 48,96
    for x0, ring, fill in ((32, 4, 1), (48, 3, 14)):
        d.rounded_rectangle([x0 + 1, 97, x0 + 14, 110], radius=3, fill=ring)
        d.rounded_rectangle([x0 + 3, 99, x0 + 12, 108], radius=2, fill=fill)
        sh.outline(x0, 96, 16, 16)
    word(sh, 0, 112, 'PERFECT', 3)
    word(sh, 48, 112, 'GOOD', 4)
    word(sh, 80, 112, 'EARLY', 14)
    word(sh, 96, 128, 'LATE', 14)


def go_coach(sh, d, x0, y0):
    """64x32 GO bi-level coach side (props palette), repeats end to end."""
    d.rectangle([x0, y0 + 1, x0 + 63, y0 + 27], fill=4)                 # white body
    d.rectangle([x0 + 1, y0, x0 + 62, y0 + 2], fill=12)                 # roof
    d.line([x0 + 1, y0, x0 + 62, y0], fill=6)
    for wx in range(x0 + 14, x0 + 50, 6):                               # upper deck windows
        d.rectangle([wx, y0 + 4, wx + 4, y0 + 8], fill=1)
    d.rectangle([x0, y0 + 11, x0 + 63, y0 + 12], fill=9)                # green stripe
    for wx in range(x0 + 14, x0 + 50, 6):                               # lower deck windows
        d.rectangle([wx, y0 + 14, wx + 4, y0 + 18], fill=1)
    d.rectangle([x0, y0 + 21, x0 + 63, y0 + 27], fill=9)                # green skirt
    d.line([x0, y0 + 21, x0 + 63, y0 + 21], fill=10)
    for dx in (3, 52):                                                   # doors
        d.rectangle([x0 + dx, y0 + 4, x0 + dx + 8, y0 + 27], fill=5)
        d.line([x0 + dx + 4, y0 + 4, x0 + dx + 4, y0 + 27], fill=11)
        d.rectangle([x0 + dx + 1, y0 + 6, x0 + dx + 3, y0 + 10], fill=1)
        d.rectangle([x0 + dx + 5, y0 + 6, x0 + dx + 7, y0 + 10], fill=1)
    for (gx, rows) in ((26, ('###', '#..', '#.#', '#.#', '###')), (30, ('###', '#.#', '#.#', '#.#', '###'))):
        for yy, r in enumerate(rows):
            for xx, c in enumerate(r):
                if c == '#':
                    sh.px(x0 + gx + xx, y0 + 22 + yy, 4)
    d.rectangle([x0, y0 + 28, x0 + 63, y0 + 29], fill=15)               # underframe
    for wx in (8, 18, 44, 54):                                           # bogie wheels
        d.ellipse([x0 + wx - 3, y0 + 27, x0 + wx + 2, y0 + 31], fill=6)
        d.point((x0 + wx - 1, y0 + 29), fill=11)
    d.line([x0, y0 + 1, x0, y0 + 29], fill=15)                          # gap between cars
    d.line([x0 + 63, y0 + 1, x0 + 63, y0 + 29], fill=11)


def go_engine(sh, d, x0, y0):
    """64x32 GO diesel (MP40-ish) facing right: green and white, boxy cab
    with a raked windshield at the head, GO on the side."""
    d.rectangle([x0, y0 + 6, x0 + 57, y0 + 27], fill=4)                  # white body
    d.rectangle([x0 + 2, y0 + 3, x0 + 44, y0 + 5], fill=12)              # roof hatches
    for hx in (6, 18, 30):
        d.rectangle([x0 + hx, y0 + 1, x0 + hx + 7, y0 + 2], fill=11)     # radiators / fans
        d.line([x0 + hx + 1, y0 + 1, x0 + hx + 6, y0 + 1], fill=6)
    # cab: taller box at the head with a raked nose
    d.polygon([(x0 + 44, y0 + 2), (x0 + 56, y0 + 2), (x0 + 62, y0 + 12), (x0 + 63, y0 + 27),
               (x0 + 44, y0 + 27)], fill=4)
    d.line([x0 + 44, y0 + 2, x0 + 56, y0 + 2], fill=12)
    d.polygon([(x0 + 52, y0 + 5), (x0 + 56, y0 + 5), (x0 + 60, y0 + 12), (x0 + 52, y0 + 12)], fill=1)  # windshield
    d.rectangle([x0 + 46, y0 + 5, x0 + 50, y0 + 10], fill=1)            # side window
    d.point((x0 + 57, y0 + 7), fill=5)
    # green lower body and the swoosh up to the cab
    d.rectangle([x0, y0 + 17, x0 + 63, y0 + 27], fill=9)
    d.polygon([(x0 + 40, y0 + 17), (x0 + 63, y0 + 13), (x0 + 63, y0 + 17)], fill=9)
    d.line([x0, y0 + 17, x0 + 40, y0 + 17], fill=10)
    d.line([x0, y0 + 27, x0 + 63, y0 + 27], fill=10)
    # GO logo on the hood
    for (gx, rows) in ((16, ('###', '#..', '#.#', '#.#', '###')), (20, ('###', '#.#', '#.#', '#.#', '###'))):
        for yy, r in enumerate(rows):
            for xx, c in enumerate(r):
                if c == '#':
                    sh.px(x0 + gx + xx, y0 + 20 + yy, 4)
    d.rectangle([x0 + 59, y0 + 22, x0 + 62, y0 + 24], fill=3)            # headlight
    d.rectangle([x0 + 34, y0 + 8, x0 + 36, y0 + 15], fill=11)            # door
    d.rectangle([x0, y0 + 28, x0 + 63, y0 + 29], fill=15)                # underframe
    for wx in (8, 16, 46, 54):                                           # trucks
        d.ellipse([x0 + wx - 3, y0 + 27, x0 + wx + 2, y0 + 31], fill=6)
        d.point((x0 + wx - 1, y0 + 29), fill=11)
    d.rectangle([x0 + 24, y0 + 28, x0 + 36, y0 + 30], fill=6)            # fuel tank
    d.line([x0, y0 + 6, x0, y0 + 29], fill=15)


def go_cab(sh, d, x0, y0):
    """16x32: the cab end of the last coach (the tail, facing left)."""
    go_coach(sh, d, x0, y0)
    d.rectangle([x0 + 16, y0, x0 + 63, y0 + 31], fill=0)
    d.rectangle([x0, y0, x0 + 3, y0 + 31], fill=0)                       # rake the nose
    d.polygon([(x0 + 4, y0 + 1), (x0 + 15, y0 + 1), (x0 + 15, y0 + 27), (x0 + 1, y0 + 27),
               (x0 + 1, y0 + 12)], fill=4)
    d.line([x0 + 4, y0 + 1, x0 + 15, y0 + 1], fill=12)
    d.polygon([(x0 + 4, y0 + 4), (x0 + 9, y0 + 4), (x0 + 9, y0 + 10), (x0 + 2, y0 + 10)], fill=1)  # cab window
    d.rectangle([x0 + 11, y0 + 14, x0 + 14, y0 + 18], fill=1)
    d.rectangle([x0 + 1, y0 + 11, x0 + 15, y0 + 12], fill=9)             # stripe
    d.rectangle([x0 + 1, y0 + 21, x0 + 15, y0 + 27], fill=9)
    d.line([x0 + 1, y0 + 21, x0 + 15, y0 + 21], fill=10)
    d.rectangle([x0 + 2, y0 + 23, x0 + 4, y0 + 25], fill=2)              # tail lights
    d.rectangle([x0 + 1, y0 + 28, x0 + 15, y0 + 29], fill=15)
    d.ellipse([x0 + 6, y0 + 27, x0 + 11, y0 + 31], fill=6)
    d.point((x0 + 8, y0 + 29), fill=11)


# ---------------------------------------------------------------- the power walker
def _wlimb(d, x, y, ang, length, col, width=2):
    ex = x + math.sin(math.radians(ang)) * length
    ey = y + math.cos(math.radians(ang)) * length
    d.line([x, y, ex, ey], fill=col, width=width)
    return ex, ey


def walker_pose(i, n=8):
    """Power-walk cycle: straight-ish planted leg, swinging knee, elbows at
    90 degrees pumping against the legs, hips and shoulders counter-rotating."""
    ph = 2 * math.pi * i / n
    s, c = math.sin(ph), math.cos(ph)
    front = 34 * s                     # near leg, + = forward
    back = -front
    # the leg swinging forward bends at the knee
    kf = 34 * max(0.0, c)
    kb = 34 * max(0.0, -c)
    arm_f = -58 * s                    # near arm opposite to the near leg
    arm_b = 58 * s
    bob = -1 if abs(s) < 0.45 else 0   # rises as the legs pass
    return dict(legs=(front, back), knees=(kf, kb), arms=(arm_f, arm_b), bob=bob)


def draw_walker(sh, x0, y0, legs=(0, 0), knees=(0, 0), arms=(0, 0), elbows=(95, 95), bob=0,
                lean=1, head_tilt=0, cup=True, arm_up=False):
    """32x32 power walker facing right, feet at y0+31, centred on x0+16.
    Returns the near hand's position (for the coffee cup sprite)."""
    d = sh.draw()
    cx = x0 + 15
    hip = (cx, y0 + 17 + bob)
    sho = (cx + lean + 1, y0 + 8 + bob)

    def leg(front):
        i = 0 if front else 1
        col = 8 if front else 9
        kx, ky = _wlimb(d, hip[0], hip[1], legs[i], 7, col, 3)
        fx, fy = _wlimb(d, kx, ky, legs[i] - knees[i], 7, col, 2)
        # shoe: heel back, toe forward
        d.line([fx - 2, fy, fx + 3, fy], fill=11)
        d.line([fx - 1, fy - 1, fx + 2, fy - 1], fill=11)
        d.point((fx + 3, fy - 1), fill=10)

    def arm(front):
        i = 0 if front else 1
        col = 5 if front else 6
        ex, ey = _wlimb(d, sho[0], sho[1] + 1, arms[i], 5, col, 2)
        if arm_up and front:
            hx, hy = _wlimb(d, ex, ey, arms[i] - 30, 5, col, 2)
        else:
            hx, hy = _wlimb(d, ex, ey, arms[i] + elbows[i], 5, col, 2)
        d.rectangle([hx - 1, hy - 1, hx, hy], fill=2)
        return hx, hy

    arm(False)
    leg(False)
    # torso: track jacket, zip stripe, a little forward lean
    d.polygon([(cx - 3 + lean, y0 + 8 + bob), (cx + 3 + lean, y0 + 8 + bob),
               (cx + 3, y0 + 18 + bob), (cx - 3, y0 + 18 + bob)], fill=5)
    d.line([cx - 3 + lean, y0 + 9 + bob, cx - 3, y0 + 17 + bob], fill=6)
    d.line([cx + 2 + lean, y0 + 9 + bob, cx + 2, y0 + 16 + bob], fill=7)
    d.line([cx - 3, y0 + 18 + bob, cx + 3, y0 + 18 + bob], fill=9)       # waistband
    leg(True)
    # head: hair, sweatband, eye, ear
    hx = cx - 3 + lean + head_tilt
    hy = y0 + bob
    d.ellipse([hx, hy, hx + 7, hy + 8], fill=2)
    d.chord([hx, hy - 1, hx + 7, hy + 5], 180, 360, fill=4)
    d.rectangle([hx, hy + 1, hx + 1, hy + 5], fill=4)
    d.line([hx + 1, hy + 2, hx + 7, hy + 2], fill=12)                  # sweatband
    d.point((hx + 6, hy + 4), fill=1)
    d.point((hx + 2, hy + 5), fill=3)
    d.point((hx + 7, hy + 6), fill=3)
    hand = arm(True)
    sh.outline(x0, y0, 32, 32)
    return hand


W_STAND = dict(legs=(5, -5), knees=(0, 0), arms=(-10, 10), elbows=(80, 80), bob=0, lean=0)
W_EXCUSE = dict(legs=(14, -10), knees=(0, 12), arms=(-150, 20), elbows=(0, 90), bob=0, lean=-1, arm_up=True)
W_STUMBLE = dict(legs=(34, -26), knees=(0, 0), arms=(-160, -130), elbows=(10, 10), bob=1, lean=-3)


# (x, y) of each 32x32 walker frame: 8 stride frames, stand, excuse, stumble
W_FRAMES = [(0, 0), (32, 0), (64, 0), (0, 128), (32, 128), (64, 128), (64, 192), (96, 192),
            (0, 224), (32, 224), (64, 224)]


def coffee_cup(d, x, y):
    """8x8 at (x, y): the cup in hand, white with a green sleeve and a lid
    (props palette). The hand grips it at (4, 4)."""
    d.rectangle([x + 2, y + 2, x + 5, y + 7], fill=4)
    d.rectangle([x + 2, y + 4, x + 5, y + 5], fill=9)
    d.rectangle([x + 1, y + 1, x + 6, y + 1], fill=7)
    d.point((x + 3, y), fill=12)


def build_sprites():
    sh = Sheet(256)
    d = sh.draw()
    # the walker: 32x32 frames; the coffee is its own sprite at the hand
    hands = []
    poses = [walker_pose(i) for i in range(8)] + [W_STAND, W_EXCUSE, W_STUMBLE]
    for (x, y), pose in zip(W_FRAMES, poses):
        hx, hy = draw_walker(sh, x, y, **pose)
        hands.append((int(round(hx)) - x, int(round(hy)) - y))
    coffee_cup(d, 96, 0)
    sh.outline(96, 0, 8, 8)
    # coffee splash (props palette)
    for (x, y, r) in ((116, 6, 2), (121, 4, 1), (119, 10, 2), (124, 9, 1), (114, 11, 1)):
        d.ellipse([x - r, y - r, x + r, y + r], fill=7)
    # pigeon frames
    for k, up in enumerate((0, 1)):
        x0 = 112 + 8 * k
        d.ellipse([x0 + 1, 18 + up, x0 + 6, 22 + up], fill=11)
        d.ellipse([x0 + 4, 16 + up * 2, x0 + 7, 19 + up * 2], fill=12)
        d.point((x0 + 7, 18 + up * 2), fill=3)
        d.point((x0 + 5, 22 + up), fill=13)
        d.line([x0 + 3, 23, x0 + 3, 23], fill=14)
    # crowd
    for i, f in enumerate(P.WALK):
        P.draw_person(sh, i * 16, 32, **f)
    for i in range(2):
        f = dict(P.WALK[i * 2])
        f['arms'] = (-70, f['arms'][1])
        f['elbows'] = (60, 0)
        P.draw_person(sh, 64 + i * 16, 32, head_down=True, item=P.phone, **f)
    P.draw_person(sh, 96, 32, **dict(P.STAND, arms=(-100, -95), elbows=(60, 60)))
    d.rectangle([108, 41, 111, 43], fill=1)
    P.draw_person(sh, 112, 32, **P.STAND)
    for i, f in enumerate(P.RUN):
        P.draw_person(sh, i * 16, 64, **f)
    # hot dog cart 32x32 at (64,64)
    d.polygon([(66, 70), (94, 70), (88, 64), (72, 64)], fill=3)
    for k in range(66, 94, 6):
        d.polygon([(k, 70), (k + 3, 70), (80, 64)], fill=2)
    d.line([80, 70, 80, 78], fill=5)
    d.rectangle([66, 78, 94, 90], fill=5)
    d.rectangle([66, 78, 94, 80], fill=4)
    d.rectangle([70, 82, 90, 87], fill=2)
    d.ellipse([70, 88, 76, 94], fill=15)
    d.ellipse([86, 88, 92, 94], fill=15)
    sh.outline(64, 64, 32, 32)
    # sandwich board 16x32 at (96,64)
    d.polygon([(99, 74), (108, 74), (110, 95), (97, 95)], fill=15)
    d.rectangle([99, 76, 108, 90], fill=4)
    d.line([101, 80, 106, 80], fill=2)
    d.line([101, 84, 106, 84], fill=7)
    sh.outline(96, 64, 16, 32)
    # camera flash 16x16 at (0,96)
    d.polygon([(8, 96), (10, 104), (8, 111), (6, 104)], fill=4)
    d.polygon([(0, 104), (8, 102), (15, 104), (8, 106)], fill=4)
    d.ellipse([5, 101, 11, 107], fill=3)
    beat_ui(sh, d)
    go_coach(sh, d, 0, 160)
    go_engine(sh, d, 64, 160)
    go_cab(sh, d, 0, 192)
    word(sh, 16, 192, 'MISS', 5)
    # PRESTO gold tick: the bar's downbeat (8x8 at 48,192)
    d.ellipse([49, 193, 55, 199], fill=3)
    d.ellipse([51, 195, 53, 197], fill=14)
    sh.outline(48, 192, 8, 8)

    names = [('npc0', 0, 32), ('npc1', 16, 32), ('npc2', 32, 32), ('npc3', 48, 32),
             ('zombie0', 64, 32), ('zombie1', 80, 32), ('photo', 96, 32), ('npcstand', 112, 32),
             ('jog0', 0, 64), ('jog1', 16, 64), ('jog2', 32, 64), ('jog3', 48, 64),
             ('board', 96, 64)]
    for n, x, y in names:
        sh.obj(n, x, y, 16, 32, 8, 31)
    sh.obj('cart', 64, 64, 32, 32, 16, 31)
    for i, (x, y) in enumerate(W_FRAMES):
        sh.obj('pw%d' % i, x, y, 32, 32, 16, 31)
    sh.obj('cup', 96, 0, 8, 8, 4, 4)
    sh.obj('coach', 0, 160, 64, 32, 0, 0)
    sh.obj('loco', 64, 160, 64, 32, 0, 0)
    sh.obj('cab', 0, 192, 16, 32, 0, 0)
    sh.obj('wmiss', 16, 192, 32, 16, 0, 0)
    sh.obj('tickgold', 48, 192, 8, 8, 4, 4)
    sh.obj('splash', 112, 0, 16, 16)
    sh.obj('pigeon0', 112, 16, 8, 8, 4, 7)
    sh.obj('pigeon1', 120, 16, 8, 8, 4, 7)
    sh.obj('flash', 0, 96, 16, 16)
    sh.obj('marker', 16, 96, 8, 8, 4, 7)
    sh.obj('tickbig', 24, 96, 8, 8, 4, 4)
    sh.obj('ticksm', 16, 104, 8, 8, 4, 4)
    sh.obj('footl', 24, 104, 8, 8, 4, 4)
    sh.obj('footr', 64, 96, 8, 8, 4, 4)
    sh.obj('target', 32, 96, 16, 16, 8, 8)
    sh.obj('targetlit', 48, 96, 16, 16, 8, 8)
    sh.obj('wperfect', 0, 112, 48, 16, 0, 0)
    sh.obj('wgood', 48, 112, 32, 16, 0, 0)
    sh.obj('wearly', 80, 112, 32, 16, 0, 0)
    sh.obj('wlate', 96, 128, 32, 16, 0, 0)
    out('bay_spr.bin', sh.tiles())
    with open('build/bay_meta.inc', 'w') as f:
        f.write(sh.meta_inc())
        # where the coffee cup goes on each walker frame: its top-left
        # relative to the feet anchor (frame x 16, y 31), grip at (4, 4)
        f.write('walker_cup:\n')
        for (hx, hy) in hands:
            f.write('    .byte $%02X, $%02X\n' % ((hx - 16 - 4) & 0xFF, (hy - 31 - 4) & 0xFF))
    data = bytearray()
    for p in P.CROWD:
        data += pal_bytes(p, 16)
    data += pal_bytes([hexrgb(c) for c in PROPS], 16)
    out('bay_spr_pal.bin', data)      # sprite palettes 1..5
    return sh


def pack_palettes(img, max_pals):
    """Like snes.build_palettes, but packs harder: tile colour sets go to the
    palette they grow least, with seeded reshuffles until they fit."""
    from snes import rgba_pixels, tile_colours
    img, px = rgba_pixels(img)
    w, h = img.size
    sets = set()
    for ty in range(h // 8):
        for tx in range(w // 8):
            c = frozenset(tile_colours(px, tx, ty))
            if c:
                sets.add(c)
    sets = [a for a in sets if not any(a < b for b in sets)]
    rnd = random.Random(1)
    order = sorted(sets, key=lambda a: -len(a))
    for attempt in range(400):
        pals = []
        ok = True
        for a in order:
            best, grow = None, 99
            for p in pals:
                u = len(p | a)
                if u <= 15 and u - len(p) < grow:
                    best, grow = p, u - len(p)
            if best is None:
                pals.append(set(a))
            else:
                best |= a
            if len(pals) > max_pals:
                ok = False
                break
        if ok:
            return [[(0, 0, 0)] + sorted(p, key=lambda c: (c[0] * 3 + c[1] * 6 + c[2])) for p in pals]
        order = sorted(sets, key=lambda a: (-len(a), rnd.random()))
        if attempt > 50:
            rnd.shuffle(order)
    raise ValueError('palettes do not pack into %d' % max_pals)


def strip_columns(rows, pri):
    """rows: [17][STRIP_W/8] map words. Returns (column table, column index)."""
    ncol = len(rows[0])
    table, index, seen = [], bytearray(), {}
    for c in range(ncol):
        col = []
        for r in range(17):
            w = rows[r][c]
            x, y = c * 8, r * 8
            if any(x0 <= x and x + 7 <= x1 and y0 <= y and y + 7 <= y1 for (x0, y0, x1, y1) in pri):
                w |= 0x2000
            col.append(w)
        key = tuple(col)
        if key not in seen:
            seen[key] = len(table)
            table.append(col)
        index.append(seen[key])
    assert len(table) <= 256, len(table)
    data = bytearray()
    for col in table:
        for w in col:
            data += bytes((w & 0xFF, w >> 8))
    return data, index


def build():
    far = far_towers()
    strip, pri = street_strip()
    floor = street_floor()
    allimg = Image.new('RGBA', (STRIP_W, 256 + 120 + 136), (0, 0, 0, 0))
    allimg.paste(far, (0, 0))
    allimg.paste(floor, (0, 256))
    allimg.paste(strip, (0, 376))
    pals = pack_palettes(allimg, 6)
    ts = TileSet(4)
    m_far = convert_bg(far, pals, 2, ts)
    m_floor = convert_bg(floor, pals, 2, ts)
    m_strip = convert_bg(strip, pals, 2, ts)
    cols, idx = strip_columns(m_strip, pri)
    near = [[0] * 64 for _ in range(32)]
    for r in range(17):
        for c in range(64):
            near[r][c] = (cols[2 * (idx[c] * 17 + r)] | cols[2 * (idx[c] * 17 + r) + 1] << 8)
    for r in range(15):
        near[17 + r] = m_floor[r]
    out('bay_tiles.bin', ts.data())
    out('bay_bg1.bin', map_bytes(near)[:4096])
    out('bay_bg2.bin', map_bytes(m_far)[:4096])
    out('bay_cols.bin', cols)
    out('bay_colidx.bin', idx)
    data = bytearray()
    for p in pals:
        data += pal_bytes(p, 16)
    data += bytes(32 * (6 - len(pals)))
    out('bay_pal.bin', data)
    sh = build_sprites()
    hdma_gradient([(0, '#0c1020'), (HUD_H, '#0c1020'), (HUD_H + 1, '#3a3c70'), (90, '#a85878'),
                   (130, '#f08850'), (150, '#f8b070')], 'bay_sky.bin')
    # preview: the start, and the finish
    def scene(x):
        img = Image.new('RGBA', (256, 224), rgb('#88b8e8'))
        img.alpha_composite(far.crop((x // 4 % 256, 0, x // 4 % 256 + 256, 224)))
        img.alpha_composite(strip.crop((x, 0, x + 256, 136)), (0, 0))
        img.alpha_composite(floor.crop((x % 256, 0, x % 256 + 256, 88)), (0, 136))
        return img
    a, b = scene(0), scene(COURSE_LEN)
    b.alpha_composite(render(sh, (0, 160, 64, 32), PROPS), (100, TRAIN_Y))
    b.alpha_composite(render(sh, (0, 0, 32, 32), P.ATHLETE), (56, 141))
    a.alpha_composite(render(sh, (0, 0, 32, 32), P.ATHLETE), (56, 141))
    a.alpha_composite(render(sh, (16, 32, 16, 32), P.CROWD[0]), (110, 125))
    both = Image.new('RGBA', (512, 224))
    both.paste(a, (0, 0))
    both.paste(b, (256, 0))
    preview(both, 'bay.png')
    return '%d tiles, %d pals, %d strip columns' % (len(ts), len(pals), len(cols) // 34)


if __name__ == '__main__':
    print(build())
