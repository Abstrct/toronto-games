"""Off-Leash Alert bots.

Skilled bots peek event RAM (dog states and positions, see the `=` offsets
at the top of src/ev_park.s) through the Game that run_bot is driving; they
find it on the caller's frame, so pt.py needs no hook. No-skill bots are
exploit detectors: holding UP, mashing B while walking, random input.
"""
import os
import sys
DEBUG = os.environ.get("PARK_DEBUG")

from policies import Policy, idle, hold_up, random_input, A, B, X, UP, DOWN, LEFT, RIGHT

# ev_ram offsets (src/ev_park.s)
K_X, K_Y, K_DASH, K_DASHCD, K_BALLS, B_STATE = 0, 2, 16, 18, 26, 48
K_STATE, K_STUM = 10, 288
K_LIVE, K_CALM, K_ARMED, K_CHAIN = 540, 542, 544, 548
D_SLOT, D_X, D_Y, D_STATE, D_KIND = 80, 96, 112, 176, 208
DS_ALERT, DS_CHARGE, DS_SIT, DS_CROUCH, DS_LUNGE = 1, 2, 7, 9, 10
THREAT = (DS_ALERT, DS_CHARGE, DS_CROUCH, DS_LUNGE)
WINDOW = (DS_CROUCH, DS_LUNGE)          # the red "!", then the lunge: B pays by hand
NUM_ENT = 8


def _game():
    f = sys._getframe(2)
    while f is not None:
        g = f.f_locals.get('g')
        if g is not None and hasattr(g, 'core') and hasattr(g, 'sym'):
            return g
        f = f.f_back
    return None


class _Peeker(Policy):
    """Reads the walker and the dogs every frame."""

    def __init__(self):
        self.g = None
        self.prev = 0

    def view(self):
        if self.g is None:
            self.g = getattr(self, "game", None) or _game()
        base = self.g.sym['ev_ram']
        r = self.g.core.peek(base, 600)
        w = lambda o: r[o] | r[o + 1] << 8
        me = {'x': r[K_X + 1], 'y': w(K_Y), 'dash': w(K_DASH), 'cd': w(K_DASHCD),
              'balls': r[K_BALLS], 'ball': r[B_STATE], 'state': r[K_STATE],
              'stum': w(K_STUM), 'live': r[K_LIVE], 'armed': r[K_ARMED], 'chain': r[K_CHAIN]}
        dogs = []
        for i in range(NUM_ENT):
            if r[D_SLOT + 2 * i] == 0xFF:
                continue
            dogs.append({'i': i, 'x': r[D_X + 2 * i + 1], 'y': w(D_Y + 2 * i), 'st': r[D_STATE + 2 * i],
                         'kind': r[D_KIND + 2 * i]})
        return me, dogs

    def press(self, m, btn):
        """an edge: only if the button was up last frame"""
        return m | btn if not (self.prev & btn) else m

    def done(self, m):
        self.prev = m
        return m


def _toward(me, d, m=0):
    """steer toward a dog (a sitting one, for a pat)"""
    if d['x'] < me['x'] - 3:
        m |= LEFT
    elif d['x'] > me['x'] + 3:
        m |= RIGHT
    if d['y'] < me['y'] - 2:
        m |= UP
    elif d['y'] > me['y'] + 2:
        m |= DOWN
    return m


def _sitter(me, dogs, reach):
    best = None
    for d in dogs:
        if d['st'] != DS_SIT:
            continue
        dist = abs(d['x'] - me['x']) + abs(d['y'] - me['y'])
        if dist < reach and (best is None or dist < best[0]):
            best = (dist, d)
    return best[1] if best else None


