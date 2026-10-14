"""TTC Surfing bots.

The no-skill ones (idle, hold_right, mash_a, random_input) are exploit
detectors: they must collect germs on every leg and go PATIENT ZERO.

subway_expert reads the true train force and the dot's velocity from RAM
and leans against both with a short prediction: frame-perfect balance, the
ceiling (0 germs, the full STANDING SURF chain, lots of DEAD CENTRE).

subway_ace is the expert plus the trick the card never mentions, NO HANDS
(glide into a stop off the D-pad with the dot still gold: +100 a stop). Its
tell: NH_CUE frames before a stop on a clean leg the brake eases, the arrow
goes, the status says GLIDING IN..., a ding, and the ring pulses gold for the
frames in which letting go still counts. It is the ceiling the default
records are judged against.

subway_cue is subway_surfer plus that tell and nothing else: on GLIDING IN...
it lets go. At 10-12 frames it must land the trick on most stops it is
offered (`pt.py curve subway -p subway_cue -l 10,12`).

subway_surfer is the human yardstick (the CURVE bot): it plans only from
what's on screen. It sees the dot (and judges its drift from the last few
frames of motion, not from RAM velocity) and the lurch cue: a HOLLOW arrow
that blinks through the 40-frame warning (get ready) and turns into a SOLID
double arrow when the push starts (lean now), with the status line naming
the lean. Like the card tells it, it waits for the solid arrow (lead 0) and
otherwise steers the dot back toward the middle with a dead zone, the way a
person nudges. `pt.py curve subway` delays all of that by a human reaction.
The top end comes from GOLD SURF (the dot never left the gold middle all leg,
bar slips of up to 8 frames inside 9 px, while the dot flickers gold: the
stop's STANDING SURF pays x3), which needs quick, small hands.

subway_human is subway_surfer with a built-in 15-frame (250 ms) hand, so a
plain `balance` run shows where an average player lands.

subway_newbie is the round-5 first-timer (Dana): 20-frame hands, presses the
arrow's way as soon as the HOLLOW arrow shows and holds it, only pulls back
once the dot is red. On the round-5 build it went PATIENT ZERO for 120 every
time, as Dana did; it should reach Union.

subway_obey (and obey20 / obey25 / dana) is the round-7 prompt test: it
never looks at the dot, only at the arrow and the status line, and does what
they say ("CURVE! HOLD ^": hold that way while the arrow is solid) 20-25
frames late. On the round-7 build a held lean drove the dot out the far side
of the ring (PATIENT ZERO at 10 and 22 frames alike); a held lean now settles
the dot in the white, so all four reach Union.

subway_ace plays the title demo (request: demo_export POLICY['subway']):
it shows the undocumented trick twice in the demo's 24 s.

Every ride differs past TMU (the course is drawn from rng on the ride's first
frame, and run_bot seeds rng), and three of the last four legs carry a gag
(kinds 4 SIGNAL PROBLEMS and 5 BACKPACK) that the bots read like any lurch.
"""
import inspect

from policies import Policy, LEFT, RIGHT, UP, DOWN

# ev_ram layout (src/ev_subway.s)
W_BX, W_BY, W_VX, W_VY, W_FX, W_FY = 0, 2, 4, 6, 8, 10
W_SEG, W_SPEED, W_LS, W_LT, W_GERMS, W_GRAB, W_KIND = 16, 18, 24, 26, 28, 30, 34
W_STATUS = 42                 # the HUD's status line (what it reads, as an index)
ST_GLIDE = 16                 # "GLIDING IN...": the brake eased, the ring pulses gold
LS_GAP, LS_WARN, LS_ACT, LS_END = range(4)
# lurch kind -> (axis, push sign): the arrow points the other way
PUSH = {0: (0, -1), 1: (1, +1), 2: (1, -1), 3: (0, +1), 4: (0, +1), 5: (0, -1)}


def s16(v):
    return v - 0x10000 if v & 0x8000 else v


