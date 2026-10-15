# Toronto Games: playtest round 10, 2026-10-14/15

The same ten testers played the build from sprint 9. Sprint 9 made these changes:

- **Hidden tricks:** each one now has a warning, visible and audible, at least 15 f before its window.
- **The three round-9 majors are fixed:**
  - Regatta's coach no longer re-plans without input.
  - TTC's gold copy now matches the game.
  - Off-Leash tackles cost a heart, never points.
- **Bay:** spills cost time, blind A costs a beat, and faster hands score more.
- **Cards:** style is itemised in all seven events with 12 px sub-rows. Every event has a gave-up line, and the records board shows rank numbers.
- **Records:** set at about 70–76% of each event's best run.

The build under test was frozen as `build/pt/panel10` (tag `panel10`).

A first launch of this round was cut off by a spend limit, and the testers restarted. They filed 34 findings: 5 major and 29 minor. They are archived in `playtests/2026-10-14-round10/findings.jsonl` and `build/pt/findings_round10.jsonl`.

## Scoreboard (round 9 → 10)

| Tester | Overall | vs CG | Bike | Bay | Off-Leash | Tallboy | Regatta | Parking | Subway |
|---|---|---|---|---|---|---|---|---|---|
| Dana, beginner | 8 → 8 | 8 → 8 | 8 | 7 → 6 | 7 → **9** | 8 → 7 | 8 | 8 → 7 | 8 |
| Marcus, party | 8.5 → **9** | 8.5 → **9** | 7.5 | 6.5 → **7.5** | 7.5 | 7 → 7.5 | 8 | 8.5 | 7 → 7.5 |
| Priya, YouTuber | 8.5 → 8.5 | 8.5 → 8.5 | 7.5 | 7.5 | 7 → 7.5 | 8 → 7.5 | 8 → 7.5 | 8 | 7 |
| Rob, TAS | 8.5 → 8.5 | 8.5 → 8.5 | 8.5 → 8 | 7.5 | 9 → **9.5** | 9 → 8.5 | 8 | 8 → 8.5 | 8.5 |
| Lena, designer | 9 → 9 | 8 → 8 | 8 → **9** | 7 | 10 | 9 | 8 | 8 | 7 |
| Gord, Torontonian | 8.5 → 8.5 | 8 → 8 | 8 | 7.5 → **8.5** | 8.5 | 7.5 | 8 | 8 | 7.5 |
| Kenji, art/audio | 9 → 9 | 9 → 9 | 9 → 8.5 | 9 | 8.5 → 9 | 8.5 | 8.5 | 8.5 | 9 |
| Tasha, completionist | 8 → **8.5** | 8 → **8.5** | 6.5 → 7* | 7.5* | – | – | 6.5 → **7.5** | – | – |
| Hal, tournament | 8.5 → **9** | 8.5 → 8.5 | 7.5 → 8 | 8 | 7 → **8** | 7.5 | 8 | 8.5 | 8.5 → **9** |
| Mo, QA | 8.2 → 8.4 | 7.8 → 8 | 8 | 7.5 → 8 | 8 | 7 | 7.5 → 8 | 7 → 7.5 | 6.5 |
| **Average** | **8.5 → 8.6** | **8.3 → 8.4** | 7.85 → **7.95** | 7.5 → **7.65** | 7.9 → **8.55** | 7.75 → 7.8 | 7.85 → **7.95** | 8.05 → 8.05 | 7.55 → **7.8** |

\* fragment; – = intro card only this round.

History:

| Round | Overall | vs California Games |
|---|---|---|
| 1 | 5.6 | 5.0 |
| 2 | 6.7 | 6.2 |
| 3 | 7.1 | 6.6 |
| 4 | 7.9 | 7.4 |
| 5 | 7.7 | 7.2 |
| 6 | 8.1 | 7.5 |
| 7 | 8.2 | 7.9 |
| 8 | 8.5 | 8.3 |
| 9 | 8.5 | 8.3 |
| **10** | **8.6** | **8.4** |

The plateau broke, but only by a little. **Off-Leash jumped to 8.55**, the best event in the game: Rob gives it 9.5 and Lena 10. Every event is now 7.65 or above.

- **Hal (overall 9):** "For running a bracket, yes."
- **Marcus (9 vs CG):** "Yes as a party machine, and just about as a sport."
- **Kenji (9 vs CG):** yes on presentation and audio.

## What got fixed (round-9 complaints)

- **All three round-9 majors:**
  - **Regatta:** Tasha obeyed every order and finished with LINE HONOURS. Mo: "DRIFTED!" replaces false praise.
  - **Off-Leash:** a walk that ignores the coach banks 300. Hal's B-timing sweep scores 6610–7350, "a ±5% band a bracket can live with".
  - **TTC:** tapping no longer ends PATIENT ZERO. It still doesn't pay, though; see below.
