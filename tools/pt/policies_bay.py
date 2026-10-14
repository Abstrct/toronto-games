"""Bay St Power Walk bots.

The event is a rhythm game on "Whelp, I'm Alive" (15 frames an 8th note). The
walk is on the BEAT, the big dots (every quarter note, 30 frames): PERFECT is
the landing frame -2..+3 (a press read the frame after the landing scores 0,
the landing frame itself -1), GOOD -4..+5, EARLY/LATE (a short stride) out
to the edge of the 8th. A beat is only missed when neither its 8th nor the "and" after it got a
step. DOUBLE TIME: a good step on the beat and another on the small dot after
it is a longer stride and twice the style. The song starts on the first frame
of control, so 8th k lands at t = 15k + PHASE; k % 8 == 0 is a bar's downbeat
(the gold PRESTO dot, Y).

`bay_ear` is the curve bot: it reads only the screen (the dots in OAM) and
taps as each dot lands, without pre-compensating pt's hand latency. The older
bots (`bay_beat` family) step on every 8th from RAM timing.
"""
import collections
import inspect

B, Y, SELECT, START, UP, DOWN, LEFT, RIGHT, A, X, L, R = (1 << i for i in range(12))

PHASE = 1           # t % 15 that scores dead centre (measured: holds starting at t land at ph = t)
TAP = 3             # frames a tap is held

# event RAM layout (src/ev_bay.s)
NUM_ENT = 20
E_TYPE, E_WX, E_LANE = 64, 64 + 40, 64 + 4 * 40
E_V = 64 + 3 * 40
E_FLAGS = 64 + 8 * 40
T_SUIT, T_TOURIST, T_ZOMBIE, T_JOGGER, T_PIGEON, T_CART, T_BOARD = 1, 2, 3, 4, 5, 6, 7


def _game():
    f = inspect.currentframe()
    while f:
        g = f.f_locals.get('g')
        if g is not None and hasattr(g, 'core') and hasattr(g, 'sym'):
            return g
        f = f.f_back
    return None


class Policy:
    every = 1

    def act(self, t, tel, rng):
        return 0


class _Eyes:
    """Reads the street: who is in which lane how far ahead."""

    def __init__(self, owner):
        self.owner = owner
        self.g = None
        self.base = None

    def look(self):
        if self.g is None:
            self.g = getattr(self.owner, "game", None) or _game()
            if self.g is None:
                return None
            self.base = self.g.sym.addr.get('ev_ram', 0x1018) if hasattr(self.g.sym, 'addr') \
                else self.g.sym['ev_ram']
        ram = self.g.core.peek(self.base, 512)
        w = lambda o: ram[o] | ram[o + 1] << 8
        me = dict(dist=w(0), lane=ram[6], state=ram[14], cd=w(26), speed=w(4) / 256.0)
        ents = []
        for i in range(NUM_ENT):
            typ = ram[E_TYPE + 2 * i]
            if not typ or typ == T_PIGEON or typ > T_BOARD:
                continue
            ents.append(dict(type=typ, wx=w(E_WX + 2 * i), lane=ram[E_LANE + 2 * i],
                             flags=ram[E_FLAGS + 2 * i], v=w(E_V + 2 * i) / 256.0))
        return me, ents


def _rel(e, me):
    return (e['wx'] - me['dist'] + 0x8000) % 0x10000 - 0x8000


