"""Parallel Parking: an Annex side street from above (BG1), the player's car
in 9 rotations (0..80 degrees, turning in), parked cars, tow truck, parking
officer, hydrant + geyser, gauge markers."""
import math
import random
from PIL import Image, ImageDraw
from snes import (TileSet, convert_bg, build_palettes, map_bytes, pal_bytes, hexrgb, snap,
                  out, preview)
from sprites import Sheet, render
import people as P
import art_bike
import art_park


def rgb(h):
    return snap(hexrgb(h)) + (255,)


C = {k: rgb(v) for k, v in {
    'asph': '#4a4a54', 'asph2': '#42424b', 'asph3': '#55555f', 'park': '#50505a',
    'white': '#e0e0e0', 'yellow': '#e0b820', 'sw': '#b0acac', 'swseam': '#94909a',
    'curb': '#d8d8dc', 'curbsh': '#3a3a44', 'grass': '#4c9a3c', 'grass2': '#3e8634',
    't1': '#1e5a26', 't2': '#2c7432', 't3': '#46923e', 'pit': '#5a3c24',
    'roof': '#7a3a30', 'roof2': '#5a2820', 'roof3': '#9a5040', 'porch': '#c8b090',
    'brick': '#a85040', 'gp': '#18a050', 'gp2': '#f8f8f8', 'pole': '#606068',
    'hedge': '#2a6a30', 'hedge2': '#3a8040', 'path': '#c8bca8',
}.items()}

CURB = 232
FAR_CARS = [('#3870c0', '#28508c'), ('#c8c8cc', '#98989c'), ('#2a7a48', '#1c5a34'), ('#a83030', '#782020')]


def far_car(d, x, y, cols):
    """A parked car on the far side, nose down (southbound), 22 x 38."""
    body, shade = rgb(cols[0]), rgb(cols[1])
    d.rounded_rectangle([x, y, x + 21, y + 37], radius=4, fill=rgb('#181820'))
    d.rounded_rectangle([x + 1, y + 1, x + 20, y + 36], radius=3, fill=body)
    d.rectangle([x + 3, y + 25, x + 18, y + 29], fill=rgb('#283048'))     # windshield (front is down)
    d.rectangle([x + 3, y + 7, x + 18, y + 9], fill=rgb('#283048'))       # rear window
    d.rectangle([x + 4, y + 11, x + 17, y + 23], fill=shade)             # roof
    d.point((x + 3, y + 36), fill=rgb('#f8f0c0'))
    d.point((x + 18, y + 36), fill=rgb('#f8f0c0'))
    d.point((x + 3, y + 1), fill=rgb('#c02020'))
    d.point((x + 18, y + 1), fill=rgb('#c02020'))


