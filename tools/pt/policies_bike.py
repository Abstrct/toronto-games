"""Bike Courier bots.

The no-skill ones (idle, hold_a, mash_a, random_input, and the bike_camp_*
lane campers: steer to one line, hold A, never look) are exploit detectors.
The planners read the event's RAM (player, traffic table) and pick a line
each look, the way a player reads the road: ride lane centres clear of the
rails, cross the tracks at full lock (a TRACK HOP), dodge doors/potholes/
people, grab tokens, and (bike_pro, bike_greedy) tuck in behind the 501 to
draft it.

bike_stylist is the curve bot (see its comment); bike_courier is its careful
base. bike_human is the yardstick for "a decent human finishes": ~15-frame looks,
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
T_XING = 11         # streetcar tracks across the road: everyone crosses them
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
        me['xing'] = None       # rel of the tracks across the road, if on the way
        for i in range(NUM_ENT):
            t = r[E_TYPE + 2 * i]
            if t == T_XING:
                rel = s16((w(E_WY + 2 * i) - me['dist']) & 0xFFFF)
                if rel > 0 and (me['xing'] is None or rel < me['xing']):
                    me['xing'] = rel
            if not t or t > 9:
                continue
            ents.append({'t': t, 'x': w(E_X + 2 * i) / 256, 'rel': s16((w(E_WY + 2 * i) - me['dist']) & 0xFFFF),
                         'vy': s16(w(E_VY + 2 * i)) / 256, 'vx': s16(w(E_VX + 2 * i)) / 256,
                         'timer': w(E_TIMER + 2 * i), 'flags': r[E_FLAGS + 2 * i]})
        return me, ents


def xing_due(me, lag=0.0, early=10):
    """True when B now (landing `lag` frames late) puts the hop over the
    tracks across the road: they're about `early` frames off when it lands
    (a hop is 20 frames in the air)"""
    rel, sp = me.get('xing'), me['speed']
    if rel is None or sp < 1.4:
        return False
    k = rel / sp - lag
    return 3 <= k <= early


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

    hop_rails = False   # B as it's about to cross a rail (a TRACK HOP, not a wobble)
    hop_xing = True     # B for the tracks across the road (HOP THE RAILS: B!)

    def act(self, t, tel, rng):
        m = self.act1(t, tel, rng)
        if self.hop_rails and not m & DOWN:
            me = self.me
            r = self.g.core.peek(self.ev + B_HOPCD, 2)
            vx = me['vx']
            if me['state'] == 0 and r[0] == 0 and r[1] == 0 and self.hop_xing and xing_due(me):
                m |= B
            elif me['state'] == 0 and r[0] == 0 and r[1] == 0 and me['speed'] >= 1.4 and abs(vx) > 0.5:
                for rail in RAILS:
                    k = (rail - me['x']) / vx
                    if 2 <= k <= 10:
                        m |= B
                        break
        return m

    def act1(self, t, tel, rng):
        me, ents = self.read()
        self.me = me
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
    """Rides hard, detours for tokens, drafts the 501, hops the rails it
    crosses, quick eyes (Rob). The title demo's bot."""
    react = (2, 6)
    drafts = True
    hop_rails = True


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
# bike_courier: a careful rider (the curve bot until sprint 4, now the base
# of bike_stylist). It plays like a person with a pad, so a late
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
STOP_SEEN = 230               # src/ev_bike_ent.inc: the stopped car's callout
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


# ---------------------------------------------------------------------------
# bike_stylist: the curve bot. bike_courier's eyes and hands, plus what a
# player picks up after a few runs:
#  * it knows how quick its own hand is: it times its first pedal stroke (how
#    long from deciding to press A until the bike moves) and from then on
#    plans for that hand (+- a quarter) instead of for any hand from 0 to 20;
#  * it hops every rail it crosses (TRACK HOP), and rides over a pothole in
#    its line with a hop instead of swerving round it (POTHOLE HOP) when the
#    hop is free;
#  * it lets traffic come at it and slips out of the way late (CLOSE CALL),
#    but only when the dodge is safe for its own hand: a quick hand waits for
#    the oncoming cars, a slow one only plays chicken with a car it is
#    catching up on, or the 501;
#  * every move is worth more to it while a chain is going (it sees the x2);
#  * how much it plays for style at all is its nerve, which falls with its
#    measured hand: all-in at 0 frames, half at 6, none from 12 (a 250 ms
#    player rides like bike_courier and hops only the potholes in its line).
CLOSE_D = 40                   # src/ev_bike_ent.inc
CLOSE_T = (1, 2, 3, 4, 5, 6)   # parked cars, cars and the 501 (near_tab)
B_HOPD, B_CHAIN, B_CHAINT = 402, 406, 408
B_XOK = 470                    # 1 = a TTC TRANSFER would pay


