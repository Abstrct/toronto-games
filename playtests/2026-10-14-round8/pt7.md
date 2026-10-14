# pt7 Kenji (SNES pixel art / SPC700 audio), round 8

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8:**
- overall 6 → 7 → 7.5 → 8 → 8.5 → 9 → 9 → 9
- vs California Games 5 → 6 → 7 → 7.5 → 8 → 8.5 → 8.5 → 9
- Bike 6 → 7 → 8 → 8.5 → 8.5 → 9 → 8.5 → 9 · Bay 6 → 7 → 7 → 7 → 8 → 8.5 → 9 → 9 · Off-Leash 6 → 6 → 7 → 7.5 → 7.5 → 8 → 8 → 8.5 · Tallboy 7 → 7 → 8 → 8.5 → 8.5 → 8.5 → 8.5 → 8.5 · Regatta 4 → 6 → 7 → 7 → 7.5 → 7 → 7 → 8
- Parking 6 → 7 → 7.5 → 8 → 8.5 → 8.5 · Subway 5 → 7 → 8 → 8.5 → 8.5 → 9

## 1. My round-7 complaints
- **Coach vs. ADRIFT clock (pt7r7-sail-999928938): fixed.** As a first-timer I obeyed every order at about 12 f and finished with 49 s left (1935, TIGHT ROUNDING +200). The ADRIFT countdown never showed. Long turns now come in halves ("TACK NOW! TAP ◀ ONCE" → "GOOD! TAP ◀ 5 MORE TIMES"), and a finished order no longer hangs around.
- **Invisible in-lane rails (pt7r7-bike-9948): fixed.** The track bed is now pale concrete with two steel rails, and the 501 runs on it.
- **Off-Leash strip callouts (pt7r7-park-200366): fixed.** Callouts are rounded, bordered panels up top, clear of the dogs. **Gate arch: better.** The arch now draws over the walker's legs as he passes through.
- **Two-line panel with no leading (pt7r7-bike-314124): fixed.** There's 16 px between the rows, and it uses my rewrite: "ANOTHER TRICK IN 2 S = X2".
- **Regatta 3 dB quiet: fixed.** AC RMS: Regatta −16.2, TTC −16.6, Bay −16.9, Parking −17.0, Bike −17.6, Off-Leash −17.8, Tallboy −18.6 dBFS, a 2.4 dB spread. DC is within ±33 on every song.
- **Silent ADRIFT card: fixed.** The fail sting is about 1.8 s long and decays to true silence, with no thump.
- **TTC 3 px dot: fixed.** It's now about a 5 px gold dot and reads instantly.
- **HOP THE RAILS leaving early: better.** In the demo the panel is up while the rails are on screen.
- **Not retested:** MISS drawn over a tourist's face.

