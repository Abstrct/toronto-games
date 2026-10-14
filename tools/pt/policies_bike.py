"""Bike Courier bots.

The no-skill ones (idle, hold_a, mash_a, random_input, and the bike_camp_*
lane campers: steer to one line, hold A, never look) are exploit detectors.
The planners read the event's RAM (player, traffic table) and pick a line
each look, the way a player reads the road: ride lane centres clear of the
rails, cross the tracks at full lock (a TRACK HOP), dodge doors/potholes/
people, grab tokens, and (bike_pro, bike_greedy) tuck in behind the 501 to
draft it.

bike_human is the yardstick for "a decent human finishes": ~15-frame looks,
only sees what is on screen, misses the odd hazard, and steers by holding the
pad until it is about there (so it overshoots) instead of counter-steering.

run_bot() only hands a policy the telemetry dict, so these find the Game
object in the caller's frame (`g` in pt.run_bot / Session) to peek WRAM.
"""
import inspect

from policies import Policy, A, B, LEFT, RIGHT

# ev_ram layout (src/ev_bike.s)
B_PX, B_VX, B_SPEED, B_DIST, B_STATE, B_INV = 0, 2, 4, 6, 12, 16
NUM_ENT = 16
E_TYPE, E_X, E_WY, E_VY, E_VX, E_TIMER, E_FLAGS = 64, 96, 128, 192, 224, 256, 320
T_PARKED, T_PARKED_S, T_CAR_N, T_CAR_S, T_TRAM_N, T_TRAM_S, T_HOLE, T_TOKEN, T_PED = range(1, 10)
HW = {1: 15, 2: 15, 3: 15, 4: 15, 5: 20, 6: 20, 7: 11, 9: 8}
HH = {1: 29, 2: 29, 3: 29, 4: 29, 5: 55, 6: 55, 7: 14, 9: 14}
RAILS = (83, 107, 151, 175)
# where a courier can sit: well clear of every rail
LANES = (40, 66, 95, 117, 140, 163, 184)
HOME = 184
STEER_ACC = 0x38 / 256      # counter-steer: vx change per frame
STEER_DECAY = 0x30 / 256    # let go: vx change per frame
DRAFT_NEAR, DRAFT_FAR = 58, 124


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
    def read(self):
        if getattr(self, 'g', None) is None:
            self.g = getattr(self, 'game', None) or find_game()
            self.ev = self.g.sym['ev_ram']
        r = self.g.core.peek(self.ev, 400)
        w = lambda o: r[o] | r[o + 1] << 8
        me = {'x': w(B_PX) / 256, 'vx': s16(w(B_VX)) / 256, 'speed': w(B_SPEED) / 256,
              'dist': w(B_DIST), 'state': r[B_STATE], 'inv': w(B_INV)}
        ents = []
        for i in range(NUM_ENT):
            t = r[E_TYPE + 2 * i]
            if not t or t > 9:
                continue
            ents.append({'t': t, 'x': w(E_X + 2 * i) / 256, 'rel': s16((w(E_WY + 2 * i) - me['dist']) & 0xFFFF),
                         'vy': s16(w(E_VY + 2 * i)) / 256, 'vx': s16(w(E_VX + 2 * i)) / 256,
                         'timer': w(E_TIMER + 2 * i), 'flags': r[E_FLAGS + 2 * i]})
        return me, ents


class _Camp(_Reader):
    """No skill: get to one line, hold A, never look again (re-steer after a
    wipeout puts you back in the bike lane)."""
    trivial = True
    lane = HOME

    def act(self, t, tel, rng):
        me, _ = self.read()
        d = self.lane - me['x']
        if abs(d) < 3:
            return A
        return A | (RIGHT if d > 0 else LEFT)


class bike_camp_left(_Camp):
    lane = 66


class bike_camp_strack(_Camp):
    lane = 95


class bike_camp_centre(_Camp):
    lane = 128


class bike_camp_ntrack(_Camp):
    lane = 163


class bike_camp_gap(_Camp):
    lane = 182