class park_ace(_Peeker):
    """Perfect eyes: sidesteps every lunging dog late in his leap (CLOSE SHAVE),
    stepping INTO the side he sprang from (MATADOR), a ball if the step is
    on cooldown, and pats every dog it dodged (DODGE 'N' PAT)."""
    dodge_at = 11            # frames after he springs (the flash): 9-16 is the shave
    matador = True

    def __init__(self):
        super().__init__()
        self.sprung = {}     # dog slot -> (frame he sprang, the side he sprang from)
        self.pst = {}

    def act(self, t, tel, rng):
        me, dogs = self.view()
        for d in dogs:
            if d['st'] == DS_LUNGE and self.pst.get(d['i']) != DS_LUNGE:
                self.sprung[d['i']] = (t, LEFT if d['x'] <= me['x'] else RIGHT)
            self.pst[d['i']] = d['st']
        m = UP
        sit = _sitter(me, dogs, 90) if not me['live'] else None
        if sit is not None:
            return self.done(_toward(me, sit))
        threat = None
        for d in dogs:
            if d['st'] == DS_CHARGE:
                m &= ~UP                              # he's on his way: let him come (no outrunning him to Dundas)
            if d['st'] not in WINDOW:
                continue
            dist = abs(d['x'] - me['x']) + abs(d['y'] - me['y'])
            if threat is None or dist < threat[0]:
                threat = (dist, d)
        if threat is not None:
            dist, d = threat
            m &= ~UP                                  # stand and face him
            sp = self.sprung.get(d['i'])
            if d['st'] == DS_LUNGE and sp and t - sp[0] >= self.dodge_at:
                if me['cd'] == 0:
                    m = self.press(m, B)
                    if self.matador:
                        m |= sp[1]
                elif me['dash'] == 0 and me['balls'] and me['ball'] == 0:
                    m = self.press(m, A)
        # drift back toward the middle of the park between dogs
        if threat is None and not me['dash']:
            if me['x'] < 100 and t % 3 == 0:
                m |= RIGHT
            elif me['x'] > 156 and t % 3 == 0:
                m |= LEFT
        return self.done(m)


class park_dawdle(park_ace):
    """park_ace walking north only part of the time (Rob's timeout farm, round 6):
    with one go per dog, a slower walk must never pay more than a fast one."""
    duty = 45

    def act(self, t, tel, rng):
        m = super().act(t, tel, rng)
        if (t % 100) >= self.duty:
            m &= ~UP
        return m


def _dawdle_at(n):
    return type('park_dawdle%d' % n, (park_dawdle,), {"duty": n})


DAWDLE = [_dawdle_at(n) for n in (30, 45, 60, 80)]


class park_fetcher(_Peeker):
    """Throws a ball at every dog that spots it; dodges when out of balls."""

    def act(self, t, tel, rng):
        me, dogs = self.view()
        m = UP
        near = None
        for d in dogs:
            if d['st'] not in THREAT:
                continue
            dist = abs(d['x'] - me['x']) + abs(d['y'] - me['y'])
            if near is None or dist < near[0]:
                near = (dist, d['st'])
        if near:
            if me['balls'] and me['ball'] == 0:
                m = self.press(m, A)
            elif near[1] in WINDOW and near[0] < 34 and me['cd'] == 0:
                m = self.press(m, B)
        return self.done(m)


class park_sloppy(_Peeker):
    """A decent human: presses B anywhere from 14 to 38 px out, and misses one charge in eight."""

    def __init__(self):
        super().__init__()
        self.aim = {}

    def act(self, t, tel, rng):
        me, dogs = self.view()
        m = UP
        live = set()
        for d in dogs:
            if d['st'] not in WINDOW:
                continue
            live.add(d['i'])
            if d['i'] not in self.aim:          # a new charge: how well will I read it?
                self.aim[d['i']] = None if rng.random() < 0.12 else 26 + rng.randint(-12, 12)
            aim = self.aim[d['i']]
            dist = abs(d['x'] - me['x']) + abs(d['y'] - me['y'])
            if aim is not None and dist < aim and me['cd'] == 0:
                m = self.press(m, B)
        for i in list(self.aim):
            if i not in live:
                del self.aim[i]
        return self.done(m)


class park_timing(Policy):
    """The old blind bot: walk up, sidestep on a fixed rhythm."""
    every = 2

    def act(self, t, tel, rng):
        m = UP
        ph = t % 50
        if ph < 4:
            m |= B | rng.choice([LEFT, RIGHT])
        if t % 90 == 0:
            m |= A
        return m


class up_mash_b(Policy):
    trivial = True
    """No skill: hold UP and hammer B."""

    def act(self, t, tel, rng):
        return UP | (B if t % 8 < 4 else 0)


class up_mash_ab(Policy):
    trivial = True
    """No skill: hold UP and hammer A and B."""

    def act(self, t, tel, rng):
        return UP | (B if t % 8 < 4 else A)


