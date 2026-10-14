"""TTC Surfing: inside a Line 1 subway car (BG1, windows cut out), the tunnel
racing past (BG2, 64x32) and a station platform (BG2 alt map, 32x32),
sprites for the balancing rider, passengers, balance ring + dot, germs."""
import math
import random
from PIL import Image, ImageDraw
from snes import (TileSet, convert_bg, build_palettes, map_bytes, pal_bytes, hexrgb, snap,
                  out, preview)
from sprites import Sheet, render
import people as P

WIN_TOP, WIN_BOT = 40, 112
FLOOR = 168


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
    # ceiling + lights
    d.rectangle([0, 0, 255, 23], fill=ceil)
    d.rectangle([0, 0, 255, 16], fill=rgb('#2c2c34'))      # dark vent panel behind the HUD
    d.line([0, 17, 255, 17], fill=frame)
    d.rectangle([0, 19, 255, 21], fill=lamp)
    d.line([0, 23, 255, 23], fill=wall2)
    # ad strip
    d.rectangle([0, 24, 255, 39], fill=wall)
    ads = ['#3878d0', '#f08020', '#38a048', '#c83878', '#f0c020', '#5848b0']
    for i, x in enumerate(range(4, 256, 42)):
        d.rectangle([x, 26, x + 36, 37], fill=rgb(ads[i % len(ads)]))
        d.rectangle([x + 3, 28, x + 14, 35], fill=wall3)
        d.line([x + 17, 30, x + 33, 30], fill=wall3)
        d.line([x + 17, 33, x + 29, 33], fill=wall3)
    # wall below the windows, windows cut out
    d.rectangle([0, 40, 255, FLOOR - 1], fill=wall)
    for x0 in range(8, 256, 64):
        d.rounded_rectangle([x0 - 1, WIN_TOP - 1, x0 + 48, WIN_BOT + 1], radius=4, fill=frame)
        d.rounded_rectangle([x0, WIN_TOP, x0 + 47, WIN_BOT], radius=4, fill=(0, 0, 0, 0))
    # overhead grab bar + straps
    d.rectangle([0, 44, 255, 45], fill=pole)
    for x in range(20, 256, 32):
        d.line([x, 46, x, 52], fill=frame)
        d.ellipse([x - 3, 52, x + 3, 58], outline=frame)
    # seats along the wall
    d.rectangle([0, 116, 255, 140], fill=seat)
    for x in range(0, 256, 24):
        d.line([x, 116, x, 140], fill=seat2)
    d.line([0, 117, 255, 117], fill=seat3)
    d.rectangle([0, 141, 255, 150], fill=seat2)
    d.rectangle([0, 151, 255, FLOOR - 1], fill=wall2)
    # floor
    d.rectangle([0, FLOOR, 255, 255], fill=floor)
    rnd = random.Random(4)
    for _ in range(260):
        x, y = rnd.randrange(256), rnd.randrange(FLOOR, 256)
        d.point((x, y), fill=floor2)
    d.line([0, FLOOR, 255, FLOOR], fill=frame)
    # vertical poles
    for x in (56, 96, 160, 200):
        d.rectangle([x, 46, x + 2, FLOOR + 30], fill=pole)
        d.line([x + 2, 46, x + 2, FLOOR + 30], fill=pole2)
    return img


def tunnel():
    img = Image.new('RGBA', (512, 256), rgb('#18181c'))
    d = ImageDraw.Draw(img)
    for y in (52, 60, 92):
        d.line([0, y, 511, y], fill=rgb('#38343a'))
        d.line([0, y + 1, 511, y + 1], fill=rgb('#28242a'))
    for x in range(0, 512, 64):
        d.rectangle([x, 40, x + 3, 120], fill=rgb('#2a282e'))
    for x in range(24, 512, 128):
        d.ellipse([x, 70, x + 6, 76], fill=rgb('#f8e8a0'))
        d.ellipse([x + 1, 71, x + 5, 75], fill=rgb('#fff8d8'))
    for x in (96, 352):
        d.rectangle([x, 78, x + 10, 90], fill=rgb('#30303a'))
        d.ellipse([x + 3, 80, x + 7, 84], fill=rgb('#40e060'))
    return img


def platform():
    img = Image.new('RGBA', (256, 256), rgb('#d8d0b0'))
    d = ImageDraw.Draw(img)
    # vitrolite-style tile wall, a coloured trim band, the name band
    for y in range(40, 120, 8):
        d.line([0, y, 255, y], fill=rgb('#c0b898'))
    for x in range(0, 256, 8):
        d.line([x, 40, x, 119], fill=rgb('#c8c0a0'))
    d.rectangle([0, 44, 255, 47], fill=rgb('#2a8a4a'))
    d.rectangle([0, 60, 255, 79], fill=rgb('#f8f4e8'))
    d.rectangle([0, 92, 255, 95], fill=rgb('#2a8a4a'))
    d.rectangle([0, 100, 255, 112], fill=rgb('#a8a090'))
    d.rectangle([0, 108, 255, 110], fill=rgb('#f0c820'))
    return img


# -------------------------------------------------------------- sprites
MISC = ['#000000', '#101018', '#f8f8f8', '#a8b8c8', '#48e048', '#208820', '#f8e040', '#f04838',
        '#f89838', '#88d8f8', '#c8f8a0']


