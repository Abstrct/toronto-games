# Toronto Games: playtest round 6, 2026-10-14

The same ten testers played the build after sprint 5. What changed in sprint 5:
- **Result cards:** honest penalty cards ("SCORES NEVER GO BELOW 0"), per-event finish headers and rates, and a Bike forfeit row.
- **Regatta:** ADRIFT now means no progress, bumps cost time, there's a pin arrow plus green diamonds, and the coach gives tap counts.
- **Events:**
  - Bay: big dots make the train.
  - Off-Leash: a SAFE/BOLD ladder.
  - Tallboy: a chalk × chain × BUZZ budget.
  - Parking: an unstick coach.
  - TTC Surfing: gags and an open top.
  - Bike: no pothole conveyor.
- **Presentation:** one callout panel style everywhere, and Regatta's music is louder.

The build under test was frozen as `build/pt/panel6` (tag `panel6`). Testers filed 40 findings: 9 major, 26 minor and 5 notes
(`build/pt/panel6/pt findings --file build/pt/findings_round6.jsonl`). Seven of the nine majors are Regatta's.
Per-tester reports are in `playtests/2026-10-14-round6/`.

## Scoreboard (round 5 → 6; full histories in each report)

| Tester | Overall | vs CG | Bike | Bay | Off-Leash | Tallboy | Regatta | Parking | Subway |
|---|---|---|---|---|---|---|---|---|---|
| Dana, beginner | 7 → **8** | 6 → **7** | 4 → **6** | 6 → 7 | 8 → 7 | 5 → **8** | 6 → 6 | 5 → **4** | – |
| Marcus, party | 7.5 → 8 | 7.5 → 7.5 | 5.5 → 6 | 6.5 → 7.5 | 7 → 7.5 | 6 → 6.5 | 4.5 → 4.5 | 8 → 8 | 6 → 6 |
| Priya, YouTuber | 7.5 → 8 | 7 → 7.5 | 7 → 7 | 7.5 → 7.5 | 6.5 → 7 | 7 → 7 | 6 → 7 | 7 → 7.5 | 7 → 7 |
| Rob, TAS | 8 → 8 | 7 → 7 | 8 → 8 | 8 → 8 | 8 → **6** | 7 → 7 | 7 → 7 | 7 → 8 | 7 → 8 |
| Lena, designer | 8 → 8 | 7 → 7 | 8 → 8 | 7 → 8 | 8 → 8 | 7 → 7 | 5 → 5 | 8 → 8 | 7 → 7 |
| Gord, Torontonian | 7 → 7.5 | 6.5 → 7 | 6 → 6.5 | 6 → 7.5 | 7 → 7 | 7 → 6.5 | 6 → 6 | 5 → 7 | 7 → 7.5 |
| Kenji, art/audio | 8.5 → **9** | 8 → **8.5** | 8.5 → 9 | 8 → 8.5 | 7.5 → 8 | 8.5 → 8.5 | 7.5 → 7 | 7.5 → 8 | 8 → 8.5 |
| Tasha, completionist | 8 → 8.5 | 7.5 → 8 | 6.5 → 6.5 | 6.5 → 7 | 6 → 6 | 5.5 → 5.5 | 5.5 → **7** | 7 → 7.5 | 6 → 6 |
| Hal, tournament | 8 → 8 | 8 → 8 | 7.5 → 8 | 8 → 8 | 7 → 7 | 7.5 → 7.5 | 6 → 6.5 | 7.5 → 7.5 | 8 → 8 |
| Mo, QA | 7.5 → 8 | 7 → 7.5 | 8 → 8 | 6.5 → 7 | 6.5 → 7 | 6 → 6 | 5 → **7** | 6.5 → 7 | 6.5 → 6.5 |
| **Average** | **7.7 → 8.1** | **7.2 → 7.5** | 6.9 → **7.3** | 7.0 → **7.6** | 7.2 → 7.1 | 6.7 → **7.0** | 5.9 → **6.3** | 6.9 → **7.3** | 6.7 → **7.2** |

