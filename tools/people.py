"""Side-view people (facing right), 16x32, drawn from joint angles on an
indexed Sheet. Colour indices follow the athlete layout so any person can
be palette-swapped (player palette from player_palette, crowd palettes here):
 1 outline 2 skin 3 skin shade 4 hair 5 top 6 top shade 7 accent (tie/stripe)
 8 pants 9 pants shade 10 white 11 shoes 12 yellow 13 dark yellow 14 lt grey 15 grey"""
import math
from snes import hexrgb

ATHLETE = ['#000000', '#101018', '#f8c890', '#c88850', '#483018', '#e02818', '#901010',
           '#f8f8f8', '#283878', '#182450', '#f8f8f8', '#383038', '#f8d020', '#a87810',
           '#d8d8e8', '#787890']


def crowd_pal(skin, shade, hair, top, top_sh, accent, pants, pants_sh, shoes='#302828'):
    p = list(ATHLETE)
    p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[11] = (skin, shade, hair, top, top_sh,
                                                             accent, pants, pants_sh, shoes)
    return [hexrgb(c) for c in p]


CROWD = [
    # suit: grey suit, red tie
    crowd_pal('#f0c8a0', '#c09070', '#302018', '#585868', '#383848', '#c82828', '#404050', '#282838'),
    # tourist: hawaiian-ish shirt, khaki shorts (pants colour)
    crowd_pal('#f8d0b0', '#d0a080', '#c89040', '#30a8c8', '#1878a0', '#f8e040', '#c8b080', '#a08858'),
    # office worker: blue shirt, navy pants
    crowd_pal('#a86840', '#784828', '#181010', '#5888d0', '#3860a8', '#f8f8f8', '#283050', '#181c38'),
    # student: green hoodie, jeans
    crowd_pal('#e8b888', '#b88858', '#683818', '#38904c', '#206830', '#d8d8d8', '#4060a0', '#283c70'),
]


def _limb(d, x, y, ang, length, col, width=2):
    ex = x + math.sin(math.radians(ang)) * length
    ey = y + math.cos(math.radians(ang)) * length
    d.line([x, y, ex, ey], fill=col, width=width)
    return ex, ey


def draw_person(sh, x0, y0, legs=(20, -20), knees=(0, 0), arms=(-20, 20), elbows=(0, 0),
                bob=0, lean=0, head_down=False, item=None, item_arm=0):
    """legs/arms: (front, back) angles in degrees from straight down, + = forward.
    knees/elbows: extra bend. item drawn in the front hand."""
    d = sh.draw()
    hip = (x0 + 8, y0 + 19 + bob)
    sh_ = (x0 + 8 + lean, y0 + 11 + bob)

    def leg(front):
        i = 0 if front else 1
        col, shoe = (8, 11) if front else (9, 11)
        kx, ky = _limb(d, hip[0], hip[1], legs[i], 6, col)
        fx, fy = _limb(d, kx, ky, legs[i] - knees[i], 6, col)
        d.line([fx - 1, fy, fx + 2, fy], fill=shoe)
        d.point((fx + 2, fy - 1), fill=shoe)

    def arm(front):
        i = 0 if front else 1
        col = 5 if front else 6
        ex, ey = _limb(d, sh_[0], sh_[1] + 1, arms[i], 5, col)
        hx, hy = _limb(d, ex, ey, arms[i] + elbows[i], 4, col, 1)
        d.point((hx, hy), fill=2)
        return hx, hy

    arm(False)
    leg(False)
    # torso
    d.polygon([(x0 + 5 + lean, y0 + 10 + bob), (x0 + 10 + lean, y0 + 10 + bob),
               (x0 + 10, y0 + 20 + bob), (x0 + 5, y0 + 20 + bob)], fill=5)
    d.line([x0 + 5 + lean, y0 + 11 + bob, x0 + 5, y0 + 19 + bob], fill=6)
    d.line([x0 + 9 + lean, y0 + 11 + bob, x0 + 9, y0 + 14 + bob], fill=7)
    leg(True)
    # head
    hx = x0 + 5 + lean + (1 if head_down else 0)
    hy = y0 + 1 + bob + (1 if head_down else 0)
    d.ellipse([hx, hy, hx + 6, hy + 7], fill=2)
    d.chord([hx, hy - 1, hx + 6, hy + 5], 180, 360, fill=4)
    d.rectangle([hx, hy + 1, hx + 1, hy + 4], fill=4)
    d.point((hx + 2, hy + 4), fill=3)
    d.point((hx + 5, hy + (5 if head_down else 3)), fill=1)
    hand = arm(True)
    if item:
        item(d, hand[0], hand[1])
    sh.outline(x0, y0, 16, 32)


