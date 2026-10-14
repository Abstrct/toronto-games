# Toronto Games: playtest round 5, 2026-10-14

The same ten testers played the build after sprint 4. Sprint 4 brought:
- **Result cards:** 16 px rows, zero rows hidden, and a reason line under every failed run.
- **Fairness:** every event finishes at a human's reaction time, and experts score 1.85–2.1× an average human.
- **Events:** Bay is judged on the beat with DOUBLE TIME, Regatta has a close-hauled arrow and TACK NOW, and Parking
  has a stop line and an itemised spot box.
- **Menus:** a TITLE confirm and a quiet spell between players.

The build was frozen as `build/pt/panel5` (tag `panel5`). Testers filed 62 findings: 14 major, 46 minor and 2 notes.
List them with `build/pt/panel5/pt findings --file build/pt/findings_round5.jsonl`. Per-tester reports are in
`playtests/2026-10-14-round5/`. Round 4 was cut off after four reports, so "–" marks a round with no score.

## Scoreboard (round 1 → 2 → 3 → 4 → 5)

| Tester | Overall | vs CG | Bike | Bay | Off-Leash | Tallboy | Regatta | Parking | Subway |
|---|---|---|---|---|---|---|---|---|---|
| Dana, beginner | 6 → 7 → 7 → – → 7 | 6 → 7 → 6 → – → 6 | 4 | 6 | **8** | 5 | 6 | 5 | 4 |
| Marcus, party | 6 → 7 → 7.5 → – → 7.5 | 5 → 7 → 7.5 → – → 7.5 | 5.5 | 6.5 | 7 | 6 | 4.5 | **8** | 6 |
| Priya, YouTuber | 6 → 7 → 7.5 → – → 7.5 | 5 → 6.5 → 7 → – → 7 | 7 | 7.5 | 6.5 | 7 | 6 | 7 | 7 |
| Rob, TAS | 5 → 7 → 7 → – → **8** | 5 → 6 → 7 → – → 7 | 8 | 8 | 8 | 7 | 7 | 7 | 7 |
| Lena, designer | 5 → 6 → 7 → 8 → 8 | 4 → 5 → 6 → 7 → 7 | 8 | 7 | 8 | 7 | 5 | 8 | 7 |
| Gord, Torontonian | 6 → 6 → 6 → – → **7** | 5 → 5 → 5 → – → **6.5** | 6 | 6 | 7 | 7 | 6 | 5 | 7 |
| Kenji, art/audio | 6 → 7 → 7.5 → 8 → **8.5** | 5 → 6 → 7 → 7.5 → **8** | 8.5 | 8 | 7.5 | 8.5 | 7.5 | 7.5 | 8 |
| Tasha, completionist | 5.5 → 7 → 7.5 → 8 → 8 | 5 → 6.5 → 7 → 7.5 → 7.5 | 6.5 | 6.5 | 6 | 5.5 | 5.5 | 7 | 6 |
| Hal, tournament | 5 → 6.5 → 7 → 7.5 → **8** | 5 → 6.5 → 7 → 7.5 → **8** | 7.5 | 8 | 7 | 7.5 | 6 | 7.5 | 8 |
| Mo, QA | 5 → 6.5 → 7 → – → 7.5 | 5 → 6 → 6.5 → – → 7 | 8 | 6.5 | 6.5 | 6 | 5 | 6.5 | 6.5 |
| **Average** | **5.6 → 6.7 → 7.1 → 7.9\* → 7.7** | **5.0 → 6.2 → 6.6 → 7.4\* → 7.2** | 6.6 → **6.9** | 6.7 → **7.0** | 6.7 → **7.2** | 6.3 → **6.7** | 5.3 → **5.9** | 5.7 → **6.9** | 4.8 → **6.7** |

\* Round 4 is only the four testers who finished (Lena, Kenji, Tasha, Hal). The same four went from 7.9 to **8.1** overall
and from 7.4 to **7.6** against California Games. Event columns compare round 3 with round 5.

**Overall:**
- **Every event rose.** The two newest made the biggest jumps: TTC Surfing went from 4.8 to 6.7 and Parking from 5.7 to 6.9.
- **No event averages below 5.9 any more.** Regatta is still last.
- **Two testers rate it a full 8 against California Games:** Hal (*"the first build I'd put on the bar TV for a bracket"*)
  and Kenji. Gord, the hardest marker, gave his first 7 overall.

## Is it as good as California Games yet?

Two testers say yes or "nearly" (Hal, Kenji). The other eight say "close, not yet". Their single biggest blockers
fall into three groups:

