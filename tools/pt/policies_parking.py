"""Parallel Parking bots.

The car is on screen the whole time, so reading its pose from event RAM is
what a player sees: where the car is, which way it points, the wheel
indicator, the grade lamps, the cyclist. What separates the bots is timing
and judgement:

    park_expert   knows the manoeuvre cold, reads the pose exactly and acts on
                  the frame: stops where the swing will end dead centre (a
                  hair past the line in a long spot, then a free tap back),
                  counter-steers for the curb kiss, straightens on the frame,
                  backs in right behind the cyclist (CLOSE SHAVE).
    park_human    the same plan from a player who has practised it: every
                  decision is made LEAD frames ahead (LEAD = the hand's
                  measured lag: practice is learning your own timing), but
                  judged by eye, so each spot it misjudges the stop line, the
                  counter-steer point and the straight by a little (more the
                  slower the hand), and it aims with a margin that grows with
                  its lag. Only a quick hand (lag <= SHAVE_LAG) tries the
                  close shave. This is the bot `pt.py curve parking` slows.
    park_coach    a first-timer who only follows the coach line in the panel
                  (reads the message the HUD shows, reacts to it in 12 f).
    park_prompt*  the same at 20-25 f (and 40 f), and a 25 f hand the coach
                  thinks is quick: the proof that every cue leaves a human
                  time to act.
    park_wiggle   no plan: drives up, backs in at full lock, counter-steers
                  at a random moment, presses A.
"""
import math

from policies import Policy, idle, hold_a, mash_a, random_input, A, B, UP, DOWN, LEFT, RIGHT

# ev_ram offsets (src/ev_parking.s)
O_AX, O_AY, O_TH, O_PHASE, O_SPOT, O_LEN, O_BTOP, O_V, O_STEER, O_NOTCH = 0, 2, 4, 6, 10, 12, 14, 16, 18, 20
O_CLOCK, O_FLAGS, O_MSGT, O_INSPOT, O_GC, O_GA, O_GS = 24, 32, 42, 78, 66, 68, 70
O_BX, O_BY, O_BST, O_COACH, O_SHOWN, O_ANIM = 128, 130, 132, 140, 124, 48
O_TGT, O_FRONT, O_REAR, O_SHAVE = 206, 232, 234, 286
CX, CY = 80, 88
CURB, A_REAR, TGT_Y, BIKE_X = 232, 88, 91, 170
F_REV, F_FWD = 1, 2
SWING = 54.5            # the rear axle ends about this far behind where it pulled up


def _s16(v):
    return v - 0x10000 if v & 0x8000 else v