## 2. Regressions and new issues
- **[minor art] pt7r8-sail-11736809.** Both Regatta result cards sit on a ghost of the HUD frame. The text is wiped but the white border and top-right corner poke out above the card, like two frames printed off-register.
- **[minor ux] pt7r8-sail-11753048.** On my first run, after mark 2 the tip "PASS CLOSER = TIGHT ROUNDING" held the coach line for about 2 s. Only then came "MARK 2! NOW TAP ◀ 3 TIMES", and all that time I was sailing away from mark 3. (The repro's screenshot landed after the order had appeared; my run-1 shots a14–a16 show the delay.)
- **Unfiled:**
  - The Regatta song peaks at −0.5 dBFS (30936) when idle.
  - An empty "WATCH THAT MOVE!" panel flashes at the end of the Off-Leash demo.
  - "TAP FASTER FOR A CLEAN TACK" fired at exactly 6 taps/s, which is the rate the manual quotes. At 7.5/s I got CLEAN TACK +100.

## 3. Copy: 8.5/10
- **Clear:**
  - "ZIG-ZAG UP: I'LL CALL TACKS" (and it did)
  - "SET! YOU STEP AS HE LUNGES"
  - "STUCK! TAP A TO SCRAMBLE"
  - "CRATES! TAP A AT THE CHALK"
  - The DEAD ON / ON THE CHALK / BIT LATE ladder: grades 8 f apart, honest feedback.
- **Jokes that land:**
  - "BIT LATE, BUD!"
  - "HE'S NEVER DONE THIS!"
  - "CLOSE SHAVE! SHE DIDN'T BLINK"
  - "THE RCYC BAR IS OPEN!"
- **Unclear:**
  - "TACK NOW! TAP ◀ ONCE" reads as the whole tack, so I sat there for 2 s.
  - "MISS THE BUOY! TAP ◀ 2 TIMES" in red, a second after a clean mark-1 rounding, reads as a scolding.
  - Off-Leash card: "BOLD: RED ! 200, LATE 400+" is shorthand.
  - Bay card: "RED !: ▲/▼ AS ARROW, OR A" is cryptic.
- **Rewrite:** "TACK! TAP ◀ 1 OF 6 NOW".

## 4. Mastery
- **Bay, played twice:**
  - First-timer (big dots at ±4 f, lane-blind): 1119, MADE THE 5:42, 10 spills, DECAF.
  - Locked double time at ±2 f, still lane-blind: 1511 (1.35×).
  - Blind weaving added nothing (1159–1488).
  - The bots that read lanes score about 3.9–4.4k. The top end is reading the lanes, plus the beat and SLALOM, so there's more than one thing to master.
- **Tallboy:** take-off is graded (+39/+31/+21), and LIQUID COURAGE pays a base of 42 instead of 11 at high BUZZ. That's a real risk axis.
- **Regatta:** fast taps pay CLEAN TACK. The bots' expert/human ratio is about 2×. I couldn't land ROLL TACK myself.
- **Hidden tricks:** I found all seven from the title demos. I reproduced none of them in play.
  - Bike TTC TRANSFER +120: hop clean across the in-lane track.
  - Bay SLALOM X2 +50.
  - Off-Leash OLE! MATADOR +550 (late sidestep).
  - Tallboy LIQUID COURAGE.
  - Regatta ROLL TACK +250 (tack while hiking in a gust).
  - Parking "SHE DIDN'T BLINK" +200 (back in right behind the cyclist).
  - TTC "LOOK MA, NO HANDS!" +100 at STAND CLEAR.

## 5. Report
1. Kenji, pixels and SPC.
2. **9/10**: every audio-visual complaint I had is closed, and Regatta no longer betrays a newcomer. vs CG **9**.
3. Per event:
   - **Bike 9:** the rails finally read as steel.
   - **Bay 9:** the beat track, slalom.
   - **Off-Leash 8.5:** the panels are on-model now.
   - **Tallboy 8.5:** the grade ladder; the HUD's PTS/CHAIN rows are cramped.
   - **Regatta 8:** finishable, with a sting; the tip-before-order hiccup.
   - **Parking 8.5:** CLOSE SHAVE is a great trick.
   - **TTC 9:** the dot reads.
4. Loved:
   - the fail sting
   - the 2.4 dB song spread
   - "ANOTHER TRICK IN 2 S = X2"
5. Problems:
   - [minor] pt7r8-sail-11736809
   - [minor] pt7r8-sail-11753048
   - [minor] Regatta −0.5 dBFS peak
   - [minor] Off-Leash empty demo panel
   - [minor] "TACK NOW! TAP ◀ ONCE" copy
6. CG taught its tricks by letting you stumble into them. Here they're only visible in the demos; I couldn't reproduce one in ~80 commands.
7. Toronto ideas:
   - a Porter prop plane over the harbour
   - TTC "PLEASE STAND CLEAR" chime
   - a Bellwoods white squirrel
8. Quote: "The coach beats the clock now. Make the tricks findable without the demo."

## 6. As good as California Games?
Yes, about 9 against CG's bar. The biggest thing left is **discoverability of mastery**. Even after watching the demos, the hidden tricks are hard to land, and CG's tricks felt obvious once seen.
