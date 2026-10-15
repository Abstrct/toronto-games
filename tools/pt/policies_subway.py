"""TTC Surfing bots.

The no-skill ones (idle, hold_right, mash_a, random_input, subway_wiggle,
subway_mash) are exploit detectors: idle, hold_right and mash_a go PATIENT
ZERO; a blind left/right wiggle (Mo, round 9) must earn next to no style,
and mashing every way must not keep the dot gold (a tap only catches with
nothing else pressed for 8 frames).

The gold: a hold the solid arrow's way parks the dot in the white (the safe
STANDING SURF); a TAP its way (a fresh press) catches the dot toward 3 px
past the middle, so tapping on the arrow's white beat flash (4 frames in 16,
shown while the leg can still be a GOLD SURF: the ring's sweet spot glows
and the status says TAP) keeps it gold. From the third leg track joints
throw the dot 5 px; their slip is forgiven 8 frames longer.

subway_expert reads the true train force and the dot's velocity from RAM
and leans against both with a short prediction: frame-perfect balance.

subway_ace is the expert plus the undocumented trick (glide into a stop off
the pad), from its tell only: 69 frames out on a clean leg the ring starts
blinking gold with a tick every 8 frames; 15 frames on, the window opens:
let go between then and 29 frames on (a 14-frame window) and the brake
eases (the arrow goes, GLIDING IN..., a ding, the ring steady gold); stay
off the pad to the stop with the dot gold: +100. It is the ceiling the
default records are judged against, and plays the title demo
(demo_export POLICY['subway']).

subway_cue is subway_surfer plus that tell and nothing else: when the ring
starts blinking it gives the arrow one last tap and lets go. The acceptance
test is `pt.py curve subway -p subway_cue -l 12,15,18,20,24`, counting the
trick from the card's NO HANDS row (ev_style slot 4, 100 a stop).

subway_surfer is the human yardstick (the CURVE bot): it plans only from
what's on screen: the dot (its drift judged from the last few frames of
motion, not RAM velocity), the arrow (hollow, solid, its beat flash), the
gold glow and the status line. While the leg can be gold it taps on the
flash (skipping one when the dot is well over on its side, pressing when it
falls well behind, checking an overshoot), else it holds the arrow's way
and nudges the dot back with a dead zone. `pt.py curve subway` delays all
of that by a human reaction.

subway_human is subway_surfer with a built-in 15-frame (250 ms) hand.

subway_lena is Lena's round-9 test (pt5r9-subt-22267988) as a prompt-only
tapper: it never looks at the dot, taps the solid arrow's way every 16 (or
10) frames, 15 frames late. It must reach Union with some gold surfs.

subway_newbie is the round-5 first-timer (Dana): 20-frame hands, presses
the arrow's way as soon as any arrow shows and holds it, only pulls back
once the dot is red. subway_obey (and obey20 / obey25 / dana) is the
round-7 prompt test: holds the way the arrow points 20-25 frames late and
never looks at the dot. All of them must reach Union (a held lean settles
the dot in the white), and never land the trick by accident.

Every ride differs past TMU (the course is drawn from rng on the ride's first
frame, and run_bot seeds rng), and three of the last four legs carry a gag
(kinds 4 SIGNAL PROBLEMS and 5 BACKPACK) that the bots read like any lurch.
"""
import inspect

from policies import Policy, LEFT, RIGHT, UP, DOWN