class _Parker(Policy):
    every = 1
    LEAD = 0            # frames of anticipation
    LEAD_MAX = None     # None: a fixed LEAD; else LEAD = min(measured lag, LEAD_MAX)
    SWAP_GAP = 1.0      # aim for this curb gap
    TAP = 10            # frames per tap (hold), then the same released
    SHAVE = True        # back in right behind the cyclist
    CENTRE = True       # pull up for dead centre, then tap back to it

    def __init__(self):
        self.stage = None
        self.spot = -1
        self.prog = []          # queued masks for a motor program (taps)
        self.wait = 0
        self.prev = None
        self.park_tries = 0
        self.nudges = 0

    def view(self):
        g = self.game
        m = g.core.peek(g.sym['ev_ram'], 300)
        w = lambda o: m[o] | m[o + 1] << 8
        s = lambda o: _s16(w(o))
        st = {'ax': w(O_AX) / 256.0, 'ay': w(O_AY) / 256.0, 'th': s(O_TH) / 65536.0 * 2 * math.pi,
              'phase': m[O_PHASE], 'spot': m[O_SPOT], 'len': w(O_LEN), 'btop': w(O_BTOP), 'v': s(O_V),
              'steer': s(O_STEER), 'notch': s(O_NOTCH), 'clock': w(O_CLOCK), 'flags': m[O_FLAGS],
              'inspot': m[O_INSPOT], 'gc': m[O_GC], 'ga': m[O_GA], 'gs': m[O_GS],
              'bx': w(O_BX), 'by': w(O_BY) / 256.0, 'bst': m[O_BST], 'coach': w(O_COACH),
              'cx': [s(CX + 2 * i) for i in range(4)], 'cy': [s(CY + 2 * i) for i in range(4)],
              'anim': w(O_ANIM), 'hit': m[138], 'tgt': w(O_TGT), 'front': s(O_FRONT), 'rear': s(O_REAR),
              'shave': m[O_SHAVE + 1]}
        return st

    # ---- the plan ----
    def tap(self, btn, n=1, hold=0, length=None):
        for _ in range(n):
            self.prog += [btn | hold] * (length or self.TAP) + [hold] * self.TAP

    def gap_pred(self, st, th=None):
        th = st['th'] if th is None else th
        return CURB - 11 - st['ax'] - 32 * (1 - math.cos(th)) - 3

    def feel_lag(self, t, m):
        """how late my decisions land on the pad (a human learns this)"""
        if self.LEAD_MAX is None:
            return
        g = self.game
        raw = g.core.peek(g.sym['pad'], 2)
        raw = raw[0] | raw[1] << 8
        pad = sum(1 << i for i in range(12) if raw & (1 << (15 - i))) & (UP | DOWN | LEFT | RIGHT | A)
        if not hasattr(self, 'pend'):
            self.pend, self.lags, self.sent, self.last_pad = [], [], None, 0
        if pad != self.last_pad:
            # the pad just changed: the oldest decision it matches has landed
            # (anything older was superseded or missed)
            for j, (t0, want) in enumerate(self.pend):
                if want == pad:
                    self.lags = (self.lags + [t - t0])[-12:]
                    del self.pend[:j + 1]
                    break
        self.last_pad = pad
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

    def new_spot(self, st, rng):
        """per-spot judgement errors (none for the expert)"""
        self.y_err = self.gap_err = self.th_err = 0.0

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
            self.shave_go = False
            self.prev_by = None
            self.let_go = False
            self.stuck = 0
            self.coached = None
            self.new_spot(st, rng)
        prev = self.prev or st
        self.prev = st
        # pinned on something with a pedal down: do what the instructor says
        # for the rest of the spot
        if self.last_m & (UP | DOWN) and st['v'] == 0 and (st['ax'], st['ay']) == (prev['ax'], prev['ay']):
            self.stuck += 1
        else:
            self.stuck = 0
        if self.stuck > 30 and not self.coached:
            self.coached = park_coach()
            self.coached.game = self.game
        if self.coached:
            return self.coached.act(t, tel, rng)
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

    def pull_target(self, st):
        """where the rear axle stops before backing in"""
        tgt = st['tgt']
        if not self.CENTRE:
            return tgt
        # the swing ends SWING px back; dead centre is axle y = (btop + 114) / 2.
        # A hair forward of that (up to 4 px past the line) and a free tap
        # back beats stopping short (moving forward again costs ONE-MOVE)
        # (no further up than y 87.5: a curb-kiss swing from there just clears the BMW)
        want = (st['btop'] + 114) / 2.0 - SWING - 1.5
        return max(87.5, tgt - 3.5, min(tgt + 6, want))

    def y_margin(self):
        return 0.0

    def bike_coming(self, st):
        """she's riding up and hasn't passed my nose yet"""
        if st['bst'] != 2:
            return False
        return st['by'] + 6 > min(st['cy']) - 2

    def bike_block(self, st, lead):
        """wait for the cyclist: she's coming and my nose is out in her line"""
        if st['bst'] != 2:
            return False
        front = min(st['cy'])
        left = min(st['cx'])
        if self.shave_go:
            return False
        if self.SHAVE and self.try_shave and st['flags'] & F_REV == 0 and st['th'] > -0.05:
            # go when she'll be SHAVE_DY px below my front-left corner as my
            # hand gets there: the nose swings out right behind her
            fl = st['cy'][2]
            spd = max(1.0, self.prev_by - st['by']) if self.prev_by else 1.25
            self.prev_by = st['by']
            if st['by'] - spd * lead > fl + self.SHAVE_DY:
                return True
            self.shave_go = True
            return False
        # still below (or level with) my front, and I'm out in the lane or about to be
        return st['by'] > front - 24 and left < BIKE_X + 16

    SHAVE_DY = 8.0
    STR_PAD = 3         # frames the car still turns after letting go
    try_shave = True
    stuck = 0
    coached = None
    shave_go = False
    prev_by = None
    let_go = False

    def plan(self, st, prev, rng):
        ay, v, th, notch = st['ay'], st['v'], st['th'], st['notch']
        lead = self.LEAD
        tgt_y = st['tgt']           # the yellow stop line (rear bumper = axle + 6)
        if self.stage == 'up':
            # (a slow hand stops a little short: more than 4 px past the line
            # costs the ONE-MOVE)
            tgt = self.pull_target(st) + self.y_err + self.y_margin()
            if ay - self.stop_dist(v, lead) > tgt + 0.5 and v >= 0:
                return UP
            if v != 0:
                return 0
            if ay < tgt_y - 4:
                self.stage = 'reup'
                return 0
            self.stage = 'back'
            return 0
        if self.stage == 'reup':
            # overshot: back straight up to the mark
            if ay + self.stop_dist(v, lead) < tgt_y and v <= 0:
                return DOWN
            if v != 0:
                return 0
            self.stage = 'back'
            return 0
        if self.stage == 'back':
            if self.bike_block(st, lead):
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
            rate = th - prev['th']
            if not self.let_go and th + rate * (lead + self.STR_PAD) < -self.th_err:
                return self.pedal(st, LEFT)
            self.let_go = True          # let go: wait for it to stop
            if v != 0:
                return 0
            self.stage = 'park'
            return 0
        if self.stage == 'park':
            if v != 0:
                return 0
            if self.NUDGE and st['inspot'] and st['gc'] == 0 and st['ga'] == 0 and self.nudges < 3:
                f, r = st['front'], st['rear']
                # dead centre (|front - rear| <= 1) by a free tap back; forward
                # (losing ONE-MOVE) only for the SPACE lamp
                if r - f >= 2 or (f - r >= 2 and st['gs'] != 0):
                    self.nudges += 1
                    self.stage = 'nudge'
                    self.nudge_to = (f - r) / 2.0
                    self.nudge_dir = DOWN if f < r else UP
                    self.nudge_y = ay
                    return 0
            if st['inspot'] and self.park_tries < 3:
                self.park_tries += 1
                self.tap(A)
                self.wait = 20
                return 0
            # not in the spot (cyclist made me stop short?): keep backing
            if not st['inspot'] and st['flags'] & F_REV:
                self.stage = 'straight' if th < 0 else 'up'
                self.let_go = False
            return 0
        if self.stage == 'nudge':
            # move the car by nudge_to px (+ = back), stopping on it
            left = abs(self.nudge_to) - abs(ay - self.nudge_y)
            if left - self.stop_dist(v, lead) > 0.4 and (v == 0 or (v < 0) == (self.nudge_dir == DOWN)):
                return self.nudge_dir
            if v != 0:
                return 0
            self.stage = 'park'
            return 0
        return 0

    y_err = 0.0
    gap_err = 0.0
    th_err = 0.0
    NUDGE = True


