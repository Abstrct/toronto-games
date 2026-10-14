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

from policies import Policy, A, B, DOWN, LEFT, RIGHT

# ev_ram layout (src/ev_bike.s)
B_PX, B_VX, B_SPEED, B_DIST, B_STATE, B_INV = 0, 2, 4, 6, 12, 16
B_HOP, B_HOPCD = 400, 42
NUM_ENT = 16
E_TYPE, E_X, E_WY, E_VY, E_VX, E_TIMER, E_FLAGS = 64, 96, 128, 192, 224, 256, 320
T_PARKED, T_PARKED_S, T_CAR_N, T_CAR_S, T_TRAM_N, T_TRAM_S, T_HOLE, T_TOKEN, T_PED = range(1, 10)
HW = {1: 15, 2: 15, 3: 15, 4: 15, 5: 19, 6: 19, 7: 11, 9: 8}
HH = {1: 29, 2: 29, 3: 29, 4: 29, 5: 55, 6: 55, 7: 14, 9: 14}
RAILS = (83, 107, 151, 175)
# where a courier can sit: well clear of every rail
LANES = (40, 66, 95, 117, 140, 163, 186)
HOME = 186
STEER_ACC = 0x40 / 256      # vx change per frame while held
STEER_REL = 0x80 / 256      # let go / reverse: vx change per frame
STEER_SPD = 0x200 / 256
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
        stop = vx * vx / (2 * STEER_REL)
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
                    return m | (DOWN if rel < 75 else 0)
                if rel > 100 or me['speed'] < tram['vy']:
                    return m | A
                return m
        # pedal unless everything near is blocked; then brake and let it go by
        if self.danger and self.brake_ok and me['speed'] > 0.8:
            return m | DOWN
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


# ---------------------------------------------------------------------------
# bike_courier: the curve bot. It plays like a person with a pad, so a late
# hand costs what it would cost a person, not more:
#  * it only reacts to what is on screen (plus the 501's warning sign behind);
#  * it plans each lane change as one motor program (hold the pad N frames,
#    with B in the same chord when the move crosses a rail: a TRACK HOP), and
#    keeps an efference copy of where that move will leave it, instead of
#    steering frame by frame off what it sees (that is what a 15-frame hand
#    turns into a wobble);
#  * it plans with slack for its own hand: a move is only "safe" if it is safe
#    whether the hand lands now, ~10 or ~20 frames from now;
#  * it never changes the pad more often than every 7 frames.

def _prog_tables():
    prog, disp = [0.0], [0.0]
    v = x = 0.0
    for _ in range(200):
        v = min(v + STEER_ACC, STEER_SPD)
        x += v
        prog.append(x)
    for n in range(1, 200):
        v = min(n * STEER_ACC, STEER_SPD)
        x = prog[n]
        while v > 0:
            v = max(0.0, v - STEER_REL)
            x += v
        disp.append(x)
    return prog, disp


PROG, DISP = _prog_tables()
SETTLE = 7
VIS = {1: 0, 2: 16, 3: 0, 4: 16, 5: 40, 6: 40, 7: 0, 8: 0, 9: 0}
MINCHG = 7