**History:**

| Round | Overall | vs California Games |
|---|---|---|
| 1 | 5.6 | 5.0 |
| 2 | 6.7 | 6.2 |
| 3 | 7.1 | 6.6 |
| 4 | 7.9\* | 7.4\* |
| 5 | 7.7 | 7.2 |
| **6** | **8.1** | **7.5** |

\* Round 4 is only the four testers who finished it.

**Highlights:**
- **The game passes 8/10 for the first time, and every tester is at 7.5 or above.**
- **Kenji gives 9** (8.5 against California Games): *"one panel style, cards that add up, songs at matched levels."*
- **Dana gives 8** and medalled three times: *"I've never done that before."* She delivered on Bike for the first time in six rounds.
- **Event averages:** six of the seven are 7.0–7.6. Regatta (6.3) is still last, but rose again.
- **Off-Leash slipped** (7.2 → 7.1) on Rob's timeout farm and Dana's missed bronze.

## Is it as good as California Games yet?

Hal and Kenji say yes or nearly (8 and 8.5), and Hal says it is *"yes on six events"*. The other eight say "close" or
"nearly". Their single biggest blockers:

1. **Regatta's coach can end your race** (Lena, Hal, Marcus, Mo, Dana, Kenji; 7 major findings).
   - Following the tap counts can steer you along a mark's ring without it counting, onto the beach or onto the
     docked Ward's ferry, or head-to-wind on a pin.
   - ADRIFT then ends the race: "10 S GETTING NO CLOSER", with a 1–2 s warning.
   - Bump popups (GOOSED, AGROUND, GUST) replace the tap count exactly when it's needed.
   - Lena: *"California Games never let its own hint kill you."*
   - Six testers propose the same fixes:
     - inside two boat-lengths of the ring, drop the tap counts ("RING AHEAD! HOLD YOUR COURSE");
     - make ADRIFT need near-zero speed, or a much longer, counted-down warning;
     - push the boat off the ferry the way the shore does;
     - give one instruction per tack.
2. **Off-Leash rewards the wrong things.**
   - Rob: timing out keeps every dog, so a dawdle at 30% walking speed sets the record ("OUT OF TIME!" … "NEW TORONTO RECORD!").
   - Dana: a flawless safe run (9 dodged, 0 tackles) misses bronze by 110, and the SAFE line "feels like a trap".
   - Marcus: the bold window is invisible, because nothing on screen marks the lunge.
3. **Depth the coach doesn't hand you** (Tasha, Mo, Gord).
   - The coaches now teach every trick, so an expert pulls away mostly by reacting faster.
   - Tallboy and Regatta show almost no gain from faster reactions: 6 f vs 15 f is 2128 vs 1958 in Tallboy, and 3030 vs 3260 in Regatta.
   - Bike makes you survive before you can style.

## What got fixed (round-5 complaints)

**Cards:**
- Off-Leash and Regatta 0-cards show the real sums.
- Bike shows a grey FORFEIT row.
- The finish headers are loved: "MADE THE 5:42!", "UNION! EVERYBODY OFF!", "THE RCYC BAR IS OPEN!".
- "NO LEANING, NO POINTS" appears, and PATIENT ZERO shows only once.

**Events:**
- **Bay:** the card teaches DOUBLE TIME, and big dots make the train (all ten agree).
- **Regatta:**
  - No free mark.
  - The arrow sits over the mark.
  - Flailers now end at 13–17 s instead of 92 s.
  - Mo and Tasha finished first try following the coach. Mo had quit for 79 in round 5; Tasha won silver.
- **Off-Leash:** a blind B rhythm now gets tackled out.
- **Tallboy:** the one-trick top is gone (BUZZ budget, DEAD ON).
- **TTC Surfing:** the top is open (8010–8086, no ties).
- **Parking:** the attract demo, the spot-3 bell order, the quit card, the itemised box and the fades.
- **Bike:** a careful rider delivers.