1. **Regatta** (Lena, Mo, Hal; six testers file majors there).
   - ADRIFT ends good races. Marcus had rounded all three marks with 13 s left; Lena was 1.5 s from mark 3.
     Both were sailing well but hadn't touched ◀ ▶ for 10 s.
   - Flailers drift 92 s for 0, and bumps wipe out every course point.
   - An idle boat rounds mark 1 by itself, then the card says "STANDING STILL PAYS 0".
   - The yellow arrow reads as the boat's heading.
   - A 6-frame player and a 15-frame player score the same (1.0×).
2. **An ordinary player's first minute and the cards that explain it** (Dana, Marcus, Priya, Tasha).
   - Off-Leash is the model everyone points to: a fair warning, a forgiving window and a reachable finish.
     Dana: *"I dodged five dogs, got a medal, said so long to the white squirrel."*
   - Elsewhere: Bike wipes out every party player before Spadina.
   - Following Bay's card ("LEFT, RIGHT ON BIG DOTS") misses the train: six testers showed it.
   - Off-Leash and Regatta cards show **"CROSSING 450 − TACKLES 450 = 0"** under "CROSSING PAID BY DISTANCE",
     because the penalty is clamped to whatever reaches zero, so the card looks rigged.
3. **Style depth at the top** (Rob, Gord).
   - Tallboy, TTC Surfing and Parking flatten to a fixed maximum: 32 of 48 expert TTC runs land on exactly 6653,
     and Tallboy's top is the same SIP 'N' HOP 26 times.
   - Gord: *"Now give me a reason to go back for style."*
   - Rob: *"Four events are worth a record attempt. In the other three, the record attempt ends in a tie."*

## What got fixed (round-4 complaints)

- **Result cards:** confirmed fixed by every tester who raised them.
  - There are no more "− WIPEOUTS 0" rows, and zero-score cards add up.
  - Reason lines land: "THE 5:42 LEFT WITHOUT YOU", "COP CAUGHT YOU: FINED 1/4", "THIRD WIPEOUT. NO TIPS!".
- **Off-Leash:** now finishable by beginners, Dana and Gord included. The squirrel no longer hides warnings.
- **Tallboy:** honest players aren't busted at 19–32 s any more.
- **TTC Surfing:**
  - The hollow-then-solid arrow is a real warning.
  - The skill cliff is gone: a 250 ms human scores half the expert's score.
  - Gord reached Union on his first ride.
- **Parking:**
  - The stop line, the coaching and the itemised box read *"the best tutorial on the cart"* (Lena) and *"superb"* (Marcus).
  - The idle run that dragged 97 s now ends in a tow at 14 s.
  - The ticket arithmetic is consistent.
- **Bike:** tap-pedalling works and RAIL WOBBLE shows.
- **Menus:**
  - The TITLE confirm saves the roster.
  - REMATCH goes straight to Bike with the same crew.
  - A tie shares gold.
- **Audio:** stereo is audible and the levels are even. Only Regatta is 4–6 dB quiet.

## Problems, ranked

**Major** (each raised by three or more testers):
1. **Regatta's ADRIFT rule and score floor.**
   - Filings: pt5r5-sail-957327564, pt2r5-party-957869750, pt9r5-sail-957555384, pt1r5-sail-957702746.
   - End the race on no progress toward the mark, not on no steering.
   - Never let bumps put a trier below an idler.
   - Don't let the idle drift round mark 1.
2. **Bay's card teaches the losing move.**
   - Filings: pt5r5-bay-957401403, pt2r5-party-957463326, pt6r5-bay-958202775, pt9r5-card-bay-957686919,
     pt4r5-bay-958080028.
   - Six testers proposed the same rewrite: "◀ ▶ ON EVERY DOT / SMALL DOTS = DOUBLE TIME".
   - Coffee and GROOVE are never introduced.
3. **Clamped penalties read as rigged.**
   - Filings: pt3r5-park-957538336, pt3r5-sail-957560909, pt7r5-park-957610625, pt2r5-party-957553676,
     pt1r5-park-957920936.
   - Show the real per-hit cost ("3 TACKLES −450") and floor the score instead.
4. **The Bike wipeout card lists TOKENS and STYLE that don't count.**
   - Raised by nine of ten testers.
   - Mark them forfeited, or leave them off a failed card.
5. **Results cards locked under mashing.**
   - Filing: pt10r5-cops-957785058.
   - **Fixed on main after the freeze** (0e18245): once LET GO has been up for four quiet spells, a fresh A goes through.
