# Toronto Games: playtest round 9, 2026-10-14

The same ten testers played the build after sprint 8. What sprint 8 changed:
- **The coach is never wrong.** Regatta's tack check now times the bow through the wind, and Bike's prompts were audited: 0 wrong out of 605.
- **Every hidden trick has a tell** and a window of about 8 frames.
- **The result card itemises style** (Regatta and Bay), and stats can read "N OF M".
- **Fairness and depth:**
  - Bay: an earlier red !, a brush instead of a spill, and the conductor holds the doors.
  - Off-Leash: half the dogs are kept on a fail.
  - Parking: a NONSTOP skill axis.
  - Tallboy: scrambles are paid.
- **Menus:**
  - The sign-up "DAVEER" bug is fixed.
  - Demos no longer show "LET GO" lines.
  - The demo banner is shorter.
  - The tie line now says ties are never broken by score.
- **Audio:** Tallboy's intro and Regatta's peak were fixed.

The build under test was frozen as `build/pt/panel9` (tag `panel9`). Testers filed 38 findings: 3 major, 27 minor and 8 notes.
List them with `build/pt/panel9/pt findings --file build/pt/findings_round9.jsonl`. Per-tester reports are in
`playtests/2026-10-14-round9/`.

## Scoreboard (round 8 → 9)

| Tester | Overall | vs CG | Bike | Bay | Off-Leash | Tallboy | Regatta | Parking | Subway |
|---|---|---|---|---|---|---|---|---|---|
| Dana, beginner | 8 → 8 | 8 → 8 | 7 → **8** | 6 → **7** | 8 → 7 | 8 → 8 | 8 → 8 | 8 → 8 | 8 → 8 |
| Marcus, party | 8.5 → 8.5 | 8.5 → 8.5 | 7 → 7.5 | 7 → 6.5 | 8 → 7.5 | 7 → 7 | 7.5 → 8 | 8 → 8.5 | 7.5 → 7 |
| Priya, YouTuber | 8.5 → 8.5 | 8.5 → 8.5 | 7.5 | 7 → 7.5 | 7 | 7.5 → 8 | 8 | 8 | 7 |
| Rob, TAS | 8.5 → 8.5 | 8.5 → 8.5 | 8.5 | 8 → 7.5 | 9 | 8.5 → **9** | 8 | 7 → 8 | 8 → 8.5 |
| Lena, designer | 9 → 9 | 8 → 8 | 8 | 7 | 9 → **10** | 9 | 8 | 8 | 7 |
| Gord, Torontonian | 8 → **8.5** | 7.5 → **8** | 7.5 → 8 | 7.5 | 7.5 → **8.5** | 7.5 | 7 → 8 | – → 8 | – → 7.5 |
| Kenji, art/audio | 9 → 9 | 9 → 9 | 9 | 9 | 8.5 | 8.5 | 8 → 8.5 | 8.5 | 9 |
| Tasha, completionist | 8.5 → **8** | 8.5 → **8** | 6.5 | 7.5 | 6.5 | 6 | 7.5 → **6.5** | 8 | 6.5 |
| Hal, tournament | 8.5 → 8.5 | 8.5 → 8.5 | 8 → 7.5 | 8 | 7.5 → 7 | 7.5 | 7.5 → 8 | 8 → 8.5 | 8.5 |
| Mo, QA | 8.3 → 8.2 | 7.8 → 7.8 | 8 | 7.5 | 7.5 → 8 | 7 | 7.5 | 6.5 → 7 | 7 → 6.5 |
| **Average** | **8.5 → 8.5** | **8.3 → 8.3** | 7.7 → **7.9** | 7.5 → 7.5 | 7.9 → 7.9 | 7.7 → **7.8** | 7.7 → **7.9** | 7.8 → **8.1** | 7.6 → 7.6 |

History:

| Round | Overall | vs California Games |
|---|---|---|
| 1 | 5.6 | 5.0 |
| 2 | 6.7 | 6.2 |
| 3 | 7.1 | 6.6 |
| 4 | 7.9* | 7.4* |
| 5 | 7.7 | 7.2 |
| 6 | 8.1 | 7.5 |
| 7 | 8.2 | 7.9 |
| 8 | 8.5 | 8.3 |
| **9** | **8.5** | **8.3** |

*Round 4 had only four testers.

**The plateau:**
- The overall average held at its high (8.5 / 8.3). Every event is now 7.5–8.1, and Parking passes 8.
- Lena rates Off-Leash **10**: "as good as anything Epyx made".
- Dana medalled in **all seven events** for the first time: *"Seven medals, zero tricks."*
- Tasha dropped half a point on a Regatta coach regression.

## Is it as good as California Games yet?

Most of the panel says yes, or yes on most events:
- Hal: *"bracket-ready on six events."*
- Marcus: *"As a party machine, yes."*
- Kenji: yes, 9/10 against California Games' bar.
- Rob and Lena: yes for Off-Leash and Tallboy.
- Dana: *"For a first-timer, yes."*

The things in the way:

