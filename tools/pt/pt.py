#!/usr/bin/env python3
"""pt — the Toronto Games playtest harness.

Persistent, branchable play sessions on top of a long-lived snes9x core
(ptcore), with game-aware telemetry: which screen is up (from the 65816 call
stack), score, fails, players, lag frames and a per-frame event log.

    python3 tools/pt/pt.py do  SESSION "<script>"   play: step a session forward
    python3 tools/pt/pt.py state SESSION            telemetry for a session
    python3 tools/pt/pt.py replay SESSION           re-run from power-on, check it matches
    python3 tools/pt/pt.py bot EVENT [-p POLICY..] [-n RUNS]   scripted bots, score spread
    python3 tools/pt/pt.py balance [-n RUNS]        every event x every policy, flags
    python3 tools/pt/pt.py fuzz [-n RUNS] [-f FRAMES]  random input, crash/soft-lock hunt
    python3 tools/pt/pt.py golden record|check      screen hashes of every key scene
    python3 tools/pt/pt.py bug SESSION "title" -s major -k design   file a finding + verified repro
    python3 tools/pt/pt.py findings                 all findings, most severe first
    python3 tools/pt/pt.py scenes                   list goto targets

Script language (space separated; superset of tools/run.py):
    wN               run N frames with the held buttons
    hBTN / rBTN      hold / release (BTN may be A+RIGHT); rALL releases all
    pBTN             tap: 3 frames down, 3 up (pA+B for a chord)
    (tokens)*N       repeat a group, e.g. (pLEFT pRIGHT)*20
    s:NAME           screenshot (PNG, 2x) into the session's shots/
    film:NAME:N:K    N frames, one every K, as a contact sheet + GIF
    wav:NAME:N       record N frames of audio to NAME.wav (peak, clipping, stereo width)
    save:LABEL       named checkpoint;  load:LABEL  jump back to it
    goto:TARGET      cached jump to a scene (see `pt.py scenes`)
    until:COND[:MAX] run until COND holds (default MAX 3600 frames).
                     COND: scene=bike.play  scene!=title  ev_fail>=1  ev_score>500
                     frame>N, a|b for "or", a&b for "and"
    state            print full telemetry
    seed:N           write the RNG (variation for bots)
    mADDR:LEN        hex dump WRAM
    BTN: A B X Y L R UP DOWN LEFT RIGHT START SELECT
"""
import argparse
import hashlib
import json
import os
import random
import re
import shutil
import statistics
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..'))
CORE = os.path.join(ROOT, 'build', 'emu', 'snes9x', 'libretro', 'snes9x_libretro.dylib')
PT = os.path.join(ROOT, 'build', 'pt')
PTCORE = os.path.join(PT, 'ptcore')
# PT_ROM pins a build (e.g. a frozen panel copy) so development can carry on
ROM = os.environ.get('PT_ROM') or os.path.join(ROOT, 'toronto_games.sfc')

BTN = {'B': 0, 'Y': 1, 'SELECT': 2, 'START': 3, 'UP': 4, 'DOWN': 5, 'LEFT': 6,
       'RIGHT': 7, 'A': 8, 'X': 9, 'L': 10, 'R': 11}
EVENTS = ['bike', 'bay', 'park', 'cops', 'sail', 'parking', 'subway']
EVENT_TITLE = {'bike': 'Bike Courier', 'bay': 'Bay St Power Walk', 'park': 'Off-Leash Alert',
               'cops': 'Tallboy Trot', 'sail': 'Harbour Regatta', 'parking': 'Parallel Parking',
               'subway': 'TTC Surfing'}
SPONSORS = ["Honest Ed's", 'Sam the Record Man', "Eaton's", 'Pizza Pizza', 'Swiss Chalet',
            'Mr. Sub', 'Canadian Tire', 'Roots', 'Laura Secord', "Shopsy's", 'Steam Whistle',
            'MuchMusic']

# exported routines -> what the player is looking at
SCREEN_SYMS = {'title_screen': 'title', 'main_menu': 'menu', 'register_players': 'signup',
               'pick_events': 'pick', 'records_screen': 'records', 'event_standings': 'standings',
               'final_table': 'final', 'ceremony': 'ceremony',
               'records_board': 'records', 'pick_one': 'pick'}
EVENT_SYMS = {'ev_bike': 'bike', 'ev_bay': 'bay', 'ev_park': 'park', 'ev_cops': 'cops',
              'ev_sail': 'sail', 'ev_parking': 'parking', 'ev_subway': 'subway'}
EVENT_SUB = {'event_card': 'intro', 'event_countdown': 'countdown', 'score_card': 'results'}


def mask_of(spec):
    m = 0
    for b in spec.split('+'):
        if b not in BTN:
            raise ValueError('unknown button %r' % b)
        m |= 1 << BTN[b]
    return m


def buttons_of(mask):
    return '+'.join(b for b, i in BTN.items() if mask >> i & 1) or '-'


def rom_id():
    with open(ROM, 'rb') as f:
        return hashlib.sha1(f.read()).hexdigest()[:12]


# ---------------------------------------------------------------- symbols
class Symbols:
    """Addresses from build/map.txt plus the zero page laid out in src/vars.s."""

    def __init__(self):
        self.addr = {}
        text = open(os.environ.get('PT_MAP') or os.path.join(ROOT, 'build', 'map.txt')).read()
        for m in re.finditer(r'(\w+)\s+([0-9A-F]{6}) RLA', text):
            self.addr[m.group(1)] = int(m.group(2), 16)
        m = re.search(r'^vars\.o:\n(?:\s+\w+\s+Offs=\w+.*\n)*?\s+ZEROPAGE\s+Offs=([0-9A-F]+)', text, re.M)
        zp = int(m.group(1), 16) if m else 0
        seg, off = None, 0
        for line in open(os.environ.get('PT_VARS') or os.path.join(ROOT, 'src', 'vars.s')):
            s = line.split(';')[0].strip()
            if s.startswith('.segment'):
                seg, off = s.split('"')[1], 0
                continue
            m = re.match(r'(\w+):\s*\.res\s+(\d+)', s)
            if m and seg == 'ZEROPAGE':
                self.addr.setdefault(m.group(1), zp + off)
                off += int(m.group(2))
        self.code = sorted((a, n) for n, a in self.addr.items() if a >= 0x800000)
        self.rom = open(ROM, 'rb').read()

    def __getitem__(self, name):
        return self.addr[name]

    def name_at(self, a):
        if a < 0x800000 and (a & 0xFFFF) >= 0x8000:
            a |= 0x800000            # banks $00-$3F mirror the ROM at $80-$BF
        lo, hi, best = 0, len(self.code), None
        while lo < hi:
            mid = (lo + hi) // 2
            if self.code[mid][0] <= a:
                best = self.code[mid]
                lo = mid + 1
            else:
                hi = mid
        return best

    def rom_byte(self, a):
        bank, off = (a >> 16) & 0x7F, a & 0xFFFF
        if off < 0x8000:
            return None
        i = bank * 0x8000 + off - 0x8000
        return self.rom[i] if i < len(self.rom) else None


