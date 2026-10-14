# pt6 Gord (Leslieville, TTC since the Red Rockets, C64 California Games), round 7

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7:**
- overall 6 → 6 → 6 → – → 7 → 7.5 → 8
- vs California Games 5 → 5 → 5 → – → 6.5 → 7 → 7.5
- Bike 7 → 5 → 5 → – → 6 → 6.5 → 6.5; Bay 6 → 6 → 6 → – → 6 → 7.5 → 7; Off-Leash 5 → 6 → 6 → – → 7 → 7 → 7.5; Tallboy 4 → 5 → 5 → – → 7 → 6.5 → 7.5; Regatta 4 → 5 → 4 → – → 6 → 6 → 8
- Parking 6 → – → 5 → 7 → 7.5; Subway 5 → – → 7 → 7.5 → 7.5

## 1. Round-6 complaints
- **Coach stomped by GUST (pt6r6-sail-989938768): fixed.** GUST/HIKE now shows in the HUD where SPD was, and the coach panel keeps its order. MARK 1! NOW TAP ◀ 8 TIMES and TACK NOW! TAP ▶ 5 TIMES each gave me a CLEAN TACK! +100.
- **Ferry pin (pt6r6-sail-990008438): not reproduced.** I aimed at the docked ferry twice and ran aground on the pier and on the island instead. Both times I got AGROUND! TAP ▶ TO BEAR OFF, then PUSHED OFF! SAIL ON!.
- **"GOLD DOT ALL LEG" (copy): fixed.** The Subway card now reads GOLD DOT STOP TO STOP = X3, which is my rewrite.
- **LINE HONOURS with bumps: fixed.** With one bump the style was 600; with none it was 900, so the +300 only paid on the clean run.
- **Bike as a survival test: unchanged.** Riding blind: 279, three wipeouts. Hopping the rails and changing lanes: 366, still wiped out, at 83% of the way.
- **RAIL WOBBLE on every lane change: unchanged.** It still pops when I steer out of the bike lane.
- **DECAF twice on one card:** not seen this round.

## 2. Regressions and new issues
- [minor ux] **pt6r7-sail2-999906496:** after I round mark 3, the HUD says TO LINE! but the coach keeps "TO MARK 3: TAP ▶ ONCE" for about 1.5 s. I waited for the real order and bumped the mark: TOUCHED THE MARK! -2 S, no line honours.
- [minor ux] **pt6r7-bay-902538:** in DOUBLE TIME, MISS keeps popping over my walker around a jogger bump, even on steps tapped dead on the dots. Meanwhile the tip box says "TIP: STEP AS BIG DOTS LAND", which sounds like it wants me off double time. Sloppy double time now beats big dots by only 16% (1152 vs 996; last round it was +56%). Both runs made the 5:42 with 7 s to spare.
- [note ux] **pt6r7-sail2-903401:** the Regatta card shows "+ STYLE 900" as one number. CLEAN TACK, TIGHT ROUNDING and LINE HONOURS never appear on it by name.
- Bike rails: the hop only counts when the rails are right under the wheel. Pressed 6–16 frames early, I still got a RAIL WOBBLE. HOP THE RAILS: B! comes up about 90 frames ahead, so first-timers will press too early.
- Parking: when I'm stopped and touching nothing, the coach says "KEEP DOWN+RIGHT: GET READY". KEEP what?

## 3. Copy: 8.5/10
**Clear the first time:** "TRACK HOP! +60 / NEW TRICK IN 2 S: X2", "RING AHEAD! HOLD YOUR COURSE", "AGROUND! TAP ▶ TO BEAR OFF", "LET GO OF ▲: STOP ON THE LINE", "STRAIGHT! LET GO OF THE PAD", "TOO LATE! LET GO OF THE PAD", "15 S GETTING NO CLOSER / 250 A MARK + PART OF NEXT", and the itemised Parking spot box (TIME LEFT +174, CURB KISS +150).

**Jokes that land:** "THE RCYC BAR IS OPEN!" is the most Toronto line in the game. Also "THIRD WIPEOUT. NOT PAID!", "SPADINA! YOU LOST HIM!", "JOGGER! ON YOUR LEFT! SPLASH", "CAR IN BIKE LANE. AGAIN.", "ADRIFT! GETTING NOWHERE".

**Unclear:** "TIP: STEP AS BIG DOTS LAND" (during double time), "KEEP DOWN+RIGHT" (when you're holding nothing), and the stale "TO MARK 3".

**Rewrite:** during double time, the tip should say **"DOUBLE TIME: EVERY DOT, LEFT-RIGHT"**.

## 4. Mastery
- **Regatta:** my first-timer run following the coach scored 2485. Cleaning up the mark-3 rounding scored 2860 (style 900). The record is 3900, and above that there's FERRY SURF and a third clean tack. That's three or four things to master.
- **Tallboy:** the same chalk timing scored 2188 dry and 4060 with a sip on every hop (9 SIP 'N' HOPs). Taking off late on the chalk (threshold 250) got me BUSTED at 419. This is the clearest skill curve in the game.
- **Off-Leash:** 3960 with 15f reactions, 3810 waiting longer. The walk bonus (66 s left = 2150) outweighs the dogs, and bold timing didn't pull away.
- **Bay:** with perfect hands, double time beats big dots by 46% (1753 vs 1204). With human hands it's 16%.
- **Hidden tricks:** I didn't find one by play. In fairness, I'd seen "ROLL TACK" in the repo's commit log, so I tried hiking through a tack, holding the turn, and an A mid-tack. All three gave a plain CLEAN TACK.

## 5. Report
**Who:** a Leslieville lifer, Leafs and Jays, rode the Red Rockets.

**Overall 8/10:** Regatta went from my worst event to my favourite, and the cards say Toronto in every line. vs CG: 7.5/10 as good.

**Per event:**
- Bike 6.5: track hop copy great, still a survival test.
- Bay 7: PASSED counter and 5:42 header good; double time muddier.
- Off-Leash 7.5: MADE IT TO DUNDAS!, 3960.
- Tallboy 7.5: sip skill pays, SO LONG, NANA!
- Regatta 8: RCYC bar, line honours.
- Parking 7.5: the coach rescues you, NICELY DONE. +1024.
- Subway 7.5: 1442/1510, UNION! EVERYBODY OFF!

**Top 3 loved:** THE RCYC BAR IS OPEN!; Regatta's one-order coach; Tallboy's sip-'n'-hop payoff.

**Top problems:**
1. Bike still ends before style starts [design].
2. Stale mark-3 order [minor, 999906496].
3. Double-time MISS/tip contradiction [minor, 902538].
4. Lumped Regatta style [note, 903401].
5. Early rail-hop prompt [minor].

**CG had:** tricks named on the score screen.

**More Toronto:** "AGROUND AT HANLAN'S"; a 504 King car on the Bay crossing; "SHORT-TURNED AT SHAW" as a Bike fail line.

**Wall quote:** "Rounded three marks, crossed the line, and the RCYC bar was open. I've never been let in there in real life."

## 6. As good as California Games yet?
Nearly. The biggest thing in the way is still **Bike**: it's the opener, and a first-timer is wiped out before a single TRACK HOP counts. Everything I earned there was forfeit, while in CG your first BMX run was already doing tricks.
