"""Harbour Regatta bots.

Steering is in notches (16 directions, one per boat frame): a tap turns the
goal one notch, a hold keeps turning a notch every few frames. The bots steer
the way a person does with that: they pick the notch they want from what's on
screen (the boat, the yellow arrow, the marks and anything in the water within
the camera view), tap or hold for about as many notches as it takes, then
watch the bow line until it settles before deciding again. They never react
to anything off screen.

    sail_expert   tacks on the right notch, rounds the marks close (TIGHT
                  ROUNDING), steers round geese and kayaks it can see, dips
                  into the ferry's wake on the last leg when she's coming
    sail_casual   a decent club sailor: rounds wide, tacks late, fumbles a bit
    sail_human    a first-timer: follows the arrow, zig-zags when it points
                  into the wind, overshoots taps, forgets to hike
    sail_pointer  a beginner who just follows the yellow arrow (no tacking)
"""
import math
import os
import re
import sys

from policies import Policy, A, LEFT, RIGHT

# ev_ram offsets (src/ev_sail.s)
O_X, O_Y, O_HEAD, O_SPEED, O_WIND, O_GUST, O_STATE, O_MARK = 0, 4, 8, 10, 12, 18, 22, 28
O_FX, O_FERRYD, O_FWAIT, O_IRONS, O_BRG = 44, 46, 60, 56, 250
O_CAMX, O_CAMY = 34, 36
O_SURF, O_SURFT, O_SURFOK = 190, 192, 194
O_HGOAL = 288
O_ADIR = 320         # the yellow arrow's notch (shows the tack on a beat)
NOGO = 28
NOTCH = 16


def _layout():
    """Course from build/sail_layout.inc (written by tools/art_sail.py)."""
    here = os.path.dirname(os.path.abspath(__file__))
    txt = open(os.path.join(here, '..', '..', 'build', 'sail_layout.inc')).read()
    num = lambda k: int(re.search(r'^%s = (\d+)' % k, txt, re.M).group(1))
    xs = [int(v) for v in re.search(r'MARK_XS (.*)', txt).group(1).split(',')]
    ys = [int(v) for v in re.search(r'MARK_YS (.*)', txt).group(1).split(',')]
    return (list(zip(xs, ys)), (num('LINE_X'), num('LINE_Y')), num('LINE_HALF'),
            num('FERRY_Y'), num('FERRY_X0'), num('FERRY_X1'))


MARKS, LINE, LINE_HALF, FERRY_Y, FERRY_X0, FERRY_X1 = _layout()


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
    m = g.core.peek(base, 360)
    w = lambda o: m[o] | m[o + 1] << 8
    sw = lambda o: w(o) - 0x10000 if w(o) & 0x8000 else w(o)
    pad = g.core.peek(g.sym['pad'], 2)
    return {'x': w(O_X), 'y': w(O_Y), 'head': m[O_HEAD], 'speed': w(O_SPEED), 'wind': m[O_WIND],
            'gust': w(O_GUST), 'state': m[O_STATE], 'mark': m[O_MARK], 'fx': w(O_FX),
            'ferryd': sw(O_FERRYD), 'fwait': w(O_FWAIT), 'irons': m[O_IRONS],
            'brg': m[O_BRG], 'rmark': m[180], 'rmin': w(182), 'hgoal': m[O_HGOAL],
            'camx': w(O_CAMX), 'camy': w(O_CAMY), 'surf': m[O_SURF], 'surfok': m[O_SURFOK],
            'pad': pad[0] | pad[1] << 8, 'adir': m[O_ADIR],
            'floats': [(w(64 + 2 * i), w(74 + 2 * i)) for i in range(5)]}


def bearing(dx, dy):
    """0..255, 0 = north, clockwise (the game's heading units)."""
    return int(round(math.atan2(dx, -dy) * 128 / math.pi)) & 0xFF


def sdiff(a, b):
    """signed a - b in 1/256 turns"""
    return ((a - b + 128) & 0xFF) - 128


def on_screen(b, x, y, margin=0):
    sx, sy = x - b['camx'], y - b['camy']
    return -margin <= sx < 256 + margin and 32 - margin <= sy < 224 + margin


def notch_of(a):
    return ((a + 8) & 0xFF) & 0xF0


