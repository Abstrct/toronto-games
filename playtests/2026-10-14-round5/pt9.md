# pt9 Hal (tournament host), round 5

**Round 1 → 2 → 3 → 4 → 5:**
- overall 5 → 6.5 → 7 → 7.5 → **8**
- vs California Games 5 → 6.5 → 7 → 7.5 → **8**
- Bike 6 → 6.5 → 7 → 7 → 7.5 · Bay 6.5 → 7 → 7.5 → 7.5 → 8 · Off-Leash 5 → 6.5 → 6.5 → 6.5 → 7 · Tallboy 3 → 7.5 → 7.5 → 7.5 → 7.5 · Regatta 3 → 4 → 5 → 6.5 → 6
- Parking 6.5 → 6 → 7.5 · Subway 5 → 7.5 → 8

I'm Hal. I've run California Games brackets at conventions, and I judge whether a room of strangers can play this fairly in turns.

## 1. My round-4 complaints
- **Parking idle took 97 s to score 0: FIXED.** Now you're towed at 14 s, and the card says "10 S WITHOUT DRIVING".
- **A mashed A on the final standings threw the crew away: FIXED.** TITLE is still the default, but it now asks "LEAVE AND LOSE 2 PLAYERS? ▶NO YES" with the cursor on NO.
- **"HELLO? STEER LEFT/RIGHT!" nagged a boat that was fine: BETTER.** It now reads "HELLO? STEER OR GO ADRIFT!" and warns about a real rule. Doing nothing ends at about 16 s with "NOBODY STEERED FOR 10 S".
- **Parking "PULL UP BESIDE IT" was ambiguous: FIXED.** The card now says "UP: REAR BUMPER TO LINE / BACK IN: DOWN+RIGHT, THEN DOWN+LEFT", which is my rewrite, and the line is painted on the road. The live coaching is the best in the game: "LET GO! STOP ON THE LINE", "PAST IT! ↓ BACK TO THE LINE", "GET READY: DOWN+LEFT SOON", "NOW! ROLL TO DOWN+LEFT".
- **A regular couldn't pull away from a first-timer: MOSTLY FIXED** (see section 4).
- Podium before the final table: unchanged, and fine now that both show the reason.

## 2. Regressions and new issues
- **[major] pt9r5-sail-957555384.** In the Regatta, a flailing first-timer (random ◀ ▶ every 20–60 frames) sails for **92 s and scores 0**: 17 bumps, COURSE 182 − BUMPS 182. A player who taps twice and lets go gets ADRIFT and **148 in 16 s**. The one who tries holds the pad six times as long and scores less. The clock went from 75 to 90 since round 4, and the bots agree (random_input and hold_right both take 92 s for 0).
- **[minor] pt9r5-park-957635332.** In Off-Leash, holding ▲ and tapping B once a second without ever looking gives **0 tackles and 1585–1775**. That's #5 on the board and a solo bronze, and it beats the average honest bot (leash_human ~1400). Tapping B every 2 s instead gets you tackled out for 0.
- **[minor] pt9r5-bike-957575728.** The Bike wipeout card lists "TTC TOKENS X50 2", but RIDE 267 = SCORE 267. At a table someone adds the 100 and calls the card wrong. The HUD also shows three full hearts under the card.
- **[minor] pt9r5-card-bay-957686919.** The Bay card never mentions DOUBLE TIME. Stepping blind on every dot scores **2470**, against **1776** for blind stepping on the big dots only. Whoever read the manual gets +40%.

Fairness checks that passed:
- Bay 2P with identical inputs: 1776 / 1776.
- Shared gold at 5–5, a 0 earns no medal, and "CO-CHAMPIONS OF TORONTO / TIED ON 5 PTS AND MEDALS" appears on both the podium and the final table.
- Tallboy BUSTED sums are honest: 181 + 88 − 67 = 202, "FINED 1/4".

## 3. Copy: 8/10
**Clear:**
- The Parking coaching.
- The TTC HUD: "STATION AHEAD" → "BRAKES! LEAN ◀".
- Tallboy: "TAP A AT CHALK. RED: HOLD", "OOF! SPILLED! HE'S GAINING", "COP'S WATCHING! DON'T SIP!".
- Regatta: "WIND FROM TOP: ZIG-ZAG UP" matches the WIND ↓ arrow.
- Every reason line under a failed run reads well: "THE 5:42 LEFT WITHOUT YOU", "COP CAUGHT YOU: FINED 1/4", "250 PER MARK ROUNDED", "STANDING STILL PAYS 0", "THIRD WIPEOUT. NO TIPS!".

