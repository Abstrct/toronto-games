"""The soundtrack: 8-bit loops after Canadian bands - close enough to tickle
your memory, bent enough to stay its own tune (chords and grooves follow the
originals, the melodies wander off).

Four channels like an NES: lead, harmony, bass (triangle), drums.
Tempo is frames per 16th note at 60 Hz: 900 / BPM (a pair alternates)."""
from audio import song, fill, tr, chan

# instrument ids (see audio.INSTRUMENTS)
LEAD25, LEAD50, BASS, DRUMS, PARK_BASS, SAW, SAIL_LICK, PAD = range(8)
PLUCK, STAB, THIN, FLUTE, SAIL_STRUM, SOFTPLUCK, STRUM, SAIL_LEAD = range(8, 16)


def rest(bars):
    return '.:%d' % (16 * bars)


def rep(text, n):
    return ' '.join([text] * n)


def sec(name, lead, harm, bass, drums):
    """A section: four channel strings that must all be the same length."""
    lens = [len(chan(c)) for c in (lead, harm, bass, drums)]
    assert len(set(lens)) == 1 and lens[0] % 16 == 0, (name, lens)
    return (lead, harm, bass, drums)


def join(*sections):
    return [' '.join(s[i] for s in sections) for i in range(4)]


def pump(*roots):
    """Root 8ths, one bar per root."""
    return ' '.join(rep(r + ' .', 8) for r in roots)


# ---------------------------------------------------------------------------
# 0 title - "KC Incidental" (after Broken Social Scene, "KC Accidental")
# E minor, a ringing chord-shape riff over Em7 - Am/E - G/D D7 - Cmaj7 with
# the bass stepping down E D C, layered chiming guitars, busy punchy drums.
def kc_sections():
    em7, ame, gd, d7, cm7 = 'E3 G3 B3 D4', 'E3 G3 C4 E4', 'D3 G3 B3 D4', 'D3 F#3 A3 C4', 'C3 E3 G3 B3'
    halves = [em7, em7, ame, ame, gd, d7, cm7, cm7]
    shimmer = fill(halves, '1 3 4 3 2 4 3+ 4')
    shimmer_hi = fill(halves, '1+ 3 4 3 2+ 4 3+ 4')
    riff = ('D5:3 D5:3 D5:2 C5:4 B4:4 '
            'C5:3 E5:3 C5:2 B4:4 G4:4 '
            'B4:4 G4:2 D4:2 F#4:2 A4:2 C5:4 '
            'B4:2 G4:2 E4:2 C4:2 E4:2 G4:2 B4:4')
    melody = ('G4:8 A4:6 B4:2 C5:8 B4:4 A4:4 B4:6 A4:2 G4:4 F#4:4 G4:4 E4:12 '
              'G4:8 A4:6 B4:2 D5:8 C5:4 B4:4 C5:6 B4:2 A4:4 F#4:4 E4:12 - . . .')
    bass = ('E2 . E2 . E3 . E2 . E2 . E2 . E3 . E2 . '
            'E2 . E2 . E3 . E2 . E2 . E2 . E3 . E2 . '
            'D2 . D2 . D3 . D2 . D2 . D2 . D3 . F#2 . '
            'C2 . C2 . C3 . C2 . C2 . C2 . C3 . D2 .')
    beat = 'k . h k s . h . k . h k s . h h'
    drums = ('x . h k s . h . k . h k s . h h ' + rep(beat, 2) +
             ' k . h k s . h . T T T . t t t .')
    intro = sec('intro', '@8 ' + riff, '@13 ' + shimmer, rest(4),
                rest(3) + ' . . . . . . . . T . T . t t t t')
    a = sec('a', rep(riff, 2), shimmer + ' ' + shimmer_hi, rep(bass, 2), rep(drums, 2))
    b = sec('b', '@5 ' + melody, rep(shimmer_hi, 2), rep(bass, 2), rep(drums, 2))
    a2 = sec('a2', '@8 ' + riff, shimmer_hi, bass,
             'x . h k s . h . k . h k s . h h ' + rep(beat, 2) +
             ' k . s s s . s s T T T T t t t t')
    return intro, a, b, a2


def kc_incidental():
    intro, a, b, a2 = kc_sections()
    return song(6, [PLUCK, SOFTPLUCK, BASS, DRUMS], join(intro, a, b, a2), loop=64)


# ---------------------------------------------------------------------------
# 8 podium - "KC Incidental (Podium Reprise)": the title theme comes back for
# the medals, behind a four-bar fanfare that swells out of a snare roll.
def podium_reprise():
    _, a, b, a2 = kc_sections()
    em, c, d, b7 = 'E3 G3 B3 E4', 'C3 E3 G3 C4', 'D3 F#3 A3 D4', 'B2 D#3 F#3 A3'
    fanfare = sec('fanfare',
                  '@9 E5:2 E5:2 E5:2 G5:2 B5:8 '
                  'C6:2 C6:2 C6:2 B5:2 G5:8 '
                  'A5:2 A5:2 A5:2 B5:2 D6:8 '
                  'D#6:4 F#6:4 B5:6 . . @8',
                  '@9 ' + fill([em, c, d, b7], '1 . 2 . 3 . 4 . 3+ . . . 4 . . .') + ' @13',
                  'E2:8 E3:8 C2:8 C3:8 D2:8 D3:8 B1:8 B2:4 F#2:4'.replace('B1:8', 'B2:8'),
                  'r . . . r . . . r . r . r r r r '
                  'x . . . s . . . x . . . s . s . '
                  'x . . . s . . . x . . . s s s s '
                  'x . T . T . t . t . t . s s s s')
    return song(6, [STAB, STAB, BASS, DRUMS], join(fanfare, a, b, a2), loop=64)


