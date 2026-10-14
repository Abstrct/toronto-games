"""Bike Courier: top-down Queen St West (BG1) and its sprites."""
import random
from PIL import Image, ImageDraw
from snes import (TileSet, convert_bg, build_palettes, map_bytes, pal_bytes, hexrgb, snap,
                  out, preview)
from sprites import Sheet

# road columns (x) -------------------------------------------------
RAILS = [82, 106, 150, 174]


def rgb(h):
    return snap(hexrgb(h)) + (255,)


ROAD = {
    'asph': '#45454f', 'asph2': '#3d3d46', 'asph3': '#50505a', 'park': '#4c4c55',
    'white': '#e0e0e0', 'yellow': '#e0b820', 'conc': '#6c6c74', 'seam': '#5a5a62',
    'steel': '#b8b8c8', 'groove': '#202028', 'hole': '#303038', 'rim': '#68686f',
}
SIDE = {
    'sw': '#a8a8b0', 'swseam': '#8c8c98', 'curb': '#d0d0d8', 'curbsh': '#383840',
    'tree1': '#1c5028', 'tree2': '#2c7034', 'tree3': '#48983c', 'pit': '#5a3c24',
    'red': '#c82828', 'awhite': '#f0f0f0', 'green': '#208840', 'blue': '#2858b8',
    'ayellow': '#e8b820', 'ashade': '#7c7c86', 'glass': '#80b0d0', 'glass2': '#486c90',
    'wall': '#584038', 'sign': '#202028', 'lamp': '#f8f0a0', 'ring': '#686870',
    'ttcred': '#d82020', 'paper': '#2050b0',
    # Queen West fronts
    'roof': '#4a4048', 'brick': '#8c3a2a', 'stone': '#c8b890', 'purple': '#7a3a9a',
    # (the rest of the fronts reuse colours above: the BG has 6 palettes)
    'roof2': '#202028', 'brick2': '#584038', 'stone2': '#7c7c86', 'black': '#202028',
    'neon': '#d82020', 'bulb': '#f8f0a0', 'van': '#f0f0f0', 'vanred': '#c82828',
    'vanblue': '#2858b8', 'glassd': '#486c90', 'scrap': '#a8a8b0', 'rust': '#5a3c24',
    'purple2': '#584038', 'green2': '#1c5028', 'umb': '#c82828',
}
C = {k: rgb(v) for k, v in {**ROAD, **SIDE}.items()}