# ---------------------------------------------------------------- core
class Core:
    """One ptcore process."""

    def __init__(self):
        ensure_core()
        self.p = subprocess.Popen([PTCORE, CORE, ROM], stdin=subprocess.PIPE,
                                  stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                                  text=True, cwd=ROOT, bufsize=1)
        self._read()
        self.watch_names = []

    def _read(self):
        while True:
            line = self.p.stdout.readline()
            if not line:
                raise RuntimeError('ptcore exited')
            if line.startswith('ok') or line.startswith('err'):
                if line.startswith('err'):
                    raise RuntimeError('ptcore: ' + line.strip())
                return line[2:].strip()

    def cmd(self, line):
        self.p.stdin.write(line + '\n')
        self.p.stdin.flush()
        return self._read()

    def close(self):
        try:
            self.cmd('quit')
        except Exception:
            pass
        self.p.wait(timeout=5)

    def run(self, n, m1=0, m2=0):
        return self.cmd('run %d %X %X' % (n, m1, m2)).split()

    def peek(self, a, n):
        return bytes.fromhex(self.cmd('peek %X %d' % (a, n)))

    def poke(self, a, data):
        self.cmd('poke %X %s' % (a, data.hex()))

    def save(self, path):
        self.cmd('save ' + path)

    def load(self, path):
        self.cmd('load ' + path)

    def hash(self):
        return self.cmd('hash')

    def regs(self):
        pb, pc, s, a, x, y, p, db = self.cmd('regs').split()
        return {'pb': int(pb, 16), 'pc': int(pc, 16), 's': int(s, 16), 'a': int(a, 16),
                'x': int(x, 16), 'y': int(y, 16), 'p': int(p, 16), 'db': int(db, 16)}

    def stack(self):
        parts = self.cmd('stack').split()
        return int(parts[0], 16), bytes.fromhex(parts[1]) if len(parts) > 1 else b''

    def audio(self):
        peak, rms = self.cmd('audio').split()
        return int(peak), float(rms)

    def shot(self, png, scale=2):
        from PIL import Image
        ppm = png + '.ppm'
        self.cmd('shot ' + ppm)
        img = Image.open(ppm)
        img = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
        img.save(png)
        os.remove(ppm)
        return png


