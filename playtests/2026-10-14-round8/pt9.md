# pt9 Hal (tournament host), round 8

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8:**
- overall 5 → 6.5 → 7 → 7.5 → 8 → 8 → 8 → **8.5**
- vs California Games 5 → 6.5 → 7 → 7.5 → 8 → 8 → 8 → **8.5**
- Bike 6 → 6.5 → 7 → 7 → 7.5 → 8 → 8 → **8** · Bay 6.5 → 7 → 7.5 → 7.5 → 8 → 8 → 8 → **8** · Off-Leash 5 → 6.5 → 6.5 → 6.5 → 7 → 7 → 7.5 → **7.5** · Tallboy 3 → 7.5 → 7.5 → 7.5 → 7.5 → 7.5 → 7.5 → **7.5** · Regatta 3 → 4 → 5 → 6.5 → 6 → 6.5 → 6.5 → **7.5**
- Parking 6.5 → 6 → 7.5 → 7.5 → 8 → **8** · Subway 5 → 7.5 → 8 → 8 → 7.5 → **8.5**

I'm Hal. I've run California Games brackets at conventions, and I judge whether strangers can play this fairly in turns.

## 1. My round-7 complaints
- **Regatta first-timer cliff (pt9r7-sail-999912881, major): FIXED.** I played by hand as a slow first-timer. I filmed between moves, so I often answered the coach 1–3 s late, and once I skipped an order entirely. I still finished with 41 s left for **2315**. Last round I got 459. Mark 1 gave TIGHT ROUNDING +500, and both tacks at ~6 taps a second gave CLEAN TACK +100. After a completed order the box now reads "GOOD! HOLD YOUR COURSE", which is the rewrite I asked for. The coach bots (coach, obey, dana) all finish at 2300–2400 with sd ≤ 264.
- **Hull over mark 2's ring doesn't count (pt9r7-sail2-374228): BETTER.** The hull crossed the top of the dotted ring and the mark counted, about 50 frames after the overlap. That's readable from the couch.
- **TTC 2P luck (pt9r7-2p-327091): FIXED.** In a 2P competition I gave both players identical scripts. Regatta came out 2315/2315 and TTC 240/240, each run exactly 3737 frames long. The podium read "CO-CHAMPIONS OF TORONTO / TIED ON 10 PTS AND MEDALS", which is exactly right.
- **Bike "NOT PAID!" under a score (pt9r7-bike-364265): FIXED.** The card now reads "THIRD WIPEOUT. NO DELIVERY / PAID FOR THE RIDE ONLY", with FORFEIT STYLE 60 in grey. `--verify` still reports this finding PRESENT, but only because my old condition was just "score = 279".
- **Score scales across events: UNCHANGED.** The records run from Bay's 3000 to Off-Leash's 8500, and park_ace scores 12362. That's cosmetic unless the final table's SCORE column breaks ties.
- **Parking HALF IN cliff:** not retested this round.

## 2. Regressions and new issues
- **[minor] pt9r8-sail3-11884256:** the first half of a long turn leaves a slow reader head-to-wind with an empty SPD bar. It happened on two separate turns. Then "GOOD! TAP ▶ 3 MORE TIMES" changed to "MARK 3! NOW TAP ▶ 4 TIMES" without my tapping, while the HUD read TO LINE!, about 8 s after mark 3.
- **[minor] pt9r8-sail-11893932:** the Regatta card itemises TIGHT ROUNDING 500 and then lumps the rest into "+ STYLE 700". The two CLEAN TACKs aren't listed, so a judge can't check the 700.
- **Off-Leash sloppy turns are a coin flip (bot data, not filed).** Over 12 runs, park_sloppy gave median 4762, min 0 and sd 1937. Two runs were tackled out for 0, and the rest beat the careful leash_human (3618). In a bracket, one bad dog can decide a heat.
- No regressions found in menus, the hand-off guard ("HAND THE PAD TO PLAYER 2" ate my mashed A) or the tie logic.

## 3. Copy: 8.5/10
**Clear:**
- "GOOD! HOLD YOUR COURSE"
- "ZIG-ZAG UP: I'LL CALL TACKS" (replaces the confusing "WAIT FOR TACK NOW")
- "PASS CLOSER = TIGHT ROUNDING"
- "THIRD WIPEOUT. NO DELIVERY"
- "20 GERMS: STYLE IS VOID / ONLY LEGS YOU LEANED PAY"
- "SO LONG, SEAGULL!"
- The Regatta intro card is five clean lines.