def street():
    img = Image.new('RGBA', (256, 256), C['asph'])
    d = ImageDraw.Draw(img)
    px = img.load()
    rnd = random.Random(21)
    noise = [[rnd.random() for _ in range(32)] for _ in range(32)]
    for y in range(256):
        for x in range(49, 232):
            n = noise[y % 32][x % 32]
            base = C['park'] if (x < 80 or x >= 200) else C['asph']
            px[x, y] = C['asph2'] if n < 0.07 else (C['asph3'] if n > 0.95 else base)
    # Brunswick: no centre line, just the parking-lane edges (dashed)
    for y in range(0, 256, 16):
        d.rectangle([78, y, 79, y + 9], fill=C['white'])
        d.rectangle([200, y, 201, y + 9], fill=C['white'])
    # parked up the far side too
    for i, y in enumerate((44, 100, 150, 204)):
        far_car(d, 53, y, FAR_CARS[i % len(FAR_CARS)])
    # left: houses, lawns, sidewalk, curb
    for i, y in enumerate(range(0, 256, 64)):
        d.rectangle([0, y, 23, y + 63], fill=C['grass'])
        # roof seen from above: gable ridge down the middle
        d.rectangle([0, y + 6, 18, y + 50], fill=C['roof'])
        d.rectangle([0, y + 6, 18, y + 8], fill=C['roof3'])
        d.line([9, y + 6, 9, y + 50], fill=C['roof2'])
        for yy in range(y + 10, y + 50, 4):
            d.line([0, yy, 18, yy], fill=C['roof2'])
        d.rectangle([18, y + 20, 23, y + 38], fill=C['porch'])
        d.rectangle([24, y + 27, 31, y + 31], fill=C['path'])
        d.ellipse([2, y + 52, 14, y + 62], fill=C['t1'])
        d.ellipse([3, y + 52, 12, y + 59], fill=C['t2'])
    d.rectangle([24, 0, 31, 255], fill=C['grass2'])
    for y in range(0, 256, 64):
        d.rectangle([24, y + 27, 31, y + 31], fill=C['path'])
    d.rectangle([32, 0, 46, 255], fill=C['sw'])
    for y in range(0, 256, 16):
        d.line([32, y, 46, y], fill=C['swseam'])
    d.line([47, 0, 47, 255], fill=C['curb'])
    d.line([48, 0, 48, 255], fill=C['curbsh'])
    # right: curb, sidewalk, hedges
    d.line([CURB, 0, CURB, 255], fill=C['curbsh'])
    d.line([CURB + 1, 0, CURB + 1, 255], fill=C['curb'])
    d.rectangle([234, 0, 247, 255], fill=C['sw'])
    for y in range(0, 256, 16):
        d.line([234, y, 247, y], fill=C['swseam'])
    d.rectangle([248, 0, 255, 255], fill=C['hedge'])
    for y in range(0, 256, 8):
        d.ellipse([248, y, 255, y + 7], fill=C['hedge2'])
    # Green P sign (below the HUD panel) and a street tree on the right sidewalk
    d.rectangle([240, 56, 241, 66], fill=C['pole'])
    d.ellipse([236, 50, 245, 59], fill=C['gp'])
    d.rectangle([239, 52, 240, 57], fill=C['gp2'])
    d.rectangle([240, 52, 242, 54], fill=C['gp2'])
    d.ellipse([235, 196, 246, 207], fill=C['pit'])
    d.ellipse([233, 188, 248, 203], fill=C['t1'])
    d.ellipse([234, 188, 245, 199], fill=C['t2'])
    d.ellipse([236, 189, 241, 194], fill=C['t3'])
    return img


# player's car in athlete-palette indices, drawn as rotated polygons
def rot(p, a):
    x, y = p
    return (x * math.cos(a) - y * math.sin(a), x * math.sin(a) + y * math.cos(a))


SS = 8                                  # supersampling for the rotated frames
DETAIL = {7: 2.2, 9: 1.4, 12: 2.0, 13: 2.0, 14: 2.0, 11: 1.3}   # thin parts win ties


def draw_player_car(sh, x0, y0, deg):
    """Car centred in a 48x48 cell, front up, rotated `deg` counter-clockwise.
    Drawn 8x up and boiled down a pixel at a time (the colour covering most
    of it, thin details weighted up), so a tilted car keeps one clean edge
    and an unbroken stripe instead of polygon stair-steps."""
    big = Image.new('L', (48 * SS, 48 * SS), 0)
    d = ImageDraw.Draw(big)
    a = -math.radians(deg)
    cx, cy = 24.0 * SS, 24.0 * SS

    def poly(pts, col):
        q = [rot(p, a) for p in pts]
        d.polygon([(cx + x * SS, cy + y * SS) for x, y in q], fill=col)

    W, H = 11, 19.5
    body = [(-W + 2, -H), (W - 2, -H), (W, -H + 3), (W, H - 3), (W - 2, H), (-W + 2, H), (-W, H - 3), (-W, -H + 3)]
    poly(body, 6)
    poly([(x - 1.2, y) for x, y in body], 5)
    for (wx, wy) in ((-W - 1, -H + 6), (W - 1, -H + 6), (-W - 1, H - 11), (W - 1, H - 11)):
        poly([(wx, wy), (wx + 2, wy), (wx + 2, wy + 6), (wx, wy + 6)], 11)
    poly([(-8, -9), (8, -9), (7, -4), (-7, -4)], 9)            # windshield
    poly([(-6.5, -3.5), (6.5, -3.5), (6.5, 7), (-6.5, 7)], 5)  # roof
    poly([(-1, -16), (1, -16), (1, 15), (-1, 15)], 7)            # racing stripe
    poly([(-7, 7.5), (7, 7.5), (8, 11), (-8, 11)], 9)            # rear window
    poly([(-9, -H), (-6, -H), (-6, -H + 1.5), (-9, -H + 1.5)], 12)
    poly([(6, -H), (9, -H), (9, -H + 1.5), (6, -H + 1.5)], 12)
    poly([(-9, H - 1.5), (-6, H - 1.5), (-6, H), (-9, H)], 13)
    poly([(6, H - 1.5), (9, H - 1.5), (9, H), (6, H)], 13)
    poly([(-6, -8.5), (-3, -8.5), (-3.5, -7.5), (-6, -7.5)], 14)  # glint
    px = big.load()
    for oy in range(48):
        for ox in range(48):
            votes = {}
            for yy in range(oy * SS, oy * SS + SS):
                for xx in range(ox * SS, ox * SS + SS):
                    v = px[xx, yy]
                    votes[v] = votes.get(v, 0) + 1
            if votes.get(0, 0) * 2 > SS * SS:
                continue
            votes.pop(0, None)
            best = max(votes, key=lambda k: votes[k] * DETAIL.get(k, 1.0))
            sh.px(x0 + ox, y0 + oy, best)
    sh.outline(x0, y0, 48, 48)


