"""Dev helper: render a 'notegram' (energy at each semitone C2..C7 over time)
of a raw 16-bit stereo capture from the harness, to eyeball the music."""
import math
import struct
import sys
from PIL import Image

RATE = 32040


def main(path, out):
    data = open(path, 'rb').read()
    n = len(data) // 4
    mono = []
    for i in range(0, n, 4):                     # decimate to 8 kHz
        l, r = struct.unpack_from('<hh', data, i * 4)
        mono.append((l + r) / 65536.0)
    rate = RATE / 4.0
    win = 400
    notes = [65.41 * 2 ** (k / 12.0) for k in range(61)]
    cols = []
    for start in range(0, len(mono) - win, win):
        seg = mono[start:start + win]
        col = []
        for f in notes:
            w = 2 * math.pi * f / rate
            c = 2 * math.cos(w)
            s1 = s2 = 0.0
            for x in seg:
                s0 = x + c * s1 - s2
                s2, s1 = s1, s0
            p = s1 * s1 + s2 * s2 - c * s1 * s2
            col.append(p)
        cols.append(col)
    peak = max(max(c) for c in cols) or 1
    img = Image.new('RGB', (len(cols) * 3, 61 * 4))
    px = img.load()
    for x, col in enumerate(cols):
        for y, p in enumerate(col):
            v = int(255 * max(0.0, min(1.0, 1 + math.log10(p / peak + 1e-12) / 4)))
            for dx in range(3):
                for dy in range(4):
                    px[x * 3 + dx, (60 - y) * 4 + dy] = (v, v // 2 + (v > 200) * 100, 40)
    img.save(out)
    print('frames', len(cols), 'saved', out)


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