# ---------------------------------------------------------------------------
# 7 off-leash - "If I Had a Million Collars" (after Barenaked Ladies, "If I
# Had $1000000"): Scarborough's finest for Trinity Bellwoods. D major, a
# swung boom-chick strum, a whistled lead (you're calling a dog), the
# stepping-down verse D - A/C# - Bm - A - G - D/F# - Em - A and a bouncy
# D - G - A - D chorus with a gap for the woof.
def million_collars():
    D, Acs, Bm, A = 'D3 F#3 A3 D4', 'C#3 E3 A3 C#4', 'B2 D3 F#3 B3', 'A2 E3 A3 C#4'
    G, Dfs, Em = 'G2 D3 G3 B3', 'F#2 D3 F#3 A3', 'E3 G3 B3 E4'
    pick = '1 . 3 4 2 . 3 4 1 . 3 4 2 3 4 3'

    def walk(r, f, w):
        return '%s:4 %s:4 %s:4 %s:2 %s:2' % (r, f, r, f, w)

    shuffle = 'k . h . s . h . k . h k s . h .'
    intro = sec('intro', rest(2),
                '@14 ' + fill([D, A], pick),
                walk('D2', 'A2', 'C#3') + ' ' + walk('A2', 'E2', 'C#3'),
                'h . h . h . h . h . h . h . h . k . h . s . h . k . s . s s s s')
    verse = sec('verse',
                '@11 A4:4 F#4:2 A4:2 D5:6 . . '
                'C#5:2 D5:2 E5:4 C#5:4 A4:4 '
                'B4:4 D5:2 B4:2 F#4:6 . . '
                'A4:2 B4:2 C#5:4 E5:8 '
                'D5:4 B4:2 D5:2 G5:6 . . '
                'F#5:2 E5:2 D5:4 A4:8 '
                'G4:2 A4:2 B4:4 E5:4 D5:4 '
                'C#5:12 - . . .',
                fill([D, Acs, Bm, A, G, Dfs, Em, A], pick),
                ' '.join([walk('D2', 'A2', 'C#3'), walk('C#2', 'A2', 'B2'), walk('B2', 'F#2', 'A2'),
                          walk('A2', 'E2', 'G2'), walk('G2', 'D3', 'F#2'), walk('F#2', 'D3', 'E2'),
                          walk('E2', 'B2', 'G2'), walk('A2', 'E2', 'C#3')]),
                'x . h . s . h . k . h k s . h . ' + rep(shuffle, 6) + ' k . h . s . h . k . s . T . t .')
    chorus = sec('chorus',
                 'F#5:2 F#5:2 F#5:2 E5:2 D5:4 A4:4 '
                 'B4:2 B4:2 B4:2 C#5:2 D5:4 B4:4 '
                 'C#5:2 C#5:2 C#5:2 D5:2 E5:4 A5:4 '
                 'F#5:8 - . . . . . . . '
                 'A5:2 A5:2 A5:2 G5:2 F#5:4 D5:4 '
                 'G5:2 F#5:2 E5:2 D5:2 B4:4 D5:4 '
                 'E5:4 C#5:4 A4:4 E5:4 '
                 'D5:12 - . . .',
                 fill([D, G, A, D, D, G, A, D], pick),
                 pump('D2', 'G2', 'A2', 'D2', 'D2', 'G2', 'A2', 'D2'),
                 'x . h . s . h . k . h k s . h . ' + rep(shuffle, 2) +
                 ' k . h . s . . . x . . . s s s . ' + rep(shuffle, 3) + ' k . h . s . s . s s s s T T t t')
    return song((9, 6), [FLUTE, STRUM, BASS, DRUMS], join(intro, verse, chorus), loop=32)


