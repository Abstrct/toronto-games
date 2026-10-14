"""Off-Leash Alert bots.

Skilled bots peek event RAM (dog states and positions, see the `=` offsets
at the top of src/ev_park.s) through the Game that run_bot is driving; they
find it on the caller's frame, so pt.py needs no hook. No-skill bots are
exploit detectors: holding UP, mashing B while walking, random input.
"""
import sys

from policies import Policy, idle, hold_up, random_input, A, B, UP, DOWN, LEFT, RIGHT

# ev_ram offsets (src/ev_park.s)
K_X, K_Y, K_DASH, K_DASHCD, K_BALLS, B_STATE = 0, 2, 16, 18, 26, 48
K_STATE, K_STUM = 10, 288
K_LIVE, K_CALM, K_ARMED, K_CHAIN = 540, 542, 544, 548
D_SLOT, D_X, D_Y, D_STATE = 80, 96, 112, 176
DS_ALERT, DS_CHARGE, DS_SIT = 1, 2, 7
NUM_ENT = 8


def _game():
    f = sys._getframe(2)
    while f is not None:
        g = f.f_locals.get('g')
        if g is not None and hasattr(g, 'core') and hasattr(g, 'sym'):
            return g
        f = f.f_back
    return None


class _Peeker(Policy):
    """Reads the walker and the dogs every frame."""

    def __init__(self):
        self.g = None
        self.prev = 0

    def view(self):
        if self.g is None:
            self.g = getattr(self, "game", None) or _game()
        base = self.g.sym['ev_ram']
        r = self.g.core.peek(base, 600)
        w = lambda o: r[o] | r[o + 1] << 8
        me = {'x': r[K_X + 1], 'y': w(K_Y), 'dash': w(K_DASH), 'cd': w(K_DASHCD),
              'balls': r[K_BALLS], 'ball': r[B_STATE], 'state': r[K_STATE],
              'stum': w(K_STUM), 'live': r[K_LIVE], 'armed': r[K_ARMED], 'chain': r[K_CHAIN]}
        dogs = []
        for i in range(NUM_ENT):
            if r[D_SLOT + 2 * i] == 0xFF:
                continue
            dogs.append({'i': i, 'x': r[D_X + 2 * i + 1], 'y': w(D_Y + 2 * i), 'st': r[D_STATE + 2 * i]})
        return me, dogs

    def press(self, m, btn):
        """an edge: only if the button was up last frame"""
        return m | btn if not (self.prev & btn) else m

    def done(self, m):
        self.prev = m
        return m


def _toward(me, d, m=0):
    """steer toward a dog (a sitting one, for a pat)"""
    if d['x'] < me['x'] - 3:
        m |= LEFT
    elif d['x'] > me['x'] + 3:
        m |= RIGHT
    if d['y'] < me['y'] - 2:
        m |= UP
    elif d['y'] > me['y'] + 2:
        m |= DOWN
    return m


def _sitter(me, dogs, reach):
    best = None
    for d in dogs:
        if d['st'] != DS_SIT:
            continue
        dist = abs(d['x'] - me['x']) + abs(d['y'] - me['y'])
        if dist < reach and (best is None or dist < best[0]):
            best = (dist, d)
    return best[1] if best else None


class park_ace(_Peeker):
    """Walks up, sidesteps every charging dog at the very last moment (CLOSE SHAVE),
    a ball if the step is on cooldown, and pats every dog it dodged (DODGE 'N' PAT)."""
    dodge_at = 20

    def act(self, t, tel, rng):
        me, dogs = self.view()
        m = UP
        sit = _sitter(me, dogs, 90) if not me['live'] else None
        if sit is not None:
            return self.done(_toward(me, sit))
        threat = None
        for d in dogs:
            if d['st'] != DS_CHARGE:
                continue
            dist = abs(d['x'] - me['x']) + abs(d['y'] - me['y'])
            if threat is None or dist < threat:
                threat = dist
        if threat is not None and threat < self.dodge_at:
            if me['cd'] == 0:
                m = self.press(m, B)
            elif me['dash'] == 0 and me['balls'] and me['ball'] == 0 and threat < 24:
                m = self.press(m, A)
        # drift back toward the middle of the park between dogs
        if threat is None and not me['dash']:
            if me['x'] < 100 and t % 3 == 0:
                m |= RIGHT
            elif me['x'] > 156 and t % 3 == 0:
                m |= LEFT
        return self.done(m)


class park_fetcher(_Peeker):
    """Throws a ball at every dog that spots it; dodges when out of balls."""

    def act(self, t, tel, rng):
        me, dogs = self.view()
        m = UP
        near = None
        for d in dogs:
            if d['st'] not in (DS_ALERT, DS_CHARGE):
                continue
            dist = abs(d['x'] - me['x']) + abs(d['y'] - me['y'])
            if near is None or dist < near[0]:
                near = (dist, d['st'])
        if near:
            if me['balls'] and me['ball'] == 0:
                m = self.press(m, A)
            elif near[1] == DS_CHARGE and near[0] < 34 and me['cd'] == 0:
                m = self.press(m, B)
        return self.done(m)


