"""TTC Surfing: inside a Line 1 subway car (BG1, windows cut out), the tunnel
racing past (BG2, 64x32) and a station platform (32x32, streamed into BG2 a
column at a time as the train pulls in), sprites for the big balancing rider
and his gags, passengers, the balance ring (a dark disc with a sweet spot and
a red danger rim), the dot, the lean arrows and germs.

Screen bands (BG1): 0-33 dark HUD band (two text rows at 16 px pitch),
35-37 ceiling lamp, 38-49 ad cards, 52-112 windows, 116-150 seats,
151-167 wall, 168-239 floor, 240-255 HUD band colour again (the car sways
a few px vertically, so the wrap-around rows must match)."""
import math
import random
from PIL import Image, ImageDraw
from snes import (TileSet, convert_bg, build_palettes, map_bytes, pal_bytes, hexrgb, snap,
                  out, preview)
from sprites import Sheet, render
import people as P

WIN_TOP, WIN_BOT = 52, 112
FLOOR = 168
BAND = '#24242c'


def rgb(h):
    return snap(hexrgb(h)) + (255,)


def interior():
    img = Image.new('RGBA', (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    wall, wall2, wall3 = rgb('#d8d8d0'), rgb('#b0b0a8'), rgb('#f0f0e8')
    ceil, lamp = rgb('#c8c8c0'), rgb('#f8f8e0')
    seat, seat2, seat3 = rgb('#c82828'), rgb('#901818'), rgb('#e85048')
    pole, pole2 = rgb('#f0c820'), rgb('#a88010')
    floor, floor2 = rgb('#404048'), rgb('#55555e')
    frame = rgb('#6a6a72')
    band = rgb(BAND)
    # HUD band: two 16 px text rows on a plain dark panel, a TTC-red trim under it
    d.rectangle([0, 0, 255, 33], fill=band)
    d.line([0, 33, 255, 33], fill=rgb('#c81e28'))
    d.rectangle([0, 34, 255, 37], fill=ceil)
    d.rectangle([0, 35, 255, 36], fill=lamp)
    # ad strip
    d.rectangle([0, 38, 255, 51], fill=wall)
    ads = ['#3878d0', '#f08020', '#38a048', '#c83878', '#f0c020', '#5848b0']
    for i, x in enumerate(range(4, 256, 42)):
        d.rectangle([x, 39, x + 36, 49], fill=rgb(ads[i % len(ads)]))
        d.rectangle([x + 3, 41, x + 14, 47], fill=wall3)
        d.line([x + 17, 42, x + 33, 42], fill=wall3)
        d.line([x + 17, 45, x + 29, 45], fill=wall3)
    # wall, windows cut out
    d.rectangle([0, 50, 255, FLOOR - 1], fill=wall)
    for x0 in range(8, 256, 64):
        d.rounded_rectangle([x0 - 1, WIN_TOP - 1, x0 + 48, WIN_BOT + 1], radius=4, fill=frame)
        d.rounded_rectangle([x0, WIN_TOP, x0 + 47, WIN_BOT], radius=4, fill=(0, 0, 0, 0))
    # overhead grab bar + straps
    d.rectangle([0, 54, 255, 55], fill=pole)
    for x in range(20, 256, 32):
        d.line([x, 56, x, 61], fill=frame)
        d.ellipse([x - 3, 61, x + 3, 67], outline=frame)
    # seats along the wall
    d.rectangle([0, 116, 255, 140], fill=seat)
    for x in range(0, 256, 24):
        d.line([x, 116, x, 140], fill=seat2)
    d.line([0, 117, 255, 117], fill=seat3)
    d.rectangle([0, 141, 255, 150], fill=seat2)
    d.rectangle([0, 151, 255, FLOOR - 1], fill=wall2)
    # floor
    d.rectangle([0, FLOOR, 255, 239], fill=floor)
    rnd = random.Random(4)
    for _ in range(240):
        x, y = rnd.randrange(256), rnd.randrange(FLOOR, 240)
        d.point((x, y), fill=floor2)
    d.line([0, FLOOR, 255, FLOOR], fill=frame)
    d.rectangle([0, 240, 255, 255], fill=band)
    # vertical poles (the sticky one at 96 is the gag's)
    for x in (56, 96, 160, 200):
        d.rectangle([x, 56, x + 2, FLOOR + 40], fill=pole)
        d.line([x + 2, 56, x + 2, FLOOR + 40], fill=pole2)
    return img


def tunnel():
    """Dark concrete, cable runs, ribs; the only lamps are dim amber signal
    lights low on the wall (nothing the size or colour of the balance dot)."""
    img = Image.new('RGBA', (512, 256), rgb('#18181c'))
    d = ImageDraw.Draw(img)
    for y in (60, 66, 98):
        d.line([0, y, 511, y], fill=rgb('#38343a'))
        d.line([0, y + 1, 511, y + 1], fill=rgb('#28242a'))
    for x in range(0, 512, 64):
        d.rectangle([x, 52, x + 3, 120], fill=rgb('#2a282e'))
        d.line([x + 4, 52, x + 4, 120], fill=rgb('#222026'))
    for x in range(40, 512, 128):
        d.rectangle([x, 84, x + 9, 90], fill=rgb('#30303a'))
        d.rectangle([x + 2, 86, x + 4, 88], fill=rgb('#a85818'))
        d.rectangle([x + 6, 86, x + 7, 88], fill=rgb('#502010'))
    for x in (100, 356):
        d.rectangle([x, 72, x + 22, 80], fill=rgb('#2c4030'))
        d.line([x + 2, 76, x + 20, 76], fill=rgb('#3c5840'))
    return img


def platform():
    """Line 1 station wall: vitrolite tiles, green trim, a white name band
    (rows 7-9, where the station sign box lands) and the yellow edge strip."""
    img = Image.new('RGBA', (256, 256), rgb('#d8d0b0'))
    d = ImageDraw.Draw(img)
    for y in range(52, 120, 8):
        d.line([0, y, 255, y], fill=rgb('#c0b898'))
    for x in range(0, 256, 8):
        d.line([x, 52, x, 119], fill=rgb('#c8c0a0'))
    d.rectangle([0, 50, 255, 53], fill=rgb('#2a8a4a'))
    d.rectangle([0, 56, 255, 79], fill=rgb('#f8f4e8'))
    d.rectangle([0, 84, 255, 87], fill=rgb('#2a8a4a'))
    for x in range(12, 256, 64):
        d.rectangle([x, 92, x + 22, 104], fill=rgb('#a8a090'))   # benches/columns
        d.rectangle([x + 2, 94, x + 20, 96], fill=rgb('#887f70'))
    d.rectangle([0, 106, 255, 112], fill=rgb('#a8a090'))
    d.rectangle([0, 108, 255, 110], fill=rgb('#f0c820'))
    return img


# -------------------------------------------------------------- sprites
# misc palette (sprite palette 5): ring, dots, arrows, germs
MISC = ['#000000', '#101018', '#f8f8f8', '#a8b8c8', '#48e048', '#208820', '#f8e040', '#f04838',
        '#f89838', '#88d8f8', '#c8f8a0', '#1c2444', '#34427a', '#6a2034', '#c8d0e8', '#283058']

RW, RH = 32, 40


def _pt(x, y, ang, length):
    return (x + math.sin(math.radians(ang)) * length, y + math.cos(math.radians(ang)) * length)


def big_person(sh, x0, y0, legs=(14, -14), knees=(0, 0), arms=(-40, 40), elbows=(0, 0), bob=0,
               tilt=0, hip=(14, 25), eyes='open', mouth=False):
    """The big rider (athlete colour layout, ~38 px tall in a 32x40 cell):
    legs/arms are world angles from straight down (+ = forward, right),
    tilt pitches the torso (+ = forward)."""
    d = sh.draw()
    hx, hy = x0 + hip[0], y0 + hip[1] + bob
    sx, sy = _pt(hx, hy, 180 - tilt, 11)
    nx, ny = _pt(hx, hy, 180 - tilt, 13)
    cx, cy = _pt(hx, hy, 180 - tilt, 18)

    def leg(front):
        i = 0 if front else 1
        col = 8 if front else 9
        kx, ky = _pt(hx, hy, legs[i], 7)
        fx, fy = _pt(kx, ky, legs[i] - knees[i], 7)
        d.line([hx, hy, kx, ky], fill=col, width=3)
        d.line([kx, ky, fx, fy], fill=col, width=3)
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
    d.line([hx, hy, sx, sy], fill=5, width=7)
    c, s = math.cos(math.radians(tilt)), math.sin(math.radians(tilt))
    d.line([hx - 3 * c, hy - 3 * s, sx - 3 * c, sy - 3 * s], fill=6, width=1)
    d.line([hx + 2 * c, hy + 2 * s - 3, sx + 2 * c, sy + 2 * s], fill=7, width=1)
    d.line([hx - 3, hy, hx + 3, hy], fill=9)
    leg(True)
    d.line([sx, sy, nx, ny], fill=2, width=3)
    hxl, hyt = round(cx - 4), round(cy - 5)
    d.ellipse([hxl, hyt, hxl + 8, hyt + 9], fill=2)
    d.chord([hxl - 1, hyt - 1, hxl + 8, hyt + 6], 180, 360, fill=4)
    d.rectangle([hxl - 1, hyt + 1, hxl + 1, hyt + 5], fill=4)
    d.point((hxl + 3, hyt + 5), fill=3)
    ey = hyt + 4
    if eyes == 'shut':
        d.line([hxl + 6, ey, hxl + 7, ey], fill=1)
    elif eyes == 'wide':
        d.rectangle([hxl + 6, ey - 1, hxl + 7, ey], fill=10)
        d.point((hxl + 7, ey), fill=1)
    else:
        d.point((hxl + 7, ey), fill=1)
        d.point((hxl + 6, ey), fill=1)
    if mouth:
        d.rectangle([hxl + 6, ey + 3, hxl + 7, ey + 4], fill=1)
    arm(True)
    sh.outline(x0, y0, RW, RH)


# rider frames (32x40 cells, 4 per row)
RIDER = [
    ('up', dict(arms=(-75, 75), elbows=(-20, 20))),                         # surfing stance
    ('lb1', dict(arms=(-100, 50), elbows=(-20, 20), tilt=-8, legs=(20, -10))),
    ('lb2', dict(arms=(-140, 10), elbows=(0, 30), tilt=-16, legs=(28, -6), eyes='wide')),
    ('lf1', dict(arms=(-50, 100), elbows=(-20, 20), tilt=8, legs=(10, -20))),
    ('lf2', dict(arms=(-10, 140), elbows=(-30, 0), tilt=16, legs=(6, -28), eyes='wide')),
    ('wobble', dict(arms=(-160, 160), elbows=(40, -40), knees=(30, 20), legs=(30, -24), bob=2,
                    eyes='wide', mouth=True)),
    ('pole', dict(arms=(-150, -120), elbows=(30, 20), tilt=-14, legs=(-20, -40), eyes='shut')),
    ('face', dict(arms=(150, 110), elbows=(0, 0), tilt=48, legs=(-10, -40), knees=(0, 20),
                  eyes='shut', hip=(10, 25))),
    ('sit', dict(arms=(-150, 150), elbows=(30, -30), legs=(80, 70), knees=(85, 80), bob=4,
                 eyes='wide', mouth=True)),
    ('floor', dict(arms=(10, 30), elbows=(0, 0), tilt=70, legs=(-60, -80), knees=(-100, -90),
                   hip=(12, 30), eyes='shut')),
    ('walk0', dict(arms=(-30, 30), legs=(26, -22), knees=(0, 12))),
    ('walk1', dict(arms=(20, -20), legs=(-20, 26), knees=(12, 0))),
]


def build_sprites():
    sh = Sheet(208)
    d = sh.draw()
    for i, (n, pose) in enumerate(RIDER):
        big_person(sh, (i % 4) * RW, (i // 4) * RH, **pose)
    # passengers (16x32) at y=128: a 16x16 piece must never start on tile
    # row 15 or 31 (its lower half would wrap inside the 256-tile name table)
    PY = 128
    P.draw_person(sh, 0, PY, legs=(85, 80), knees=(90, 85), arms=(-60, 10), elbows=(70, 0), bob=6,
                  head_down=True, item=P.phone)
    P.draw_person(sh, 16, PY, legs=(85, 80), knees=(90, 85), arms=(10, -10), bob=7, head_down=True)
    P.draw_person(sh, 32, PY, legs=(6, -6), knees=(0, 0), arms=(-175, 10), elbows=(0, 0))
    P.draw_person(sh, 48, PY, legs=(6, -6), knees=(0, 0), arms=(10, -10), elbows=(0, 0))
    d.rounded_rectangle([48 + 1, PY + 9, 48 + 6, PY + 21], radius=2, fill=9)
    d.line([48 + 2, PY + 12, 48 + 5, PY + 12], fill=6)
    sh.outline(48, PY, 16, 32)
    P.draw_person(sh, 64, PY, **P.WALK[0])
    P.draw_person(sh, 80, PY, **P.WALK[2])
    # lean arrows 16x16 at (96,128) right, (112,128) up: yellow, dark outline
    AY = 128
    d.polygon([(97, AY + 5), (104, AY + 5), (104, AY + 1), (111, AY + 7), (111, AY + 8), (104, AY + 14),
               (104, AY + 10), (97, AY + 10)], fill=6, outline=1)
    d.line([98, AY + 9, 104, AY + 9], fill=8)
    d.polygon([(117, AY + 15), (117, AY + 8), (113, AY + 8), (119, AY + 1), (120, AY + 1), (126, AY + 8),
               (122, AY + 8), (122, AY + 15)], fill=6, outline=1)
    d.line([121, AY + 9, 121, AY + 14], fill=8)
    # dots 8x8 at y=144: ok (white/cyan), sweet (gold), danger (red), parked (grey)
    for k, (fc, sc) in enumerate(((2, 9), (6, 8), (7, 13), (3, 15))):
        x0 = 96 + k * 8
        d.ellipse([x0, 144, x0 + 6, 150], fill=sc, outline=1)
        d.ellipse([x0 + 1, 145, x0 + 4, 148], fill=fc)
    # germs 8x8 at (96,152),(104,152)
    for k in range(2):
        x0 = 96 + k * 8
        pts = [(1, 2), (5, 1), (3, 4), (6, 5), (2, 6)] if k == 0 else [(2, 1), (6, 2), (1, 4), (4, 5), (6, 6)]
        for (x, y) in pts:
            d.ellipse([x0 + x - 1, 152 + y - 1, x0 + x + 1, 152 + y + 1], fill=4)
            d.point((x0 + x, 152 + y), fill=10)
    # balance ring 48x48 at (0,160): a dark disc (plain backing over anything),
    # a red danger rim, a lighter sweet spot in the middle, white outline
    cx, cy = 23.5, 160 + 23.5
    for y in range(160, 208):
        for x in range(0, 48):
            r = math.hypot(x - cx, y - cy)
            if r <= 23.6:
                c = 11
                if r > 22.4:
                    c = 1
                elif r > 21.2:
                    c = 2
                elif r > 17.5:
                    c = 13
                elif r <= 5.6:
                    c = 12 if r <= 4.6 else 15
                if c == 11 and (abs(x - cx) < 0.6 or abs(y - cy) < 0.6) and 8 < r < 17:
                    c = 15
                sh.px(x, y, c)
    names = [n for n, _ in RIDER]
    for i, n in enumerate(names):
        sh.obj(n, (i % 4) * RW, (i // 4) * RH, RW, RH, 16, 39)
    for n, x in (('sit_phone', 0), ('sit_sleep', 16), ('strap', 32), ('backpack', 48), ('walk_a', 64),
                 ('walk_b', 80)):
        sh.obj(n, x, PY, 16, 32, 8, 31)
    sh.obj('arrow_r', 96, 128, 16, 16)
    sh.obj('arrow_u', 112, 128, 16, 16)
    for k, n in enumerate(('dot_ok', 'dot_sweet', 'dot_bad', 'dot_off')):
        sh.obj(n, 96 + k * 8, 144, 8, 8, 3, 3)
    sh.obj('germ0', 96, 152, 8, 8, 4, 4)
    sh.obj('germ1', 104, 152, 8, 8, 4, 4)
    sh.obj('ring', 0, 160, 48, 48, 24, 24)
    out('subway_spr.bin', sh.tiles())
    with open('build/subway_meta.inc', 'w') as f:
        f.write(sh.meta_inc())
    data = bytearray()
    for p in P.CROWD:
        data += pal_bytes(p, 16)
    data += pal_bytes([hexrgb(c) for c in MISC], 16)
    out('subway_spr_pal.bin', data)      # sprite palettes 1..5
    return sh


def build():
    car = interior()
    tun = tunnel()
    plat = platform()
    allimg = Image.new('RGBA', (512, 768), (0, 0, 0, 0))
    allimg.paste(car, (0, 0))
    allimg.paste(tun, (0, 256))
    allimg.paste(plat, (0, 512))
    pals = build_palettes(allimg, 6)
    ts = TileSet(4)
    m1 = convert_bg(car, pals, 2, ts, priority=True)
    m2 = convert_bg(tun, pals, 2, ts)
    m3 = convert_bg(plat, pals, 2, ts)
    out('subway_tiles.bin', ts.data())
    out('subway_bg1.bin', map_bytes(m1)[:2048])
    out('subway_tunnel.bin', map_bytes(m2)[:4096])
    out('subway_platform.bin', map_bytes(m3)[:2048])
    data = bytearray()
    for p in pals:
        data += pal_bytes(p, 16)
    data += bytes(32 * (6 - len(pals)))
    out('subway_pal.bin', data)
    sh = build_sprites()
    sh.preview([hexrgb(c) for c in MISC], 'subway_sheet.png')
    for name, back in (('subway.png', tun), ('subway_station.png', plat)):
        view = Image.new('RGBA', (256, 224), (0, 0, 0, 255))
        view.alpha_composite(back.crop((0, 0, 256, 224)))
        view.alpha_composite(car.crop((0, 0, 256, 224)))
        view.alpha_composite(render(sh, (0, 0, 32, 40), P.ATHLETE), (112, 171))
        view.alpha_composite(render(sh, (0, 128, 16, 32), P.CROWD[0]), (32, 120))
        view.alpha_composite(render(sh, (16, 128, 16, 32), P.CROWD[2]), (212, 120))
        view.alpha_composite(render(sh, (48, 128, 16, 32), P.CROWD[3]), (176, 179))
        view.alpha_composite(render(sh, (0, 160, 48, 48), MISC), (104, 108))
        view.alpha_composite(render(sh, (96, 144, 8, 8), MISC), (130, 126))
        view.alpha_composite(render(sh, (96, 128, 16, 16), MISC), (150, 124))
        preview(view, name)
    return '%d tiles, %d pals' % (len(ts), len(pals))


if __name__ == '__main__':
    print(build())