# ---------------------------------------------------------------------------
# 2 bike courier - "Gold Guns Gulls" (after Metric, "Gold Guns Girls")
# A minor at 180: the octave riff, everything VI - VII - i, machine-gun 8ths,
# galloping kick in the chorus.
def gold_guns_gulls():
    riff_a = 'A3:2 A3:2 A4:2 A4:4 A4:4 A4:2'
    riff_b = 'A3:2 A3:2 A4:2 A4:4 G4:4 C5:2'
    riff = riff_a + ' ' + riff_b

    def chug(root, fifth):
        return ' '.join([root, '.', root, '.', fifth, '.', root, '.'] * 2)

    simple = 'k . h . s . h . k . h . s . h h'
    gallop = 'k . k . s . k . k . k . s . k h'

    intro = sec('intro',
                rest(4),
                '@9 ' + rep(riff, 2),
                rest(2) + ' ' + pump('A2') + ' A2 . A2 . A2 . A2 . A2 . A2 C3 . A2 . D3',
                rep(simple, 3) + ' k . h . s . h . k k k k s s s s')
    verse = sec('verse',
                '. . . . A4:2 A4:2 C5:2 A4:2 G4:4 A4:12 - . . . '
                '. . . . B4:2 B4:2 D5:2 B4:2 A4:4 G4:12 - . . . '
                '. . . . C5:2 C5:2 E5:2 C5:2 D5:4 C5:4 B4:4 A4:8 '
                '. . . . E5:2 D5:2 C5:2 A4:2 B4:4 A4:12 - . . .',
                ' '.join([chug('F3', 'C4')] * 2 + [chug('G3', 'D4')] * 2 + [chug('A3', 'E4')] * 4),
                pump('F2', 'F2', 'G2', 'G2', 'A2', 'A2', 'A2', 'A2'),
                'x . h . s . h . k . h . s . h h ' + rep(simple, 6) + ' k . h . s . h . k . s s s . s .')
    pre = sec('pre',
              'A4:8 C5:8 A4:16 B4:8 D5:8 E5:12 - . . .',
              'A3 . C4 . C4 . C4 . C4 . C4 . C4 . C4 . '
              'C4 . C4 . C4 . C4 . A3 . C4 . C4 . C4 . '
              'C4 . D4 . D4 . D4 . D4 . D4 . D4 . D4 . '
              'D4 . E4 . E4 . E4 . E4 . E4 . G4 . E4 .',
              pump('F2', 'F2', 'G2', 'G2'),
              rep('k . t . k . t . k . t . k . t .', 3) + ' k t k t s s s s T T T T t t t t')
    chorus = sec('chorus',
                 '@0 E5:2 E5:2 E5:2 G5:2 E5:4 D5:2 C5:2 D5:4 C5:4 A4:8 '
                 'E5:2 E5:2 E5:2 G5:2 A5:4 G5:2 E5:2 G5:4 E5:4 D5:8 '
                 'C5:4 A4:4 C5:4 D5:4 C5:8 A4:8 '
                 'B4:4 D5:4 G5:4 F5:2 E5:2 D5:8 B4:4 - . . .',
                 rep(riff, 2) + ' ' + rep(tr(riff_a, -4), 2) + ' ' + rep(tr(riff_a, -2), 2),
                 pump('A2', 'A2', 'A2', 'A2', 'F2', 'F2', 'G2', 'G2'),
                 'x . k . s . k . k . k . s . k h ' + rep(gallop, 6) + ' k . k . s . k . s s s s T T t t')
    return song(5, [THIN, STAB, BASS, DRUMS], join(intro, verse, pre, chorus))


# ---------------------------------------------------------------------------
# 4 bay st power walk - "Whelp, I'm Alive" (after Metric, "Help I'm Alive")
# G minor at ~120: Bb - C - Gm - Eb over a heartbeat kick, root 8ths with a
# high Bb ping on 2 and 4, the four-on-the-floor "hammer" pedal on G, then
# Bb - Eb - F - Gm with the guitar pedalling Bb (A under the F).
def whelp_im_alive():
    def ping(root):
        return '%s . %s . Bb4 . %s . %s . %s . Bb4 . %s .' % ((root,) * 6)

    verse_harm = ' '.join(ping(r) for r in ('Bb2', 'C3', 'G2', 'Eb3'))
    heart = 'k . k . s h s . k . k . s h s .'
    verse1 = sec('verse1',
                 '@7 Bb4:16 C5:16 G4:16 Eb4:14 - .',
                 '@8 ' + verse_harm,
                 'Bb2:16 C3:16 G2:16 Eb2:16',
                 rep(heart, 4))
    verse2 = sec('verse2',
                 '@0 D5:2 D5:2 D5:2 C5:2 D5:4 F5:4 E5:4 D5:2 C5:2 C5:8 '
                 'D5:2 D5:2 D5:2 Bb4:2 D5:4 G5:4 F5:4 Eb5:2 D5:2 Bb4:6 - .',
                 verse_harm,
                 'Bb2:16 C3:16 G2:16 Eb2:16',
                 rep(heart, 3) + ' k . k . s h s . s s s s s s s s')
    hammer = sec('hammer',
                 'G5:2 G5:2 G5:2 F5:2 G5:4 Bb5:4 A5:4 G5:4 F5:4 D5:4 '
                 'G5:2 G5:2 G5:2 F5:2 G5:4 Bb5:4 C6:4 Bb5:4 A5:6 - .',
                 '@9 ' + rep('G3 . D4 . G4 . D4 .', 8),
                 pump('G2', 'G2', 'G2', 'G2'),
                 'x . h . k . h . k . h . k . h . ' + 'k . h . k . h . k . h . k . h . '
                 'k . o . k . o . k . o . k . o . ' + 'x . . . x . . . x . . . x . s s')
    chorus = sec('chorus',
                 'D5:4 F5:4 D5:4 Bb4:4 Eb5:4 G5:4 F5:4 Eb5:4 F5:4 C5:4 A4:4 C5:4 D5:12 - . . .',
                 pump('Bb3', 'Bb3', 'A3', 'Bb3'),
                 pump('Bb2', 'Eb3', 'F2', 'G2'),
                 'x . h . s . h . k . h . s . h . ' + rep('k . h . s . h . k . h . s . h .', 2) +
                 ' k . h . s . h . k . h . s . s s')
    return song((8, 7), [PAD, PLUCK, BASS, DRUMS], join(verse1, verse2, hammer, chorus))