def queen_west(d, px):
    """The sidewalks of Queen St W, one 64-px block per shop, so each front
    reads at riding speed instead of a run of identical striped awnings.
    West side (left, south of Queen): the Horseshoe Tavern's neon horseshoe
    and marquee, the Black Bull's umbrella patio, a green-awning shop, a
    purple gallery. East side (right, north of Queen): CityTV's news truck
    bursting out of the wall, the Bovine Sex Club's scrap-metal front, a
    red-awning diner, a yellow-awning record shop."""
    import math

    def P(x, y, col, flip):
        if 0 <= y < 256:
            px[255 - x if flip else x, y] = C[col]

    def R(x0, y0, x1, y1, col, flip):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                P(x, y, col, flip)

    def disc(cx, cy, r, col, flip):
        for y in range(int(cy - r) - 1, int(cy + r) + 2):
            for x in range(int(cx - r) - 1, int(cx + r) + 2):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r and 0 <= x < 22:
                    P(x, y, col, flip)

    def ring(cx, cy, r, col, flip):
        for k in range(48):
            a = k * math.pi / 24
            P(int(round(cx + r * math.cos(a))), int(round(cy + r * math.sin(a))), col, flip)

    def roof(y0, col, edge, flip):
        R(0, y0, 5, y0 + 63, col, flip)
        R(6, y0, 6, y0 + 63, edge, flip)
        R(0, y0, 6, y0, 'curbsh', flip)            # party wall

    def awning(y0, y1, col, shade, flip):
        R(7, y0, 12, y1, col, flip)
        R(7, y0, 7, y1, shade, flip)
        for y in range(y0, y1 + 1, 4):              # scalloped valance
            P(13, y + 1, col, flip)
            P(13, y + 2, col, flip)
        for y in range(y0 + 2, y1 + 3):              # its shadow
            P(14 if (y - y0) % 4 in (1, 2) else 13, y, 'ashade', flip)

    for flip in (False, True):
        for k in range(4):
            y0 = 64 * k
            shop = k + (4 if flip else 0)
            if shop == 0:       # HORSESHOE TAVERN
                roof(y0, 'roof2', 'black', flip)
                R(7, y0 + 30, 11, y0 + 58, 'black', flip)     # marquee canopy
                for y in range(y0 + 31, y0 + 58, 3):
                    P(11, y, 'bulb', flip)
                    P(7, y + 1, 'bulb', flip)
                # the neon horseshoe, hung out over the sidewalk
                for a in range(0, 360, 6):
                    if 30 < a < 150:
                        continue                              # open end up (lucky)
                    for r in (4.5, 5.5):
                        x = 13 + r * math.cos(math.radians(a))
                        y = y0 + 16 - r * math.sin(math.radians(a))
                        P(int(round(x)), int(round(y)), 'neon', flip)
                for (bx, by) in ((9, 14), (17, 14), (13, 22), (10, 19), (16, 19)):
                    P(bx, y0 + by, 'bulb', flip)
                R(6, y0 + 15, 7, y0 + 16, 'scrap', flip)      # its bracket
            elif shop == 1:     # BLACK BULL patio
                roof(y0, 'brick', 'brick2', flip)
                R(7, y0 + 4, 7, y0 + 60, 'black', flip)       # patio rail
                R(7, y0 + 4, 20, y0 + 4, 'black', flip)
                R(7, y0 + 60, 20, y0 + 60, 'black', flip)
                R(20, y0 + 4, 20, y0 + 60, 'black', flip)
                for cy in (y0 + 17, y0 + 44):
                    disc(13.5, cy, 6, 'umb', flip)
                    for a in range(0, 360, 90):
                        for r in range(1, 6):
                            P(int(round(13.5 + r * math.cos(math.radians(a + 45)))),
                              int(round(cy + r * math.sin(math.radians(a + 45)))), 'awhite', flip)
                    P(13, cy, 'black', flip)
            elif shop == 2:     # green-awning shop
                roof(y0, 'roof', 'black', flip)
                awning(y0 + 8, y0 + 50, 'green', 'green2', flip)
                R(7, y0 + 54, 8, y0 + 61, 'glass', flip)
            elif shop == 3:     # purple gallery
                roof(y0, 'stone', 'stone2', flip)
                awning(y0 + 6, y0 + 30, 'purple', 'purple2', flip)
                awning(y0 + 36, y0 + 58, 'purple', 'purple2', flip)
            elif shop == 4:     # CITYTV: the news truck out through the wall
                roof(y0, 'stone', 'stone2', flip)
                for y in range(y0 + 4, y0 + 60, 6):
                    R(1, y, 4, y + 2, 'glassd', flip)       # window grid
                # the truck, nose out, at an angle
                ang = math.radians(-24)
                for v in range(0, 22):
                    for u in range(-5, 6):
                        x = 5 + v * math.cos(ang) - u * math.sin(ang)
                        y = y0 + 34 + v * math.sin(ang) + u * math.cos(ang)
                        col = 'van'
                        if v > 17:
                            col = 'glassd' if abs(u) < 4 else 'van'
                        elif abs(u) == 5:
                            col = 'vanred' if v % 2 else 'van'
                        elif v in (8, 9):
                            col = 'vanblue'
                        if v == 21:
                            col = 'black'
                        P(int(round(x)), int(round(y)), col, flip)
                for (rx, ry) in ((7, 22), (9, 25), (6, 46), (8, 44), (11, 47), (5, 27)):
                    R(rx, y0 + ry, rx + 1, y0 + ry, 'stone2', flip)   # rubble
            elif shop == 5:     # BOVINE SEX CLUB: scrap metal everywhere
                roof(y0, 'black', 'black', flip)
                R(7, y0 + 2, 9, y0 + 61, 'black', flip)
                for (cx, cy, r) in ((9, 10, 4), (12, 22, 3), (9, 34, 4), (11, 47, 3), (9, 57, 3)):
                    ring(cx, y0 + cy, r, 'scrap', flip)
                    P(cx, y0 + cy, 'scrap', flip)
                for (x0_, y_, l) in ((7, 16, 8), (7, 28, 6), (7, 41, 9), (7, 52, 5)):
                    R(x0_, y0 + y_, x0_ + l, y0 + y_, 'rust', flip)
                for y in range(y0 + 4, y0 + 60, 7):
                    P(3, y, 'neon', flip)                  # red lights in the junk
            elif shop == 6:     # diner, red awning
                roof(y0, 'brick', 'brick2', flip)
                awning(y0 + 6, y0 + 56, 'red', 'brick2', flip)
                for y in range(y0 + 12, y0 + 52, 10):
                    R(9, y, 11, y + 4, 'awhite', flip)    # lettering blocks
            else:               # record shop, yellow awning
                roof(y0, 'roof', 'black', flip)
                awning(y0 + 10, y0 + 54, 'ayellow', 'rust', flip)
                disc(10, y0 + 32, 3, 'black', flip)       # a big record on it
                P(10, y0 + 32, 'ayellow', flip)