# ev_ram layout (src/ev_subway.s)
W_BX, W_BY, W_VX, W_VY, W_FX, W_FY = 0, 2, 4, 6, 8, 10
W_SEG, W_SPEED, W_LS, W_LT, W_GERMS, W_GRAB, W_KIND, W_DUR = 16, 18, 24, 26, 28, 30, 34, 38
W_STATUS = 42                 # the HUD's status line (what it reads, as an index)
W_GOLD = 154                  # 1 = the leg can still be a GOLD SURF: the ring's sweet spot glows
W_EASE = 190                  # 1 = the brake eased (GLIDING IN..., the ring steady gold)
W_NHW = 200                   # 1 = the tell is up (the ring blinks gold, ticks)
ST_GLIDE = 16                 # "GLIDING IN...": the brake eased, the arrow's gone
BEAT = 16                     # the solid arrow flashes white 4 frames in 16 while the leg is gold
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
        r = self.g.core.peek(self.ev, 214)
        w = lambda o: r[o] | r[o + 1] << 8
        ls, status = r[W_LS], r[W_STATUS]
        solid = ls == LS_ACT and status != ST_GLIDE
        return {'x': (s16(w(W_BX)) / 256, s16(w(W_BY)) / 256),
                'v': (s16(w(W_VX)) / 256, s16(w(W_VY)) / 256),
                'f': (s16(w(W_FX)), s16(w(W_FY))),
                'ls': ls, 'lt': w(W_LT), 'kind': r[W_KIND], 'grab': w(W_GRAB),
                'speed': w(W_SPEED), 'seg': r[W_SEG], 'status': status,
                # what the screen shows: the solid arrow, its white beat flash,
                # the gold leg's glow, the tell (blinking / steady gold ring)
                'solid': solid, 'gold': r[W_GOLD],
                'flash': solid and r[W_GOLD] and ((r[W_DUR] - r[W_LT]) & (BEAT - 1)) < 4,
                'tell': r[W_NHW] and not r[W_EASE], 'eased': r[W_EASE]}


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


def arrow_btn(kind):
    """The pad button the solid arrow points to (against the push)."""
    ax, sg = PUSH[kind]
    if ax == 0:
        return RIGHT if sg < 0 else LEFT
    return DOWN if sg < 0 else UP


def arrow_btn_opp(kind):
    b = arrow_btn(kind)
    return {LEFT: RIGHT, RIGHT: LEFT, UP: DOWN, DOWN: UP}[b]


class subway_ace(subway_expert):
    """subway_expert plus the trick the card never mentions (NO HANDS), from
    its tell only: when the ring starts blinking gold (and ticking) it keeps
    riding for 15 frames, gives the arrow one last tap and lets go, and stays
    off the pad till the stop. Frame-perfect like the expert: the ceiling,
    and the title demo's player."""

    def act(self, t, tel, rng):
        m = super().act(t, tel, rng)
        s = self.read()
        if s['tell'] or s['eased']:
            if getattr(self, 'tell_t', None) is None:
                self.tell_t = t
            k = t - self.tell_t
            if k < 15:
                return m
            if k < 18:
                return arrow_btn(s['kind'])
            return 0
        self.tell_t = None
        return m


class subway_surfer(_Reader):
    """Human-like: the dot's position, its drift judged from motion, and the
    on-screen cues, nothing else. Off the solid arrow it nudges the dot back
    to the middle (a dead zone, the way a person nudges). On the solid arrow
    it does what the card says: while the leg can still be a GOLD SURF (the
    ring's sweet spot glows, the status says TAP) it taps the arrow's way on
    each white flash of the arrow, skipping a flash when the dot is well over
    on its side and pressing when it falls well behind; once the gold has gone
    it holds the arrow's way (the safe STANDING SURF), correcting the dot.
    The other axis it nudges back. `pt.py curve subway` delays all of it by a
    human reaction."""
    look = 10
    dz = 2.5
    dz_off = 4.5
    tap_max = 1
    behind = -6.5

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
        if not s['solid']:
            return steer(x, v, (0, 0), self.look, self.dz)
        ax, sg = PUSH[s['kind']]
        push = [0, 0]
        push[ax] = sg
        if not s['gold']:
            return steer(x, v, push, self.look, self.dz)
        # gold: the push's axis by taps on the beat; the other axis only
        # when the dot's running well off (the rider finds their feet)
        m = steer(x, v, (0, 0), self.look, self.dz_off)
        m &= (UP | DOWN) if ax == 0 else (LEFT | RIGHT)
        btn = arrow_btn(s['kind'])
        xa, va = -sg * x[ax], -sg * v[ax]
        pred = xa + va * self.look
        if (s["flash"] and pred < self.tap_max) or pred < self.behind:
            m |= btn
        elif pred > 5.5:                    # running off the arrow's side: check it
            m |= arrow_btn_opp(s['kind'])
        return m


