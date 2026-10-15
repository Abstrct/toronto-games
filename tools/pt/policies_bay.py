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
        ram = self.g.core.peek(self.base, 620)
        w = lambda o: ram[o] | ram[o + 1] << 8
        me = dict(dist=w(0), lane=ram[6], state=ram[14], cd=w(26), speed=w(4) / 256.0,
                  tips=ram[602], decaf=ram[512])
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
        # plan the same beat twice). A person hears the beat coming: under a
        # hand latency (pt curve, the couch drivers) the tap is sent that
        # much early, as bay_hand does, so it still lands on the beat.
        if getattr(self, 'lat', None) is None:
            self.lat = _hand_latency()
        k = (t + self.lat - PHASE - self.offset) // self.period + 1
        if self.k_plan is not None:
            k = self.k_plan + 1
        self.k_plan = k
        nominal = PHASE + self.offset + k * self.period
        self.next_tap = nominal - self.lat + int(round(rng.gauss(self.bias, self.jitter)))
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
    `latency` local; a couch driver script's PT_LATENCY or module-level `lat`;
    0 otherwise). A person learns their own hands: the bots anticipate it."""
    import os
    import sys
    f = inspect.currentframe()
    while f:
        if f.f_code.co_name == 'run_bot' and 'latency' in f.f_locals:
            return int(f.f_locals['latency'] or 0)
        f = f.f_back
    if os.environ.get('PT_LATENCY'):
        return int(os.environ['PT_LATENCY'])
    lat = getattr(sys.modules.get('__main__'), 'lat', None)
    return lat if isinstance(lat, int) else 0


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
    lane changes fine past walkers for a CUT IT FINE. Card readers (L 12-18)
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
        self.kinds = {}         # emit frame -> the dot that tap aims at
        self.aimed = None

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
        # card readers learn the CUT IT FINE from the coach ("DODGE LATER:
        # CUT IT FINE!", w_tips bit 7) and try it from then on, anticipating
        # the gap closing as they anticipate a dot (with an error ~ their hand)
        self.learns_shave = self.shave is None and 9 <= S <= 18
        self.shave_seen = None
        self.shave_err = {}
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
        if abs(d) > 7.5 and getattr(self, 'aimed', None) == 'small':
            d -= 15 if d > 0 else -15   # a step on the small dot shows half a beat
                                        # off (no step on the big one): I know
                                        # which I aimed at
        seen = d + self.rng.choice((-1, 0, 0, 1)) * 0.5
        self.err = 0.85 * self.err + 0.15 * abs(seen + 0.5)
        if self.try_dbl and self.dbl and self.err > 4.0:
            self.dbl = False            # "the small dots are too fast for me"
        if not self.alpha:
            return
        # aim: the landing frame (-1) and the one after (0) are dead centre
        self.corr += self.alpha * (seen + 0.5)
        self.corr = max(-24.0, min(24.0, self.corr))

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
            self.kinds[emit] = kind
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
               and -250 < e['rel'] < 0 and noticed(e)]
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
        if self.learns_shave and not self.shaving and me['tips'] & 0x80:
            if self.shave_seen is None:
                self.shave_seen = t
            elif t - self.shave_seen > 64 + 40:        # the tip shows, they read it
                self.shaving = True
        if room(best) > here + 8 and room(best) >= 28 and (self.prefer_lanes or not can_excuse
                                                          or room(best) > 90):
            if self.gold_t is not None and self.S < 9 and t < self.gold_t + TELL_T + 1 - self.L:
                return 0                    # the gold !: its cut counts TELL_T frames on
            if self.shaving and not jog and abs(best - me['lane']) == 1:
                # cut it fine past somebody on foot: move when they're 14-24 px
                # ahead (CUT IT FINE), a little sooner the faster we close
                near = min(ahead, key=lambda e: e['rel'])
                close = max(0.2, me['speed'] - near['v'])
                aim = 21
                if self.S < 9:
                    lead = 4 + self.L       # (knows its own hands)
                else:
                    aim = 26            # a careful cut: the far edge of the window
                    # a person's guess of "when it'll be close", made L frames
                    # before it lands: per person, an error of ~L/3 frames
                    key = (near['type'], near['wx'] // 32, near['lane'])
                    if key not in self.shave_err:
                        self.shave_err[key] = rng.gauss(0, 1 + self.S / 3.0)
                    lead = 4 + self.L + self.shave_err[key]
                if near['type'] < T_JOGGER and near['rel'] - close * lead > aim:
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

    gold_t = None

    def act(self, t, tel, rng):
        self.rng = rng
        if self.L is None:
            self.setup()
        spr = self.screen()
        warn = self.look_beat(t, spr)
        if self.tiles['WARNBIG'] in set(tile for _, _, tile in spr):
            if self.gold_t is None:
                self.gold_t = t
        else:
            self.gold_t = None
        self.plan(t)
        while self.queue and self.queue[0][0] <= t:
            e, m = self.queue.pop(0)
            if self.tap_until > t - 1:
                continue        # a thumb can't press twice at once
            self.aimed = self.kinds.pop(e, None)
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


TELL_T = 15         # ev_bay.s: the chain's gold ! goes up this many frames before the cut counts


class bay_cue(bay_ear):
    """The tell check for the undocumented chain (pt.py curve-style: run it at
    latency L, +-3 frames). Walks as bay_ear and cuts it fine by eye to open
    a chain. Then it goes by the screen: the CUT IT FINE / chain popup says a
    chain is open, so it holds its lane moves for a gold !; a gold ring a
    lane over says who to fall in behind, so it steps over; the moment a gold
    ! goes up (with its beep) it presses the way the gold arrow points, and
    the hand's latency L lands the press. It never reads the chain's state or
    the window from RAM. `episodes` / `landed` count gold !s and chains landed
    off them, `log` each one (measurement only); an episode whose gold ! went
    up while a lane press of its own was still in flight is logged 'moving'
    (not a reaction to the tell)."""
    skill = None
    shave = True
    wait = 0            # frames it waits after the gold ! before pressing
    rings = True        # follows the gold rings (the setup)

    def __init__(self):
        super().__init__()
        self.gold_was = False
        self.episodes = 0
        self.landed = 0
        self.watch = None
        self.press_at = None
        self.ring_at = -99
        self.lane_t = -99
        self.chain_until = -1
        self.last_pop = ''
        self.log = []

    def _slaloms(self):
        if self.eyes.base is None:
            self.eyes.look()
        return self.game.core.peek(self.eyes.base + 659, 1)[0]

    def _ahead(self):
        """(px to the nearest one ahead in my lane, my lane): the eyes."""
        seen = self.eyes.look()
        if not seen:
            return 999, None
        me, ents = seen
        rel = [_rel(e, me) for e in ents if e['lane'] == me['lane'] and not e['flags'] & 0x0C
               and e['type'] != T_JOGGER]
        rel = [r for r in rel if r > -2]
        return (min(rel) if rel else 999), me['lane']

    def hazards(self, t, rng):
        # a chain open: hold the lane for its gold ! unless about to walk in
        if t < self.chain_until and self._ahead()[0] > 24:
            return 0
        return bay_ear.hazards(self, t, rng)

    def act(self, t, tel, rng):
        m = self._act(t, tel, rng)
        if m & (X | B | UP | DOWN):
            if t >= self.act_until - TAP and m == self.act_mask and self.lane_t < t - TAP:
                self.lane_t = t
        return m

    def _act(self, t, tel, rng):
        self.rng = rng
        if self.L is None:
            self.setup()
        row = self.game.text_rows()[9]
        if row != self.last_pop:
            if 'CUT IT FINE' in row or 'SLALOM' in row:
                self.chain_until = t + 150      # read it: a chain is open
            self.last_pop = row
        spr = self.screen()
        T = self.tiles
        tiles = set(tile for _, _, tile in spr)
        gold = T['WARNBIG'] in tiles
        # measurement only: did a chain land off this gold !?
        if self.watch is not None:
            o, n, moving = self.watch
            if self._slaloms() > n:
                self.landed += 1
                self.log.append((o, t - o, 'moving landed' if moving else 'landed'))
                self.watch = None
            elif not gold and t > o + 8:
                self.log.append((o, t - o, 'moving' if moving else 'missed'))
                self.watch = None
        if gold and not self.gold_was:
            self.episodes += 1
            self.watch = (t, self._slaloms(), t - self.lane_t <= self.L + 4)
            self.press_at = t + self.wait
            self.chain_until = max(self.chain_until, t + 60)
        self.gold_was = gold
        if not gold:
            self.press_at = None
        if self.press_at is not None and t >= self.press_at and t >= self.tap_until:
            m = X if T['LANEUPG'] in tiles else B if T['LANEDNG'] in tiles else 0
            if m:
                self.press_at = None
                self.act_mask = m
                self.act_until = t + TAP
                self.busy_until = t + self.L + 10
                self.look_beat(t, spr)          # (the feet are planned as ever)
                self.plan(t)
                return m
        if gold or self.press_at is not None:
            # waiting on the gold !: feet only, no other lane move
            self.look_beat(t, spr)
            self.plan(t)
            while self.queue and self.queue[0][0] <= t:
                _, m = self.queue.pop(0)
                if self.tap_until > t - 1:
                    continue
                self.tap_mask = m
                self.tap_until = t + TAP
            if t < self.tap_until:
                return self.tap_mask
            return self.act_mask if t < self.act_until else 0
        m = bay_ear.act(self, t, tel, rng)
        if m or not self.rings or t < self.tap_until or t < self.act_until or t < self.busy_until:
            return m
        # a gold ring a lane over: fall in behind them (not with somebody
        # under a red ! right here: they may be the next gold !)
        if t % 3 or t - self.ring_at < self.L + 12:
            return 0
        me_y = None
        for x, y, tile in spr:
            if tile == T['RINGYEL'] and x == 64:
                me_y = y
        if me_y is None:
            return 0
        for x, y, tile in spr:
            if tile == T['RINGYEL'] and x != 64 and abs(y - me_y) in (19, 20, 21):
                nxt = self.queue[0][0] if self.queue else t + 99
                if t + 5 >= nxt or self._ahead()[0] < 104:
                    return 0
                m = X if y < me_y else B
                self.ring_at = t
                self.act_mask = m
                self.act_until = t + TAP
                self.busy_until = t + self.L + 10
                return m
        return 0


class bay_weave(bay_cue):
    """The title demo: the expert (bay_ear at 0 frames: DOUBLE TIME, PRESTO,
    CUT IT FINEs) who also reads the chain's tell: after a cut it falls in
    behind whoever wears the gold ring, and cuts past them TELL_T + 2 frames
    after their gold ! goes up: the undocumented chain, shown in play."""
    wait = TELL_T + 2


class bay_cue_blind(bay_cue):
    """bay_ear with bay_cue's bookkeeping, the tell ignored: the same walk and
    cuts, never looks for gold (how often the chain lands by accident for a
    player who cuts it fine)."""
    rings = False

    def hazards(self, t, rng):
        return bay_ear.hazards(self, t, rng)

    def _act(self, t, tel, rng):
        self.rng = rng
        if self.L is None:
            self.setup()
        spr = self.screen()
        gold = self.tiles['WARNBIG'] in set(tile for _, _, tile in spr)
        if self.watch is not None:
            o, n, moving = self.watch
            if self._slaloms() > n:
                self.landed += 1
                self.log.append((o, t - o, 'landed'))
                self.watch = None
            elif not gold and t > o + 8:
                self.log.append((o, t - o, 'missed'))
                self.watch = None
        if gold and not self.gold_was:
            self.episodes += 1
            self.watch = (t, self._slaloms(), False)
        self.gold_was = gold
        return bay_ear.act(self, t, tel, rng)


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



class bay_ear_dt2(bay_ear):
    """bay_ear that always walks DOUBLE TIME and never swipes PRESTO: the
    DOUBLE TIME line on its own, against bay_ear_single."""
    double = True
    presto_on = False


class bay_ear_single(bay_ear):
    """bay_ear on the big dots only: the plain walk DOUBLE TIME must beat."""
    double = False


class bay_walkman(bay_ear):
    """Steps on every big dot like an average human and never looks up: no
    lanes, no EXCUSE ME (Marcus's round-4 run)."""
    skill = 15
    dodges = False
    double = False
    presto_on = False

class bay_prompt(bay_ear):
    """Does what the screen says and nothing else: steps as the big dots land
    (the card's first line) and, when a red ! shows, changes lane the way the
    white arrow beside the walker points (no arrow: stays put). Never reads
    the street itself. Run at 20-25 f (`pt.py curve bay -p bay_prompt -l
    20,25`) it is the cue-timing check: obeying must beat ignoring
    (bay_prompt_deaf, the same feet with the cues ignored)."""
    double = False
    presto_on = False
    obey = True
    blind_dir = False   # Dana's round-7 script: up or down at random

    def act(self, t, tel, rng):
        self.rng = rng
        if self.L is None:
            self.setup()
            self.busy_until = 0
        spr = self.screen()
        self.look_beat(t, spr)
        self.plan(t)
        while self.queue and self.queue[0][0] <= t:
            _, m = self.queue.pop(0)
            if self.tap_until > t - 1:
                continue
            self.tap_mask = m
            self.tap_until = t + TAP
        if t < self.tap_until:
            return self.tap_mask
        if t < self.act_until:
            return self.act_mask
        if not self.obey or t < self.busy_until:
            return 0
        T = self.tiles
        tiles = set(tile for _, _, tile in spr)
        if T['WARN'] not in tiles:
            return 0
        nxt = self.queue[0][0] if self.queue else t + 99
        if t + 5 >= nxt:
            return 0
        if self.blind_dir:
            m = rng.choice((UP, DOWN))
        elif T.get('LANEUP') in tiles:
            m = UP
        elif T.get('LANEDN') in tiles:
            m = DOWN
        elif T.get('LANEA') in tiles:
            m = A
        else:
            return 0
        self.act_mask = m
        self.act_until = t + TAP
        # a person sees their own move land before moving again
        self.busy_until = t + self.L + self.L // 4 + 8
        return m


class bay_prompt_deaf(bay_prompt):
    """bay_prompt's feet, cues ignored: the baseline obeying must beat."""
    obey = False


class bay_aspam(bay_prompt):
    """Mo's habit: bay_prompt's feet, lanes ignored, A (EXCUSE ME) every 45
    frames whatever is ahead. Must not beat bay_prompt (obeying the arrow)."""
    obey = False

    def act(self, t, tel, rng):
        m = super().act(t, tel, rng)
        if not m and t % 45 < 3 and t >= self.tap_until:
            return A
        return m


class bay_prompt_blind(bay_prompt):
    """Obeys the red ! but picks up or down at random (no arrow reading)."""
    blind_dir = True


class bay_dana(bay_ear):
    """Dana's round-8 script, frame for frame: steps on the big dots a little
    loose (-3..+7 frames), looks at the screen once a beat (just after a step),
    and when she saw a red ! she acts after the step two beats on: the way the
    arrow pointed when she last looked, or A when there was no arrow. Her real
    reaction to a ! is 60-90 frames. `pt.py curve bay -p bay_dana -l 0`."""
    lo, hi = -3, 7

    def act(self, t, tel, rng):
        self.rng = rng
        if self.L is None:
            self.setup()
            self.k = 0
            self.pend = None
            self.look_at = None
            self.act_at = None
            self.act_m = 0
            self.saw = None
            self.next_step = None
            self.done = set()
        spr = self.screen()
        T = self.tiles
        for x, y, tile in spr:
            if y == DOT_Y and tile in (T['TICKBIG'], T['TICKGOLD']) and x > TARGET_X:
                self.landings.setdefault(t + (x - TARGET_X) // 2, 'big')
        if self.next_step is None:
            nxt = [l for l in sorted(self.landings) if l > t + self.hi and l not in self.done]
            if nxt:
                self.done.add(nxt[0])
                self.next_step = nxt[0] + rng.randint(self.lo, self.hi)
        m = 0
        if self.next_step is not None and t >= self.next_step:
            self.next_step = None
            self.tap_mask = self.foot
            self.foot = RIGHT if self.foot == LEFT else LEFT
            self.tap_until = t + TAP
            self.k += 1
            look = 6
            if self.pend is not None and self.k >= self.pend:
                self.act_at = t + 7
                self.act_m = self.saw if self.saw else A
                self.pend = None
                look = 13
            self.look_at = t + look
        if t < self.tap_until:
            m |= self.tap_mask
        if self.act_at is not None and self.act_at <= t < self.act_at + TAP:
            m |= self.act_m
        if self.look_at == t:
            tiles = set(tile for _, _, tile in spr)
            red = T['WARN'] in tiles or T['RINGRED'] in tiles
            self.saw = UP if T['LANEUP'] in tiles else DOWN if T['LANEDN'] in tiles else \
                A if T['LANEA'] in tiles else None
            if red and self.pend is None:
                self.pend = self.k + 2
        return m


class bay_flipper(bay_prompt):
    """Changes lane every 40 frames whatever is there (farming DODGEs)."""
    def act(self, t, tel, rng):
        m = super().act(t, tel, rng)
        if not m and t % 40 == 0:
            lane = self.eyes.look()[0]['lane']
            return UP if lane == 2 or (lane == 1 and (t // 40) % 2) else DOWN
        return m


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


POLICIES = {c.__name__: c for c in [bay_beat, bay_hand, bay_ear, bay_prompt, bay_dana, bay_cue, bay_cue_blind, bay_prompt_deaf, bay_aspam, bay_prompt_blind, bay_flipper, bay_steady, bay_ear_raw, bay_ear_dt, bay_ear_dt2, bay_ear_single, bay_weave, bay_walkman, bay_casual, bay_stepper, bay_ace, bay_human, bay_sloppy, bay_rookie, bay_blind,
                                     bay_spam, bay_steady6, bay_double, bay_halfout, bay_mash,
                                     bay_mash10, bay_mashy]}

DEFAULTS = {'bay': ['idle', 'mash_a', 'random_input', 'bay_mash', 'bay_mash10', 'bay_mashy',
                    'bay_steady6', 'bay_halfout', 'bay_blind', 'bay_spam', 'bay_double', 'bay_rookie',
                    'bay_human', 'bay_stepper', 'bay_casual', 'bay_sloppy', 'bay_steady', 'bay_prompt_deaf',
                    'bay_walkman', 'bay_aspam',
                    'bay_prompt', 'bay_hand', 'bay_ear', 'bay_weave',
                    'bay_beat', 'bay_ace']}

CURVE = {'bay': 'bay_ear'}

