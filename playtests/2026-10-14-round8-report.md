# Toronto Games: playtest round 8, 2026-10-14

The same ten testers played the build after sprint 7. The build under test was frozen as `build/pt/panel8` (tag `panel8`).

What sprint 7 changed:
- **Cues are timed for a 20–25 f human:** Bike's rails and potholes, Bay's red ! plus a lane arrow, Parking's coach, and TTC's hold/tap.
- **Regatta's coach:** no stale orders, turns come in halves, and ADRIFT waits while you're on course. A latent CPU-width crash is fixed.
- **Risk pays:** Off-Leash CLOSE SHAVE is now double NICE, and Bay's DOUBLE TIME is free to try.
- **Copy and cards:** Bike's NO DELIVERY lines, Tallboy's scramble cue, the GOLDS BREAK TIES line, and "compete in some" starting empty.
- **Hidden tricks:** each event's title demo now shows its trick, with a WATCH THAT MOVE! banner.

Testers filed 30 findings: 2 major, 23 minor and 5 notes. That's the fewest yet (72 → 56 → 62 → 40 → 35 → 30), and there were no crashes or soft-locks.
List them with `build/pt/panel8/pt findings --file build/pt/findings_round8.jsonl`.
Per-tester reports are in `playtests/2026-10-14-round8/`.

## Scoreboard (round 7 → 8)

| Tester | Overall | vs CG | Bike | Bay | Off-Leash | Tallboy | Regatta | Parking | Subway |
|---|---|---|---|---|---|---|---|---|---|
| Dana, beginner | 7 → **8** | 7 → **8** | 4 → **7** | 6 → 6 | 8 → 8 | 8 → 8 | 8 → 8 | 5 → **8** | 4 → **8** |
| Marcus, party | 8.5 → 8.5 | 8 → 8.5 | 6.5 → 7 | 7 → 7 | 8 → 8 | 7 → 7 | 7 → 7.5 | 8 → 8 | 7.5 → 7.5 |
| Priya, YouTuber | 8.5 → 8.5 | 8 → 8.5 | 7 → 7.5 | 7.5 → 7 | 7 → 7 | 7 → 7.5 | 8 → 8 | 8 → 8 | 7 → 7 |
| Rob, TAS | 8.5 → 8.5 | 8 → 8.5 | 8 → 8.5 | 8 → 8 | 8 → **9** | 8 → 8.5 | 8 → 8 | 7 → 7 | 8 → 8 |
| Lena, designer | 8 → **9** | 8 → 8 | 8 → 8 | 7 → 7 | 8 → **9** | 8 → **9** | 7 → 8 | 8 → 8 | 7 → 7 |
| Gord, Torontonian | 8 → 8 | 7.5 → 7.5 | 6.5 → 7.5 | 7 → 7.5 | 7.5 → 7.5 | 7.5 → 7.5 | 8 → 7 | – | – |
| Kenji, art/audio | 9 → 9 | 8.5 → **9** | 8.5 → 9 | 9 → 9 | 8 → 8.5 | 8.5 → 8.5 | 7 → 8 | 8.5 → 8.5 | 8.5 → 9 |
| Tasha, completionist | 8.5 → 8.5 | 8 → 8.5 | 6.5 | 7 → 7.5 | 6.5 → 6.5 | 6 | 6.5 → 7.5 | 8 | 6.5 |
| Hal, tournament | 8 → 8.5 | 8 → 8.5 | 8 → 8 | 8 → 8 | 7.5 → 7.5 | 7.5 → 7.5 | 6.5 → 7.5 | 8 → 8 | 7.5 → 8.5 |
| Mo, QA | 8 → 8.3 | 7.5 → 7.8 | 7.5 → 8 | 7 → 7.5 | 7.5 → 7.5 | 7 → 7 | 7 → 7.5 | 6.5 → 6.5 | 7 → 7 |
| **Average** | **8.2 → 8.5** | **7.9 → 8.3** | 7.1 → **7.7** | 7.4 → 7.5 | 7.6 → **7.9** | 7.5 → 7.7 | 7.3 → **7.7** | 7.5 → **7.8** | 7.1 → **7.6** |

**Overall:**

| Round | Overall | vs California Games |
|---|---|---|
| 1 | 5.6 | 5.0 |
| 2 | 6.7 | 6.2 |
| 3 | 7.1 | 6.6 |
| 4 | 7.9* | 7.4* |
| 5 | 7.7 | 7.2 |
| 6 | 8.1 | 7.5 |
| 7 | 8.2 | 7.9 |
| **8** | **8.5** | **8.3** |

*Four testers in round 4.

- **Every event rose,** and they now sit at 7.5–7.9. Bike rose most (+0.6), on Dana's 4 → 7.
- **Every tester rates it 8 or higher overall.** Kenji gives 9 vs California Games. Lena gives 9 overall, with Off-Leash and Tallboy both at 9.
- **Dana, the beginner, recovered from 7 to 8** and medalled in six of seven events: *"I did what the box said, and for the first time the box was right."*

