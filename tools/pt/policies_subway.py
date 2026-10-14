"""TTC Surfing bots.

The no-skill ones (idle, hold_right, mash_a, random_input) are exploit
detectors: they must collect germs on every leg and go PATIENT ZERO.

subway_expert reads the true train force and the dot's velocity from RAM
and leans against both with a short prediction: frame-perfect balance, the
ceiling (0 germs, the full STANDING SURF chain, lots of DEAD CENTRE).

subway_surfer is the human yardstick (the CURVE bot): it plans only from
what's on screen. It sees the dot (and judges its drift from the last few
frames of motion, not from RAM velocity) and the lurch cue: the yellow
arrow by the ring that blinks through the 40-frame warning (faster near
the end, with the beeps/squeal/hiss) and goes solid when the push starts.
It leans the way the arrow points once the cue is about to fire, and
otherwise steers the dot back toward the middle with a dead zone, the way a
person nudges. `pt.py curve subway` delays all of that by a human reaction.

subway_human is subway_surfer with a built-in 15-frame (250 ms) hand, so a
plain `balance` run shows where an average player lands.
"""
import inspect

from policies import Policy, LEFT, RIGHT, UP, DOWN

# ev_ram layout (src/ev_subway.s)
W_BX, W_BY, W_VX, W_VY, W_FX, W_FY = 0, 2, 4, 6, 8, 10
W_SEG, W_SPEED, W_LS, W_LT, W_GERMS, W_GRAB, W_KIND = 16, 18, 24, 26, 28, 30, 34
LS_GAP, LS_WARN, LS_ACT, LS_END = range(4)
# lurch kind -> (axis, push sign): the arrow points the other way
PUSH = {0: (0, -1), 1: (1, +1), 2: (1, -1), 3: (0, +1)}


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
        r = self.g.core.peek(self.ev, 40)
        w = lambda o: r[o] | r[o + 1] << 8
        return {'x': (s16(w(W_BX)) / 256, s16(w(W_BY)) / 256),
                'v': (s16(w(W_VX)) / 256, s16(w(W_VY)) / 256),
                'f': (s16(w(W_FX)), s16(w(W_FY))),
                'ls': r[W_LS], 'lt': w(W_LT), 'kind': r[W_KIND], 'grab': w(W_GRAB),
                'speed': w(W_SPEED), 'seg': r[W_SEG]}


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


class subway_surfer(_Reader):
    """Human-like: the dot's position, its drift judged from motion, and the
    on-screen cue. lead = how many frames before the push the cue makes it
    lean (the third beep / the solid arrow)."""
    look = 10
    dz = 2.5
    lead = 6

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
        if (s['ls'] == LS_WARN and s['lt'] <= self.lead) or s['ls'] == LS_ACT:
            ax, sg = PUSH[s['kind']]
            push[ax] = sg
        return steer(x, v, push, self.look, self.dz)


class subway_human(subway_surfer):
    """subway_surfer with its own 250 ms (15 frame) hand, for `balance`."""
    delay = 15

    def act(self, t, tel, rng):
        q = getattr(self, 'q', None)
        if q is None:
            q = self.q = []
        q.append(super().act(t, tel, rng))
        return q.pop(0) if len(q) > self.delay else 0


POLICIES = {c.__name__: c for c in (subway_expert, subway_surfer, subway_human)}
DEFAULTS = {'subway': ['idle', 'hold_right', 'mash_a', 'random_input', 'subway_human', 'subway_expert']}
CURVE = {'subway': 'subway_surfer'}