class leash_human(_Peeker):
    """A decent first-timer: sees the screen ~15 frames late (12-20), reads the
    "!" and presses B once to get set (or, a third of the time, tries to time it
    by hand and is often early or late), forgets one dog in ten, throws a ball
    now and then, wanders a bit off the line, and goes for a pat half the time."""

    def __init__(self):
        super().__init__()
        self.hist = []
        self.plan = {}
        self.lag = None
        self.wander = 0
        self.patting = False

    def act(self, t, tel, rng):
        cur = self.view()
        self.hist.append(cur)
        if self.lag is None:
            self.lag = rng.randint(12, 20)
        me, dogs = self.hist[-self.lag] if len(self.hist) > self.lag else self.hist[0]
        now_me = cur[0]
        if len(self.hist) > 64:
            self.hist.pop(0)
        m = UP
        # a bit of aimless steering
        if t % 90 == 0:
            self.wander = rng.choice([0, 0, 0, LEFT, RIGHT])
        if t % 90 < 20:
            m |= self.wander
        if now_me['x'] < 70:
            m = (m & ~LEFT) | RIGHT
        elif now_me['x'] > 186:
            m = (m & ~RIGHT) | LEFT
        live = set()
        for d in dogs:
            if d['st'] not in THREAT:
                continue
            live.add(d['i'])
            if d['i'] not in self.plan:
                r = rng.random()
                if r < 0.10:
                    self.plan[d['i']] = ('miss', 0)
                elif r < 0.62:
                    self.plan[d['i']] = ('arm', 0)
                elif r < 0.72 and me['balls']:
                    self.plan[d['i']] = ('ball', 0)
                else:
                    self.plan[d['i']] = ('time', 30 + rng.randint(-14, 14))
            kind, aim = self.plan[d['i']]
            dd, mm = d, me
            if kind == 'time':      # timing by eye anticipates: judged on the real gap
                dd = next((e for e in cur[1] if e['i'] == d['i']), d)
                mm = now_me
            dist = abs(dd['x'] - mm['x']) + abs(dd['y'] - mm['y'])
            if kind == 'arm':
                m = self.press(m, B)
                self.plan[d['i']] = ('done', 0)
            elif kind == 'ball' and now_me['ball'] == 0:
                m = self.press(m, A)
                self.plan[d['i']] = ('done', 0)
            elif kind == 'time' and d['st'] in WINDOW and dist < aim:
                m = self.press(m, B)
                self.plan[d['i']] = ('done', 0)
        for i in list(self.plan):
            if i not in live:
                del self.plan[i]
        if not live:
            sit = _sitter(me, dogs, 60)
            if sit is not None and (self.patting or rng.random() < 0.02):
                self.patting = True
                return self.done(_toward(now_me, sit))
            self.patting = False
        return self.done(m)


class leash_nervous(leash_human):
    """leash_human with jumpy thumbs: a dog that's merely on screen and close
    (not barking yet) gets a nervous B one time in four, and an "!" now and
    then gets a second B. A nervous honest player must still finish."""

    def __init__(self):
        super().__init__()
        self.jumped = set()

    def act(self, t, tel, rng):
        m = super().act(t, tel, rng)
        me, dogs = self.hist[-1]
        for d in dogs:
            if d['st'] != 0 or d['i'] in self.jumped:
                continue
            if abs(d['x'] - me['x']) + abs(d['y'] - me['y']) < 110:
                self.jumped.add(d['i'])
                if rng.random() < 0.25:
                    m = self.press(m, B)
        if me['live'] and rng.random() < 0.01:
            m = self.press(m, B)
        return self.done(m)


K_CAM = 34
K_TACKLE, K_DODGED, K_HAND, K_SHAVES, K_HURT = 28, 30, 580, 554, 582