class park_expert(_Parker):
    LEAD = 0
    SWAP_GAP = -0.5     # (the model's -3 px for the wheel's travel is a hair long: a 0 px kiss)
    STR_PAD = 2         # let go 2 frames early: ZERO ANGLE


SHAVE_LAG = 8


class park_human(_Parker):
    """A practised human: plans ahead by their own measured lag, judges by
    eye (per-spot errors that grow with the lag), aims with a margin."""
    LEAD = 6
    LEAD_MAX = 40
    CREEP_LAG = 30

    STR_PAD = 2

    def new_spot(self, st, rng):
        # (an eye can't judge half a pixel or half a degree: errors have a floor)
        lag = self.lag() or 6
        self.y_err = rng.gauss(0, 0.5 + 0.07 * lag)
        self.gap_err = rng.gauss(0, 0.5 + 0.06 * lag)
        self.th_err = rng.gauss(0, 0.007 + 0.0007 * lag)
        self.try_shave = lag <= SHAVE_LAG
        self.CENTRE = lag <= SHAVE_LAG
        self.SHAVE_DY = 8.0 + rng.gauss(0, 1.5)

    def y_margin(self):
        return 0.2 * self.lag()

    def plan(self, st, prev, rng):
        # a sure hand aims for the curb kiss; a slower one leaves margin
        self.SWAP_GAP = 0.5 + 0.12 * self.lag()
        return super().plan(st, prev, rng)


class park_wiggle(_Parker):
    """Knows the gist, not the timing: random stop point and counter-steer."""
    SHAVE = False
    CENTRE = False
    NUDGE = False

    def plan(self, st, prev, rng):
        if self.stage == 'up' and st['v'] == 0 and st['ay'] > 150:
            self.y_err = rng.uniform(-6, 14)
            self.gap_err = rng.uniform(-4, 12)
            self.th_err = rng.uniform(-0.05, 0.12)
        return super().plan(st, prev, rng)