def build_sprites():
    sh = Sheet(80)
    d = sh.draw()
    wide = dict(legs=(14, -14), knees=(0, 0))
    frames = [
        dict(wide, arms=(-40, 40), elbows=(0, 0)),                    # upright, arms out a touch
        dict(wide, arms=(-70, 20), elbows=(0, 0), lean=-2),           # lean back 1
        dict(wide, arms=(-110, -40), elbows=(0, 0), lean=-4),         # lean back 2
        dict(wide, arms=(20, 70), elbows=(0, 0), lean=2),             # lean forward 1
        dict(wide, arms=(60, 110), elbows=(0, 0), lean=4),            # lean forward 2
        dict(legs=(25, -20), knees=(20, 10), arms=(-150, 150), elbows=(30, 30), bob=1),  # wobble
        dict(wide, arms=(-120, -60), elbows=(0, 0), lean=-3),         # grab back (pole)
        dict(wide, arms=(120, 60), elbows=(0, 0), lean=4),            # grab forward
    ]
    for i, f in enumerate(frames):
        P.draw_person(sh, i * 16, 0, **f)
    # sat on a stranger's lap
    P.draw_person(sh, 0, 32, legs=(85, 75), knees=(95, 85), arms=(-120, 140), elbows=(0, 0), bob=6)
    # passengers
    P.draw_person(sh, 16, 32, legs=(85, 80), knees=(90, 85), arms=(-60, 10), elbows=(70, 0), bob=6,
                  head_down=True, item=P.phone)
    P.draw_person(sh, 32, 32, legs=(85, 80), knees=(90, 85), arms=(10, -10), bob=7, head_down=True)
    P.draw_person(sh, 48, 32, legs=(6, -6), knees=(0, 0), arms=(-175, 10), elbows=(0, 0))
    P.draw_person(sh, 64, 32, legs=(6, -6), knees=(0, 0), arms=(10, -10), elbows=(0, 0))
    # huge backpack on the last one
    d.rounded_rectangle([64 + 1, 32 + 9, 64 + 6, 32 + 21], radius=2, fill=9)
    d.line([64 + 2, 32 + 12, 64 + 5, 32 + 12], fill=6)
    sh.outline(64, 32, 16, 32)
    P.draw_person(sh, 80, 32, **P.WALK[0])
    # balance ring 32x32 at (96,32)
    d.ellipse([97, 33, 126, 62], outline=1)
    d.ellipse([98, 34, 125, 61], outline=2)
    d.ellipse([105, 41, 118, 54], outline=3)
    d.line([111, 45, 111, 50], fill=3)
    d.line([109, 47, 114, 47], fill=3)
    # dot (safe / danger), germs, "!"
    d.ellipse([1, 65, 6, 70], fill=6, outline=1)
    d.ellipse([9, 65, 14, 70], fill=7, outline=1)
    for k in range(2):
        x0 = 16 + k * 8
        pts = [(1, 2), (5, 1), (3, 4), (6, 5), (2, 6)] if k == 0 else [(2, 1), (6, 2), (1, 4), (4, 5), (6, 6)]
        for (x, y) in pts:
            d.ellipse([x0 + x - 1, 64 + y - 1, x0 + x + 1, 64 + y + 1], fill=4)
            d.point((x0 + x, 64 + y), fill=10)
    d.polygon([(33, 64), (38, 64), (39, 71), (32, 71)], fill=7, outline=1)
    d.rectangle([35, 65, 36, 68], fill=2)
    d.point((35, 70), fill=2)

    names = ['up', 'lb1', 'lb2', 'lf1', 'lf2', 'wobble', 'grab_b', 'grab_f']
    for i, n in enumerate(names):
        sh.obj(n, i * 16, 0, 16, 32, 8, 31)
    for n, x in (('splat', 0), ('sit_phone', 16), ('sit_sleep', 32), ('strap', 48), ('backpack', 64),
                 ('walker', 80)):
        sh.obj(n, x, 32, 16, 32, 8, 31)
    sh.obj('ring', 96, 32, 32, 32)
    sh.obj('dot_ok', 0, 64, 8, 8, 4, 4)
    sh.obj('dot_bad', 8, 64, 8, 8, 4, 4)
    sh.obj('germ0', 16, 64, 8, 8, 4, 4)
    sh.obj('germ1', 24, 64, 8, 8, 4, 4)
    sh.obj('bang', 32, 64, 8, 8, 4, 8)
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
    for name, back in (('subway.png', tun), ('subway_station.png', plat)):
        view = Image.new('RGBA', (256, 224), (0, 0, 0, 255))
        view.alpha_composite(back.crop((0, 0, 256, 224)))
        view.alpha_composite(car.crop((0, 0, 256, 224)))
        view.alpha_composite(render(sh, (64, 0, 16, 32), P.ATHLETE), (120, 165))
        view.alpha_composite(render(sh, (16, 32, 16, 32), P.CROWD[0]), (24, 120))
        view.alpha_composite(render(sh, (32, 32, 16, 32), P.CROWD[2]), (216, 120))
        view.alpha_composite(render(sh, (64, 32, 16, 32), P.CROWD[3]), (176, 165))
        view.alpha_composite(render(sh, (96, 32, 32, 32), MISC), (112, 60))
        view.alpha_composite(render(sh, (0, 64, 8, 8), MISC), (122, 72))
        preview(view, name)
    return '%d tiles, %d pals' % (len(ts), len(pals))


if __name__ == '__main__':
    print(build())
