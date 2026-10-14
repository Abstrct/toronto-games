"""SPC700 audio data: BRR samples + directory, pitch table, instruments and
the songs (written in tools/songs.py), compiled to the step format audio.s plays.

Song bytes: tempo even, tempo odd, length.w, loop step.w, 4 instrument ids,
then 4 channels x length steps (16th notes).
Step: 0 hold, 1 key off, 2.. = note (2 = C2), $80 kick, $81 snare, $82 hat,
$83 open hat, $84 crash, $85 low tom, $86 high tom, $87 rim, $90+n instrument.

Source tokens: '.' hold, '-' key off, 'C#5' note, k s h o x t T r drums,
'@n' instrument n, and 'tok:N' to make any token last N steps."""
import math
import struct
from snes import out

RATE = 32000
DIR_ADDR = 0x3000


def brr_encode(samples, loop=False):
    """Filter-0 BRR. samples: ints in -32768..32767, padded to 16."""
    s = list(samples)
    while len(s) % 16:
        s.append(0)
    data = bytearray()
    nblocks = len(s) // 16
    for b in range(nblocks):
        blk = s[b * 16:(b + 1) * 16]
        best = None
        for shift in range(0, 13):
            err = 0
            nibs = []
            for v in blk:
                n = int(round(v * 2 / (1 << shift)))
                n = max(-8, min(7, n))
                dec = (n << shift) >> 1
                err += (dec - v) ** 2
                nibs.append(n & 0xF)
            if best is None or err < best[0]:
                best = (err, shift, nibs)
        _, shift, nibs = best
        hdr = (shift << 4)
        if b == nblocks - 1:
            hdr |= 1
            if loop:
                hdr |= 2
        data.append(hdr)
        for i in range(0, 16, 2):
            data.append((nibs[i] << 4) | nibs[i + 1])
    return bytes(data)