class park_prompt(Policy):
    """Obeys only the line on screen, with a human hand: each prompt is acted
    on LAT frames after it shows (+- JIT), and only what it names is held.
    Nothing else is read: no RAM, no plan, no anticipation. The proof that
    every cue leaves a 20-25 f human time to act. FAST_CUES: prompts this
    hand answers quicker than the rest (the coach then thinks it is quicker
    than it is: it measures its reaction on LET GO OF UP and BACK IN)."""
    every = 1
    LAT = 22
    JIT = 2
    FAST_CUES = {}

    # prompt prefix -> what the hand holds (None: tap A)
    TABLE = (('GAS ', UP), ('LET GO OF ', 0), ('PAST IT!', DOWN), ('HOLD DOWN+RIGHT: BACK', DOWN | RIGHT),
             ('HOLD DOWN+RIGHT', DOWN | RIGHT), ('NOW!', DOWN | LEFT),
             ('HOLD DOWN+LEFT', DOWN | LEFT), ('STRAIGHT! LET', 0), ('A: PARK', None), ('A: ON TO', None),
             ('A: SEE', None), ('TOO FAR OUT', None), ('OVER THE CURB', None), ('WAIT!', 0),
             ('HOLD UP+LEFT', UP | LEFT), ('MIND THE BMW', DOWN), ('TOO SOON', DOWN | RIGHT), ('PINNED', DOWN),
             ('STUCK! HOLD UP', UP), ('STUCK! HOLD DOWN', DOWN), ('TOO LATE!', 0), ('HOLD UP+RIGHT', UP | RIGHT),
             ('ENOUGH!', 0), ('HOLD DOWN ONLY', DOWN), ('BACK STRAIGHT', DOWN))

    def __init__(self):
        self.queue = []
        self.hold = 0
        self.want = 0
        self.txt = None
        self.taps = []

    def shown(self):
        g = self.game
        m = g.core.peek(g.sym['ev_ram'], 192)
        a = m[124] | m[125] << 8
        if a == 0xFFFF:
            return ''
        bank = g.sym['ev_parking'] >> 16
        off = (bank - 0x80) * 0x8000 + (a & 0x7FFF)
        return g.sym.rom[off:off + 40].split(b'\0')[0].decode('latin-1')

    def act(self, t, tel, rng):
        txt = self.shown()
        if txt != self.txt:
            self.txt = txt
            for pre, mask in self.TABLE:
                if txt.startswith(pre):
                    lat = self.FAST_CUES.get(pre, self.LAT)
                    due = t + max(1, lat + rng.randint(-self.JIT, self.JIT))
                    if self.queue:
                        due = max(due, self.queue[-1][0] + 1)
                    self.queue.append((due, mask, txt))
                    break
        while self.queue and self.queue[0][0] <= t:
            _, mask, _ = self.queue.pop(0)
            if mask is None:
                self.taps = [A] * 6 + [0] * 4
                self.hold = 0
            else:
                self.hold = mask
        if self.taps:
            return self.taps.pop(0) | self.hold
        return self.hold


class park_coach(park_prompt):
    """A first-timer who only follows the coach line in the panel, with a
    quick hand (12 f)"""
    LAT = 12


class park_prompt20(park_prompt):
    LAT = 20


class park_prompt25(park_prompt):
    LAT = 25


class park_prompt40(park_prompt):
    """slower than the coach's aim allows: exercises TOO LATE and the pull-out"""
    LAT = 40
    JIT = 4


class park_prompt25q(park_prompt):
    """a 25 f hand the coach measures as quick (it saw LET GO OF UP and BACK
    IN coming and answered them in 8 f)"""
    LAT = 25
    FAST_CUES = {'LET GO OF ': 8, 'HOLD DOWN+RIGHT: BACK': 8}


POLICIES = {c.__name__: c for c in [park_expert, park_human, park_wiggle, park_coach, park_prompt,
                                        park_prompt20, park_prompt25, park_prompt25q, park_prompt40]}
DEFAULTS = {'parking': ['idle', 'hold_a', 'mash_a', 'park_wiggle', 'park_coach', 'park_human', 'park_expert',
                        'random_input']}
CURVE = {'parking': 'park_human'}
