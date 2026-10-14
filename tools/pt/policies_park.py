"""Off-Leash Alert bots.

Skilled bots peek event RAM (dog states and positions, see the `=` offsets
at the top of src/ev_park.s) through the Game that run_bot is driving; they
find it on the caller's frame, so pt.py needs no hook. No-skill bots are
exploit detectors: holding UP, mashing B while walking, random input.
"""
import sys

from policies import Policy, idle, hold_up, random_input, A, B, X, UP, DOWN, LEFT, RIGHT

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


K_CAM = 34


def _hand_latency():
    """the latency pt.py's run_bot is applying to this bot (0 outside a curve run)"""
    f = sys._getframe(2)
    while f is not None:
        if 'pending' in f.f_locals and 'latency' in f.f_locals:
            return f.f_locals['latency'] or 0
        f = f.f_back
    return 0


class park_hand(_Peeker):
    """The CURVE bot: a practised player with a human hand.

    It only reacts to what's on screen: a dog is a threat from the frame its
    "!" shows (over the dog, or pinned to the bottom edge). From then on it
    judges the charge by eye, the way you time a ball coming at you: it
    watches the gap close and presses B early enough that its own (known,
    practised) reaction delay lands the step where it aims. It aims as late
    as its consistency allows: a steady hand (small jitter) goes for the
    CLOSE SHAVE, a shaky one aims safely inside the DODGE range, and if even
    that's a gamble it gets set on the "!" instead (the beginner's dodge).
    A press that lands early still arms the step, so erring early is safe.
    Between dogs it walks north and goes back for a pat when the dog it
    dodged sits within easy reach."""

    def __init__(self):
        super().__init__()
        self.lat = None
        self.seen = {}           # dog slot -> plan
        self.hold_b = 0
        self.gap = {}            # dog slot -> last gaps (closing speed by eye)

    def act(self, t, tel, rng):
        if self.lat is None:
            self.lat = _hand_latency()
        me, dogs = self.view()
        cam = self.g.core.peek(self.g.sym['ev_ram'] + K_CAM, 2)
        cam = cam[0] | cam[1] << 8
        L = self.lat
        J = L // 4
        m = UP
        live = set()
        for d in dogs:
            if d['st'] not in (DS_ALERT, DS_CHARGE):
                continue
            live.add(d['i'])
            dist = abs(d['x'] - me['x']) + abs(d['y'] - me['y'])
            hist = self.gap.setdefault(d['i'], [])
            hist.append(dist)
            del hist[:-4]
            if d['i'] not in self.seen:
                self.seen[d['i']] = 'watch'
            plan = self.seen[d['i']]
            if plan == 'done':
                continue
            # closing speed, by eye, over the last few frames (never under a walk)
            v = max(2.6, (hist[0] - hist[-1]) / max(1, len(hist) - 1))
            aim = 12 + 1.5 * J * v
            behind = d['y'] - cam > 192           # coming from off the bottom: no read on it
            if aim > 34 or behind:
                if not me['armed']:
                    self.hold_b = 8               # get set on the "!"
                self.seen[d['i']] = 'done'
                continue
            if d['st'] == DS_ALERT:
                if d['y'] < me['y'] and dist < 64:
                    m &= ~UP                      # he's right ahead, barking: wait for him
                if dist - v * (L + J) <= aim:     # too close to time it: get set now
                    self.hold_b = 8
                    self.seen[d['i']] = 'done'
            elif dist - v * L <= aim:
                self.hold_b = 8
                self.seen[d['i']] = 'done'
        for i in list(self.seen):
            if i not in live:
                del self.seen[i]
                self.gap.pop(i, None)
        if self.hold_b:
            self.hold_b -= 1
            m |= B
        elif not live and not me['dash']:
            sit = _sitter(me, dogs, 70)
            if sit is not None:
                m = _toward(me, sit)
            if me['x'] < 100:
                m |= RIGHT
            elif me['x'] > 156:
                m |= LEFT
        # X does nothing in the park. Flipping it now and then re-sends the
        # held mask: pt.py's jittered hand can land an old decision after a
        # newer one, which would otherwise stick (a human lets go of DOWN)
        if (t >> 4) & 1:
            m |= X
        return self.done(m)


POLICIES = {c.__name__: c for c in [park_ace, park_fetcher, park_sloppy, park_timing, park_human, park_hand,
                                     up_mash_b, up_mash_ab]}
DEFAULTS = {'park': ['idle', 'hold_up', 'up_mash_b', 'up_mash_ab', 'random_input',
                     'park_timing', 'park_sloppy', 'park_human', 'park_fetcher', 'park_hand', 'park_ace']}
CURVE = {'park': 'park_hand'}

