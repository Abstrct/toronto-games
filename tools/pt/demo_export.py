"""Record the attract-mode demos from the pt harness bots.

    python3 tools/pt/demo_export.py            # record all, write src/demo_data.inc, rebuild, verify
    python3 tools/pt/demo_export.py --verify   # just replay the committed streams and check them

How it works: the ROM has a harness hook, `demo_force` (game.s). Poked to 2
at the title, the next START runs demo_play in *record* mode: the event in
`demo_ev` starts exactly as an attract demo does (Practice, one PLAYER 1,
fixed rng and frame counter) but the real pads pass through and every frame's
`pad` is logged at $7F:0000 (boot.s demo_pads). We drive that with a bot
policy, then RLE the log into (mask word, frames byte) runs ending in a 0
count, for demo_blob in src/demo_data.inc. Poked to 1, the hook plays the
recorded stream, which is how --verify checks each demo reproduces its
recording (score and event RAM at the same frame).

Re-run this whenever an event's code or data changes: a stale stream just
plays a clumsier demo, but it no longer matches what the bot did.
"""
import argparse
import hashlib
import os
import random
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import pt  # noqa: E402

ROOT = pt.ROOT
OUT = os.path.join(ROOT, 'src', 'demo_data.inc')
DEMO_EVENTS = 5                 # events 0..4 have bots to record
POLICY = {'bike': 'bike_pro', 'bay': 'bay_beat', 'park': 'park_ace', 'cops': 'cops_pro',
          'sail': 'sail_expert'}
FRAMES = 1680                   # game frames per demo: ~28 s, intro + countdown included
CHECK_AT = FRAMES - 40          # NMI frame of the RAM comparison


def start_demo(g, ev, mode):
    pt.goto_target(g, 'title')
    g.core.poke(g.sym['demo_force'], bytes([mode]))
    g.core.poke(g.sym['demo_ev'], bytes([ev]))
    g.held = 0
    for _ in range(10):         # the first START may only settle the logo
        g.step(1, 0)
        g.step(3, pt.mask_of('START'))
        g.step(3, 0)
        for _ in range(40):
            g.step(1, 0)
            if g.core.peek(g.sym['demo_on'], 1)[0]:
                return
    raise RuntimeError('the demo never started (scene %s)' % g.scene())


def snapshot(g):
    return {'ev_score': int.from_bytes(g.core.peek(g.sym['ev_score'], 2), 'little'),
            'ev_ram': hashlib.sha1(g.core.peek(g.sym['ev_ram'], 2048)).hexdigest()[:12],
            'scene': g.scene()}


def frame_no(g):
    return int.from_bytes(g.core.peek(g.sym['frame'], 2), 'little')


def record(ev):
    from policies import POLICIES
    name = pt.EVENTS[ev]
    g = pt.Game()
    pol = POLICIES[POLICY[name]]()
    pol.game = g
    rng = random.Random(1992 + ev)
    start_demo(g, ev, 2)
    t, hold, snap, n = None, 0, None, 0
    while True:
        logged = int.from_bytes(g.core.peek(g.sym['demo_off'], 2), 'little') // 2
        if logged >= FRAMES or not g.core.peek(g.sym['demo_on'], 1)[0]:
            break
        sc = g.scene()
        if sc == name + '.play':
            if t is None:
                t = 0
            if t % pol.every == 0:
                hold = pol.act(t, g.last, rng)
            t += 1
        elif sc == name + '.intro':
            hold = pt.mask_of('A') if n % 30 < 3 else 0
        else:
            hold = 0
        g.step(1, hold)
        n += 1
        if frame_no(g) == CHECK_AT and snap is None:
            snap = snapshot(g)
    raw = g.core.peek(0x10000, logged * 2)
    g.core.close()
    masks = [raw[i] | raw[i + 1] << 8 for i in range(0, len(raw), 2)]
    return masks, snap


def rle(masks):
    runs = []
    for m in masks:
        if runs and runs[-1][0] == m and runs[-1][1] < 255:
            runs[-1][1] += 1
        else:
            runs.append([m, 1])
    return runs


def write_inc(streams):
    lines = ['; Attract-demo joypad streams: written by tools/pt/demo_export.py, do not edit.',
             '; Runs of (pad mask word, frames byte); a frames byte of 0 ends a stream.',
             '; demo_start: byte offset of each event\'s stream ($FFFF = no demo).',
             'demo_blob:']
    offs, off = [], 0
    for ev, (runs, snap) in enumerate(streams):
        offs.append(off)
        lines.append('; %s: %d runs, policy %s, expect %s' % (pt.EVENTS[ev], len(runs), POLICY[pt.EVENTS[ev]], snap))
        flat = []
        for m, n in runs:
            flat += ['$%02X' % (m & 0xFF), '$%02X' % (m >> 8), '%d' % n]
        flat += ['0', '0', '0']
        for i in range(0, len(flat), 24):
            lines.append('    .byte ' + ', '.join(flat[i:i + 24]))
        off += 3 * len(runs) + 3
    lines.append('demo_start:')
    lines.append('    .word ' + ', '.join('$%04X' % o for o in offs))
    lines.append('    .res (NUM_EVENTS - %d) * 2, $FF' % len(offs))
    open(OUT, 'w').write('\n'.join(lines) + '\n')
    return off


def play(ev):
    """replay the committed stream; -> snapshot at CHECK_AT and whether it returned to the title"""
    g = pt.Game()
    start_demo(g, ev, 1)
    snap = None
    for i in range(FRAMES + 600):
        g.step(1, 0)
        if frame_no(g) == CHECK_AT and snap is None:
            snap = snapshot(g)
        if snap and g.scene() == 'title':
            break
    back = g.scene() == 'title'
    on = g.core.peek(g.sym['demo_on'], 1)[0]
    g.core.close()
    return snap, back, on


def expected():
    exp = {}
    for line in open(OUT):
        if line.startswith('; ') and ' expect ' in line:
            name = line[2:].split(':')[0]
            exp[name] = eval(line.split(' expect ', 1)[1])
    return exp


def verify():
    exp = expected()
    ok = True
    for ev in range(DEMO_EVENTS):
        name = pt.EVENTS[ev]
        snap, back, on = play(ev)
        good = snap == exp.get(name) and back and on == 0
        ok &= good
        print('%-5s %s  playback %s  recorded %s  back to title %s' % (
            name, 'OK  ' if good else 'FAIL', snap, exp.get(name), back))
    return ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--verify', action='store_true')
    a = ap.parse_args()
    subprocess.run(['make'], cwd=ROOT, check=True, capture_output=True)
    if not a.verify:
        streams = []
        for ev in range(DEMO_EVENTS):
            masks, snap = record(ev)
            runs = rle(masks)
            streams.append((runs, snap))
            print('%-5s %d frames -> %d runs, %s' % (pt.EVENTS[ev], len(masks), len(runs), snap))
        size = write_inc(streams)
        print('wrote %s (%d bytes)' % (os.path.relpath(OUT, ROOT), size))
        subprocess.run(['make'], cwd=ROOT, check=True, capture_output=True)
    sys.exit(0 if verify() else 1)


if __name__ == '__main__':
    main()
