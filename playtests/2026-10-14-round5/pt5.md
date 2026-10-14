# pt5 Lena (16-bit sports designer) — Round 5

**Round 1 → 2 → 3 → 4 → 5:**
- overall 5 → 6 → 7 → 8 → 8
- vs California Games 4 → 5 → 6 → 7 → 7
- Bike 6 → 6 → 7 → 8 → 8 · Bay 6 → 7 → 8 → 8 → 7 · Off-Leash 5 → 6 → 7 → 8 → 8 · Tallboy 4 → 5 → 6 → 7 → 7 · Regatta 3 → 4 → 5 → 5 → 5
- Parking 4 → 7 → 8 · Subway 5 → 6 → 7

## 1. Round-4 complaints
- **Fixed:** Tallboy B ≥6f into a tap hop (B at A+6/+10/+14 all give SIP 'N' HOP X3! +24). TTC doors-open drift (dot held through DOORS OPEN at Wellesley, R4 ttc-951446276 didn't happen). Parking "$75 TICKET" vs +150 (box now reads HALF IN +150 / $75 TICKET −75 / SPOT +75, which is my rewrite word for word, and a parking officer walks up). Regatta AGROUND/ADRIFT mismatch (screen and card both say ADRIFT, with a reason line). Bike WIPEOUTS 3/0 (row removed, "THIRD WIPEOUT. NO TIPS!"). Bike RAIL WOBBLE now shows ("RAIL WOBBLE! HOP RAILS: B"). Regatta rounding rule is now on screen: "SAIL INTO THE DOTTED RING!"
- **Better:** Regatta start now points at mark 1 instead of the ferry dock. An idle boat rounds mark 1 on its own, which is too generous, but idle still pays 0. TTC arrow: hollow ~15f, then solid ~45f before the dot leaves the ring, plus a top-left status line. The arrow is now a real telegraph.
- **Unchanged:** Tallboy play lane is still a thin strip. Regatta still loses a first-timer: 55 s for 2 marks and 5 bumps (goose, rental kayak, east wall).

## 2. Regressions / new
- [major] **pt5r5-sail-957327564**: ADRIFT ends the race while I'm sailing at speed toward mark 3 (SPD up, about 1.5 s from the ring), because I hadn't touched ◀▶ for 10 s. The README says "going nowhere". It punishes holding a good line, which is a core sailing skill.
- [major] **pt5r5-bay-957401403**: the card says "LEFT, RIGHT ON BIG DOTS". Doing exactly that, on the beat with GROOVE green, gets MISSED THE TRAIN (654). Hitting every dot FINISHES with 10 s left (2445, #3 on the board). DOUBLE TIME isn't a bonus, it's mandatory, and the card never mentions small dots. A first-timer who obeys the card fails every time. This is the one regression.
- [minor] **pt5r5-sail-957336161**: the big yellow mark arrow sits just ahead of the bow and reads as your heading. I misread it 3 times and sailed away from mark 3 twice. Also, a goose sits inside mark 2's ring, so rounding it ends in "HONK! HONK! GOOSED!"
- [minor] **pt5r5-park-957469613**: Off-Leash keeps showing "DOG! PRESS B TO GET SET!" for ~70f after you're already set, which invites a punished second B.
- [minor] **pt5r5-ttc-957561258**: the "GOLD DOT SURF X1 +225" callout contradicts the card's "= X3".
- Unfiled: Bike card shows TTC TOKENS 2 but the sum adds only RIDE, with no line saying why. Tallboy idle card shows RUN 0 with the bar 40% full, plus "FINED 1/4" on a score of 0. Parking half-in at 45° with every lamp red still nets +75.

## 3. Copy: 8/10
- **Clear:** "SAIL INTO THE DOTTED RING!", "MARK 2 IS UPWIND: ZIG-ZAG!", "RUN DOWNWIND TO MARK 3!", the TTC status line (STAND CLEAR! / GO! LEAN ▶ / BRAKES! LEAN ◀ / CRUISING), Parking "STRAIGHT! LET GO TO STOP", "LET GO OF THE BUTTONS", and Tallboy "CHALK + B MID-AIR = X3!"
- **Jokes that land:** "EASY! IT'S A RENTAL!", "THE 5:42 LEFT WITHOUT YOU", "ADRIFT! NOBODY STEERING", "THIRD WIPEOUT. NO TIPS!"
- **Unclear:** "LEFT, RIGHT ON BIG DOTS" (it teaches you to fail). "GOLD DOT SURF X1". The Regatta card says "STANDING STILL PAYS 0" next to MARKS ROUNDED 1 / COURSE 0, and the free mark was never explained. If you overshoot in Parking, "HOLD DOWN+RIGHT: BACK IN" and "PAST IT!" alternate 8 frames apart. The README says the chalk takeoff alone is x3, but the game's x3 needs the sip.
- **Rewrite:** Bay card line → **"LEFT/RIGHT ON EVERY DOT"**, and drop "big".

## 4. Mastery
Skill now shows in the score:
- **Bay:** 654 → 2445. But that gap measures knowing a hidden rule, not playing better.
- **Off-Leash** is the CG model, with B timed by tier: early DODGE 0, +74–80f NICE TIMING +25, +84f CLOSE SHAVE +75.
- **Parking:** following the coach with ~12f reactions got 1220 on spot 1 (ONE-MOVE, CURB KISS, 22 S LEFT). A botched half-in got 75. That's a 16× spread.
- **Tallboy:** chalk +9..+14f clears and +6 spills. A SIP 'N' HOP on top is only +24 against 50 for the hop, so style is a garnish.
- **Regatta:** skill = not getting lost. I never saw style pay.

## 5. PLAYTEST.md report
1. Lena, shipped two SNES sports games.
2. **8/10.** Every R4 promise is kept, and the telegraphs are now honest everywhere except Bay's card and Regatta's ADRIFT. vs CG: 7/10.
3. Bike 8 (BMX: hop/close-call chain x2, RAIL WOBBLE taught). Bay 7 (Summer Games sprint: best rhythm core, card breaks it). Off-Leash 8 (footbag-style timed trick). Tallboy 7 (roller skating: chalk window fair, lane thin). Regatta 5 (surfing: coaching lines great, navigation still the game). Parking 8 (the best tutorial on the cart). Subway 7 (half-pipe balance, now announced).
4. Loved: Parking coach plus the itemised spot box. TTC hollow→solid arrow. The Off-Leash CLOSE SHAVE tier.
5. Top problems: bay-957401403 [major], sail-957327564 [major], sail-957336161 [minor], park-957469613 [minor], ttc-957561258 [minor].
6. CG: one glance told you your heading and your goal. Regatta's goal arrow still fights the bow.
7. Toronto: the parking officer is perfect, so do more: a TTC "please move to the back of the car" chime as the station cue, and a ferry horn before the surf window.
8. "Every danger is announced now. Make every card tell the truth too."

## 6. As good as CG?
Not yet: 7/10. The biggest thing in the way is still **Regatta**. Half of every run is spent being lost, and the new ADRIFT rule DQs you while you're sailing correctly. Fix the heading readability, and make ADRIFT require SPD ≈ 0.
