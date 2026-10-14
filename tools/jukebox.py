"""Dev helper: record every song from the ROM (title-screen sound test,
SELECT cycles) to build/music/NN.wav plus a notegram PNG of each.
    python3 tools/jukebox.py [seconds] [song ...]"""
import os
import subprocess
import sys
import wave

ROOT = os.path.join(os.path.dirname(__file__), '..')
OUT = os.path.join(ROOT, 'build', 'music')
RATE = 32040


def main():
    secs = float(sys.argv[1]) if len(sys.argv) > 1 else 30
    which = [int(a) for a in sys.argv[2:]] or list(range(9))
    os.makedirs(OUT, exist_ok=True)
    for n in which:
        raw = os.path.join(OUT, '%02d.raw' % n)
        script = 'w150 ' + 'pSELECT w4 ' * n + 'v:%s w%d V' % (raw, int(secs * 60))
        if n == 0:
            script = 'w60 v:%s w%d V' % (raw, int(secs * 60))
        subprocess.check_call([sys.executable, os.path.join(ROOT, 'tools', 'run.py'), script],
                              stdout=subprocess.DEVNULL)
        data = open(raw, 'rb').read()
        w = wave.open(os.path.join(OUT, '%02d.wav' % n), 'wb')
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data)
        w.close()
        print('song', n, len(data) // 4 / RATE, 's')
        if '--gram' in os.environ.get('JUKEBOX', ''):
            subprocess.check_call([sys.executable, os.path.join(ROOT, 'tools', 'notegram.py'), raw,
                                   os.path.join(OUT, '%02d.png' % n)])
        os.remove(raw)


if __name__ == '__main__':
    main()