class _Sailor(Policy):
    """Notch steering with a human tap/hold hand and a look-at-the-result pause."""
    every = 1
    beat_margin = 4      # close-hauled notch must be this far outside the no-go
    reach_min = 40       # sail at the mark if it's this far off the wind
    hysteresis = 12      # how far past the layline before tacking
    hike = True
    offset = 0           # aim this many px beside the mark (tight rounding)
    radial_d = 40        # this close, aim at the point offset px out toward us
    settle = 6           # frames to look at the bow line after it moves
    slop = 0             # extra frames a hold runs on (sloppy hands)

    def __init__(self):
        self.tack = 0
        self.press = 0           # current steer mask
        self.until = 0           # press runs until this frame
        self.expect = None       # hgoal we're waiting to see
        self.wait_until = 0
        self.stale = 0
        self.kick = 0
        self.rmark_done = -1

    # ---------------------------------------------------------- where to go
    def target(self, b):
        k = b['mark']
        if self.offset and b['rmark'] < 3 and b['rmin'] > self.offset + 3 and self.rmark_done != b['rmark']:
            k = b['rmark']                          # finish the rounding close in
        elif self.offset and b['rmark'] < 3:
            self.rmark_done = b['rmark']
        if k >= 3:
            return LINE
        mx, my = MARKS[k]
        if not self.offset:
            return (mx, my)
        # pass the buoy close on the side we're already on
        dx, dy = b['x'] - mx, b['y'] - my
        d = math.hypot(dx, dy) or 1
        if d > self.radial_d:
            px, py = -dy / d, dx / d
            return (mx + px * self.offset, my + py * self.offset)
        return (mx + dx / d * self.offset, my + dy / d * self.offset)

    def beat_notch(self, wind, side):
        """the notch closest to the wind on this tack that still drives"""
        for k in range(1, 8):
            n = (notch_of(wind) + side * k * NOTCH) & 0xFF
            r = sdiff(n, wind)
            if abs(r) >= NOGO + self.beat_margin and (r > 0) == (side > 0):
                return n
        return (wind + side * 64) & 0xFF

    def free_notch(self, brg, wind):
        """nearest notch to a bearing that isn't in the no-go"""
        n = notch_of(brg)
        r = sdiff(n, wind)
        if abs(r) >= NOGO + self.beat_margin:
            return n
        return self.beat_notch(wind, 1 if sdiff(brg, wind) >= 0 else -1)

    def desired(self, b):
        tx, ty = self.target(b)
        brg = bearing(tx - b['x'], ty - b['y'])
        rel = sdiff(brg, b['wind'])
        if abs(rel) >= self.reach_min:
            self.tack = 1 if rel > 0 else -1
            # hold the current notch while the bearing is still near it
            cur = b['hgoal']
            if abs(sdiff(brg, cur)) <= 11 and abs(sdiff(cur, b['wind'])) >= NOGO + self.beat_margin:
                return cur
            return self.free_notch(brg, b['wind'])
        if self.tack == 0:
            self.tack = 1 if rel >= 0 else -1
        if self.tack > 0 and rel < -self.hysteresis:
            self.tack = -1
        elif self.tack < 0 and rel > self.hysteresis:
            self.tack = 1
        return self.beat_notch(b['wind'], self.tack)

    def avoid(self, b, want):
        return want

    # ---------------------------------------------------------- the hand
    def steer(self, t, b, want, rng):
        goal = b['hgoal']
        if self.expect is not None:
            # waiting to see the taps land on the bow line
            if goal == self.expect or t >= self.wait_until:
                self.expect = None
                self.wait_until = t + self.settle
            return self.press if t < self.until else 0
        if t < self.until:
            return self.press
        if t < self.wait_until:
            return 0
        d = sdiff(want, goal)
        n = int(round(d / NOTCH))
        if n == 0:
            return 0
        n = self.route(b, goal, n)
        n = self.fumble(n, rng)
        if n == 0:
            return 0
        self.press = RIGHT if n > 0 else LEFT
        k = abs(n)
        # a tap for one notch, a hold for more (first repeat at 18, then every 9)
        dur = 10 if k == 1 else 18 + (k - 2) * 9 + 4
        dur += self.slop and rng.randint(0, self.slop)
        self.until = t + dur
        self.expect = (goal + n * NOTCH) & 0xF0
        self.wait_until = t + dur + 60
        return self.press

    def fumble(self, n, rng):
        return n

    long_way = True      # gybe round rather than tack through the wind, if it's not much further

    def route(self, b, goal, n):
        """turn the long way round rather than through the wind, if it's not much further"""
        if abs(n) < 5 or not self.long_way:
            return n
        def crosses(k):
            step = 1 if k > 0 else -1
            return any(abs(sdiff((goal + step * i * NOTCH) & 0xFF, b['wind'])) < NOGO
                       for i in range(1, abs(k)))
        alt = n - 16 if n > 0 else n + 16
        if crosses(n) and not crosses(alt) and abs(alt) <= abs(n) + 4:
            return alt
        return n

    def act(self, t, tel, rng):
        b = read_boat(self)
        if b['state'] != 0:
            return 0
        want = self.avoid(b, self.desired(b))
        m = self.steer(t, b, want, rng)
        # a thumb still down on the pad long after we meant to let go: lift it
        held = (LEFT if b['pad'] & 0x0200 else 0) | (RIGHT if b['pad'] & 0x0100 else 0)
        if held and not (m & held):
            self.stale += 1
        else:
            self.stale = 0
        if self.stale > 45:
            self.kick ^= 1
        if self.hike and b['gust'] and self.hikes(rng):
            m |= A
        if self.kick and not m:
            m = A
        return m

    def hikes(self, rng):
        return True


