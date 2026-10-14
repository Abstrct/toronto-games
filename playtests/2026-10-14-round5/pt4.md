# pt4 Rob (score attack / TAS), round 5

**Round 1 → 2 → 3 → 4 → 5:**
- overall 5 → 7 → 7 → – → 8
- vs California Games 5 → 6 → 7 → – → 7
- Bike 6→7→8→–→8 · Bay 6→6→8→–→8 · Off-Leash 4→6→8→–→8 · Tallboy 3→7→7→–→7 · Regatta 7→7→6→–→7
- Parking 4 → – → 7 · Subway 4 → – → 7

Each event below shows best / record / 15-frame human. The best runs are replay-verified in the `pt4r5-*tas` sessions.
- Bike 8763 / 6500 / 3986
- Bay 4409 / 3000 / 2090
- Off-Leash 6600 / 4200 / 4165
- Tallboy 5366 / 3600 / 2862
- Regatta 5575 / 4500 / 2475
- Parking 5080 / 4600 / 2655
- Subway 6653 / 5000 / 3274

## 1. My earlier complaints
- R4 Parking capped at 4650: **fixed**. Time left now pays +10/s, so perfect runs separate (best 5080).
- R3:
  - Regatta gold above the TAS ceiling: **fixed**.
  - Ferry surf never fires: **better**. It works, but only if you wait at the start.
  - Subway flat at 2300: **better**. The x3 gold-dot legs add a layer, but the top is flat again.
  - Tallboy ground sips break chains: **fixed**. They now add points (5366 vs 5350), and greedy sipping collapses the run to 2150–3030, which is real risk.
  - Score scale between events: **better** (2.0x, was 2.4x).
  - Free base points: **better** in Bike, Tallboy and Subway (15–24% of the best score), still about half in Bay and Regatta.
  - HOW TO PLAY said five events: **fixed**.
  - DRAFTING worth too little: not re-tested.

## 2. New issues (no crashes, no desyncs)
- [minor] pt4r5-copstas-957786991: Tallboy tops out at 5350. All 26 hurdles become SIP 'N' HOPs on the chalk; anything within ±2 frames ties (5366 with ground sips).
- [minor] pt4r5-subtas-957977854: Subway's best is 6653, and 32 of 48 expert runs land exactly on it.
- [minor] pt4r5-sailtas-957997553: the Regatta record route is to idle 5 s so you meet the ferry. The clock leaves about 70 s spare.
- [minor] pt4r5-parkingtas-958051117: the Parking record is 91% of the best run (other events 64–81%), so gold means flawless.
- [minor] pt4r5-park2-958146965: Parking, my nose got pinned on the BMW. DOWN+LEFT did nothing, and the coach line was only the joke.
- [minor] pt4r5-park-957903474: the quit card's DINGS+FINES of 150 doesn't match the 225 in the spot box. "QUITTERS KEEP 450 AT MOST" isn't explained.
- [minor] pt4r5-bay-958080028: Bay's DOUBLE TIME is never taught, and it's worth +27%.
- [minor] pt4r5-parkingtas-957789396: the spot box's "23S LEFT" reads as "235 LEFT".

## 3. Copy: 7/10
**Clear:**
- The Parking coach ("PAST IT! ⬇ BACK TO THE LINE") and the Tallboy coach ("GREEN BIN! HOLD A AT RED").
- The failed-run lines ("THE 5:42 LEFT WITHOUT YOU", "THIRD WIPEOUT. NO TIPS!").
- "SO LONG, DECAF!"

**Unclear:**
- Tallboy's "SIP 'N' HOP X15!" while the HUD says x5. It's the chain times chalk, but nothing says so.
- Bay's WALK 2425 has no visible link to TIME LEFT.
- The Bike card's sum reads oddly (RIDE indented, then "+ TIPS+STYLE").
- "HOLD UP+LEFT: STRAIGHTEN" made me over-hold.

**Rewrite:** a Bay card line, "SMALL DOTS: DOUBLE TIME!".

## 4. Mastery
**Bay, played twice:**
- First go (taps ±4 f, ignoring lanes): 1683.
- Frame-perfect big dots: 1801. With small dots: 2470.
- Weaving with PRESTO: 4409.

Each layer pays. Parking by hand: spot 1 came out at −75, then I quit. The expert scores 5080.

Across the events the expert scores 1.6–2.5x the 15-frame human: a healthy gap. Where it stops paying:
- The top of Tallboy, Subway and Parking ends in ties.
- Regatta's 2400 for tight roundings is all-or-nothing.
- Bay's combo caps at x5.

Bike and Off-Leash still reward inventing a better route.

## 5. Report
1. Rob, a TAS and score-attack player who once held a footbag leaderboard spot.
2. 8/10: every event has a style layer and a reachable record. vs CG: 7/10.
3. Per event:
   - Bike 8: style is 60% of the best score, and farming one rail earns only 600 in 20 s.
   - Bay 8: a real rhythm game.
   - Off-Leash 8: CLOSE SHAVE chains.
   - Tallboy 7: the chains feel great, but the top is flat.
   - Regatta 7: the surf rewards waiting.
   - Parking 7: the best coaching, but a brutal first spot.
   - Subway 7: capped at the top.
4. Loved: the Bike chain callouts, Bay's DOUBLE TIME with PRESTO, the itemised Parking box.
5. Problems: the Tallboy cap, the Subway cap, the ferry wait, the Parking record height, DOUBLE TIME never taught.
6. California Games had an open-ended top in every event.
7. More Toronto: the ferry leaves Jack Layton when you round mark 2; the "please stand clear" chime starts a gold leg.
8. "Four events are worth a record attempt. In the other three, the record attempt ends in a tie."

## 6. As good as California Games?
Close, not yet. The biggest thing in the way: Tallboy, Subway and Parking still flatten to a fixed maximum.

No pkill this round. About 65 harness commands.
