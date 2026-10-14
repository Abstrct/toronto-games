"""Tallboy Trot bots.

The skilled ones read event RAM (they find the running `Game` on the call
stack, since `run_bot` has no hook) and plan jumps with a frame-exact copy of
the event's physics (src/ev_cops.s):

  cops_safe   perfect hurdling, never sips: the "just run" line
  cops_pro    perfect hurdling, sips whenever the cop is off-screen, times air
              sips over hurdles for SIP 'N' HOP chains, never sips by a bin
  cops_human  cops_pro with reaction noise, a cautious sip buffer and the
              odd missed jump
  cops_rookie first go: sloppy timing, fluffs one hurdle in four
  cops_human15  a decent human, modelled from the outside in: ~15-frame
              reaction to the cop, +-4 frames of jump timing, taps A for the
              low stuff and holds it for bins (and sometimes forgets), sips
              in committed 20-frame gulps, now and then next to a bin

The no-skill exploit detectors (idle, hold_a, hold_b, mash_a) come from
policies.py; `hold_b_mash_a` (sip + bunny-hop forever) and `tap_a` (a short
tap every 40 frames) are new ones.
"""
import inspect

from policies import Policy, A, B

RUN_SPD, SIP_SPD, TRIP_SPD = 0x200, 0xE0, 0x80
JUMP_V, GRAVITY, MIN_HOP, HOP_CUT = 0x3C0, 0x20, 6, 0x180
COP_SEEN = 110
OB_HW = [0, 14, 14, 9, 9]
OB_H = [0, 12, 10, 26, 9]
T_BIN = 3
ST_RUN = 0


def _game():
    f = inspect.currentframe()
    while f:
        g = f.f_locals.get('g')
        if g is not None and hasattr(g, 'core') and hasattr(g, 'sym'):
            return g
        f = f.f_back
    return None


def _w(b, o, signed=False):
    v = b[o] | b[o + 1] << 8
    return v - 0x10000 if signed and v >= 0x8000 else v


class _State:
    def __init__(self, g):
        base = g.sym['ev_ram']
        b = g.core.peek(base, 216)
        self.dist, self.distf, self.speed = _w(b, 0), _w(b, 2), _w(b, 4)
        self.h, self.vy = _w(b, 6), _w(b, 8, True)
        self.air, self.state, self.prog = b[10], b[12], b[18]
        self.gap, self.copspd = _w(b, 24), _w(b, 26)
        self.hold = _w(b, 46)
        self.t = _w(b, 52)
        self.chain, self.chaint = b[54], _w(b, 56)
        self.ents = []
        for i in range(10):
            t = _w(b, 64 + 2 * i)
            if t:
                self.ents.append(dict(i=i, t=t, wx=_w(b, 84 + 2 * i), wxf=_w(b, 104 + 2 * i),
                                      v=_w(b, 124 + 2 * i, True), flags=_w(b, 144 + 2 * i)))

    def bin_near(self, frames=0):
        """A green bin within raccoon reach of where you'll be in `frames`."""
        for e in self.ents:
            if e['t'] == T_BIN:
                rel = e['wx'] - self.dist - frames * SIP_SPD // 256
                if -30 <= rel < 56:
                    return True
        return False


def simulate(s, k, hold_a, air_b, horizon=90):
    """True if jumping k frames from now (A held hold_a frames, B held in the
    air if air_b) gets past every obstacle in the horizon without a hit."""
    dfix = s.dist * 256 + (s.distf & 0xFF)
    speed, h, vy, air, hold = s.speed, s.h, s.vy, s.air, s.hold
    ents = [[e['t'], e['wx'] * 256 + (e['wxf'] & 0xFF), e['v'], e['flags'] & 1] for e in s.ents]
    for f in range(horizon):
        a_held = k <= f < k + hold_a
        if not air:
            if f == k:
                air, vy, hold = 1, JUMP_V, 0
        else:
            hold += 1
            if not a_held and hold >= MIN_HOP and vy >= HOP_CUT:
                vy = HOP_CUT
        sipping = air_b and air
        tgt = SIP_SPD if sipping else RUN_SPD
        if speed < tgt:
            speed = min(tgt, speed + 0x10)
        elif speed > tgt:
            speed = max(tgt, speed - 0x18)
        dfix += speed
        if air:
            vy -= GRAVITY
            h += vy
            if h < 0:
                h, vy, air = 0, 0, 0
        dist = dfix >> 8
        for e in ents:
            if e[2]:
                e[1] += e[2]
            if e[3]:
                continue
            rel = (e[1] >> 8) - dist
            if abs(rel) < OB_HW[e[0]] and (h >> 8) < OB_H[e[0]]:
                return False
    return True


