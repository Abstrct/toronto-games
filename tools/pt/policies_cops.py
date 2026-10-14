"""Tallboy Trot bots.

Most skilled ones read event RAM (they find the running `Game` on the call
stack, since `run_bot` has no hook) and plan jumps with a frame-exact copy of
the event's physics (src/ev_cops.s):

  cops_safe   perfect hurdling, never sips: the "just run" line
  cops_pro_rt perfect hurdling, sips whenever the cop is off-screen and the
              BUZZ has room, times air sips over hurdles for SIP 'N' HOPs
  cops_human  cops_pro_rt with reaction noise, a cautious sip buffer and the
              odd missed jump
  cops_rookie first go: sloppy timing, fluffs one hurdle in four
  cops_human15  a decent human, modelled from the outside in: ~15-frame
              reaction to the cop, +-4 frames of jump timing, taps A for the
              low stuff and holds it for bins (and sometimes forgets), sips
              in committed 20-frame gulps, now and then next to a bin
  cops_eyes   the CURVE bot: plays only from what's on screen. It jumps when
              the runner reaches an obstacle's chalk take-off mark (tap for a
              yellow one, hold for red), reads the cop from his sprite and
              the HUD meter, sips in whole gulps when the way's clear and the
              cop's well back, and sips through the jump for SIP 'N' HOPs.
              No physics model, no look into RAM's future; `pt curve` adds
              the hand's latency on top.
  cops_pro    the expert (and the title demo): cops_eyes with a frame of
              anticipation error, cutting it fine with the cop and the BUZZ
              budget, and taking the big hurdles on LIQUID COURAGE (the
              undocumented trick) when a ground gulp sets it up
  cops_ace    the best run we know: cops_pro with near-perfect anticipation
              that rides the BUZZ high for LIQUID COURAGE (the undocumented trick)
  cops_firstgo  cops_noob who never sips (Dana's chalk-only first go)
  cops_prompt a first-timer who obeys only on-screen prompts, no
              anticipation (`pt curve -p cops_prompt -l 20,22,25`)
  cops_allsip sips over every hop, never minds the BUZZ (it goes red)
  cops_gold   plays the undocumented trick off its tell alone: the BUZZ meter's
              colour on the HUD (gold just under the red). `python3
              tools/pt/policies_cops.py gold 10,12,15` counts how often it lands
  cops_lost   Marcus's lost first-timer (20-30 frame hand): must beat mash_a
  cops_noob   an honest first-timer: +-5 frames off the chalk, freezes on one
              hurdle in four, sips without minding the BUZZ (run it through
              `pt curve -p cops_noob -l 15,24`: it should outlast the 30 s
              warm-up and bank a few hundred points when it's busted)

Every take-off pays up to 40 (minus a point per 1.6 px from the chevron,
nothing 64 px past it), and ON THE CHALK (8 px short .. 20 px past) doubles a
SIP 'N' HOP, DEAD ON triples it. So the curve slopes all the way from 0 to
~20 frames of hand latency. A late hand that runs into a hurdle stops against
it for 24 frames, and its A (on seeing the stop) scrambles over (no spill).

The no-skill exploit detectors (idle, hold_a, hold_b, mash_a) come from
policies.py; `hold_b_mash_a` (sip + bunny-hop forever) and `tap_a` (a short
tap every 40 frames) are new ones.
"""
import inspect
import os
import sys

from policies import Policy, A, B