1. **The hidden tricks aren't learnable from the screen** (all ten testers).
   - Hand landings varied widely:
     - Lena landed 5 of 7.
     - Rob landed 4.
     - Gord landed 2.
     - Priya and Marcus each landed Bike's.
     - Kenji, Tasha, Mo, Hal and Dana landed none.
   - Kenji named the design fix: *"Make the tell a warning that lasts 15 frames or more before the window opens, not the window itself."* Today's tells mostly *are* the window:
     - Off-Leash's flash comes 6–14 frames before the window, so a 15 f reaction to it lands late (Rob).
     - Bike's rails flash for 2–4 frames.
     - Regatta has no tell anyone could read; only Lena reverse-engineered a recipe.
   - Tallboy's gold BUZZ zone doesn't show where "brave" ends and SLOSHED starts.
   - Parking's bell wasn't seen on spot 2.
2. **The coach (or card) is wrong again in two places.** These are two of the three majors.
   - Regatta's coach can still steer a late tapper in circles at mark 2. It re-plans orders without input and praises taps you never made ("KEEP ON! TAP ▶ 3 MORE"), and the ADRIFT countdown runs during "GOOD! TAP ONCE MORE" (Tasha major, Mo).
   - TTC's card says "TAP TO STAY GOLD". Tapping as told ends PATIENT ZERO, while holding scored 3642 (Lena major).
3. **Off-Leash's tackle floor** (Hal major).
   - Three tackles cost 450, which can still wipe a competent walk to 0. The sloppy bot ranges 0–7200.
   - The fail card's "HALF THE DOGS" has no dogs row (Priya, Hal).
   - The record (10000) leaves a flawless safe walk at bronze (Dana).
4. **Bay is pulled four ways:**
   - Lanes are optional (Gord).
   - Blind EXCUSE ME pays (Mo).
   - The better player loses: Kev's 11 f ace scores less than a 15 f walker, and DOUBLE TIME at 15 f misses the train (Marcus).
   - The record of 3300 is 93% of the best bot (Rob).
5. **Style sub-rows are cramped** (Priya, Kenji, Gord, Mo, Marcus, Lena, Dana). They're half-row spaced and touch "+ STYLE", so Marcus calls them *"unreadable from the couch."* Bike, Tallboy, Off-Leash and TTC style still isn't itemised, though the README now promises it.

## What got fixed (round-8 complaints)

- **Both round-8 majors.**
  - Regatta's TAP FASTER now matches six taps/s (Gord, Kenji).
  - Bike names only the hazard that's really there (Gord: every prompt had its hazard).
  - Gord: *"the coach finally doesn't lie."*
- **Regatta:**
  - The card itemises style and adds up (Tasha, Marcus, Dana, Lena, Hal).
  - No ghost HUD behind the card.
  - MISS THE BUOY appears only on a real line.
  - Orders hold while you hesitate (Hal, Mo).
- **Bay:**
  - The phase trap is fixed: all six offsets now make the train (Priya).
  - The card reads in plain words (Dana, Gord, Mo).
  - Following the arrow beats ignoring it (Dana: 1582 with 1 spill).
- **Parking:**
  - The flat top is opened (Rob: expert 5343–7439; Hal: 3104 → 6477 → 7249).
  - OWED replaces a negative HUD.
- **Tallboy:**
  - Graded take-offs (Rob: *"pays by the frame instead of punishing by the frame"*).
  - The sip line reads "SIPS PAY UNSEEN".
  - Its music is louder (Priya: rms 1886 → 3624).
- **Menus:**
  - The DAVEER bug is fixed.
  - Demos have no LET GO line.
  - No-skill players don't medal (Marcus: Dave went home with nothing).
  - "N MORE FOR SILVER" on the cards is loved (Tasha).
- **Audio:** songs sit at −16.9 to −18.5 dBFS with DC within ±42 and no clipping (Kenji, Priya).

## Problems, ranked

**Major (3):**
- **pt8r9-sail2-21402136:** Regatta's coach circles a late tapper at mark 2.
- **pt5r9-subt-22267988:** TTC's "TAP TO STAY GOLD" card copy.
- **pt9r9-parkc-22272311:** Off-Leash's third tackle zeroes the run.

**Minor, grouped:**
- **Regatta:**
  - Orders re-plan without input and say "KEEP ON!" for taps never made (pt10r9-sail-21254992).
  - "GOOD! TAP ▶ 3 MORE" ran Mo aground.
  - The give-up card silently drops earned style (Tasha).
  - "HANDS OFF THE HELM PAYS 0" shows after one tap (Kenji).
  - "MARK 1 ROUNDED! HOLD COURSE" is then followed by TAP orders (Dana).
  - The curve is bumpy: 18 and 24 f out-score 15 f (Hal).
- **Off-Leash:**
  - "B MID-LEAP 400+" is wrong: the shave is the *last* 8 f of the leap (Lena).
  - The DOGS bonus looks capped at 2000 for 8 and 9 dodges (Marcus).
  - The TACKLES row disappears with a board line (Marcus).
  - The card "reads like a betting slip" (Gord).