# ---------------------------------------------------------------------------
# 1 menu - "Bobcaygeese" (after The Tragically Hip, "Bobcaygeon")
# G major, laid back at ~85: G | Am7 rocking B-C on top, the 5-6-1 pickup
# into G answered by an A-E-G-C arpeggio, then Bm | C | G | Am7.
def bobcaygeese():
    gtr_g = 'G3:2 B3:2 D4:2 C4 B3 G3:2 B3:2 C4 D4 B3:2'
    gtr_am = 'A3:2 E4:2 G4:2 E4:2 C5:2 G4:2 E4:2 C4:2'
    bass_g = 'G2:6 G2:2 . . B2:2 D3:4'
    bass_am = 'A2:4 E3:2 G3:2 C3:4 D2:2 E2:2'
    groove = 'k . h k s . k . h . k . s . h .'
    intro = sec('intro', rest(2), '@13 ' + gtr_g + ' ' + gtr_am, bass_g + ' ' + bass_am,
                '.:12 h . h h ' + '.:8 h . h . s s s s')
    verse = sec('verse',
                '. . . . B4:2 B4:2 B4:2 C5:2 D5:2 B4:2 C5:4 B4:2 A4:2 E4:8 '
                '. . . . B4:2 C5:2 D5:2 D5:2 C5:2 B4:2 C5:6 B4:2 G4:8 '
                '. . B4:2 B4:2 C5:2 D5:4 B4:2 G4:2 A4:4 C5:4 B4:2 A4:2 G4:4 '
                '. . . . D5:2 D5:2 C5:2 B4:2 C5:4 B4:4 A4:4 E4:4 D4:4',
                rep(gtr_g + ' ' + gtr_am, 4),
                rep(bass_g + ' ' + bass_am, 4),
                'x . h k s . k . h . k . s . h . ' + rep(groove, 6) + ' k . h k s . k . s . s s T . t .')
    chords = ['B3 D4 F#4', 'C4 E4 G4', 'G3 B3 D4', 'A3 C4 E4 G4']
    refrain = sec('refrain',
                  'D5:4 F#5:4 D5:4 B4:4 E5:6 D5:2 C5:4 G4:4 B4:4 D5:4 G5:6 F#5:2 E5:8 C5:4 A4:4 '
                  'D5:4 F#5:4 A5:4 F#5:4 G5:6 E5:2 C5:4 E5:4 D5:4 B4:4 G4:4 B4:4 A4:12 - . . .',
                  '@14 ' + rep(fill(chords, '1:2 2:2 3:2 2:2 1+:2 3:2 2:2 3:2'), 2),
                  pump('B2', 'C3', 'G2', 'A2', 'B2', 'C3', 'G2', 'A2'),
                  'x . h k s . k . h . k . s . h . ' + rep(groove, 2) + ' k . h k s . k . h . k . s . o . '
                  'k . o k s . k . o . k . s . o . ' + rep(groove, 2) + ' k . h k s . s . s s s s T T t t')
    return song((11, 10), [FLUTE, SOFTPLUCK, BASS, DRUMS], join(intro, verse, refrain), loop=32)


