"""Off-Leash Alert: Trinity Bellwoods, 3/4 top-down. A 256x2560 park map
(streamed by rows) on BG1, autumn tree canopies on BG2 (high priority,
packed), collision and "behind a canopy" bitmaps, the dog / ball placements,
and sprites for the walker, dogs and tennis balls. World y grows downward:
start gate at the bottom (Queen St), finish gate at the top (Dundas).
Landmarks: the tennis courts, the dog bowl, the drum circle."""
import math
import random
from PIL import Image, ImageDraw
from snes import (TileSet, convert_bg, build_palettes, raw_map_bytes, pal_bytes, hexrgb, snap,
                  out, preview, hdma_gradient)
from sprites import Sheet, render
import people as P

W, H = 256, 2560


def rgb(h):
    return snap(hexrgb(h)) + (255,)


COL = {k: rgb(v) for k, v in {
    'g1': '#4c9a3c', 'g2': '#58a844', 'g3': '#3e8634', 'gdark': '#2e6a2a',
    'p1': '#d8c494', 'p2': '#c4ae7c', 'p3': '#e8d8b0',
    't1': '#1e5a26', 't2': '#2c7432', 't3': '#46923e', 'trunk': '#5a3a20', 'shadow': '#2a5a24',
    'wood': '#8a5a30', 'wood2': '#5c3a1c', 'iron': '#282830', 'stone': '#c8c4b8', 'stone2': '#9c988c',
    'red': '#d03030', 'white': '#f0f0f0', 'blue': '#3060c0', 'yellow': '#e8c030',
    'bowl': '#3a7a30', 'bowl2': '#346c2c', 'bowl3': '#448c38', 'fence': '#f0f0f0',
    'skin': '#e8b888', 'skin2': '#a86840', 'hair': '#402818',
    'shirt': '#c04878', 'shirt2': '#3888c8', 'pants': '#283050',
    # autumn in Bellwoods
    'm1': '#8c1c14', 'm2': '#c83020', 'm3': '#f06030',          # red maple
    'o1': '#9c5410', 'o2': '#e09020', 'o3': '#f8c840',          # sugar maple, gold
    's1': '#143c24', 's2': '#245a34',                            # spruce
    'leaf': '#d06a20', 'leaf2': '#e8a030',
    'court': '#2f6e62', 'court2': '#3a8272', 'line': '#f0f0f0', 'mesh': '#9c988c',
    'drum': '#a0582c', 'drum2': '#e8d8b0',
}.items()}

solid = set()       # (tx, ty) tiles that block walking
behind = set()      # (tx, ty): feet here are behind a tree canopy (sprite drawn under it)


