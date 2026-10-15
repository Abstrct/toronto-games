"""Parallel Parking bots.

The car is on screen the whole time, so reading its pose from event RAM is
what a player sees: where the car is, which way it points, the wheel
indicator, the grade lamps, the cyclist. What separates the bots is timing
and judgement:

    park_expert   knows the manoeuvre cold, reads the pose exactly and acts on
                  the frame (or as far ahead as its hand is late: it learns
                  its own lag): stops where the swing will end dead centre (a
                  hair past the line in a long spot, then a free tap back),
                  counter-steers for the curb kiss, straightens on the frame,
                  never stands still (brakes on DOWN and rolls straight into
                  reverse, A as it stops: NONSTOP), and on a cyclist's spot
                  paces its approach so it arrives as she comes by and backs
                  in right behind her (the undocumented trick).
    park_driver     the same plan from a player who has practised it: every
                  decision is made LEAD frames ahead (LEAD = the hand's
                  measured lag: practice is learning your own timing), but
                  judged by eye, so each spot it misjudges the stop line, the
                  counter-steer point, the straight and the moment it stops
                  by a little (more the slower the hand), and it aims with a
                  margin that grows with its lag. It goes for NONSTOP; a
                  quick hand (lag <= SHAVE_LAG) paces its approach and
                  anticipates the trick; a slower one has learned the
                  cyclist's DING! bubble: it waits on the line and backs in
                  CUE_AIM frames after the bubble shows (less its own lag).
                  This is the bot `pt.py curve parking` slows.
    park_human    park_driver with its own 15 f hand (+- 4, 3% missed): what an
                  average practised player scores (`pt.py bot` needs no
                  latency for it).
    park_tell     the trick from its tell alone: waits on the line, and the
                  moment the cyclist's DING! bubble shows beside her (read
                  from OAM) rolls to DOWN+RIGHT. It reads nothing else about
                  her; the hand's latency is its reaction.
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
    NONSTOP = False     # never stand still: brake on DOWN, reverse as it stops, A as it stops
    PACE = False        # on a cyclist's spot, pace the approach to arrive as she comes by
    A_ERR = 0           # frames my A lands off the moment the car stops (per spot, +- this)

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
        self.hist = (getattr(self, 'hist', []) + [m])[-64:]
        return m

    def v_ahead(self, v, lead):
        """the speed once what my hand is still carrying out has landed
        (the gas I've decided on but not yet felt)"""
        for m in getattr(self, 'hist', [])[-lead:] if lead else []:
            if v >= 0:
                v = min(96, v + 4) if m & UP else max(0, v - 8)
        return v

    def new_spot(self, st, rng):
        """per-spot judgement errors (none for the expert)"""
        self.y_err = self.gap_err = self.th_err = 0.0

    def _act(self, t, tel, rng):
        self.t = t
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
            self.letgo_t = None
            self.brake_t = None
            self.stuck = 0
            self.coached = None
            self.bspd = 1.25
            self.a_off = 0
            self.new_spot(st, rng)
            if self.A_ERR:
                self.a_off = rng.randint(-self.A_ERR, self.A_ERR)
        prev = self.prev or st
        self.prev = st
        if st['bst'] == 2 and prev['bst'] == 2 and prev['by'] > st['by']:
            self.bspd = prev['by'] - st['by']
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
            spd = self.bspd
            if st['by'] - spd * lead > fl + self.SHAVE_DY:
                return True
            self.shave_go = True
            return False
        # still below (or level with) my front, and I'm out in the lane or about to be
        return st['by'] > front - 24 and left < BIKE_X + 16

    def stopping(self, v, lead):
        """the car has stopped (NONSTOP: or A pressed now lands as it does)"""
        if v == 0:
            return True
        if not self.NONSTOP:
            return False
        # braking 8 a frame from when my let-go lands (my hand is as late
        # for A as it was for that): A counts under 9
        if self.letgo_t is None:
            return abs(v) <= 8
        frames = max(0, -(-(self.letgo_v - 8) // 8))
        return self.t - self.letgo_t >= frames - self.a_off

    def bike_wait_at_line(self, st, lead):
        """NONSTOP braking onto the line: would I have to wait for her there?"""
        if st['bst'] != 2:
            return False
        frames = abs(st['v']) // 8 + 1
        return False if self.shave_go else self.bike_block(st, lead + frames)

    def approach_speed(self, st, tgt, lead):
        """PACE: the speed (1/128 px a frame) that gets me to the line as the
        cyclist comes by (in time to back in right behind her, or once she's
        past), or None: flat out"""
        if not (self.PACE and st['bst'] == 2):
            return None
        spd = max(0.8, self.bspd)
        fl_line = st['cy'][2] - (st['ay'] - tgt)        # my front-left corner, on the line
        if self.SHAVE and self.try_shave:
            go = (st['by'] - fl_line - self.SHAVE_DY) / spd - lead
        else:
            go = (st['by'] - (fl_line - 26)) / spd - lead
        if go <= 0:
            return None
        arrive = go - 4 + self.pace_err
        dist = st['ay'] - tgt
        if dist <= 0:
            return None
        want = 128.0 * dist / max(1.0, arrive)
        return max(16, min(96, want))

    pace_err = 0.0
    a_off = 0
    letgo_t = None
    letgo_v = 0
    brake_t = None
    brake_v = 0
    t = 0
    bspd = 1.25
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
                want = self.approach_speed(st, tgt, lead)
                if want is not None and self.v_ahead(v, lead) >= want:
                    return 0            # (letting go brakes: feathering the gas)
                return UP
            if v > 0:
                # NONSTOP: brake on DOWN (it brakes just as letting go does)
                # and it rolls straight into reverse; the wheel goes over as
                # it stops
                if self.NONSTOP and not self.bike_wait_at_line(st, lead):
                    # (the wheel goes over in the last 2 frames of the
                    # braking, which starts when my DOWN lands)
                    if self.brake_t is None:
                        self.brake_t, self.brake_v = self.t, v
                    late = self.t - self.brake_t >= self.brake_v // 8 - 2
                    return DOWN | (RIGHT if late else 0)
                return 0
            if ay < tgt_y - 4:
                self.stage = 'reup'
                return 0
            self.stage = 'back'
            if self.NONSTOP:
                return self.plan(st, prev, rng)
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
            if not self.let_go:
                self.letgo_t, self.letgo_v = self.t, abs(v)
            self.let_go = True          # let go: wait for it to stop
            if not self.stopping(v, lead):
                return 0
            self.stage = 'park'
            return self.plan(st, prev, rng) if self.NONSTOP else 0
        if self.stage == 'park':
            if not self.stopping(v, lead):
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
                self.let_go = False; self.letgo_t = None
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


class park_tas(_Parker):
    """frame-perfect: the ceiling (and the title demo's driver)"""
    LEAD = 0
    LEAD_MAX = 40       # (a late hand: it learns its lag and plans that far ahead)
    SWAP_GAP = -0.5     # (the model's -3 px for the wheel's travel is a hair long: a 0 px kiss)
    STR_PAD = 2         # let go 2 frames early: ZERO ANGLE
    NONSTOP = True
    PACE = True


class park_expert(park_tas):
    """the best player in the room: park_tas's plan and timing, judged by a
    very good eye (a third of a pixel, a quarter of a degree, a frame or
    two), so the top end varies run to run as a real ace's does"""
    def new_spot(self, st, rng):
        self.y_err = rng.gauss(0, 0.35)
        self.gap_err = rng.gauss(0, 0.45)
        self.th_err = rng.gauss(0, 0.004)
        self.SHAVE_DY = 8.0 + rng.gauss(0, 1.5)
        self.pace_err = rng.gauss(0, 2.0)
        self.A_ERR = 1


SHAVE_LAG = 8
PACE_LAG = 12           # a slower hand waits on the line for the cyclist
CUE_AIM = 21            # ... and backs in about this many frames after her DING! bubble shows


class park_driver(_Parker):
    """A practised human: plans ahead by their own measured lag, judges by
    eye (per-spot errors that grow with the lag), aims with a margin."""
    LEAD = 6
    LEAD_MAX = 40
    CREEP_LAG = 30
    NONSTOP = True
    PACE = True

    STR_PAD = 2

    def new_spot(self, st, rng):
        # (an eye can't judge half a pixel or half a degree: errors have a floor)
        lag = self.lag() or 6
        self.y_err = rng.gauss(0, 0.5 + 0.07 * lag)
        self.gap_err = rng.gauss(0, 0.5 + 0.06 * lag)
        self.th_err = rng.gauss(0, 0.007 + 0.0007 * lag)
        self.try_shave = lag <= SHAVE_LAG
        self.CENTRE = lag <= SHAVE_LAG
        self.PACE = lag <= PACE_LAG
        self.SHAVE_DY = 8.0 + rng.gauss(0, 1.5)
        # judging her speed and my arrival by eye: off by a few frames
        self.pace_err = rng.gauss(0, 2 + 0.25 * lag)
        self.A_ERR = 1 + lag // 6
        # a slower hand that has learned the cyclist's DING! bubble: waits on
        # the line and backs in a beat after it (its own lag learned)
        self.tell = lag > SHAVE_LAG
        if self.tell:
            self.PACE = False       # (waits on the line for her instead)
        self.heard_t = None

    def bike_block(self, st, lead):
        if not self.tell:
            return super().bike_block(st, lead)
        if st['bst'] != 2 or self.shave_go:
            return False
        if self.heard_t is None and bubble_up(self.game):
            self.heard_t = self.t
        if self.heard_t is not None and st['flags'] & F_REV == 0:
            if self.t >= self.heard_t + max(0, CUE_AIM - self.lag()):
                self.shave_go = True
                return False
            return True
        front, left = min(st['cy']), min(st['cx'])
        return st['by'] > front - 24 and left < BIKE_X + 16

    def y_margin(self):
        return 0.2 * self.lag()

    def plan(self, st, prev, rng):
        # a sure hand aims for the curb kiss; a slower one leaves margin
        self.SWAP_GAP = 0.5 + 0.12 * self.lag()
        return super().plan(st, prev, rng)


class park_human(park_driver):
    """park_driver with an average human hand built in: every decision lands
    HAND +- HAND/4 frames late, and 3% never happen (what `pt.py curve`
    does to park_driver at 15 f), so `pt.py bot` shows an average player"""
    HAND = 15
    MISS = 0.03

    def act(self, t, tel, rng):
        m = super().act(t, tel, rng)
        if not hasattr(self, 'hq'):
            self.hq, self.hwant, self.hhold = [], 0, 0
            self.hrng = __import__('random').Random(rng.random())
        if m != self.hwant and self.hrng.random() >= self.MISS:
            self.hwant = m
            due = t + max(0, self.HAND + self.hrng.randint(-(self.HAND // 4), self.HAND // 4))
            if self.hq:
                due = max(due, self.hq[-1][0] + 1)
            self.hq.append((due, m))
        while self.hq and self.hq[0][0] <= t:
            self.hhold = self.hq.pop(0)[1]
        return self.hhold


def _bubble_tiles():
    """the DING! bubble's two 16x16 tiles (build/parking_meta.inc MS_BUBBLE_BASE)"""
    import os
    import re
    inc = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'build', 'parking_meta.inc')
    try:
        base = int(re.search(r'MS_BUBBLE_BASE = (\d+)', open(inc).read()).group(1))
    except (OSError, AttributeError):
        base = 316
    return (base, base + 2)


BUBBLE_TILES = _bubble_tiles()


def bubble_up(game):
    """the DING! bubble is on screen: read from OAM, as the player sees it"""
    oam = game.core.peek(game.sym['oam_buf'], 512)
    for i in range(128):
        x, y, t, at = oam[4 * i:4 * i + 4]
        if 224 <= y < 240:
            continue            # parked off screen
        if (t | (at & 1) << 8) in BUBBLE_TILES:
            return True
    return False


class park_tell(park_driver):
    """The undocumented trick from its tell alone: drives up to the line as
    usual (no pacing), waits, and the moment the cyclist's DING! bubble shows
    beside her (read from OAM: what's on screen) rolls to DOWN+RIGHT. Nothing
    else about her is read. The hand's latency is the reaction (pt.py curve
    parking -p park_tell; or with a fixed +-3 jitter for the trick's table)."""
    NONSTOP = False
    PACE = False

    def new_spot(self, st, rng):
        super().new_spot(st, rng)
        self.try_shave = True
        self.heard = False
        self.PACE = False
        self.CENTRE = False     # stop on the line and wait there

    def bike_block(self, st, lead):
        if st['bst'] != 2 or self.shave_go:
            return False
        if not self.heard and bubble_up(self.game):
            self.heard = True
        if self.heard and st['flags'] & F_REV == 0:
            self.shave_go = True
            return False
        # no bubble yet: wait for it (or for her to go by)
        front, left = min(st['cy']), min(st['cx'])
        return st['by'] > front - 24 and left < BIKE_X + 16

    def plan(self, st, prev, rng):
        # stopped a little short of the line counts as on it (the coach says
        # WAIT there too): no creeping up to it with a slow hand
        if self.stage == 'up' and st['v'] == 0 and 0 <= st['ay'] - st['tgt'] <= 8 and st['flags'] & F_REV == 0:
            self.stage = 'back'
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

    # prompt prefix -> what the hand holds (None: tap A). The arrow glyphs
    # read back as their font codes + 32: v down, u up, o left, n right
    TABLE = (('GAS ', UP), ('LET GO OF ', 0), ('PAST IT!', DOWN), ('HOLD v+n: BACK', DOWN | RIGHT),
             ('HOLD v+n', DOWN | RIGHT), ('KEEP HOLDING v+n', DOWN | RIGHT), ('NOW!', DOWN | LEFT),
             ('HOLD v+o', DOWN | LEFT), ('STRAIGHT! LET', 0), ('A: PARK', None), ('A: ON TO', None),
             ('A: SEE', None), ('TOO FAR OUT', None), ('OVER THE CURB', None), ('WAIT!', 0),
             ('HOLD u+o', UP | LEFT), ('MIND THE BMW', DOWN), ('TOO SOON', DOWN | RIGHT), ('PINNED', DOWN),
             ('STUCK! HOLD u', UP), ('STUCK! HOLD v', DOWN), ('EASY, CURB!', 0), ('HOLD u+n', UP | RIGHT),
             ('ENOUGH!', 0))

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


POLICIES = {c.__name__: c for c in [park_tas, park_expert, park_driver, park_human, park_tell, park_wiggle, park_coach,
                                    park_prompt, park_prompt20, park_prompt25, park_prompt25q, park_prompt40]}
DEFAULTS = {'parking': ['idle', 'hold_a', 'mash_a', 'park_wiggle', 'park_coach', 'park_human', 'park_driver',
                        'park_expert', 'park_tas', 'random_input']}
CURVE = {'parking': 'park_driver'}