**Menus and presentation:**
- **Menus:**
  - REMATCH is the default.
  - Hand-overs say "HAND THE PAD TO…".
  - Mashing never locks a card.
  - The roster cursor works, and B returns to the event list in Practice.
- **Presentation:** one callout style everywhere, and every song sits at −16 to −18 dBFS.

## Problems, ranked

**Major:**
1. **Regatta coach and ADRIFT.** Findings: pt9r6-sail-989879571, pt5r6-adrift-990059561, pt2r6-party-991169431,
   pt1r6-sail-991903771, pt7r6-sail-991962863 and pt5r6-sail-990007861 (ferry pin).
   - The coach steers past the ring, onto the shore or onto the ferry, or into irons.
   - Its counts get replaced or contradicted mid-tack.
   - ADRIFT fires with ~1–2 s of warning while the player obeys.
2. **Off-Leash timeout farm** (pt4r6-leashdawdle-991404677). Dogs keep arriving and a timeout keeps them; DOGS is 94%
   of a top score.
3. **Off-Leash safe run misses bronze** (pt1r6-park2-990292909). The record moved to 6000, so bronze is 2000, and a
   perfect safe walk scores 1890.
4. **Parking swing with no let-go cue** (pt1r6-pk-992068943, Dana). "HOLD DOWN+LEFT: SWING IN" stays up until the
   curb and the sidewalk. Priya found the reverse: "LET GO! STOP ON THE LINE" arrives ~15 f before the line, a
   regression from round 5 (pt3r6-pk-990182475).

**Minor, grouped:**
- **Regatta:**
  - "ALL 3! NOW CROSS THE LINE!" doesn't say where. Tasha sailed along the line and it didn't count.
  - The record (4500) is 95% of Rob's best.
  - "COURSE +25 A SEC" hides the 1000 base, and the card has no TIME LEFT row.
  - A goose sits on mark 1's exit.
  - Empty callout panel flashes.
  - TIGHT ROUNDING arrives late.
  - "MARK 2 IS UPWIND: ZIG-ZAG!" doesn't say which way.
  - Expert scores swing 3295–5675 by seed (Hal).
- **Off-Leash:**
  - "75 FOR EVERY TENTH WALKED" over CROSSING 261 / 315 / 498, which aren't multiples (five testers).
  - "THIRD TACKLE ENDS THE WALK" over 4 tackles (600).
  - The practice card loses the TACKLES row.
  - Idle reads "CALLED IT A DAY".
  - Hearts stay ♥♥♥ after the third tackle.
  - Mashing B is an 85 s turn for 0.
  - "SAFE: … 50" (50 what?).
- **Bay:** lane dodging is optional. Spills stop at 8 (DECAF) and DECAF does nothing visible, so a no-dodge DOUBLE TIME walk
  goes #4 on the board (Mo, Tasha, Priya). PRESTO is never explained. The HUD's DECAF clashes with "SO LONG, DECAF!".
- **Bike:**
  - −200 per wipeout on a delivered run isn't on the card or in the manual.
  - TIPS vs TOKENS.
  - "FORFEIT TIPS, STYLE 100" reads as style = 100.
  - "SPLAT!" doesn't say what you hit.
- **Tallboy:**
  - The hands-off card says "COP CAUGHT YOU: FINED 1/4" on 0 with no fine row.
  - The popup says "YOU KEEP 3/4" while the card says "FINED 1/4".
  - "SCRAMBLE! A AT THE CHALK" is ambiguous.
  - Two-line panels have no leading.
  - The plateau: 144 of 648 expert configs tie at 4670.
- **TTC:** LEGS LEANED over-counts (1 leaned → 2), GERMS shows 21 vs "20 GERMS", and "GOLD DOT ALL LEG: SURF X3" reads as broken English.
- **Parking:** the BMW pin is still reproducible; the spot box is still 4 rows at 8 px; pressing A on the box says "THAT'S NOT A SPOT!";
  a crooked car scores ANGLE GOOD and still renders smeared; TIME LEFT is fractional.