class park_hand(_Peeker):
    """The CURVE bot: a practised player with a human hand.

    It knows nothing about its own reaction time. It reacts only to what's
    on screen: a dog is a threat from the frame its white "!" shows (over the
    dog or pinned to the bottom edge); the red "!" says he's crouched to
    spring, and the lunge is the dog leaving the ground (he flashes white).
    Every leap takes the same LEAP frames to land, and the back half of it
    is the shave. It learns, as a player does:
      - each kind's crouch (doodle, lab, husky, corgi look different), from
        watching the red "!" turn into a lunge;
      - its own lag, from how far into the leap its walker visibly steps
        compared with where it meant to, and from the popups (NICE: too
        early; TACKLED: too late).
    The first dog it gets set on the "!" (as the coach says). With one heart
    left, or a dog coming from off the bottom, it plays safe the same way.
    A kind it hasn't seen spring yet: B as soon as the red "!" shows (NICE
    TIMING). A kind it knows: B timed for late in the lunge (CLOSE SHAVE),
    stepping into his side (MATADOR) while its hand is steady; a hand that
    scatters a lot goes back to NICE TIMING. It has walked the park before,
    so it starts out knowing roughly how long each kind crouches (KNOWN).
    It stands still while a dog is on it, and goes back for a pat when the
    dog it dodged sits within easy reach."""

    KNOWN = {0: 29, 1: 26, 2: 25, 3: 33}   # crouch frames by kind, from earlier walks

    O0 = 10.0                # first guess at its own lag (frames): it leads a little
    safe = False             # park_safe: gets set on every "!" (the safe line)
    nice_only = False        # park_nice: never tries the shave
    LEAP = 16                # frames from his flash to landing on me (the same every leap, by eye)
    SHAVE_AT = 12.5          # frames into the leap the step should land (9-16 is the shave: early = NICE, late = tackled)

    def __init__(self):
        super().__init__()
        self.O = self.O0
        self.C = dict(self.KNOWN)  # kind -> crouch frames (seen this walk, or known)
        self.crouch = {}         # dog slot -> (t, kind, gap) when the red "!" showed
        self.leap = {}           # dog slot -> (t, gap) when he sprang
        self.plan = {}           # dog slot -> 'arm' / 'done' / press frame
        self.prevst = {}
        self.hold_b = 0
        self.side = 0
        self.cnt = None
        self.timing = None       # (dog, aim) of the press in flight
        self.errs = []
        self.prev_dash = 0
        self.dogs_seen = 0
        self.cool = 0
        self.sh_try = self.sh_ok = 0     # shave attempts, and the ones not tackled
        self.last = None

    def shaky(self):
        """tackled lately, or a hand whose last few steps (after the first few,
        while it found its lag) landed well off: NICE TIMING for a while
        (it keeps trying the shave one dog in four)"""
        if self.dogs_seen < self.cool:
            return True
        if self.sh_try >= 3 and self.sh_ok < 0.7 * self.sh_try and self.dogs_seen % 5:
            return True                       # the shave isn't paying for my hand
        e = self.errs[3:][-3:]
        return len(e) >= 2 and sum(abs(x) for x in e) / len(e) > 3 and self.dogs_seen % 4

    def learn(self, t, me, dogs):
        r = self.g.core.peek(self.g.sym['ev_ram'], 600)
        w = lambda o: r[o] | r[o + 1] << 8
        cnt = (w(K_TACKLE), w(K_DODGED), w(K_HAND), w(K_SHAVES))
        if self.cnt is None:
            self.cnt = cnt
        tk, dd, hd, sh = (c - p for c, p in zip(cnt, self.cnt))
        self.cnt = cnt
        for d in dogs:
            was = self.prevst.get(d['i'])
            if d['st'] == DS_CROUCH and was != DS_CROUCH:
                self.crouch[d['i']] = (t, d['kind'], abs(d['x'] - me['x']) + abs(d['y'] - me['y']))
            if d['st'] == DS_LUNGE and was == DS_CROUCH and d['i'] in self.crouch:
                c = t - self.crouch[d['i']][0]                     # his rhythm, seen
                self.C[d['kind']] = (self.C[d['kind']] * 3 + c) / 4 if d['kind'] in self.C else c
                self.leap[d['i']] = (t, abs(d['x'] - me['x']) + abs(d['y'] - me['y']))
            self.prevst[d['i']] = d['st']
        # the walker visibly steps aside: how far into his leap? (frames late)
        if me['dash'] and not self.prev_dash and self.timing and self.last:
            i, shave = self.timing
            pme, pdogs = self.last
            d = next((e for e in pdogs if e['i'] == i), None)
            err = None
            if d is not None and d['st'] == DS_LUNGE and i in self.leap:
                err = (t - self.leap[i][0]) - self.SHAVE_AT
            elif d is not None and d['st'] == DS_CROUCH and i in self.crouch:
                t0, kind, gap = self.crouch[i]     # he hadn't even sprung
                err = (t - t0 - self.C.get(kind, 28)) - self.SHAVE_AT
            if err is not None and shave:
                self.errs.append(err)
                self.O += 0.8 * max(-8.0, min(6.0, err))
                if DEBUG: print("  step err %.1f frames, dog was %s, O now %.1f" % (err, d["st"], self.O))
        self.prev_dash = me['dash']
        self.last = (me, dogs)
        if self.timing:
            if tk:
                self.O += 4                  # too late: lean earlier
                self.cool = self.dogs_seen + 4
                self.sh_try += self.timing[1]
                self.errs.append(6)
                self.timing = None
            elif dd:
                if self.timing[1]:
                    self.sh_try += 1
                    self.sh_ok += 1
                self.timing = None
        self.O = max(-2.0, min(40.0, self.O))
        return r[K_HURT]

    def act(self, t, tel, rng):
        me, dogs = self.view()
        hurt = self.learn(t, me, dogs)
        cam = self.g.core.peek(self.g.sym['ev_ram'] + K_CAM, 2)
        cam = cam[0] | cam[1] << 8
        m = UP
        live = set()
        for d in dogs:
            if d['st'] not in THREAT:
                continue
            live.add(d['i'])
            dist = abs(d['x'] - me['x']) + abs(d['y'] - me['y'])
            if d['i'] not in self.plan:
                self.plan[d['i']] = None
                self.dogs_seen += 1
            plan = self.plan[d['i']]
            if d['st'] != DS_ALERT:
                m &= ~UP                          # he's coming: stand and face him
            if plan == 'done':
                continue
            behind = d['y'] - cam > 192           # coming from off the bottom: no read on it
            if plan is None and (self.dogs_seen == 1 or hurt >= 2 or behind or self.safe):
                if not me['armed']:
                    self.hold_b = 8               # get set on the "!"
                self.plan[d['i']] = 'done'
                continue
            if d['st'] not in WINDOW or d['i'] not in self.crouch:
                continue
            t0, kind, gap = self.crouch[d['i']]
            if plan is None:                       # the red "!": shave or NICE?
                side = 0
                shave = kind in self.C and not self.nice_only and not self.shaky()
                if shave:                          # OLE: step into the side he faces from
                    side = LEFT if d['x'] <= me['x'] else RIGHT
                self.plan[d['i']] = plan = (shave, side)
            shave, side = plan
            if not shave:
                when = t0                          # B on the red "!": NICE TIMING
            elif d['i'] in self.leap:              # he's sprung (the flash): time it off that
                when = self.leap[d['i']][0] + self.SHAVE_AT - self.O
            else:                                  # his rhythm, from the crouch
                when = t0 + self.C[kind] + self.SHAVE_AT - self.O
            if t >= when:
                if DEBUG:
                    print('  press t=%d dog %d st %d dist %d cd %d shave %s O %.1f' % (t, d['i'], d['st'], dist, me['cd'], shave, self.O))
                self.hold_b = 8
                self.side = side
                self.plan[d['i']] = 'done'
                self.timing = (d['i'], shave)
        for i in list(self.plan):
            if i not in live:
                del self.plan[i]
                self.crouch.pop(i, None)
                self.leap.pop(i, None)
        if self.hold_b:
            self.hold_b -= 1
            m |= B | self.side
        elif not live and not me['dash']:
            sit = _sitter(me, dogs, 70)
            if sit is not None:
                m = _toward(me, sit)
            if me['x'] < 100:
                m |= RIGHT
            elif me['x'] > 156:
                m |= LEFT
        # X does nothing in the park. Flipping it now and then re-sends the
        # held mask: pt.py's jittered hand can land an old decision after a
        # newer one, which would otherwise stick (a human lets go of DOWN)
        if (t >> 4) & 1:
            m |= X
        return self.done(m)