class subway_cue(subway_surfer):
    """subway_surfer that has learned the tell for the undocumented trick
    and nothing else about it: when the ring starts blinking gold (a tick
    every 8 frames) it gives the arrow one last tap and lets go of the pad
    till the stop. It never reads the trick's own state (the window, the
    frames off the pad): only the tell's on-screen state. `pt.py curve subway
    -p subway_cue -l 12,15,18,20,24` must land the trick on most stops it is
    offered at 15-20 frames."""

    def act(self, t, tel, rng):
        m = super().act(t, tel, rng)
        s = self.read()
        if s['tell'] or s['eased']:
            if getattr(self, 'tell_t', None) is None:
                self.tell_t = t
            return arrow_btn(s['kind']) if t - self.tell_t < 3 else 0
        self.tell_t = None
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





class subway_wiggle(Policy):
    """Mo's round-9 exploit check: a blind left/right wiggle, holding each
    way 20 frames, never looking at the train. It must not earn style."""
    trivial = True

    def act(self, t, tel, rng):
        return LEFT if (t // 20) % 2 else RIGHT


class subway_wiggle_tap(Policy):
    """The same wiggle as taps: tap left, 20 frames, tap right, 20 frames."""
    trivial = True

    def act(self, t, tel, rng):
        k = t % 46
        return LEFT if k < 3 else RIGHT if 23 <= k < 26 else 0


class subway_lena(Policy):
    """Lena's round-9 tap test (pt5r9-subt-22267988): never looks at the dot,
    taps the solid arrow's way (3 frames down) every `every_n` frames while
    it's up, 15 frames late. With TAP TO STAY GOLD the card said this works;
    it went PATIENT ZERO. It must reach Union with gold surfs."""
    period = 16
    delay = 15

    def act(self, t, tel, rng):
        q = getattr(self, 'q', None)
        if q is None:
            q = self.q = []
            self.g = getattr(self, 'game', None) or find_game()
            self.ev = self.g.sym['ev_ram']
            self.k = 0
        r = self.g.core.peek(self.ev, 44)
        m = 0
        if r[W_LS] == LS_ACT and r[W_STATUS] != ST_GLIDE:
            m = arrow_btn(r[W_KIND]) if self.k % self.period < 3 else 0
            self.k += 1
        else:
            self.k = 0
        q.append(m)
        return q.pop(0) if len(q) > self.delay else 0


class subway_lena10(subway_lena):
    period = 10





class subway_mash(Policy):
    """Exploit check for the tap catch: mashes all four directions in turn
    (2 frames each), never looking. A tap only ever catches the dot toward
    the middle (or the arrow's side), so this must not keep it gold."""
    trivial = True

    def act(self, t, tel, rng):
        return (RIGHT, 0, LEFT, 0, UP, 0, DOWN, 0)[(t // 2) % 8]


class subway_mash_lr(Policy):
    """The same, left and right only."""
    trivial = True

    def act(self, t, tel, rng):
        return (RIGHT, 0, LEFT, 0)[(t // 2) % 4]


POLICIES = {c.__name__: c for c in (subway_expert, subway_ace, subway_surfer, subway_cue, subway_human, subway_newbie,
                                    subway_obey, subway_obey20, subway_obey25, subway_dana,
                                    subway_wiggle, subway_wiggle_tap, subway_lena, subway_lena10, subway_mash, subway_mash_lr)}
DEFAULTS = {'subway': ['idle', 'hold_right', 'mash_a', 'random_input', 'subway_wiggle', 'subway_mash', 'subway_newbie',
                       'subway_dana', 'subway_obey', 'subway_lena', 'subway_human', 'subway_cue', 'subway_expert', 'subway_ace']}
CURVE = {'subway': 'subway_surfer'}