def road_image():
    img = Image.new('RGBA', (256, 256), C['asph'])
    px = img.load()
    d = ImageDraw.Draw(img)
    rnd = random.Random(5)
    noise = [[rnd.random() for _ in range(32)] for _ in range(32)]
    for y in range(256):
        for x in range(24, 232):
            n = noise[y % 32][x % 32]
            base = 'park' if (x < 56 or x >= 200) else 'asph'
            c = C[base]
            if n < 0.08:
                c = C['asph2']
            elif n > 0.94:
                c = C['asph3']
            px[x, y] = c
    # track beds + rails
    for (a, b) in ((74, 116), (142, 184)):
        d.rectangle([a, 0, b - 1, 255], fill=C['conc'])
        for y in range(0, 256, 32):
            d.line([a, y, b - 1, y], fill=C['seam'])
        d.line([a, 0, a, 255], fill=C['seam'])
        d.line([b - 1, 0, b - 1, 255], fill=C['seam'])
    for r in RAILS:
        d.rectangle([r, 0, r + 1, 255], fill=C['steel'])
        d.line([r + 2, 0, r + 2, 255], fill=C['groove'])
    # centre line and parking lines
    for x in (125, 126, 129, 130):
        d.line([x, 0, x, 255], fill=C['yellow'])
    d.line([54, 0, 55, 255], fill=C['white'])
    d.rectangle([54, 0, 55, 255], fill=C['white'])
    d.rectangle([200, 0, 201, 255], fill=C['white'])
    # parking stall ticks
    for y in range(0, 256, 64):
        d.line([24, y, 53, y], fill=C['white'])
        d.line([202, y + 32, 231, y + 32], fill=C['white'])
    # manholes
    for (mx, my) in ((64, 40), (40, 168), (122, 220)):
        d.ellipse([mx - 5, my - 5, mx + 5, my + 5], fill=C['rim'])
        d.ellipse([mx - 4, my - 4, mx + 4, my + 4], fill=C['hole'])
        d.line([mx - 3, my, mx + 3, my], fill=C['rim'])
    # sidewalks
    for (a, b) in ((0, 22), (234, 256)):
        d.rectangle([a, 0, b - 1, 255], fill=C['sw'])
        for y in range(0, 256, 16):
            d.line([a, y, b - 1, y], fill=C['swseam'])
    d.line([22, 0, 22, 255], fill=C['curb'])
    d.line([23, 0, 23, 255], fill=C['curbsh'])
    d.line([232, 0, 232, 255], fill=C['curbsh'])
    d.line([233, 0, 233, 255], fill=C['curb'])
    queen_west(d, px)
    # street furniture at the curb, in the gaps between the fronts:
    # ring-and-post bike stands, a TTC stop pole, little street trees
    for (rx, ry) in ((18, 62), (18, 190), (237, 30), (237, 158)):
        d.ellipse([rx - 2, ry - 2, rx + 2, ry + 2], outline=C['ring'])
    d.rectangle([236, 96, 239, 101], fill=C['ttcred'])
    d.rectangle([236, 98, 239, 99], fill=C['awhite'])
    for (tx, ty) in ((17, 128), (238, 190)):
        d.ellipse([tx - 5, ty - 5, tx + 5, ty + 5], fill=C['tree1'])
        d.ellipse([tx - 4, ty - 5, tx + 3, ty + 2], fill=C['tree2'])
        d.ellipse([tx - 3, ty - 4, tx + 0, ty - 1], fill=C['tree3'])
    return img


# sprites ----------------------------------------------------------
CAR_BASE = ['#000000', '#101018', None, None, None, '#283048', '#5878a8', '#282828',
            '#f8f0a0', '#e02020', None, '#f0f0f0', '#a0a0b0']
CARS = {
    'red':   ('#c82020', '#901010', '#f05050', None),
    'blue':  ('#2050c0', '#183080', '#5080f0', None),
    'taxi':  ('#f07810', '#b05008', '#f8b050', '#30a040'),
    'white': ('#d8d8e0', '#9898a8', '#ffffff', None),
}
STREETCAR = ['#000000', '#101018', '#d02828', '#901818', '#f06050', '#f0f0f0', '#b8b8c0',
             '#283048', '#181818', '#f8f0a0', '#f8f8f8', '#8c8c98']
MISC = ['#000000', '#101018', '#f0b888', '#402818', '#d8f838', '#78b818', '#383848', '#f8d020',
        '#b08010', '#fff4b0', '#26262c', '#5c5c66', '#f8f8f8', '#101010', '#e02818', '#f8e040']
FX = ['#000000', '#101018', '#f8e040', '#f88820', '#ffffff', '#e02818',
      '#08080c', '#24242c', '#5a5a64', '#84848e', '#b04808']


def car_pal(name):
    body, shade, light, sign = CARS[name]
    cols = list(CAR_BASE)
    cols[2], cols[3], cols[4] = body, shade, light
    cols[10] = sign or body
    return [hexrgb(c) for c in cols]


