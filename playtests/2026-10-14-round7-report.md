# Toronto Games: playtest round 7, 2026-10-14

The same ten testers played the build after sprint 6. The build under test was frozen as `build/pt/panel7` (tag `panel7`).

Sprint 6 changed these things:
- **Regatta's coach:** it gives one order at a time and says RING AHEAD! HOLD YOUR COURSE near a ring. The ADRIFT countdown never runs near a mark, and the boat pushes off the shore and the ferry.
- **Off-Leash:** 16 dogs, each comes once, with a red-! crouch tell.
- **Bay:** dodging counts and PRESTO is explained.
- **Parking:** the coach is timed to the player's own reactions.
- **Tallboy:** take-offs are graded.
- **Bike:** wipeouts drop tokens, and streetcar crossings are added.
- **Result jingles,** with the DC offset fixed.
- **Menus:** the roster prompt defaults to NO, and the podium names silver and bronze.
- **One undocumented trick per event.**

Testers filed 35 findings: 6 major, 27 minor and 2 notes. That's the fewest per round so far: 72 → 56 → 62 → 40 → 35.
List them with `build/pt/panel7/pt findings --file build/pt/findings_round7.jsonl`.
Per-tester reports are in `playtests/2026-10-14-round7/`.

## Scoreboard (round 6 → 7)

| Tester | Overall | vs CG | Bike | Bay | Off-Leash | Tallboy | Regatta | Parking | Subway |
|---|---|---|---|---|---|---|---|---|---|
| Dana, beginner | 8 → **7** | 7 → 7 | 6 → **4** | 7 → 6 | 7 → 8 | 8 → 8 | 6 → **8** | 4 → 5 | – → 4 |
| Marcus, party | 8 → **8.5** | 7.5 → 8 | 6 → 6.5 | 7.5 → 7 | 7.5 → 8 | 6.5 → 7 | 4.5 → **7** | 8 → 8 | 6 → 7.5 |
| Priya, YouTuber | 8 → **8.5** | 7.5 → 8 | 7 → 7 | 7.5 → 7.5 | 7 → 7 | 7 → 7 | 7 → 8 | 7.5 → 8 | 7 → 7 |
| Rob, TAS | 8 → **8.5** | 7 → 8 | 8 → 8 | 8 → 8 | 6 → **8** | 7 → 8 | 7 → 8 | 8 → 7 | 8 → 8 |
| Lena, designer | 8 → 8 | 7 → **8** | 8 → 8 | 8 → 7 | 8 → 8 | 7 → 8 | 5 → **7** | 8 → 8 | 7 → 7 |
| Gord, Torontonian | 7.5 → 8 | 7 → 7.5 | 6.5 → 6.5 | 7.5 → 7 | 7 → 7.5 | 6.5 → 7.5 | 6 → **8** | 7 → 7.5 | 7.5 → 7.5 |
| Kenji, art/audio | 9 → 9 | 8.5 → 8.5 | 9 → 8.5 | 8.5 → 9 | 8 → 8 | 8.5 → 8.5 | 7 → 7 | 8 → 8.5 | 8.5 → 8.5 |
| Tasha, completionist | 8.5 → 8.5 | 8 → 8 | 6.5 → 6.5 | 7 → 7 | 6 → 6.5 | 5.5 → 6 | 7 → 6.5 | 7.5 → 8 | 6 → 6.5 |
| Hal, tournament | 8 → 8 | 8 → 8 | 8 → 8 | 8 → 8 | 7 → 7.5 | 7.5 → 7.5 | 6.5 → 6.5 | 7.5 → 8 | 8 → 7.5 |
| Mo, QA | 8 → 8 | 7.5 → 7.5 | 8 → 7.5 | 7 → 7 | 7 → 7.5 | 6 → 7 | 7 → 7 | 7 → 6.5 | 6.5 → 7 |
| **Average** | **8.1 → 8.2** | **7.5 → 7.9** | 7.3 → 7.1 | 7.6 → 7.4 | 7.1 → **7.6** | 7.0 → **7.5** | 6.3 → **7.3** | 7.3 → **7.5** | 7.2 → 7.1 |