# ---------------------------------------------------------------------------
# 3 standings - "Ahead by a Centimetre" (after The Tragically Hip,
# "Ahead by a Century"). D major at ~128: the two-bar riff over ringing
# open-D strings with its G#-A-G# turn, a D drone verse, C and Cadd9
# detours, then the A | G/B chorus climbing 5-5-5-1-2-3.
def ahead_by_a_centimetre():
    riff1 = 'F#5:6 E5:4 A5:4 F#5:2 . . D5:4 A4:2 G#4:2 A4:2 G#4:2 E4:2'
    riff2 = 'F#5:6 D5:4 A5:4 B5:2 . . D5:4 A4:2 G#4:2 A4:2 B4:2 E4:2'

    def ring(*chords):
        return fill(chords, '1:2 2:2 3:2 2:2 1:2 2:2 3:2 2:2')

    d, c, cadd9, a, gb = 'D3 A3 D4', 'C3 G3 C4', 'C3 G3 D4', 'A2 E3 A3', 'B2 G3 D4'
    sync = '%s:3 %s:3 %s:2 %s:3 %s:3 %s:2'

    def drone(r, o, f):
        return sync % (r, r, o, r, f, o)

    soft = 'k . h . r . h . h . k . r . h .'
    full = 'k . h . s . h . h . k . s . h .'
    intro = sec('intro', '@8 ' + riff1 + ' ' + riff2, '@13 ' + ring(d, d, d, d),
                rest(2) + ' ' + drone('D2', 'D3', 'A2') + ' ' + drone('D2', 'D3', 'A2'),
                rest(1) + ' . . h . r . h . h . h . r . h . ' + rep(soft, 2))
    verse = sec('verse',
                '@1 A4:4 A4:2 F#4:2 A4:4 B4:4 A4:8 F#4:4 E4:4 A4:4 A4:2 F#4:2 A4:4 D5:4 C#5:8 A4:8 '
                'G4:4 G4:2 E4:2 G4:4 A4:4 G4:8 E4:8 F#4:4 A4:4 D5:4 E5:4 F#5:8 E5:4 D5:4',
                ring(d, d, d, d, c, c, d, d),
                ' '.join([drone('D2', 'D3', 'A2')] * 4 + [drone('C2', 'C3', 'G2')] * 2 +
                         [drone('D2', 'D3', 'A2')] * 2),
                rep(soft, 7) + ' k . h . r . h . r . r . T . t .')
    pre = sec('pre',
              'D5:8 E5:8 F#5:16 E5:8 D5:8 E5:10 A4:2 A4:2 A4:2',
              ring(d, d, cadd9, cadd9),
              drone('D2', 'D3', 'A2') + ' ' + drone('D2', 'D3', 'A2') + ' ' +
              drone('C2', 'C3', 'G2') + ' ' + drone('C2', 'C3', 'G2'),
              rep(full, 3) + ' k . h . s . h . s . s . s s s s')
    chorus = sec('chorus',
                 '@5 D5:10 D5:2 E5:2 F#5:2 E5:8 C#5:4 A4:4 B4:4 D5:4 G5:4 F#5:2 E5:2 D5:10 A4:2 A4:2 A4:2 '
                 'D5:10 E5:2 F#5:2 A5:2 G5:6 F#5:2 E5:8 D5:4 B4:4 D5:4 E5:4 D5:12 - . . .',
                 ring(a, a, gb, gb, a, a, gb, gb),
                 pump('A2', 'A2', 'B2', 'B2', 'A2', 'A2', 'B2', 'B2'),
                 'x . h . s . h . h . k . s . h . ' + rep(full, 3) +
                 ' x . h . s . h . h . k . s . h . ' + rep(full, 2) + ' k . h . s . s . T T T T t t t t')
    return song(7, [PLUCK, SOFTPLUCK, BASS, DRUMS], join(intro, verse, pre, chorus))


# ---------------------------------------------------------------------------
# 5 chase - "Hay, Officer" (after Mother Mother, "Hayloft")
# A minor at ~200: Am | C/G | F | Ab, an 8th-note riff hammering A against a
# moving lower note (the Ab creeping back up to A), half-time drums, a
# six-syllable hook, and a jump up a half step.
def hay_officer():
    def riff(lows):
        return ' '.join('A4:2 %s:2 A4:2 %s:2 A4:2 %s:2 A4:2 %s:2' % (l, l, l, m) for l, m in lows)

    loop = riff([('G4', 'G4'), ('E4', 'G#4'), ('F4', 'F4'), ('G#4', 'G#4')])
    roots = [('A2', 'A3'), ('G2', 'G3'), ('F2', 'F3'), ('G#2', 'G#3')]
    bounce = ' '.join(rep('%s:2 %s:2' % r, 4) for r in roots)
    half = 'k . h . k . h . s . h . h . k .'
    drive = 'k . o . s . o . k . o . s . o .'
    roll = 's . s . s . s . s s s s s s s s'
    # the riff alone for two bars, then the bass bounce and hats join (a race
    # starts here, so the build-up can't be four bars of near silence)
    intro = sec('intro', rest(4), '@9 ' + loop,
                rest(2) + ' ' + ' '.join(rep('%s:2 %s:2' % r, 4) for r in roots[2:]),
                rest(2) + ' ' + half + ' . . . . . . . . s s s s s s s s')
    lead = sec('lead',
               '@10 E5:2 E5:2 E5:2 E5:2 -:2 E5:2 E5:2 -:2 E5:2 F5:2 G5:2 A5:2 -:8 '
               'E5:2 E5:2 E5:2 E5:2 -:2 E5:2 E5:2 -:2 E5:2 F5:2 G5:2 A5:2 A6:6 -:2 '
               'E5:2 E5:2 E5:2 E5:2 -:2 E5:2 E5:2 -:2 E5:2 F5:2 G5:2 A5:2 -:8 '
               'E5:2 E5:2 E5:2 E5:2 -:2 G5:2 E5:2 -:2 E5:2 F5:2 G5:2 C6:2 A6:6 -:2',
               rep(loop, 2),
               rep(bounce, 2),
               'x . o . s . o . k . o . s . o . ' + rep(drive, 6) + ' ' + roll)
    hook = sec('hook',
               '@0 E5:2 -:2 E5:2 -:2 E5:2 G5:2 A5:2 C6:2 -:2 E5:2 -:2 E5:2 E5:2 G5:2 A5:2 G5:2 '
               'F5:2 -:2 F5:2 F5:2 F5:2 A5:2 C6:2 A5:2 -:2 Eb5:2 -:2 C6:2 -:2 Bb5:2 -:2 G5:2 '
               'E5:2 -:2 E5:2 -:2 E5:2 G5:2 A5:2 C6:2 -:2 E5:2 -:2 E5:2 E5:2 G5:2 A5:2 G5:2 '
               'F5:2 -:2 F5:2 F5:2 F5:2 A5:2 C6:2 A5:2 -:2 Eb5:2 Eb5:2 Eb5:2 -:2 Bb5:2 G5:4',
               rep(loop, 2),
               pump('A2', 'G2', 'F2', 'G#2', 'A2', 'G2', 'F2', 'G#2'),
               'x . h . k . h . s . h . h . k . ' + rep(half, 6) + ' ' + roll)
    jump = sec('jump',
               '@10 ' + tr('E5:2 E5:2 E5:2 E5:2 -:2 E5:2 E5:2 -:2 E5:2 F5:2 G5:2 A5:2 A6:6 -:2', 1) +
               ' ' + tr('E5:2 E5:2 E5:2 E5:2 -:2 G5:2 E5:2 -:2 E5:2 F5:2 G5:2 C6:2 A6:6 -:2', 1),
               tr(loop, 1),
               tr(bounce, 1),
               'x . o . s . o . ' * 1 + 'k . o . s . o . ' + rep(drive, 2) + ' ' + roll)
    return song((5, 4), [THIN, STAB, BASS, DRUMS], join(intro, lead, hook, jump), loop=64)