# The courier (player palette: 1 outline 2 skin 3 skin shade 5 jersey
# 6 jersey shade 7 helmet 8 shorts 9 shorts shade 10 white 11 shoes
# 12 bag 13 bag shade 14 rim 15 frame). Top-down, 16x32: front wheel up,
# helmet over the bars, a big messenger bag on the back, knees pumping.
# Pedal phases 0-3: left pedal forward / left at the top / left back /
# left at the bottom (right is always opposite).
def draw_courier(sh, x0, y0, phase, lean=0):
    from PIL import Image, ImageDraw
    im = Image.new('P', (16, 32), 0)
    d = ImageDraw.Draw(im)
    # wheels (tyre, a glint of rim) and the frame
    d.rectangle([7, 0, 8, 8], fill=1)
    d.point((7, 2), fill=14)
    d.point((8, 5), fill=14)
    d.rectangle([7, 24, 8, 31], fill=1)
    d.point((8, 26), fill=14)
    d.point((7, 29), fill=14)
    d.rectangle([7, 9, 8, 24], fill=15)
    # saddle + shorts
    d.rectangle([5, 19, 10, 22], fill=8)
    d.rectangle([6, 21, 9, 22], fill=9)
    # torso (jersey) with the shade on the right, bag + strap on the back
    d.ellipse([4, 11, 11, 20], fill=5)
    d.ellipse([8, 12, 11, 20], fill=6)
    d.ellipse([4, 11, 10, 19], fill=5)
    d.line([4, 12, 11, 19], fill=1)        # bag strap
    d.rectangle([6, 15, 9, 19], fill=15)   # the messenger bag
    d.line([6, 19, 9, 19], fill=1)
    d.line([9, 15, 9, 19], fill=1)
    d.line([6, 17, 8, 17], fill=12)        # its reflector strip
    # legs, seen from above: knee and shin beside the frame, swinging
    # fore and aft with the crank (thighs are under the torso)
    KNEE = [(15, 1), (13, 2), (18, 1), (19, 0)]     # knee y, how far out
    FOOT = [20, 22, 26, 24]
    for side in (0, 1):
        p = (phase + 2 * side) % 4
        ky, kout = KNEE[p]
        fy = FOOT[p]
        sgn = -1 if side == 0 else 1
        kx = (4 if side == 0 else 11) + sgn * kout
        fx = 5 if side == 0 else 10
        d.line([kx, ky, fx, fy], fill=9 if side else 8, width=2)
        d.rectangle([min(kx, kx - sgn), ky, max(kx, kx - sgn), ky + 1], fill=8)
        d.point((kx, ky), fill=3)          # a knee
        d.rectangle([min(fx, fx + sgn), fy, max(fx, fx + sgn), fy + 1], fill=11)
    # arms out to the bars, gloves on the grips
    d.line([4, 12, 2, 9], fill=5, width=2)
    d.line([11, 12, 13, 9], fill=6, width=2)
    d.rectangle([1, 9, 14, 9], fill=15)
    d.rectangle([1, 8, 2, 9], fill=2)
    d.rectangle([13, 8, 14, 9], fill=2)
    # helmet: shell in the accent colour, a jersey-colour stripe, vents
    d.ellipse([5, 5, 10, 12], fill=7)
    d.line([7, 5, 7, 12], fill=5)
    d.line([8, 6, 8, 11], fill=6)
    # lean: the top of the bike and rider swing into the turn
    if lean:
        src = im.copy()
        im = Image.new('P', (16, 32), 0)
        for y in range(32):
            sx = lean * (2 if y < 11 else 1 if y < 18 else 0)
            row = src.crop((0, y, 16, y + 1))
            im.paste(row, (sx, y))
    sh.img.paste(im, (x0, y0))
    sh.outline(x0, y0, 16, 32)


def _person(d, cx, cy, ang, limbs):
    """A sprawled courier seen from above, body along angle ang (deg),
    for the tumble. limbs: (arm spread, leg spread) in degrees."""
    import math
    def pt(r, a):
        return (cx + r * math.sin(math.radians(a)), cy - r * math.cos(math.radians(a)))
    hx, hy = pt(6, ang)
    fx, fy = pt(-5, ang)
    sx, sy = pt(3, ang)
    for s in (-1, 1):
        ax, ay = pt(3, ang)
        ex, ey = (ax + 7 * math.sin(math.radians(ang + s * limbs[0])),
                  ay - 7 * math.cos(math.radians(ang + s * limbs[0])))
        d.line([ax, ay, ex, ey], fill=5, width=2)
        d.rectangle([ex - 1, ey - 1, ex, ey], fill=2)
        lx, ly = (fx + 7 * math.sin(math.radians(ang + 180 + s * limbs[1])),
                  fy - 7 * math.cos(math.radians(ang + 180 + s * limbs[1])))
        d.line([fx, fy, lx, ly], fill=8, width=2)
        d.rectangle([lx - 1, ly - 1, lx, ly], fill=11)
    d.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=5)
    bx, by = pt(-1, ang)
    d.rectangle([bx - 2, by - 2, bx + 2, by + 2], fill=12)
    d.ellipse([hx - 3, hy - 3, hx + 3, hy + 3], fill=7)
    d.point((hx, hy), fill=10)