def coffee(d, x, y):
    d.rectangle([x - 1, y - 4, x + 1, y], fill=10)
    d.line([x - 1, y - 2, x + 1, y - 2], fill=6)
    d.line([x - 1, y - 5, x + 1, y - 5], fill=15)


def phone(d, x, y):
    d.rectangle([x, y - 3, x + 1, y], fill=1)
    d.point((x + 1, y - 3), fill=14)


def tallboy(d, x, y):
    d.rectangle([x - 1, y - 5, x + 1, y], fill=13)
    d.line([x - 1, y - 5, x + 1, y - 5], fill=14)


WALK = [dict(legs=(24, -20), knees=(0, 10), arms=(-18, 18), bob=0),
        dict(legs=(8, -6), knees=(0, 30), arms=(-6, 6), bob=-1),
        dict(legs=(-20, 24), knees=(10, 0), arms=(18, -18), bob=0),
        dict(legs=(-6, 8), knees=(30, 0), arms=(6, -6), bob=-1)]
RUN = [dict(legs=(40, -30), knees=(10, 50), arms=(-35, 40), elbows=(80, 80), bob=0, lean=1),
       dict(legs=(15, -10), knees=(20, 80), arms=(-10, 15), elbows=(80, 80), bob=-2, lean=1),
       dict(legs=(-30, 40), knees=(50, 10), arms=(40, -35), elbows=(80, 80), bob=0, lean=1),
       dict(legs=(-10, 15), knees=(80, 20), arms=(15, -10), elbows=(80, 80), bob=-2, lean=1)]
JUMP = dict(legs=(50, -10), knees=(90, 60), arms=(-120, -150), elbows=(20, 20), bob=-2, lean=1)
STUMBLE = dict(legs=(30, -25), knees=(0, 0), arms=(-150, -120), elbows=(0, 0), bob=1, lean=-2)
STAND = dict(legs=(4, -4), knees=(0, 0), arms=(-4, 4), bob=0)
SIP = dict(legs=(4, -4), knees=(0, 0), arms=(-150, 4), elbows=(140, 0), bob=0)
EXCUSE = dict(legs=(16, -12), knees=(0, 10), arms=(-80, 10), elbows=(0, 0), bob=0)


def draw_fallen(sh, x0, y0):
    """Lying face down, 32 wide x 16 tall (feet left)."""
    d = sh.draw()
    d.line([x0 + 2, y0 + 12, x0 + 10, y0 + 11], fill=9, width=2)
    d.line([x0 + 2, y0 + 14, x0 + 10, y0 + 13], fill=8, width=2)
    d.rectangle([x0 + 10, y0 + 9, x0 + 20, y0 + 14], fill=5)
    d.line([x0 + 20, y0 + 10, x0 + 27, y0 + 7], fill=5, width=2)
    d.ellipse([x0 + 21, y0 + 8, x0 + 28, y0 + 14], fill=2)
    d.chord([x0 + 21, y0 + 7, x0 + 28, y0 + 13], 180, 360, fill=4)
    d.point((x0 + 1, y0 + 12), fill=11)
    d.point((x0 + 1, y0 + 14), fill=11)
    sh.outline(x0, y0, 32, 16)