# ---------------------------------------------------------------------------
# 6 regatta - "Brother Downwind" (after Sam Roberts, "Brother Down")
# D Dorian at ~100: Dm | C | G | G strummed with F always on top and a G-F
# flick on beat 4, a sixteenth-note chant, the "rest, then climb" chorus on
# Dm and G, and the falling three-note guitar lick.
def brother_downwind():
    strum = '1 2 3 4 1 - 3 4 1 2 3 4 G4 4 3 4'
    dm, c, g = 'D3 A3 D4 F4', 'C3 G3 C4 F4', 'G2 D3 B3 F4'

    def bassbar(r, o, f):
        return '%s:3 %s:3 %s:2 %s:3 %s:3 %s:2' % (r, r, o, r, f, o)

    bd, bc, bg = bassbar('D2', 'D3', 'A2'), bassbar('C2', 'C3', 'G2'), bassbar('G2', 'G3', 'D3')
    groove = 'k . h . s . h k k . h . s . h .'
    groove2 = 'k . h . s . h k h . k . s . h .'
    beat4 = groove + ' ' + groove2 + ' ' + groove + ' ' + groove2
    dcgg = fill([dm, c, g, g], strum)
    # a two-bar count-in on G (a race is ~25 s, so the band comes in early)
    intro = sec('intro', rest(2), '@12 ' + fill([g, g], strum), bg + ' ' + bg,
                '. . h . . . h . . . h . . . h . k . h . s . h k s . s . s s s s')
    verse = sec('verse',
                'A4 A4 A4 A4 C5:2 A4:2 D5 C5 A4:2 G4:4 A4 A4 A4 A4 C5:2 D5:2 E5:4 D5:4 '
                'D5 D5 D5 D5 C5:2 A4:2 G4:8 -:16 '
                'A4 A4 A4 A4 C5:2 A4:2 D5 C5 A4:2 E5:4 E5 E5 E5 E5 D5:2 C5:2 D5:4 C5:4 '
                'B4 B4 B4 B4 A4:2 G4:2 A4:8 -:16',
                rep(dcgg, 2),
                rep(' '.join([bd, bc, bg, bg]), 2),
                'x . h . s . h k k . h . s . h . ' + groove2 + ' ' + groove + ' ' + groove2 + ' ' +
                groove + ' ' + groove2 + ' ' + groove + ' k . h . s . h k s . s . T . t .')
    chorus = sec('chorus',
                 '@15 -:4 A4:4 C5:2 D5:4 E5:2 .:6 D5:2 C5:4 A4:4 '
                 '-:4 A4:4 C5:2 D5:4 E5:2 .:6 G5:2 E5:4 D5:4 '
                 '-:4 A4:4 C5:2 D5:4 E5:2 .:6 D5:2 C5:4 A4:4 '
                 '-:4 B4:4 D5:2 E5:4 G5:2 .:4 E5:2 D5:4 C5:2 A4:4',
                 rep(fill([dm, dm, g, g], strum), 2),
                 rep(' '.join([bd, bd, bg, bg]), 2),
                 'x . h . s . h k k . h . s . h . ' + groove2 + ' ' + beat4 + ' ' +
                 groove + ' k . h . s . h k s . s s s s s s')
    lick = sec('lick',
               '@6 F5:6 E5:6 D5:4 F5:6 E5:6 C5:4 B4:6 C5:6 D5:4 B4:6 C5:6 D5:4 '
               'F5:6 E5:6 D5:4 F5:6 E5:6 D5:4 A5:6 G5:6 F5:4 A5:6 G5:6 F5:2 - .',
               rep(dcgg, 2),
               rep(' '.join([bd, bc, bg, bg]), 2),
               'x . h . s . h k k . h . s . h . ' + groove2 + ' ' + beat4 + ' ' +
               groove + ' k . h . s . h k s . s . s s s s')
    return song(9, [SAIL_LEAD, SAIL_STRUM, BASS, DRUMS], join(intro, verse, chorus, lick), loop=32)