## Is it as good as California Games yet?

**Yes, or "close enough to host", for most of the panel.**
- Dana: *"Yes, for a first-timer: 8 vs 8."*
- Hal: *"For running a bracket, yes."*
- Kenji: *"Yes, about 9 against California Games' bar."*
- Tasha: *"at par or better"* on presentation and fairness.
- Marcus: *"Close enough that I'd host it."*
- Rob, for Off-Leash and Tallboy: *"Round 8 pays me for showing off, and only when I'm good."*

What remains:
1. **Tricks have no tells** (Lena, Priya, Kenji, Marcus).
   - Every tester found all seven tricks through the demos.
   - Only Rob, Lena and Marcus reproduced some by hand.
   - The windows are tight and have no on-screen or audio cue: one trick is 1–2 frames on later dogs, another is a 12 f window timed off your own taps.
   - Lena: *"Make the hidden trick visible a frame before you need it, and it's California Games."*
   - The WATCH THAT MOVE! banner also lingers over the next documented callout, which blurs which move was the secret (Gord, Tasha, Hal).
2. **The coach must never be wrong** (Gord; both majors).
   - Regatta's "TAP FASTER FOR A CLEAN TACK" fires even at 10 taps a second (Gord, Kenji, Tasha). Lena and Dana got CLEAN TACK at 6–10/s, so the check is inconsistent.
   - Bike names the wrong hazard: POTHOLE when it's a parked car (Gord), and CAR IN BIKE LANE when you're nowhere near it (Dana).
   - Gord: *"In California Games the screen never lied to you."*
3. **The Regatta card must itemise style** (Tasha, Hal, Mo, Marcus, Lena, Dana, Gord).
   - Its one "biggest source" line reads as an extra addend (LINE HONOURS 300 above COURSE) or as a count (CLEAN TACKS 100).
   - Every tester asked for the full breakdown. Marcus's version: "ROLL TACKS 3 = 750 / TIGHT 1 = 500 / LINE 300 / = STYLE 1650".
4. **Parking's top end is one line** (Rob, Hal). The human bot gets about 85% of the expert, so a score-attacker has nothing to chase.

## What got fixed (round-7 complaints)

**All four round-7 cue majors are fixed:**
- **Bike:** the rails prompt now comes about 30 f ahead, and Dana and Gord both delivered for the first time.
- **Parking:** a coach-obeyer at 22 f parked all three spots.
- **TTC:** holding is safe. Dana's script went from PATIENT ZERO at 160 to 0 germs and 3217.
- **Bay:** the arrow beats ignoring it. Dana says it's still marginal.

**Both Regatta stale-coach majors are fixed.**
- Hal finished slow and late for 2315 (459 in R7); Kenji and Dana finished with 0 ADRIFT.
- "GOOD! HOLD YOUR COURSE" and "ZIG-ZAG UP: I'LL CALL TACKS" landed well.

**Risk now pays:**
- Off-Leash: CLOSE SHAVE beats NICE for good hands. Lena: *"the ladder, done right"*. Rob: *"the best risk ladder in the game"*.
- Tallboy: BUZZ is a resource (Lena 9).

**Copy and cards:**
- Bike's NO DELIVERY lines are in, and its STYLE cap is gone (Rob: 7180).
- Tallboy's scramble cue and its "50 A HURDLE" sum are in.
- GOLDS BREAK TIES decided Marcus vs Jen.
- "Compete in some" starts empty.
- SO LONG lines are kept.

**Presentation:**
- **Audio:** song spread is 2.4 dB and DC is within ±33 (Kenji). The fail sting decays to silence, and Regatta's opening is now loud enough.
- **Visuals:** the TTC dot reads, and Bike's in-lane rails read as steel.

## Problems, ranked

**Major (2):**
- **pt6r8-sail-11657594:** Regatta's TAP FASTER verdict is wrong at human tap rates.
- **pt6r8-bike-11280396:** Bike's coach names the wrong hazard.

**Minor, grouped:**
- **Regatta:**
  - The style line on the card (7 testers).
  - Turn and coach flow:
    - The coach flip-flops if you hesitate ~1.5 s, and "MARK n! NOW…" shows 300 f late (Mo, Hal).
    - The second half of a long turn can leave a slow reader head-to-wind (Hal).
    - "MISS THE BUOY!" fires in red after clean roundings, and on the line that earned +500 (Kenji, Tasha).
    - "PASS CLOSER" holds the coach line for ~2 s after a rounding (Kenji).
    - "TACK NOW! TAP ◀ ONCE" reads as the whole tack (Kenji).
  - The HUD frame ghosts behind the result card (Kenji).
  - The song peaks at −0.5 dBFS.
- **Bay:**
  - The red ! at ~35 f is still marginal for a 22 f human, so following the arrow still ends in DECAF (Dana).
  - Starting phase decides 1311 vs 409 for the same rhythm, and nothing says to land on the dot (Priya).
  - The beginner margin is 1 s (Lena).
  - DOUBLE TIME doesn't beat a steady walk on the couch (Marcus).
  - The SPILLS count row drops on board cards (Mo).
  - The card's "RED !: ▲/▼ AS ARROW, OR A" is cryptic (6 testers).
