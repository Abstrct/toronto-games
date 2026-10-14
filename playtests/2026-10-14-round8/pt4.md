# pt4 Rob (score attack / TAS), round 8

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8:**
- overall 5 → 7 → 7 → – → 8 → 8 → 8.5 → **8.5**
- vs California Games 5 → 6 → 7 → – → 7 → 7 → 8 → **8.5**
- Bike 6→7→8→–→8→8→8→**8.5** · Bay 6→6→8→–→8→8→8→**8** · Off-Leash 4→6→8→–→8→6→8→**9** · Tallboy 3→7→7→–→7→7→8→**8.5** · Regatta 7→7→6→–→7→7→8→**8**
- Parking 4 → – → 7 → 8 → 7 → **7** · Subway 4 → – → 7 → 8 → 8 → **8**

Bot ceilings (12 seeds) / record / human bot: Bike 10530 / 7500 / 3461 · Bay 3603 / 3000 / 1975 · Off-Leash 12825 / 8500 / 3702 · Tallboy 8817 / 6300 / 2602 · Regatta 5205 / 3900 / 2618 · Parking 6536 / 4700 / 5367 · Subway 8476 / 6100 / 3931. No cheese beat honest play: idle, hold, mash and hop-spam all score 0–404.

## 1. My round-7 complaints
- Bike STYLE cap at 5000: **fixed**. bike_stylist hit STYLE 7180 (10530 total). Verify said GONE.
- Tallboy stuck coach: **fixed**. It's my rewrite word for word: "STUCK! TAP A TO SCRAMBLE", then "OOF! SPILLED! HE'S GAINING / STUCK? TAP A TO SCRAMBLE". Verify still says PRESENT, but that's a stale condition. I watched the fix on screen.
- Parking top end is one fixed line: **unchanged**. Expert 6378–6536 (sd 67), human median 5588.
- "RIDE 1562+20/S": **fixed**. The card now says "RIDE 1 PER 4 M".
- Nothing hinted that hidden tricks exist: **fixed**. The demo banner WATCH THAT MOVE! plus a named popup shows every one of them.
- Off-Leash dogs are 85% of the score: **unchanged** (ace: dogs 10100–10950 of ~12400). Walking slower still costs points at every speed: 30% walk 350, 45% 11238, 60% 11755, 80% 12371, ace 12412.

## 2. Regressions and new issues
- [minor] **pt4r8-bike1-11660729**: Bike's seed decides too much. Stylist runs went 7270–10530, and one seed paid STYLE 7180 against 3700–5060 on the others. The record (7500) sits at the stylist median, so a record attempt is a reroll.
- [minor] **pt4r8-parking-11659108**: Parking's ceiling rose, but it's still one fixed line.
- [note] **pt4r8-baycard-11667020**: Bay's record is 83–86% of bay_ace, the steepest in the game. bay_expert misses the train on every seed (stale bot?).
- Bike: farming TTC TRANSFER in the streetcar lane earns 1240 style in 14 s, then three wipeouts forfeit all of it. That's the right risk, not a bug.

## 3. Copy: 8.5/10
**Clear:** "SAFE: B ON ! = 100 PER DOG / BOLD: RED ! 200, LATE 400+" (the whole risk ladder on one card), "ANOTHER TRICK IN 2 S = X2", "SLOSHED! 0 PTS, CHAIN OVER", "TACKLED! -150. SO FRIENDLY", "HE'S NEVER DONE THIS!", "PAID FOR THE RIDE ONLY". The GAVE UP card adds up to the point (50 − 150, floored at 0, FORFEIT DOGS 550). The Parking spot box itemises all nine lines.
**Unclear:** "HOLD B: SIP, COP CAN'T SEE" (**pt4r8-copscard-11666137**). On first read I took it to mean B hides me. "DODGE +20  Y GOLD = PRESTO" (Bay) crams two rules onto one line. "*CRACK* FRESH TALLBOY" came up in the demo, and I couldn't tell what it rewarded. The Bike card dropped ▼ brake, but the manual still lists it.
**Rewrite:** "SIPS PAY WHEN THE COP CAN'T SEE".

## 4. Mastery
**Off-Leash, dog 1, by hand.** As a first-timer, B at "DOG! PRESS B TO GET SET!" gives DODGE +100. Going for style, B at 0–48 f after the red ! is NICE TIMING +200 and 52–66 f is CLOSE SHAVE +400; 68 f or later gets you tackled (−150). B with the D-pad held toward the dog at 52–57 f is **OLE! MATADOR +550** (the demo chains it to +600 and +650). Holding the d-pad toward the dog and then pressing B is only a CLOSE SHAVE. The window is 6 f: an expert can learn it, and it isn't frame-perfect. That's 5.5x per dog between a first-timer and an expert, over 16 dogs.
**Tallboy.** The hop window is 4 f: tap at +20 for ON THE CHALK +36, at +24 for DEAD ON +39; earlier and you hit the crates. **LIQUID COURAGE**: a long (30 f) mid-air sip that tips the BUZZ into the red pays a base of 21–22 instead of 8 ("21 X3 DEAD ON +63"). Then you're TIPSY and the cop closes in. That's real risk/reward.
**Bots, expert ÷ 15-frame human:** Bike 3.0x (best seed), Off-Leash 3.35x, Tallboy 3.3x, Subway 2.15x, Regatta 1.9x, Bay 1.8x, Parking 1.2x. Yes, skill pulls away, CG-style, and Off-Leash, Tallboy, Bike and Regatta each have several skills to master. Parking still has one.

**Hidden tricks.** I found all seven in the title demos. I reproduced three by hand: Bike **TTC TRANSFER** +120 (steer sideways 2 f before B and hop both streetcar rails in one go; hop first, then steer, gives only TRACK HOP +60), MATADOR and LIQUID COURAGE. Seen in the demos but not reproduced: Bay SLALOM X2 +50, Regatta ROLL TACK +250, Parking CLOSE SHAVE "SHE DIDN'T BLINK" +200, Subway LOOK MA, NO HANDS! +100.

## 5. Report
1. Rob, TAS and score-attack player, ex-footbag leaderboard.
2. 8.5/10: both my round-7 bugs are fixed, and the hidden tricks are now earned and visible. vs CG 8.5/10.
3. Bike 8.5 (cap gone, TTC TRANSFER, seed luck) · Bay 8 (record steep; didn't hand-play) · Off-Leash 9 (100/200/400/550, the best risk ladder in the game) · Tallboy 8.5 · Regatta 8 (bots only) · Parking 7 · Subway 8 (bots only).
4. Loved: OLE! MATADOR; LIQUID COURAGE's tipsy trade-off; the demos teaching tricks the way CG's attract mode did.
5. Problems: Bike seed variance [minor] pt4r8-bike1-11660729; Parking flat top [minor] pt4r8-parking-11659108; Tallboy sip line [minor] pt4r8-copscard-11666137; Bay record steep [note] pt4r8-baycard-11667020; Off-Leash dogs are 85% of the score [note].
6. CG's footbag had one session's worth of new combos. Parking still has none.
7. More Toronto: make Bike's TTC TRANSFER pay a "PRESTO TAP" sound and +1 token.
8. "Round 7 made me pay for losing. Round 8 pays me for showing off, and only when I'm good."

## 6. Is it as good as California Games yet?
Yes for Off-Leash and Tallboy. The biggest thing in the way overall is Parking: its top end is still one fixed line, and the human bot gets 85% of it.

pt4 · no pkill · ~65 harness/bot commands.