TRUCK = ['#000000', '#101018', '#f8c818', '#b88808', '#303038', '#9898a8', '#d8d8e0', '#e02818',
         '#801010', '#78c8f8', '#f8f8f8', '#283048', '#f87818', '#3878d0']
OFFICER = ['#000000', '#101018', '#e8b888', '#b88858', '#202020', '#384870', '#24305a', '#f8d020',
           '#283048', '#1a2038', '#f8f8f8', '#181818', '#30c048', '#e02818', '#f8f8f8', '#787890']


def draw_truck(sh, x0, y0):
    d = sh.draw()
    d.rounded_rectangle([x0 + 5, y0 + 2, x0 + 26, y0 + 16], radius=3, fill=2)   # cab
    d.rectangle([x0 + 8, y0 + 5, x0 + 23, y0 + 9], fill=11)                     # windshield
    d.rectangle([x0 + 9, y0 + 11, x0 + 22, y0 + 13], fill=12)                   # roof light bar
    d.rectangle([x0 + 5, y0 + 17, x0 + 26, y0 + 40], fill=5)                    # flatbed
    d.rectangle([x0 + 5, y0 + 17, x0 + 7, y0 + 40], fill=6)
    for yy in range(y0 + 20, y0 + 40, 4):
        d.line([x0 + 7, yy, x0 + 24, yy], fill=4)
    d.rectangle([x0 + 14, y0 + 38, x0 + 17, y0 + 46], fill=4)                   # tow boom
    d.rectangle([x0 + 12, y0 + 45, x0 + 19, y0 + 47], fill=3)
    for (wx, wy) in ((3, 5), (26, 5), (3, 30), (26, 30)):
        d.rectangle([x0 + wx, y0 + wy, x0 + wx + 2, y0 + wy + 6], fill=4)
    sh.outline(x0, y0, 32, 48)


def draw_cyclist(sh, x0, y0, k):
    d = sh.draw()
    d.rectangle([x0 + 7, y0 + 1, x0 + 8, y0 + 8], fill=4)          # front wheel
    d.rectangle([x0 + 7, y0 + 23, x0 + 8, y0 + 30], fill=4)        # back wheel
    d.rectangle([x0 + 7, y0 + 9, x0 + 8, y0 + 22], fill=15)        # frame
    d.rectangle([x0 + 3, y0 + 7, x0 + 12, y0 + 8], fill=15)        # handlebar
    # knees pumping (navy pants)
    kl, kr = (16, 20) if k == 0 else (20, 16)
    d.ellipse([x0 + 3, y0 + kl, x0 + 6, y0 + kl + 4], fill=5)
    d.ellipse([x0 + 9, y0 + kr, x0 + 12, y0 + kr + 4], fill=5)
    d.ellipse([x0 + 3, y0 + 11, x0 + 12, y0 + 21], fill=12)        # hi-vis jacket
    d.line([x0 + 4, y0 + 13, x0 + 3, y0 + 9], fill=12, width=2)    # arms to the bars
    d.line([x0 + 11, y0 + 13, x0 + 12, y0 + 9], fill=12, width=2)
    d.rectangle([x0 + 5, y0 + 16, x0 + 10, y0 + 20], fill=7)       # courier bag
    d.ellipse([x0 + 5, y0 + 10, x0 + 10, y0 + 15], fill=13)        # helmet
    d.point((x0 + 6, y0 + 11), fill=10)
    sh.outline(x0, y0, 16, 32)