class bike_courier(_Reader):
    margin = 4          # px of slack round every hazard
    H = 90              # frames of look-ahead
    delays = (0, 10, 20)  # when the hand might land
    greed = 60          # a token on the line is worth this much detour
    hops = True
    look = 3

    def __init__(self):
        self.g = None
        self.reset()
        self.cur = A
        self.last_change = -99

    def reset(self):
        self.cmd_end = -1
        self.cmd_mask = A
        self.busy_until = -1
        self.exp_x = None
        self.brake_until = -1
        self.next_look = 0

    def read(self):
        if getattr(self, 'g', None) is None:
            self.g = getattr(self, 'game', None) or find_game()
            self.ev = self.g.sym['ev_ram']
        me, ents = _Reader.read(self)
        r = self.g.core.peek(self.ev + B_HOPCD, 2)
        me['hopcd'] = r[0] | r[1] << 8
        return me, ents

    def out(self, t, m):
        if m != self.cur:
            self.cur = m
            self.last_change = t
        return m

    def visible(self, e):
        rel = e['rel']
        if e['t'] == T_TRAM_N and rel < 0:
            return rel >= -160
        return -40 <= rel <= 168 + VIS.get(e['t'], 0)

    # where the rider is at frame k of the plan
    def traj(self, x_now, x0, t_settle, L, D):
        d = L - x0
        sgn = 1 if d > 0 else -1
        ad = abs(d)

        def f(k):
            if k < t_settle:
                return x_now + (x0 - x_now) * k / max(t_settle, 1)
            k2 = k - t_settle - D
            if k2 <= 0 or ad < 1:
                return x0
            return x0 + sgn * min(ad, PROG[min(k2, 199)])
        return f

    def hazards(self, me, ents):
        """per hazard: list of (k, x0, x1) frames it overlaps the rider's row"""
        out = []
        sp = me['speed']
        for e in ents:
            if e['t'] == T_TOKEN or not self.visible(e):
                continue
            hh = HH[e['t']] + 1
            hw = HW[e['t']] + self.margin
            door = e['t'] == T_PARKED and (e['flags'] & 2 or e['timer'])
            rows = []
            my = 0.0
            v = sp
            for k in range(0, self.H, 2):
                rel = e['rel'] + e['vy'] * k - my
                ex = e['x'] + e['vx'] * k
                if abs(rel) < hh:
                    rows.append((k, ex - hw, ex + hw))
                if door and abs(rel + 6) < 14 and (e['flags'] & 2 or rel < e['timer'] + 6):
                    rows.append((k, ex - 20 - 10 - self.margin, ex - 20 + 10 + self.margin))
                v = min(3.0, v + 0.08)
                my += 2 * v
            if rows:
                out.append(rows)
        return out

    def cost(self, me, ents, haz, x_now, x0, t_settle, L):
        c = abs(L - x0) * 0.3 + (0 if L == HOME else 6)
        worst = 0
        for D in (self.delays if abs(L - x0) >= 1 else (0,)):
            f = self.traj(x_now, x0, t_settle, L, D)
            for rows in haz:
                for (k, a, b) in rows:
                    if a <= f(k) <= b:
                        worst = max(worst, 2000 - k * 8)
                        break
        c += worst
        for e in ents:
            if e['t'] == T_TOKEN and 20 < e['rel'] < 168 and abs(e['x'] - L) < 8:
                c -= self.greed
        return c

    def act(self, t, tel, rng):
        me, ents = self.read()
        if t - self.last_change < MINCHG:
            return self.out(t, self.cur)
        if me['state'] != 0:
            self.reset()
            return self.out(t, A)
        if me['speed'] < 0.3 and t >= self.brake_until + 30 and t >= self.cmd_end:
            # not moving and not meaning to brake: the hand slipped. Let go, press again
            self.stall = getattr(self, 'stall', 0) + 1
            if self.stall > 20:
                self.stall = 0
                return self.out(t, 0)
        else:
            self.stall = 0
        if t < self.cmd_end:
            return self.out(t, self.cmd_mask)
        base = DOWN if t < self.brake_until else A      # A wins over DOWN in the game
        if t < self.next_look:
            return self.out(t, base)
        self.next_look = t + self.look
        x = me['x']
        if t < self.busy_until and self.exp_x is not None:
            x0, t_settle = self.exp_x, self.busy_until - t
        else:
            x0, t_settle = x, 0
            self.exp_x = x
        haz = self.hazards(me, ents)
        costs = {L: self.cost(me, ents, haz, x, x0, t_settle, L) for L in LANES}
        best = min(costs, key=costs.get)
        near = min(LANES, key=lambda L: abs(L - x0))
        if abs(near - x0) <= SETTLE and costs[near] <= costs[best] + 4:
            best = near                                 # staying put is as good
        if costs[best] >= 1000 and me['speed'] > 1.0:
            self.brake_until = t + 12
            base = DOWN
        elif t >= self.brake_until:
            base = A
        d = best - x0
        if abs(d) <= SETTLE - 1:
            return self.out(t, base)
        n = min(range(MINCHG, 199), key=lambda k: abs(DISP[k] - abs(d)))
        m = (RIGHT if d > 0 else LEFT) | base
        if self.hops and me['speed'] >= 1.4 and me['hopcd'] == 0 and t >= self.busy_until:
            for r in RAILS:
                if min(x0, best) < r < max(x0, best):
                    dr = abs(r - x0)
                    k = next(i for i in range(200) if PROG[i] >= dr)
                    if 3 <= k <= 16:
                        m |= B
                    break
        self.cmd_mask = m
        self.cmd_end = t + n
        self.exp_x = best
        self.busy_until = t + n + 26
        return self.out(t, m)


class bike_ace(bike_courier):
    """Perfect hands (Rob with a stopwatch): no slack for its own hand, hunts
    every token line, hops every rail it crosses and every pothole in its
    line. The ceiling probe, not a human (not in the curve)."""
    margin = 2
    delays = (0,)
    greed = 160
    look = 1

    def act(self, t, tel, rng):
        m = bike_courier.act(self, t, tel, rng)
        me, ents = self.last_read
        if me['state'] == 0 and me['hopcd'] == 0 and me['speed'] >= 1.4 and not m & B:
            for e in ents:
                if e['t'] == T_HOLE and abs(e['x'] - me['x']) < HW[T_HOLE] + 2 and 14 < e['rel'] - 14 < 3 * me['speed'] + 2:
                    if t - self.last_change >= 2:
                        m |= B
                        self.cur = m
                        self.last_change = t
                    break
        return m

    def read(self):
        me, ents = bike_courier.read(self)
        r = self.g.core.peek(self.ev + 402, 2)
        me['hop_ready'] = ((me['dist'] - (r[0] | r[1] << 8)) & 0xFFFF) >= 240
        self.last_read = (me, ents)
        return self.last_read

    def cost(self, me, ents, haz, x_now, x0, t_settle, L):
        c = bike_courier.cost(self, me, ents, haz, x_now, x0, t_settle, L)
        if me.get('hop_ready') and me['hopcd'] == 0 and me['speed'] >= 1.4:
            for r in RAILS:
                if min(x0, L) < r < max(x0, L):
                    k = next(i for i in range(200) if PROG[i] >= abs(r - x0))
                    if 3 <= k <= 16:
                        c -= 45
                    break
        return c


CURVE = {'bike': 'bike_courier'}

POLICIES = {c.__name__: c for c in [bike_courier, bike_ace, bike_pro, bike_human, bike_novice, bike_safe, bike_greedy,
                                    bike_camp_left, bike_camp_strack, bike_camp_centre,
                                    bike_camp_ntrack, bike_camp_gap]}
DEFAULTS = {'bike': ['idle', 'hold_a', 'mash_a', 'random_input',
                     'bike_camp_left', 'bike_camp_strack', 'bike_camp_centre',
                     'bike_camp_ntrack', 'bike_camp_gap',
                     'bike_human', 'bike_safe', 'bike_pro', 'bike_greedy', 'bike_courier']}