class _Planner(_Reader):
    every = 1
    margin = 6          # extra px around every hazard
    horizon = 70        # frames of look-ahead
    greed = 40          # how much a token is worth a detour
    brake_ok = True
    react = (1, 1)      # frames between looks at the road (reaction time)
    sloppy = 0.0        # chance of not noticing a hazard on a look
    sight = (-400, 900)  # rel range it can see
    drafts = False
    draft_pull = 80     # how far out of its way it goes to draft the 501
    human_steer = False
    aim = 0             # +- px of error on the line it aims for

    def __init__(self):
        self.g = None
        self.target = HOME
        self.next_look = 0
        self.danger = False
        self.draft = None

    def blocks(self, me, e):
        """[(x0, x1, t_arrive)] the hazard covers when it reaches the rider's row."""
        out = []
        sp = max(me['speed'], 1.0)
        if e['t'] == T_TOKEN:
            return out
        hh = HH[e['t']] + 2
        close = sp - e['vy']                      # closing speed (px/frame)
        rel = e['rel']
        if rel > hh:
            if close <= 0.05:
                return out
            ta = (rel - hh) / close
        elif rel < -hh:
            if close >= -0.05:                    # behind us and not catching up
                return out
            ta = (rel + hh) / close
        else:
            ta = 0
        if ta > self.horizon:
            return out
        m = self.margin
        if e['t'] == T_PED:
            # where they'll be when we get there, plus where they are now
            fx = e['x'] + e['vx'] * ta
            out.append((min(e['x'], fx) - 8 - m, max(e['x'], fx) + 8 + m, ta))
            return out
        hw = HW[e['t']]
        out.append((e['x'] - hw - m, e['x'] + hw + m, ta))
        if e['t'] == T_PARKED and (e['timer'] or e['flags'] & 2):
            dx = e['x'] - 20
            out.append((dx - 10 - m, dx + 10 + m, ta))
        return out

    def lane_cost(self, me, ents, blocks, L):
        x = me['x']
        lo, hi = min(x, L), max(x, L)
        cost = abs(L - x) * 0.6 + (0 if L == HOME else 8)
        # the time it takes to get there
        t_move = 8 + abs(L - x) / 1.5
        for (x0, x1, ta) in blocks:
            if x0 <= L <= x1:
                cost += 2000 - ta * 10
            elif x0 <= hi and lo <= x1 and ta < t_move:
                cost += 1500 - ta * 10       # it's in the way while we cross
        for e in ents:
            if e['t'] == T_TOKEN and 0 < e['rel'] < 220 and abs(e['x'] - L) < 9:
                cost -= self.greed
        return cost

    def steer(self, me, target):
        x, vx = me['x'], me['vx']
        d = target - x
        if self.human_steer:
            # hold the pad until about there, then let go and drift in
            if abs(d) < 5:
                return 0
            return RIGHT if d > 0 else LEFT
        stop = vx * vx / (2 * STEER_ACC)
        if abs(d) < 1.0 and abs(vx) < 0.3:
            return 0
        if d > 0:
            if vx > 0 and stop >= d:
                return LEFT
            return RIGHT
        if vx < 0 and stop >= -d:
            return RIGHT
        return LEFT

    def act(self, t, tel, rng):
        me, ents = self.read()
        if me['state'] != 0:
            self.target = HOME
            self.draft = None
            return A
        if t >= self.next_look:
            self.next_look = t + rng.randint(*self.react)
            self.plan(me, ents, rng)
        m = self.steer(me, self.target)
        if self.draft is not None:
            tram = next((e for e in ents if e['t'] == T_TRAM_N), None)
            if tram is None:
                self.draft = None
            else:
                rel = tram['rel']
                if tram['flags'] & 0x10 or rel < 68:
                    return m | (B if rel < 75 else 0)
                if rel > 100 or me['speed'] < tram['vy']:
                    return m | A
                return m
        # pedal unless everything near is blocked; then brake and let it go by
        if self.danger and self.brake_ok and me['speed'] > 0.8:
            return m | B
        return m | A

    def plan(self, me, ents, rng):
        lo, hi = self.sight
        seen = [e for e in ents if lo <= e['rel'] <= hi]
        blocks = []
        for e in seen:
            if self.sloppy and rng.random() < self.sloppy:
                continue
            blocks += self.blocks(me, e)
        x = me['x']
        lanes = list(LANES)
        costs = {L: self.lane_cost(me, seen, blocks, L) for L in lanes}
        best = min(costs, key=costs.get)
        # don't change our mind mid-crossing unless the target got dangerous
        if self.target in costs and abs(x - self.target) > 3 and costs[self.target] < 1000:
            best = self.target if costs[self.target] <= costs[best] + 30 else best
        self.draft = None
        if self.drafts:
            tram = next((e for e in seen if e['t'] == T_TRAM_N), None)
            if tram and -220 < tram['rel'] < 200 and not tram['flags'] & 0x10:
                others = [b for e in seen if e is not tram for b in self.blocks(me, e)]
                if tram['rel'] >= 50:
                    # tuck in behind it
                    c = self.lane_cost(me, seen, others, tram['x'])
                    if c < 1000 and c < costs[best] + self.draft_pull:
                        best = tram['x']
                        self.draft = tram
                        costs[best] = c
                elif tram['rel'] < -40 or abs(x - tram['x']) >= 22:
                    # wait beside the tracks for it to come by (its own
                    # box, no margin: we want to be right next to it)
                    tb = [(a + self.margin - 1, b - self.margin + 1, ta) for (a, b, ta) in self.blocks(me, tram)]
                    for L in (186, 140):
                        c = self.lane_cost(me, seen, others + tb, L)
                        if c < 1000 and c < costs[best] + self.draft_pull // 4:
                            best = L
                            costs[best] = c
        if self.aim:
            best += rng.uniform(-self.aim, self.aim)
        self.target = best
        self.danger = costs.get(best, 0) >= 1000 if self.draft is None else False


class bike_pro(_Planner):
    """Rides hard, detours for tokens, drafts the 501, quick eyes (Rob)."""
    react = (2, 6)
    drafts = True


class bike_human(_Planner):
    """A decent first-timer: ~15-frame looks, sees only the screen (plus the
    501's warning sign behind), misses the odd hazard, steers by feel."""
    react = (12, 20)
    sloppy = 0.10
    horizon = 50
    greed = 25
    margin = 8
    sight = (-160, 190)
    human_steer = True
    aim = 3


class bike_novice(bike_human):
    """Slower eyes and hands still (not in the default set)."""
    react = (18, 28)
    sloppy = 0.18
    greed = 0


class bike_safe(_Planner):
    """Wider margins, ignores tokens: the careful commuter."""
    margin = 10
    greed = 0
    react = (6, 12)


class bike_greedy(_Planner):
    """Chases every token line, tighter margins, drafts."""
    margin = 4
    greed = 120
    react = (3, 8)
    drafts = True


POLICIES = {c.__name__: c for c in [bike_pro, bike_human, bike_novice, bike_safe, bike_greedy,
                                    bike_camp_left, bike_camp_strack, bike_camp_centre,
                                    bike_camp_ntrack, bike_camp_gap]}
DEFAULTS = {'bike': ['idle', 'hold_a', 'mash_a', 'random_input',
                     'bike_camp_left', 'bike_camp_strack', 'bike_camp_centre',
                     'bike_camp_ntrack', 'bike_camp_gap',
                     'bike_human', 'bike_safe', 'bike_pro', 'bike_greedy']}