- **Cards:**
  - Style is itemised in every event, and the sub-rows no longer touch.
  - Gave-up lines are fixed for Bay, TTC and Parking.
  - Off-Leash's DOGS and TACKLES rows survive the row budget.
  - The records board shows rank numbers.
- **Bay:**
  - Lanes matter: Gord's straight walk scored 800, against 1515 dodging.
  - Faster hands win: in Marcus's party it went Kev 2042, Marcus 1493, Jen 1279.
  - Blind A misses the train: Mo scored 353.
  - Following the arrow leaves 3–6 s.
- **Bike:**
  - There's no warm-up rear-end any more (Dana).
  - The RAILS HOPPED window is exactly half a second (Rob).
  - The wobble line reads "HOP THE RAILS: B" (Hal's rewrite).
- **Off-Leash:** "B ON ANY ! = SAFE DODGE / LATER B = MORE PTS: RISKY!" is "the best intro line in the game" (Marcus, Kenji). Dana's same 22 f reflex went from bronze to silver.
- **Ties:** in 2P TTC with identical hands, both players got gold and the podium read "CO-CHAMPIONS OF TORONTO" (Hal: "the best tie screen I've seen in this genre").

## Hidden tricks by hand

| Event | Landed by | Missed by | Notes |
|---|---|---|---|
| Off-Leash | Rob (1st try), Lena (1st), Kenji (7), Gord (2 of 4), Mo (~13) | Priya, Dana, Hal | The glow says *when*. Nothing says *which way* (hold toward the dog). |
| Bike | Lena (3 of 5), Priya (2 of 3), Mo (4th try) | Marcus 0/5, Hal 0/8, Tasha, Kenji, Gord | The spark is "the best new tell" (Lena, Kenji, Priya). It says *when* but not *what*: the trick looks exactly like a TRACK HOP until it pays (Gord, Hal). |
| Parking | Mo (1st try) | – | The DING bubble works. |
| Tallboy | Dana (by accident) | Rob 0/8, Gord | Rob held B *in the red*. The meter's gold cell doesn't say "sip now". The honk confused him. |
| Bay | Rob, Gord (by accident) | Priya, Lena | The yellow-! burst reads in the demo. |
| Regatta | nobody | Rob, Lena, Priya, Dana, Mo | Round 9's recipe is gone. Dana: the HUD's HIKE blink comes with TACK NOW!, too late for 22 f. |
| TTC | nobody | Mo 0/3 | Rarely attempted. |

Kenji's summary: **"The spark says now. Make the rails say where."** A tell now shows *when* a trick is possible. The next step is a tell that also shows *what to do*: a direction, a pose, a ghost of the move.

## Problems, ranked

**Major (5):**
- **Bike: the crossing rails aren't drawn** (pt3r10-bike-71345345, pt7r10-bike-71361734). HOP THE RAILS: B! and RAIL WOBBLE fire over plain asphalt. Priya: "Hop the rails! …which rails?"
- **Regatta: the coach's WAIT covers the whole tight-rounding window** (pt8r10-sail-71407026). Turning at +28 f pays +300. Obeying NOW (+34 f and after) never does. The coach doesn't teach its own top move.
- **TTC: tapping on the flash at 12 f still loses** (pt5r10-ttctap-72122001). It costs 18 germs (−720) for one GOLD SURF (+225). Lena's hold script also dropped from 3642 to about 1000, because the new track joints jolt the dot.
- **Parking: "NOW! ROLL TO ▼+◀" shows for about 8 f, then flips back to KEEP HOLDING** (pt1r10-park2-72273650). Obeying at 22 f gets "TOO SOON!". It happened on every spot.

**Minor, by theme:**
- **The "+ TIME" subtotal row** (7 testers: pt10r10-sail-37057953, pt8r10-sail-36978487, pt1r10-bike2-71836713, pt2r10-card-72039737, pt3r10-bay-71529428, pt6r10-bike-71436506, pt6r10-bay2-71984794, pt9r10-lb18-72464885, pt10r10-park-72114622).
  - When a board line squeezes the card, "RIDE 1500 + TIME 2020" shows the subtotal, which reads as an addend.
  - The itemised form ("DELIVERY 1500 / 26 SEC AT 20 520") is loved.
  - Marcus: "your best run should get the clearest card, and right now it gets the most squeezed one."
- **OTHER STYLE / ALL THE REST hide named moves** (pt2r10-card2-72077478, pt5r10-bayL2-71999475, pt10r10-pk-72386573). A record run collapses to "OTHER STYLE 4100". Parking's gave-up card calls ONE-MOVE "TIDY PARKING".
  - Dana: "NICE TIMING 1000" after ten +400 popups, because the card rows pay the increment over DODGE (pt1r10-dog-72325479).
- **Off-Leash scale:**
  - A 15 f first try beats the 10200 record (Marcus pt2r10-card2-72205590; curve median 11687). Off-Leash pays 3–4× any other event, so it dominates the SCORE column.
  - Holding ▲ and tapping B blind every 2 s scores 7860, silver (Mo pt10r10-park-72117965).
- **Bay:**
  - Blind lane-weaving pays: 1825–1895, against 1015 for a careful straight walk (Priya pt3r10-bay-71750950, Rob pt4r10-bay-71660361).
  - Arrow-followers still go DECAF (Lena pt5r10-bayL1-72131511; Marcus's whole party).
  - The missed-train reason is always "ON THE DOTS" (Mo pt10r10-bay-71891391).
- **Regatta coach:**
  - "TAP 4" turns into "5 MORE" (Priya pt3r10-sail-71762277).
  - "GOOD! HOLD YOUR COURSE" is followed by DRIFTED! (Tasha pt8r10-sail-71463475).
  - "AGROUND! TAP ▶" gives no count (Hal pt9r10-sag-72481431).
  - One tap at the gun drifts round mark 1 for 264 (Kenji pt7r10-sail-71665051).
- **Bike:**
  - A second bike-lane car arrives unannounced (Gord pt6r10-bike-71362170).
  - The record is 95% of the best bot (Rob pt4r10-i-bike-71665890).
  - The sidewalk sprite still crosses the card border on WIPED OUT (Kenji pt7r10-bike-71676888).
- **Tallboy:**
  - A blind tapper's floor fell from 1281 to about 370 (Priya pt3r10-cops-71748076).
  - An early hop gets no TOO EARLY line (Dana pt1r10-cops-72338192).
  - The trick fails by hand (Rob pt4r10-cops-71666523).
  - Expert/human is 3.6× (Hal).
- **Copy:** "NOW! IN THE PANEL: ▼+◀" (6 testers), "GAGS RIDDEN", "LUCKY SIPS", "MARK 1 ROUNDED! WAIT…" (wait for what?). The README still lists ▼ brake for Bike, and FETCH is +300 in the game but +100 in the README.

## Copy

Clarity averages 8.5/10. The lines testers loved:
- "TACKLED! −1 ♥. SO FRIENDLY"
- "B ON ANY ! = SAFE DODGE / LATER B = MORE PTS: RISKY!"
- "DOCKED EARLY: 250 A MARK"
- "STYLE PAYS AT THE LINE"
- "BRUSHED PAST! SORRY!" (Gord: "the game said SORRY for me. That's Toronto.")
- "CO-CHAMPIONS OF TORONTO"

## Mastery

- **Expert/human (bots):**

  | Event | Ratio |
  |---|---|
  | Bike | 1.8× |
  | Bay | 1.8× |
  | Off-Leash | 1.2× (2.05× best vs human) |
  | Tallboy | 1.9× (3.6× best vs human) |
  | Regatta | 1.6× |
  | Parking | 1.7× |
  | TTC | 2.2× |

  Every curve finishes 100% of runs.
- **By hand:**
  - Off-Leash has the clearest ladder: DODGE 300, NICE 400, CLOSE SHAVE 500, then the trick at 600, all reactable (Rob, Priya, Dana: 7525 → 9075).
  - Regatta's top end hides behind the WAIT (Tasha: 2535 obeying, 2850 for style; Hal 1.1× by hand).

## Next sprint

1. **Tells that say *what*, not just *when*.** For every trick, the warning shows the move:
   - Off-Leash: the dog's glow flashes an arrow toward him.
   - Bike: draw the crossing rails and the transfer line; the spark points at the far rail.
   - Regatta: a visible cue inside a window the coach doesn't talk over.
   - Tallboy: the gold cell says SIP, the honk says STOP.
   - TTC: the gold gesture works at 12–15 f.

   Acceptance test: a bot that only *sees* the tell, with no recipe, finds the input by trying ≤ 5 variants.
2. **Draw Bike's crossing rails** where HOP THE RAILS fires (two majors).
3. **The coach never talks over the window it's coaching:**
   - Regatta's NOW lands inside tight-rounding timing.
   - Parking's NOW! stays up until obeyed, without flipping back.
   - TTC tapping beats holding at 12–15 f, and holding survives the jolts.
4. **Cards: the best run gets the clearest card.**
   - Base rows always show "1000 + 26 S AT 20 = …", never a bare subtotal.
   - No OTHER STYLE when a named move scored; drop a stat or the board line first.
   - Row values match the popups.
5. **Balance:**
   - Off-Leash's scale comes down, or its record goes up to ~75% of best, with no blind metronome silver.
   - Bay blind weaving shouldn't pay, and arrow-followers shouldn't all go DECAF.
   - Tallboy's blind floor goes back up.
   - Lower Bike's record.
6. **Copy:**
   - "IN THE PANEL", the AGROUND count, "TAP 4 → 5 MORE", "WAIT…", "LUCKY SIPS", "GAGS RIDDEN".
   - README: Bike brake, FETCH.