def build_sprites():
    sh = Sheet(256)
    d = sh.draw()
    # player car frames: bands of 48 px, two per band
    for k in range(9):
        band, col = k // 2, k % 2
        draw_player_car(sh, col * 48, band * 48, k * 10)
    art_bike.draw_car(sh, 96, 0)                      # parked car (car palettes)
    draw_truck(sh, 96, 48)
    # officer (top-down walker frames from the park, officer palette)
    art_park.draw_walker(sh, 96, 96, 'down', 0)
    art_park.draw_walker(sh, 112, 96, 'down', 1)
    # hydrant (truck palette): red cap from above
    d.ellipse([97, 145, 102, 150], fill=7)
    d.ellipse([98, 146, 101, 149], fill=8)
    d.point((96, 147), fill=7)
    d.point((103, 147), fill=7)
    # geyser frames: a 16x64 column of water shooting up out of the hydrant
    for k in range(2):
        x0, y0 = 96 + k * 16, 192
        cx = x0 + 7.5
        for y in range(y0 + 10, y0 + 64):
            t = (y - y0 - 10) / 54.0
            hw = 1.5 + 1.8 * t + 0.6 * math.sin(y * 0.9 + k * 2.0)
            d.line([cx - hw, y, cx + hw, y], fill=9)
            d.point((cx - hw, y), fill=13)
            if (y + k * 3) % 7 < 3:
                d.point((cx + 0.5 * math.sin(y * 0.5), y), fill=10)
        # spray crown and falling drops
        for i in range(10):
            ang = math.pi + i * math.pi / 9
            r = 5 + (i * 3 + k * 2) % 3
            x, y = cx + r * math.cos(ang) * 1.3, y0 + 10 + r * math.sin(ang)
            d.ellipse([x - 1, y - 1, x + 1, y + 1], fill=9 if i % 2 else 10)
        for i in range(6):
            x = x0 + 1 + (i * 5 + k * 3) % 14
            y = y0 + 14 + (i * 11 + k * 6) % 30
            d.point((x, y), fill=9)
            d.point((x, y + 1), fill=13)
        d.ellipse([cx - 3, y0 + 6, cx + 3, y0 + 12], fill=10)
    # gauge marker (down arrow), pins, sparkle, ticket (officer palette)
    d.polygon([(96, 176), (103, 176), (99, 182)], fill=14, outline=1)      # marker
    d.polygon([(104, 176), (111, 176), (107, 182)], fill=12, outline=1)    # good pin
    d.polygon([(112, 176), (119, 176), (115, 182)], fill=13, outline=1)    # bad pin
    for (x, y) in ((123, 177), (121, 179), (125, 179), (123, 181)):
        d.point((x, y), fill=7)
    d.point((123, 179), fill=14)
    d.rectangle([97, 185, 103, 191], fill=14, outline=1)                   # ticket
    d.line([98, 187, 102, 187], fill=1)
    d.line([98, 189, 101, 189], fill=1)
    d.polygon([(105, 184), (110, 184), (111, 191), (104, 191)], fill=13, outline=1)  # alarm "!"
    d.rectangle([107, 185, 108, 188], fill=14)
    d.point((107, 190), fill=14)

    # road paint (officer palette): a Green P stencil in the empty spot, and
    # the yellow stop line in the lane where your rear bumper should stop
    d.rounded_rectangle([81, 193, 94, 206], radius=3, fill=12, outline=1)
    d.rectangle([85, 196, 86, 203], fill=14)                                # P stem
    d.rectangle([87, 196, 89, 197], fill=14)                                # bowl
    d.rectangle([87, 200, 89, 201], fill=14)
    d.rectangle([90, 197, 90, 200], fill=14)
    d.rectangle([49, 226, 70, 229], fill=1)
    d.rectangle([50, 227, 69, 228], fill=7)
    for x in range(52, 69, 6):                                              # hatching
        d.point((x, 227), fill=1)
    # cyclist seen from above, riding north (officer palette): 2 pedal frames
    for k in range(2):
        draw_cyclist(sh, 48 + k * 16, 192, k)
    for k in range(9):
        band, col = k // 2, k % 2
        sh.obj('pcar%d' % k, col * 48, band * 48, 48, 48)
    sh.obj('spotp', 80, 192, 16, 16)
    sh.obj('stopline', 48, 224, 24, 8, 12, 4)
    sh.obj('cyc0', 48, 192, 16, 32, 8, 16)
    sh.obj('cyc1', 64, 192, 16, 32, 8, 16)
    sh.obj('parked', 96, 0, 32, 48)
    sh.obj('truck', 96, 48, 32, 48)
    sh.obj('cop0', 96, 96, 16, 32, 8, 30)
    sh.obj('cop1', 112, 96, 16, 32, 8, 30)
    sh.obj('hydrant', 96, 144, 8, 8)
    sh.obj('geyser0', 96, 192, 16, 64, 8, 62)
    sh.obj('geyser1', 112, 192, 16, 64, 8, 62)
    sh.obj('marker', 96, 176, 8, 8, 4, 7)
    sh.obj('pin_ok', 104, 176, 8, 8, 4, 7)
    sh.obj('pin_bad', 112, 176, 8, 8, 4, 7)
    sh.obj('sparkle', 120, 176, 8, 8)
    sh.obj('ticket', 96, 184, 8, 8)
    sh.obj('alarm', 104, 184, 8, 8)
    out('parking_spr.bin', sh.tiles())
    with open('build/parking_meta.inc', 'w') as f:
        f.write(sh.meta_inc())
    pals = [art_bike.car_pal('red'), art_bike.car_pal('blue'), art_bike.car_pal('white'),
            [hexrgb(c) for c in TRUCK], [hexrgb(c) for c in OFFICER]]
    data = bytearray()
    for p in pals:
        data += pal_bytes(p, 16)
    out('parking_spr_pal.bin', data)      # sprite palettes 1..5
    return sh


