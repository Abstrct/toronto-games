# pt6 Gord (Leslieville, TTC since the Red Rockets, C64 California Games), round 8

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8:**
- overall 6 → 6 → 6 → – → 7 → 7.5 → 8 → 8
- vs California Games 5 → 5 → 5 → – → 6.5 → 7 → 7.5 → 7.5
- Bike 7 → 5 → 5 → – → 6 → 6.5 → 6.5 → 7.5; Bay 6 → 6 → 6 → – → 6 → 7.5 → 7 → 7.5; Off-Leash 5 → 6 → 6 → – → 7 → 7 → 7.5 → 7.5; Tallboy 4 → 5 → 5 → – → 7 → 6.5 → 7.5 → 7.5; Regatta 4 → 5 → 4 → – → 6 → 6 → 8 → 7
- Parking 6 → – → 5 → 7 → 7.5 → – (not played this round); Subway 5 → – → 7 → 7.5 → 7.5 → – (opening only)

## 1. Round-7 complaints
- **Bike is a survival test: better.** Riding blind still scores 279 (three wipeouts). But reacting to the new POTHOLE! HOP IT: B got me DELIVERED! SIGN HERE. for 2120 on my first real run, with two wipeouts. The opener is finally winnable.
- **Early rail-hop prompt: fixed (mostly).** HOP THE RAILS: B! now comes up about 20 frames ahead, so B at 13–19 frames after it is a TRACK HOP. At 22 frames it's a RAIL WOBBLE, though the manual says "half a second" (pt6r8-bike-11317005).
- **RAIL WOBBLE on lane changes: better.** I steered across the rails in the warm-up without a wobble.
- **Stale mark-3 order (999906496): fixed.** It now says MARK 3 ROUNDED! HOLD COURSE, then MARK 3! NOW TAP ▶ 5 TIMES. Same at mark 1.
- **Double-time MISS and the tip contradiction (902538): fixed.** Steps on the dots read GOOD, PERFECT or DEAD ON, followed by IN THE GROOVE! FULL STRIDE and POWER WALK X2!.
- **Lumped Regatta style (903401): better.** The card shows a LINE HONOURS 300 line. But it sits above COURSE as if it were a separate addend, while it's actually inside + STYLE 420.
- **"KEEP DOWN+RIGHT":** not re-tested (didn't play Parking).

## 2. Regressions and new issues
- [major ux] **pt6r8-sail-11657594:** on the coach's TACK NOW! TAP ◀ 5 TIMES I tapped at 10, 7.5, 6 and 3.3 taps a second, and every time I got the same heading and TAP FASTER FOR A CLEAN TACK. Tapping flat out and being told to tap faster is the worst line in the game right now. My first-timer Regatta: 2320 (R7: 2485).
- [major ux] **pt6r8-bike-11280396:** at 85% of Queen, POTHOLE! HOP IT: B replaces CAR IN BIKE LANE while the only thing ahead is a parked blue car. Then SPLAT! CAR IN BIKE LANE under SPADINA AHEAD!. The coach names the wrong hazard.
- [minor] The coach box flashes empty for a frame or two between lines (seen in Bay and Off-Leash).
- [note] Bay still lets you ignore lanes: 10–11 spills and I still made the 5:42.

## 3. Copy: 8/10
**Clear the first time:** "MARK 1 ROUNDED! HOLD COURSE", "ZIG-ZAG UP: I'LL CALL TACKS", "RUN DOWNWIND TO MARK 3!", "ALL 3! CROSS THE DOTTED LINE", "ANOTHER TRICK IN 2 S = X2", "NEXT BUMP SPILLS COFFEE: -40", "LAST SIP! 1 MORE SPILL: DECAF", "STUCK! TAP A TO SCRAMBLE", "THIRD WIPEOUT. NO DELIVERY / PAID FOR THE RIDE ONLY".

**Jokes that land:** "BUMPED A BANKER! SORRY!" (the SORRY is pure Toronto), "HE'S FRIENDLY!" as a dog charges you, "GREEN BIN! HOLD A AT RED", "GRABBED THE STICKY POLE!", "FACE-FIRST IN A BACKPACK!", "SO LONG, SEAGULL!", and THE RCYC BAR IS OPEN! again.

**Unclear or wrong:** "TAP FASTER FOR A CLEAN TACK" (after fast taps). "POTHOLE! HOP IT: B" with no pothole on screen. The Bay card's "RED !: ↑/↓ AS ARROW, OR A" reads like a cipher on first view.

**Rewrite:** Bay card line → **"RED !: ▲▼ TO THE ARROW'S LANE"**, then put "NO LANE? A = EXCUSE ME" on its own line.

## 4. Mastery
- **Bay** (played twice): big dots only gave 1079, double time gave 1455 (+35%), neither run changing lanes. It's still one thing to master.
- **Bike:** delivery is a cliff. One pothole hop decided 366 vs 2120. Style was 120 of the 2120, so tricks barely register next to RIDE 1500+20/S. CG's BMX paid for tricks; this pays for arriving.
- **Off-Leash** (curve bot as my hands): 4815 at 15 f vs 9875 at 0 f. Bold timing now clearly pulls away (R7: 3960 vs 3810).
- **Tallboy:** 3469 at 15 f vs 6492 at 0 f. Still the best skill curve.
- **Regatta:** the clean-tack bug caps the top end for anyone following the coach.

**Hidden tricks (from title demos, not reproduced by me):** Bike **TTC TRANSFER! +120** (the demo hops across the streetcar rail that runs along Queen, then it fires; my hop across that rail did nothing), Bay **SLALOM X2! +50**, Regatta **ROLL TACK! +250**. Tallboy shows "*CRACK* FRESH TALLBOY". WATCH THAT MOVE! also fires on documented moves (DODGE 'N' PAT, DEAD ON THE CHALK), so the banner doesn't single out the secret. I couldn't spot Off-Leash's or Parking's.

## 5. Report
**Who:** a Leslieville lifer, Leafs and Jays, rode the Red Rockets.

**Overall 8/10:** Bike is finally deliverable, and the coach is honest almost everywhere. Almost. vs CG: 7.5/10 as good.

**Per event:**
- Bike 7.5: delivered!
- Bay 7.5: groove copy good, lanes optional.
- Off-Leash 7.5: "HE'S FRIENDLY!"
- Tallboy 7.5: green bins.
- Regatta 7: great coach, broken tack verdict.

**Top 3 loved:** "BUMPED A BANKER! SORRY!"; MARK 3 ROUNDED! HOLD COURSE; my first ever DELIVERED! SIGN HERE.

**Top problems:**
1. TAP FASTER at every cadence [major, pt6r8-sail-11657594].
2. Wrong-hazard prompt [major, pt6r8-bike-11280396].
3. Bike style dwarfed by delivery [design].
4. Tight rail window [minor, pt6r8-bike-11317005].
5. Bay lanes optional [note].

**CG had:** tricks you could see yourself doing, named on screen and worth real points.

**More Toronto:** "SHORT-TURNED AT SHAW" as a Bike fail; a 504 King on the Bay crossing; "AGROUND AT HANLAN'S"; Off-Leash fail "NO DOGS IN THE WADING POOL".

**Wall quote:** "Signed for a package at Spadina with one heart left. First delivery in eight rounds. I nearly rang the bell."

## 6. As good as California Games yet?
Not quite. The biggest thing in the way is **trust in the coach**. When it says TAP FASTER after I tapped as fast as a human can, or says POTHOLE when it's a car, I stop believing it. In CG the screen never lied to you.
