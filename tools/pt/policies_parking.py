"""Parallel Parking bots.

The car is on screen the whole time, so reading its pose from event RAM is
what a player sees: where the car is, which way it points, the wheel
indicator, the grade lamps, the cyclist. What separates the bots is timing:

    park_expert   knows the manoeuvre cold and acts on the exact frame:
                  stops with the bumpers level, counter-steers at the right
                  angle, straightens on the frame, waits out the cyclist.
    park_human    the same plan from a player who has learned it, with a
                  human's anticipation: every decision is made LEAD frames
                  ahead from the car's visible motion (no frame-perfect
                  RAM). A practised player knows their own reaction time,
                  so LEAD is the hand's measured lag (how long a decision
                  takes to show up on the pad), but nobody anticipates more
                  than LEAD_MAX frames. A sure hand aims for the curb
                  kiss, a slow one leaves margin and (from 12 frames) creeps
                  in reverse; with CURB and ANGLE green it nudges to centre
                  for the SPACE lamp. Its pull-up mark is the yellow stop
                  line the game draws. This is the bot `pt.py curve
                  parking` slows down.
    park_coach    a first-timer who only follows the coach line in the panel
                  (reads the message the HUD shows, reacts to it).
    park_wiggle   no plan: drives up, backs in at full lock, counter-steers
                  at a random moment, presses A.
"""
import math

from policies import Policy, idle, hold_a, mash_a, random_input, A, B, UP, DOWN, LEFT, RIGHT

# ev_ram offsets (src/ev_parking.s)
O_AX, O_AY, O_TH, O_PHASE, O_SPOT, O_LEN, O_BTOP, O_V, O_STEER, O_NOTCH = 0, 2, 4, 6, 10, 12, 14, 16, 18, 20
O_CLOCK, O_FLAGS, O_MSGT, O_INSPOT, O_GC, O_GA, O_GS = 24, 32, 42, 78, 66, 68, 70
O_BX, O_BY, O_BST, O_COACH, O_SHOWN, O_ANIM = 128, 130, 132, 140, 124, 48
O_TGT = 206
CX, CY = 80, 88
CURB, A_REAR, TGT_Y, BIKE_X = 232, 88, 91, 170
F_REV = 1


def _s16(v):
    return v - 0x10000 if v & 0x8000 else v