class leash_prompt(_Peeker):
    """Does only what the screen says, as a first-timer who read the card once
    (run it at 20-25 frames of latency: pt.py curve park -p leash_prompt).
    Holds UP (the walk is north). B when the callout says PRESS B or B NOW,
    and B whenever a "!" shows over a dog (the card: SAFE: B ON !); the bold
    variant waits for the red "!" instead (BOLD: B ON RED !). It never pats,
    throws or steers: a prompt-follower must still finish and medal."""
    red = False

    def __init__(self):
        super().__init__()
        self.said = ''
        self.seen = set()

    def act(self, t, tel, rng):
        me, dogs = self.view()
        m = UP
        line = self.game.text_rows()[4].strip(' .')
        if line != self.said:
            self.said = line
            if 'PRESS B' in line or 'B NOW' in line:
                m = self.press(m, B)
        for d in dogs:
            st = d['st']
            want = DS_CROUCH if self.red else DS_ALERT
            if st == want and d['i'] not in self.seen:
                self.seen.add(d['i'])
                m = self.press(m, B)
            elif st not in THREAT:
                self.seen.discard(d['i'])
        if self.prev & B and not (m & B):
            pass
        return self.done(m)


class leash_prompt_red(leash_prompt):
    """leash_prompt on the bold line: B on every red "!" (BOLD: B ON RED !)"""
    red = True


