"""Harbour Regatta bots.

Steering is in notches (16 directions, one per boat frame): a tap turns the
goal one notch, a hold keeps turning a notch every few frames. The bots steer
the way a person does with that: they pick the notch they want from what's on
screen (the boat, the bow diamonds, the yellow arrow, the coach line, the
marks and anything in the water within the camera view), tap or hold for
about as many notches as it takes, then watch the bow line until it settles
before deciding again. They never react to anything off screen.

What's on screen: the yellow arrow marks the next mark (a pin over it, or at
the screen edge pointing at it); the bow diamonds turn green on the course to
steer (s_adir: straight at the mark, or close-hauled on the right tack); the
coach line says "TO MARK 2: TAP < 2 TIMES", "TACK NOW! TAP > 4 TIMES", "IN
IRONS! TAP < ONCE", "ADRIFT SOON! ...".

    sail_expert   tacks on the right notch with quick taps (CLEAN TACK), rounds each mark at its own chosen
                  distance (graded TIGHT ROUNDING), steers round geese and
                  kayaks it can see, rides the ferry's wake on the last leg
                  when she's there. Each run picks its own line (rounding
                  distance, layline margin), as a real expert's would vary.
    sail_casual   a decent club sailor: rounds wide, tacks late, fumbles a bit
    sail_human    a first-timer who keeps the diamonds green (sloppy taps,
                  forgets to hike)
    sail_pointer  a first-timer who steers at the yellow arrow (never into the
                  red no-go ticks) and does what the coach line says
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
O_ADIR = 320         # the course to steer (green diamonds)
O_POPUP, O_GREEN, O_COACHN, O_BUF = 32, 352, 358, 400
NOGO = 28
NOTCH = 16
TOUCH = 6.5          # a pass closer than this touches the buoy (rough distance < 6)


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


def _solid():
    here = os.path.dirname(os.path.abspath(__file__))
    return open(os.path.join(here, '..', '..', 'build', 'sail_solid.bin'), 'rb').read()


SOLID = _solid()


def land(x, y):
    """the shore you can see (the game's 8 px land map)"""
    x, y = int(x), int(y)
    if not (0 <= x < 512 and 0 <= y < 512):
        return True
    tx, ty = x >> 3, y >> 3
    return bool(SOLID[ty * 8 + (tx >> 3)] & (0x80 >> (tx & 7)))


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
            'popup': w(O_POPUP), 'green': m[O_GREEN], 'coachn': m[O_COACHN] - 256 if m[O_COACHN] & 0x80 else m[O_COACHN],
            'floats': [(w(64 + 2 * i), w(74 + 2 * i)) for i in range(5)]}