- **Bay:** the gave-up card says "THE 5:42 LEFT WITHOUT YOU" at 5:41:20 (Mo), plus the four-way balance above.
- **Bike:**
  - A rear-end crash 5 s into the warm-up with no coach line (Dana).
  - "STEER HARD OVER RAILS" when obeying "STEER ◀" (Gord, Hal).
  - The ⚠ before "501 BEHIND!" reads as a hazard ahead (Priya).
  - Bike's trick is now so forgiving it doesn't separate players (Kenji).
  - "+ TOKENS+STYLE" sits under separate TOKENS and STYLE rows (Marcus, Dana).
  - Sprites draw over the card border (Kenji).
- **Tallboy:**
  - "GOLD 22" is unexplained (Rob).
  - Style isn't itemised.
- **TTC:**
  - "THE TRAIN DID ALL THE WORK" shows on a gave-up card (Mo).
  - "LEGS LEANED 5 OF 5" vs "OF 6" (Marcus).
  - A blind wiggle earns style (Mo).
- **Parking:**
  - "SPOTS PARKED 0" over "FINISHED SPOTS STILL COUNT" (Mo).
  - "LET GO OF ▲" is replaced by *DING DING* in ~24 f (Tasha).
  - Card order: "A TO PARK" comes before BACK IN (Rob).
  - "DOWN+RIGHT" is spelled out, against the arrow glyphs used elsewhere (Priya, Kenji).
- **Records board:** the same medal icons mean rank and threshold on one page (Tasha).
- **Copy:** the formulas on the result cards ("RIDE 1500+20/S") read as maths (Dana, Priya).

## Copy

Clarity averages **8.4/10**.

The best-loved lines:
- "ZIG-ZAG UP: I'LL CALL TACKS"
- "RED ! = SOMEONE IN THE WAY"
- "N MORE FOR SILVER"
- "SPLAT! RAN INTO A CAR / DROPPED 1 TOKEN"
- "THE WHITE SQUIRREL!" (Gord: *"the best Toronto line in the game"*)
- "SO LONG, MARCUS!" (Kev bumped him four times in one night)

What's left is two verbs ("TAP TO STAY GOLD", "MID-LEAP"), the card formulas, and the gave-up reason lines.

## Mastery

Skill shows clearly in every event.

Practised (8 f) vs first-timer (18 f), from Hal:

| Event | Ratio |
|---|---|
| Bike | 1.7× |
| Off-Leash | 1.8× |
| Tallboy | 1.5× |
| Regatta | 1.3× |
| Parking | 1.2× |

Expert vs human bot:

| Event | Ratio |
|---|---|
| Bike | 2.6–2.9× |
| Bay | 1.8–2.2× |
| Off-Leash | 2.7–3.7× |
| Tallboy | 2.5–3.2× |
| Regatta | 1.7–1.8× |
| Parking | 2.0–2.3× |
| TTC | 2.0× |

Testers' two-run comparisons:
- **Off-Leash:** Lena went 3485 → 5050 → 9510.
- **Tallboy:** Dana went 2294 → 5729, Lena 2073 → 5332.
- **Regatta:** Tasha found a 3-frame rounding staircase from +200 to +300 to +500. In her words: *"That's a sport."*

## Next sprint

1. **Tells that warn, not windows that flash.** For every hidden trick:
   - The cue starts **≥ 15–20 f before** the window opens, and lasts until it closes.
   - It is visible **and** audible.
   - It's readable in normal play, not only in the demo's setup.
   - Specific fixes:
     - Off-Leash: warn earlier, before the spring.
     - Bike: the rails glow from ~20 f out.
     - Regatta: an actual tell for its trick.
     - Tallboy: mark the brave/SLOSHED boundary on the meter.
     - Parking: ring on every cyclist spot.
     - TTC and Bay: verify their cues are visible.
   - Acceptance test: a cue-watching bot at **18–20 f** lands the trick more often than not.
2. **The coach and card copy never mislead:**
   - Regatta never re-plans without input and never praises untapped taps; it pauses ADRIFT during any order.
   - TTC's gold copy matches the mechanic.
   - Off-Leash's "MID-LEAP" is corrected.
   - Gave-up reason lines are right for Bay, TTC and Parking.
3. **Off-Leash's tackle floor:**
   - Tackles can't wipe a competent walk to 0 (cap the penalty, or keep walk pay).
   - The fail card shows DOGS or says why not.
   - The record comes down so a flawless safe walk reaches silver.
4. **Bay rebalance:**
   - Dodging matters (spills cost time as well as points).
   - Blind EXCUSE ME doesn't pay.
   - DOUBLE TIME rewards faster hands.
   - The record goes back to ~75% of the best run.
5. **Style rows:**
   - Full 16 px spacing (or 12 px), never touching.
   - Itemise Bike, Tallboy, Off-Leash and TTC too.
   - Bike's "+ TOKENS+STYLE" made readable.
6. **Polish:**
   - Bike: no unwarned warm-up rear-end, and the wobble copy.
   - Parking: card order, arrows instead of words, and the LET GO window.
   - Records board icons.
   - The card formulas.
