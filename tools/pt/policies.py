"""Bot policies for `pt.py bot` / `pt.py balance`.

A policy decides the held buttons every `every` frames:
    act(t, telemetry, rng) -> joypad mask
`t` counts frames since the event took control; `telemetry` has frame, lag,
ev_score, ev_fail, cur_player, event_idx. `self.game` is the running Game, so
a policy can read event RAM with self.game.core.peek(addr, n). Trivial policies (idle, hold_*,
mash_*) are the exploit detectors: if one of them scores well, a player with
no skill will too.
"""
B, Y, SELECT, START, UP, DOWN, LEFT, RIGHT, A, X, L, R = (1 << i for i in range(12))


class Policy:
    every = 1

    def act(self, t, tel, rng):
        return 0


class idle(Policy):
    every = 60


class hold_a(Policy):
    def act(self, t, tel, rng):
        return A


class hold_b(Policy):
    def act(self, t, tel, rng):
        return B


class hold_up(Policy):
    def act(self, t, tel, rng):
        return UP


class hold_right(Policy):
    def act(self, t, tel, rng):
        return RIGHT


class mash_a(Policy):
    def act(self, t, tel, rng):
        return A if t % 6 < 3 else 0


class random_input(Policy):
    every = 8

    def act(self, t, tel, rng):
        m = 0
        for b in (A, B, UP, DOWN, LEFT, RIGHT):
            if rng.random() < 0.3:
                m |= b
        return m


# ---- bike: pedal, and weave around trouble
class bike_weave(Policy):
    every = 4

    def __init__(self):
        self.steer, self.until = 0, 0

    def act(self, t, tel, rng):
        if t >= self.until:
            self.steer = rng.choice([0, 0, 0, LEFT, RIGHT])
            self.until = t + rng.choice([8, 16, 24])
        return A | self.steer


# ---- bay: alternate strides; excuse-me and lane hops when blocked
class bay_stride(Policy):
    """Clean left/right alternation at a steady cadence (what the card asks for)."""
    def __init__(self, period=10):
        self.period = period

    def act(self, t, tel, rng):
        ph = t % (2 * self.period)
        if ph < 3:
            return LEFT
        if self.period <= ph < self.period + 3:
            return RIGHT
        return 0


class bay_mash(bay_stride):
    def __init__(self):
        super().__init__(period=3)


class bay_expert(bay_stride):
    """Stride, say excuse-me every second, hop lanes now and then."""
    def __init__(self):
        super().__init__(period=8)
        self.lane = 0

    def act(self, t, tel, rng):
        m = super().act(t, tel, rng)
        if t % 60 < 3:
            m |= A
        if t % 150 == 0:
            self.lane = rng.choice([UP, DOWN])
        if t % 150 < 20:
            m |= self.lane
        return m


# ---- park: cross the park, dodge with sidesteps
class park_dodge(Policy):
    every = 2

    def act(self, t, tel, rng):
        m = UP
        ph = t % 50
        if ph < 4:
            m |= B | rng.choice([LEFT, RIGHT])
        if t % 90 == 0:
            m |= A
        if (t // 120) % 3 == 1:
            m |= rng.choice([LEFT, RIGHT]) if ph % 20 < 6 else 0
        return m


# ---- cops (Tallboy): jump obstacles, sip in between
class cops_jump(Policy):
    def act(self, t, tel, rng):
        return A if t % 40 < 12 else 0


class cops_jump_sip(Policy):
    def act(self, t, tel, rng):
        ph = t % 60
        if ph < 12:
            return A
        if 20 <= ph < 45:
            return B
        return 0


# ---- sail: hold a heading, tack periodically, hike out
class sail_tack(Policy):
    every = 2

    def act(self, t, tel, rng):
        leg = (t // 150) % 2
        m = LEFT if leg else RIGHT
        if t % 150 >= 25:
            m = 0
        if t % 30 < 10:
            m |= A
        return m


class sail_random(Policy):
    every = 30

    def act(self, t, tel, rng):
        return rng.choice([0, 0, LEFT, RIGHT]) | (A if rng.random() < 0.3 else 0)


POLICIES = {c.__name__: c for c in [idle, hold_a, hold_b, hold_up, hold_right, mash_a, random_input,
                                     bike_weave, bay_stride, bay_mash, bay_expert, park_dodge,
                                     cops_jump, cops_jump_sip, sail_tack, sail_random]}

DEFAULTS = {
    'bike': ['idle', 'hold_a', 'mash_a', 'bike_weave', 'random_input'],
    'bay': ['idle', 'bay_stride', 'bay_mash', 'bay_expert', 'random_input'],
    'park': ['idle', 'hold_up', 'park_dodge', 'random_input'],
    'cops': ['idle', 'hold_b', 'hold_a', 'cops_jump', 'random_input'],
    'sail': ['idle', 'hold_right', 'sail_tack', 'sail_random', 'random_input'],
    'parking': ['idle', 'hold_a', 'mash_a', 'random_input'],
    'subway': ['idle', 'hold_right', 'mash_a', 'random_input'],
}


# the skilled bot `pt.py curve <event>` slows down to human reaction times;
# plug-ins may set CURVE = {'<event>': 'policy'}
CURVE = {}


# per-event bots live in policies_<event>.py next to this file; each may define
# POLICIES (name -> class) and DEFAULTS (event -> list) to add or replace
def _plugins():
    import importlib
    import os
    here = os.path.dirname(os.path.abspath(__file__))
    for f in sorted(os.listdir(here)):
        if f.startswith('policies_') and f.endswith('.py'):
            m = importlib.import_module(f[:-3])
            POLICIES.update(getattr(m, 'POLICIES', {}))
            DEFAULTS.update(getattr(m, 'DEFAULTS', {}))
            CURVE.update(getattr(m, 'CURVE', {}))


_plugins()