RUN_SPD, SIP_SPD, TRIP_SPD = 0x200, 0xE0, 0x80
JUMP_V, GRAVITY, MIN_HOP, HOP_CUT = 0x3C0, 0x20, 8, 0x180
COP_SEEN = 110
GAP_MAX = 176
OB_HW = [0, 10, 10, 8, 8]
OB_H = [0, 12, 10, 30, 9]
MK_D = [0, 54, 56, 76, 79]      # chalk take-off marks (src/ev_cops.s mk_d)
PLAYER_SX = 104
T_BIN, T_COON = 3, 4
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
        b = g.core.peek(base, 344)
        self.dist, self.distf, self.speed = _w(b, 0), _w(b, 2), _w(b, 4)
        self.h, self.vy = _w(b, 6), _w(b, 8, True)
        self.air, self.state, self.prog = b[10], b[12], b[18]
        self.buzz = b[20]
        self.gap, self.copspd = _w(b, 24), _w(b, 26)
        self.hold = _w(b, 46)
        self.t = _w(b, 52)
        self.chain, self.chaint = b[54], _w(b, 56)
        self.bump = b[268]          # up against a hurdle (you see the runner stop dead)
        self.style = _w(b, 258)
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
        tgt = RUN_SPD           # an air sip keeps your momentum
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
    ground_buzz = 60    # BUZZ below this: room for a ground sip (save the rest for SIP 'N' HOPs)
    air_buzz = 120      # ...for a SIP 'N' HOP (176+ is TIPSY: the cop closes in)
    react = 12          # frames to notice you've stopped dead against a hurdle

    def __init__(self):
        self.g = None
        self.bumped = 0
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
        # stopped dead against a hurdle: hit A once you've noticed
        if s.bump and not s.air:
            self.bumped = self.bumped or t
            if t - self.bumped >= self.react and t >= self.a_until:
                self.a_until = t + 6
                return A
            return m
        self.bumped = 0
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
        if (self.sip and clear_run and self.gap_ok(s, frames) and not s.bin_near(frames)
                and s.buzz < self.ground_buzz):
            m |= B
        return m

    def plan_jump(self, t, s, rng, err=0, fluff=False):
        want_b = self.air_sip and self.gap_ok(s, (60 - s.prog + 2) // 3 + 4) and s.buzz < self.air_buzz
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


class cops_pro_rt(_Runner):
    """The old RAM planner (jump windows from a physics copy), sipping too."""
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


class cops_eyes(Policy):
    """The CURVE bot: a player who only knows what the screen shows.

    - Obstacles: it sees each one (and its chalk take-off mark) once it's on
      screen, and jumps when the runner reaches the mark: a tap (~8 frames of A)
      for a yellow mark, a hold (~22 frames) for a red one. Its own anticipation
      is off by up to +-2 frames; `pt curve` adds the hand's latency.
    - The cop: it reads the HUD COP meter (16 steps) and whether his bike is on
      screen. Ground gulps only when the meter is low; air sips when he's out of
      sight.
    - Sips: whole gulps (B for ~22 frames), never when a mark is coming up
      within ~45 frames or a green bin is close (sometimes it forgets).
    """
    TAP, HOLD, GULP = 8, 22, 22
    ERR = 2                     # anticipation error, frames
    BIAS = 0                    # habitually early (+) or late (-), frames
    ground_q = 3                # HUD cop meter at or below this: a ground gulp is safe
    air_q = 5                   # ...at or below this (and he's off screen): sip through the jump
    ground_buzz = 2             # HUD buzz meter (16 steps) at or below this: room for a ground gulp
    air_buzz = 5                # ...for a sip over crates or a bench (10+ is TIPSY: the cop gains)
    air_buzz_big = 7            # ...over a bin or a raccoon (they pay double)
    careless = 0.1
    courage = False             # gulps on the ground to take a big hurdle at BUZZ 128+
    miss = 0.0                  # chance to freeze on a hurdle and not jump at all
    sips = True
    scramble = True             # hits A when the runner stops dead against a hurdle

    def __init__(self):
        self.g = None
        self.done = {}          # slot -> wx when we jumped for it
        self.err = {}           # slot -> this hurdle's anticipation error (frames)
        self.a_until = self.b_until = -1

    @staticmethod
    def cop_q(s):
        q = ((GAP_MAX - min(GAP_MAX, s.gap >> 8)) * 13) >> 7
        return min(16, q)

    def act(self, t, tel, rng):
        if self.g is None:
            self.g = getattr(self, "game", None) or _game()
        s = _State(self.g)
        if s.state != ST_RUN:
            self.a_until = self.b_until = -1
            self.done.clear()
            return 0
        q = self.cop_q(s)
        cop_on_screen = (s.gap >> 8) <= PLAYER_SX + 20
        # what's ahead: live hurdles not yet passed or hit, nearest mark first
        ahead = []
        for e in s.ents:
            if e['flags'] & 0x0B:
                continue
            rel = e['wx'] - s.dist
            if rel < -16 or PLAYER_SX + rel - MK_D[e['t']] > 264:
                continue        # behind us, or its mark isn't on screen yet
            ahead.append((rel - MK_D[e['t']], rel, e))
        ahead.sort(key=lambda a: a[0])
        live = {e['i'] for _, _, e in ahead}
        for k in [k for k in self.done if k not in live]:
            del self.done[k]
        m = 0
        if t < self.a_until:
            m |= A
        if t < self.b_until:
            m |= B
        # stopped dead against a hurdle: anyone hits A (it lands a hand's latency later)
        if s.bump and not s.air and t >= self.a_until and self.scramble:
            self.a_until = t + 6
            return m | A
        if s.air or t < self.a_until:
            return m
        for to_mark, rel, e in ahead:
            if e['i'] in self.done:
                continue
            closing = 2 + (0.625 if e['t'] == T_COON else 0)
            if e['i'] not in self.err:
                self.err[e['i']] = rng.uniform(-self.ERR, self.ERR) + self.BIAS
            if to_mark <= self.err[e['i']] * closing:
                del self.err[e['i']]
                self.done[e['i']] = e['wx']
                if rng.random() < self.miss:
                    return m        # froze: runs straight into it
                hold = self.HOLD if e['t'] == T_BIN else self.TAP
                self.a_until = t + hold + rng.randint(-2, 2)
                m |= A
                room = self.air_buzz_big if e['t'] in (T_BIN, T_COON) else self.air_buzz
                if self.sips and q <= self.air_q and not cop_on_screen and s.buzz >> 4 <= room:
                    # let go of both together for a big jump, well after A for a hop: two
                    # releases a frame or two apart can land in either order on a late hand
                    self.b_until = self.a_until if e['t'] == T_BIN else t + self.GULP
                    m |= B
                else:
                    self.b_until = -1
                    m &= ~B
                return m
            break
        # a ground gulp when the coast is clear
        if t >= self.b_until:
            nxt = min((a[0] for a in ahead if a[2]['i'] not in self.done), default=999)
            bin_close = any(e['t'] == T_BIN and -30 < rel < 90 for _, rel, e in ahead)
            if (self.sips and nxt > 90 and q <= self.ground_q and not cop_on_screen and s.buzz >> 4 <= self.ground_buzz
                    and (not bin_close or rng.random() < self.careless / 20)):
                self.b_until = t + self.GULP
                m |= B
            elif self.sips and self.courage and q <= self.ground_q and not cop_on_screen and not bin_close:
                # a gulp now that leaves the BUZZ at 128..170 when we take off for
                # the bin or raccoon coming up: its SIP 'N' HOP is LIQUID COURAGE
                big = [a for a in ahead if a[2]['i'] not in self.done]
                if big and big[0][2]['t'] in (T_BIN, T_COON) and 90 < big[0][0] < 240:
                    frames = self.GULP + big[0][0] / 2
                    if 130 <= s.buzz + 56 - frames / 4 <= 170:
                        self.b_until = t + self.GULP
                        m |= B
        return m


class cops_noob(cops_eyes):
    """An honest first-timer (run it with a 15-24 frame hand): jumps a few
    frames off the chalk either way, freezes on one hurdle in four, sips
    now and then and doesn't watch the BUZZ."""
    ERR = 5
    miss = 0.25
    careless = 0.5
    ground_q, air_q = 2, 4
    ground_buzz, air_buzz, air_buzz_big = 15, 15, 15

    def act(self, t, tel, rng):
        # sips without minding the BUZZ until the meter first goes red (and
        # TIPSY! / SLOSHED! comes up): from then on, only while it's pink
        if self.g is not None and self.ground_buzz > 10 and self.g.core.peek(self.g.sym['ev_ram'] + 20, 1)[0] >= 176:
            self.ground_buzz, self.air_buzz, self.air_buzz_big = 6, 8, 9
        return super().act(t, tel, rng)


class cops_firstgo(cops_noob):
    """Dana's first go: cops_noob who never touches B (run it with a 15-20 frame hand)."""
    sips = False


class cops_pro(cops_eyes):
    """The expert: cops_eyes with an expert's anticipation (a frame either
    way), cutting it fine with the cop (sips the moment he's out of sight) and
    the buzz."""
    ERR = 1
    ground_q, air_q = 4, 6
    ground_buzz, air_buzz, air_buzz_big = 2, 6, 10
    courage = True


class cops_ace(cops_pro):
    """The best run we know: cops_pro who knows the undocumented trick. A SIP
    'N' HOP's base is 8 + a point for every 16 BUZZ you had before the sip
    (LIQUID COURAGE from 128 up, 4 more on the base), so it rides the meter
    just under the red and takes the big hurdles on courage."""
    ERR = 0.5
    ground_buzz, air_buzz, air_buzz_big = 4, 10, 10


class cops_prompt(Policy):
    """A first-timer who reads the intro card once and from then on does only
    what the screen says (run it through `pt curve -p cops_prompt -l 20,22,25`:
    the hand's latency is all the timing it has, no anticipation at all).

    - Hurdles: the card says yellow chalk = tap A, red chalk = hold A. It
      decides to jump when the chevron reaches the runner's feet.
    - Stopped dead against a hurdle: does nothing until a callout says to
      tap A, then taps it.
    - Sips: only once a callout has said HOLD B; then a gulp whenever the cop
      is off screen and nothing's close, until TIPSY / SLOSHED / the cop's
      watching says stop (and again once the BUZZ meter is out of the red).
      SIP 'N' HOPs only after a callout has said B mid-air.
    """
    TAP, HOLD, GULP = 8, 22, 24

    def __init__(self):
        self.g = None
        self.done = set()
        self.a_until = self.b_until = -1
        self.sip_ok = self.air_ok = False
        self.stop = False
        self.last = ''
        self.scram = False

    def popup(self):
        return ' '.join(r.strip(' .') for r in self.g.text_rows()[8:13])

    def act(self, t, tel, rng):
        if self.g is None:
            self.g = getattr(self, "game", None) or _game()
        s = _State(self.g)
        if s.state != ST_RUN:
            self.a_until = self.b_until = -1
            return 0
        txt = self.popup() if t % 2 == 0 else self.last
        fresh = txt != self.last
        self.last = txt
        if fresh:
            if 'HOLD B' in txt and "DON'T" not in txt:
                self.sip_ok, self.stop = True, False
                if not s.air and not s.bump:
                    self.b_until = t + self.GULP
            if 'MID-AIR' in txt:
                self.air_ok = True
            if any(w in txt for w in ("DON'T SIP", 'TIPSY', 'SLOSHED', 'SAW THAT')):
                self.stop = True
                self.b_until = -1
            self.scram = 'SCRAMBLE' in txt and 'TAP A' in txt
        if self.stop and s.buzz < 176 and (s.gap >> 8) > PLAYER_SX + 20:
            self.stop = False       # the meter's pink again and he's gone
        m = 0
        if t < self.a_until:
            m |= A
        if t < self.b_until:
            m |= B
        if s.bump and not s.air:
            if self.scram and t >= self.a_until:
                self.a_until = t + 6
                return A
            return m & ~B
        if s.air or t < self.a_until:
            return m
        cop_seen = (s.gap >> 8) <= PLAYER_SX + 20
        for e in s.ents:
            if e['flags'] & 0x1B or e['i'] in self.done:
                continue
            to_mark = e['wx'] - s.dist - MK_D[e['t']]
            if -24 < to_mark <= 0:
                self.done.add(e['i'])
                self.a_until = t + (self.HOLD if e['t'] == T_BIN else self.TAP)
                m |= A
                if self.air_ok and self.sip_ok and not self.stop and not cop_seen:
                    self.b_until = t + self.GULP
                    m |= B
                else:
                    self.b_until = -1
                    m &= ~B
                return m
        live = {e['i'] for e in s.ents if not e['flags'] & 0x1B}
        self.done &= live
        if self.sip_ok and not self.stop and t >= self.b_until and not cop_seen:
            near = min((e['wx'] - s.dist for e in s.ents if not e['flags'] & 0x1B and e['wx'] - s.dist > -10),
                       default=999)
            if near > 150 and rng.random() < 0.03:
                self.b_until = t + self.GULP
                m |= B
        return m


class cops_lost(cops_noob):
    """Marcus's lost first-timer (run it with a 20-30 frame hand): the chalk
    means little to it (jumps up to 8 frames off it), it freezes on a third of
    the hurdles and runs into them, often forgets to hold A for a bin, and
    sips now and then without minding the cop's meter. Its real but clumsy
    attempt should still beat a masher (`mash_a`, `random_input`)."""
    ERR = 8
    miss = 0.33
    careless = 0.5
    ground_q, air_q = 6, 8

    def act(self, t, tel, rng):
        m = super().act(t, tel, rng)
        # a tap where a bin wanted a hold, half the time
        if m & A and t >= self.a_until - 1 and self.a_until - t > 12 and rng.random() < 0.5:
            self.a_until = t + self.TAP
        return m


class cops_gold(cops_eyes):
    """The tell's proof: a player who has noticed that the BUZZ meter turns
    gold (and the can glows) just under the red, and plays on that alone. It
    reads the meter from the HUD's text layer (its colour and fill), never the
    BUZZ itself:
    - pink: gulp on the ground (cop off screen, nothing close) to fill it up;
    - gold: stop gulping; sip through the next hop (the cop off screen);
    - red: no sips until it's pink again.
    `tries` counts hops it took with B on a gold meter, `landed` the ones that
    paid the undocumented trick (read from RAM afterwards, only to score the
    bot: `python3 tools/pt/policies_cops.py gold`)."""
    ERR = 2

    def __init__(self):
        super().__init__()
        self.tries = self.landed = 0
        self.watch = None       # c_brave when we took off on gold

    def meter(self):
        tm = self.g.core.peek(self.g.sym['txt_map'] + (1 * 32 + 16) * 2, 8)
        pal = (tm[1] >> 2) & 7
        fill = sum(max(0, min(4, tm[2 * i] - 73)) for i in range(4))
        return {7: 'pink', 1: 'gold', 2: 'red'}.get(pal, 'pink'), fill

    def act(self, t, tel, rng):
        if self.g is None:
            self.g = getattr(self, "game", None) or _game()
        s = _State(self.g)
        brave = _w(self.g.core.peek(self.g.sym['ev_ram'] + 340, 2), 0)
        if self.watch is not None:
            if s.air:
                self.flew = True
            elif self.flew or t > self.watch_t + 90:
                self.landed += brave > self.watch
                self.watch = None
        col, fill = self.meter()
        # what the hand will do: gulp on pink, hop-sip on gold, nothing on red
        self.ground_buzz = 16 if col == 'pink' else -1
        self.air_buzz = self.air_buzz_big = 16 if col == 'gold' else -1
        self.air_q = 16 if col == 'gold' else 6
        took_off = t >= self.a_until
        # cops_eyes judges room from s.buzz >> 4: give it only what the meter shows
        m = self._act_seen(t, tel, rng, fill)
        if took_off and t < self.a_until and m & B and col == 'gold':
            self.tries += 1
            self.watch, self.watch_t, self.flew = brave, t, False
        return m

    def _act_seen(self, t, tel, rng, fill):
        orig = _State.__init__

        def seen(st, g, _orig=orig):
            _orig(st, g)
            st.buzz = fill << 4
        _State.__init__ = seen
        try:
            return cops_eyes.act(self, t, tel, rng)
        finally:
            _State.__init__ = orig


class cops_allsip(cops_eyes):
    """Dana's "sip on every hop": an air sip over every hurdle the cop can't
    see, never one on the ground, never minding the BUZZ. It should hit the
    red within ~10 hops and get SLOSHED: always sipping is a choice that costs."""
    ground_buzz = -1
    air_buzz = air_buzz_big = 16
    air_q = 16


POLICIES = {c.__name__: c for c in [cops_safe, cops_pro, cops_pro_rt, cops_human, cops_rookie, cops_human15, cops_eyes, cops_noob, cops_firstgo, cops_ace, cops_prompt, cops_allsip, cops_gold, cops_lost,
                                    hold_b_mash_a, tap_a]}
DEFAULTS = {'cops': ['idle', 'hold_b', 'hold_a', 'mash_a', 'hold_b_mash_a', 'tap_a', 'cops_jump', 'cops_safe',
                     'cops_pro', 'cops_human', 'cops_human15', 'cops_eyes', 'cops_rookie', 'random_input']}
CURVE = {'cops': 'cops_eyes'}


if __name__ == '__main__' and sys.argv[1:2] == ['gold']:
    # the tell's proof: cops_gold at a 10-15 frame hand lands the undocumented
    # trick more often than not when it goes for it
    import random as _r
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import pt
    lats = [int(x) for x in (sys.argv[2] if len(sys.argv) > 2 else '10,12,15').split(',')]
    n = int(sys.argv[3]) if len(sys.argv) > 3 else 6
    for lat in lats:
        T = L = 0
        sc = []
        for seed in range(1, n + 1):
            pol = cops_gold()
            g = pt.Game()
            pol.game = g
            pt.goto_target(g, 'cops')
            rng = _r.Random(seed)
            g.core.poke(g.sym['rng'], bytes([rng.randrange(1, 256), rng.randrange(256)]))
            hrng = _r.Random(seed * 7919 + 1)
            pending, hold, want = [], 0, 0
            for t in range(60 * 120):
                m = pol.act(t, g.last, rng)
                if m != want and hrng.random() >= 0.03:
                    want = m
                    due = t + max(0, lat + hrng.randint(-(lat // 4), lat // 4))
                    if pending:
                        due = max(due, pending[-1][0] + 1)
                    pending.append((due, m))
                while pending and pending[0][0] <= t:
                    hold = pending.pop(0)[1]
                g.step(1, hold)
                if t % 15 == 0 and t > 60 and not g.scene().startswith('cops.play'):
                    break
            g.step(300, 0)
            sc.append(g.state(full=False)['ev_score'])
            T += pol.tries
            L += pol.landed
            g.core.close()
        print('latency %2d: went for it %3d times, landed %3d (%.0f%%); scores %s'
              % (lat, T, L, 100.0 * L / max(1, T), sc))