class park_sloppy(_Peeker):
    """A decent human: presses B anywhere from 14 to 38 px out, and misses one charge in eight."""

    def __init__(self):
        super().__init__()
        self.aim = {}

    def act(self, t, tel, rng):
        me, dogs = self.view()
        m = UP
        live = set()
        for d in dogs:
            if d['st'] != DS_CHARGE:
                continue
            live.add(d['i'])
            if d['i'] not in self.aim:          # a new charge: how well will I read it?
                self.aim[d['i']] = None if rng.random() < 0.12 else 26 + rng.randint(-12, 12)
            aim = self.aim[d['i']]
            dist = abs(d['x'] - me['x']) + abs(d['y'] - me['y'])
            if aim is not None and dist < aim and me['cd'] == 0:
                m = self.press(m, B)
        for i in list(self.aim):
            if i not in live:
                del self.aim[i]
        return self.done(m)


class park_timing(Policy):
    """The old blind bot: walk up, sidestep on a fixed rhythm."""
    every = 2

    def act(self, t, tel, rng):
        m = UP
        ph = t % 50
        if ph < 4:
            m |= B | rng.choice([LEFT, RIGHT])
        if t % 90 == 0:
            m |= A
        return m


class up_mash_b(Policy):
    trivial = True
    """No skill: hold UP and hammer B."""

    def act(self, t, tel, rng):
        return UP | (B if t % 8 < 4 else 0)


class up_mash_ab(Policy):
    trivial = True
    """No skill: hold UP and hammer A and B."""

    def act(self, t, tel, rng):
        return UP | (B if t % 8 < 4 else A)


class park_human(_Peeker):
    """A decent first-timer: sees the screen ~15 frames late (12-20), reads the
    "!" and presses B once to get set (or, a third of the time, tries to time it
    by hand and is often early or late), forgets one dog in ten, throws a ball
    now and then, wanders a bit off the line, and goes for a pat half the time."""

    def __init__(self):
        super().__init__()
        self.hist = []
        self.plan = {}
        self.lag = None
        self.wander = 0
        self.patting = False

    def act(self, t, tel, rng):
        cur = self.view()
        self.hist.append(cur)
        if self.lag is None:
            self.lag = rng.randint(12, 20)
        me, dogs = self.hist[-self.lag] if len(self.hist) > self.lag else self.hist[0]
        now_me = cur[0]
        if len(self.hist) > 64:
            self.hist.pop(0)
        m = UP
        # a bit of aimless steering
        if t % 90 == 0:
            self.wander = rng.choice([0, 0, 0, LEFT, RIGHT])
        if t % 90 < 20:
            m |= self.wander
        if now_me['x'] < 70:
            m = (m & ~LEFT) | RIGHT
        elif now_me['x'] > 186:
            m = (m & ~RIGHT) | LEFT
        live = set()
        for d in dogs:
            if d['st'] not in (DS_ALERT, DS_CHARGE):
                continue
            live.add(d['i'])
            if d['i'] not in self.plan:
                r = rng.random()
                if r < 0.10:
                    self.plan[d['i']] = ('miss', 0)
                elif r < 0.62:
                    self.plan[d['i']] = ('arm', 0)
                elif r < 0.72 and me['balls']:
                    self.plan[d['i']] = ('ball', 0)
                else:
                    self.plan[d['i']] = ('time', 30 + rng.randint(-14, 14))
            kind, aim = self.plan[d['i']]
            dd, mm = d, me
            if kind == 'time':      # timing by eye anticipates: judged on the real gap
                dd = next((e for e in cur[1] if e['i'] == d['i']), d)
                mm = now_me
            dist = abs(dd['x'] - mm['x']) + abs(dd['y'] - mm['y'])
            if kind == 'arm':
                m = self.press(m, B)
                self.plan[d['i']] = ('done', 0)
            elif kind == 'ball' and now_me['ball'] == 0:
                m = self.press(m, A)
                self.plan[d['i']] = ('done', 0)
            elif kind == 'time' and d['st'] == DS_CHARGE and dist < aim:
                m = self.press(m, B)
                self.plan[d['i']] = ('done', 0)
        for i in list(self.plan):
            if i not in live:
                del self.plan[i]
        if not live:
            sit = _sitter(me, dogs, 60)
            if sit is not None and (self.patting or rng.random() < 0.02):
                self.patting = True
                return self.done(_toward(now_me, sit))
            self.patting = False
        return self.done(m)


POLICIES = {c.__name__: c for c in [park_ace, park_fetcher, park_sloppy, park_timing, park_human,
                                     up_mash_b, up_mash_ab]}
DEFAULTS = {'park': ['idle', 'hold_up', 'up_mash_b', 'up_mash_ab', 'random_input',
                     'park_timing', 'park_sloppy', 'park_human', 'park_fetcher', 'park_ace']}