# ---------------------------------------------------------------------------
# 9 parallel parking - "Park the Pain Away" (a nod to Peaches, "Fuck the Pain
# Away"): an original tune in that song's world - F# minor at ~130, bare
# groovebox electroclash with a broken (not four-on-the-floor) beat, a low
# buzzing saw bass, a deadpan chanted lead, and a backing-up beeper in the
# harmony. It stops dead before the loop, like you should.
KEY_PARK = 2                    # written in E minor, played in F# minor


def park_the_pain_away():
    buzz_a = 'E2:2 E2:2 . . E3:2 E2:2 . . D3:2 E2:2'
    buzz_b = 'E2:2 E2:2 . . E3:2 E2:2 G2:2 A2:2 B2:2'
    buzz_c = 'C2:2 C2:2 . . C3:2 C2:2 . . B2:2 C3:2'
    buzz_d = 'D2:2 D2:2 . . D3:2 D2:2 . . E3:2 D3:2'
    beeper = 'B5 - . . . . . . B5 - . . . . . .'
    machine = 'k . h . s . k . h . k . s . h .'
    machine2 = 'k . h . s . k . h . k . s . s s'
    verse_buzz = rep(rep(buzz_a, 3) + ' ' + buzz_b, 2)

    def offbeat(n):
        return '. . %s - . . %s - . . %s - . . %s -' % ((n,) * 4)

    intro = sec('intro', rest(4),
                '@9 ' + rest(2) + ' ' + rep(beeper, 2),
                rest(2) + ' ' + buzz_a + ' ' + buzz_b,
                'k . h . . . k . h . k . . . h . ' + machine + ' ' + machine + ' ' +
                'k . h . s . k . s . s . s s s s')
    verse = sec('verse',
                '@10 -:4 E5:2 E5:2 G5:2 -:2 E5:2 D5:2 E5:4 -:12 '
                '-:4 G5:2 G5:2 A5:2 -:2 G5:2 E5:2 D5:4 B4:4 -:8 '
                '-:4 E5:2 E5:2 G5:2 -:2 E5:2 D5:2 E5:4 -:4 B5:2 -:6 '
                '-:4 A5:2 G5:2 E5:2 -:2 D5:2 E5:2 E5:4 -:12',
                rep(beeper, 8),
                verse_buzz,
                'x . h . s . k . h . k . s . h . ' + machine2 + ' ' + rep(machine + ' ' + machine2, 2) +
                ' ' + machine + ' k . h . s . k . s s s . s s s s')
    chorus = sec('chorus',
                 'G5:4 G5:2 E5:2 G5:4 A5:4 F#5:6 E5:2 D5:8 '
                 'E5:2 E5:2 G5:2 B5:2 A5:4 G5:4 E5:12 -:4 '
                 'G5:4 G5:2 E5:2 G5:4 A5:4 B5:6 A5:2 F#5:8 '
                 'G5:2 F#5:2 E5:2 D5:2 B4:4 D5:4 E5:12 -:4',
                 ' '.join(offbeat(n) for n in ('G4', 'A4', 'B4', 'B4', 'G4', 'A4', 'B4', 'B4')),
                 rep(' '.join([buzz_c, buzz_d, buzz_a, buzz_b]), 2),
                 'x . o . s . k . o . k . s . o . ' + rep(machine + ' ' + machine2, 3) +
                 ' k . h . s . k . s . s s s s s s')
    brake = sec('brake',
                '-:16 ' + rest(3),
                '-:16 ' + rest(1) + ' ' + beeper + ' ' + beeper,
                buzz_a + ' ' + buzz_a + ' ' + buzz_a + ' E2:2 E2:2 E3:2 -:10',
                rep('k . . . . . k . . . k . . . . .', 2) + ' ' + machine +
                ' s . s . s s s s x . . . - . . .')
    return song(7, [THIN, STAB, PARK_BASS, DRUMS],
                [tr(c, KEY_PARK) for c in join(intro, verse, chorus, brake)], loop=64)