def build():
    img = street()
    pals = build_palettes(img, 6)
    ts = TileSet(4)
    m = convert_bg(img, pals, 2, ts)
    out('parking_tiles.bin', ts.data())
    out('parking_map.bin', map_bytes(m)[:2048])
    data = bytearray()
    for p in pals:
        data += pal_bytes(p, 16)
    data += bytes(32 * (6 - len(pals)))
    out('parking_pal.bin', data)
    sh = build_sprites()
    view = img.crop((0, 0, 256, 224)).copy()
    view.alpha_composite(render(sh, (96, 0, 32, 48), art_bike.car_pal('red')), (200, 20))
    view.alpha_composite(render(sh, (96, 0, 32, 48), art_bike.car_pal('blue')), (200, 126))
    for k, (x, y) in enumerate([(165, 40), (170, 70), (180, 95)]):
        f = [0, 4, 6][k]
        view.alpha_composite(render(sh, ((f % 2) * 48, (f // 2) * 48, 48, 48), P.ATHLETE), (x, y))
    view.alpha_composite(render(sh, (96, 48, 32, 48), TRUCK), (150, 160))
    view.alpha_composite(render(sh, (96, 96, 16, 32), OFFICER), (232, 60))
    view.alpha_composite(render(sh, (96, 144, 8, 8), TRUCK), (240, 116))
    view.alpha_composite(render(sh, (96, 152, 16, 16), TRUCK), (236, 104))
    view.alpha_composite(render(sh, (48, 192, 16, 32), OFFICER), (162, 150))
    preview(view, 'parking.png')
    return '%d tiles, %d pals' % (len(ts), len(pals))


if __name__ == '__main__':
    print(build())