def find_game():
    f = inspect.currentframe()
    while f:
        g = f.f_locals.get('g')
        if g is not None and hasattr(g, 'core') and hasattr(g, 'sym'):
            return g
        f = f.f_back
    raise RuntimeError('no Game in the call stack')


class _Reader(Policy):
    every = 1

    def read(self):
        if getattr(self, 'g', None) is None:
            self.g = getattr(self, 'game', None) or find_game()
            self.ev = self.g.sym['ev_ram']
        r = self.g.core.peek(self.ev, 44)
        w = lambda o: r[o] | r[o + 1] << 8
        return {'x': (s16(w(W_BX)) / 256, s16(w(W_BY)) / 256),
                'v': (s16(w(W_VX)) / 256, s16(w(W_VY)) / 256),
                'f': (s16(w(W_FX)), s16(w(W_FY))),
                'ls': r[W_LS], 'lt': w(W_LT), 'kind': r[W_KIND], 'grab': w(W_GRAB),
                'speed': w(W_SPEED), 'seg': r[W_SEG], 'status': r[W_STATUS]}


def steer(pos, vel, push, look, dz):
    """Per axis: lean the dot back toward the middle (with a prediction and a
    dead zone), and against the push when there's nothing to correct."""
    m = 0
    for a, (neg, pos_b) in enumerate(((LEFT, RIGHT), (UP, DOWN))):
        pred = pos[a] + vel[a] * look
        if pred > dz:
            m |= neg
        elif pred < -dz:
            m |= pos_b
        elif push[a] > 0:
            m |= neg
        elif push[a] < 0:
            m |= pos_b
    return m


class subway_expert(_Reader):
    """Frame-perfect: true force and velocity from RAM."""

    def act(self, t, tel, rng):
        s = self.read()
        if s['grab']:
            return 0
        push = [1 if f > 0 else -1 if f < 0 else 0 for f in s['f']]
        if s['ls'] == LS_WARN and s['lt'] <= 3:
            ax, sg = PUSH[s['kind']]
            push[ax] = sg
        return steer(s['x'], s['v'], push, 8, 1.0)


class subway_ace(subway_expert):
    """subway_expert plus the trick the card never mentions (NO HANDS): when
    the brake eases into a stop (GLIDING IN..., the ring pulses gold) it lets
    go of the pad at once and glides in. Frame-perfect like the expert: the
    ceiling, and the title demo's player."""

    def act(self, t, tel, rng):
        m = super().act(t, tel, rng)
        if self.read()['status'] == ST_GLIDE:
            return 0
        return m


class subway_surfer(_Reader):
    """Human-like: the dot's position, its drift judged from motion, and the
    on-screen cue. lead = how many frames before the push the cue makes it
    lean (0: on the solid arrow, as the card says)."""
    look = 10
    dz = 2.5
    lead = 0

    def act(self, t, tel, rng):
        s = self.read()
        hist = getattr(self, 'hist', None)
        if hist is None:
            hist = self.hist = []
        hist.append(s['x'])
        del hist[:-5]
        if s['grab']:
            return 0
        x = s['x']
        x0 = hist[0]
        n = max(1, len(hist) - 1)
        v = ((x[0] - x0[0]) / n, (x[1] - x0[1]) / n)
        push = [0, 0]
        if ((s['ls'] == LS_WARN and s['lt'] <= self.lead) or s['ls'] == LS_ACT) and s['status'] != ST_GLIDE:
            ax, sg = PUSH[s['kind']]                # (the arrow goes once the brake eases)
            push[ax] = sg
        return steer(x, v, push, self.look, self.dz)


class subway_cue(subway_surfer):
    """subway_surfer that has learned the tell for the undocumented trick
    and nothing else about it: when the status line says GLIDING IN... (the
    arrow goes, a ding, the ring pulses gold) it lets go of the pad until
    the stop. It never reads the trick's own state (the eased push, the
    frames off the pad, the window). `pt.py curve subway -p subway_cue -l
    10,12` must land the trick on most stops it is offered."""

    def act(self, t, tel, rng):
        m = super().act(t, tel, rng)
        if self.read()['status'] == ST_GLIDE:
            return 0
        return m