**Overall:**

| Round | Overall | vs California Games |
|---|---|---|
| 1 | 5.6 | 5.0 |
| 2 | 6.7 | 6.2 |
| 3 | 7.1 | 6.6 |
| 4\* | 7.9 | 7.4 |
| 5 | 7.7 | 7.2 |
| 6 | 8.1 | 7.5 |
| **7** | **8.2** | **7.9** |

\* Round 4 is the four testers who finished it.

- **Regatta is no longer last.** It jumped a full point (6.3 → 7.3). Five testers moved it up 1.5–2.5, and three name it their favourite (Gord, Priya, Dana).
- **"vs California Games" rose the most (7.5 → 7.9).** Seven testers now give 8 or 8.5.
- **The events now sit in a tight band, 7.1–7.6.** Off-Leash, Tallboy and Parking rose. Bike, Bay and TTC slipped slightly, mostly on Dana's prompt-timing problems.
- **Dana is the only tester who dropped** (8 → 7), and her report says why: four prompts give the right action at the wrong moment or with the wrong verb.

## Is it as good as California Games yet?

Hal says yes on six events (*"Six events I'd run blind. The seventh still needs a judge at the buoy."*). Rob, Marcus, Priya, Lena, Gord and Kenji say "nearly" or "very close". Their single biggest blockers:

1. **Cue timing: the right action at the wrong moment.** Dana, Gord and Priya raised it; it accounts for 4 of the 6 majors.
   - **Bike:** "HOP THE RAILS: B!" shows about 100 frames before the rails, so a hop made when told wobbles (pt1r7-bike-999836828, Gord too).
   - **Bay:** the red "!" gives about 20 frames, less than a human reaction (pt1r7-bay-90675).
   - **Parking:** "STRAIGHT! LET GO OF THE PAD" lands with or after the curb hit at 22 frames (pt1r7-pk-1068139).
   - **TTC:** "SOLID: D-PAD THAT WAY NOW" reads as *hold*, and holding drives the dot out of the ring (pt1r7-ttc4-1735525).
   - Dana: *"Regatta shows the fix works: a coach timed to a human made it a joy this round."*
2. **Regatta's coach goes stale after each mark.** Five testers saw it.
   - The previous order ("TO MARK 2: TAP ◀ ONCE") stays up 70–100 frames after the HUD moves on, and the boat bumps the mark it just rounded.
   - Two majors:
     - Hal (pt9r7-sail-999912881): circled mark 2 and went ADRIFT.
     - Kenji (pt7r7-sail-999928938): TACK NOW came only at ADRIFT IN 3.
   - "ZIG-ZAG: WAIT FOR TACK NOW!" reads as "TACK NOW!".
   - Hal's fixes:
     - count a pass across the drawn ring;
     - clear an order once it's done ("GOOD. HOLD IT…");
     - freeze ADRIFT on green diamonds.
3. **Risk and discovery at the top** (Lena, Tasha, Marcus).
   - **Off-Leash:** CLOSE SHAVE pays +100 over NICE but a tackle costs 150, a heart and the chain. The risky trick doesn't pay more than the safe one.
   - **Regatta:** style is hidden so well that a coach-follower sees no STYLE row at all.
   - **Hidden tricks:** none was found by play. Three testers saw "ROLL TACK" in a commit title, which is a leak. Commit messages no longer name tricks.
   - Tasha: *"California Games showed you the trick in the attract demo and then let you work out how to do it."*

## What got fixed (round-6 complaints)

- **Regatta:**
  - Coach-obeyers finish. Lena went 8/8; Marcus, Mo, Tasha, Gord, Dana and Priya finished on their first try. Lena: *"The coach finally sails with you, not against you."*
  - Ferry pins are gone, GUST no longer covers the coach, LINE HONOURS is clean-only, and the finish line is clear.
  - Expert spread dropped from sd 870 to sd ~100.
- **Off-Leash:**
  - Rob's timeout farm is gone (*"Round 6 paid me to lose. Round 7 makes me pay for it, which is right."*).
  - A safe walk medals, the bold window is reachable, and the per-tenth line is honest.
  - Hearts empty, mashers end quickly, and idle shows "NAP IN BELLWOODS!".
