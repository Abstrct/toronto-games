# pt8 Tasha (completionist/UX researcher) — Round 5

**Round 1 → 2 → 3 → 4 → 5:**
- overall 5.5 → 7 → 7.5 → 8 → 8
- vs California Games 5 → 6.5 → 7 → 7.5 → 7.5
- Bike 6 → 6 → 6.5 → 6.5 → 6.5; Bay 5 → 6 → 6.5 → 7 → 6.5; Off-Leash 5 → 5 → 5 → 5.5 → 6; Tallboy 4 → 5 → 5.5 → 5.5 → 5.5; Regatta 3 → 4 → 5.5 → 5.5 → 5.5; Parking 4.5 → 6.5 → 7; Subway 4 → 6 → 6

## 1. Round-4 complaints
- Penalty row reads 0 next to a non-zero count: **fixed**. Bay has −SPILLS 160, Off-Leash −TACKLES 450, Parking −DINGS+FINES 700, and Bike drops the row on a knockout.
- Rates never stated: **better**. Bike shows "TTC TOKENS X50" and Subway "RIDE: 40 A STOP YOU SURFED". Spills, tackles, bumps and style still have no rate.
- RIDE/WALK/CROSSING/COURSE never defined: **better** (Subway's is now defined; the others still aren't).
- Zero-score cards used the old layout with no sum: **fixed**. Subway and Regatta zero cards now show the sum plus a reason line.
- Squashed breakdown rows: **unchanged** in the Parking spot box.
- Sponsor icon glued to the name on final standings: **fixed** (it has its own column now).
- B on the intro card does nothing: **unchanged**.
- First A eaten on the compete intro card: **unchanged**. PRESS A still shows at about 135 f.
- 1 EVENT, then B, put the cursor on TITLE with no confirm: **fixed**. B now returns to 1 EVENT, and TITLE asks "LEAVE AND LOSE 2 PLAYERS? ▶NO". Final standings still default to TITLE, though.
- Parking "PENALTY −150" gave no reason, and $75 tickets were inconsistent: **fixed**. Every hit is itemised: CURB HIT, SIDEWALK, HEDGE, DENT, BIKE LANE, $75 TICKET.
- SPOTS PARKED 0 but PARKING 300: **better**. A TICKETS row now explains the half-ins.
- Hands-off TTC scored 0 with no explanation: **fixed** ("STANDING STILL PAYS 0").
- Regatta idles into ADRIFT: **better**. In play it warns "HELLO? STEER OR GO ADRIFT!" and the card says "NOBODY STEERED FOR 10 S". The intro card still never mentions the rule.

## 2. Regressions and new issues
- [minor ux] **pt8r5-sail-957700622**: with no input at all the boat rounds mark 1 by itself. The card then says "MARKS ROUNDED 1 / COURSE 0 / STANDING STILL PAYS 0". That contradicts the README's 250 per mark, and the boat wasn't standing still. My steered DNF with 1 mark got COURSE 314.
- [minor ux] **pt8r5-bike-957243608**: the failed card lists "TTC TOKENS X50 5 / STYLE 100" above "RIDE 230 = SCORE 230". It reads as 5+100+230=230, and the token row shows the count, not 250.
- [minor ux] **pt8r5-parking-957463376**: the spot box ends "SPOT −175" and then the HUD goes UP from 680 to 755, because live dings are listed again.
- [minor ux] **pt8r5-parking-957501119**: on spot 3 the coach says "HOLD DOWN+RIGHT: BACK IN" and about 26 f later "DING DING! BIKE! WAIT FOR IT". Following the coach cost me −150 BIKE LANE. Spot 3 also starts at TIME 25 without saying so.
- [minor ux] **pt8r5-parking-957406415**: the box repeats "PARKED." then "PARKED +200", the rows touch, and it says 23S LEFT while the HUD shows 24.
- [note art] **pt8r5-parkx-957586948**: a car parked a few degrees off straight renders smeared, with doubled edges.
- Regatta has a yellow arrow beside the boat that sometimes points away from the next mark. Neither the intro card nor the README explains it.

## 3. Copy: 7.5/10
**Clear and funny:** "1937 MORE FOR BRONZE" and "THE BOARD STARTS AT 2600", which are the best UX lines in the game. Also "THIRD WIPEOUT. NO TIPS!", "THE 5:42 LEFT WITHOUT YOU", "COP CAUGHT YOU: FINED 1/4" (127+104−57=174, I checked), "IN IRONS! STEER RIGHT ▶▶", "◀◀ TACK NOW!", "DOG! PRESS B TO GET SET!", "TIP: STEP SMALL DOTS TOO!", "BUMPER TAP! (IT'S A BMW)", "INTO THE HEDGE!", "FACE-FIRST INTO A BACKPACK!" and "PARKED. IT'LL DO."

**Unclear:**
- "STANDING STILL PAYS 0" contradicts what happened in Regatta. On TTC it contradicts the intro's own "RIDE TO UNION HANDS-FREE".
- "PATIENT ZERO!" appears twice on the same card.
- "SPOT 3: TIGHT. MAID'S ON DUTY" doesn't warn that a bike is coming.
- The Bike card's "HOP RAILS, DODGE LATE: X8" is shorthand only.

**Rewrite** (zero-score footer): "NO LEANING, NO POINTS" for TTC, and "HANDS OFF THE TILLER PAYS 0" for Regatta.

## 4. Mastery
Parking shows it clearly. As a first-timer following the coach late I scored 530: PARKING 850 + STYLE 380 − DINGS+FINES 700. Practising the roll timing got me 2620 (1580 + 1040, #4, "SO LONG, TOWTRUCK!"). Every card added up to the point. One flaw: on spot 1 a sloppy overshoot still earned ONE-MOVE and 930, against 940 for a clean run, so the timing bonus dominates and ONE-MOVE isn't really checked.

Bay didn't separate players. On-beat walking scored 411, double time 418 (stuck in a crowd), weaving 620; all three missed the train. Subway does reward effort: hands-off scored 0, clumsy leaning 160.

The bot curves on this ROM put a 0 f expert at about 1.9× a 15 f human in every event. Skill pays, but there's no California Games-style "look what I did" trick ceiling in what I could reach.

## 5. Report sections
1. Tasha, completionist UX researcher. 2. **8/10**: the cards finally teach the scoring; **vs CG 7.5/10**. 3. Per event: above. 4. Loved: "N MORE FOR BRONZE / BOARD STARTS AT"; Parking itemised hits + coach; leave-roster confirms. 5. Problems: see section 2, plus intro card eats first A and ignores B. 6. CG had: tricks you learn by playing, and the score shows off the trick. 7. Toronto: Regatta arrow as a "Billy Bishop windsock"; Bay "UNION IN 2 MIN"; "GREEN P OWES YOU" ticket total. 8. Quote: "The game finally told me why I scored 0. Then it said I was standing still while my boat rounded a mark by itself."

## 6. Is it as good as California Games yet?
Not quite. The menus and records loop beat it, and the cards now add up. The biggest thing in the way is that a first-timer still can't finish Bay or Regatta by reading the screen, and their zero cards blame the player for things that didn't happen.