**Unclear:**
- "MARK 3! NOW TAP ▶ 4 TIMES" under a HUD that reads TO LINE!
- "+ STYLE 700" with only part of the style itemised.
- The final table has a SCORE column (2555), but nothing says whether it breaks ties after points, golds and silvers. I'd want to know before I run a bracket on it.

**Rewrite:** "TO THE LINE: 3 MORE TAPS ▶", kept on screen until the taps are done.

## 4. Mastery
**Reaction speed, bot medians at 8 f vs 18 f:**
- Off-Leash: ~9100 vs 4990 (1.8×)
- Tallboy: ~4600 vs 3072 (1.5×)

**Style ceilings, human bot vs best bot (n = 6):**

| Event | Human | Best | Spread |
|---|---|---|---|
| Bike | 3408 | rider 8617 | 2.5× |
| Bay | 1953 | ear 4072 | 2.1× |
| Off-Leash | 3817 | ace 12362 | 3.2× |
| Tallboy | 2691 | pro 8349 | 3.1× |
| Regatta | 2631 | expert 4928 | 1.9× |
| TTC | 3928 | ace 8466 | 2.2× |
| Parking | 5209 | expert 6407 | 1.2× (coach-only play scores 2631) |

Skill shows up the way it did in California Games, a bit steeper at the top in Off-Leash and Tallboy.

**My Regatta, played twice:** first-timer 2315. A replay of the same run gave 2315 in competition. expert is 4928, so there's room above me.

**More than one thing to master?**
- Regatta: tight roundings, brisk tacks, hiking, ferry surf.
- Bay: beat, lanes, PRESTO.
- Parking: still one thing, timing.

**Hidden tricks.** I found these by watching the title demos, not by my own play:
- **Bike:** "TTC TRANSFER! +120"
- **Off-Leash:** "OLE! MATADOR! +550" (later "X3!! +650")
- **Tallboy:** "LIQUID COURAGE! +630"
- **Bay:** "PRESTO \*BEEP\*! COMBO UP" also gets WATCH THAT MOVE!, but the Bay card already says "Y GOLD = PRESTO", so either it isn't hidden or the real trick is something else.
- Regatta, Parking and TTC: my samples missed their banners.

I didn't reproduce any of them by hand, so I can't say how each is done.

## 5. Report sections
- **Overall 8.5/10:** every event is now fair to a stranger. **vs CG: 8.5/10.**
- **Per event:**
  - **TTC 8.5:** same train for everyone, and ties come out exact.
  - **Bike 8:** honest card.
  - **Bay 8**
  - **Parking 8:** the top is flat.
  - **Regatta 7.5:** first-timers finish now, but the coach still stalls slow readers mid-turn.
  - **Off-Leash 7.5:** the sloppy coin flip.
  - **Tallboy 7.5:** 6× between rookie and pro.
- **Turn lengths:**
  - Parking 26–30 s
  - Regatta finishes 20–26 s for bots, 49 s for my slow run
  - Off-Leash 39–65 s
  - Bay 42–63 s
  - Bike 51–56 s
  - TTC 62 s
  - Tallboy 63–68 s
  - A 4-player all-events night runs about 30 min of play.
- **Loved:**
  1. Co-champions on the podium.
  2. The Regatta coach finally lets a first-timer finish.
  3. The mashed-A guard on hand-off.
- **Top problems:**
  1. Off-Leash 0-or-5000 sloppy variance (bot data)
  2. [minor] pt9r8-sail3-11884256
  3. [minor] pt9r8-sail-11893932
  4. The tiebreak by SCORE is unstated
  5. Parking's flat top
- **CG had:** a scoring scale players could compare across events.
- **More Toronto:** the ferry horn for the Regatta gun.
- **Quote:** "Two players, the same thumbs, the same score. That's a tournament."

## 6. Is it as good as California Games yet?
**For running a bracket, yes, now.** The biggest remaining thing is Off-Leash's cliff. One late B can take a competent turn from about 4500 to 0, and that decides heats more than skill does. Pay a partial walk on a slope, the way the Bike now pays for the ride.