6. **The Parking attract demo wedged into a car, and the DEMO caption overprinted the coach line.**
   - Filings: pt3r5-pkdemo-957275610, pt10r5-att-957657579.
   - **Fixed on main after the freeze** (71a21af): the bot waited for the car to be placed, and the caption moved
     to the bottom row.

**Minor, grouped:**
- **Parking:**
  - The coach can lead into a wedge (pt1r5-park2, pt4r5-park2) or into the bike lane on spot 3 (pt8r5-parking-957501119).
  - The spot box double-counts live hits (pt8r5-parking-957463376).
  - "23S" reads as "235", and the box rows are cramped.
  - The quit card's DINGS+FINES doesn't match the box (pt4r5-park-957903474, pt2r5-party-957996091).
  - "FIX IT, OR A" reads as cut off.
- **Off-Leash:** a blind B rhythm can finish, so you never have to watch the dogs (pt9r5-park-957635332,
  pt2r5-party-957581068). "GET SET" stays up after you're set.
- **Tallboy:** one input pair repeated 26 times sets the record (pt6r5-cops2). The README's "chalk alone = x3"
  contradicts the game. "TAP A AT CHALK. RED: HOLD" never says hold what.
- **TTC Surfing:**
  - "PATIENT ZERO!" appears twice on the card.
  - The callout says "GOLD DOT SURF X1" while the card says X3.
  - "CURVE! LEAN ↓" reads as "crouch".
  - "STANDING STILL PAYS 0" contradicts the intro's "HANDS-FREE".
- **Regatta:**
  - TACK NOW gives no hold length.
  - LINE HONOURS shows after 6 bumps (pt6r5-sail-958181074).
  - The ferry-wait record route.
  - The music is quiet (pt7r5-sail-957664885).
- **Copy:** FINISHED! on five events (wanted: "MADE THE 5:42!", "UNION!"); "X8 of what?" on the Bike card.
- **Presentation:** three callout styles (panel, band, bare text); Parking hard-cuts between spots.

## Copy

Testers scored copy clarity 7–8 out of 10, averaging **7.3**. The jokes are the best-loved thing in the game:
- "BUMPED A BANKER! SORRY!", "HONK! HONK! GOOSED!", "EASY! IT'S A RENTAL!", "GRABBED THE STICKY POLE!",
  "BUMPER TAP! (IT'S A BMW)", "THE 5:42 LEFT WITHOUT YOU".

The remaining problems are lines that contradict what just happened:
- "NOBODY STEERED FOR 10 S" while steering.
- "CROSSING PAID BY DISTANCE" over a 0.
- "STANDING STILL PAYS 0" after a free mark.

Two controls lines also need an object: "X8" of what, and "HOLD" what?

## Mastery

The bot curves put an expert at 1.85–2.1× an average human in every event, and the testers mostly agree:
- **Bay:** 587 for a sloppy walker, 1776 on the beat, 2470 with DOUBLE TIME and 4409 weaving with PRESTO. Every layer pays.
- **Tallboy:** 1470 for a careful player against 5118 (3.5×).
- **Parking:** 530 against 2620 by hand.
- **Off-Leash:** the CLOSE SHAVE timing tier feels like California Games, though the payoff is small (+10%).

The gaps are elsewhere:
- **Regatta:** skill means finding your way, not style.
- **Bike and TTC Surfing:** casual players die before style pays.
- **Tallboy, TTC Surfing and Parking:** the top of the score range is flat.

## Next sprint

1. **Regatta:**
   - ADRIFT on no progress.
   - A floor above the idler.
   - No free mark.
   - An arrow that can't be read as the heading.
   - TACK NOW with a hold length.
   - The music level.
2. **Cards:**
   - Bay's every-dot line plus a coffee and GROOVE line.
   - Real per-hit penalties with a floored score (Off-Leash, Regatta, Parking quit).
   - Forfeited rows marked on Bike.
   - Per-event finish lines instead of FINISHED!.
   - The X8 and HOLD wording.
   - "PATIENT ZERO" once.
3. **First minute:**
   - Bike: thin out the potholes in the curb lane, and keep them away from open doors for the first 30 s.
   - Bay: a lane read that works in the 3/4 view.
   - Off-Leash: a blind B rhythm should fail.
4. **Top-end depth:**
   - Open the ceiling in Tallboy (vary the trick: RACCOON RUN, chalk-plus-sip variants), TTC Surfing and Parking.
   - Lower the Parking record to about 80% of the best run.
5. **Parking coach:**
   - The wedge recovery.
   - Spot 3's bike timing.
   - The double-counted box.
6. **Presentation:** one callout style everywhere; a fade between Parking spots.