def _bike_side(d, cx, cy, ang, rim=14):
    """The bike on its side / spinning: two wheels and the frame."""
    import math
    dx, dy = 8 * math.cos(math.radians(ang)), 8 * math.sin(math.radians(ang))
    for k in (-1, 1):
        wx, wy = cx + k * dx, cy + k * dy
        d.ellipse([wx - 5, wy - 5, wx + 5, wy + 5], outline=1)
        d.ellipse([wx - 4, wy - 4, wx + 4, wy + 4], outline=rim)
        d.point((wx, wy), fill=15)
    d.line([cx - dx, cy - dy, cx, cy - 3, cx + dx, cy + dy], fill=7, width=2)
    d.line([cx, cy - 3, cx - dx * 0.4, cy - dy * 0.4 + 3], fill=15, width=1)


def draw_tumble(sh, x0, y0, k):
    """Wipeout: the courier cartwheels one way, the bike skids the other."""
    from PIL import Image, ImageDraw
    im = Image.new('P', (32, 32), 0)
    d = ImageDraw.Draw(im)
    if k == 0:
        _bike_side(d, 11, 22, 25)
        _person(d, 20, 11, 50, (70, 30))
    else:
        _bike_side(d, 12, 22, 155)
        _person(d, 19, 11, 230, (110, 45))
    sh.img.paste(im, (x0, y0))
    sh.outline(x0, y0, 32, 32)


def draw_crash(sh, x0, y0):
    """Down: bike flat on the road, the courier sat up next to it, dazed."""
    from PIL import ImageDraw
    d = sh.draw()
    _bike_side(sh.draw(), x0 + 13, y0 + 23, 0)
    # sitting courier, legs out in front, seen from above
    d.line([x0 + 21, y0 + 14, x0 + 18, y0 + 24], fill=8, width=2)
    d.line([x0 + 24, y0 + 14, x0 + 26, y0 + 24], fill=8, width=2)
    d.rectangle([x0 + 17, y0 + 24, x0 + 18, y0 + 25], fill=11)
    d.rectangle([x0 + 26, y0 + 24, x0 + 27, y0 + 25], fill=11)
    d.ellipse([x0 + 18, y0 + 4, x0 + 27, y0 + 14], fill=5)
    d.rectangle([x0 + 20, y0 + 5, x0 + 25, y0 + 9], fill=12)
    d.line([x0 + 19, y0 + 10, x0 + 15, y0 + 13], fill=5, width=2)
    d.line([x0 + 26, y0 + 10, x0 + 29, y0 + 14], fill=6, width=2)
    d.rectangle([x0 + 14, y0 + 13, x0 + 15, y0 + 14], fill=2)
    d.rectangle([x0 + 29, y0 + 14, x0 + 30, y0 + 15], fill=2)
    d.ellipse([x0 + 19, y0 + 0, x0 + 26, y0 + 7], fill=7)
    d.line([x0 + 22, y0 + 0, x0 + 22, y0 + 7], fill=10)
    sh.outline(x0, y0, 32, 32)


def draw_car(sh, x0, y0):
    d = sh.draw()
    d.rounded_rectangle([x0 + 4, y0 + 4, x0 + 27, y0 + 43], radius=5, fill=3)
    d.rounded_rectangle([x0 + 4, y0 + 4, x0 + 25, y0 + 43], radius=5, fill=2)
    d.line([x0 + 8, y0 + 7, x0 + 22, y0 + 7], fill=4)
    d.polygon([(x0 + 8, y0 + 13), (x0 + 23, y0 + 13), (x0 + 22, y0 + 18), (x0 + 9, y0 + 18)], fill=5)
    d.line([x0 + 10, y0 + 14, x0 + 14, y0 + 14], fill=6)
    d.rectangle([x0 + 9, y0 + 19, x0 + 22, y0 + 30], fill=2)
    d.line([x0 + 10, y0 + 20, x0 + 10, y0 + 28], fill=4)
    d.rectangle([x0 + 13, y0 + 23, x0 + 18, y0 + 26], fill=10)
    d.polygon([(x0 + 9, y0 + 31), (x0 + 22, y0 + 31), (x0 + 23, y0 + 35), (x0 + 8, y0 + 35)], fill=5)
    d.rectangle([x0 + 6, y0 + 4, x0 + 9, y0 + 5], fill=8)
    d.rectangle([x0 + 22, y0 + 4, x0 + 25, y0 + 5], fill=8)
    d.rectangle([x0 + 6, y0 + 42, x0 + 9, y0 + 43], fill=9)
    d.rectangle([x0 + 22, y0 + 42, x0 + 25, y0 + 43], fill=9)
    for (wx, wy) in ((3, 9), (27, 9), (3, 33), (27, 33)):
        d.rectangle([x0 + wx, y0 + wy, x0 + wx + 1, y0 + wy + 6], fill=7)
    d.rectangle([x0 + 2, y0 + 15, x0 + 3, y0 + 16], fill=2)
    d.rectangle([x0 + 28, y0 + 15, x0 + 29, y0 + 16], fill=2)
    sh.outline(x0, y0, 32, 48)