# ---------------------------------------------------------------- game view
class Game:
    """Core + symbols + the scene/telemetry model of Toronto Games."""

    TELEMETRY = ['frame:2', 'lag:1', 'ev_score:2', 'ev_fail:1', 'cur_player:1', 'event_idx:1']

    def __init__(self, core=None):
        self.sym = Symbols()
        self.core = core or Core()
        self.held = 0
        self.frames = 0          # frames advanced through this Game
        self.watch = []
        for t in self.TELEMETRY:
            n, l = t.split(':')
            self.watch.append((n, self.sym[n], int(l)))
        self.core.cmd('watch ' + ','.join('%X:%d' % (a, l) for _, a, l in self.watch))
        self.last = None
        self.step(0)

    # one frame at a time when someone is listening for events; in bulk otherwise
    def step(self, n=1, mask=None, m2=0):
        out = self.core.run(n, self.held if mask is None else mask, m2)
        self.frames += n
        vals = {}
        for (name, _, l), h in zip(self.watch, out[1:]):
            b = bytes.fromhex(h)
            vals[name] = int.from_bytes(b, 'little')
        self.last = vals
        return vals

    def callstack(self):
        r = self.core.regs()
        s, data = self.core.stack()
        frames = [(r['pb'] << 16) | r['pc']]
        # JSL pushes bank, hi, lo of (return - 1): validate by the JSL opcode at ret-3
        i = 0
        while i + 2 < len(data):
            lo, hi, bank = data[i], data[i + 1], data[i + 2]
            ret = (bank << 16) | (hi << 8) | lo
            # game code is called in banks $80-$8F only; bank $00 holds just the
            # vector stubs, which are entered by interrupts, never by JSL
            if 0x80 <= bank <= 0x8F and hi >= 0x80 and self.sym.rom_byte(ret - 3) == 0x22:
                frames.append(ret + 1)
                i += 3
            else:
                i += 1
        out = []
        for a in frames:
            nm = self.sym.name_at(a)
            out.append((a, nm[1] if nm else '?'))
        return out

    def scene(self, stack=None):
        names = [n for _, n in (stack or self.callstack())]
        ev = next((EVENT_SYMS[n] for n in names if n in EVENT_SYMS), None)
        if ev:
            sub = next((EVENT_SUB[n] for n in names if n in EVENT_SUB), 'play')
            return ev + '.' + sub
        # outermost screen wins: helpers shared between screens can sit next
        # to another screen's label and would otherwise be misnamed
        for n in reversed(names):
            if n in SCREEN_SYMS:
                return SCREEN_SYMS[n]
        if 'game_main' in names:
            return 'transition'      # between screens: loading, fading, medal maths
        return 'boot' if self.frames < 120 else 'unknown:' + (names[0] if names else '?')

    def state(self, full=True):
        ram = self.core.peek(0, 0x2000)
        w = lambda a: ram[a] | ram[a + 1] << 8
        S = self.sym
        st = {
            'frame': w(S['frame']), 'lag': ram[S['lag']],
            'scene': self.scene(),
            'game_mode': ['all', 'some', 'practice'][ram[S['game_mode']]] if ram[S['game_mode']] < 3 else ram[S['game_mode']],
            'num_players': ram[S['num_players']], 'cur_player': ram[S['cur_player']],
            'event_idx': ram[S['event_idx']],
            'event': EVENTS[ram[S['event_idx']]] if ram[S['event_idx']] < len(EVENTS) else None,
            'ev_score': w(S['ev_score']), 'ev_fail': ram[S['ev_fail']],
            'ev_stat': [w(S['ev_stat'] + 2 * i) for i in range(4)],
            'held': buttons_of(self.held),
        }
        if full:
            pl = []
            for i in range(min(st['num_players'], 8)):
                b = S['players'] + 32 * i
                name = bytes(ram[b:b + 9]).split(b'\0')[0].decode('latin1').strip()
                sp = ram[b + 9]
                pl.append({'name': name, 'sponsor': SPONSORS[sp] if sp < 12 else sp,
                           'scores': [w(b + 10 + 2 * k) for k in range(len(EVENTS))],
                           'points': w(b + 24), 'gold': ram[b + 26], 'silver': ram[b + 27],
                           'bronze': ram[b + 28], 'total': w(b + 30)})
            st['players'] = pl
            rec = []
            for k in range(len(EVENTS)):
                b = S['records'] + 16 * k
                rec.append({'event': EVENTS[k], 'score': w(b),
                            'name': bytes(ram[b + 2:b + 11]).split(b'\0')[0].decode('latin1').strip()})
            st['records'] = rec
            st['stack'] = ['%06X %s' % (a, n) for a, n in self.callstack()]
            peak, rms = self.core.audio()
            st['audio'] = {'peak': peak, 'rms': rms}
            st['frame_hash'] = self.core.hash()
        return st


    # ---- presentation lint: things the panel kept finding by eye
    def text_rows(self):
        """BG3 text layer as 28 strings (non-glyph tiles shown as '.')."""
        tm = self.core.peek(self.sym['txt_map'], 2048)
        rows = []
        for y in range(28):
            line = ''
            for x in range(32):
                t = tm[(y * 32 + x) * 2] & 0x7F
                line += chr(t + 32) if 1 <= t <= 63 else ('.' if t else ' ')
            rows.append(line)
        return rows

    def sprites(self):
        """Visible sprites from the OAM shadow: (x, y, w, h). OBSEL is 8x8 / 16x16."""
        oam = self.core.peek(self.sym['oam_buf'], 512)
        hi = self.core.peek(self.sym['oam_hi'], 32)
        out = []
        for i in range(128):
            x, y = oam[i * 4], oam[i * 4 + 1]
            b = (hi[i >> 2] >> ((i & 3) * 2)) & 3
            if b & 1:
                x -= 256
            size = 16 if b & 2 else 8
            if y >= 224 or x <= -size or x >= 256:
                continue
            out.append((x, y, size, size))
        return out

    def lint(self):
        issues = []
        rows = self.text_rows()
        glyph = lambda c: c not in ' .'
        for r in (0, 27):
            if any(glyph(c) for c in rows[r]):
                issues.append(('overscan', 'text on row %d (scanlines %d-%d, hidden by CRT overscan): %r'
                               % (r, r * 8, r * 8 + 7, rows[r].strip(' .'))))
        # text on a solid window panel (tile + 128) sits above sprites; only
        # text printed straight onto the playfield can be covered by them
        tm = self.core.peek(self.sym['txt_map'], 2048)
        bare = lambda cx, cy: glyph(rows[cy][cx]) and not (tm[(cy * 32 + cx) * 2] & 0x80)
        hit = {}
        for (x, y, w, h) in self.sprites():
            for cy in range(max(0, (y + 1) // 8), min(28, (y + h + 7) // 8)):
                for cx in range(max(0, x // 8), min(32, (x + w + 7) // 8)):
                    if bare(cx, cy):
                        hit.setdefault(cy, set()).add(cx)
        for cy, xs in sorted(hit.items()):
            issues.append(('sprite_over_text', 'sprite overlaps text on row %d: %r' % (cy, rows[cy].strip(' .'))))
        return issues


# ---------------------------------------------------------------- scenes
NAV_MENU = 'w200 pSTART w40'
NAV_PRACTICE = NAV_MENU + ' pDOWN pDOWN pA w40 pSTART w40 pA w60 pSTART w60'


def _event_nav(k, stop):
    return NAV_PRACTICE + ' ' + 'pDOWN ' * k + 'pA until:scene=%s.intro w50 pA until:scene=%s.%s' % (
        EVENTS[k], EVENTS[k], stop)


TARGETS = {
    'title': 'w200 until:scene=title',
    'menu': NAV_MENU,
    'signup': NAV_MENU + ' pDOWN pDOWN pA until:scene=signup w40',
    'records': NAV_MENU + ' pDOWN pDOWN pDOWN pA until:scene=records w40',
}
for _k, _e in enumerate(EVENTS):
    TARGETS['intro:' + _e] = NAV_PRACTICE + ' ' + 'pDOWN ' * _k + 'pA until:scene=%s.intro w40' % _e
    TARGETS[_e] = _event_nav(_k, 'play')
TARGET_HELP = {
    'title': 'title screen, logo settled', 'menu': 'main menu',
    'signup': 'name-entry grid (Practice)', 'records': 'Toronto Records screen',
}
for _e in EVENTS:
    TARGET_HELP['intro:' + _e] = 'event card for ' + EVENT_TITLE[_e]
    TARGET_HELP[_e] = EVENT_TITLE[_e] + ': first frame of control (Practice, 1 player)'


# ---------------------------------------------------------------- script runner
class Runner:
    """Executes the script language against a Game, logging what happened."""

    def __init__(self, game, outdir, log_every=1):
        self.g = game
        self.outdir = outdir
        self.events = []
        self.outputs = []
        self.tokens = []         # every executed primitive, for replay
        self.labels = {}         # label -> (state path, tokens)
        self.on_label = self._plain_label

    def _plain_label(self, kind, label):
        """Outside a session: goto works, checkpoints need a session."""
        if kind != 'goto':
            raise ValueError('%s:%s needs a session (pt.py do SESSION ...)' % (kind, label))
        self.tokens[:] = list(goto_target(self.g, label))
        self._last_scene = None

    # --- primitives
    def wait(self, n):
        g = self.g
        prev = g.last or g.step(0)
        left = n
        while left > 0:
            k = min(left, 1)
            v = g.step(k)
            self._diff(prev, v)
            prev = v
            left -= k
        self.tokens.append('w%d' % n)

    def _diff(self, a, b):
        f = self.g.frames
        if f < 240:
            return
        if b['ev_fail'] > a['ev_fail']:
            self.events.append({'f': f, 'ev': 'fail', 'n': b['ev_fail']})
        if b['ev_score'] != a['ev_score']:
            if self.events and self.events[-1]['ev'] == 'score' and f - self.events[-1]['f'] <= 30:
                self.events[-1]['to'] = b['ev_score']
                self.events[-1]['f'] = f
            else:
                self.events.append({'f': f, 'ev': 'score', 'from': a['ev_score'], 'to': b['ev_score']})
        if b['lag'] != a['lag'] and self.g.scene().endswith('.play'):   # loads drop frames on purpose
            d = (b['lag'] - a['lag']) & 0xFF
            if self.events and self.events[-1]['ev'] == 'lag' and f - self.events[-1]['f'] <= 60:
                self.events[-1]['n'] += d
                self.events[-1]['f'] = f
            else:
                self.events.append({'f': f, 'ev': 'lag', 'n': d})
        if b['cur_player'] != a['cur_player']:
            # the game bumps cur_player past the last player when a round ends
            n = self.g.core.peek(self.g.sym['num_players'], 1)[0]
            if b['cur_player'] < n:
                self.events.append({'f': f, 'ev': 'next_player', 'p': b['cur_player']})

    def scene_check(self):
        sc = self.g.scene()
        if not self.events or self._last_scene != sc:
            self.events.append({'f': self.g.frames, 'ev': 'scene', 'scene': sc})
        self._last_scene = sc
        return sc

    _last_scene = None

    def cond(self, expr):
        def atom(a):
            m = re.match(r'(\w+)\s*(>=|<=|!=|=|>|<)\s*(\S+)$', a)
            if not m:
                raise ValueError('bad condition %r' % a)
            k, op, v = m.groups()
            if k == 'scene':
                cur = self.g.scene()
                ok = cur == v or cur.startswith(v + '.') if op == '=' else not (cur == v or cur.startswith(v + '.'))
                return ok
            cur = self.g.last.get(k) if k in self.g.last else None
            if cur is None:
                ram = self.g.core.peek(self.g.sym[k], 2)
                cur = ram[0] | ram[1] << 8
            v = int(v, 0)
            return {'>=': cur >= v, '<=': cur <= v, '!=': cur != v, '=': cur == v,
                    '>': cur > v, '<': cur < v}[op]
        return any(all(atom(a) for a in part.split('&')) for part in expr.split('|'))

    def until(self, expr, limit):
        g = self.g
        prev = g.last or g.step(0)
        n = 0
        needs_scene = 'scene' in expr
        while n < limit:
            if self.cond(expr):
                break
            v = g.step(1)
            self._diff(prev, v)
            prev = v
            n += 1
            if needs_scene and n % 4 == 0:
                pass
        self.tokens.append('w%d' % n)
        hit = self.cond(expr)
        self.events.append({'f': g.frames, 'ev': 'until', 'cond': expr, 'hit': hit, 'frames': n})
        if not hit:
            raise RuntimeError('until:%s not reached within %d frames (scene %s)' % (expr, limit, g.scene()))
        return n

    def tap(self, spec):
        m = mask_of(spec)
        keep = self.g.held
        self.g.held = keep | m
        self.tokens.append('h' + spec)
        self.wait(3)
        self.g.held = keep
        self.tokens.append('r' + spec)
        self.wait(3)

    def film(self, name, n, k):
        from PIL import Image
        rawp = os.path.join(self.outdir, name + '.raw')
        if os.path.exists(rawp):
            os.remove(rawp)
        out = self.g.core.cmd('film %s %d %d %X 0' % (rawp, n, k, self.g.held)).split()
        w, h = int(out[1]), int(out[2])
        self.g.frames += n * k
        self.tokens.append('w%d' % (n * k))
        data = open(rawp, 'rb').read()
        os.remove(rawp)
        frames = [Image.frombytes('RGB', (w, h), data[i * w * h * 3:(i + 1) * w * h * 3]) for i in range(n)]
        cols = min(n, 6)
        rows = (n + cols - 1) // cols
        sheet = Image.new('RGB', (cols * w, rows * h), (20, 20, 20))
        from PIL import ImageDraw
        f0 = self.g.frames - n * k
        for i, fr in enumerate(frames):
            sheet.paste(fr, ((i % cols) * w, (i // cols) * h))
            ImageDraw.Draw(sheet).text(((i % cols) * w + 3, (i // cols) * h + h - 11),
                                       '@%d' % (f0 + (i + 1) * k), fill=(255, 255, 0))
        sp = os.path.join(self.outdir, name + '_sheet.png')
        sheet.save(sp)
        gp = os.path.join(self.outdir, name + '.gif')
        big = [fr.resize((w * 2, h * 2), Image.NEAREST) for fr in frames]
        big[0].save(gp, save_all=True, append_images=big[1:], duration=max(20, int(1000 * k / 60)), loop=0)
        self.g.step(0)
        self.outputs.append({'film': sp, 'gif': gp, 'frames': n, 'every': k})

    def wav(self, name, n):
        """Record n frames of audio to NAME.wav and measure it."""
        import array
        import math
        import wave
        rawp = os.path.join(self.outdir, name + '.raw')
        self.g.core.cmd('wav ' + rawp)
        self.wait(n)
        self.g.core.cmd('wavend')
        data = open(rawp, 'rb').read()
        os.remove(rawp)
        wp = os.path.join(self.outdir, name + '.wav')
        w = wave.open(wp, 'wb')
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(32040)
        w.writeframes(data)
        w.close()
        d = array.array('h', data)
        L, R = d[0::2], d[1::2]
        if not L:
            return {'wav': wp, 'frames': n, 'silent': True}
        ml, mr = sum(L) / len(L), sum(R) / len(R)
        rms = lambda xs: math.sqrt(sum(x * x for x in xs) / len(xs)) if xs else 0
        mid = [((a - ml) + (b - mr)) / 2 for a, b in zip(L, R)]
        side = [((a - ml) - (b - mr)) / 2 for a, b in zip(L, R)]
        rm, rs = rms(mid), rms(side)
        return {'wav': wp, 'frames': n, 'peak': max(map(abs, d)), 'clipped': sum(1 for x in d if abs(x) >= 32700),
                'rms': round(rm), 'side_db': round(20 * math.log10(rs / rm), 1) if rm and rs else None,
                'silent': rm < 50}

    # --- the language
    def execute(self, script):
        for tok in tokenize(script):
            self.one(tok)

    def one(self, tok):
        g = self.g
        if isinstance(tok, tuple):
            body, times = tok
            for _ in range(times):
                for t in body:
                    self.one(t)
            return
        if tok.startswith('s:'):
            os.makedirs(self.outdir, exist_ok=True)
            p = g.core.shot(os.path.join(self.outdir, tok[2:] + '.png'))
            self.outputs.append({'shot': p, 'frame': g.frames, 'scene': self.scene_check()})
        elif tok.startswith('film:'):
            _, name, n, k = tok.split(':')
            os.makedirs(self.outdir, exist_ok=True)
            self.film(name, int(n), int(k))
        elif tok.startswith('wav:'):
            _, name, n = tok.split(':')
            os.makedirs(self.outdir, exist_ok=True)
            self.outputs.append(self.wav(name, int(n)))
        elif tok.startswith('until:'):
            parts = tok[6:].split(':')
            self.until(parts[0], int(parts[1]) if len(parts) > 1 else 3600)
            self.scene_check()
        elif tok.startswith('save:'):
            self.on_label('save', tok[5:])
        elif tok.startswith('load:'):
            self.on_label('load', tok[5:])
        elif tok.startswith('goto:'):
            self.on_label('goto', tok[5:])
        elif tok.startswith('seed:'):
            v = int(tok[5:], 0) & 0xFFFF or 1
            g.core.poke(g.sym['rng'], bytes([v & 0xFF, v >> 8]))
            self.tokens.append(tok)
        elif tok == 'state':
            self.outputs.append({'state': g.state()})
        elif tok == 'rALL':
            g.held = 0
            self.tokens.append(tok)
        elif re.match(r'w\d+$', tok):
            self.wait(int(tok[1:]))
            if int(tok[1:]) >= 30:
                self.scene_check()
        elif tok[0] == 'h' and tok[1:2].isupper():
            g.held |= mask_of(tok[1:])
            self.tokens.append(tok)
        elif tok[0] == 'r' and tok[1:2].isupper():
            g.held &= ~mask_of(tok[1:])
            self.tokens.append(tok)
        elif tok[0] == 'p' and tok[1:2].isupper():
            self.tap(tok[1:])
        elif re.match(r'm[0-9A-Fa-f]+:\d+$', tok):
            a, l = tok[1:].split(':')
            self.outputs.append({'ram': a.upper(), 'hex': g.core.peek(int(a, 16), int(l)).hex(' ')})
        else:
            raise ValueError('unknown token %r' % tok)


def tokenize(s):
    """Split a script into tokens; '(a b)*N' becomes a nested (list, N)."""
    toks = re.findall(r'\(|\)\*\d+|\)|[^\s()]+', s)
    stack = [[]]
    for t in toks:
        if t == '(':
            stack.append([])
        elif t.startswith(')'):
            body = stack.pop()
            n = int(t[2:]) if t.startswith(')*') else 1
            stack[-1].append((body, n))
        elif re.match(r'.+\*\d+$', t) and not t.startswith(('until:', 'film:')):
            base, n = t.rsplit('*', 1)
            stack[-1].append(([base], int(n)))
        else:
            stack[-1].append(t)
    if len(stack) != 1:
        raise ValueError('unbalanced parentheses')
    return stack[0]


# ---------------------------------------------------------------- scene cache
def cache_dir():
    d = os.path.join(PT, 'cache', rom_id())
    os.makedirs(d, exist_ok=True)
    return d


def goto_target(game, name):
    """Load a cached savestate for a target, building it on first use.
    Returns the replay tokens that reach it from power-on."""
    if name not in TARGETS:
        raise ValueError('unknown target %r (try: %s)' % (name, ', '.join(TARGETS)))
    d = cache_dir()
    sp = os.path.join(d, name.replace(':', '_') + '.state')
    mp = sp + '.json'
    if os.path.exists(sp) and os.path.exists(mp):
        meta = json.load(open(mp))
        game.core.load(sp)
        game.held = 0
        game.frames = meta['frames']
        game.step(0)
        return meta['tokens']
    fresh = Game()
    r = Runner(fresh, d)
    r.execute(TARGETS[name])
    fresh.held = 0
    fresh.core.save(sp)
    json.dump({'tokens': r.tokens, 'frames': fresh.frames, 'scene': fresh.scene()}, open(mp, 'w'))
    fresh.core.close()
    return goto_target(game, name)


# ---------------------------------------------------------------- sessions
class Session:
    """A play session that persists between commands as a savestate + replay log."""

    def __init__(self, name):
        if not re.match(r'[\w.-]+$', name):
            raise ValueError('session names are letters, digits, - _ .')
        self.name = name
        self.dir = os.path.join(PT, 'sessions', name)
        os.makedirs(os.path.join(self.dir, 'labels'), exist_ok=True)
        self.meta_p = os.path.join(self.dir, 'session.json')
        self.state_p = os.path.join(self.dir, 'current.state')
        if os.path.exists(self.meta_p):
            self.meta = json.load(open(self.meta_p))
        else:
            self.meta = {'rom': rom_id(), 'tokens': [], 'frames': 0, 'held': 0, 'labels': {}}

    def open(self):
        g = Game()
        if self.meta['rom'] != rom_id():
            print('note: the ROM changed since this session started; replaying its inputs', file=sys.stderr)
            Runner(g, self.dir).execute(' '.join(self.meta['tokens']))
            self.meta['rom'] = rom_id()
        elif os.path.exists(self.state_p):
            g.core.load(self.state_p)
            g.frames = self.meta['frames']
        g.held = self.meta['held']
        g.step(0)
        return g

    def do(self, script):
        g = self.open()
        r = Runner(g, os.path.join(self.dir, 'shots'))
        base = list(self.meta['tokens'])
        sess = self

        def on_label(kind, label):
            nonlocal base
            if kind == 'save':
                p = os.path.join(sess.dir, 'labels', label + '.state')
                g.core.save(p)
                sess.meta['labels'][label] = {'tokens': base + r.tokens, 'frames': g.frames, 'held': g.held,
                                              'anchor': sess.meta.get('anchor')}
                r.outputs.append({'saved': label, 'frame': g.frames})
            elif kind == 'load':
                lab = sess.meta['labels'].get(label)
                if not lab:
                    raise ValueError('no checkpoint %r (have: %s)' % (label, ', '.join(sess.meta['labels']) or 'none'))
                g.core.load(os.path.join(sess.dir, 'labels', label + '.state'))
                g.frames, g.held = lab['frames'], lab['held']
                g.step(0)
                base, r.tokens[:] = list(lab['tokens']), []
                sess.meta['anchor'] = lab.get('anchor')
                r.outputs.append({'loaded': label, 'frame': g.frames})
            else:
                toks = goto_target(g, label)
                base, r.tokens[:] = list(toks), []
                # repros relative to this goto survive menu/card timing changes
                sess.meta['anchor'] = {'target': label, 'start': len(toks)}
                r.outputs.append({'goto': label, 'frame': g.frames})
            r._last_scene = None
            r.scene_check()

        r.on_label = on_label
        t0 = time.time()
        f0 = g.frames
        err = None
        try:
            r.execute(script)
        except Exception as e:      # keep the state reached so far
            err = str(e)
        self.meta['tokens'] = base + r.tokens
        self.meta['frames'] = g.frames
        self.meta['held'] = g.held
        g.core.save(self.state_p)
        json.dump(self.meta, open(self.meta_p, 'w'))
        st = g.state(full=False)
        with open(os.path.join(self.dir, 'log.jsonl'), 'a') as f:
            f.write(json.dumps({'script': script, 'from': f0, 'to': g.frames, 'events': r.events,
                                'outputs': r.outputs, 'error': err}) + '\n')
        g.core.close()
        res = {'session': self.name, 'frame': g.frames, 'advanced': g.frames - f0,
               'seconds': round((g.frames - f0) / 60, 2), 'state': st,
               'events': compact_events(r.events), 'outputs': r.outputs,
               'wall_ms': int((time.time() - t0) * 1000)}
        if err:
            res['error'] = err
        return res


def compact_events(evs):
    out = []
    for e in evs:
        if e['ev'] == 'scene':
            if out and out[-1].startswith('scene ') and out[-1].endswith(' ' + e['scene']):
                continue
            out.append('@%d scene %s' % (e['f'], e['scene']))
        elif e['ev'] == 'score':
            out.append('@%d score %d->%d' % (e['f'], e['from'], e['to']))
        elif e['ev'] == 'fail':
            out.append('@%d FAIL #%d' % (e['f'], e['n']))
        elif e['ev'] == 'lag':
            out.append('@%d LAG %d frame(s) dropped' % (e['f'], e['n']))
        elif e['ev'] == 'next_player':
            out.append('@%d turn -> player %d' % (e['f'], e['p'] + 1))
        elif e['ev'] == 'until':
            out.append('@%d until %s (%d frames)' % (e['f'], e['cond'], e['frames']))
    return out


# ---------------------------------------------------------------- bots
def run_bot(event, policy_name, seed, max_frames=60 * 240, film=None, latency=0, jitter=0, miss=0.0):
    """latency/jitter/miss model a human: each decision lands latency +- jitter
    frames late, and a fraction `miss` of decisions never happen."""
    from policies import POLICIES
    pol = POLICIES[policy_name]()
    g = Game()
    pol.game = g            # policies may read event RAM through pol.game.core.peek
    goto_target(g, event)
    rng = random.Random(seed)
    g.core.poke(g.sym['rng'], bytes([rng.randrange(1, 256), rng.randrange(256)]))
    t = 0
    fails = []
    lag = 0
    prev = g.last
    hold = 0
    want = 0
    pending = []                 # (frame the hand gets there, mask)
    hrng = random.Random(seed * 7919 + 1)
    while t < max_frames:
        if t % pol.every == 0:
            m = pol.act(t, g.last, rng)
            if not latency and not jitter and not miss:
                hold = m
            elif m != want and hrng.random() >= miss:
                want = m
                # a hand can be late, but it never reorders its own decisions
                due = t + max(0, latency + hrng.randint(-jitter, jitter))
                if pending:              # one change per frame: a tap is never swallowed
                    due = max(due, pending[-1][0] + 1)
                pending.append((due, m))
        if pending:
            while pending and pending[0][0] <= t:
                hold = pending.pop(0)[1]
        v = g.step(1, hold)
        if v['ev_fail'] > prev['ev_fail']:
            fails.append(t)
        # only slowdown during play counts; screen loads drop frames on purpose
        if v['lag'] != prev['lag'] and g.scene().endswith('.play'):
            lag += (v['lag'] - prev['lag']) & 0xFF
        prev = v
        t += 1
        if t % 15 == 0 and not g.scene().startswith(event + '.play'):
            break
    sc = g.scene()
    # let the result settle (score is final once the results card is up)
    if not sc.startswith(event + '.results'):
        for _ in range(240):
            g.step(1, 0)
            if g.scene().startswith(event + '.results'):
                break
    g.step(20, 0)
    st = g.state(full=False)
    res = {'event': event, 'policy': policy_name, 'seed': seed, 'score': st['ev_score'],
           'latency': latency, 'success': st['ev_fail'] == 0,
           'fails': st['ev_fail'], 'fail_frames': fails, 'frames': t,
           'finished': t < max_frames, 'stats': st['ev_stat'], 'lag': lag,
           'end_scene': st['scene']}
    if film:
        g.core.shot(film)
    g.core.close()
    return res


def summarize(rows):
    sc = [r['score'] for r in rows]
    fr = [r['frames'] / 60 for r in rows]
    return {'n': len(rows), 'mean': round(statistics.mean(sc)), 'median': round(statistics.median(sc)),
            'min': min(sc), 'max': max(sc), 'sd': round(statistics.pstdev(sc)),
            'secs_median': round(statistics.median(fr), 1), 'fails_mean': round(statistics.mean(r['fails'] for r in rows), 2),
            'timeouts': sum(not r['finished'] for r in rows), 'lag': sum(r['lag'] for r in rows)}


def parallel_map(fn, jobs, workers):
    from concurrent.futures import ProcessPoolExecutor
    with ProcessPoolExecutor(max_workers=workers) as ex:
        return list(ex.map(fn, jobs))


def _bot_job(j):
    return run_bot(*j)


def _curve_job(j):
    event, pol, seed, maxf, lat = j
    return run_bot(event, pol, seed, maxf, latency=lat, jitter=lat // 4, miss=0.03 if lat else 0.0)


def cmd_curve(a):
    """Score and finish rate against human reaction time. A good event degrades
    gracefully: an average human (~15 frames, 250 ms) still finishes and clearly
    beats standing still."""
    sys.path.insert(0, HERE)
    from policies import POLICIES, DEFAULTS, CURVE
    skilled = [p for p in DEFAULTS[a.event] if not is_trivial(p) and p != 'random_input']
    pol = a.policy or CURVE.get(a.event) or (skilled[-1] if skilled else None)
    if not pol:
        sys.exit('no skilled bot for %s: write one in tools/pt/policies_%s.py (set CURVE)' % (a.event, a.event))
    _warm([a.event])
    lats = [int(x) for x in a.latencies.split(',')]
    jobs = [(a.event, pol, a.seed + i, a.max_frames, L) for L in lats for i in range(a.runs)]
    jobs += [(a.event, 'idle', a.seed + i, a.max_frames, 0) for i in range(2)]
    rows = parallel_map(_curve_job, jobs, a.jobs)
    idle = statistics.median(r['score'] for r in rows if r['policy'] == 'idle')
    print('\n%s: %s with a human hand (latency +- latency/4 frames, 3%% missed inputs); idle scores %d'
          % (EVENT_TITLE[a.event], pol, idle))
    print('  %8s %6s %6s %6s %8s %6s' % ('latency', 'ms', 'median', 'min', 'finished', 'secs'))
    curve = {}
    for L in lats:
        rs = [r for r in rows if r['policy'] == pol and r['latency'] == L]
        med = statistics.median(r['score'] for r in rs)
        fin = sum(r['success'] for r in rs) / len(rs)
        curve[L] = (med, fin)
        print('  %8d %6d %6d %6d %7d%% %6.1f' % (L, round(L * 1000 / 60), med, min(r['score'] for r in rs),
                                                round(100 * fin), statistics.median(r['frames'] for r in rs) / 60))
    flags = []
    human = min(lats, key=lambda L: abs(L - 15))
    hm, hf = curve[human]
    if hf < 0.5:
        flags.append('an average human (%d frames) finishes only %d%% of runs' % (human, round(100 * hf)))
    if hm <= 1.5 * idle + 100:
        flags.append('an average human (%d frames) scores about what standing still scores (%d vs %d)' % (human, hm, idle))
    fast = min(lats)
    if curve[fast][0] > 0 and hm > 0 and curve[fast][0] / hm > 3:
        flags.append('cliff: %d-frame play scores %.0fx the %d-frame score' % (fast, curve[fast][0] / hm, human))
    elif curve[fast][0] > 0 and hm == 0:
        flags.append('cliff: %d-frame play scores %d, %d-frame play scores 0' % (fast, curve[fast][0], human))
    print('\nFLAGS' if flags else '\nno flags')
    for f in flags:
        print('  !', f)
    out = os.path.join(PT, 'reports', 'curve_%s_%d.json' % (a.event, int(time.time())))
    os.makedirs(os.path.dirname(out), exist_ok=True)
    json.dump({'rom': rom_id(), 'event': a.event, 'policy': pol, 'idle': idle, 'flags': flags, 'rows': rows},
              open(out, 'w'), indent=1)
    print('full results:', os.path.relpath(out, ROOT))


def cmd_bot(a):
    sys.path.insert(0, HERE)
    from policies import POLICIES, DEFAULTS
    pols = a.policy or DEFAULTS[a.event]
    for p in pols:
        if p not in POLICIES:
            sys.exit('unknown policy %s (have: %s)' % (p, ', '.join(POLICIES)))
    goto_target(Game(), a.event) if False else None
    _warm([a.event])
    jobs = [(a.event, p, a.seed + i, a.max_frames) for p in pols for i in range(a.runs)]
    rows = parallel_map(_bot_job, jobs, a.jobs)
    report = {'rom': rom_id(), 'event': a.event, 'rows': rows,
              'summary': {p: summarize([r for r in rows if r['policy'] == p]) for p in pols}}
    out = os.path.join(PT, 'reports', 'bot_%s_%d.json' % (a.event, int(time.time())))
    os.makedirs(os.path.dirname(out), exist_ok=True)
    json.dump(report, open(out, 'w'), indent=1)
    print_table(a.event, report['summary'])
    print('\nfull results:', os.path.relpath(out, ROOT))


def _warm(targets):
    g = Game()
    for t in targets:
        goto_target(g, t)
    g.core.close()


def record_of(event):
    g = Game()
    goto_target(g, 'menu')
    st = g.state()
    g.core.close()
    return next(r['score'] for r in st['records'] if r['event'] == event)


def print_table(event, summ, record=None):
    print('\n%s%s' % (EVENT_TITLE[event], ('  (default record %d)' % record) if record is not None else ''))
    print('  %-12s %5s %6s %6s %6s %6s %5s %6s %5s %4s' % ('policy', 'runs', 'mean', 'median', 'min', 'max', 'sd',
                                                       'secs', 'fails', 'lag'))
    for p, s in summ.items():
        print('  %-12s %5d %6d %6d %6d %6d %5d %6.1f %5.2f %4d%s' % (
            p, s['n'], s['mean'], s['median'], s['min'], s['max'], s['sd'], s['secs_median'], s['fails_mean'],
            s['lag'], '  (%d timed out)' % s['timeouts'] if s['timeouts'] else ''))


TRIVIAL = ('idle', 'hold_a', 'hold_b', 'mash_a', 'hold_right', 'hold_up')


def is_trivial(name):
    """No-skill exploit detectors: the built-ins, or a policy class with trivial = True."""
    from policies import POLICIES
    return name in TRIVIAL or getattr(POLICIES.get(name), 'trivial', False)


def cmd_balance(a):
    sys.path.insert(0, HERE)
    from policies import DEFAULTS
    events = a.events or EVENTS
    _warm(events + ['menu'])
    jobs = [(e, p, a.seed + i, a.max_frames) for e in events for p in DEFAULTS[e] for i in range(a.runs)]
    rows = parallel_map(_bot_job, jobs, a.jobs)
    rec = {}
    g = Game()
    goto_target(g, 'menu')
    for r in g.state()['records']:
        rec[r['event']] = r['score']
    g.core.close()
    summ = {e: {p: summarize([r for r in rows if r['event'] == e and r['policy'] == p]) for p in DEFAULTS[e]}
            for e in events}
    flags = []
    for e in events:
        print_table(e, summ[e], rec.get(e))
        trivial = {p: s for p, s in summ[e].items() if is_trivial(p)}
        skilled = {p: s for p, s in summ[e].items() if not is_trivial(p) and p != 'random_input'}
        best = max(s['max'] for s in summ[e].values())
        for p, s in trivial.items():
            if s['median'] >= rec.get(e, 1 << 30):
                flags.append('%s: no-skill policy "%s" beats the default record (median %d vs %d)' % (
                    e, p, s['median'], rec[e]))
            if skilled and p != 'idle' and s['median'] >= max(k['median'] for k in skilled.values()) > 0:
                flags.append('%s: no-skill policy "%s" (%d) outscores every skilled bot (best %d) — degenerate strategy'
                             % (e, p, s['median'], max(k['median'] for k in skilled.values())))
        idle = summ[e].get('idle')
        if idle and idle['median'] > 0:
            flags.append('%s: standing still scores %d' % (e, idle['median']))
        if best == 0:
            flags.append('%s: no bot scored at all — check that the event is learnable/winnable' % e)
        if all(s['sd'] == 0 for s in summ[e].values()):
            flags.append('%s: every run of a policy scored the same — the event has no randomness' % e)
        for p, s in summ[e].items():
            if s['secs_median'] < 20 and not is_trivial(p) and p != 'random_input':
                flags.append('%s: "%s" turns end after %.0fs (median) — CG events ran ~60-90s' % (e, p, s['secs_median']))
            if s['secs_median'] > 120:
                flags.append('%s: "%s" turns last %.0fs (median) — long wait for the next player' % (e, p, s['secs_median']))
            if s['timeouts']:
                flags.append('%s: "%s" hit the frame cap %d time(s) — event may not end on its own' % (e, p, s['timeouts']))
            if s['lag']:
                flags.append('%s: "%s" dropped %d frame(s) to slowdown during play' % (e, p, s['lag']))
        allmed = [s['median'] for s in summ[e].values()]
    meds = {e: max(s['median'] for s in summ[e].values()) for e in events}
    if meds and min(meds.values()) > 0 and max(meds.values()) / min(meds.values()) > 4:
        flags.append('score scale: best-bot medians differ %.0fx across events (%s) — raw totals will be dominated by one event'
                     % (max(meds.values()) / min(meds.values()), ', '.join('%s %d' % kv for kv in meds.items())))
    print('\nFLAGS' if flags else '\nno flags')
    for f in flags:
        print('  !', f)
    out = os.path.join(PT, 'reports', 'balance_%d.json' % int(time.time()))
    os.makedirs(os.path.dirname(out), exist_ok=True)
    json.dump({'rom': rom_id(), 'records': rec, 'summary': summ, 'flags': flags, 'rows': rows}, open(out, 'w'), indent=1)
    print('\nfull results:', os.path.relpath(out, ROOT))


# ---------------------------------------------------------------- fuzz
FUZZ_WEIGHTS = [('A', 6), ('START', 3), ('B', 3), ('UP', 3), ('DOWN', 3), ('LEFT', 3), ('RIGHT', 3),
                ('SELECT', 1), ('X', 1), ('Y', 1), ('L', 1), ('R', 1)]


def fuzz_one(job):
    seed, frames, start = job
    rng = random.Random(seed)
    g = Game()
    toks = []
    if start != 'power':
        toks = list(goto_target(g, start))
    names, weights = zip(*FUZZ_WEIGHTS)
    seen = {}
    findings = []
    last_frame = g.last['frame']
    last_hash, same_hash = None, 0
    scene, scene_since = None, 0
    t = 0
    while t < frames:
        # mostly short taps, sometimes holds and chords
        k = rng.choice([3, 3, 3, 6, 10, 20, 45])
        m = 0
        for _ in range(rng.choice([1, 1, 1, 2])):
            m |= 1 << BTN[rng.choices(names, weights)[0]]
        if rng.random() < 0.25:
            m = 0
        g.step(k, m)
        toks += ['h' + buttons_of(m), 'w%d' % k, 'rALL'] if m else ['w%d' % k]
        t += k
        if t // 30 != (t - k) // 30:
            r = g.core.regs()
            v = g.last
            sc = g.scene()
            seen[sc] = seen.get(sc, 0) + 1
            if sc != scene:
                scene, scene_since = sc, t
            pc = r['pb'] << 16 | r['pc']
            problem = None
            if v['frame'] == last_frame:
                problem = 'NMI stopped: frame counter frozen'
            elif not ((r['pb'] & 0x7F) < 0x40 and r['pc'] >= 0x8000):
                problem = 'CPU executing outside ROM code at %06X' % pc
            elif sc.startswith('unknown'):
                problem = 'unrecognised call stack (%s)' % sc
            elif sc == 'transition' and t - scene_since > 60 * 10:
                problem = 'stuck between screens for 10s'
            elif t - scene_since > 60 * 300 and not sc.endswith('.play'):
                problem = 'stuck on %s for 300s of random input' % sc
            last_frame = v['frame']
            h = g.core.hash()
            same_hash = same_hash + 30 if h == last_hash else 0
            last_hash = h
            if same_hash >= 60 * 30 and not problem:
                problem = 'screen frozen for 30s of random input on %s' % sc
            if problem:
                d = os.path.join(PT, 'fuzz', '%s_seed%d' % (rom_id(), seed))
                os.makedirs(d, exist_ok=True)
                g.core.save(os.path.join(d, 'crash.state'))
                g.core.shot(os.path.join(d, 'screen.png'))
                st = g.state()
                json.dump({'problem': problem, 'seed': seed, 'frame': t, 'state': st,
                           'repro': ' '.join(toks)}, open(os.path.join(d, 'finding.json'), 'w'), indent=1)
                findings.append({'seed': seed, 'frame': t, 'problem': problem, 'scene': sc,
                                 'dir': os.path.relpath(d, ROOT)})
                break
    g.core.close()
    return {'seed': seed, 'frames': t, 'scenes': seen, 'findings': findings}


def cmd_fuzz(a):
    if a.start != 'power':
        _warm([a.start])
    res = parallel_map(fuzz_one, [(a.seed + i, a.frames, a.start) for i in range(a.runs)], a.jobs)
    cov = {}
    for r in res:
        for s, n in r['scenes'].items():
            cov[s] = cov.get(s, 0) + n
    found = [f for r in res for f in r['findings']]
    print('fuzz: %d runs x %d frames (%.0f min of play) from %s' % (a.runs, a.frames, a.runs * a.frames / 3600, a.start))
    print('scene coverage (samples):')
    for s, n in sorted(cov.items(), key=lambda kv: -kv[1]):
        print('  %-18s %d' % (s, n))
    never = [s for s in ['title', 'menu', 'signup', 'pick', 'records', 'standings', 'final', 'ceremony']
             + ['%s.%s' % (e, x) for e in EVENTS for x in ('intro', 'play', 'results')] if s not in cov]
    if never:
        print('never reached:', ', '.join(never))
    print('\nFINDINGS' if found else '\nno crashes, freezes or soft-locks found')
    for f in found:
        print('  ! seed %d @%d (%s): %s  -> %s/finding.json' % (f['seed'], f['frame'], f['scene'], f['problem'], f['dir']))


# ---------------------------------------------------------------- lint
def _lint_job(job):
    target, frames, mask = job
    g = Game()
    goto_target(g, target)
    found = {}
    for t in range(0, frames + 1, 15):
        if t:
            g.step(15, mask)
        for kind, msg in g.lint():
            found.setdefault((kind, msg), (t, g.scene()))
    g.core.close()
    return target, [{'kind': k, 'msg': m, 'frame': f, 'scene': sc} for (k, m), (f, sc) in found.items()]


def cmd_lint(a):
    targets = a.targets or list(TARGETS)
    _warm(targets)
    res = parallel_map(_lint_job, [(t, a.frames, mask_of(a.hold) if a.hold else 0) for t in targets], a.jobs)
    n = 0
    for target, issues in res:
        print('%-14s %s' % (target, 'clean' if not issues else '%d issue(s)' % len(issues)))
        for i in issues:
            print('    %-16s @%-4d %s' % (i['kind'], i['frame'], i['msg']))
        n += len(issues)
    print('\n%d issue(s). Heuristics: overscan = text in the top/bottom 8 scanlines; sprite_over_text = an OAM box'
          ' over a text glyph printed straight onto the playfield (panel text sits above sprites).' % n)


# ---------------------------------------------------------------- golden
def cmd_golden(a):
    path = os.path.join(ROOT, 'tools', 'pt', 'golden.json')
    names = list(TARGETS)
    if a.mode == 'record':
        g = Game()
        out = {}
        for n in names:
            goto_target(g, n)
            g.step(1, 0)
            out[n] = g.core.hash()
            g.core.shot(os.path.join(PT, 'golden_%s.png' % n.replace(':', '_')))
        g.core.close()
        json.dump(out, open(path, 'w'), indent=1)
        print('recorded %d scenes -> %s' % (len(out), os.path.relpath(path, ROOT)))
        return
    want = json.load(open(path))
    g = Game()
    bad = 0
    for n in names:
        try:
            goto_target(g, n)
        except Exception as e:
            print('  FAIL %-14s cannot reach: %s' % (n, e))
            bad += 1
            continue
        g.step(1, 0)
        h = g.core.hash()
        p = os.path.join(PT, 'check_%s.png' % n.replace(':', '_'))
        if h != want.get(n):
            g.core.shot(p)
            print('  DIFF %-14s %s -> %s  (see %s)' % (n, want.get(n), h, os.path.relpath(p, ROOT)))
            bad += 1
        else:
            print('  ok   %s' % n)
    g.core.close()
    sys.exit(1 if bad else 0)


# ---------------------------------------------------------------- replay
def cmd_replay(a):
    s = Session(a.session)
    toks = ' '.join(s.meta['tokens'])
    g = Game()
    Runner(g, os.path.join(s.dir, 'replay')).execute(toks)
    h = g.core.hash()
    g.core.close()
    g2 = s.open()
    h2 = g2.core.hash()
    g2.core.close()
    print(json.dumps({'tokens': len(s.meta['tokens']), 'frames': s.meta['frames'],
                      'replay_hash': h, 'session_hash': h2, 'deterministic': h == h2}))
    if a.print:
        print(toks)


# ---------------------------------------------------------------- findings
FINDINGS = os.path.join(PT, 'findings.jsonl')


def cmd_bug(a):
    """File a finding at the session's current moment, with a verified repro."""
    s = Session(a.session)
    g = s.open()
    st = g.state()
    fid = '%s-%d' % (a.session, int(time.time() * 1000) % 10 ** 9)
    d = os.path.join(PT, 'findings', fid)
    os.makedirs(d, exist_ok=True)
    g.core.shot(os.path.join(d, 'screen.png'))
    g.core.save(os.path.join(d, 'moment.state'))
    h = g.core.hash()
    g.core.close()
    toks = ' '.join(s.meta['tokens'])
    r = Game()
    Runner(r, d).execute(toks)
    ok = r.core.hash() == h
    r.core.close()
    anchor = s.meta.get('anchor')
    rel = {'target': anchor['target'], 'tokens': ' '.join(s.meta['tokens'][anchor['start']:])} if anchor else None
    rec = {'id': fid, 'tester': a.tester or a.session, 'severity': a.severity, 'kind': a.kind,
           'repro_rel': rel, 'check': a.check,
           'title': a.title, 'detail': a.detail or '', 'scene': st['scene'], 'frame': s.meta['frames'],
           'event': st['event'] if st['scene'].split('.')[0] in EVENTS else None,
           'screen': os.path.relpath(os.path.join(d, 'screen.png'), ROOT), 'repro': toks,
           'repro_verified': ok, 'rom': rom_id(), 'state': {k: st[k] for k in ('ev_score', 'ev_fail', 'ev_stat', 'num_players', 'cur_player', 'game_mode')}}
    with open(FINDINGS, 'a') as f:
        f.write(json.dumps(rec) + '\n')
    print(json.dumps({k: rec[k] for k in ('id', 'severity', 'scene', 'screen', 'repro_verified')}))


def _verify_one(rec):
    """Replay a finding on the current ROM: event-relative when possible."""
    g = Game()
    out = {'id': rec['id']}
    try:
        r = Runner(g, os.path.join(PT, 'verify', rec['id']))
        if rec.get('repro_rel'):
            r.execute('goto:' + rec['repro_rel']['target'])
            r.execute(rec['repro_rel']['tokens'])
            out['mode'] = 'event'
        else:
            r.execute(rec['repro'])
            out['mode'] = 'power-on'
        st = g.state(full=False)
        out.update({'scene': st['scene'], 'ev_score': st['ev_score'], 'ev_fail': st['ev_fail']})
        if rec.get('check'):
            out['present'] = bool(r.cond(rec['check']))
        out['same_scene'] = st['scene'] == rec['scene']
    except Exception as e:
        out['error'] = str(e)[:120]
    finally:
        g.core.close()
    return out


def cmd_findings(a):
    path = a.file or FINDINGS
    if not os.path.exists(path):
        print('no findings yet')
        return
    rows = [json.loads(l) for l in open(path)]
    if a.verify:
        res = {v['id']: v for v in parallel_map(_verify_one, rows, os.cpu_count())}
        counts = {}
        for r in rows:
            v = res[r['id']]
            if 'error' in v:
                st = 'ERROR'
            elif 'present' in v:
                st = 'PRESENT' if v['present'] else 'GONE'
            elif not v['same_scene']:
                st = 'DESYNC?'
            else:
                st = 'REPLAYED'
            counts[st] = counts.get(st, 0) + 1
            print('%-8s [%s] %-14s %s  (%s replay -> %s score %s)' % (
                st, r['severity'], r['scene'], r['title'][:70], v.get('mode', '?'), v.get('scene', v.get('error')),
                v.get('ev_score')))
        print('\n' + ', '.join('%s %d' % kv for kv in sorted(counts.items())))
        print('PRESENT/GONE need a --check condition on the finding; REPLAYED = reached the same scene, look at it;'
              ' DESYNC? = the replay ended somewhere else (the game changed under a power-on repro)')
        out = os.path.join(PT, 'reports', 'verify_%d.json' % int(time.time()))
        os.makedirs(os.path.dirname(out), exist_ok=True)
        json.dump({'rom': rom_id(), 'file': path, 'results': list(res.values())}, open(out, 'w'), indent=1)
        return
    order = {'blocker': 0, 'major': 1, 'minor': 2, 'note': 3}
    rows.sort(key=lambda r: (order.get(r['severity'], 9), r['scene']))
    if a.json:
        print(json.dumps(rows, indent=1))
        return
    for r in rows:
        print('[%s] %-7s %-14s %s%s  (%s, %s)' % (r['severity'], r['kind'], r['scene'], r['title'],
              '' if r['repro_verified'] else '  !repro unverified', r['tester'], r['screen']))


# ---------------------------------------------------------------- build
def ensure_core():
    src = os.path.join(HERE, 'ptcore.c')
    if not os.path.exists(PTCORE) or os.path.getmtime(PTCORE) < os.path.getmtime(src):
        os.makedirs(PT, exist_ok=True)
        subprocess.check_call(['cc', '-O2', '-o', PTCORE, src,
                               '-I', os.path.join(ROOT, 'build', 'emu', 'snes9x', 'libretro')])


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('do', help='step a session with a script')
    p.add_argument('session')
    p.add_argument('script')
    p = sub.add_parser('new', help='start (or restart) a session, optionally at a target')
    p.add_argument('session')
    p.add_argument('target', nargs='?')
    p = sub.add_parser('state', help='full telemetry for a session')
    p.add_argument('session')
    p = sub.add_parser('replay', help='replay a session from power-on and check determinism')
    p.add_argument('session')
    p.add_argument('--print', action='store_true', help='print the full input script')
    p = sub.add_parser('bot', help='run scripted bots on one event')
    p.add_argument('event', choices=EVENTS)
    p.add_argument('-p', '--policy', action='append')
    p.add_argument('-n', '--runs', type=int, default=8)
    p.add_argument('-s', '--seed', type=int, default=1)
    p.add_argument('-j', '--jobs', type=int, default=os.cpu_count())
    p.add_argument('--max-frames', type=int, default=60 * 240)
    p = sub.add_parser('curve', help='score and finish rate against human reaction time')
    p.add_argument('event', choices=EVENTS)
    p.add_argument('-p', '--policy')
    p.add_argument('-l', '--latencies', default='0,6,9,12,15,18,24')
    p.add_argument('-n', '--runs', type=int, default=4)
    p.add_argument('-s', '--seed', type=int, default=1)
    p.add_argument('-j', '--jobs', type=int, default=os.cpu_count())
    p.add_argument('--max-frames', type=int, default=60 * 240)
    p = sub.add_parser('balance', help='all events x default policies, with design flags')
    p.add_argument('events', nargs='*', choices=EVENTS + [[]], default=None)
    p.add_argument('-n', '--runs', type=int, default=6)
    p.add_argument('-s', '--seed', type=int, default=1)
    p.add_argument('-j', '--jobs', type=int, default=os.cpu_count())
    p.add_argument('--max-frames', type=int, default=60 * 240)
    p = sub.add_parser('fuzz', help='random input hunting crashes and soft-locks')
    p.add_argument('-n', '--runs', type=int, default=os.cpu_count())
    p.add_argument('-f', '--frames', type=int, default=60 * 60 * 5)
    p.add_argument('-s', '--seed', type=int, default=1)
    p.add_argument('-j', '--jobs', type=int, default=os.cpu_count())
    p.add_argument('--start', default='power', help="'power' or a goto target")
    p = sub.add_parser('lint', help='presentation lint: overscan text, sprites over text')
    p.add_argument('targets', nargs='*')
    p.add_argument('-f', '--frames', type=int, default=180)
    p.add_argument('--hold', help='buttons held while sampling, e.g. A')
    p.add_argument('-j', '--jobs', type=int, default=os.cpu_count())
    p = sub.add_parser('golden', help='screen-hash regression of every goto target')
    p.add_argument('mode', choices=['record', 'check'])
    p = sub.add_parser('bug', help='file a finding at the session\'s current moment (screenshot, state, verified repro)')
    p.add_argument('session')
    p.add_argument('title')
    p.add_argument('-s', '--severity', choices=['blocker', 'major', 'minor', 'note'], default='major')
    p.add_argument('-k', '--kind', choices=['bug', 'design', 'art', 'audio', 'ux', 'toronto', 'balance'], default='bug')
    p.add_argument('-d', '--detail')
    p.add_argument('-t', '--tester')
    p.add_argument('-c', '--check', help='condition that holds while the bug is present, e.g. "ev_score>2000" or "scene=bike.results"; lets findings --verify say PRESENT/GONE')
    p = sub.add_parser('findings', help='list filed findings, most severe first')
    p.add_argument('--json', action='store_true')
    p.add_argument('--verify', action='store_true', help='replay every finding on the current ROM')
    p.add_argument('--file', help='a findings .jsonl (default: the live one)')
    sub.add_parser('scenes', help='list goto targets')
    a = ap.parse_args()

    if a.cmd == 'do':
        print(json.dumps(Session(a.session).do(a.script), indent=1))
    elif a.cmd == 'new':
        d = os.path.join(PT, 'sessions', a.session)
        if os.path.isdir(d):
            shutil.rmtree(d)
        s = Session(a.session)
        print(json.dumps(s.do('goto:' + a.target if a.target else 'w1'), indent=1))
    elif a.cmd == 'state':
        s = Session(a.session)
        g = s.open()
        print(json.dumps(g.state(), indent=1))
        g.core.close()
    elif a.cmd == 'replay':
        cmd_replay(a)
    elif a.cmd == 'bot':
        cmd_bot(a)
    elif a.cmd == 'balance':
        cmd_balance(a)
    elif a.cmd == 'curve':
        cmd_curve(a)
    elif a.cmd == 'fuzz':
        cmd_fuzz(a)
    elif a.cmd == 'golden':
        cmd_golden(a)
    elif a.cmd == 'lint':
        cmd_lint(a)
    elif a.cmd == 'bug':
        cmd_bug(a)
    elif a.cmd == 'findings':
        cmd_findings(a)
    elif a.cmd == 'scenes':
        for n in TARGETS:
            print('  %-14s %s' % (n, TARGET_HELP.get(n, '')))


if __name__ == '__main__':
    main()