class sail_expert(_Sailor):
    """Rounds 10 px off each buoy, steers round geese and kayaks on screen,
    and rides the ferry's wake to the line when she's coming its way."""
    offset = 10

    def target(self, b):
        st = self.surf_target(b)
        return st if st else super().target(b)

    def surf_target(self, b):
        """last leg: dip into the westbound ferry's wake if she'll be there"""
        if b['mark'] != 3 or b['surf'] >= 2 or b['surfok']:
            return None
        if b['rmark'] < 3 and b['rmin'] > self.offset + 3:
            return None                             # finish the rounding first
        fx = b['fx']
        if not on_screen(b, fx, FERRY_Y, 48) or b['ferryd'] > 0 or b['fwait']:
            return None
        if b['x'] < LINE[0] + 40:
            return None
        astern = b['x'] - fx                        # westbound: + = behind her
        dy = FERRY_Y - b['y']
        if abs(dy) < 12:
            # in the lane: ride her wake west, peel off before her stern
            return (b['x'] - 60, FERRY_Y) if astern >= 32 else None
        if dy < 0:
            return None
        # drop into the lane so the wake slot (40-70 astern) arrives as we do
        t_down = dy / 0.8
        if astern + t_down > 75 or astern + t_down < 20:
            return None
        return (b['x'] - 16, FERRY_Y)

    def obstacles(self, b):
        obs = []
        for (x, y) in b['floats']:
            if on_screen(b, x, y):
                obs.append((x, y, 16, 14, 0))
        fx = b['fx']
        astern = (b['x'] - fx) * (-b['ferryd'])
        if self.surf_target(b) and not b['fwait'] and astern > 32:
            return obs                              # dropping into her wake on purpose
        if on_screen(b, fx, FERRY_Y, 32):
            obs.append((fx, FERRY_Y, 32, 16, 0 if b['fwait'] else b['ferryd']))
        return obs

    def avoid(self, b, want):
        sp = max(b['speed'], 0x80) / 256.0
        surfing = b['mark'] == 3 and abs(b['y'] - FERRY_Y) < 14
        for la in (want, b['head']):
            a = la * math.pi / 128
            hit = None
            for k in range(6, 45, 3):
                px = b['x'] + math.sin(a) * sp * k
                py = b['y'] - math.cos(a) * sp * k
                for (ox, oy, rx, ry, vx) in self.obstacles(b):
                    ox += vx * k
                    if surfing and vx and ry == 16:
                        rx = 28
                    if abs(px - ox) < rx and abs(py - oy) < ry:
                        hit = (ox, oy)
                        break
                if hit:
                    break
            if hit:
                ob = bearing(hit[0] - b['x'], hit[1] - b['y'])
                side = sdiff(ob, la)
                for step in (2, 3):
                    cand = (la - step * NOTCH if side > 0 else la + step * NOTCH) & 0xFF
                    if abs(sdiff(cand, b['wind'])) >= NOGO + 4:
                        return notch_of(cand)
                cand = (la + 2 * NOTCH if side > 0 else la - 2 * NOTCH) & 0xFF
                return notch_of(cand)
        return want


class sail_casual(_Sailor):
    """A decent club sailor: late taps, holds a little long, sails wide."""
    hysteresis = 22
    beat_margin = 10
    settle = 14
    slop = 6
    long_way = False     # tacks through the wind like a sailor

    def fumble(self, n, rng):
        if rng.random() < 0.12:
            return n + rng.choice((-1, 1))
        return n

    def hikes(self, rng):
        return rng.random() < 0.7


class sail_human(_Sailor):
    """A first-timer who sails from the screen: points the bow line at the
    yellow arrow (16 directions as drawn). On the beat the arrow shows the
    tack and swings across at TACK NOW; the human sees it a beat late (the
    curve's latency) and sometimes ignores the first swing. Taps are sloppy
    (holds run long and turn a notch too far now and then), settles slowly,
    hikes in most gusts."""
    settle = 20
    slop = 10
    long_way = False     # TACK NOW! STEER LEFT: steers left

    def desired(self, b):
        return b['adir']

    def fumble(self, n, rng):
        r = rng.random()
        if r < 0.15:
            return n + (1 if n > 0 else -1)          # one too many
        if r < 0.20:
            return 0                                 # hesitates
        return n

    def hikes(self, rng):
        return rng.random() < 0.6


class sail_pointer(_Sailor):
    """Follows the yellow arrow and nothing else, never hikes: the panel's honest run."""
    hike = False
    settle = 12
    long_way = False

    def desired(self, b):
        return b['adir']


POLICIES = {c.__name__: c for c in (sail_expert, sail_casual, sail_human, sail_pointer)}
DEFAULTS = {'sail': ['idle', 'hold_a', 'hold_right', 'mash_a', 'random_input', 'sail_random', 'sail_tack',
                     'sail_pointer', 'sail_human', 'sail_casual', 'sail_expert']}
CURVE = {'sail': 'sail_expert'}