def coach_text(pol):
    """the built message (coach / tack / irons lines) as on screen"""
    g = _game(pol)
    return bytes(g.core.peek(g.sym['ev_ram'] + O_BUF, 32)).split(b'\0')[0].decode('latin1')


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
    tap_period = 0       # turn 2+ notches with taps this far apart (0: hold the pad)

    def __init__(self):
        self.tack = 0
        self.press = 0           # current steer mask
        self.until = 0           # press runs until this frame
        self.expect = None       # hgoal we're waiting to see
        self.wait_until = 0
        self.stale = 0
        self.kick = 0
        self.rmark_done = -1
        self.taps = 0            # taps in this turn (0: a hold)
        self.t0 = 0

    def pressing(self, t):
        if not self.taps:
            return self.press
        i, ph = divmod(t - self.t0, self.tap_period)
        return self.press if i < self.taps and ph < 3 else 0

    # ---------------------------------------------------------- where to go
    def target(self, b):
        k = b['mark']
        if self.offset and b['rmark'] < 3 and b['rmin'] > self.offset + 2 and self.rmark_done != b['rmark']:
            k = b['rmark']                          # finish the rounding close in
        elif self.offset and b['rmark'] < 3:
            self.rmark_done = b['rmark']
        if k >= 3:
            return LINE
        mx, my = MARKS[k]
        if not self.offset:
            return (mx, my)
        # pass the buoy `offset` px off, square to our line of approach, on the
        # side the next leg goes (never straight at it: that's a touch)
        dx, dy = b['x'] - mx, b['y'] - my
        d = math.hypot(dx, dy) or 1
        if d < self.offset:
            return (mx + dx / d * (self.offset + 8), my + dy / d * (self.offset + 8))
        nx, ny = MARKS[k + 1] if k < 2 else LINE
        px, py = -dy / d, dx / d
        if px * (nx - mx) + py * (ny - my) < 0:
            px, py = -px, -py
        return (mx + px * self.offset, my + py * self.offset)

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
            return self.pressing(t) if t < self.until else 0
        if t < self.until:
            return self.pressing(t)
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
        self.t0 = t
        if self.tap_period and k >= 2:
            # k quick taps (what the coach line asks for)
            self.taps = k
            dur = k * self.tap_period
        else:
            # a tap for one notch, a hold for more (first repeat at 18, then every 8)
            self.taps = 0
            dur = 10 if k == 1 else 18 + (k - 2) * 8 + 4
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
    """Rounds 8-13 px off each buoy (its own choice each run), steers round
    geese and kayaks on screen, and rides the ferry's wake to the line when
    she's there."""
    offset = 10
    tap_period = 6
    long_way = False     # tacks through the wind (quick taps), never loops round

    def act(self, t, tel, rng):
        if t == 0:                                  # today's line
            self.offset = rng.choice((7, 7, 7.5, 8, 8, 8.5))
            self.hysteresis = rng.choice((8, 10, 12, 14, 16))
        return super().act(t, tel, rng)

    def target(self, b):
        st = self.surf_target(b)
        return st if st else super().target(b)

    def desired(self, b):
        """near a mark, pick the notch whose straight line passes the buoy
        closest to `offset` px without touching it (TIGHT ROUNDING is graded
        by the closest pass): the turn onto it has to come at the right moment"""
        k = None
        if b['rmark'] < 3 and self.rmark_done != b['rmark']:
            k = b['rmark']
        elif b['mark'] < 3:
            mx, my = MARKS[b['mark']]
            if math.hypot(mx - b['x'], my - b['y']) < 110:
                k = b['mark']
        if k is not None:
            n = self.round_notch(b, k)
            if n is not None:
                return n
            if k == b['rmark']:
                self.rmark_done = k                 # past it: on to the next leg
        return super().desired(b)

    def round_notch(self, b, k):
        """the approach is set up from 40-110 px out; inside 40 the bow is
        committed (it can't turn in time anyway) unless it would hit"""
        mx, my = MARKS[k]
        rx, ry = mx - b['x'], my - b['y']
        dist = math.hypot(rx, ry)

        def pass_of(n):
            a = n * math.pi / 128
            ux, uy = math.sin(a), -math.cos(a)
            return rx * ux + ry * uy, abs(rx * uy - ry * ux)
        if dist < 40:
            along, cross = pass_of(b['hgoal'])
            if along <= 2:
                return None                         # past it
            if cross >= TOUCH:
                return b['hgoal']
            c = b['hgoal']
            opts = [((c + dn * NOTCH) & 0xFF) for dn in (1, -1)]
            opts = [n for n in opts if abs(sdiff(n, b['wind'])) >= NOGO + 4] or opts
            return max(opts, key=lambda n: pass_of(n)[1])
        c = notch_of(bearing(rx, ry))
        best = None
        for dn in (0, -1, 1, -2, 2):
            n = (c + dn * NOTCH) & 0xFF
            if abs(sdiff(n, b['wind'])) < NOGO + 4:
                continue
            along, cross = pass_of(n)
            if along <= 2:
                continue
            cost = abs(cross - self.offset) + (60 if cross < self.offset - 0.5 else 0) + abs(dn) * 0.5
            if best is None or cost < best[0]:
                best = (cost, n)
        if best is None or best[0] > 40:
            return None
        return best[1]

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
            return (b['x'] - 60, FERRY_Y) if astern >= 34 and b['x'] > LINE[0] + 60 else None
        if dy < 0:
            return None
        # drop into the lane if her wake (28-192 astern) will still be there
        t_down = dy / 0.8
        if astern + t_down > 180 or astern + t_down < 36:
            return None
        return (b['x'] - 16, FERRY_Y)

    def obstacles(self, b):
        obs = []
        for (x, y) in b['floats']:
            if on_screen(b, x, y):
                obs.append((x, y, 16, 14, 0))
        fx = b['fx']
        astern = (b['x'] - fx) * (-b['ferryd'])
        if self.surf_target(b) and not b['fwait'] and astern > 44:
            return obs                              # dropping into her wake on purpose
        if on_screen(b, fx, FERRY_Y, 32):
            obs.append((fx, FERRY_Y, 32, 16, 0 if b['fwait'] else b['ferryd']))
        return obs

    def avoid(self, b, want):
        want = self.shore(b, want)
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


    def shore(self, b, want):
        """don't sail into the shore you can see: the nearest notch that's
        clear for the next ~40 px and still drives"""
        def clear(n):
            a = n * math.pi / 128
            return not any(land(b['x'] + math.sin(a) * d, b['y'] - math.cos(a) * d) for d in (14, 24, 34, 44))
        if clear(want):
            return want
        for k in (1, -1, 2, -2, 3, -3, 4, -4):
            n = (want + k * NOTCH) & 0xF0
            if clear(n) and abs(sdiff(n, b['wind'])) >= NOGO + 4:
                return n
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
    """A first-timer reading the screen, never hikes: steers at the yellow
    arrow (but not into the red no-go ticks: as close to it as she'll sail),
    and when a coach line says TAP < N TIMES she taps N
    times that way. Green diamonds: leave the helm alone."""
    hike = False
    settle = 12
    long_way = False
    tap_period = 10      # does as the coach line says: TAP < 4 TIMES

    def __init__(self):
        super().__init__()
        self.last_popup = 0
        self.order = None                           # notch the coach asked for

    def desired(self, b):
        pop = b['popup']
        if pop > self.last_popup + 1 and 'TAP' in coach_text(self) and b['coachn']:
            self.order = (b['hgoal'] + b['coachn'] * NOTCH) & 0xF0
        self.last_popup = pop
        if b['green']:
            self.order = None
            return b['hgoal']
        if self.order is not None:
            if b['hgoal'] == self.order:
                self.order = None
            else:
                return self.order
        tx, ty = (MARKS[b['mark']] if b['mark'] < 3 else LINE)
        brg = bearing(tx - b['x'], ty - b['y'])
        return self.free_notch(brg, b['wind'])      # as near the arrow as the red ticks allow