class bay_beat(Policy):
    """A good player: steps on the beat (human jitter), excuse-me's walkers
    and sidesteps carts, boards and joggers."""
    jitter = 1.2        # sd of tap timing, frames
    bias = 0            # mean lateness, frames
    miss = 0.0          # chance to drop a beat
    react = 40          # px ahead at which it reacts
    period = 15         # frames between taps
    offset = 0
    prefer_lanes = False
    presto = False
    delay = 0           # frames the eyes lag behind the game
    blind_spot = 0.0    # chance not to notice a given obstacle

    def __init__(self):
        self.eyes = _Eyes(self)
        self.next_tap = None
        self.k_plan = None
        self.foot = LEFT
        self.tap_until = -1
        self.tap_mask = 0
        self.lane_hold = -1
        self.lane_mask = 0
        self.excuse_at = -100
        self.hist = collections.deque()
        self.ignored = set()
        self.seen = set()

    def plan_tap(self, t, rng):
        # the next beat after the last one planned (an early tap must not
        # plan the same beat twice)
        k = (t - PHASE - self.offset) // self.period + 1
        if self.k_plan is not None:
            k = self.k_plan + 1
        self.k_plan = k
        nominal = PHASE + self.offset + k * self.period
        self.next_tap = nominal + int(round(rng.gauss(self.bias, self.jitter)))
        self.next_k = (nominal - PHASE) // 15 if self.period == 15 else None
        if self.next_tap <= t:
            self.next_tap = t + 1

    def view(self, t):
        seen = self.eyes.look()
        if not seen:
            return None
        if not self.delay:
            return seen
        self.hist.append(seen)
        while len(self.hist) > self.delay + 1:
            self.hist.popleft()
        me_now, me_then = seen[0], self.hist[0][0]
        # the street (and where I was in it) as it was `delay` frames ago;
        # my lane is what I last pressed
        me = dict(me_then, lane=me_now['lane'])
        return me, self.hist[0][1]

    def steer(self, t, rng):
        if self.react <= 0:
            return 0
        seen = self.view(t)
        if not seen:
            return 0
        me, ents = seen
        for e in ents:
            e['rel'] = _rel(e, me)
            key = (e['type'], e['wx'] // 64, e['lane'])
            if self.blind_spot and key not in self.seen:
                self.seen.add(key)
                if rng.random() < self.blind_spot:
                    self.ignored.add(key)
            e['ignored'] = key in self.ignored
        ahead = [e for e in ents if e['lane'] == me['lane'] and -2 < e['rel'] < self.react
                 and not e['flags'] & 0x0C and e['type'] != T_JOGGER and not e['ignored']]
        behind = [e for e in ents if e['type'] == T_JOGGER and e['lane'] == me['lane'] and -72 < e['rel'] < 0
                  and not e['flags'] & 0x04 and not e['ignored']]
        if not ahead and not behind:
            return 0

        def busy(lane):
            return any(e['lane'] == lane and -16 < e['rel'] < self.react + 16 and not e['flags'] & 0x0C
                       for e in ents)
        options = [l for l in (me['lane'] - 1, me['lane'] + 1) if 0 <= l <= 2 and not busy(l)]
        walkers = ahead and all(e['type'] < T_JOGGER for e in ahead) and not behind
        can_excuse = walkers and t - self.excuse_at > 42 and any(e['rel'] < 60 for e in ahead)
        if can_excuse and not (self.prefer_lanes and options):
            self.excuse_at = t
            return A
        if not options:
            return 0
        to = rng.choice(options)
        return UP if to < me['lane'] else DOWN

    def act(self, t, tel, rng):
        m = 0
        if self.next_tap is None:
            self.plan_tap(t, rng)
        if t >= self.next_tap:
            if rng.random() >= self.miss:
                self.tap_mask = self.foot
                if self.presto and self.next_k is not None and self.next_k % 8 == 0:
                    self.tap_mask |= Y
                self.tap_until = t + TAP
                self.foot = RIGHT if self.foot == LEFT else LEFT
            self.plan_tap(t + 2, rng)
        if t < self.tap_until:
            m |= self.tap_mask
        # lanes / excuse me: every few frames, on its own thumb
        if t < self.lane_hold:
            m |= self.lane_mask
        elif t % 4 == 0:
            s = self.steer(t, rng)
            if s:
                self.lane_mask = s
                self.lane_hold = t + 3
                m |= s
        elif self.delay:
            self.view(t)        # keep the memory rolling
        return m


def _hand_latency():
    """The reaction latency pt's human hand adds to every input (pt.py run_bot's
    `latency` local; 0 outside `pt.py curve`)."""
    f = inspect.currentframe()
    while f:
        if f.f_code.co_name == 'run_bot' and 'latency' in f.f_locals:
            return int(f.f_locals['latency'] or 0)
        f = f.f_back
    return 0


class bay_hand(Policy):
    """The curve bot: a person with a pad, not a RAM reader.

    `pt.py curve` delays every input by the hand's reaction latency L. Beat taps
    aren't reactions (you hear the song coming and anticipate it), so this bot
    sends its steps L frames early and pt's delay lands them back on the beat.
    What's left is human rhythm: timing noise (sd 0.7 + 0.16 L frames: 3.1 at
    L = 15, plus pt's own +-L/4 hand jitter), a slowly wandering sense of the
    beat (AR(1) drift, sd ~0.08 L; about 3.9 frames all told at L = 15), and the odd dropped beat. L doubles as the
    skill knob: an L = 0 hand is the expert.

    Hazards ARE reactions: lane changes and EXCUSE ME are decided from what is
    on screen now (people visible ahead in your lane) and land L frames late.
    Look-ahead is a human's ~1 s glance down the sidewalk, and a slow hand
    overlooks more (L% of hazards go unnoticed). Experts weave and swipe PRESTO;
    slower hands lean on EXCUSE ME and skip PRESTO once timing gets loose."""
    every = 1
    skill = None            # fixed noise level (frames, like L) outside `curve`
    blind = None            # chance to overlook a hazard (default L%)
    dodges = True

    def __init__(self):
        self.eyes = _Eyes(self)
        self.L = None
        self.k = None             # next 8th note to step on
        self.emit = None          # frame to send it
        self.drift = 0.0
        self.foot = LEFT
        self.tap_until = -1
        self.tap_mask = 0
        self.act_until = -1
        self.act_mask = 0
        self.excuse_at = -100
        self.noticed = {}

    def setup(self):
        L = self.L = _hand_latency()
        S = L if self.skill is None else self.skill
        self.sd = 0.7 + 0.16 * S
        self.drift_sd = 0.026 * S          # stationary sd ~0.08 S with rho 0.95
        self.drop = 0.01 if S else 0.0
        self.react = 76                     # px ahead (about a second of walking)
        self.p_blind = 0.01 * S if self.blind is None else self.blind
        self.prefer_lanes = S < 9
        self.presto = S < 9

    def next_beat(self, t, rng):
        # first 8th whose (anticipated) send time is still ahead of us
        k = max(self.k + 1 if self.k is not None else 0, (t + self.L - PHASE) // 15 + 1)
        self.k = k
        self.drift = 0.95 * self.drift + rng.gauss(0, self.drift_sd) if self.drift_sd else 0.0
        land = PHASE + 15 * k + rng.gauss(0, self.sd) + self.drift
        self.emit = max(t + 1, int(round(land)) - self.L)

    def hazards(self, t, rng):
        seen = self.eyes.look()
        if not seen:
            return 0
        me, ents = seen
        if me['state'] not in (0, 1):
            return 0
        for e in ents:
            e['rel'] = _rel(e, me)

        def noticed(e):
            key = (e['type'], e['wx'] // 32, e['lane'])
            if key not in self.noticed:
                self.noticed[key] = rng.random() >= self.p_blind
            return self.noticed[key]
        ahead = [e for e in ents if e['lane'] == me['lane'] and -2 < e['rel'] < self.react
                 and not e['flags'] & 0x0C and e['type'] != T_JOGGER and noticed(e)]
        behind = [e for e in ents if e['type'] == T_JOGGER and e['lane'] == me['lane'] and -90 < e['rel'] < 0
                  and not e['flags'] & 0x04 and noticed(e)]
        if not ahead and not behind:
            return 0

        def room(lane):
            # (px you could walk in that lane before reaching someone, and
            # whether that someone is a walker you could ask to step aside);
            # 0 room: someone right beside you, or a jogger coming
            if any(e['lane'] == lane and e['type'] == T_JOGGER and -90 < e['rel'] < 0 for e in ents):
                return 0, False
            near = sorted((e['rel'], e['type']) for e in ents if e['lane'] == lane and not e['flags'] & 0x0C
                          and e['type'] != T_JOGGER and e['rel'] > -18)
            if not near:
                return 999, False
            r, typ = near[0]
            return (0 if r < 28 else r), (typ < T_JOGGER and r > -4)
        here = min((e['rel'] for e in ahead), default=999)
        lanes = [l for l in (me['lane'] - 1, me['lane'] + 1) if 0 <= l <= 2]
        clean = [l for l in lanes if room(l)[0] > here + 16]
        walkers = ahead and all(e['type'] < T_JOGGER for e in ahead) and not behind
        can_excuse = walkers and t - self.excuse_at > 45 and any(e['rel'] < 60 for e in ahead)
        if clean and (self.prefer_lanes or not can_excuse):
            best = max(room(l)[0] for l in clean)
            to = rng.choice([l for l in clean if room(l)[0] == best])
        elif can_excuse:
            self.excuse_at = t
            return A
        else:
            # boxed in by something that won't move: step in behind a walker
            # (and ask them next)
            soft = [l for l in lanes if room(l)[1]]
            if not soft or here > 40:
                return 0
            to = rng.choice(soft)
        return X if to < me['lane'] else B

    def act(self, t, tel, rng):
        if self.L is None:
            self.setup()
        if self.emit is None:
            self.next_beat(t, rng)
        if t >= self.emit:
            if rng.random() >= self.drop:
                self.tap_mask = self.foot
                if self.presto and self.k % 8 == 0:
                    self.tap_mask |= Y
                self.tap_until = t + TAP
                self.foot = RIGHT if self.foot == LEFT else LEFT
            self.next_beat(t, rng)
        if t < self.tap_until:
            return self.tap_mask
        if t < self.act_until:
            return self.act_mask
        # the other thumb: only between taps, so a lane press never rides on a step
        if self.dodges and t % 3 == 0 and t + 6 < self.emit:
            s = self.hazards(t, rng)
            if s:
                self.act_mask = s
                self.act_until = t + TAP
                return s
        return 0


def _sprite_tiles():
    """MS_*_BASE tile numbers of the event's sprites (build/bay_meta.inc)."""
    import os
    import re
    here = os.path.dirname(os.path.abspath(__file__))
    meta = os.path.join(here, '..', '..', 'build', 'bay_meta.inc')
    out = {}
    for m in re.finditer(r'^MS_(\w+)_BASE = (\d+)', open(meta).read(), re.M):
        out[m.group(1)] = int(m.group(2))
    return out


TARGET_X = 56       # screen x of a dot sprite landing in the target (BEAT_X - 4)
DOT_Y = 204         # the dots' sprite row (BEAT_Y - 4)
HIT_Y = 199         # the "where your step landed" mark


class bay_ear(bay_hand):
    """The curve bot: taps to what a person sees and hears, never to RAM.

    Each frame it reads the sprites on screen (the OAM the PPU shows this
    frame): the dots sliding into the target at 2 px a frame tell it when the
    next big dot (a beat), small dot (the "and") and gold dot (a bar) will
    land. It presses AS THE DOT LANDS, the frame the target lights and the
    note sounds, plus human timing noise (motor sd 0.6 + 0.12 L frames, a
    slowly wandering inner beat, the odd dropped step).

    It does NOT pre-compensate pt's hand latency L: its presses reach the
    game L +- L/4 frames late. All it gets is what a person gets: the mark
    under the strip (where the step landed) and EARLY / LATE, from which it
    nudges its timing by a fraction (phase correction, gain `alpha`, read off
    the screen to +-1 frame). alpha = 0 is a player who never adapts.

    Lanes: when a red ! shows over someone in its lane (or a jogger behind)
    it moves to the lane with the most room, L frames later; slower hands
    overlook L% of them and lean on EXCUSE ME. Experts (L < 9) walk double
    time (every dot), swipe PRESTO on the gold dots and weave, cutting their
    lane changes fine past walkers for a CLOSE SHAVE. Card readers (L 12-18)
    try the small dots too, as the card says, and go back to the big dots
    when their steps keep landing EARLY / LATE."""
    alpha = 0.3
    double = None       # None: experts, and card readers while it works
    presto_on = None
    excuse = True
    shave = None        # None: experts only

    def __init__(self):
        super().__init__()
        self.tiles = _sprite_tiles()
        self.landings = {}      # frame a dot lands -> 'big' | 'small' | 'gold'
        self.planned = set()
        self.queue = []         # (emit frame, mask)
        self.corr = 0.0         # learned anticipation, frames
        self.busy_until = 0
        self.second = None
        self.last_hit = None

    def setup(self):
        L = self.L = _hand_latency()
        S = L if self.skill is None else self.skill
        self.S = S
        self.sd = 0.6 + 0.12 * S
        self.drift_sd = 0.02 * S
        self.drop = 0.01 + 0.001 * S if S else 0.0
        self.react = 76
        self.p_blind = 0.01 * S if self.blind is None else self.blind
        self.prefer_lanes = S < 9
        self.dbl = (S <= 18) if self.double is None else self.double
        self.try_dbl = self.double is None and 12 <= S <= 18    # gives up if it isn't working
        self.err = 0.0          # running mean |frames off| of my steps
        self.presto = (S < 12) if self.presto_on is None else self.presto_on
        self.shaving = (S < 9) if self.shave is None else self.shave
        if not self.excuse:
            self.prefer_lanes = True

    def screen(self):
        g = self.game
        oam = g.core.peek(g.sym['oam_buf'], 512)
        hi = g.core.peek(g.sym['oam_hi'], 32)
        spr = []
        for i in range(128):
            x, y, tile, attr = oam[4 * i:4 * i + 4]
            if y >= 224:
                continue
            if (hi[i >> 2] >> ((i & 3) * 2)) & 1:
                x -= 256
            spr.append((x, y, tile | (attr & 1) << 8))
        return spr

    def look_beat(self, t, spr):
        T = self.tiles
        kinds = {T['TICKBIG']: 'big', T['TICKSM']: 'small', T['TICKGOLD']: 'gold'}
        warn = False
        hit = None
        for x, y, tile in spr:
            if y == DOT_Y and tile in kinds and x > TARGET_X:
                land = t + (x - TARGET_X) // 2
                self.landings.setdefault(land, kinds[tile])
            elif y == HIT_Y and tile == T['HIT']:
                hit = x
            elif tile == T['WARN']:
                warn = True
        if hit is not None and hit != self.last_hit:
            # a new mark: where my last step landed, read to +-1 frame
            self.feedback((TARGET_X - hit) / 2.0)
        self.last_hit = hit
        return warn

    def feedback(self, d):
        seen = d + self.rng.choice((-1, 0, 0, 1)) * 0.5
        self.err = 0.85 * self.err + 0.15 * abs(seen + 0.5)
        if self.try_dbl and self.dbl and self.err > 4.0:
            self.dbl = False            # "the small dots are too fast for me"
        if not self.alpha:
            return
        # aim: the landing frame (-1) and the one after (0) are dead centre
        self.corr += self.alpha * (seen + 0.5)
        self.corr = max(-12.0, min(12.0, self.corr))

    def plan(self, t):
        rng = self.rng
        for land, kind in sorted(self.landings.items()):
            if land in self.planned or land <= t:
                continue
            if kind == 'small' and not self.dbl:
                continue
            self.planned.add(land)
            self.drift = 0.9 * self.drift + rng.gauss(0, self.drift_sd) if self.drift_sd else 0.0
            if rng.random() < self.drop:
                continue
            at = land + rng.gauss(0, self.sd) + self.drift - self.corr
            emit = max(t, int(round(at)))
            m = self.foot
            self.foot = RIGHT if self.foot == LEFT else LEFT
            if kind == 'gold' and self.presto:
                m |= Y
            self.queue.append((emit, m))
        self.queue.sort()
        for k in [k for k in self.landings if k < t - 30]:
            del self.landings[k]

    def hazards(self, t, rng):
        """The red ! is up: what a person on the sidewalk does about it."""
        seen = self.eyes.look()
        if not seen:
            return 0
        me, ents = seen
        if me['state'] not in (0, 1):
            return 0

        def noticed(e):
            key = (e['type'], e['wx'] // 32, e['lane'])
            if key not in self.noticed:
                self.noticed[key] = rng.random() >= self.p_blind
            return self.noticed[key]
        for e in ents:
            e['rel'] = _rel(e, me)
        live = [e for e in ents if not e['flags'] & 0x0C]
        horizon = 150 if self.S < 9 else 96     # experts read the whole street
        ahead = [e for e in live if e['lane'] == me['lane'] and -2 < e['rel'] < horizon
                 and e['type'] != T_JOGGER and noticed(e)]
        jog = [e for e in live if e['type'] == T_JOGGER and e['lane'] == me['lane']
               and -200 < e['rel'] < 0 and noticed(e)]
        if not ahead and not jog:
            return 0
        here = 0 if jog else min(e['rel'] for e in ahead)

        def room(lane):
            if any(e['lane'] == lane and e['type'] == T_JOGGER and -120 < e['rel'] < 8 for e in live):
                return -1                       # a jogger coming up that lane
            if any(e['lane'] == lane and -20 < e['rel'] < 20 for e in live):
                return -1                       # someone right beside you
            return min((e['rel'] for e in live if e['lane'] == lane and e['rel'] >= 20
                        and e['type'] != T_JOGGER), default=999)
        # neighbours, or two lanes over when the middle one is passable now
        lanes = [l for l in (me['lane'] - 1, me['lane'] + 1) if 0 <= l <= 2]
        if me['lane'] != 1 and room(1) >= 28:
            lanes.append(2 - me['lane'])
        best = max(lanes, key=lambda l: (room(l) - 12 * (abs(l - me['lane']) - 1), rng.random()))
        walkers = ahead and all(e['type'] < T_JOGGER for e in ahead) and not jog
        can_excuse = (self.excuse and walkers and t - self.excuse_at > 45
                      and min(e['rel'] for e in ahead) < (36 if self.S < 9 else 60))
        if room(best) > here + 8 and room(best) >= 28 and (self.prefer_lanes or not can_excuse
                                                          or room(best) > 90):
            if self.shaving and not jog and abs(best - me['lane']) == 1:
                # cut it fine past somebody on foot: move when they're 14-24 px
                # ahead (CLOSE SHAVE), a little sooner the faster we close
                near = min(ahead, key=lambda e: e['rel'])
                close = max(0.2, me['speed'] - near['v'])
                if near['type'] < T_JOGGER and near['rel'] - close * 4 > 21:
                    return 0
            m = X if best < me['lane'] else B
            if abs(best - me['lane']) == 2:
                self.second = (t + 7, m)
            return m
        if can_excuse:
            self.excuse_at = t
            return A
        # about to walk into a cart or a board with no gap anywhere: squeezing
        # past somebody walking beats that
        solid = [e for e in ahead if e['type'] >= T_CART and e['rel'] < 44]
        if solid:
            soft = [l for l in (me['lane'] - 1, me['lane'] + 1) if 0 <= l <= 2 and not any(
                e['lane'] == l and (e['type'] >= T_JOGGER and -120 < e['rel'] < 30) for e in live)]
            if soft:
                return X if soft[0] < me['lane'] else B
        return 0

    def act(self, t, tel, rng):
        self.rng = rng
        if self.L is None:
            self.setup()
        spr = self.screen()
        warn = self.look_beat(t, spr)
        self.plan(t)
        while self.queue and self.queue[0][0] <= t:
            _, m = self.queue.pop(0)
            if self.tap_until > t - 1:
                continue        # a thumb can't press twice at once
            self.tap_mask = m
            self.tap_until = t + TAP
        if t < self.tap_until:
            return self.tap_mask
        if t < self.act_until:
            return self.act_mask
        if self.second and t >= self.second[0]:
            self.act_mask = self.second[1]
            self.act_until = t + TAP
            self.second = None
            return self.act_mask
        nxt = self.queue[0][0] if self.queue else t + 99
        # a person knows they just pressed: no second lane change until the
        # first one has shown on screen
        if self.dodges and (warn or self.S < 9) and t % 3 == 0 and t + 5 < nxt and t >= self.busy_until:
            s = self.hazards(t, rng)
            if s == A and not self.excuse:
                s = 0
            if s:
                self.act_mask = s
                self.act_until = t + TAP
                if s != A:
                    self.busy_until = t + self.L + self.L // 4 + 6
                return s
        return 0


class bay_steady(bay_ear):
    """The steady on-beat walker: a step on every big dot (average human
    timing), moves over a lane whenever a red ! warns, never says EXCUSE ME."""
    skill = 15
    excuse = False
    double = False
    presto_on = False


class bay_ear_raw(bay_ear):
    """bay_ear that never adapts its timing (alpha 0): taps on the landing,
    plus pt's hand latency, all run."""
    alpha = 0.0


class bay_ear_dt(bay_ear):
    """bay_ear that always tries DOUBLE TIME and PRESTO, however loose its
    timing: is the expert's walk worth it for an ordinary hand?"""
    double = True
    presto_on = True



class bay_walkman(bay_ear):
    """Steps on every big dot like an average human and never looks up: no
    lanes, no EXCUSE ME (Marcus's round-4 run)."""
    skill = 15
    dodges = False
    double = False
    presto_on = False

class bay_casual(bay_hand):
    """A decent rhythm player who doesn't dodge perfectly (Gord, Marcus):
    human timing (sd ~3.1 + drift) and hand latency even outside `curve`,
    overlooks 40% of the crowd, says EXCUSE ME rather than weave."""
    skill = 15
    blind = 0.4

    def setup(self):
        super().setup()
        if not self.L:          # outside `curve`: add the hand's lag ourselves
            self.L = 0


class bay_stepper(bay_hand):
    """Steps in time like a person (sd ~3 frames + drift) and never looks up:
    no lanes, no EXCUSE ME. The steady stepper of rounds 2-3."""
    skill = 15
    dodges = False


class bay_ace(bay_beat):
    """Expert: tight timing, weaves through lanes instead of asking (asking
    breaks the combo), swipes PRESTO on every gold downbeat."""
    jitter = 0.7
    react = 48
    prefer_lanes = True
    presto = True


class bay_human(bay_beat):
    """A decent human following the card: hears the beat but taps loosely
    (sd 2.8 frames, a frame late on average, drops 1 beat in 15), sees the
    street 15 frames late, misses 1 obstacle in 5, and leans on EXCUSE ME."""
    jitter = 2.8
    bias = 1
    miss = 1 / 15
    react = 56
    delay = 15
    blind_spot = 0.2


class bay_sloppy(bay_beat):
    """Gets the idea but is loose: +-3 frame timing, drops 1 beat in 12,
    reacts late."""
    jitter = 2.5
    miss = 1 / 12
    react = 26


class bay_rookie(bay_beat):
    """First go: +-4 frames (~70 ms), drifts late, drops 1 beat in 8,
    notices trouble late."""
    jitter = 3.5
    offset = 1
    miss = 1 / 8
    react = 22


class bay_blind(bay_beat):
    """On the beat but never looks up from the phone: no lanes, no excuse-me."""
    react = 0


class bay_spam(bay_beat):
    """pt8's open-loop record script: metronome steps plus EXCUSE ME every
    45 frames, no lanes, never looks."""
    jitter = 0.0
    react = 0

    def act(self, t, tel, rng):
        m = super().act(t, tel, rng)
        if t % 45 < 3:
            m |= A
        return m


class bay_steady6(bay_beat):
    """Taps a steady 6/s without listening to the music (avoids obstacles)."""
    period = 10
    jitter = 0.8


class bay_double(bay_beat):
    """8 taps/s: steps on every 16th note (half on the beat, half between)."""
    period = 7.5
    jitter = 0.8

    def plan_tap(self, t, rng):
        k = int((t - PHASE) // 7.5) + 1
        self.next_tap = int(round(PHASE + k * 7.5 + rng.gauss(0, self.jitter)))
        self.next_k = None
        if self.next_tap <= t:
            self.next_tap = t + 1


class bay_halfout(bay_beat):
    """Steady and on tempo but half a beat out (pt5): 7 frames late every step."""
    jitter = 0.0
    offset = 7
    react = 0


class bay_mash(Policy):
    """Alternates LEFT/RIGHT as fast as the pad allows (20 taps/s)."""
    trivial = True

    def act(self, t, tel, rng):
        ph = t % 6
        return LEFT if ph < 3 else RIGHT


class bay_mash10(Policy):
    """Alternating 10 taps/s with no sense of the beat."""
    trivial = True

    def act(self, t, tel, rng):
        ph = t % 12
        if ph < 3:
            return LEFT
        if 6 <= ph < 9:
            return RIGHT
        return 0


class bay_mashy(Policy):
    """Alternating 10 taps/s and hammering Y and A: hoping for PRESTO."""
    trivial = True

    def act(self, t, tel, rng):
        ph = t % 12
        m = LEFT if ph < 3 else RIGHT if 6 <= ph < 9 else 0
        if t % 4 < 2:
            m |= Y | A
        return m


POLICIES = {c.__name__: c for c in [bay_beat, bay_hand, bay_ear, bay_steady, bay_ear_raw, bay_ear_dt, bay_walkman, bay_casual, bay_stepper, bay_ace, bay_human, bay_sloppy, bay_rookie, bay_blind,
                                     bay_spam, bay_steady6, bay_double, bay_halfout, bay_mash,
                                     bay_mash10, bay_mashy]}

DEFAULTS = {'bay': ['idle', 'mash_a', 'random_input', 'bay_mash', 'bay_mash10', 'bay_mashy',
                    'bay_steady6', 'bay_halfout', 'bay_blind', 'bay_spam', 'bay_double', 'bay_rookie',
                    'bay_human', 'bay_stepper', 'bay_casual', 'bay_sloppy', 'bay_steady', 'bay_hand', 'bay_ear',
                    'bay_beat', 'bay_ace']}

CURVE = {'bay': 'bay_ear'}