- **Bay:** spills keep costing, DECAF ends DOUBLE TIME, the card teaches lanes, and the judge words sit over the walker.
- **Parking:** the coach is timed to human reactions (Priya, Hal, Tasha and Kenji parked first time), the clock is honest to the tenth, and the box tells you how to advance.
- **Tallboy:** reaction matters (8 vs 18 frames went from 1.04× to 1.5×), the plateau is open, and the sip is a real second verb.
- **Bike:** no undocumented fee, and crash lines name what you hit.
- **TTC:** honest LEGS LEANED, germs capped at 20, and Gord's gold-dot wording.
- **Menus:** the roster prompt defaults to NO (Mo: *"Fifteen A's on LOSE ALL 8 PLAYERS? and all eight are still standing. Ship it."*), standings spacing is fixed, and the podium names silver and bronze.
- **Audio:** the DC offset is gone (Kenji: under ±40 everywhere), there's no thump, and the result jingles play.
- **Records:** every #1 is at 65–76% of Rob's best TAS run.

## Problems, ranked

**Major (6):** the four cue-timing findings above (Bike rails, Bay red !, Parking straighten, TTC hold), plus the two Regatta stale-coach findings.

**Minor, grouped:**
- **Bike:**
  - "THIRD WIPEOUT. NOT PAID!" sits under a non-zero score (5 testers).
  - "RIDE 1562+20/S" doesn't say what 1562 is (4).
  - STYLE is hard-capped at 5000, and the card doesn't say so (Rob).
  - The rails along the lanes are 1 px lines that look like lane dividers (Kenji).
  - The 501's only warning is a small ⚠.
  - First-timers still wipe out before style starts (Priya, Gord, Dana).
- **Regatta:**
  - TOUCHED THE MARK shows ~220 frames late, by the dock (Tasha).
  - Style is lumped into one number on the card (Gord, Tasha).
  - CLEAN TACK needs ~10 taps a second, and that's untold (Lena).
  - "RUN DOWNWIND TO MARK 3!" has no count.
  - The music is ~3 dB quiet again (Kenji: −19.9 dBFS).
- **Off-Leash:**
  - A 2-frame DODGE hole as the red "!" goes out and the lunge starts (Lena, Marcus).
  - Callouts are a borderless strip, unlike the panels in the other six events (Kenji).
  - "3 HEARTS GONE. NO DOGS!" doesn't say "forfeit".
  - "SAFE: B ON ! = 100 A DOG" (the "A" reads as the button).
- **Bay:**
  - A lane-blind DOUBLE TIME walk still makes the board (Mo).
  - MISS pops on dead-on DOUBLE TIME steps, and "TIP: STEP AS BIG DOTS LAND" contradicts double time (Gord).
  - At 15 f, double time scores below a plain walk (Marcus).
  - The first-timer margin is down to 0 s (Lena).
  - "LAST SIP!" shows under DECAF (Tasha).
  - The quit card is headed "CALLED IT A DAY".
- **Tallboy:**
  - When stuck against crates, the coach says "HOLD B!" and never "TAP A TO SCRAMBLE" (Rob).
  - "RUN HURDLES+ROAD" is a formula, not a rate (Priya, Marcus).
  - The finish popup and the card add up the same total two ways (Marcus).
  - Expert/human is 4.4×, steeper than the guideline (Rob).
- **Parking:**
  - The top end is one line (5549–5645 on every seed), and the human bot equals the expert (Rob, Hal).
  - The card line "DOWN+LEFT ON NOW!" reads as a typo (Lena, Hal, Kenji).
  - "KEEP DOWN+RIGHT" shows when holding nothing (Gord).
  - "PARKED. IT'LL DO." undersells a 936.
  - "PARKED ON BRUNSWICK!" shows after 1 of 3 spots (Dana).
- **TTC:**
  - 2P identical blind input scores differ (Hal).
  - The dot is 3 px and hard to read (Kenji).