- **Menus:**
  - B on the roster asks "LEAVE AND LOSE 8 PLAYERS?" with YES under A (pt10r6-menu-990661906).
  - "PLAYER 2 0 0 0" reads as "PLAYER 20".
  - The podium names only the champion.
- **Audio:** the DC offset has grown (Regatta −4.6k, ADRIFT alarm −8.4k), and stopping a song thumps (Kenji). No result jingle,
  and no podium swell (Priya).
- **Harness:** the Parking human and expert bots play identical runs (Rob). Several findings' `-c` conditions are bare
  scene checks, so `--verify` can't tell a fix.

## Copy

Clarity averages **8.0/10** (7.5–8.5).

The winners are the coaches and the headers:
- Parking's chain: "GAS ▲: REAR BUMPER TO LINE" → "NOW! ROLL TO DOWN+LEFT" → "STRAIGHT! LET GO TO STOP".
- Off-Leash's "SAFE / BOLD" lines and "SET! YOU STEP AS HE LUNGES".
- Bay's "SMALL DOTS = DOUBLE TIME".
- "CAR IN BIKE LANE. AGAIN."
- "HANDS OFF THE HELM PAYS 0".

The jokes keep landing: "IT'S DUNDAS, BUD", "TACKLED −150 (HE'S FRIENDLY)", "OOF! RACCOON STOLE THE CAN".

What's left is lines that disagree with the number next to them (75 a tenth, FINED 1/4 on 0, LEGS LEANED, GERMS 21),
and Regatta coach lines that point the wrong way.

## Mastery

The testers agree skill now pays:

| Event | First go | Skilled play | Ratio |
|---|---|---|---|
| Bay | 344–1150 | 1454–1921 (DOUBLE TIME) | 1.7–4.2× |
| Tallboy | 1470 (chalk only) | 2518 (with sips) | 1.7× |
| Off-Leash | 1890 (safe) | 2625–2695 (bold) | 1.4× |
| Parking | +369 per spot | +1437 per spot | 4× |

Rob's sweeps put the expert at 1.8–3.3× an average human everywhere.

The gaps:
- **Regatta** has no reachable top for a human.
- **Bay's** second skill (dodging) doesn't count.
- **Off-Leash's** bold window is invisible.
- **Tallboy and Parking** plateau at the very top.
- **The coaches teach everything**, so nothing is left to discover. Tasha: *"I'd like a trick the coach never mentions."*

## Next sprint

1. **Regatta:**
   - **Fix the coach:**
     - near a ring it says "HOLD YOUR COURSE";
     - it gives one instruction per tack;
     - coaching outranks bump popups;
     - it never gives a count while aground.
   - **Fix ADRIFT:** it needs near-zero speed or a counted-down 5 s warning, and never fires near a mark.
   - **Fix the ferry:** push the boat off it, and keep it clear of mark 3's approach.
   - **Copy and records:** say which way to cross the finish line, lower the record to ~75%, and move the goose off mark 1's exit.
   - **Consistency:** a steadier expert score.
2. **Off-Leash:**
   - A fixed dog schedule, or a timeout that doesn't bank dogs.
   - Bronze within reach of a perfect safe walk.
   - A visible lunge tell.
   - Honest copy (the 75-a-tenth line, the third tackle).
   - An idle reason, and the hearts.
3. **Bay:** make dodging count (DECAF should slow you, spills should keep costing). Teach PRESTO.
4. **Parking:** a let-go cue in the swing, an earlier "LET GO! STOP ON THE LINE", and the BMW pin.
5. **Copy and cards:**
   - Bike: TIPS/TOKENS and the wipeout fee on the card.
   - Tallboy: the hands-off line and 3/4 vs 1/4.
   - TTC: LEGS LEANED, GERMS 20, and the gold-dot wording.
   - The roster's leave prompt defaults to NO.
   - Standings spacing.
   - Name the podium's silver and bronze.
6. **Audio:** high-pass the DC, add a short result jingle, and give the podium a swell.
7. **Depth:** one undocumented trick per event, which the coach never mentions.
