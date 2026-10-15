# pt4 Rob (score attack / TAS), round 9

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9:**
- overall 5 → 7 → 7 → – → 8 → 8 → 8.5 → 8.5 → **8.5**
- vs California Games 5 → 6 → 7 → – → 7 → 7 → 8 → 8.5 → **8.5**
- Bike 6→7→8→–→8→8→8→8.5→**8.5** · Bay 6→6→8→–→8→8→8→8→**7.5** · Off-Leash 4→6→8→–→8→6→8→9→**9** · Tallboy 3→7→7→–→7→7→8→8.5→**9** · Regatta 7→7→6→–→7→7→8→8→**8**
- Parking 4 → – → 7 → 8 → 7 → 7 → **8** · Subway 4 → – → 7 → 8 → 8 → 8 → **8.5**

Bots (12 seeds), best skilled / record / human-ish: Bike stylist 8322 (7810–9890) / 7500 / 3171 · Bay ace 3549 / **3300** / 1956 · Off-Leash ace 14073 / **10000** / 3777 · Tallboy pro 8515 / 6300 / 2677 · Regatta 4965 / 3900 / 2743 · Parking expert 6672 (5343–7439) / **5000** / 3321 · Subway 8390 / 6100 / 4176. Cheese still loses: idle, hold, mash and spam score 0–573.

## 1. My round-8 complaints
- Bike seed variance: **better**. The stylist's spread fell from 3260 to 2080 (sd 589), and the 7500 record now sits below the stylist's worst seed.
- Parking's top end was one fixed line: **fixed**. The expert's spread is 5343–7439 (sd 606, was 67), the human bot fell from 5367 to 3321, and the record rose to 5000.
- "HOLD B: SIP, COP CAN'T SEE": **fixed**. The card now says "HOLD B: SIPS PAY UNSEEN".
- Bay's record was too steep: **worse**. It went from 3000 to 3300, which is 93% of bay_ace. The human bot (1956) no longer reaches silver (2200). bay_expert still misses the train (448).
- Off-Leash dogs are 85% of the score: **unchanged**, but walking slowly no longer zeroes you (dawdle30 was 350, now 5171).

## 2. Regressions and new issues
- [minor] **pt4r9-card-bay-21829312**: Bay's record is 93% of the best bot.
- [minor] **pt4r9-gold-21829750**: LIQUID COURAGE says "GOLD 22", and nothing in the game explains GOLD.
- [minor] **pt4r9-rails-21830450**: The RAILS HOPPED window is 21 f (B at +0..+20 after HOP THE RAILS: B!). The manual says half a second.
- [note] **pt4r9-park-21846722**: Off-Leash expert/human is 3.7x, above the 3x target. CLOSE SHAVE/MATADOR can't be hit by reacting to the flash (details below).
- [note] **pt4r9-sail-21846080**: ROLL TACK has no tell. I got nowhere in 10 tries.
- [note] **pt4r9-card-parking-21831152**: The Parking card puts "A TO PARK" before the back-in lines.

## 3. Copy: 8.5/10
**Clear:** "SET! YOU STEP AS HE LUNGES", "RED ! = B NOW FOR +200", "CHALK! B MID-AIR PAYS X2", "DEAD ON! B MID-AIR PAYS X3", "BIT LATE, BUD!", "OOF! RACCOON STOLE THE CAN", "THE WHITE SQUIRREL!" (pure Trinity Bellwoods), "GLIDING IN...", "ZIG-ZAG UP: I'LL CALL TACKS". The Tallboy BUSTED card adds up to the point: 200 + 183 − 95 (FINE IS 1/4 OF RUN+STYLE) = 288. So does the Off-Leash fail card: 200 + 50 − 450, then SCORES NEVER GO BELOW 0, and HEARTS GONE: HALF THE DOGS / DUNDAS PAYS THEM ALL.
**Unclear:** "GOLD 22" (is it a medal? a meter zone?). The Parking card order: "UP TO THE LINE, A TO PARK" then "BACK IN…". "TOO LATE! LET GO OF THE PAD" mid-swing reads like a fail, though the coach then recovers you. The manual still lists ▼ brake for Bike and promises a half-second rail window.
**Rewrite:** "LIQUID COURAGE! +66 / TIPSY 22 X3 DEAD ON".