class leash_cue(Policy):
    """Watches the screen for one thing only: the white flash a dog gives as
    he springs (sprite palette 7 in OAM, the tell). Then B with the d-pad
    toward the side he's facing from (an unflipped dog faces right: he's on
    your left). It never gets set on the "!", never reads a dog's state or
    timer. Run it at a practised human's 10-12 frames to check the tell
    leaves a window a hand can hit:
        pt.py curve park -p leash_cue -l 10,12"""

    def __init__(self):
        self.was = False
        self.hold = 0
        self.side = 0

    def flash(self):
        g = self.game
        oam = g.core.peek(g.sym['oam_buf'], 512)
        side = None
        for i in range(128):
            y, attr = oam[i * 4 + 1], oam[i * 4 + 3]
            if y < 224 and (attr >> 1) & 7 == 7:
                side = RIGHT if attr & 0x40 else LEFT
        return side

    def act(self, t, tel, rng):
        side = self.flash()
        if side and not self.was:
            self.hold, self.side = 6, side
        self.was = bool(side)
        m = UP
        if self.hold:
            self.hold -= 1
            m |= B | self.side
        return m


class _blind(Policy):
    """No skill: hold UP and tap B on a metronome, never looking at a dog
    (round 5: once a second crossed with 0 tackles for a solo bronze)."""
    trivial = True
    period = 60

    def act(self, t, tel, rng):
        return UP | (B if t % self.period < 4 else 0)


def _blind_at(n):
    return type('up_blind_b%d' % n, (_blind,), {"period": n})


BLIND = [_blind_at(n) for n in (30, 35, 40, 45, 50, 60, 75, 90)]


class park_safe(park_hand):
    """park_hand on the safe line: gets set on every "!", never times a step by hand."""
    safe = True


class leash_dana(park_hand):
    """Dana, round 6: the safe line to the letter (B on every white "!"),
    never goes back for a pat. A flawless one must reach bronze."""
    safe = True

    def act(self, t, tel, rng):
        m = super().act(t, tel, rng)
        me, dogs = self.view()
        if not me['live'] and not me['dash'] and not (m & B):
            m = (m & ~(LEFT | RIGHT | DOWN)) | UP
        return m


class park_nice(park_hand):
    """park_hand that only ever aims for NICE TIMING (B on the red "!"), never the shave."""
    nice_only = True


class park_bold(park_hand):
    """park_hand that goes for the CLOSE SHAVE on every dog it has a read on,
    tackled or not (Lena's question: does the bold verb pay for my hand?)"""
    def shaky(self):
        return False


POLICIES = {c.__name__: c for c in [park_ace, park_fetcher, park_sloppy, park_timing, leash_human, leash_nervous, park_hand, park_safe, park_nice, park_bold, leash_prompt, leash_prompt_red, leash_dana, leash_cue,
                                     up_mash_b, up_mash_ab] + BLIND + DAWDLE}
DEFAULTS = {'park': ['idle', 'hold_up', 'up_mash_b', 'up_mash_ab', 'up_blind_b40', 'up_blind_b60', 'random_input',
                     'park_timing', 'park_sloppy', 'leash_human', 'leash_nervous', 'park_fetcher', 'park_safe',
                     'park_hand', 'park_ace']}
CURVE = {'park': 'park_hand'}

