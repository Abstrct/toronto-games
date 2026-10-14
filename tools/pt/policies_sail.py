"""Harbour Regatta bots.

The skilled ones read the boat from event RAM (position, heading, wind, next
mark) and sail it like a person would: straight at the mark when it can be
reached, zig-zagging at ~50 degrees off the wind when it's upwind, hiking out
in gusts.

    sail_expert   tight tacks, exact steering, hikes in gusts, rounds the
                  marks close (TIGHT ROUNDING) and surfs the ferry when it can
    sail_casual   a decent club sailor: late reactions, wide steering slop
    sail_human    a first-timer who only uses what's on screen: the 16-way
                  yellow arrow, the no-go ticks and the IN IRONS message, with
                  a ~15-frame reaction time and sloppy, overshooting steering
    sail_pointer  a beginner who just follows the yellow arrow (no tacking)
"""
import math
import os
import re
import sys

from policies import Policy, A, LEFT, RIGHT

# ev_ram offsets (src/ev_sail.s)
O_X, O_Y, O_HEAD, O_SPEED, O_WIND, O_GUST, O_STATE, O_MARK = 0, 4, 8, 10, 12, 18, 22, 28
O_FY, O_FERRYD, O_FWAIT, O_IRONS, O_LUFF, O_BRG = 44, 46, 60, 56, 176, 250
NOGO = 28


def _layout():
    """Course from build/sail_layout.inc (written by tools/art_sail.py)."""
    here = os.path.dirname(os.path.abspath(__file__))
    txt = open(os.path.join(here, '..', '..', 'build', 'sail_layout.inc')).read()
    num = lambda k: int(re.search(r'^%s = (\d+)' % k, txt, re.M).group(1))
    xs = [int(v) for v in re.search(r'MARK_XS (.*)', txt).group(1).split(',')]
    ys = [int(v) for v in re.search(r'MARK_YS (.*)', txt).group(1).split(',')]
    return list(zip(xs, ys)), (num('LINE_X'), num('LINE_Y')), num('FERRY_X')


MARKS, LINE, FERRY_X = _layout()


def _game(pol):
    g = getattr(pol, 'game', None)
    if g is not None:
        return g
    f = sys._getframe(2)
    while f is not None:
        g = f.f_locals.get('g')
        if g is not None and hasattr(g, 'core') and hasattr(g, 'sym'):
            pol.game = g
            return g
        f = f.f_back
    raise RuntimeError('policies_sail: no Game on the stack (run_bot changed?)')


def read_boat(pol):
    g = _game(pol)
    base = g.sym['ev_ram']
    m = g.core.peek(base, 256)
    w = lambda o: m[o] | m[o + 1] << 8
    sw = lambda o: w(o) - 0x10000 if w(o) & 0x8000 else w(o)
    return {'x': w(O_X), 'y': w(O_Y), 'head': m[O_HEAD], 'speed': w(O_SPEED), 'wind': m[O_WIND],
            'gust': w(O_GUST), 'state': m[O_STATE], 'mark': m[O_MARK], 'fy': w(O_FY),
            'ferryd': sw(O_FERRYD), 'fwait': w(O_FWAIT), 'irons': m[O_IRONS], 'luff': m[O_LUFF],
            'brg': m[O_BRG], 'rmark': m[180], 'rmin': w(182)}


def bearing(dx, dy):
    """0..255, 0 = north, clockwise (the game's heading units)."""
    return int(round(math.atan2(dx, -dy) * 128 / math.pi)) & 0xFF


def sdiff(a, b):
    """signed a - b in 1/256 turns"""
    return ((a - b + 128) & 0xFF) - 128