## 4. Mastery
**Off-Leash dog 1, by hand.** As a first-timer, I pressed B 15 f after the white ! for DODGE +100. Going for style, B between f845 and f892 gives NICE TIMING +200. B between f893 and f900 gives CLOSE SHAVE +400, or **OLE! MATADOR +550** if you hold toward the dog. From f901 you're TACKLED (−150). The dog flashes white from f887 to f892, so if you react to the flash at 15 f you land on f902 and get tackled. You have to count from the red ! instead. An 8 f window learned by count is a real expert skill, and it's not frame-perfect.
**Tallboy, by hand.** The take-off window is now about 28 f with a graded payout: BIT LATE +14…+26, ON THE CHALK +31–38, DEAD ON +39/40 (round 8: a 4 f pass/fail). Then the sip pays its base × chalk (×2 / ×3) × chain. A first-timer gets around +20 a hurdle; the demo's LIQUID COURAGE pays +378 on a single hurdle.
**Expert vs human bot:** Off-Leash 3.7x, Tallboy 3.2x, Bike 2.6x, Parking 2.0x, Subway 2.0x, Regatta 1.8x, Bay 1.8x. Yes, skill pulls away. Every event now has at least two things to master. Parking gained one this round: its top is no longer a single line.

**Hidden tricks by hand (4 of 7):**
- MATADOR: first try. The tell is the white spring flash plus the tag jingle, but you have to count it.
- TTC TRANSFER (+100): first sweep. Steer while you hop, with B 6–14 f after the rail prompt. The prompt is the only tell.
- LIQUID COURAGE: third try. Sip until TIPSY (about three ground sips), then hold B through a hop. The BUZZ meter in the red is the tell.
- LOOK MA, NO HANDS! (+100): landed by accident. After a clean STANDING SURF, I kept hands off the pad during DOORS OPEN.
- ROLL TACK: failed in 10 tries, with nothing to read on screen.
- Bay SLALOM X2 and Parking BIKE SHAVE: not attempted (budget).

## 5. Report
1. Rob, TAS and score-attack player, ex-footbag leaderboard.
2. 8.5/10. The round-8 fixes all landed except Bay, and Tallboy's graded take-off is the best change this round. vs CG 8.5/10.
3. Bike 8.5 (variance tamer; the rail window is tighter than the copy says) · Bay 7.5 (the record is out of reach) · Off-Leash 9 · Tallboy 9 · Regatta 8 · Parking 8 (the top end opened up) · Subway 8.5.
4. Loved: Tallboy's graded chalk; MATADOR riding the CLOSE SHAVE window; THE WHITE SQUIRREL.
5. Problems: Bay record [minor] pt4r9-card-bay-21829312; GOLD [minor] pt4r9-gold-21829750; rail window [minor] pt4r9-rails-21830450; ROLL TACK tell [note] pt4r9-sail-21846080; Off-Leash curve [note] pt4r9-park-21846722.
6. CG's tricks all had a body-language tell. ROLL TACK doesn't.
7. More Toronto: a PRESTO *BEEP* on TTC TRANSFER, and a "MIND THE GAP… WRONG CITY" gag on LOOK MA.
8. "Tallboy finally pays by the frame instead of punishing by the frame."

## 6. Is it as good as California Games yet?
Yes for Off-Leash and Tallboy, and the scoring now rewards skill everywhere. The biggest thing in the way is Bay: its record needs bot-perfect play, so the event a newcomer meets second ends with no silver.

pt4 · no pkill · ~80 harness/bot commands.