- **Off-Leash:**
  - A sloppy turn swings between 0 and 5000: one late B and you're tackled out (Hal). He suggests paying the walk on a slope.
  - Empty popup boxes flash at the white→red hand-off and at the end of the demo (Priya, Kenji).
  - "HE'S FRIENDLY!" doesn't say "walk up and pat".
- **Bike:**
  - The second fail line drops when FORFEIT rows show (Marcus).
  - Seed luck: experts score 7270–10530 (Rob).
  - Style is small next to the delivery (Gord).
  - The rail window is shorter than the manual's "half a second" (Gord).
  - The rider sprite is small (Priya).
- **Parking:**
  - The HUD shows −545 over "SCORES NEVER GO BELOW 0" (Marcus).
  - The coach says "BACK IN" before "GET READY" (Lena).
  - The flat top (Rob, Hal).
- **Menus:**
  - START on a blank name, then B, leaves a hidden "PLAYER 1", so typing gives "DAVEER 1" (Marcus).
  - The demo card says "LET GO OF THE BUTTONS" (Priya).
  - The README promises WE THE NORTH! on every record (Mo).
  - An 8-player all-quit Bike gave gold for 1 point.
- **Copy:**
  - "CLOSE SHAVE" means three things across events (Priya).
  - Tallboy's "HOLD B: SIP, COP CAN'T SEE" reads as "B hides you" (Rob, Tasha).
  - TTC's "LEGS LEANED 6" has no denominator (Lena).
  - Tallboy's music is still the quietest (Priya).

## Copy

Clarity averages **8.4/10** (8–8.5).

**The panel's favourites:**
- Regatta coach: "ZIG-ZAG UP: I'LL CALL TACKS", "GOOD! HOLD YOUR COURSE", "MARK 3 ROUNDED! HOLD COURSE".
- Off-Leash risk ladder: "SAFE: B ON ! = 100 PER DOG / BOLD: RED ! 200, LATE 400+".
- Prompts: "STUCK! TAP A TO SCRAMBLE", "POTHOLE! HOP IT: B", "501 BEHIND! STEER ◀".
- "DELIVERED! SIGN HERE."
- "THE TRAIN DID ALL THE WORK".
- "SO LONG, MARCUS!" (Marcus got bumped off the board by Kev, by name).

**What's left:** two cryptic card lines (Bay's red-! line, Tallboy's sip line) and the Regatta card's style row.

## Mastery

Skill pulls clearly away everywhere except Parking.

**Hal, human bot vs best bot:**

| Event | Spread |
|---|---|
| Bike | 2.5× |
| Bay | 2.1× |
| Off-Leash | 3.2× |
| Tallboy | 3.1× |
| Regatta | 1.9× |
| TTC | 2.2× |
| Parking | 1.2× |

**Testers' two-play runs:**
- Tallboy: dry 2103–2160 vs sipping 3750–5124 vs riding the buzz 5707 (Lena).
- Off-Leash: 3535 vs 5575, and higher with the hidden trick.
- Regatta: coach-follower 2505 vs stylist 3640 (Marcus).
- Bay: 1207 vs 1548 vs a lane-reader's 3901 (Mo).

**More than one thing to master:** every event except Parking. Most testers named two to four verbs per event.

## Next sprint

1. **The coach is never wrong.**
   - Regatta's clean-tack check matches the advice, and is documented.
   - Bike names the hazard that's actually ahead, and only when you're in its path.
   - Regatta's MISS THE BUOY only when the line truly hits the buoy.
   - No coach flip-flop for ~2 s of hesitation.
   - A long turn's halves never leave you head-to-wind.
2. **Tricks get tells.** Give each hidden trick a readable cue a moment before its window (a sprite pose, a flash or a sound), and a window a practised human can hit:
   - Off-Leash: at least 6 f on every dog.
   - Regatta: a cue for the let-go.
   - Shorten the WATCH THAT MOVE! banner so it doesn't land on the next callout.
3. **Cards itemise style:**
   - Regatta: rows per source, summing to STYLE.
   - Bay: the same.
   - Bike: keep the second fail line beside the FORFEIT rows.
   - Parking: never show a negative score.
4. **Bay first-timer margin:**
   - The red ! at ≥ 45 f.
   - A "STEP ON THE DOT" hint after repeated MISS.
   - A few seconds of slack.
5. **Parking's top end:** a second skill axis, so the expert beats the human bot by ~1.6×.
6. **Off-Leash:** a sloppy turn doesn't fall to 0. Pay the walk on a slope.
7. **Menus and copy:**
   - The blank-name bug.
   - The demo card's LET GO line.
   - Distinct names for the three CLOSE SHAVEs.
   - The Bay and Tallboy card lines.
   - LEGS LEANED as "6 OF 6".
   - The README's WE THE NORTH line.
   - Tallboy's music level.