class _Sailor(Policy):
    every = 2
    tack_angle = 38      # off the wind when beating (~53 degrees)
    reach_min = 44       # sail straight at the mark if it's at least this far off the wind
    hysteresis = 12      # how far past the layline before tacking
    deadband = 3
    hike = True
    offset = 0           # aim this many px beside the mark (tight rounding)

    def __init__(self):
        self.tack = 0

    def target(self, b):
        k = b['mark']
        if self.offset and b['rmark'] < 3 and b['rmin'] > self.offset + 3:
            k = b['rmark']                          # finish the rounding close in
        if k >= 3:
            return LINE
        mx, my = MARKS[k]
        if not self.offset:
            return (mx, my)
        # pass the buoy close on the side we're already on
        dx, dy = b['x'] - mx, b['y'] - my
        d = math.hypot(dx, dy) or 1
        if d > 60:
            # aim beside it, perpendicular to the approach
            px, py = -dy / d, dx / d
            return (mx + px * self.offset, my + py * self.offset)
        return (mx + dx / d * self.offset, my + dy / d * self.offset)

    def desired(self, b):
        tx, ty = self.target(b)
        brg = bearing(tx - b['x'], ty - b['y'])
        rel = sdiff(brg, b['wind'])
        if abs(rel) >= self.reach_min:
            self.tack = 1 if rel > 0 else -1
            return brg
        # upwind: hold the current tack until the mark is well past the layline
        if self.tack == 0:
            self.tack = 1 if rel >= 0 else -1
        if self.tack > 0 and rel < -self.hysteresis:
            self.tack = -1
        elif self.tack < 0 and rel > self.hysteresis:
            self.tack = 1
        return (b['wind'] + self.tack * self.tack_angle) & 0xFF

    def act(self, t, tel, rng):
        b = read_boat(self)
        if b['state'] != 0:
            return 0
        d = sdiff(self.desired(b), b['head'])
        m = 0
        if d > self.deadband:
            m = RIGHT
        elif d < -self.deadband:
            m = LEFT
        if self.hike and b['gust']:
            m |= A
        if b['luff'] and not m:
            m = A                                   # sheet in
        return m


class sail_expert(_Sailor):
    """Rounds 10 px off each buoy, looks ahead for geese, kayaks and the
    ferry and steers round them, and rides the ferry's wake when it's going
    her way."""
    offset = 10

    def obstacles(self, b):
        g = _game(self)
        m = g.core.peek(g.sym['ev_ram'] + 64, 20)
        w = lambda o: m[o] | m[o + 1] << 8
        obs = [(w(2 * i), w(10 + 2 * i), 17, 15) for i in range(5)]
        if not b['fwait']:
            obs.append((FERRY_X, b['fy'], 18, 32, b['ferryd']))
        return obs

    def act(self, t, tel, rng):
        b = read_boat(self)
        if b['state'] != 0:
            return 0
        want = self.desired(b)
        sp = b['speed'] / 256.0
        # surf: in the wake astern of a moving ferry going roughly our way
        if not b['fwait'] and abs(b['x'] - FERRY_X) < 16:
            astern = (b['y'] - b['fy']) * (-b['ferryd'])
            fdir = 0 if b['ferryd'] < 0 else 128
            if 36 < astern < 64 and abs(sdiff(want, fdir)) < 56 and abs(sdiff(fdir, b['wind'])) >= 34:
                want = fdir
        # look ahead along the heading we want; steer round anything in the way
        for la in (want, b['head']):
            a = la * math.pi / 128
            hit = None
            for k in range(6, 40, 3):
                px = b['x'] + math.sin(a) * sp * k
                py = b['y'] - math.cos(a) * sp * k
                for o in self.obstacles(b):
                    oy = o[1] + (o[4] * k / 2 if len(o) > 4 else 0)
                    if abs(px - o[0]) < o[2] and abs(py - oy) < o[3]:
                        hit = (o[0], oy)
                        break
                if hit:
                    break
            if hit:
                # turn away from the obstacle's side
                ob = bearing(hit[0] - b['x'], hit[1] - b['y'])
                side = sdiff(ob, la)
                want = (la - 40 if side > 0 else la + 40) & 0xFF
                # never into irons to dodge
                if abs(sdiff(want, b['wind'])) < 34:
                    want = (la + 40 if side > 0 else la - 40) & 0xFF
                break
        d = sdiff(want, b['head'])
        m = 0
        if d > self.deadband:
            m = RIGHT
        elif d < -self.deadband:
            m = LEFT
        if b['gust']:
            m |= A
        if b['luff'] and not m:
            m = A
        return m


