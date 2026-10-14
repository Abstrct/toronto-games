# pt3 Priya (retro YouTuber, 200k subs, made a 40-minute California Games retrospective): Round 8

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8:**
- overall 6 → 7 → 7.5 → – → 7.5 → 8 → 8.5 → 8.5
- vs California Games 5 → 6.5 → 7 → – → 7 → 7.5 → 8 → 8.5
- Bike 6 → 6 → 7 → – → 7 → 7 → 7 → 7.5 · Bay 5 → 7 → 7 → – → 7.5 → 7.5 → 7.5 → 7 · Off-Leash 6 → 7 → 7 → – → 6.5 → 7 → 7 → 7 · Tallboy 6 → 6 → 7 → – → 7 → 7 → 7 → 7.5 · Regatta 3 → 6 → 6.5 → – → 6 → 7 → 8 → 8
- Parking (R3 → 8) 5 → – → 7 → 7.5 → 8 → 8 (demo only) · Subway 6 → – → 7 → 7 → 7 → 7

## 1. My round-7 complaints
- **NOT PAID! (pt3r7-bike-453817): fixed.** The card now reads "NO DELIVERY / PAID FOR THE RIDE ONLY".
- **"WAIT FOR TACK NOW!" (pt3r7-sail-434926): fixed.** It's now "ZIG-ZAG UP: I'LL CALL TACKS". The coach now speaks on the rounding frame ("MARK 1! NOW TAP ◀ 2 TIMES"), but I only saw that in the demo.
- **"RUN HURDLES+ROAD" (pt3r7-cops-439176): fixed.** It's now "RUN 50 A HURDLE 650"; 650+191−210=631, and the fine is a quarter.
- **Bike floor: better.** Riding straight, I lasted 47 s instead of 30 before the third wipeout. Still 279.
- **Tallboy floor: better.** Blind A taps got 631 (113 in R7). "STUCK! TAP A TO SCRAMBLE" is new.
- **Off-Leash ignoring the coach: unchanged.** Three tackles in 20 s and 0 points. "HEARTS GONE: DOGS FORFEIT" is clearer, though.
- **Tiny bike rider: unchanged.**
- **Audio:** Regatta is fixed (rms 4038, was 2031). Tallboy is unchanged and still the quietest (1886).

## 2. Regressions and new issues
- [minor ux] **pt3r8-bay-11843316.** The same 30-frame rhythm from six start offsets scored 1311 / 409 / 1040 / 1271 / 406 / 1040. One phase in three misses the train, MISS on every step, and nothing tells you to land ON the dot.
- [minor art] **pt3r8-blank2-11881946.** An empty popup box flashes at Off-Leash's white-! → red-! hand-off. I also saw it twice in the Bay demo. (pt3r8-blank-11864617 caught the wrong frame; ignore it.)
- [note ux] **pt3r8-demo2-11894810.** The attract demo's event card says "LET GO OF THE BUTTONS" to nobody.
- [note ux] **pt3r8-dog-11896698.** CLOSE SHAVE means three things: Bay +25, Off-Leash +400, Parking +200.
- No crashes or clipping. The only drops were 1–3 frames at scene starts.

## 3. Copy: 8.5/10
- **Clear and funny:**
  - "THE TRAIN DID ALL THE WORK"
  - "HE'S NEVER DONE THIS!" and "HE'S FRIENDLY!"
  - "CLOSE SHAVE! SHE DIDN'T BLINK"
  - "*CRACK* FRESH TALLBOY"
  - "WARM-UP OVER: HE'S COMING!"
  - "OLE! MATADOR!"
- **Terse:**
  - "BOLD: RED ! 200, LATE 400+" only makes sense after you've played.
  - "RED !: ▲/▼ AS ARROW, OR A" is three ideas in one line.
- **Unclear:**
  - The blank box.
  - Bay's "THE 5:42 LEFT WITHOUT YOU" gives no reason.
- **Rewrite:** after four MISSes in Bay, have the coach say "STEP AS THE BIG DOT HITS ◀".

## 4. Mastery
- **Bay, played twice:**
  - Plain stepping on a good phase: 1311.
  - Weaving blind: 1108 (12 spills).
  - The demo stacks SLALOM, BAY STREAK X4, PRESTO and CLOSE SHAVE.
  - So beat, lanes and slalom are three skills.
- **Tallboy:**
  - Blind hopping: 631.
  - Mashing sips: SLOSHED, 153.
  - The demo's LIQUID COURAGE pays +378 and +528 per hop, against +33 to +72 for a plain SIP 'N' HOP. A real top end.
- **Hidden tricks:**
  - **Found by playing:** Bike's **TTC TRANSFER +120**. Hop sideways as you reach the near streetcar rail. A hop 6–12 frames later is just TRACK HOP +60.
  - **Seen in the demos (WATCH THAT MOVE!) but not reproduced:**
    - Bay SLALOM.
    - Off-Leash MATADOR. I swept late B frame by frame and tried sidesteps; I only ever got CLOSE SHAVE or a tackle.
    - Tallboy LIQUID COURAGE.
    - Regatta ROLL TACK +250. Hiking through the tack didn't trigger it.
    - Parking SHE DIDN'T BLINK.
    - TTC LOOK MA, NO HANDS!

## 5. Report
**Overall 8.5/10.** Every R7 complaint is fixed or better, and the attract loop is now a trailer. **vs California Games: 8.5/10.**
- **Bike 7.5:** TTC TRANSFER is a great find; the rider is still too small for a thumbnail.
- **Bay 7:** the phase trap.
- **Off-Leash 7:** the jokes are perfect; ignoring the coach still scores 0.
- **Tallboy 7.5:** the floor is up; the intro is still quiet.
- **Regatta 8.**
- **Parking 8 (demo).**
- **TTC 7.**
- **Audio rms:** title 3467, Bay 4428, TTC 4792, Regatta 4038, Bike 3154, Off-Leash 3847 (side −20 dB, the narrowest), Tallboy 1886.

**Loved:**
1. The WATCH THAT MOVE! demos.
2. "THE TRAIN DID ALL THE WORK".
3. Finding TTC TRANSFER myself.

**Top problems:**
1. Bay phase trap [minor] (pt3r8-bay-11843316).
2. The blank popup box [minor] (pt3r8-blank2-11881946).
3. Off-Leash scores 0 for coach-ignorers [minor, carried over].
4. CLOSE SHAVE used three ways [note] (pt3r8-dog-11896698).
5. LET GO OF THE BUTTONS on the demo card [note] (pt3r8-demo2-11894810).

**What California Games did that this doesn't:** a big, readable Bike athlete, and tricks you can copy by feel after seeing them once.

**More Toronto:** a streetcar bell on TTC TRANSFER.

**Quote:** "The demos finally show off. Now let me pull off a MATADOR without a frame counter."

## 6. Is it as good as California Games yet?
On presentation, yes. The biggest thing in the way: MATADOR and ROLL TACK didn't come off for me when I copied the demo. California Games' tricks looked hard but came by feel.
