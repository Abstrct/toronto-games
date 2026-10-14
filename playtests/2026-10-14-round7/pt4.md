# pt4 Rob (score attack / TAS), round 7

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7:**
- overall 5 → 7 → 7 → – → 8 → 8 → **8.5**
- vs California Games 5 → 6 → 7 → – → 7 → 7 → **8**
- Bike 6→7→8→–→8→8→8 · Bay 6→6→8→–→8→8→8 · Off-Leash 4→6→8→–→8→6→**8** · Tallboy 3→7→7→–→7→7→**8** · Regatta 7→7→6→–→7→7→**8**
- Parking 4 → – → 7 → 8 → **7** · Subway 4 → – → 7 → 8 → 8

Best (my TAS sweeps) / record / ~15-frame human bot:
Bike 8602 / 6000 / 3530–3670 · Bay 4630 / 3000 / 1840–1910 · Off-Leash 11650 / 8000 / 2985–3645 · Tallboy 7893 / 5800 / 1820–2090 · Regatta 5220 / 3900 / 2255–2340 · Parking 5645 / 4200 / 4147–5645 · Subway 8501 / 6100 / 3780–3890

## 1. My round-6 complaints
- Off-Leash dawdle farm [major]: **fixed**. A 30–45% walk now times out for 300–450: "OUT OF TIME!", "FORFEIT DOGS 9050", "NO DUNDAS, NO DOGS!". Full speed is the best policy on all 4 seeds (best 11650; a 60% walk finishes for ~9800). Verify: GONE.
- Regatta record at 95% of the ceiling: **fixed**. 3900 is 75% of 5220 over 160 expert runs.
- Regatta COURSE line: **fixed**. The card now reads "TIME LEFT 68 / COURSE 1000+15/S 2020". That's my rewrite.
- "75 FOR EVERY TENTH" vs 498: **fixed** ("WALK 50 A TENTH 400").
- Tallboy plateau: **better**. The top is 7786–7893 (record 5800 = 73%). Several configs still tie at 7786, but my round-6 inputs now score 7893, so the top isn't a hard cap.
- Parking top near-fixed: **unchanged**. Experts score 5549–5645 by seed, and park_human equals park_expert on 3 of 4 seeds. BMW pin: not retested.
- Bike card sum: **better**. It adds up, but see the RIDE line below.

## 2. Regressions and new issues (no crashes or desyncs in ~400 bot runs)
- [minor] **pt4r7-biketas-504901**: Bike STYLE hard-caps at exactly 5000. 27 of 108 stylist configs hit 5000, and the top ties at 8602 with tokens as the only tiebreak. The card prints "STYLE 5000" like any other number, so a player chaining X8 past the cap never learns those tricks paid nothing.
- [minor] **pt4r7-cops-74429**: Tallboy. When I'm stopped dead on the first crates (~35 frames), the only coach line is "COP CAN'T SEE YOU: HOLD B!". It never says to press A to scramble. Then "OOF! SPILLED! HE'S GAINING".
- [note] The Bay best card drops the SPILLS count row when the NEW TORONTO RECORD lines need the space, but still shows "- SPILLS 40 EACH 40".
- [note] Bike Y isn't on the card, but tapping it every 40 frames cost the pro bot 300 style. It's probably an alias for B, so it's harmless.

## 3. Copy: 8.5/10
**Clear:** "OOPS! NO DOG THERE" (I pressed B too early, as a first-timer would), "SET! YOU STEP AS HE LUNGES", "NICE TIMING! +200" (I got it on both timings I tried, so pt2's round-6 complaint looks fixed), "SIP 'N' HOP! +24 / 8 X3 DEAD ON" (the whole formula in two lines), and "NO DUNDAS, NO DOGS!" (best fail line in the game). Every card I checked adds up.
**Unclear:** "COP CAN'T SEE YOU: HOLD B!" while I'm stuck. "RIDE 1562+20/S": why 1562? It reads like a typo next to Bay's 1000 and Regatta's 1000. "DEAD ON! B MID-AIR PAYS X3" shows after you've landed, so it reads as a tip for next time, which is fine once you know.
**Rewrite:** while stopped against a hurdle, "STUCK! TAP A TO SCRAMBLE" outranks the sip tip.

## 4. Mastery
I played Tallboy twice by hand. As a first-timer: no hop, so I sat on the crates being told to drink, then spilled. A tap at +200 frames was 12 frames early and I landed on the crates. Going for style: the tap at +212 gave "DEAD ON THE CHALK! +29", and B mid-air gave a SIP 'N' HOP worth +24 (8 × X3). That's a ~12-frame window between a spill and the top tier, which a practised human can hit. No frame-perfect inputs are needed.

**Does skill show in the score?** Yes. Expert over the 15-frame human: Tallboy 4.4x (1805 → 7893), Off-Leash 3.2–3.9x, Bike 2.4x, Bay 2.4x, Regatta 2.3x, Subway 2.2x. Tallboy and Off-Leash are now steeper than the team's ~3x guideline. **More than one thing to master?** Regatta yes: tight roundings in a chain, clean tacks, the ferry surf, and the hidden roll tack. Tallboy yes: chalk timing, BUZZ budgeting, sipping out of the cop's sight, and double-value bins. Off-Leash leans on one skill: dodge timing alone moves the dog total from ~4500 to ~9900. Parking is still one fixed line.

**Hidden tricks.** Regatta's ROLL TACK. Honestly, I didn't discover it by playing. I read it in the commit log and the bot's docstring before I'd found it, so I can't judge whether it's discoverable. I measured its value: expert with roll tacks gives a median of 5005, without them 4340 (+665, about 15%; 80 runs each). That's a well-sized secret. In the other six events, tapping X, Y, L, R, SELECT and L+R during an expert run changed nothing beyond the documented binds. I didn't find their tricks.

## 5. Report
1. Rob, TAS and score-attack player, ex-footbag leaderboard.
2. 8.5/10: the round-6 exploit is gone, and every record now sits at 65–75% of my best. vs CG 8/10.
3. Bike 8 (style cap) · Bay 8 · Off-Leash 8 (finishing pays, dogs still 85% of the score) · Tallboy 8 (open top, bad stuck coaching) · Regatta 8 (roll tack is real depth) · Parking 7 (one line, the human bot equals the expert) · Subway 8.
4. Loved: "FORFEIT DOGS / NO DUNDAS, NO DOGS!"; the Regatta card; the SIP 'N' HOP formula popup.
5. Problems: Bike style cap [minor] pt4r7-biketas-504901; Tallboy stuck coach [minor] pt4r7-cops-74429; Parking top near-fixed [minor]; Tallboy expert/human 4.4x [note]; Bay card SPILLS row [note].
6. California Games showed you the trick on the leaderboard screen. Nothing here hints that a hidden technique exists.
7. More Toronto: make Parking's hidden trick a "Green P hustle", a reverse in one swoop for a bonus with no lamps lit.
8. "Round 6 paid me to lose. Round 7 makes me pay for it, which is right."

## 6. Is it as good as California Games yet?
Nearly. Every record is a fair target now, and no cheese beats honest play. The biggest thing in the way is that Parking's top end is one fixed line (5549–5645 on every seed, and the human bot equals the expert), so it gives a score-attacker nothing to chase.

pt4 · no pkill · ~70 harness/sweep commands.