class sail_casual(_Sailor):
    every = 8            # reacts ~8 times a second
    tack_angle = 44      # sails a bit wide of the wind
    hysteresis = 22      # long tacks, overstands the marks
    deadband = 8

    def act(self, t, tel, rng):
        m = super().act(t, tel, rng)
        if rng.random() < 0.15:                    # fumbles now and then
            m = rng.choice([0, LEFT, RIGHT])
        if m & A and rng.random() < 0.4:            # forgets to hike
            m &= ~A
        return m


class sail_human(Policy):
    """Plays from the screen, late and sloppy.

    What a person sees: the yellow arrow (16 directions), the boat's heading
    (16 frames), whether the no-go ticks are showing / red, the GUST label and
    the IN IRONS message with its arrow. It reacts to what the screen showed
    ~15 frames ago (12-20, varying), holds a turn until the picture looks
    right (so it overshoots), and is never exact about the close-hauled angle.
    """
    every = 1

    def __init__(self):
        self.hist = []
        self.hold = 0
        self.until = 0
        self.lag = 15
        self.tack = 0
        self.beat = 44
        self.hike_on = False

    def act(self, t, tel, rng):
        b = read_boat(self)
        self.hist.append(b)
        if b['state'] != 0:
            return 0
        if t < self.until:                          # still carrying out the last decision
            return self.hold
        seen = self.hist[max(0, len(self.hist) - 1 - self.lag)]
        self.lag = rng.randint(12, 20)
        # the boat sprite (16 frames) as it looks now: a person tracks their own
        # boat continuously; it's the rest of the picture they're slow on
        h = (((b['head'] + 8) >> 4) & 15) * 16 + rng.randint(-6, 6)
        a = (((seen['brg'] + 8) >> 4) & 15) * 16
        wind8 = (((seen['wind'] + 16) >> 5) & 7) * 32     # the HUD vane: 8 directions
        rel_arrow = sdiff(a, wind8)
        if abs(rel_arrow) < 40:
            # the arrow points into the wind (inside the ticks): zig-zag at a
            # guessed angle, tack when the arrow is well over the other side
            if self.tack == 0:
                self.tack = 1 if rel_arrow >= 0 else -1
                self.beat = rng.randint(38, 56)
            elif self.tack > 0 and rel_arrow < -rng.randint(12, 28):
                self.tack = -1
                self.beat = rng.randint(38, 56)
            elif self.tack < 0 and rel_arrow > rng.randint(12, 28):
                self.tack = 1
                self.beat = rng.randint(38, 56)
            want = (wind8 + self.tack * self.beat) & 0xFF
        else:
            self.tack = 0
            want = a
        irons = seen['irons'] >= 12 and abs(sdiff(seen['head'], seen['wind'])) < NOGO and seen['speed'] < 0x60
        if irons:
            m = RIGHT if sdiff(seen['head'], seen['wind']) >= 0 else LEFT
            dur = rng.randint(6, 14)
        else:
            err = sdiff(want, h)
            if abs(err) <= rng.choice((8, 12, 16)):
                m = 0
                dur = self.lag
            else:
                m = RIGHT if err > 0 else LEFT
                # a person turns for about as long as it looks like it needs, plus slop
                dur = max(3, int(abs(err) / 3.0 * rng.uniform(0.7, 1.35)))
        # gusts: hike most of the time, a bit late
        if seen['gust']:
            if not self.hike_on and rng.random() < 0.7:
                self.hike_on = True
        else:
            self.hike_on = False
        if self.hike_on:
            m |= A
        if rng.random() < 0.04:                     # fumble
            m = rng.choice([0, LEFT, RIGHT])
        if seen['luff'] and not m:
            m = rng.choice([LEFT, RIGHT])
        self.hold = m
        self.until = t + min(dur, 30)
        return m


class sail_pointer(_Sailor):
    """Follows the arrow straight at the mark, like the panel did."""
    every = 4
    hike = False

    def desired(self, b):
        tx, ty = self.target(b)
        return bearing(tx - b['x'], ty - b['y'])


POLICIES = {c.__name__: c for c in (sail_expert, sail_casual, sail_human, sail_pointer)}
DEFAULTS = {'sail': ['idle', 'hold_a', 'hold_right', 'mash_a', 'random_input', 'sail_random', 'sail_tack',
                     'sail_pointer', 'sail_human', 'sail_casual', 'sail_expert']}