import policies as _base


class sail_tack(_base.sail_tack):
    """No skill (blind timed tacks, never looks at the course): an exploit
    detector. Going nowhere for ten seconds ends its race (ADRIFT), early."""
    trivial = True


class sail_random(_base.sail_random):
    """No skill (random LEFT/RIGHT/A every half second): an exploit detector.
    It must score more than sitting still, never more than sailing."""
    trivial = True


class sail_flail(Policy):
    """pt9's flailer: random LEFT or RIGHT taps every 20-60 frames, no plan."""
    trivial = True

    def __init__(self):
        self.next = 0
        self.m = 0

    def act(self, t, tel, rng):
        if t >= self.next:
            self.m = rng.choice((LEFT, RIGHT))
            self.next = t + rng.randint(20, 60)
            self.until = t + rng.randint(3, 12)
        return self.m if t < self.until else 0


POLICIES = {c.__name__: c for c in (sail_expert, sail_casual, sail_human, sail_pointer,
                                    sail_tack, sail_random, sail_flail)}
DEFAULTS = {'sail': ['idle', 'hold_a', 'hold_right', 'mash_a', 'random_input', 'sail_random', 'sail_tack', 'sail_flail',
                     'sail_pointer', 'sail_human', 'sail_casual', 'sail_expert']}
CURVE = {'sail': 'sail_expert'}