# ---------------------------------------------------------------------------
# 10 ttc surfing - "The Wait" (a nod to The Band, "The Weight"): an original
# tune in that song's world - A major at a lazy ~75 with a loose 16th swing,
# a gospel piano comp, a walking bass and a lean-back backbeat, verses that
# wander I - iii - IV - I and a call-and-response chorus rocking A to D.
def the_wait():
    A, Csm, D, E = 'A3 C#4 E4', 'G#3 C#4 E4', 'A3 D4 F#4', 'G#3 B3 E4'
    comp = '1:3 3 2:2 3:2 1:3 3 2:2 3:2'

    def walk(r, f, a):
        return '%s:6 %s:2 %s:4 %s:4' % (r, r, f, a)

    lazy = 'k . h . s . h . k . h k s . h .'
    lazy2 = 'k . h . s . h k . . h k s . h h'
    intro = sec('intro',
                '@15 A4:2 C#5:2 E5:4 D5:2 C#5:2 B4:4 A4:2 B4:2 C#5:2 E5:2 B4:6 - .',
                '@8 ' + fill([A, E], comp),
                walk('A2', 'E2', 'G#2') + ' ' + walk('E2', 'B2', 'G#2'),
                'h . h . h . h . h . h . h . h . k . h . s . h . k . T . t . t t')
    verse = sec('verse',
                '. . . . E4:2 A4:2 A4:2 B4:2 C#5:4 B4:4 A4:2 G#4:2 E4:8 '
                '. . . . F#4:2 A4:2 B4:2 A4:2 D5:4 C#5:6 B4:2 A4:8 '
                '. . . . C#5:2 E5:2 E5:2 C#5:2 B4:4 C#5:4 B4:2 G#4:2 B4:8 '
                'A4:4 F#4:2 A4:2 B4:4 D5:4 C#5:8 -:8',
                fill([A, Csm, D, A, A, Csm, D, A], comp),
                ' '.join([walk('A2', 'E2', 'B2'), walk('C#3', 'G#2', 'C#3'), walk('D3', 'A2', 'C#3'),
                          walk('A2', 'E2', 'A2'), walk('A2', 'E2', 'B2'), walk('C#3', 'G#2', 'C#3'),
                          walk('D3', 'A2', 'C#3'), walk('A2', 'E2', 'G#2')]),
                'x . h . s . h . k . h k s . h . ' + lazy2 + ' ' + rep(lazy + ' ' + lazy2, 2) +
                ' ' + lazy + ' k . h . s . h . s . s s T . t .')
    chorus = sec('chorus',
                 'C#5:4 E5:4 A5:6 G#5:2 F#5:6 E5:2 D5:8 '
                 'C#5:4 E5:4 A5:4 E5:4 F#5:12 - . . . '
                 'E5:4 C#5:2 E5:2 A5:4 B5:4 A5:4 F#5:2 E5:2 D5:8 '
                 'B4:4 E5:4 G#5:4 B5:4 A5:12 - . . .',
                 '@14 ' + fill([A, D, A, D, A, D, E, A], '1 . 2 . 3 . 2 . 1+:4 3:2 2:2'),
                 pump('A2', 'D2', 'A2', 'D2', 'A2', 'D2', 'E2', 'A2'),
                 'x . h . s . h . k . h k s . h . ' + rep(lazy + ' ' + lazy2, 3) +
                 ' k . h . s . s . T T t t s s s s')
    return song((13, 11), [SAIL_LEAD, PLUCK, BASS, DRUMS], join(intro, verse, chorus), loop=32)


# ---------------------------------------------------------------------------
# 11-13 result jingles (audio.s sfx_result): under two seconds each, played on
# the music voices when a result card comes up, then they fade out by
# themselves (the last chord rings until the fade). Not loops: loop=None.

# 11 finished: a three-note pickup into a ringing C major "ta-da"
def jingle_finish():
    return song(5, [LEAD25, PLUCK, BASS, DRUMS], [
        'G4 C5 E5:2 G5:2 E5:2 C6:14',
        'E4 G4 C5:2 E5:2 C5:2 G5:14',
        'C3:4 G2:4 C3:14',
        'r r r . s . s s x:12 . .'], loop=None)


# 12 failed: the sad trombone, wah wah wah wahhh, sliding C - B - Bb - Am
def jingle_fail():
    return song(6, [SAW, PAD, BASS, DRUMS], [
        'G4:3 F#4:3 F4:3 E4:9',
        'E4:3 D#4:3 D4:3 C4:9',
        'C3:3 B2:3 Bb2:3 A2:9',
        'k:3 k:3 k:3 t:9'], loop=None)


# 13 new record: a brass arpeggio up to a top C, a crash and a held chord
def jingle_record():
    return song(5, [SAW, LEAD50, BASS, DRUMS], [
        'G4 C5 E5 G5 C6:2 G5:2 E5 G5 C6:12',
        'E4 G4 C5 E5 G5:2 E5:2 C5 E5 G5:12',
        'C3:2 G2:2 C3:2 G2:2 E3:2 C3:12',
        'k . s . k . s . s s x:12'], loop=None)


def all_songs():
    """In SONG_* order: title, menu, bike, standings, bay, tallboy, regatta,
    off-leash, podium, parking, subway, then the result jingles (finish,
    fail, record)."""
    return [kc_incidental(), bobcaygeese(), gold_guns_gulls(), ahead_by_a_centimetre(),
            whelp_im_alive(), hay_officer(), brother_downwind(), million_collars(),
            podium_reprise(), park_the_pain_away(), the_wait(),
            jingle_finish(), jingle_fail(), jingle_record()]