class _Parker(Policy):
    every = 1
    LEAD = 0            # frames of anticipation
    SWAP_GAP = 1      # aim for this curb gap
    TAP = 10            # frames per tap (hold), then the same released

    def __init__(self):
        self.stage = None
        self.spot = -1
        self.prog = []          # queued masks for a motor program (taps)
        self.wait = 0
        self.prev = None
        self.park_tries = 0
        self.nudges = 0

    NUDGE = False

    def view(self):
        g = self.game
        m = g.core.peek(g.sym['ev_ram'], 256)
        w = lambda o: m[o] | m[o + 1] << 8
        s = lambda o: _s16(w(o))
        st = {'ax': w(O_AX) / 256.0, 'ay': w(O_AY) / 256.0, 'th': s(O_TH) / 65536.0 * 2 * math.pi,
              'phase': m[O_PHASE], 'spot': m[O_SPOT], 'len': w(O_LEN), 'btop': w(O_BTOP), 'v': s(O_V),
              'steer': s(O_STEER), 'notch': s(O_NOTCH), 'clock': w(O_CLOCK), 'flags': m[O_FLAGS],
              'inspot': m[O_INSPOT], 'gc': m[O_GC], 'ga': m[O_GA], 'gs': m[O_GS],
              'bx': w(O_BX), 'by': w(O_BY) / 256.0, 'bst': m[O_BST], 'coach': w(O_COACH),
              'cx': [s(CX + 2 * i) for i in range(4)], 'cy': [s(CY + 2 * i) for i in range(4)],
              'anim': w(O_ANIM), 'hit': m[138], 'tgt': w(O_TGT)}
        return st

    # ---- the plan ----
    def tap(self, btn, n=1, hold=0, length=None):
        for _ in range(n):
            self.prog += [btn | hold] * (length or self.TAP) + [hold] * self.TAP

    def lock(self, btn, hold=0):
        # hold the direction until the wheel is locked over
        self.tap(btn, 1, hold, length=12)

    def gap_pred(self, st, th=None):
        th = st['th'] if th is None else th
        return CURB - 11 - st['ax'] - 32 * (1 - math.cos(th)) - 3

    LEAD_MAX = None     # None: a fixed LEAD; else LEAD = min(measured lag, LEAD_MAX)

    def feel_lag(self, t, m):
        """how late my decisions land on the pad (a human learns this)"""
        if self.LEAD_MAX is None:
            return
        g = self.game
        raw = g.core.peek(g.sym['pad'], 2)
        raw = raw[0] | raw[1] << 8
        pad = sum(1 << i for i in range(12) if raw & (1 << (15 - i))) & (UP | DOWN | LEFT | RIGHT | A)
        if not hasattr(self, 'pend'):
            self.pend, self.lags, self.sent = [], [], None
        for j, (t0, want) in enumerate(self.pend):
            if want == pad:
                # this one landed; anything older was superseded or missed
                self.lags = (self.lags + [t - t0])[-12:]
                del self.pend[:j + 1]
                break
        del self.pend[:-8]
        m &= (UP | DOWN | LEFT | RIGHT | A)
        if m != self.sent:
            self.sent = m
            self.pend.append((t, m))
        if self.lags:
            lag = sorted(self.lags)[len(self.lags) // 2]
            self.LEAD = min(self.LEAD_MAX, max(0, lag - 1))

    def act(self, t, tel, rng):
        m = self._act(t, tel, rng)
        self.feel_lag(t, m)
        return m

    def _act(self, t, tel, rng):
        st = self.view()
        if st['phase'] == 1:
            # result screen: A once the box is up, to move on
            self.stage = None
            self.prog = []
            return A if st['anim'] > 100 and t % 20 < 10 else 0
        if st['phase'] != 0:
            return 0
        if st['ay'] == 0:
            return 0            # the car isn't on the road yet (a demo's first frame)
        if st['spot'] != self.spot or self.stage is None:
            self.spot = st['spot']
            self.stage = 'up'
            self.prog = []
            self.wait = 0
            self.prev = None
            self.park_tries = 0
            self.nudges = 0
        prev = self.prev or st
        self.prev = st
        if self.prog:
            return self.prog.pop(0)
        if self.wait:
            self.wait -= 1
            return self.hold_now
        m = self.plan(st, prev, rng)
        # a held pedal that isn't moving the car: let go and press again
        if m in (UP, DOWN) and st['v'] == 0 and m == self.last_m:
            self.same += 1
            if self.same > 24:
                self.same = 0
                self.wait = 4
                self.hold_now = 0
                m = 0
        else:
            self.same = 0
        self.last_m = m
        return m

    same = 0
    last_m = 0

    hold_now = 0

    def stop_dist(self, v, lead):
        """px the car still travels if I let go `lead` frames from now"""
        v = abs(v)
        return (v * v / 2048.0) + v / 128.0 * lead

    CREEP_LAG = None    # a slow hand (measured lag at least this) feathers the reverse

    def lag(self):
        lags = getattr(self, 'lags', None)
        return sorted(lags)[len(lags) // 2] if lags else 0

    def pedal(self, st, steer):
        """reverse with the wheel locked `steer`; a careful slow player creeps"""
        if self.CREEP_LAG is not None and self.lag() >= self.CREEP_LAG and st['v'] < -16:
            return steer
        return DOWN | steer

    def bike_block(self, st):
        """wait for the cyclist: she's coming and my nose is out in her line"""
        if st['bst'] != 2:
            return False
        front = min(st['cy'])
        left = min(st['cx'])
        # still below (or level with) my front, and I'm out in the lane or about to be
        return st['by'] > front - 24 and left < BIKE_X + 16

    def plan(self, st, prev, rng):
        ay, v, th, notch = st['ay'], st['v'], st['th'], st['notch']
        lead = self.LEAD
        tgt_y = st['tgt']           # the yellow stop line (rear bumper = axle + 6)
        if self.stage == 'up':
            tgt = tgt_y + self.y_err
            if ay - self.stop_dist(v, lead) > tgt + 0.5 and v >= 0:
                return UP
            if v != 0:
                return 0
            if ay < tgt_y - 4:
                self.stage = 'reup'
                return 0
            self.stage = 'lock'
            return 0
        if self.stage == 'reup':
            # overshot: back straight up to the mark
            if ay + self.stop_dist(v, lead) < tgt_y and v <= 0:
                return DOWN
            if v != 0:
                return 0
            self.stage = 'lock'
            return 0
        if self.stage == 'lock':
            self.stage = 'back'
        if self.stage == 'back':
            if self.bike_block(st):
                return 0
            # predicted counter-steer gap LEAD frames from now
            g, gp = self.gap_pred(st), self.gap_pred(prev)
            slope = g - gp if v < 0 else 0
            rate = th - prev['th']
            if v < 0 and g + slope * lead <= self.SWAP_GAP + self.gap_err and th + rate * lead < -0.78:
                self.stage = 'straight'
                return self.pedal(st, LEFT)
            return self.pedal(st, RIGHT)
        if self.stage == 'straight':
            if self.bike_block(st):
                return 0
            rate = th - prev['th']
            if th + rate * (lead + 3) < -self.th_err:
                return self.pedal(st, LEFT)
            if v != 0:
                return 0
            self.stage = 'park'
            return 0
        if self.stage == 'park':
            if v != 0:
                return 0
            # the SPACE lamp isn't green but CURB and ANGLE are: nudge to the middle
            if self.NUDGE and st['inspot'] and st['gs'] and st['gc'] == 0 and st['ga'] == 0 \
                    and self.nudges < 3:
                front = min(st['cy']) - A_REAR
                rear = st['btop'] - max(st['cy'])
                if abs(front - rear) >= 2:
                    self.nudges += 1
                    self.tap(DOWN if front < rear else UP, length=5)
                    self.wait = 20
                    return 0
            if st['inspot'] and self.park_tries < 3:
                self.park_tries += 1
                self.tap(A)
                self.wait = 20
                return 0
            # not in the spot (cyclist made me stop short?): keep backing
            if not st['inspot'] and st['flags'] & F_REV:
                self.stage = 'straight' if th < 0 else 'up'
            return 0
        return 0

    y_err = 0.0
    gap_err = 0.0
    th_err = 0.0


class park_expert(_Parker):
    LEAD = 0
    NUDGE = True


class park_human(_Parker):
    """A practised human: plans ahead by their own reaction time (at most
    6 frames' worth), aims a little safe."""
    LEAD = 6
    LEAD_MAX = 6
    CREEP_LAG = 12
    NUDGE = True

    def plan(self, st, prev, rng):
        # a sure hand aims for the curb kiss; a slower one leaves margin
        self.SWAP_GAP = min(3.5, 0.6 + max(0, self.lag() - 5) * 0.4)
        return super().plan(st, prev, rng)


class park_wiggle(_Parker):
    """Knows the gist, not the timing: random stop point and counter-steer."""

    def plan(self, st, prev, rng):
        if self.stage == 'up' and st['v'] == 0 and st['ay'] > 150:
            self.y_err = rng.uniform(-6, 14)
            self.gap_err = rng.uniform(-4, 12)
            self.th_err = rng.uniform(-0.05, 0.12)
        return super().plan(st, prev, rng)


class park_coach(Policy):
    """Follows the coach line it can see in the panel, nothing else."""
    every = 1

    def __init__(self):
        self.prog = []
        self.last = None

    def act(self, t, tel, rng):
        g = self.game
        m = g.core.peek(g.sym['ev_ram'], 192)
        w = lambda o: m[o] | m[o + 1] << 8
        if m[O_PHASE] == 1:
            return A if w(O_ANIM) > 100 and t % 20 < 10 else 0
        if self.prog:
            return self.prog.pop(0)
        shown = w(O_SHOWN)
        bank = g.sym['ev_parking'] >> 16
        off = (bank - 0x80) * 0x8000 + (shown & 0x7FFF)
        txt = g.sym.rom[off:off + 32].split(b'\0')[0].decode('latin-1')
        name = None
        for pre, k in (('GAS ', 'co_up'), ('LET GO!', 'co_brake'), ('PAST IT!', 'co_toofar'),
                       ('HOLD DOWN+RIGHT', 'co_back'), ('KEEP DOWN+RIGHT', 'co_ready'), ('NOW!', 'co_now'),
                       ('HOLD DOWN+LEFT', 'co_swing'), ('STRAIGHT! LET', 'co_stop'), ('A: PARK', 'co_park'),
                       ('TOO FAR OUT', 'co_fix'), ('OVER THE CURB', 'co_fix'), ('WAIT!', 'co_wait'),
                       ('DING DING', 'co_wait'), ('HOLD UP+LEFT', 'co_nosein'), ('MIND THE BMW', 'co_clear'),
                       ('TOO SOON', 'co_early'), ('PINNED', 'co_pinned'), ('STUCK! HOLD UP', 'co_pullup'),
                       ('STUCK! HOLD DOWN', 'co_backup')):
            if txt.startswith(pre):
                name = k
        if name is None or name == self.last:
            if name is None:
                return getattr(self, 'last_hold', 0)
        self.last = name
        hold = {'co_up': UP, 'co_brake': 0, 'co_toofar': DOWN, 'co_back': DOWN | RIGHT,
                'co_ready': DOWN | RIGHT, 'co_now': DOWN | LEFT, 'co_swing': DOWN | LEFT, 'co_stop': 0,
                'co_fix': 0, 'co_nosein': UP | LEFT, 'co_clear': DOWN, 'co_early': DOWN | RIGHT,
                'co_pinned': DOWN, 'co_pullup': UP, 'co_backup': DOWN}.get(name, 0)
        if name in ('co_park', 'co_fix'):
            self.prog = [A] * 6 + [0] * 30
            return 0
        self.last_hold = hold
        return hold


POLICIES = {c.__name__: c for c in [park_expert, park_human, park_wiggle, park_coach]}
DEFAULTS = {'parking': ['idle', 'hold_a', 'mash_a', 'park_wiggle', 'park_coach', 'park_human', 'park_expert',
                        'random_input']}
CURVE = {'parking': 'park_human'}
