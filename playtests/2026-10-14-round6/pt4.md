# pt4 Rob (score attack / TAS), round 6

**Round 1 → 2 → 3 → 4 → 5 → 6:**
- overall 5 → 7 → 7 → – → 8 → 8
- vs California Games 5 → 6 → 7 → – → 7 → 7
- Bike 6→7→8→–→8→8 · Bay 6→6→8→–→8→8 · Off-Leash 4→6→8→–→8→**6** · Tallboy 3→7→7→–→7→7 · Regatta 7→7→6→–→7→7
- Parking 4 → – → 7 → 8 · Subway 4 → – → 7 → 8

Best (TAS sweep) / record / ~15-frame human bot:
Bike 7194 / 6000 / 3660 · Bay 4437 / 3000 / 1810 · Off-Leash 9050 honest, **11125 dawdling** / 6000 / 870–3055 · Tallboy 4790 / 3600 / 1460 · Regatta 4730 / 4500 / 2580 · Parking 5237 / 3800 / (me by hand: spot 1 = +369) · Subway 8086 / 5700 / 3820

## 1. My round-5 complaints
- Tallboy 5350 hard cap: **better**. Now BUZZ budgets you to ~18 SIP 'N' HOPs; still a plateau (4670 ties in 144/648 configs, best 4790). pt4r6-copstas-991701365
- Subway 6653 cap, 32/48 ties: **fixed**. Expert 8010–8086 across rides, no exact ties.
- Regatta ferry wait: **fixed**. Ferry leaves on mark 3 and FERRY SURF fires on the racing line; idling 5 s now costs ~450.
- Parking record 91% of ceiling: **fixed** (3800 = 73%). But the problem moved to Regatta (below).
- Parking nose pinned on BMW: **unchanged** (verify PRESENT). By hand I also sat in the hedge with only "INTO THE HEDGE! -100" on the coach line for ~1.5 s.
- Parking quit card DINGS+FINES: **fixed**. "23S LEFT": **fixed** (box now says TIME LEFT +169).
- Bay DOUBLE TIME untaught: **fixed**, with my exact line, "SMALL DOTS = DOUBLE TIME".
- Copy: Tallboy X15 **fixed** ("SIP 'N' HOP! +8 / 8 X1 CHAIN"); Bay WALK **fixed** (TIME LEFT row + "WALK 1000+40/S"); Bike card sum **unchanged**.

## 2. Regressions and new issues (no crashes, no desyncs)
- [major] pt4r6-leashdawdle-991404677: Off-Leash pays you to lose. Walk at 30% duty, time out, keep every dog: "OUT OF TIME!" then "NEW TORONTO RECORD! +2798 OVER DOODLE". 8798 vs 8415 for the honest finish on the same seed; a 45% walk beats full speed on 4/4 seeds (best 11125). DOGS is 94% of the score and dogs come by time. Same policy at full speed ranges 5845–8880 by seed alone.
- [minor] pt4r6-sailtas-991683236: Regatta record 4500 is 95% of my 2916-config TAS best (4730).
- [minor] pt4r6-sailtas-991684733: "COURSE +25 A SEC 2600" hides the 1000 base; no TIME LEFT row.
- [minor] pt4r6-leashdawdle-991686217: "75 FOR EVERY TENTH WALKED" over CROSSING 498.
- [minor] pt4r6-copstas-991701365: Tallboy plateau (above).
- Good news: Bike rail-farming now gets you killed (110–323), no cheese there.

## 3. Copy: 8/10
**Clear:** every intro card is short, and Parking's coach is the best teacher in the game ("KEEP DOWN+RIGHT: GET READY", "NOW! ROLL TO DOWN+LEFT", "STRAIGHT! LET GO TO STOP"); its spot box itemises my hedge (-100) and sidewalk (-100). Jokes land: "IT'S DUNDAS, BUD", "OOF! RACCOON STOLE THE CAN", "PARKED. IT'LL DO.", "THE RCYC BAR IS OPEN!".
**Unclear:** "SCRAMBLE! A AT THE CHALK" (scramble now, or at the chalk?); the Regatta COURSE line; "75 FOR EVERY TENTH" vs 498; Off-Leash calling a timeout a record with "WE THE NORTH!".
**Rewrite:** Regatta card "TIME LEFT 64 / COURSE 1000+25/S 2600".

## 4. Mastery
Tallboy: first go by hand, I hit one SIP 'N' HOP (+8), lost the can to a raccoon, then got BUSTED. The 15-frame bot gets ~1460, the expert 4790: 3.3x, and the top has two skills (DEAD ON chalk timing x3, BUZZ budgeting). Parking: my first spot was +369 (curb, sidewalk, hedge), the expert's +1437, so ~4x, built on four skills (line stop, swing timing, curb kiss, speed). Every event's expert is 1.8–3.3x the human: healthy. Bay and Subway have truly continuous tops. Tallboy and Parking (5232–5238 on every seed) top out at a near-fixed number.

## 5. Report
1. Rob, TAS and score-attack player, ex-footbag leaderboard.
2. 8/10: the round-5 caps mostly opened up and the copy is sharp. vs CG 7/10.
3. Bike 8 (no farm, record at 83%) · Bay 8 · Off-Leash 6 (timeout farm) · Tallboy 7 (a buzz knapsack) · Regatta 7 (ferry fixed, gold too high) · Parking 8 (best coaching) · Subway 8 (open top).
4. Loved: the Parking spot box, the Regatta callout chain (TIGHT X2 +620 → X3 +720 → FERRY SURF → LINE HONOURS), Bay's taught DOUBLE TIME.
5. Problems: Off-Leash dawdle [major], Regatta record [minor], Tallboy plateau [minor], BMW pin [minor], the Regatta COURSE line [minor].
6. California Games never paid you more for failing.
7. More Toronto: Off-Leash dogs that arrive with their owners on a schedule ("THE 6 PM RUSH"), so time spent is a choice and not a farm.
8. "The only record in this build that I'd break by losing is Off-Leash."

## 6. As good as California Games?
Close; Bike, Bay, Parking and Subway hold up. The single biggest thing in the way is Off-Leash: its score is a time-based dog farm that pays a timeout more than a finish.

pt4 · no pkill · about 70 harness commands, counting the sweep scripts. Note for the team: on Parking, park_human and park_expert give identical runs (5237), so the human curve there is measuring the expert.
