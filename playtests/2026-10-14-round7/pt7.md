# pt7 Kenji (SNES pixel art / SPC700 audio), round 7

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7:**
- overall 6 → 7 → 7.5 → 8 → 8.5 → 9 → 9
- vs California Games 5 → 6 → 7 → 7.5 → 8 → 8.5 → 8.5
- Bike 6 → 7 → 8 → 8.5 → 8.5 → 9 → 8.5 · Bay 6 → 7 → 7 → 7 → 8 → 8.5 → 9 · Off-Leash 6 → 6 → 7 → 7.5 → 7.5 → 8 → 8 · Tallboy 7 → 7 → 8 → 8.5 → 8.5 → 8.5 → 8.5 · Regatta 4 → 6 → 7 → 7 → 7.5 → 7 → 7
- Parking 6 → 7 → 7.5 → 8 → 8.5 · Subway 5 → 7 → 8 → 8.5 → 8.5

## 1. My round-6 complaints
- **Regatta beach trap (pt7r6-sail): better.** Grounding is fixed: I hit the Harbourfront pier, tapped as told, got "PUSHED OFF! SAIL ON!". ADRIFT still ends races while I obey the coach (new major below).
- **DC offset (pt7r6-au-sail): fixed.** Every song's mean DC is within ±40 (was −2.8k/−4.6k). The ADRIFT alarm adds none. When the song stops, the output settles at −2, so no thump. One leftover: the alarm peaks at 30900 (−0.5 dBFS), ~7 dB over the music.
- **Song levels: slightly worse.** AC RMS: TTC −16.6, Bay −16.9, Parking −17.0, Bike −18.0, Off-Leash −18.1, Tallboy −18.3, Regatta −19.9 dBFS. That's a 3.3 dB spread, and Regatta is the quiet one again.
- **Bay judge words at x=0: fixed.** MISS/GOOD now float over the walker's head.
- **Walker overlaps tourists: unchanged.** MISS draws over the pedestrian's face.
- **Two-line panel with no leading: unchanged.** Now in Bike too (pt7r7-bike-314124).
- **Off-Leash walker over the gate arch: unchanged** (in pt7r7-park-200366).
- **Parking box advance: fixed.** The coach line now says "A: ON TO SPOT 2".
- **"SAFE: B WHEN ! SHOWS: 50": fixed.** It's now "SAFE: B ON ! = 100 A DOG".
- **Not retested:** the tackled-card rate (pt7r6-parkt), the empty Regatta panel flash, TIGHT ROUNDING order, the HIKE label.

## 2. Regressions and new issues
- **[major ux] pt7r7-sail-999928938.** I missed mark 2 by a hull width.
  - The coach said "◀ 5", which ran me downwind. Then "◀ 4" put me in irons (red diamonds, SPD empty).
  - It said "ZIG-ZAG: WAIT FOR TACK NOW!", went silent while **ADRIFT IN 5** started, and called "TACK NOW! TAP ◀ 5 TIMES" only at ADRIFT IN 3.
  - I obeyed at 12–15 f and the race ended ADRIFT about 40 px from the ring, with green diamonds on it: 460 points, 45 s left.
  - Also, a finished order ("◀ 5 TIMES") stays on screen for ~2 s after the taps.
- **[minor art] pt7r7-bike-9948.** The in-lane streetcar tracks are 1 px grey lines that look like lane dividers. The token trail leads you over them and you get "RAIL WOBBLE!" with no rail visible.
- **[minor art] pt7r7-park-200366.** Off-Leash callouts are a borderless 16 px strip laid across the dog lane, so the SET! strip covers the dog mid-lunge. The other six events use the rounded panel. (In R6 I wrongly said all seven had it.)
- **[minor art] pt7r7-bike-314124.** "TRACK HOP! +60 / NEW TRICK IN 2 S: X2": the glyph rows touch.
- **Unfiled:**
  - "HOP THE RAILS: B!" disappears the frame the rails scroll into view, so the warning leaves as the hazard arrives.
  - The ADRIFT card plays in dead silence. CG gave every result a sting.