class subway_human(subway_surfer):
    """subway_surfer with its own 250 ms (15 frame) hand, for `balance`."""
    delay = 15

    def act(self, t, tel, rng):
        q = getattr(self, 'q', None)
        if q is None:
            q = self.q = []
        q.append(super().act(t, tel, rng))
        return q.pop(0) if len(q) > self.delay else 0


class subway_newbie(_Reader):
    """A first-timer who read the card once (Dana): ~20-frame hands. Presses
    the arrow's way as soon as ANY arrow shows (hollow too), keeps pressing
    while the arrow is up unless the dot has run 10 px that way, and only
    pulls back once the dot turns red. Never chases the gold."""
    delay = 20

    def act(self, t, tel, rng):
        q = getattr(self, 'q', None)
        if q is None:
            q = self.q = []
        q.append(self.decide())
        return q.pop(0) if len(q) > self.delay else 0

    def decide(self):
        s = self.read()
        if s['grab']:
            return 0
        x = s['x']
        m = 0
        if (x[0] ** 2 + x[1] ** 2) ** 0.5 >= 16:          # red: pull back
            m |= LEFT if x[0] > 4 else RIGHT if x[0] < -4 else 0
            m |= UP if x[1] > 4 else DOWN if x[1] < -4 else 0
            return m
        if s['ls'] in (LS_WARN, LS_ACT) and s['status'] != ST_GLIDE:     # (no arrow once it eases)
            ax, sg = PUSH[s['kind']]
            # the arrow points against the push
            if -sg * x[ax] < 10:
                m |= ((RIGHT if sg < 0 else LEFT) if ax == 0 else (DOWN if sg < 0 else UP))
        return m


class subway_obey(_Reader):
    """Does exactly what the words say and nothing else (the round-7 Dana
    test): it never looks at the dot. When the arrow goes SOLID and the
    status says "CURVE! HOLD ^", it holds that way until the arrow goes, all
    `delay` frames late. `hollow` also leans on the blinking HOLLOW arrow (as
    Dana did: "lean on any arrow"), and `linger` keeps holding that many
    frames after the arrow has gone. On the round-7 build this went PATIENT
    ZERO at 10 and 22 frames alike (holding drove the dot out the far side);
    a held lean must settle the dot in the white and reach Union."""
    delay = 22
    hollow = False
    linger = 0

    def act(self, t, tel, rng):
        q = getattr(self, 'q', None)
        if q is None:
            q = self.q = []
            self.last, self.gone = 0, 0
        q.append(self.decide())
        return q.pop(0) if len(q) > self.delay else 0

    def decide(self):
        s = self.read()
        arrow = s['status'] != ST_GLIDE         # the arrow goes once the brake eases
        if arrow and (s['ls'] == LS_ACT or (self.hollow and s['ls'] == LS_WARN)):
            ax, sg = PUSH[s['kind']]
            self.last = (RIGHT if sg < 0 else LEFT) if ax == 0 else (DOWN if sg < 0 else UP)
            self.gone = 0
            return self.last
        self.gone += 1
        return self.last if self.gone <= self.linger else 0


class subway_obey20(subway_obey):
    delay = 20


class subway_obey25(subway_obey):
    delay = 25


class subway_dana(subway_obey):
    """Dana's own round-7 script: leans on any arrow, hollow or solid, 22
    frames late, and lets go 10 frames after it's gone."""
    hollow = True
    linger = 10


POLICIES = {c.__name__: c for c in (subway_expert, subway_ace, subway_surfer, subway_cue, subway_human, subway_newbie,
                                    subway_obey, subway_obey20, subway_obey25, subway_dana)}
DEFAULTS = {'subway': ['idle', 'hold_right', 'mash_a', 'random_input', 'subway_newbie', 'subway_dana', 'subway_obey', 'subway_human',
                       'subway_expert', 'subway_ace']}
CURVE = {'subway': 'subway_surfer'}