def mark_solid(x0, y0, x1, y1):
    for ty in range(max(0, y0 // 8), min(H // 8, y1 // 8 + 1)):
        for tx in range(max(0, x0 // 8), min(W // 8, x1 // 8 + 1)):
            solid.add((tx, ty))


def mark_behind(x0, y0, x1, y1):
    for ty in range(max(0, y0 // 8), min(H // 8, y1 // 8 + 1)):
        for tx in range(max(0, x0 // 8), min(W // 8, x1 // 8 + 1)):
            behind.add((tx, ty))


DOTS = {(3, 2), (11, 5), (6, 9), (14, 12), (1, 14), (9, 1)}


def grass(img):
    px = img.load()
    for y in range(H):
        for x in range(W):
            stripe = ((y // 16) % 2)
            c = COL['g1'] if stripe else COL['g2']
            if (x % 16, y % 16) in DOTS:
                c = COL['g3']
            px[x, y] = c


def path_points():
    """main path: centre wanders in 8px steps every 32px band"""
    pts = []
    for y in range(0, H, 32):
        x = 128 + 40 * math.sin(y / 260.0) + 18 * math.sin(y / 97.0 + 1.3)
        pts.append((int(round(x / 8.0)) * 8, y))
    return pts


def draw_path(d, pts, width):
    for (x, y) in pts:
        d.rectangle([x - width // 2, y, x + width // 2 - 1, y + 31], fill=COL['p1'])
    for (x, y) in pts:
        d.line([x - width // 2, y, x - width // 2, y + 31], fill=COL['p2'])
        d.line([x + width // 2 - 1, y, x + width // 2 - 1, y + 31], fill=COL['p3'])


SPECIES = {
    'oak':    ('t1', 't2', 't3'),
    'maple':  ('m1', 'm2', 'm3'),
    'gold':   ('o1', 'o2', 'o3'),
}


def tree(d, cd, cx, cy, r=14, kind='oak', var=0):
    """trunk + shadow on the ground (d), canopy on the canopy layer (cd).
    cy = canopy centre; the trunk foot is at cy + r. Every (kind, r, var)
    is the same stamp, so on a 16 x 32 grid the tiles repeat."""
    rnd = random.Random('%s-%d-%d' % (kind, r, var))
    foot = cy + r
    d.ellipse([cx - r + 4, foot - 5, cx + r + 2, foot + 4], fill=COL['shadow'])
    d.rectangle([cx - 2, cy, cx + 2, foot], fill=COL['trunk'])
    d.line([cx + 2, cy + 2, cx + 2, foot], fill=COL['wood2'])
    mark_solid(cx - 3, foot - 6, cx + 3, foot)
    # feet anywhere north of the trunk's foot and under the canopy (or half a
    # dog's 32 px body to its side: the leaves reach 1.1 r) are behind the
    # tree; from a few px above its top edge so a dog stood just behind it
    # can't paint its legs over the leaves
    mark_behind(cx - r - 16, cy - r - 6, cx + r + 16, foot - 1)
    if kind == 'spruce':
        for i in range(4):
            w = 4 + i * 3
            y = cy - r + i * (r // 2)
            cd.polygon([(cx, y - 2), (cx - w, y + r // 2 + 2), (cx + w, y + r // 2 + 2)], fill=COL['s1'])
            cd.polygon([(cx - 1, y), (cx - w + 3, y + r // 2), (cx, y + r // 2)], fill=COL['s2'])
        return
    c1, c2, c3 = (COL[k] for k in SPECIES[kind])
    blobs = []
    for i in range(6):
        a = rnd.random() * math.tau
        k = rnd.uniform(0.2, 0.45) * r
        blobs.append((cx + math.cos(a) * k, cy - 3 + math.sin(a) * k * 0.8, r * rnd.uniform(0.55, 0.65)))
    for (x, y, rr) in blobs:
        cd.ellipse([x - rr, y - rr, x + rr, y + rr * 0.9], fill=c1)
    for (x, y, rr) in blobs:
        cd.ellipse([x - rr * 0.8 - 1, y - rr * 0.85 - 1, x + rr * 0.55 - 1, y + rr * 0.45 - 1], fill=c2)
    for (x, y, rr) in blobs[:2]:
        cd.ellipse([x - rr * 0.45 - 2, y - rr * 0.6 - 2, x + rr * 0.1 - 2, y - rr * 0.1 - 2], fill=c3)
    if kind != 'oak':                       # fallen leaves on the grass
        for i in range(8):
            lx = cx + rnd.randint(-r - 2, r + 4)
            ly = foot + rnd.randint(-2, 5)
            d.point((lx, ly), fill=COL['leaf' if i % 2 else 'leaf2'])


def bench(d, cx, cy):
    d.rectangle([cx - 12, cy - 4, cx + 12, cy + 1], fill=COL['wood'])
    d.rectangle([cx - 12, cy + 2, cx + 12, cy + 3], fill=COL['wood2'])
    d.rectangle([cx - 12, cy - 7, cx + 12, cy - 6], fill=COL['wood2'])
    d.rectangle([cx - 10, cy + 4, cx - 9, cy + 6], fill=COL['iron'])
    d.rectangle([cx + 9, cy + 4, cx + 10, cy + 6], fill=COL['iron'])
    mark_solid(cx - 12, cy - 2, cx + 12, cy + 4)


def blanket(d, cx, cy, c1, c2, owner_shirt):
    for yy in range(4):
        for xx in range(6):
            col = COL[c1] if (xx + yy) % 2 else COL[c2]
            d.rectangle([cx - 12 + xx * 4, cy - 8 + yy * 4, cx - 9 + xx * 4, cy - 5 + yy * 4], fill=col)
    # owner sitting on the blanket
    d.ellipse([cx - 4, cy - 14, cx + 2, cy - 8], fill=COL['skin'])
    d.chord([cx - 4, cy - 15, cx + 2, cy - 10], 180, 360, fill=COL['hair'])
    d.rectangle([cx - 5, cy - 8, cx + 3, cy - 2], fill=COL[owner_shirt])
    d.rectangle([cx - 5, cy - 2, cx + 5, cy], fill=COL['pants'])


def gate(d, y, top, cd=None):
    """Trinity Bellwoods gate: stone pillars, iron arch, fence either side.
    cd: the canopy layer: the arch goes there too, so whoever's walked
    through it is drawn behind it. Dundas (top, the way out): feet in or past
    the gateway are behind it. Queen (the way in): feet north of the gate
    line, up to where a 32 px sprite no longer reaches the arch"""
    for x in range(0, W, 6):
        d.rectangle([x, y, x + 1, y + 14], fill=COL['iron'])
    d.rectangle([0, y + 2, W - 1, y + 3], fill=COL['iron'])
    d.rectangle([0, y + 11, W - 1, y + 12], fill=COL['iron'])
    gx = 128
    d.rectangle([gx - 40, y - 6, gx + 40, y + 16], fill=COL['p1'])
    for px_ in (gx - 44, gx + 32):
        d.rectangle([px_, y - 22, px_ + 12, y + 18], fill=COL['stone'])
        d.rectangle([px_ + 9, y - 22, px_ + 12, y + 18], fill=COL['stone2'])
        d.rectangle([px_ - 2, y - 26, px_ + 14, y - 22], fill=COL['stone2'])
    d.arc([gx - 32, y - 40, gx + 32, y + 8], 180, 360, fill=COL['iron'], width=3)
    d.arc([gx - 26, y - 34, gx + 26, y + 2], 180, 360, fill=COL['iron'], width=1)
    if cd is not None:
        cd.arc([gx - 32, y - 40, gx + 32, y + 8], 180, 360, fill=COL['iron'], width=3)
        cd.arc([gx - 26, y - 34, gx + 26, y + 2], 180, 360, fill=COL['iron'], width=1)
        if top:
            mark_behind(gx - 36, 0, gx + 36, y + 14)
        else:
            mark_behind(gx - 48, y - 44, gx + 48, y + 14)
    mark_solid(0, y, gx - 33, y + 14)
    mark_solid(gx + 33, y, W - 1, y + 14)
    mark_solid(gx - 44, y - 6, gx - 32, y + 18)
    mark_solid(gx + 32, y - 6, gx + 44, y + 18)


def tennis(d, x0, y0, x1, y1):
    """the Bellwoods courts: green hard court, white lines, chain-link fence"""
    d.rectangle([x0, y0, x1, y1], fill=COL['court'])
    cx = (x0 + x1) // 2
    for (a, b) in ((y0 + 6, (y0 + y1) // 2 - 2), ((y0 + y1) // 2 + 2, y1 - 6)):
        d.rectangle([x0 + 8, a, x1 - 8, b], fill=COL['court2'], outline=COL['line'])
        d.line([x0 + 14, a, x0 + 14, b], fill=COL['line'])
        d.line([x1 - 14, a, x1 - 14, b], fill=COL['line'])
        m = (a + b) // 2
        d.line([x0 + 14, m, x1 - 14, m], fill=COL['line'])
        d.line([cx, a + 10, cx, b - 10], fill=COL['line'])
        d.line([x0 + 14, a + 10, x1 - 14, a + 10], fill=COL['line'])
        d.line([x0 + 14, b - 10, x1 - 14, b - 10], fill=COL['line'])
    # the net between the two halves of each court (they run left-right)
    for (a, b) in ((y0 + 6, (y0 + y1) // 2 - 2), ((y0 + y1) // 2 + 2, y1 - 6)):
        d.line([cx, a - 1, cx, b + 1], fill=COL['white'])
        d.line([cx + 1, a - 1, cx + 1, b + 1], fill=COL['mesh'])
    # chain-link fence round it: a dither of posts and wire
    for x in range(x0, x1 + 1):
        for y in (y0, y0 + 1, y1 - 1, y1):
            if (x + y) % 2 == 0:
                d.point((x, y), fill=COL['mesh'])
    for y in range(y0, y1 + 1):
        for x in (x0, x0 + 1, x1 - 1, x1):
            if (x + y) % 2 == 0:
                d.point((x, y), fill=COL['mesh'])
    for x in range(x0, x1 + 1, 16):
        d.rectangle([x, y0 - 2, x + 1, y0 + 1], fill=COL['iron'])
        d.rectangle([x, y1 - 1, x + 1, y1 + 1], fill=COL['iron'])
    mark_solid(x0, y0, x1, y1)


def drummer(d, x, y, shirt, skin='skin'):
    d.ellipse([x - 3, y - 12, x + 3, y - 6], fill=COL[skin])
    d.chord([x - 3, y - 13, x + 3, y - 8], 180, 360, fill=COL['hair'])
    d.rectangle([x - 4, y - 6, x + 4, y + 1], fill=COL[shirt])
    d.rectangle([x - 5, y + 1, x + 5, y + 3], fill=COL['pants'])
    # the djembe in front
    d.rectangle([x - 2, y - 1, x + 2, y + 5], fill=COL['drum'])
    d.ellipse([x - 3, y - 3, x + 3, y], fill=COL['drum2'])
    mark_solid(x - 4, y - 2, x + 4, y + 4)


def drum_circle(d, cx, cy, rnd):
    """Sunday drum circle: a worn patch of dirt and eight drummers round it"""
    d.ellipse([cx - 34, cy - 22, cx + 34, cy + 22], fill=COL['p2'])
    d.ellipse([cx - 28, cy - 18, cx + 28, cy + 18], fill=COL['p1'])
    shirts = ['shirt', 'shirt2', 'red', 'yellow', 'shirt', 'blue', 'shirt2', 'red']
    for i in range(8):
        a = i / 8 * math.tau
        x = int(cx + math.cos(a) * 30)
        y = int(cy + math.sin(a) * 18)
        drummer(d, x, y, shirts[i], 'skin' if i % 3 else 'skin2')


def dog_bowl(d, y0, y1):
    """The dog bowl: a big sunken hollow. Seen from the south you look down
    the terraced north bank; straight sides so the tiles repeat."""
    x0, x1 = 16, W - 17
    d.rounded_rectangle([x0, y0, x1, y1], radius=32, fill=COL['bowl2'])
    d.rounded_rectangle([x0 + 8, y0 + 40, x1 - 8, y1 - 8], radius=24, fill=COL['bowl'])
    # the north bank's terraces
    for k in range(8, 40, 8):
        d.line([x0 + 24, y0 + k, x1 - 24, y0 + k], fill=COL['bowl3'])
    # floor: soft stripes like the mown grass up top
    for y in range(y0 + 48, y1 - 16, 32):
        d.rectangle([x0 + 16, y, x1 - 16, y + 15], fill=COL['bowl3'])
    # the rim fence posts, gaps where the path goes through
    for x in range(x0 + 24, x1 - 23, 16):
        if abs(x - 128) < 40:
            continue
        d.rectangle([x, y0 - 4, x + 1, y0 + 1], fill=COL['fence'])
        d.rectangle([x, y1 - 2, x + 1, y1 + 3], fill=COL['fence'])


def hammock(d, x0, x1, y):
    d.line([x0, y - 6, x1, y - 6], fill=COL['iron'])
    for x in range(x0 + 4, x1 - 3):
        sag = int(4 * math.sin((x - x0) / (x1 - x0) * math.pi))
        d.line([x, y - 6 + sag, x, y - 2 + sag], fill=COL['blue' if (x // 3) % 2 else 'yellow'])
    mx = (x0 + x1) // 2
    d.ellipse([mx - 9, y - 6, mx - 4, y - 1], fill=COL['skin'])
    d.rectangle([mx - 4, y - 4, mx + 6, y], fill=COL['red'])


def park_image():
    img = Image.new('RGBA', (W, H), (0, 0, 0, 255))
    can = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    grass(img)
    d = ImageDraw.Draw(img)
    cd = ImageDraw.Draw(can)
    pts = path_points()
    dog_bowl(d, 1120, 1488)
    draw_path(d, pts, 24)
    # cross paths near the bottom and top
    for yy in (2304, 704):
        d.rectangle([8, yy - 8, 247, yy + 7], fill=COL['p1'])
        d.line([8, yy - 8, 247, yy - 8], fill=COL['p3'])
        d.line([8, yy + 7, 247, yy + 7], fill=COL['p2'])
    # edge fences (the park boundary)
    for y in range(0, H, 8):
        d.rectangle([2, y, 3, y + 3], fill=COL['iron'])
        d.rectangle([252, y, 253, y + 3], fill=COL['iron'])
    mark_solid(0, 0, 7, H - 1)
    mark_solid(248, 0, W - 1, H - 1)
    rnd = random.Random(11)
    path_x = {y: x for (x, y) in pts}
    used = set()

    def px_at(y):
        return path_x.get(y // 32 * 32, 128)

    def near_path(x, y, gap=40):
        return any(abs(x - px_at(yy)) < gap for yy in (y - 32, y, y + 32))

    def claim(x0, y0, x1, y1):
        for ty in range(y0 // 32, y1 // 32 + 1):
            for tx in range(x0 // 32, x1 // 32 + 1):
                used.add((tx, ty))

    def free(x, y):
        k = (x // 32, y // 32)
        if k in used:
            return False
        used.add(k)
        return True

    # landmarks first
    court = None
    for y in (1880,):
        px_ = px_at(y)
        if px_ > 128:
            court = (14, y, px_ - 30, y + 150)
        else:
            court = (px_ + 30, y, 241, y + 150)
        tennis(d, *court)
        claim(court[0], court[1] - 16, court[2], court[3] + 16)
    dc = (196 if px_at(860) < 128 else 60, 860)
    drum_circle(d, dc[0], dc[1], rnd)
    claim(dc[0] - 40, dc[1] - 40, dc[0] + 40, dc[1] + 30)
    claim(0, 1110, W - 1, 1490)                     # the bowl keeps its trees on the rim
    # trees on a 16 x 32 grid so the stamps' tiles repeat; a line along each
    # fence, then a scatter in the open
    kinds = ['oak', 'oak', 'maple', 'gold', 'spruce', 'oak', 'gold', 'maple']

    def plant(x, foot):
        r = rnd.choice((12, 16))
        tree(d, cd, x, foot - r, r, rnd.choice(kinds), rnd.randrange(2))

    for y in range(160, H - 140, 64):
        for x in (24, 232):
            if free(x, y):
                plant(x, y + 16)
    for _ in range(80):
        x = rnd.randrange(3, 14) * 16 + 8
        y = rnd.randrange(5, H // 32 - 5) * 32
        if near_path(x, y) or not free(x, y):
            continue
        plant(x, y + 16)
    # the bowl's rim trees
    for (x, y) in ((40, 1120), (216, 1120), (40, 1504), (216, 1504)):
        tree(d, cd, x, y - 16, 16, 'gold' if x < 128 else 'maple', 1)
    for _ in range(14):
        x = rnd.randrange(4, 12) * 16
        y = rnd.randrange(7, H // 32 - 7) * 32
        if near_path(x, y) or abs(y - 2304) < 24 or abs(y - 704) < 24:
            continue
        if any((x // 32 + dx, y // 32 + dy) in used for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
            continue                            # room to walk round it
        free(x, y)
        bench(d, x, y)
    # no yellow blankets: a yellow jersey vanished on them in the playtest
    blankets = [('red', 'white', 'shirt'), ('blue', 'white', 'shirt2'), ('blue', 'red', 'shirt')]
    for i in range(14):
        x = rnd.randrange(4, 12) * 16
        y = rnd.randrange(8, H // 32 - 8) * 32 + 16
        if near_path(x, y) or not free(x, y):
            continue
        c1, c2, sh = blankets[i % 3]
        blanket(d, x, y, c1, c2, sh)
    gate(d, H - 60, False, cd)
    gate(d, 52, True, cd)
    return img, can, court, dc


# ------------------------------------------------------------ sprites
DOGS = {
    # fur, shade, light
    'doodle': ('#e8c890', '#c09860', '#f8e8c0'),
    'lab':    ('#383030', '#201818', '#585050'),
    'husky':  ('#a8a8b8', '#686878', '#f0f0f8'),
    'corgi':  ('#e08838', '#a85818', '#f8f0e0'),
}
DOG_BASE = ['#000000', '#101018', None, None, None, '#101010', '#f07888', '#d82828',
            '#f8f8f8', '#c8d838', '#88a020', '#f8e040', '#e02818']


def dog_pal(name):
    c = list(DOG_BASE)
    c[2], c[3], c[4] = DOGS[name]
    return [hexrgb(x) for x in c]




def _ln(d, a, b, col, w=1):
    d.line([a[0], a[1], b[0], b[1]], fill=col, width=w)


def draw_dog2(sh, x0, y0, pose, frame, corgi=False):
    """side view facing right in a 32x16 cell, feet on row 15.
    pose: run (frame 0-3), stand (0-1 wag), lunge, sit (0-1 wag)."""
    d = sh.draw()
    X = lambda v: x0 + v
    Y = lambda v: y0 + v
    if corgi:
        leg = 3
        by0, by1 = 7, 12          # body top / bottom
        bx0, bx1 = 6, 21
    else:
        leg = 5
        by0, by1 = 4, 10
        bx0, bx1 = 6, 21
    bob = 0
    if pose == 'run':
        bob = (0, -1, 0, 1)[frame] if not corgi else (0, -1, 0, 0)[frame]
    lift = -2 if pose == 'lunge' else 0
    oy = bob + lift
    if pose == 'sit':
        _sit(d, X, Y, frame, corgi)
        sh.outline(x0, y0, 32, 16)
        return
    hipx, shx = bx0 + 3, bx1 - 3
    ground = 15
    # gait: (front near, front far, back near, back far) foot x offsets
    if pose == 'run':
        g = [(4, 2, -4, -2), (1, -1, 1, 2), (-3, -1, 3, 1), (-1, 1, -1, -2)][frame]
    elif pose == 'lunge':
        g = (6, 5, -6, -5)
    else:
        g = (0, 1, 0, -1)
    legtop = by1 - 1 + oy
    foot = ground + (lift if pose == 'lunge' else 0)
    # far legs (shade)
    for hx, off in ((shx + 1, g[1]), (hipx + 1, g[3])):
        _ln(d, (X(hx), Y(legtop)), (X(hx + off // 2), Y(foot - 1)), 3, 2)
    # tail
    if pose == 'stand':
        tip = [(-4, -5), (-5, -2)][frame]
    elif pose == 'run':
        tip = [(-5, -2), (-5, -3), (-5, -2), (-5, -1)][frame]
    else:
        tip = (-6, -1)
    tb = (X(bx0 + 1), Y(by0 + 2 + oy))
    if corgi:
        d.ellipse([tb[0] - 3, tb[1] - 2, tb[0] + 1, tb[1] + 1], fill=4)
    else:
        _ln(d, tb, (tb[0] + tip[0], tb[1] + tip[1]), 2, 2)
        d.point((tb[0] + tip[0], tb[1] + tip[1]), fill=4)
    # body
    if pose == 'lunge':
        d.ellipse([X(bx0 - 1), Y(by0 + oy), X(bx1 + 1), Y(by1 + oy - 1)], fill=2)
    else:
        d.ellipse([X(bx0), Y(by0 + oy), X(bx1), Y(by1 + oy)], fill=2)
    _ln(d, (X(bx0 + 4), Y(by0 + 1 + oy)), (X(bx1 - 4), Y(by0 + 1 + oy)), 4)   # back highlight
    _ln(d, (X(bx0 + 3), Y(by1 + oy)), (X(bx1 - 3), Y(by1 + oy)), 3)          # belly shade
    if corgi:
        d.ellipse([X(bx1 - 6), Y(by0 + 2 + oy), X(bx1), Y(by1 + oy)], fill=4)  # white chest
    # near legs
    for hx, off in ((shx, g[0]), (hipx, g[2])):
        fx = hx + off // 2
        _ln(d, (X(hx), Y(legtop)), (X(fx), Y(foot - 1)), 2, 2)
        d.point((X(fx + 1), Y(foot)), fill=1)
        d.point((X(fx), Y(foot)), fill=1)
    # head
    hx0, hy0 = (bx1 - 3, by0 - 4 + oy) if not corgi else (bx1 - 2, by0 - 4 + oy)
    if pose == 'lunge':
        hx0 += 2
        hy0 += 2
    d.ellipse([X(hx0), Y(hy0), X(hx0 + 7), Y(hy0 + 7)], fill=2)
    if corgi:
        d.ellipse([X(hx0 + 4), Y(hy0 + 3), X(hx0 + 7), Y(hy0 + 7)], fill=4)
    # snout
    d.rectangle([X(hx0 + 6), Y(hy0 + 3), X(hx0 + 9), Y(hy0 + 6)], fill=4 if corgi else 2)
    d.point((X(hx0 + 9), Y(hy0 + 3)), fill=5)           # nose
    d.point((X(hx0 + 5), Y(hy0 + 2)), fill=5)           # eye
    if pose in ('run', 'lunge') or (pose == 'stand' and frame == 1):
        d.point((X(hx0 + 7), Y(hy0 + 7)), fill=6)       # tongue
        d.point((X(hx0 + 7), Y(hy0 + 8)), fill=6)
    # ear
    if corgi:
        d.polygon([(X(hx0 + 1), Y(hy0 + 1)), (X(hx0 + 2), Y(hy0 - 3)), (X(hx0 + 4), Y(hy0 + 1))], fill=2)
        d.point((X(hx0 + 2), Y(hy0 - 1)), fill=6)
    elif pose == 'lunge':
        _ln(d, (X(hx0 + 2), Y(hy0 + 1)), (X(hx0 - 1), Y(hy0 + 1)), 3, 2)   # ears flat back
    else:
        d.rectangle([X(hx0), Y(hy0 + 1), X(hx0 + 2), Y(hy0 + 6)], fill=3)   # floppy ear
    # collar
    _ln(d, (X(hx0 + 1), Y(hy0 + 7)), (X(hx0 + 2), Y(hy0 + 8)), 7)
    sh.outline(x0, y0, 32, 16)


def _sit(d, X, Y, frame, corgi):
    # rear on the ground, chest up, front legs straight, tail sweeping
    if corgi:
        d.ellipse([X(7), Y(9), X(17), Y(15)], fill=2)
        d.ellipse([X(13), Y(6), X(20), Y(14)], fill=4)
        hx0, hy0 = 15, 0
    else:
        d.ellipse([X(7), Y(7), X(16), Y(15)], fill=2)
        d.ellipse([X(12), Y(3), X(19), Y(13)], fill=2)
        d.ellipse([X(14), Y(5), X(18), Y(11)], fill=4)
        hx0, hy0 = 14, -1
    tail = [(-5, 0), (-4, -3)][frame]
    _ln(d, (X(8), Y(13)), (X(8 + tail[0]), Y(13 + tail[1])), 2 if not corgi else 4, 2)
    for fx in (15, 17):
        _ln(d, (X(fx), Y(10)), (X(fx), Y(14)), 2, 1)
        d.point((X(fx), Y(15)), fill=1)
    d.ellipse([X(hx0), Y(hy0), X(hx0 + 7), Y(hy0 + 7)], fill=2)
    d.rectangle([X(hx0 + 6), Y(hy0 + 3), X(hx0 + 9), Y(hy0 + 6)], fill=4 if corgi else 2)
    d.point((X(hx0 + 9), Y(hy0 + 3)), fill=5)
    d.point((X(hx0 + 5), Y(hy0 + 2)), fill=5)
    d.point((X(hx0 + 7), Y(hy0 + 7)), fill=6)
    d.point((X(hx0 + 7), Y(hy0 + 8)), fill=6)
    if corgi:
        d.polygon([(X(hx0 + 1), Y(hy0 + 2)), (X(hx0 + 2), Y(max(hy0 - 2, 0))), (X(hx0 + 4), Y(hy0 + 2))], fill=2)
    else:
        d.rectangle([X(hx0 + 1), Y(hy0 + 1), X(hx0 + 3), Y(hy0 + 5)], fill=3)
    _ln(d, (X(hx0 + 1), Y(hy0 + 7)), (X(hx0 + 2), Y(hy0 + 8)), 7)


DOG_POSES = [('run', 0), ('run', 1), ('run', 2), ('run', 3), ('stand', 0), ('stand', 1),
             ('lunge', 0), ('sit', 0), ('sit', 1)]


def draw_walker(sh, x0, y0, facing, step, arms_out=False, crouch=0):
    """3/4 view walker 16x24 at (x0, y0+8) within a 16x32 cell.
    step: -1 / 1 = a stride, 0 = passing (legs together)"""
    d = sh.draw()
    y0 += 6 + crouch
    lx = step
    # legs
    if facing in ('down', 'up'):
        d.rectangle([x0 + 5, y0 + 16, x0 + 7, y0 + 21 + lx], fill=8)
        d.rectangle([x0 + 9, y0 + 16, x0 + 11, y0 + 21 - lx], fill=9)
        d.rectangle([x0 + 5, y0 + 22 + lx, x0 + 7, y0 + 23 + lx], fill=11)
        d.rectangle([x0 + 9, y0 + 22 - lx, x0 + 11, y0 + 23 - lx], fill=11)
    else:
        d.line([x0 + 7, y0 + 16, x0 + 7 + 3 * lx, y0 + 22], fill=8, width=2)
        d.line([x0 + 8, y0 + 16, x0 + 8 - 3 * lx, y0 + 22], fill=9, width=2)
    # body
    d.rounded_rectangle([x0 + 4, y0 + 8, x0 + 11, y0 + 17], radius=2, fill=5)
    d.line([x0 + 4, y0 + 9, x0 + 4, y0 + 16], fill=6)
    if facing == 'down':
        d.line([x0 + 7, y0 + 9, x0 + 8, y0 + 9], fill=7)
    # arms
    if arms_out:          # set for the dog: arms wide, matador style
        d.rectangle([x0 + 0, y0 + 9, x0 + 3, y0 + 10], fill=5)
        d.rectangle([x0 + 12, y0 + 9, x0 + 15, y0 + 10], fill=6)
        d.point((x0 + 0, y0 + 8), fill=2)
        d.point((x0 + 15, y0 + 8), fill=2)
    else:
        d.rectangle([x0 + 2, y0 + 9 + lx, x0 + 3, y0 + 14 + lx], fill=5)
        d.rectangle([x0 + 12, y0 + 9 - lx, x0 + 13, y0 + 14 - lx], fill=6)
        d.point((x0 + 2, y0 + 15 + lx), fill=2)
        d.point((x0 + 13, y0 + 15 - lx), fill=2)
    # head
    d.ellipse([x0 + 4, y0 + 0, x0 + 11, y0 + 8], fill=2)
    if facing == 'up':
        d.ellipse([x0 + 4, y0 - 1, x0 + 11, y0 + 7], fill=4)
    elif facing == 'down':
        d.chord([x0 + 4, y0 - 1, x0 + 11, y0 + 5], 180, 360, fill=4)
        d.point((x0 + 6, y0 + 4), fill=1)
        d.point((x0 + 9, y0 + 4), fill=1)
    else:
        d.chord([x0 + 4, y0 - 1, x0 + 11, y0 + 5], 180, 360, fill=4)
        d.rectangle([x0 + 4, y0 + 1, x0 + 6, y0 + 5], fill=4)
        d.point((x0 + 10, y0 + 4), fill=1)
    sh.outline(x0, y0 - 6 - crouch, 16, 32)


def draw_down(sh, x0, y0, kick=False):
    """knocked over, 16x16 (kick: flat on your back, legs in the air)"""
    d = sh.draw()
    d.rounded_rectangle([x0 + 2, y0 + 8, x0 + 11, y0 + 13], radius=2, fill=5)
    d.ellipse([x0 + 10, y0 + 6, x0 + 15, y0 + 12], fill=2)
    d.chord([x0 + 10, y0 + 5, x0 + 15, y0 + 11], 270, 90, fill=4)
    if kick:
        d.line([x0 + 3, y0 + 9, x0 + 0, y0 + 2], fill=8, width=2)
        d.line([x0 + 5, y0 + 9, x0 + 4, y0 + 3], fill=9, width=2)
        d.point((x0 + 0, y0 + 1), fill=11)
        d.point((x0 + 4, y0 + 2), fill=11)
        d.line([x0 + 8, y0 + 8, x0 + 9, y0 + 4], fill=6, width=1)      # an arm waving
    else:
        d.line([x0 + 0, y0 + 11, x0 + 3, y0 + 14], fill=8, width=2)
        d.line([x0 + 0, y0 + 8, x0 + 3, y0 + 10], fill=9, width=2)
    sh.outline(x0, y0, 16, 16)


MISC = ['#000000', '#101018', '#d8e838', '#98a820', '#204818', '#f8f8f8', '#e02818', '#f8e040',
        '#b0b0c0', '#f0a0b0']


SQUIRREL = [
    # 16x16, facing right: big white plume of a tail, pink ear, black eye
    ['................', '................', '..555...........', '.55855..........',
     '.558855.........', '555885..........', '55588.......55..', '5558.......5595.',
     '.558......55515.', '..58....555555..', '...5..55555588..', '....5555555588..',
     '.....55555588...', '......8555.88...', '.......8.8......', '................'],
    ['................', '..55............', '.5585...........', '.55885..........',
     '555885..........', '55588...........', '5558........55..', '.558.......5595.',
     '..58......55515.', '...5....555555..', '....5.5555555888', '.....555555588..',
     '......555558....', '.....8.8..8.....', '................', '................'],
]


def draw_squirrel(sh, x0, y0, frame):
    rows = SQUIRREL[frame]
    sh.ascii(x0, y0, rows, {'5': 5, '8': 8, '9': 9, '1': 1})
    sh.outline(x0, y0, 16, 16)


def build_sprites():
    sh = Sheet(160)
    # walker: strides, passing frames, the matador set, the pat, the tumble
    frames = [('d', 'down', -1), ('d', 'down', 1), ('u', 'up', -1), ('u', 'up', 1),
              ('s', 'side', -1), ('s', 'side', 1), ('dp', 'down', 0), ('upp', 'up', 0)]
    for i, (n, f, st) in enumerate(frames):
        draw_walker(sh, i * 16, 0, f, st)
    draw_walker(sh, 0, 32, 'side', 0)                                   # walk_sp
    draw_walker(sh, 16, 32, 'up', 0, arms_out=True, crouch=2)           # ready
    draw_walker(sh, 32, 32, 'side', 0, crouch=3)                        # pat
    d = sh.draw()
    d.rectangle([32 + 11, 32 + 6 + 3 + 9, 32 + 14, 32 + 6 + 3 + 10], fill=5)
    d.rectangle([32 + 14, 32 + 6 + 3 + 10, 32 + 15, 32 + 6 + 3 + 13], fill=5)
    d.point((32 + 15, 32 + 6 + 3 + 14), fill=2)
    sh.outline(32, 32, 16, 32)
    # the tumble: a cartwheel (90, 180, 270 degrees) before you land
    tmp = Sheet(32)
    draw_walker(tmp, 0, 0, 'down', 0)
    fig = tmp.img.crop((0, 4, 16, 32))                # 16 x 28
    r180 = fig.rotate(180)
    sh.img.paste(r180, (48, 32 + 2))
    r90 = fig.rotate(90, expand=True)                 # 28 x 16
    sh.img.paste(r90, (2, 144))
    r270 = fig.rotate(270, expand=True)
    sh.img.paste(r270, (34, 144))
    draw_down(sh, 64, 32)
    draw_down(sh, 64, 48, kick=True)
    d = sh.draw()
    # "!" bubble
    d.rectangle([82, 32, 90, 42], fill=5, outline=1)
    d.rectangle([85, 34, 87, 38], fill=6)
    d.rectangle([85, 40, 87, 40], fill=6)
    d.polygon([(84, 43), (88, 43), (85, 46)], fill=5, outline=1)
    draw_squirrel(sh, 96, 32, 0)
    draw_squirrel(sh, 112, 32, 1)
    # tennis ball, its shadow, a heart, a warning arrow, the walker's shadow
    d.ellipse([81, 49, 86, 54], fill=2)
    d.arc([81, 49, 86, 54], 200, 340, fill=3)
    d.ellipse([89, 53, 94, 55], fill=4)
    d.polygon([(96, 51), (98, 49), (100, 51), (102, 49), (104, 51), (100, 55)], fill=6, outline=1)
    d.point((98, 50), fill=5)
    d.polygon([(105, 49), (111, 49), (108, 55)], fill=7, outline=1)
    d.ellipse([114, 50, 125, 54], fill=4)
    # dogs: big (doodle / lab / husky) then the corgi
    for k, corgi in enumerate((False, True)):
        for i, (pose, f) in enumerate(DOG_POSES):
            j = k * 9 + i
            draw_dog2(sh, (j % 4) * 32, 64 + (j // 4) * 16, pose, f, corgi)
    names = [('walk_d0', 0), ('walk_d1', 16), ('walk_u0', 32), ('walk_u1', 48), ('walk_s0', 64),
             ('walk_s1', 80), ('walk_dp', 96), ('walk_up', 112)]
    for n, x in names:
        sh.obj(n, x, 0, 16, 32, 8, 30)
    sh.obj('walk_sp', 0, 32, 16, 32, 8, 30)
    sh.obj('ready', 16, 32, 16, 32, 8, 30)
    sh.obj('pat', 32, 32, 16, 32, 8, 30)
    sh.obj('tumb2', 48, 32, 16, 32, 8, 30)
    sh.obj('tumb1', 0, 144, 32, 16, 16, 14)
    sh.obj('tumb3', 32, 144, 32, 16, 16, 14)
    sh.obj('down', 64, 32, 16, 16, 8, 14)
    sh.obj('downk', 64, 48, 16, 16, 8, 14)
    sh.obj('bang', 80, 32, 16, 16, 8, 15)
    sh.obj('sq0', 96, 32, 16, 16, 8, 14)
    sh.obj('sq1', 112, 32, 16, 16, 8, 14)
    sh.obj('ball', 80, 48, 8, 8, 4, 4)
    sh.obj('shadow', 88, 48, 8, 8, 4, 6)
    sh.obj('heart', 96, 48, 8, 8, 4, 7)
    sh.obj('arrow', 104, 48, 8, 8, 4, 0)
    sh.obj('pshadow', 112, 48, 16, 8, 8, 2)
    for k, tag in enumerate(('dog', 'pup')):
        for i in range(9):
            j = k * 9 + i
            sh.obj('%s%d' % (tag, i), (j % 4) * 32, 64 + (j // 4) * 16, 32, 16, 16, 14)
    t = sh.tiles()
    out('park_spr.bin', t[:128 * 32])        # walker + odds and ends (GFX4, assets.s)
    out('park_spr2.bin', t[128 * 32:])       # the dogs (loaded after it, from ev_park.s)
    with open('build/park_meta.inc', 'w') as f:
        f.write(sh.meta_inc())
    data = bytearray()
    for n in ('doodle', 'lab', 'husky', 'corgi'):
        data += pal_bytes(dog_pal(n), 16)
    data += pal_bytes([hexrgb(c) for c in MISC], 16)
    red = list(MISC)                     # 6: the red "!" over a crouched dog
    red[5], red[6] = MISC[6], MISC[5]    # (red bubble, white mark)
    data += pal_bytes([hexrgb(c) for c in red], 16)
    out('park_spr_pal.bin', data)        # sprite palettes 1..6
    return sh


def place_dogs(court, dc):
    """the 16 dogs (x, kind, y) and 8 spare balls (x, y): same for every player"""
    rnd = random.Random(23)
    pts = path_points()
    path_x = {y: x for (x, y) in pts}

    def blocked(x, y):
        if (x // 8, y // 8) in solid or (x // 8, (y - 8) // 8) in solid:
            return True
        if court and court[0] - 8 <= x <= court[2] + 8 and court[1] - 8 <= y <= court[3] + 8:
            return True
        return abs(x - dc[0]) < 44 and abs(y - dc[1]) < 30

    dogs = []
    kinds = [0, 3, 1, 2, 3, 0, 2, 1, 3, 1, 0, 2, 3, 2, 1, 0]
    # a forgiving first minute: wide gaps between the first dogs, closing up
    # (170 px, about 3 s of walking, down to 104) as you near Dundas
    y0 = 2370
    for i in range(16):
        y = y0 + rnd.randint(-12, 12)
        y0 -= 170 - i * 66 // 15
        px_ = path_x.get(y // 32 * 32, 128)
        for _ in range(60):
            side = rnd.choice((-1, 1))
            x = px_ + side * rnd.randint(34, 84)
            if 1120 < y < 1480:
                x = rnd.randint(40, 216)        # the bowl: anywhere on its floor
            if 28 <= x <= 228 and not blocked(x, y):
                break
        dogs.append((x, kinds[i], y))
    balls = []
    for i in range(8):
        y = 2260 - i * 256 + rnd.randint(-20, 20)
        px_ = path_x.get(y // 32 * 32, 128)
        for _ in range(60):
            x = px_ + rnd.choice((-1, 1)) * rnd.randint(18, 40)
            if 20 <= x <= 236 and not blocked(x, y):
                break
        balls.append((x, y))
    data = bytearray()
    for (x, k, y) in dogs:
        data += bytes((x, k, y & 0xFF, y >> 8))
    for (x, y) in balls:
        data += bytes((x, 0, y & 0xFF, y >> 8))
    out('park_dogs.bin', data)
    return dogs, balls


def bitmap(cells):
    bits = bytearray(H // 8 * 4)
    for (tx, ty) in cells:
        bits[ty * 4 + tx // 8] |= 0x80 >> (tx % 8)
    return bits


def build():
    solid.clear()
    behind.clear()
    img, can, court, dc = park_image()
    both = Image.new('RGBA', (W, H * 2), (0, 0, 0, 0))
    both.paste(img, (0, 0))
    both.paste(can, (0, H))
    fixed = [[COL[k][:3] for k in names.split()] for names in (
        'm1 m2 m3 o1 o2 o3 s1 s2 t1 t2 t3',
        'g1 g2 g3 shadow trunk wood wood2 leaf leaf2 iron p1 p2 p3',
        'g1 g2 g3 p1 p2 skin skin2 hair pants drum drum2 shirt shirt2 red yellow',
        'g1 g2 g3 red white blue skin hair shirt shirt2 pants wood wood2 iron shadow',
        'g1 g2 g3 court court2 white iron stone stone2 p1 p2 p3 bowl bowl2 bowl3')]
    pals = build_palettes(both, 6, fixed=fixed)
    ts = TileSet(4)
    m = convert_bg(img, pals, 2, ts)
    out('park_map.bin', raw_map_bytes(m))           # 320 rows x 32 words
    # canopies: BG2, high priority, packed (mask + row offsets + the non-blank words)
    cm = convert_bg(can, pals, 2, ts, priority=True)
    cmask, rows, cells = bytearray(H // 8 * 4), [], bytearray()
    for ty, row in enumerate(cm):
        rows.append(len(cells))
        for tx, wd in enumerate(row):
            if wd & 0x3FF:
                cmask[ty * 4 + tx // 8] |= 0x80 >> (tx % 8)
                cells += bytes((wd & 0xFF, wd >> 8))
    crow = bytearray()
    for r in rows:
        crow += bytes((r & 0xFF, r >> 8))
    out('park_canopy.bin', bytes(cmask) + bytes(crow) + bytes(cells))
    out('park_tiles.bin', ts.data())
    out('park_solid.bin', bitmap(solid))            # 4 bytes per row
    out('park_behind.bin', bitmap(behind))
    data = bytearray()
    for p in pals:
        data += pal_bytes(p, 16)
    data += bytes(32 * (6 - len(pals)))
    out('park_pal.bin', data)
    dogs, balls = place_dogs(court, dc)
    sh = build_sprites()
    full = img.copy()
    full.alpha_composite(can)
    view = full.crop((0, H - 224, 256, H)).copy()
    view.alpha_composite(render(sh, (0, 0, 16, 32), P.ATHLETE), (120, 150))
    view.alpha_composite(render(sh, (0, 64, 32, 16), dog_pal('doodle')), (70, 120))
    view.alpha_composite(render(sh, (32, 64, 32, 16), dog_pal('husky'), fliph=True), (170, 100))
    view.alpha_composite(render(sh, (64, 96, 32, 16), dog_pal('corgi')), (60, 170))
    preview(view, 'park_start.png')
    preview(full.crop((0, 1100, 256, 1500)).copy(), 'park_mid.png')
    with open('build/park_overview.txt', 'w') as f:
        f.write('dogs %r\nballs %r\n' % (dogs, balls))
    if len(ts) > 1000:
        raise ValueError('park uses %d tiles' % len(ts))
    return '%d tiles, %d pals, canopy %d bytes' % (len(ts), len(pals), len(cmask) + len(crow) + len(cells))


if __name__ == '__main__':
    print(build())