## 3. Copy: 8/10
**Clear:**
- Parking's chain, "GAS ▲ → LET GO OF ▲: STOP ON THE LINE → HOLD DOWN+RIGHT → NOW! ROLL TO DOWN+LEFT → STRAIGHT! LET GO OF THE PAD", got me 941 and ONE-MOVE on my first try.
- "DEAD ON! B MID-AIR PAYS X3" teaches the sip-hop at the right moment.
- "PUSHED OFF! SAIL ON!"

**Jokes that land:**
- "STANDING STILL PAYS 0"
- "FACE-FIRST IN A BACKPACK!"
- "GRABBED THE STICKY POLE!"
- "PARKED. IT'LL DO."
- "GRAB A POLE, GET GERMS."

**Unclear:**
- "NEW TRICK IN 2 S: X2" reads as a countdown.
- "RIDE 1 PER 4 M" is spreadsheet talk.
- "DOWN+LEFT ON NOW!" on the Parking card means nothing until you've seen the NOW! cue.
- "GOLD DOT STOP TO STOP = X3"
- "ZIG-ZAG: WAIT FOR TACK NOW!" is a promise the coach broke.

**Rewrite:** "ANOTHER TRICK IN 2 S = X2". And in Regatta, the coach must call the tack before the ADRIFT clock starts, never after.

## 4. Mastery
- **Bay, played twice:**
  - First-timer (big dots only, ±3.5 f timing, lane-blind): MADE THE 5:42 with 1 s left, 8 spills, 776.
  - Locked to the 30-frame beat in DOUBLE TIME, still lane-blind: 1555, 2.0× the first-timer.
  - In R6 the same lane-blind DT walk got 4.2×. Four spills → DECAF now kills DOUBLE TIME, so you can't reach the top end without dodging. That gives two skills, rhythm and lanes, and that's correct.
- **Tallboy:** a hop 12 f early is a spill. DEAD ON pays x3 on a sip, so the top end is timing × BUZZ management.
- **Parking:** following the coach got me near the ceiling on spot 1 (941). There's little room above a coached first-timer.
- **Hidden tricks:** I didn't find one. I'm not going to invent one.

## 5. Report
1. Kenji, pixels and SPC.
2. **9/10**: the mix is clean at last and the cards add up. vs CG **8.5**.
3. Per event:
   - **Bike 8.5:** the hop shadow and the honest "THIRD WIPEOUT. NOT PAID!"; the rails are invisible.
   - **Bay 9:** the judge words are home, and lanes matter now.
   - **Off-Leash 8:** autumn palette; the strip callouts are off-model.
   - **Tallboy 8.5:** the Kensington storefronts and the spill animation.
   - **Regatta 7:** the dome skyline; ADRIFT still beats the coach.
   - **Parking 8.5:** best coach in the game.
   - **TTC 8.5:** tunnel to tile windows; the gold/white/red dot is only 3 px, too small to read.
4. Loved:
   - zero DC
   - the Parking coach
   - "DEAD ON! B MID-AIR PAYS X3"
5. Problems:
   - [major] pt7r7-sail-999928938
   - [minor] pt7r7-bike-9948
   - [minor] pt7r7-park-200366
   - [minor] pt7r7-bike-314124
   - [minor] Regatta 3 dB quieter than TTC
6. CG had results stings and wipes between screens. Here the cards still blink in silently after a fail.
7. Toronto ideas:
   - make the in-lane rails shine like real Queen St track
   - a Porter prop plane over the Regatta sky
   - the "PLEASE STAND CLEAR" chime on TTC
8. Quote: "The DC is gone. Now make the coach beat the clock."

## 6. As good as California Games?
Close (8.5), and the audio-visual side is basically there. The single biggest thing in the way is still **Regatta**: it's the only event where doing exactly what the coach says can end your race.