def draw_door(sh, x0, y0):
    d = sh.draw()
    d.polygon([(x0 + 15, y0 + 1), (x0 + 3, y0 + 0), (x0 + 2, y0 + 4), (x0 + 15, y0 + 5)], fill=2)
    d.line([x0 + 5, y0 + 2, x0 + 12, y0 + 2], fill=5)
    sh.outline(x0, y0, 16, 8)


def draw_streetcar(sh, x0, y0):
    d = sh.draw()
    d.rectangle([x0 + 6, y0 + 10, x0 + 41, y0 + 90], fill=2)
    d.rounded_rectangle([x0 + 6, y0 + 2, x0 + 41, y0 + 24], radius=9, fill=2)
    d.rectangle([x0 + 6, y0 + 12, x0 + 7, y0 + 90], fill=5)
    d.rectangle([x0 + 40, y0 + 12, x0 + 41, y0 + 90], fill=6)
    d.line([x0 + 10, y0 + 10, x0 + 10, y0 + 88], fill=4)
    d.rectangle([x0 + 37, y0 + 10, x0 + 39, y0 + 88], fill=3)
    for (a, b) in ((28, 40), (52, 62)):
        d.rectangle([x0 + 14, y0 + a, x0 + 33, y0 + b], fill=11, outline=1)
        d.line([x0 + 16, y0 + a + 2, x0 + 31, y0 + a + 2], fill=4)
    d.chord([x0 + 9, y0 + 2, x0 + 38, y0 + 18], 180, 360, fill=7)
    d.line([x0 + 14, y0 + 5, x0 + 20, y0 + 4], fill=10)
    d.rectangle([x0 + 9, y0 + 3, x0 + 11, y0 + 4], fill=9)
    d.rectangle([x0 + 36, y0 + 3, x0 + 38, y0 + 4], fill=9)
    d.rectangle([x0 + 8, y0 + 86, x0 + 39, y0 + 90], fill=3)
    d.rectangle([x0 + 20, y0 + 70, x0 + 27, y0 + 74], fill=8)
    d.line([x0 + 23, y0 + 72, x0 + 23, y0 + 95], fill=8)
    d.line([x0 + 24, y0 + 72, x0 + 24, y0 + 95], fill=8)
    d.rectangle([x0 + 14, y0 + 76, x0 + 33, y0 + 80], fill=5)
    sh.outline(x0, y0, 48, 96)


def draw_ped(sh, x0, y0, step):
    """The jaywalker, from above, walking right (flipped for left): a big
    hi-vis jacket with a reflective band so it reads on dark asphalt,
    arms and feet swinging. Misc palette (4/5 lime, 12 white)."""
    dd = sh.draw()

    def rect(a, b, c, e, fill):
        dd.rectangle([x0 + a, y0 + b, x0 + c, y0 + e], fill=fill)

    def oval(a, b, c, e, fill):
        dd.ellipse([x0 + a, y0 + b, x0 + c, y0 + e], fill=fill)

    if step == 0:
        rect(10, 0, 13, 1, 6)
        rect(2, 14, 5, 15, 6)
        rect(11, 3, 14, 4, 5)               # arms swing too
        rect(1, 11, 4, 12, 5)
    else:
        rect(10, 14, 13, 15, 6)
        rect(2, 0, 5, 1, 6)
        rect(11, 11, 14, 12, 5)
        rect(1, 3, 4, 4, 5)
    oval(3, 2, 12, 13, 5)
    oval(3, 2, 11, 12, 4)
    rect(6, 2, 7, 13, 12)                   # reflective band
    oval(6, 5, 10, 10, 3)                   # head (hair)
    rect(10, 7, 10, 8, 2)                   # face: the way it's walking
    sh.outline(x0, y0, 16, 16)


def draw_pothole(sh, x0, y0):
    """A ragged black hole with broken asphalt round it, and the city's
    traditional response: one orange cone. FX palette."""
    d = sh.draw()
    rim = [(1, 6), (3, 2), (6, 3), (8, 0), (11, 2), (14, 1), (17, 4), (19, 8), (17, 11),
           (18, 14), (13, 13), (10, 15), (7, 12), (3, 14), (2, 10), (0, 9)]
    d.polygon([(x0 + a, y0 + b) for a, b in rim], fill=8)
    hole = [(3, 6), (5, 4), (8, 3), (10, 4), (13, 3), (16, 6), (16, 9), (14, 12), (10, 12),
            (7, 11), (4, 11), (3, 9)]
    d.polygon([(x0 + a, y0 + b) for a, b in hole], fill=7)
    d.polygon([(x0 + a, y0 + b) for a, b in
               [(5, 6), (8, 5), (13, 5), (15, 8), (13, 10), (9, 10), (5, 9)]], fill=6)
    for (a, b) in ((2, 6), (8, 1), (15, 2), (18, 9), (12, 14), (4, 12)):
        d.point((x0 + a, y0 + b), fill=9)
    d.line([x0 + 10, y0 + 5, x0 + 12, y0 + 7], fill=7)
    # the cone, seen from above: square foot, orange body, white band, tip
    cx, cy = x0 + 22, y0 + 3
    d.rectangle([cx, cy, cx + 8, cy + 8], fill=10)
    d.ellipse([cx + 1, cy + 1, cx + 7, cy + 7], fill=3)
    d.ellipse([cx + 2, cy + 2, cx + 6, cy + 6], fill=4)
    d.ellipse([cx + 3, cy + 3, cx + 5, cy + 5], fill=3)
    d.point((cx + 4, cy + 4), fill=2)
    sh.outline(x0, y0, 32, 16)