- **Cards and menus:**
  - Some board cards drop "SO LONG, …" when a penalty row takes space (Mo).
  - The medal-table tie shows 1, 1, 3 with no "golds break ties" (Marcus).
  - Two-line panel rows touch (Kenji).
  - "Compete in some" starts with all 7 on (Tasha).

## Copy

Clarity averages **8.1/10** (7–8.5).

**The best lines:**
- **Regatta's coach:** "RING AHEAD! HOLD YOUR COURSE", "AGROUND! TAP ▶ TO BEAR OFF" → "PUSHED OFF! SAIL ON!".
- **The Parking chain.**
- **Off-Leash:** "RED ! = B NOW FOR +200".
- **Tallboy's formula popups:** "SIP 'N' HOP! +24 / 8 X3 DEAD ON".
- **Off-Leash's forfeit line:** "NO DUNDAS, NO DOGS!" (Rob: best fail line in the game).

**Jokes:**
- "THE RCYC BAR IS OPEN!" (the panel's favourite).
- "IT'S DUNDAS, BUD".
- "CARD DECLINED! GOLD DOTS ONLY".
- "SORRY, HE'S A RESCUE!".

**What's left is mostly verbs and moments:**
- "SOLID: D-PAD THAT WAY NOW" → "TAP THAT WAY, DON'T HOLD".
- "NOT PAID!" over a score.
- "WAIT FOR TACK NOW!".
- "DOWN+LEFT ON NOW!".
- "NEW TRICK IN 2 S" (reads as a countdown).

## Mastery

**Reaction speed** (8 f vs 18 f, Hal):

| Event | Ratio |
|---|---|
| TTC | 2.1× |
| Bike | 1.9× |
| Off-Leash | 1.75× |
| Bay | 1.7× |
| Tallboy | 1.5× |
| Regatta | 1.4× |
| Parking | 1.25× |

That's a consistent band.

**Style ceilings** (best ÷ human-level): about 2–3× everywhere except Parking (flat). Expert ÷ 15-frame human (Rob):

| Event | Ratio |
|---|---|
| Tallboy | 4.4× |
| Off-Leash | 3.2–3.9× |
| Bike | 2.4× |
| Bay | 2.4× |
| Regatta | 2.3× |
| Subway | 2.2× |

**Testers' two-play tests:**
- **Off-Leash:** 3420 → 5400 (Marcus). Lena tried four approaches, from 3630 to 5285.
- **Tallboy:** 2100 → 4924 (Dana), 2188 → 4060 (Gord).
- **Regatta:** 2485 → 2860 (Gord).
- **Parking:** 936 → 943 (Hal).

**Hidden tricks:** none found by play. Rob measured ROLL TACK at +665 (~15%) after reading its name in git.

## Next sprint

1. **Cue timing for a 20–25 f human,** the four majors:
   - **Bike:** the rails prompt shows when the rails are on screen, and the hop window is forgiving.
   - **Bay:** the red "!" gives ≥ 35 f of warning.
   - **Parking:** the straighten cue comes before the curb.
   - **TTC:** the card says "TAP, DON'T HOLD", or holding stops pushing past centre.
2. **Regatta's stale coach:**
   - Clear an order on completion and on rounding.
   - No orders while a mark rounding is pending.
   - Count a pass across the drawn ring.
   - Freeze ADRIFT on green diamonds.
   - Show the mark bump at the mark.
   - Itemise style on the card.
   - Hint style exists to coach-followers.
   - Restore the music level.
3. **Risk pays:**
   - CLOSE SHAVE worth clearly more than NICE.
   - Close Off-Leash's 2-frame hole.
   - DOUBLE TIME worth it for a 15 f human.
   - Parking's top end gets a second axis.
4. **Copy and cards:**
   - Bike's NOT PAID / 1562 / STYLE cap.
   - Tallboy's scramble cue and RUN rate.
   - Parking's card line and "PARKED ON BRUNSWICK!" after 1 spot.
   - The Off-Leash callout panel and "forfeit" wording.
   - The board card's SO LONG line.
   - The medal-table tie text.
   - Two-line panel leading.
5. **Discovery:**
   - Show each event's hidden trick once in its attract demo, the way California Games did, without the coach naming it.
   - Keep trick names out of commit messages.