class bike_stylist(bike_courier):
    close_bonus = 90
    hop_bonus = 45
    hole_bonus = 60
    xfer_bonus = 110    # TTC TRANSFER: steer, then hop a beat later, over both rails
    wobble_cost = 40
    greed = 60
    waits = tuple(range(0, 25, 3))

    def __init__(self):
        bike_courier.__init__(self)
        self.lag = None
        self.delays = (0, 10, 20)
        self.b_at = None

    def read(self):
        me, ents = bike_courier.read(self)
        r = self.g.core.peek(self.ev + B_HOP, 12)
        w = lambda o: r[o - B_HOP] | r[o - B_HOP + 1] << 8
        me['hop_ready'] = ((me['dist'] - w(B_HOPD)) & 0xFFFF) >= 240
        me['chain'] = w(B_CHAIN) if w(B_CHAINT) else 0
        me['hop'] = w(B_HOP)
        me['xok'] = self.g.core.peek(self.ev + B_XOK, 1)[0]
        self.last_read = (me, ents)
        return me, ents

    def calibrate(self, t, me):
        if self.lag is None and me['speed'] > 0:
            self.lag = max(0, t - 1)
            j = self.lag // 4 + (1 if self.lag else 0)
            # safe whether the hand lands right away or late (a slow hand
            # doesn't trust itself to be on time)
            self.delays = tuple(sorted({0, self.lag // 2, self.lag, self.lag + j}))
            # nerve: how much risk it takes for style. A quick hand plays
            # for the chain; a slow one knows better and just rides
            self.nerve = max(0.0, min(1.0, 1 - self.lag / 12))
            self.close_bonus *= self.nerve
            self.hop_bonus *= self.nerve
            self.xfer_bonus *= self.nerve

    def fwd(self, me):
        out, my, v = [], 0.0, me['speed']
        for _ in range(self.H + 30):
            out.append(my)
            v = min(3.0, v + 0.04)
            my += v
        return out

    def hole_hoppable(self, me, e):
        sp = me['speed']
        if sp < 1.5:
            return False
        lag = self.lag if self.lag is not None else 20
        k = (e['rel'] - 32) / sp - lag          # the last frame we could press B
        return k >= me['hopcd'] + 1

    def hazards(self, me, ents):
        keep = [e for e in ents if not (e['t'] == T_HOLE and abs(e['x'] - me['x']) < 14
                                        and self.hole_hoppable(me, e))]
        return bike_courier.hazards(self, me, keep)

    def closers(self, me, ents):
        sp = me['speed']
        out = []
        for e in ents:
            if e['t'] not in CLOSE_T or not self.visible(e):
                continue
            if (e['rel'] > 0 and e['vy'] < sp) or (e['rel'] < 0 and e['vy'] > sp):
                out.append(e)
        return out

    def cost_w(self, me, ents, haz, x_now, x0, t_settle, L, w, fw, closers):
        """bike_courier.cost for a move that starts w frames from now"""
        c = abs(L - x0) * 0.3 + (0 if L == HOME else 6) + w * 0.2
        worst = 0
        for D in (self.delays if abs(L - x0) >= 1 else (0,)):
            f = self.traj(x_now, x0, t_settle, L, D + w)
            for rows in haz:
                for (k, a, b) in rows:
                    if a <= f(k) <= b:
                        worst = max(worst, 2000 - k * 8)
                        break
        c += worst
        for e in ents:
            if e['t'] == T_TOKEN and 20 < e['rel'] < 168 and abs(e['x'] - L) < 8:
                c -= self.greed
        if c >= 1000:
            return c
        # rails crossed on the ground: a RAIL WOBBLE each (speed, the chain,
        # and the timing of everything else in the plan)
        if abs(L - x0) >= 1:
            can_hop = me['hopcd'] <= w + (self.lag or 0) and me['speed'] >= 1.4
            first = None
            for r in sorted(RAILS, key=lambda r: abs(r - x0)):
                if min(x0, L) < r < max(x0, L):
                    k = next(i for i in range(200) if PROG[i] >= abs(r - x0))
                    if first is None:
                        first = k
                        if can_hop and 3 <= k <= 16:
                            continue
                    elif can_hop and 3 <= first <= 16 and k <= 21:
                        continue
                    c += self.wobble_cost
        if t_settle > 0 or abs(x_now - x0) > 2:
            return c
        mult = 1 + 0.25 * min(me['chain'], 4)
        if abs(L - x0) >= 1 and me['hop_ready'] and me['speed'] >= 1.4:
            for r in RAILS:
                if min(x0, L) < r < max(x0, L):
                    k = next(i for i in range(200) if PROG[i] >= abs(r - x0))
                    if 3 <= k <= 16:
                        c -= self.hop_bonus * mult
                    break
            if me['xok'] and self.xfer_frame(x0, L) is not None:
                c -= self.xfer_bonus * mult
        for e in ents:
            if e['t'] == T_HOLE and 40 < e['rel'] < 168 and abs(e['x'] - L) < HW[T_HOLE] and self.hole_hoppable(me, e):
                c -= self.hole_bonus * mult
                break
        if closers and abs(L - x0) >= 1:
            D = self.delays[len(self.delays) // 2]
            f = self.traj(x_now, x0, t_settle, L, D + w)
            for e in closers:
                hw, hh = HW[e['t']], HH[e['t']]
                inpath = False
                prev = e['rel']
                for k in range(1, self.H):
                    rel = e['rel'] + e['vy'] * k - fw[k]
                    if (rel > 0) != (prev > 0):
                        if inpath and abs(f(k) - e['x']) >= hw + 1:
                            c -= self.close_bonus * mult
                        break
                    prev = rel
                    if abs(f(k) - e['x']) < hw - 1 and 0 <= abs(rel) - hh < CLOSE_D - 4:
                        inpath = True
        return c

    def xfer_frame(self, x0, L):
        """a move from rest at x0 to L over both rails of a track: the frame
        after the steer to press B so the hop is over both, else None"""
        rs = sorted((r for r in RAILS if min(x0, L) < r < max(x0, L)), key=lambda r: abs(r - x0))
        if len(rs) < 2 or abs(rs[0] - rs[1]) > 30:
            return None
        k1 = next(i for i in range(200) if PROG[i] >= abs(rs[0] - x0))
        k2 = next(i for i in range(200) if PROG[i] >= abs(rs[1] - x0))
        p = max(k2 - 20, MINCHG)
        return p if p <= k1 - 1 else None

    def act(self, t, tel, rng):
        self.rng = rng
        me, ents = self.read()
        self.calibrate(t, me)
        if self.b_at is not None and t >= self.b_at:
            # the beat after the steer: hop now (TTC TRANSFER)
            self.b_at = None
            if me['state'] == 0 and me['hopcd'] == 0 and not self.cur & B:
                if t < self.cmd_end:
                    self.cmd_mask |= B
                return self.out(t, self.cur | B)
        m = self.decide(t, me, ents)
        lag = self.lag or 0
        # the tracks across the road: hop them
        if (me['state'] == 0 and me['hopcd'] == 0 and not m & B and xing_due(me, lag)
                and t - self.last_change >= 2):
            m |= B
            if t < self.cmd_end:
                self.cmd_mask |= B
            return self.out(t, m)
        # a pothole in our line: hop it
        if (me['state'] == 0 and me['hopcd'] == 0 and me['speed'] >= 1.4 and not m & B
                and t - self.last_change >= 2):
            for e in ents:
                if e['t'] != T_HOLE or not self.visible(e):
                    continue
                land = e['rel'] - me['speed'] * lag
                if abs(e['x'] - me['x'] - me['vx'] * lag) < HW[T_HOLE] + 3 and 30 < land <= 58:
                    m |= B
                    if t < self.cmd_end:
                        self.cmd_mask |= B
                    return self.out(t, m)
        return m

    def decide(self, t, me, ents):
        """bike_courier.act, choosing (line, wait) instead of a line"""
        if t - self.last_change < MINCHG:
            return self.out(t, self.cur)
        if me['state'] != 0:
            self.reset()
            return self.out(t, A)
        if me['speed'] < 0.3 and t >= self.brake_until + 30 and t >= self.cmd_end:
            self.stall = getattr(self, 'stall', 0) + 1
            if self.stall > 20:
                self.stall = 0
                return self.out(t, 0)
        else:
            self.stall = 0
        if t < self.cmd_end:
            return self.out(t, self.cmd_mask)
        base = DOWN if t < self.brake_until else A
        if t < self.next_look:
            return self.out(t, base)
        # glances aren't a metronome, even for a quick player (so no two runs
        # are the same run)
        self.next_look = t + self.look + self.rng.randint(-1, 1)
        x = me['x']
        if t < self.busy_until and self.exp_x is not None:
            x0, t_settle = self.exp_x, self.busy_until - t
        else:
            x0, t_settle = x, 0
            self.exp_x = x
        haz = self.hazards(me, ents)
        fw = self.fwd(me)
        closers = self.closers(me, ents) if t_settle == 0 else []
        costs = {}
        for L in LANES:
            for w in (self.waits if closers and self.close_bonus and abs(L - x0) >= 1 else (0,)):
                costs[(L, w)] = self.cost_w(me, ents, haz, x, x0, t_settle, L, w, fw, closers)
        best = min(costs, key=costs.get)
        near = min(LANES, key=lambda L: abs(L - x0))
        if abs(near - x0) <= SETTLE and costs[(near, 0)] <= costs[best] + 4:
            best = (near, 0)
        if costs[best] >= 1000 and me['speed'] > 1.0:
            self.brake_until = t + 12
            base = DOWN
        elif t >= self.brake_until:
            base = A
        L, w = best
        if w:
            return self.out(t, base)        # not yet: let it come
        d = L - x0
        if abs(d) <= SETTLE - 1:
            return self.out(t, base)
        n = min(range(MINCHG, 199), key=lambda k: abs(DISP[k] - abs(d)))
        m = (RIGHT if d > 0 else LEFT) | base
        if self.hops and me['speed'] >= 1.4 and me['hopcd'] == 0 and t >= self.busy_until:
            p = self.xfer_frame(x0, L) if self.xfer_bonus and me['hop_ready'] and me['xok'] else None
            if p is not None:
                self.b_at = t + p
            else:
                for r in RAILS:
                    if min(x0, L) < r < max(x0, L):
                        dr = abs(r - x0)
                        k = next(i for i in range(200) if PROG[i] >= dr)
                        if 3 <= k <= 16:
                            m |= B
                        break
        self.cmd_mask = m
        self.cmd_end = t + n
        self.exp_x = L
        self.busy_until = t + n + 26
        return self.out(t, m)


# ---------------------------------------------------------------------------
# bike_commuter: the curve bot since sprint 5. A careful first-timer who read
# the card once, the way Dana and Gord rode in round 5 (bike_stylist plans
# every line with exact traffic speeds and weaves for style, so it never sat
# in the bike lane long enough to meet what they met):
#  * it rides the bike lane and only leaves it for something in its way;
#  * it sees what is on screen (the ~45 frames above the rider, plus the
#    501's warning sign behind) and glances every 4-7 frames;
#  * something in its line: a pothole gets a hop about half the time (the
#    card says B HOP), otherwise it steers for the nearest line that looks
#    clear, holding the pad until it is about there (no counter-steer), and
#    comes home to the bike lane once the way is clear;
#  * after a few seconds it knows roughly how late its own thumb is and
#    presses B that much early (a first-timer's sense of it: +- a quarter);
#  * now and then it misses a hazard on a glance (sloppy).
class bike_commuter(_Reader):
    look = (4, 7)
    sight = 165
    margin = 3
    hop_pref = 0.5
    rail_hop = 0.5      # crosses a rail with a hop this often (B HOP RAILS)
    greedy = True       # detours for a line of tokens
    reach = 50          # ...this far from where it is
    sloppy = 0.05
    hold = 70           # frames ahead that count as "in my way"
    xing_hop = 0.8      # hops the tracks across the road (HOP THE RAILS: B!)

    def __init__(self):
        self.g = None
        self.target = HOME
        self.next_look = 0
        self.lag = None
        self.hopping = {}       # hole key -> True (hop it) / False (steer)
        self.b_until = -1
        self.brake = False
        self.move = (0, -1, -1)

    def read(self):
        me, ents = _Reader.read(self)
        r = self.g.core.peek(self.ev + B_HOPCD, 2)
        me['hopcd'] = r[0] | r[1] << 8
        r = self.g.core.peek(self.ev + B_HOP, 2)
        me['hop'] = r[0] | r[1] << 8
        return me, ents

    def threats(self, me, ents, rng):
        """[(kind, x_at_arrival, half width, frames to arrival, key)]"""
        out = []
        sp = me['speed']
        for e in ents:
            t, rel = e['t'], e['rel']
            if t in (T_TOKEN, 10):
                continue
            behind = t == T_TRAM_N and -160 <= rel < -20 and e['vy'] > sp
            # CAR IN BIKE LANE. AGAIN. comes up just before the car does
            stopped = t == T_PARKED and e['x'] < 200 and rel <= STOP_SEEN
            if not behind and not stopped and not -30 <= rel <= self.sight:
                continue
            if self.sloppy and rng.random() < self.sloppy:
                continue
            hh = HH[t]
            close = sp - e['vy']
            if rel > hh:
                if close <= 0.05:
                    continue
                ta = (rel - hh) / close
            elif rel < -hh:
                if close >= -0.05:
                    continue
                ta = (rel + hh) / close
            else:
                ta = 0
            if ta > self.hold:
                continue
            ex = e['x'] + e['vx'] * ta
            key = (t, round(e['x']), me['dist'] + rel)
            if t == T_PED:
                out.append((t, (e['x'] + ex) / 2, HW[t] + abs(ex - e['x']) / 2, ta, key))
            else:
                out.append((t, ex, HW[t], ta, key))
            if t == T_PARKED and e['flags'] & 2:
                out.append((0, e['x'] - 20, 10, ta, key))
        return out

    def blocked(self, threats, L, x, upto=None):
        lo, hi = min(x, L), max(x, L)
        for (k, cx, hw, ta, key) in threats:
            if upto is not None and ta > upto:
                continue
            w = hw + self.margin
            if cx - w < hi and lo < cx + w:
                # in the way of the line, or of the way over to it
                if abs(cx - L) < w or ta < 8 + abs(L - x) / 1.5:
                    return True
        return False

    def act(self, t, tel, rng):
        self._rng = rng
        me, ents = self.read()
        if me['state'] != 0:
            self.target = HOME
            self.brake = False
            self.move = (0, -1, -1)
            return A
        if self.lag is None and me['speed'] > 0:
            self.lag = max(0, t - 1)
        lag = self.lag or 0
        x, sp = me['x'], me['speed']
        if t >= self.next_look:
            self.next_look = t + rng.randint(*self.look)
            self.plan(me, ents, rng, t)
        # steering is a motor program: hold the pad for as long as the move
        # takes (judged by eye), let go, see where it landed, touch it up
        dirn, end, settle = self.move
        if t >= settle and abs(self.target - x) >= 5:
            self.start_move(self.target, x, t)
            dirn, end, settle = self.move
        m = dirn if t < end else 0
        m |= DOWN if self.brake else A
        # the hop: B when the hole is about two lengths off (pressed early
        # by what it thinks its thumb takes)
        if t < self.b_until:
            m |= B
        elif me['hopcd'] == 0 and me.get('xing') and self.xing_try(me) and \
                xing_due(me, lag * rng.uniform(0.75, 1.25), early=8):
            self.b_until = t + 3
            m |= B
        elif me['hopcd'] == 0 and sp >= 1.4:
            for e in ents:
                if e['t'] != T_HOLE or not 0 < e['rel'] <= self.sight:
                    continue
                key = (T_HOLE, round(e['x']), me['dist'] + e['rel'])
                if not self.hopping.get(key) or abs(e['x'] - x) >= HW[T_HOLE] + 2:
                    continue
                if e['rel'] - sp * lag * rng.uniform(0.75, 1.25) <= 10 * sp:
                    self.b_until = t + 3
                    m |= B
                break
        return m

    def xing_try(self, me, rng=None):
        key = (me['dist'] + me['xing']) // 50
        if key not in self.hopping:
            self.hopping[key] = self._rng.random() < self.xing_hop
        return self.hopping[key]

    def start_move(self, L, x, t):
        d = L - x
        n = min(range(1, 199), key=lambda k: abs(DISP[k] - abs(d)))
        self.move = (RIGHT if d > 0 else LEFT, t + n, t + n + 12 + (self.lag or 0))

    def plan(self, me, ents, rng, t):
        # where the bike is headed: a move it has pressed for but not seen
        # land yet (the efference copy: it knows what its thumb just did)
        x = self.target if t < self.move[2] else me['x']
        th = self.threats(me, ents, rng)
        # holes in my line: hop or steer? (decided once per hole)
        for (k, cx, hw, ta, key) in th:
            if k == T_HOLE and key not in self.hopping and abs(cx - x) < hw + self.margin:
                self.hopping[key] = rng.random() < self.hop_pref
        hop_ok = me['speed'] >= 1.4
        live = [h for h in th if not (h[0] == T_HOLE and self.hopping.get(h[4]) and hop_ok)]
        cur = self.target
        self.brake = False
        if not self.blocked(live, cur, x):
            # a line of tokens near by, and the way to it clear: go and get
            # them (TOKENS PAY 50 ON DELIVERY); else home to the bike lane,
            # once the last move has landed
            tl = self.token_line(me, ents, live, x) if self.greedy else None
            if tl == cur:
                return
            if tl is not None and t >= self.move[2]:
                self.go(tl, x, me, rng, t)
                return
            if cur != HOME and t >= self.move[2] and not self.blocked(live, HOME, x):
                self.go(HOME, x, me, rng, t)
            return
        # find the nearest line that looks clear
        for L in sorted(LANES, key=lambda L: abs(L - x)):
            if not self.blocked(live, L, x):
                self.go(L, x, me, rng, t)
                return
        self.brake = me['speed'] > 1.0

    def token_line(self, me, ents, live, x):
        best = None
        for e in ents:
            if e['t'] != T_TOKEN or not 30 < e['rel'] < self.sight:
                continue
            L = min(LANES, key=lambda L: abs(L - e['x']))
            if abs(L - e['x']) > 8 or abs(L - x) > self.reach:
                continue
            if self.blocked(live, L, x):
                continue
            if best is None or e['rel'] < best[0]:
                best = (e['rel'], L)
        return best and best[1]

    def go(self, L, x, me, rng, t):
        if L == self.target:
            return
        self.target = L
        self.start_move(L, x, t)
        if me['hopcd'] == 0 and me['speed'] >= 1.4 and any(min(x, L) < r < max(x, L) for r in RAILS) \
                and rng.random() < self.rail_hop:
            self.b_until = t + 3


CURVE = {'bike': 'bike_rider'}

POLICIES = {c.__name__: c for c in [bike_commuter, bike_stylist, bike_courier, bike_ace, bike_pro, bike_human, bike_novice, bike_safe, bike_greedy,
                                    bike_camp_left, bike_camp_strack, bike_camp_centre,
                                    bike_camp_ntrack, bike_camp_gap]}
DEFAULTS = {'bike': ['idle', 'hold_a', 'mash_a', 'random_input',
                     'bike_camp_left', 'bike_camp_strack', 'bike_camp_centre',
                     'bike_camp_ntrack', 'bike_camp_gap',
                     'bike_human', 'bike_safe', 'bike_pro', 'bike_greedy', 'bike_courier', 'bike_stylist',
                     'bike_commuter', 'bike_rider']}


# bike_rider: the curve bot. Whoever is holding the pad: a quick hand (under
# ~10 frames, it finds out on its first pedal stroke) has played this before
# and rides for style (bike_stylist); anyone slower rides like a careful
# first-timer (bike_commuter).
class bike_rider(bike_commuter):
    FAST = 10

    def __init__(self):
        bike_commuter.__init__(self)
        self.sty = bike_stylist()

    def act(self, t, tel, rng):
        if self.lag is None:
            self.sty.game = self.game
            ms = self.sty.act(t, tel, rng)
            mc = bike_commuter.act(self, t, tel, rng)
            return mc if self.lag is None or self.lag >= self.FAST else ms
        if self.lag < self.FAST:
            return self.sty.act(t, tel, rng)
        return bike_commuter.act(self, t, tel, rng)


class bike_dana(bike_commuter):
    """Steers round everything, never hops (Dana, round 5)."""
    hop_pref = 0.0
    rail_hop = 0.0
    xing_hop = 0.0


class bike_gord(bike_commuter):
    """Hops every pothole in the bike lane (Gord, round 5)."""
    hop_pref = 1.0


POLICIES.update({c.__name__: c for c in [bike_rider, bike_dana, bike_gord]})