FAST = [('rider_0', ''), ('rider_1', ''), ('rider_2', ''), ('rider_3', ''),
        ('rider_l0', ''), ('rider_l1', ''), ('rider_r0', ''), ('rider_r1', ''),
        ('tumble0', ''), ('tumble1', ''), ('rider_crash', ''), ('shadow', ''), ('wind', ''),
        ('pow0', ''), ('pow1', ''), ('token', ''), ('door', ''), ('pothole', ''), ('car', ''),
        ('car', 'v'), ('ped0', ''), ('ped0', 'h'), ('ped1', ''), ('ped1', 'h'), ('finish', ''),
        ('warn', ''), ('streetcar', ''), ('streetcar', 'v'), ('brake', '')]


def fast_meta(sh):
    """bm_<name>[_h|_v] tables for the bike's own sprite drawer: per piece
    .word dx, dy, tile | attr<<8, size<<1; ends with $8000. Flips are baked in,
    so the drawer never mirrors."""
    objs = {o[0]: o for o in sh.objects}
    lines = []
    for name, fl in FAST:
        (_, x, y, w, h, ax, ay) = objs[name]
        lines.append('bm_%s%s:' % (name, '_' + fl if fl else ''))
        for py in range(0, h, 16):
            for px_ in range(0, w, 16):
                cells = []
                if px_ + 16 <= w and py + 16 <= h:
                    if not sh._empty(x + px_, y + py, 16, 16):
                        cells.append((px_, py, 16))
                else:
                    for sy in range(py, min(py + 16, h), 8):
                        for sx in range(px_, min(px_ + 16, w), 8):
                            if not sh._empty(x + sx, y + sy, 8, 8):
                                cells.append((sx, sy, 8))
                for (cx, cy, n) in cells:
                    tile = ((y + cy) // 8) * 16 + (x + cx) // 8
                    dx, dy, attr = cx - ax, cy - ay, 0
                    if fl == 'h':
                        dx, attr = -dx - n, attr | 0x40
                    if fl == 'v':
                        dy, attr = -dy - n, attr | 0x80
                    attr |= tile >> 8
                    lines.append('    .word $%04X, $%04X, $%04X, %d' % (
                        dx & 0xFFFF, dy & 0xFFFF, (tile & 0xFF) | attr << 8, 2 if n == 16 else 0))
        lines.append('    .word $8000')
    return '\n'.join(lines) + '\n'


def build_sprites():
    import math
    sh = Sheet(160)
    d = sh.draw()
    # the courier: 4 pedal phases, then leaning left / right (2 phases each)
    for k in range(4):
        draw_courier(sh, 16 * k, 0, k)
    draw_courier(sh, 64, 0, 0, -1)
    draw_courier(sh, 80, 0, 2, -1)
    draw_courier(sh, 96, 0, 0, 1)
    draw_courier(sh, 112, 0, 2, 1)
    draw_tumble(sh, 0, 32, 0)
    draw_tumble(sh, 32, 32, 1)
    draw_crash(sh, 64, 32)
    # pow stars (palette 7)
    for k, (r1, r2) in enumerate(((7.5, 3.5), (5, 2))):
        x0 = 96 + 16 * k
        pts = [(x0 + 7.5 + (r1 if i % 2 == 0 else r2) * math.cos(i * math.pi / 5),
                32 + 7.5 + (r1 if i % 2 == 0 else r2) * math.sin(i * math.pi / 5)) for i in range(10)]
        d.polygon(pts, fill=2, outline=3)
        d.ellipse([x0 + 6, 38, x0 + 9, 41], fill=4)
    # token (misc palette)
    d.ellipse([96, 48, 103, 55], fill=7)
    d.ellipse([97, 49, 102, 54], fill=8)
    d.ellipse([97, 49, 101, 53], fill=7)
    d.point((98, 50), fill=9)
    d.rectangle([99, 48, 100, 55], fill=7)
    d.rectangle([99, 49, 99, 54], fill=9)
    draw_door(sh, 112, 48)
    draw_car(sh, 0, 64)
    draw_ped(sh, 32, 64, 0)
    draw_ped(sh, 48, 64, 1)
    for yy in range(4):
        for xx in range(4):
            d.rectangle([32 + xx * 4, 80 + yy * 4, 35 + xx * 4, 83 + yy * 4], fill=12 if (xx + yy) % 2 else 13)
    d.polygon([(56, 81), (63, 94), (49, 94)], fill=15, outline=13)
    d.rectangle([55, 85, 56, 90], fill=13)
    d.rectangle([55, 92, 56, 93], fill=13)
    draw_streetcar(sh, 80, 64)
    draw_pothole(sh, 0, 112)
    # hop shadow (FX palette): a soft dark oval on the asphalt
    d.ellipse([33, 113, 46, 118], fill=7)
    d.ellipse([35, 114, 44, 117], fill=6)
    # slipstream streaks (misc white / grey)
    for (wx, wy, l) in ((50, 113, 9), (53, 116, 6), (59, 112, 10), (62, 117, 5)):
        d.line([wx, wy, wx, wy + l], fill=12 if l > 7 else 11)
    # the 501's brake lights (misc palette: red with a hot yellow core)
    for bx in (9, 35):
        d.rectangle([bx, 128, bx + 4, 131], fill=14)
        d.rectangle([bx + 1, 129, bx + 3, 130], fill=15)
        d.point((bx + 2, 129), fill=12)

    sh.obj('rider_0', 0, 0, 16, 32)
    sh.obj('rider_1', 16, 0, 16, 32)
    sh.obj('rider_2', 32, 0, 16, 32)
    sh.obj('rider_3', 48, 0, 16, 32)
    sh.obj('rider_l0', 64, 0, 16, 32)
    sh.obj('rider_l1', 80, 0, 16, 32)
    sh.obj('rider_r0', 96, 0, 16, 32)
    sh.obj('rider_r1', 112, 0, 16, 32)
    sh.obj('tumble0', 0, 32, 32, 32)
    sh.obj('tumble1', 32, 32, 32, 32)
    sh.obj('rider_crash', 64, 32, 32, 32)
    sh.obj('pow0', 96, 32, 16, 16)
    sh.obj('pow1', 112, 32, 16, 16)
    sh.obj('token', 96, 48, 8, 8)
    sh.obj('door', 112, 48, 16, 8, 16, 4)
    sh.obj('car', 0, 64, 32, 48)
    sh.obj('ped0', 32, 64, 16, 16)
    sh.obj('ped1', 48, 64, 16, 16)
    sh.obj('finish', 32, 80, 16, 16)
    sh.obj('warn', 48, 80, 16, 16)
    sh.obj('streetcar', 80, 64, 48, 96)
    sh.obj('pothole', 0, 112, 32, 16, 10, 8)
    sh.obj('shadow', 32, 112, 16, 8, 8, 4)
    sh.obj('wind', 48, 112, 16, 16, 8, 8)
    sh.obj('brake', 0, 128, 48, 8, 24, -38)
    out('bike_spr.bin', sh.tiles())
    with open('build/bike_meta.inc', 'w') as f:
        f.write(sh.meta_inc())
        f.write(fast_meta(sh))
    # sprite palettes 1..7 (0 = player, filled at runtime)
    pals = [car_pal('red'), car_pal('blue'), car_pal('taxi'),
            [hexrgb(c) for c in STREETCAR], [hexrgb(c) for c in MISC],
            car_pal('white'), [hexrgb(c) for c in FX]]
    data = bytearray()
    for p in pals:
        data += pal_bytes(p, 16)
    out('bike_spr_pal.bin', data)
    sh.preview([(0, 0, 0)] + [hexrgb(c) for c in MISC[1:]], 'bike_sheet.png')
    # the courier in a real jersey, big, for checking the animation
    from sprites import render
    import people as P
    view = Image.new('RGBA', (128 + 96, 32), (69, 69, 79, 255))
    for k in range(8):
        view.alpha_composite(render(sh, (16 * k, 0, 16, 32), P.ATHLETE), (16 * k, 0))
    for k in range(3):
        view.alpha_composite(render(sh, (32 * k, 32, 32, 32), P.ATHLETE), (128 + 32 * k, 0))
    preview(view, 'bike_courier.png', 6)


def build():
    road = road_image()
    pals = build_palettes(road, 6)
    ts = TileSet(4)
    m = convert_bg(road, pals, 2, ts)
    out('bike_tiles.bin', ts.data())
    out('bike_map.bin', map_bytes(m)[:2048])
    data = bytearray()
    for p in pals:
        data += pal_bytes(p, 16)
    data += bytes(32 * (6 - len(pals)))
    out('bike_pal.bin', data)
    build_sprites()
    preview(road, 'bike_road.png')
    return '%d tiles, %d pals' % (len(ts), len(pals))


if __name__ == '__main__':
    print(build())