def wave(kind, n=32, amp=6800):
    if kind == 'sq50':
        return [amp if i < n // 2 else -amp for i in range(n)]
    if kind == 'sq25':
        return [amp if i < n // 4 else -amp for i in range(n)]
    if kind == 'sq12':
        return [amp if i < n // 8 else -amp for i in range(n)]
    if kind == 'tri':
        out_ = []
        for i in range(n):
            p = i / n
            v = 4 * p - 1 if p < 0.5 else 3 - 4 * p
            out_.append(int(v * amp * 1.1))
        return out_
    if kind == 'saw':
        return [int((2 * i / (n - 1) - 1) * amp * 0.9) for i in range(n)]
    raise ValueError(kind)


def kick():
    n = 2400
    out_ = []
    ph = 0.0
    for i in range(n):
        t = i / RATE
        f = 45 + 160 * math.exp(-t * 38)
        ph += 2 * math.pi * f / RATE
        env = math.exp(-t * 16)
        out_.append(int(math.sin(ph) * 14000 * env))
    return out_


def tom():
    n = 5200
    out_ = []
    ph = 0.0
    for i in range(n):
        t = i / RATE
        f = 95 + 90 * math.exp(-t * 22)
        ph += 2 * math.pi * f / RATE
        env = math.exp(-t * 11)
        out_.append(int(math.sin(ph) * 13000 * env))
    return out_


def build_samples():
    samples = [
        (wave('sq50'), True),
        (wave('sq25'), True),
        (wave('sq12'), True),
        (wave('tri'), True),
        (wave('saw'), True),
        (kick(), False),
        (wave('sq50'), True),
        (wave('tri'), True),
        (tom(), False),
    ]
    directory = bytearray()
    body = bytearray()
    addr = DIR_ADDR + 4 * len(samples)
    for pcm, loop in samples:
        brr = brr_encode(pcm, loop)
        directory += struct.pack('<HH', addr + len(body), addr + len(body))
        body += brr
    blob = directory + body
    out('spc_blob.bin', blob)
    return len(blob)


def pitch_table():
    data = bytearray()
    for i in range(72):                    # C2 .. B7
        midi = 36 + i
        f = 440.0 * 2 ** ((midi - 69) / 12)
        p = min(0x3FFF, int(round(f * 32 * 4096 / RATE)))
        data += struct.pack('<H', p)
    out('pitch.bin', data)


# instruments: srcn, adsr1, adsr2, volume
INSTRUMENTS = [
    (1, 0xCE, 0xB0, 0x3F),   # 0 lead, 25% square
    (0, 0xCE, 0xB0, 0x33),   # 1 lead, 50% square
    (3, 0xFF, 0xE0, 0x3C),   # 2 bass, triangle
    (5, 0xFF, 0xE0, 0x49),   # 3 drums
    (2, 0xFF, 0x8C, 0x18),   # 4 arpeggio, 12% square
    (4, 0xCE, 0xB0, 0x4C),   # 5 saw lead
    (0, 0xCE, 0xB0, 0x50),   # 6 regatta lick, 50% square (louder: the song is sparse)
    (0, 0x8A, 0xE0, 0x1A),   # 7 soft pad
    (1, 0xFF, 0x70, 0x41),   # 8 pluck, 25% square
    (0, 0xFF, 0x74, 0x41),   # 9 stab, 50% square
    (2, 0xCE, 0xB0, 0x31),   # 10 thin lead, 12% square
    (3, 0xCE, 0xB0, 0x44),   # 11 flute, triangle
    (2, 0xFF, 0x72, 0x50),   # 12 regatta strum, 12% square
    (1, 0xFF, 0x8E, 0x2C),   # 13 soft pluck, 25% square
    (2, 0xFF, 0x72, 0x36),   # 14 strum, 12% square
    (1, 0xCE, 0xB0, 0x58),   # 15 regatta lead, 25% square
]

NOTE = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}


DRUMS = {'k': 0x80, 's': 0x81, 'h': 0x82, 'o': 0x83, 'x': 0x84, 't': 0x85, 'T': 0x86, 'r': 0x87}


def step(tok):
    if tok == '.':
        return 0
    if tok == '-':
        return 1
    if tok in DRUMS:
        return DRUMS[tok]
    name = tok[0]
    acc = 0
    rest = tok[1:]
    if rest and rest[0] in '#b':
        acc = 1 if rest[0] == '#' else -1
        rest = rest[1:]
    octv = int(rest)
    midi = 12 * (octv + 1) + NOTE[name] + acc
    idx = midi - 36
    assert 0 <= idx < 72, tok
    return 2 + idx


def chan(text, inst=None):
    """Compile a channel. '@n' is zero-width: it rides on the hold step just
    before it (or sets the starting instrument). Returns steps, or with inst
    given, (steps, starting instrument, instrument at each step)."""
    steps = []
    cur = inst
    first = inst
    at = []
    for t in text.replace('|', ' ').split():
        n = 1
        if ':' in t:
            t, n = t.split(':')
            n = int(n)
        if t[0] == '@':
            k = int(t[1:])
            assert 0 <= k < len(INSTRUMENTS), t
            if not steps:
                first = cur = k
            else:
                assert steps[-1] == 0, 'instrument change needs a hold before it: ' + text[:40]
                steps[-1] = 0x90 + k
                cur = k
            continue
        steps.append(step(t))
        steps += [0] * (n - 1)
        at += [cur] * n
    if inst is None:
        return steps
    return steps, first, at


NAMES = ['C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B']


def midi(tok):
    name = tok[0]
    acc = 0
    rest = tok[1:]
    if rest and rest[0] in '#b':
        acc = 1 if rest[0] == '#' else -1
        rest = rest[1:]
    return 12 * (int(rest) + 1) + NOTE[name] + acc


def nname(m):
    return NAMES[m % 12] + str(m // 12 - 1)


def tr(text, semis):
    """Transpose every note token in a channel string."""
    outt = []
    for t in text.split():
        d = ''
        if ':' in t:
            t, d = t.split(':')
            d = ':' + d
        if t[0] in NOTE:
            t = nname(midi(t) + semis)
        outt.append(t + d)
    return ' '.join(outt)


def fill(chords, tmpl):
    """One template per chord. Chord = 'A3 C4 E4'. Template tokens: 1-4 pick
    a chord tone (+ / ++ up octaves, _ down one), anything else is literal."""
    outt = []
    for c in chords:
        tones = [midi(n) for n in c.split()]
        for t in tmpl.split():
            d = ''
            if ':' in t:
                t, d = t.split(':')
                d = ':' + d
            if t[0] in '1234':
                m = tones[int(t[0]) - 1]
                m += 12 * t.count('+') - 12 * t.count('_')
                t = nname(m)
            outt.append(t + d)
    return ' '.join(outt)


def arp(chords, per=16):
    """chords: list of 4-note chord strings, one per bar -> 16ths."""
    toks = []
    for c in chords:
        notes = c.split()
        toks += [notes[i % len(notes)] for i in range(per)]
    return ' '.join(toks)


def steps(text):
    return len(chan(text))


def song(tempo, insts, chans, loop=0):
    """tempo: frames per 16th, or (even, odd) for in-between tempos / swing.
    A channel that switches instrument gets switched back for the loop."""
    if isinstance(tempo, int):
        tempo = (tempo, tempo)
    insts = list(insts)
    chs = []
    for i, c in enumerate(chans):
        st, insts[i], at = chan(c, insts[i])
        if at and at[-1] != at[loop]:
            assert st[-1] == 0, 'channel %d must end on a hold to restore its instrument' % i
            st[-1] = 0x90 + at[loop]
        chs.append(st)
    n = len(chs[0])
    for c in chs:
        assert len(c) == n, [len(x) for x in chs]
    assert n % 2 == 0 and loop % 2 == 0 and loop < n
    data = bytearray(struct.pack('<BBHH', tempo[0], tempo[1], n, loop) + bytes(insts))
    for c in chs:
        data += bytes(c)
    return data


def songs():
    import songs as tracks
    S = tracks.all_songs()
    data = bytearray()
    table = bytearray()
    for s in S:
        table += struct.pack('<H', len(data))
        data += s
    out('music.bin', data)
    out('songs.bin', table)
    inst = bytearray()
    for i in INSTRUMENTS:
        inst += bytes(i)
    out('instruments.bin', inst)


def build():
    n = build_samples()
    pitch_table()
    songs()
    return n


if __name__ == '__main__':
    print('spc blob', build(), 'bytes')