class _Runner(Policy):
    """Plans each hurdle with simulate(); subclasses decide on sipping."""
    sip = False
    air_sip = False
    margin = 3          # px of cop gap kept on top of COP_SEEN
    noise = 0           # +- frames of jump timing error
    miss = 0.0          # chance to fluff a hurdle entirely

    def __init__(self):
        self.g = None
        self.a_until = -1
        self.b_air = False
        self.fate = {}      # entity slot -> (timing error, fluffed?) rolled once per hurdle

    def gap_ok(self, s, frames):
        loss = frames * max(0, s.copspd - SIP_SPD) / 256 + 2
        return s.gap / 256 - loss >= COP_SEEN + self.margin

    def act(self, t, tel, rng):
        if self.g is None:
            self.g = getattr(self, "game", None) or _game()
        s = _State(self.g)
        if s.state != ST_RUN:
            self.a_until = -1
            return 0
        m = 0
        if t < self.a_until:
            m |= A
        if s.air:
            if self.b_air:
                m |= B
            return m
        self.b_air = False
        ahead = [e for e in s.ents if not e['flags'] & 1 and -20 < e['wx'] - s.dist < 170]
        if ahead:
            near = min(e['wx'] - s.dist for e in ahead)
            if near < 150 and not simulate(s, 99, 0, False, 60):
                live = {e['i'] for e in s.ents}
                for k in [k for k in self.fate if k not in live]:
                    del self.fate[k]
                key = min(ahead, key=lambda e: e['wx'] - s.dist)['i']
                if key not in self.fate:
                    self.fate[key] = (rng.randint(-self.noise, self.noise) if self.noise else 0,
                                      rng.random() < self.miss)
                m |= self.plan_jump(t, s, rng, *self.fate[key])
                return m
        # nothing to jump yet: sip on the ground if the cop can't see (and no bin)
        frames = (60 - s.prog + 2) // 3
        clear_run = not ahead or min(e['wx'] - s.dist for e in ahead) > 60 + frames
        if self.sip and clear_run and self.gap_ok(s, frames) and not s.bin_near(frames):
            m |= B
        return m

    def plan_jump(self, t, s, rng, err=0, fluff=False):
        want_b = self.air_sip and self.gap_ok(s, (60 - s.prog + 2) // 3 + 4)
        options = [(20, want_b), (20, False), (4, False)] if want_b else [(4, False), (20, False)]
        for hold_a, air_b in options:
            ok = [k for k in range(0, 24) if simulate(s, k, hold_a, air_b)]
            if not ok:
                continue
            if ok[0] != 0:
                return 0        # too early still
            run = 0
            while run + 1 in ok:
                run += 1
            # jump around the middle of the window (tolerant of a frame of lag)
            target = min(run, 2) if not self.noise else max(0, run // 2 + err)
            if run > target:
                return 0
            if fluff:
                return 0
            self.a_until = t + hold_a
            self.b_air = air_b
            return A | (B if air_b else 0)
        # no clean option: jump anyway when it's about to hit
        if not fluff and not simulate(s, 99, 0, False, 8):
            self.a_until = t + 20
            return A
        return 0


class cops_safe(_Runner):
    pass


class cops_pro(_Runner):
    sip = True
    air_sip = True


class cops_human(_Runner):
    sip = True
    air_sip = True
    margin = 12
    noise = 3
    miss = 0.06


class cops_rookie(_Runner):
    """First go: sloppy timing, fluffs one hurdle in four, sips now and then."""
    sip = True
    air_sip = False
    margin = 20
    noise = 6
    miss = 0.25


class cops_human15(Policy):
    """A decent human: sees the screen, not the RAM's future. Reacts to the
    cop ~15 frames late, jumps with +-4 frames of error, taps for low stuff
    and holds for bins (forgets one time in ten), sips in whole gulps."""
    REACT = 15
    JITTER = 4
    sip_margin = 14
    air_sip_chance = 0.6
    bin_careless = 0.25

    def __init__(self):
        self.g = None
        self.gaps = []          # cop gap history: what the player "sees" is REACT frames old
        self.press = None       # (frame to press A, frames to hold)
        self.a_until = -1
        self.b_until = -1
        self.b_air = False
        self.planned = set()

    def act(self, t, tel, rng):
        if self.g is None:
            self.g = getattr(self, "game", None) or _game()
        s = _State(self.g)
        self.gaps.append(s.gap)
        seen_gap = self.gaps[-self.REACT] if len(self.gaps) >= self.REACT else s.gap
        if s.state != ST_RUN:
            self.press, self.a_until, self.b_until = None, -1, -1
            return 0
        m = 0
        # a jump planned for this frame
        if self.press and t >= self.press[0] and not s.air:
            self.a_until = t + self.press[1]
            self.b_air = self.press[2]
            self.press = None
        if t < self.a_until:
            m |= A
        if s.air:
            if self.b_air and seen_gap / 256 >= COP_SEEN + 4:
                m |= B
            return m
        self.b_air = False
        # forget hurdles once they're behind you (their slots get reused)
        live = {e['i'] for e in s.ents if e['wx'] - s.dist > -10}
        self.planned &= live
        # next hurdle: plan the press once, when it's ~60-110 px out
        ahead = [e for e in s.ents if not e['flags'] & 3 and 0 < e['wx'] - s.dist < 170]
        if ahead and self.press is None:
            e = min(ahead, key=lambda e: e['wx'] - s.dist)
            key = e['i']
            if key not in self.planned and e['wx'] - s.dist < 110:
                self.planned.add(key)
                big = e['t'] == T_BIN
                if rng.random() < 0.1:
                    big = not big           # got it wrong
                hold = rng.randint(14, 24) if big else rng.randint(2, 7)
                air_b = (rng.random() < self.air_sip_chance and seen_gap / 256 >= COP_SEEN + self.sip_margin + 10)
                ok = [k for k in range(0, 60) if simulate(s, k, hold, air_b, 120)]
                if not ok:
                    ok = [k for k in range(0, 60) if simulate(s, k, hold, False, 120)]
                    air_b = False
                if ok:
                    # aim at the middle of the longest run of good frames
                    best, cur = [], []
                    for k in range(ok[0], ok[-1] + 2):
                        if k in ok:
                            cur.append(k)
                        else:
                            if len(cur) > len(best):
                                best = cur
                            cur = []
                    mid = best[len(best) // 2]
                else:
                    mid = max(0, e['wx'] - s.dist - 30) // 2
                k = max(0, mid + rng.randint(-self.JITTER, self.JITTER))
                self.press = (t + k, hold, air_b)
                self.b_until = -1
        # ground sip: commit to a gulp when the cop's (visibly) gone and the way is clear
        if t < self.b_until:
            if self.press and self.press[0] - t < 4:
                self.b_until = -1       # let go to jump
            else:
                return m | B
        if self.press is None or self.press[0] - t > 28:
            frames = (60 - s.prog + 2) // 3
            clear = not ahead or min(e['wx'] - s.dist for e in ahead) > 50 + frames
            careless = rng.random() < self.bin_careless
            if (clear and seen_gap / 256 >= COP_SEEN + self.sip_margin
                    and (careless or not s.bin_near(frames)) and rng.random() < 0.08):
                self.b_until = t + frames + 1
                m |= B
        return m


class hold_b_mash_a(Policy):
    trivial = True

    def act(self, t, tel, rng):
        return B | (A if t % 6 < 3 else 0)


class tap_a(Policy):
    """A short tap every 40 frames, whatever's coming."""
    trivial = True

    def act(self, t, tel, rng):
        return A if t % 40 < 4 else 0


POLICIES = {c.__name__: c for c in [cops_safe, cops_pro, cops_human, cops_rookie, cops_human15,
                                    hold_b_mash_a, tap_a]}
DEFAULTS = {'cops': ['idle', 'hold_b', 'hold_a', 'mash_a', 'hold_b_mash_a', 'tap_a', 'cops_jump', 'cops_safe',
                     'cops_pro', 'cops_human', 'cops_human15', 'cops_rookie', 'random_input']}
