"""Generate every binary asset the ROM includes (build/*.bin)."""
import math
import os
import sys
import importlib

sys.path.insert(0, os.path.dirname(__file__))
from snes import out  # noqa: E402

MODULES = ['font', 'audio', 'art_title', 'art_menu', 'art_bike', 'art_bay', 'art_park', 'art_cops', 'art_sail', 'art_ceremony', 'art_parking', 'art_subway']


def tables():
    sine = bytearray()
    for i in range(256):
        v = int(round(math.sin(i * 2 * math.pi / 256) * 127))
        sine.append(v & 0xFF)
    out('sine.bin', sine)


def main():
    tables()
    for name in MODULES:
        path = os.path.join(os.path.dirname(__file__), name + '.py')
        if not os.path.exists(path):
            continue
        mod = importlib.import_module(name)
        r = mod.build()
        print('%-11s ok%s' % (name, '' if r is None else ' (%s)' % r))


if __name__ == '__main__':
    main()