**Jokes that land:** "BUMPER TAP! (IT'S A BMW)", "HALF IN. $75 TICKET!", "PHOTOBOMBED A TOURIST! SORRY!", "SHE JUST WANTS TO PLAY!".

**Unclear:**
- The Bike card's "HOP RAILS, DODGE LATE: X8" reads like a password.
- A made train is just "FINISHED!", when it should be "MADE THE 5:42!".
- The tokens line on the Bike wipeout card.
- PRESS A WHEN READY doesn't appear on every card (maybe it blinks).

**Rewrite:** Bay line 3 → "LEFT/RIGHT ON BIG DOTS (SMALL TOO = X2)".

## 4. Mastery
In Bay, by hand:
- A first-timer's rhythm (±8 f of jitter) **missed the train with 565**.
- ±4 f: 1675.
- A steady metronome: 1776.
- Double time: 2470.
- The ear and ace bots: 3800–4100.

That's a real 2–6× gap, and it comes from technique (on the beat, double time, lanes), not just reaction speed. Tallboy is even steeper: a blind hopper is busted at about 31 s with 150–200, against 5342 for the best bot.

From the reaction curves on this build (bots scoring 8 f vs 18 f late, which is reaction speed only):

| Event | 8 f vs 18 f |
|---|---|
| TTC | 2.6× |
| Bay | 1.9× |
| Bike | 1.8× |
| Parking | 1.5× |
| Off-Leash | 1.4× |
| Tallboy | 1.4× |
| Regatta | 1.0× |

Style policies push Bike, Off-Leash, Tallboy and Regatta to about 2× (Bike stylist 7252 vs human 3500; Regatta expert 5475 vs casual 2750). That's California Games territory now.

What doesn't pull away:
- In Off-Leash, a no-look metronome sits at about 35% of the ace.
- In the Regatta, reaction is worth nothing. Skill is all route, and the floor is broken (see above).

## 5. Report sections
- **Overall: 8/10.** The first build I'd put on the bar TV for a bracket. **vs CG: 8/10.**
- **Per event:**
  - **Bay 8:** fair, musical, and skill shows.
  - **TTC 8:** the best curve in the game.
  - **Parking 7.5:** the coaching turned the worst-taught event into one of the best taught.
  - **Bike 7.5:** idle is fixed; the token line is a nit.
  - **Tallboy 7.5:** the fine is honest, but blind play busts quickly.
  - **Off-Leash 7:** the metronome line.
  - **Regatta 6:** a 92 s turn for 0.
- **Turn lengths:**
  - Bay 51–64 s
  - Bike 40–60 s
  - Off-Leash 57–80 s
  - Tallboy busted 31 s, finished 65–74 s
  - Regatta 16–92 s
  - Parking 14–48 s
  - TTC 52–56 s
- **Loved:**
  1. The co-champions ceremony.
  2. Parking coaching.
  3. Bay on the beat, with identical scores for identical play.
- **Top problems:**
  1. [major] Regatta flailer (pt9r5-sail-957555384).
  2. [minor] Off-Leash blind B (pt9r5-park-957635332).
  3. [minor] Bay card silent on DOUBLE TIME (pt9r5-card-bay-957686919).
  4. [minor] Bike token line (pt9r5-bike-957575728).
  5. Record scales vary from 3000 to 6500, which only matters to records-board bragging.
- **CG had:** every bad run lasted under a minute.
- **More Toronto:**
  - Ferry horn as the Regatta start gun.
  - "Please move all the way to the back" on TTC.
  - A Green P ticket guy who docks slow parkers.
- **Quote:** "First night nobody asked me to explain the rules. They argued about the score instead, and that's the game working."

## 6. As good as California Games?
**Nearly; it's a tie on most events.** The biggest thing in the way is the Regatta's floor. A first-timer who flails gets the longest turn in the game and the lowest score, worse than giving up. End the race on no progress toward the next mark (not only on no steering), and keep the bump penalty from taking a trier below the ADRIFT score. Then I'd run it at a convention.
