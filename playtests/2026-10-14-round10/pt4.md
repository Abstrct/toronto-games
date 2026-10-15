# pt4 Rob (score attack / TAS), round 10

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10:**
- overall 5 → 7 → 7 → – → 8 → 8 → 8.5 → 8.5 → 8.5 → **8.5**
- vs California Games 5 → 6 → 7 → – → 7 → 7 → 8 → 8.5 → 8.5 → **8.5**
- Bike 6→7→8→–→8→8→8→8.5→8.5→**8** · Bay 6→6→8→–→8→8→8→8→7.5→**7.5** · Off-Leash 4→6→8→–→8→6→8→9→9→**9.5** · Tallboy 3→7→7→–→7→7→8→8.5→9→**8.5** · Regatta 7→7→6→–→7→7→8→8→8→**8**
- Parking 4 → – → 7 → 8 → 7 → 7 → 8 → **8.5** · Subway 4 → – → 7 → 8 → 8 → 8.5 → **8.5** (I didn't replay Parking or Subway by hand this round. Those scores come from their cards and the bots.)

Bots (6 seeds each), skilled / human / record: Bike stylist 6322 / 2958 / **6000** · Bay weave 4421, ace 2992 / 1862 / 3200 · Off-Leash 13862 / 6781 / 10200 · Tallboy 8753 / 2558 / 6600 · Regatta 5058 / 2876 / 3900 · Parking 6633 (tas 7316) / 3468 / 5500 · Subway 8310 / 4201 / 6100. Cheese still scores 0: idle, mash_a and hold_up all get 0 on Bay.

## 1. My round-9 complaints
- Bay record at 93% of the best bot: **better**. The record is now 3200, which is 72% of bay_weave. But it's 107% of bay_ace, and bay_human (1862) still misses silver (2133).
- "GOLD 22" in the LIQUID COURAGE callout: **fixed**. The demo now reads "SIP 40 X3 CHAIN X3 DEAD ON".
- RAILS HOPPED window was 21 f against the manual's half second: **fixed**. B at +0..+29 after HOP THE RAILS: B! gives RAILS HOPPED +80, and +30 gives RAIL WOBBLE. That's exactly 0.5 s.
- Off-Leash CLOSE SHAVE couldn't be hit by reacting: **fixed**. Dog 1 glows at f878 and springs at f888. NICE TIMING +400 runs to +13 f, CLOSE SHAVE +500 from +16 to +25, and +27 is TACKLED. A 15 f reaction to the glow lands at +17, inside the window. Expert/human fell from 3.7x to 2.0x.
- ROLL TACK has no tell: **better, not fixed**. It now pays +300. The demo shows HIKE in the HUD just before each one, but my 5 hand tries got nothing.
- Parking card order: **fixed**. It now reads "↑ TO THE LINE, ↓+▶ BACK IN / NOW! IN THE PANEL: ↓+◀ / STOPPED IN THE SPOT? A".

## 2. Regressions and new issues
- [minor] **pt4r10-bay-71660361**: Bay rewards blind weaving. Beat taps in one lane missed the train (387, 7 spills). The same taps plus a lane change every beat, never once looking at a red !, made the 5:42 for 865 and paid the hidden SLALOM. bay_weave also beats bay_ace by 48%.
- [minor] **pt4r10-i-bike-71665890**: The Bike record (6000) is 95% of the stylist's mean and sits above its worst seed (5900). The stylist fell from 8322 to 6322 this round. Bike is now the steepest record in the game.
- [minor] **pt4r10-cops-71666523**: LIQUID COURAGE regressed by hand. Holding B through a DEAD ON hop while TIPSY gave SLOSHED! 0 PTS, CHAIN OVER in 8 tries at every lead time. In round 9 it landed on my third try. The new red-zone honk tells you to let go.
- Manual: Bike still lists "▼ brake", and the card doesn't.

## 3. Copy: 8.5/10
**Clear:** "RED ! = B NOW FOR +400", "DEAD ON THE CHALK! +39", "BIT LATE, BUD! +26", "SLOSHED! 0 PTS, CHAIN OVER", "TACKLED! -1 ♥. SO FRIENDLY" (it made me laugh), "ANOTHER TRICK IN 2 S = X2", "OLE! MATADOR! +600", "PASS CLOSER = TIGHT ROUNDING". The Bay fail card ends "ON THE DOTS = FASTER WALK", a useful reason line.
**Unclear:** "TIPSY! THE COP'S GAINING" fires after only two sips, and the BUZZ meter didn't tell me I was already in the red. "SIP 40": why 40, when the manual says 8 plus 1 per 16 BUZZ? Off-Leash's "LATER B = MORE PTS: RISKY!" undersells a 10-frame window that a human can now hit.
**Rewrite:** "TIPSY! COP'S GAINING. NEXT SIP SLOSHES".

## 4. Mastery
**Bay, first-timer vs style.** My first-timer beat-walk scored 387 and missed the train. A blind weave scored 865. The bots: human 1862, ace 2992, weave 4421. Skill pulls away (2.4x), but the cheapest skill to fake is weaving, not reading the arrow.
**Off-Leash dog 1:** DODGE +300 → NICE +400 → CLOSE SHAVE +500 → MATADOR +600 (hold toward the dog). It's a graded risk ladder you can react to. This is the best risk-reward in the game, and it's California Games-grade.
**Tallboy:** the take-off grades BIT LATE +26 / DEAD ON +39. The style ceiling is still the chained sip 'n' hop (demo: +36, then +84, then +360), and pro/human is 3.4x. Everything else sits at 1.8–2.4x. Every event has at least two things to master.

**Hidden tricks by hand:** MATADOR, first try (the tell is the glow: react to it). SLALOM, by accident while blind-weaving. LIQUID COURAGE, 0 of 8 (worse than round 9). ROLL TACK, 0 of 5. I didn't attempt TTC TRANSFER, LOOK MA or BIKE SHAVE this round (budget).

## 5. Report
1. Rob, TAS and score-attack player, ex-footbag leaderboard.
2. 8.5/10. Off-Leash and the bike rails are now exactly what they claim to be, but two tricks still can't be learned by hand. vs CG 8.5/10.
3. Bike 8 (the rail window is honest; the record is too steep) · Bay 7.5 (weaving beats reading) · Off-Leash 9.5 · Tallboy 8.5 (LIQUID COURAGE got lost) · Regatta 8 · Parking 8.5 · Subway 8.5.
4. Loved: the Off-Leash ladder you can react to; the half-second rails; SO FRIENDLY.
5. Problems: Bay weave [minor] pt4r10-bay-71660361; LIQUID COURAGE [minor] pt4r10-cops-71666523; Bike record [minor] pt4r10-i-bike-71665890; ROLL TACK tell [note]; manual ▼ brake.
6. CG's tricks were learnable from body language. Tallboy and Regatta's still aren't.
7. More Toronto: a "WATCH FOR THE STREETCAR DOORS" ding on RAILS HOPPED, and a Tim's cup spilled on SLOSHED.
8. "Now the dog tells you when to be brave."

## 6. Is it as good as California Games yet?
For Off-Leash, yes; it has passed it. Overall it's level. The biggest thing in the way is the hidden tricks you can't learn by hand: ROLL TACK and, now, LIQUID COURAGE. A score-attacker plateaus on them because the game never shows when they're on.

pt4 · no pkill · ~72 harness commands.
