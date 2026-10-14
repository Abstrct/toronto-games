# pt2 Marcus, C64 sleepover host (4P party), Round 5

**Round 1 → 2 → 3 → 4 → 5:**
- overall 6 → 7 → 7.5 → – → 7.5
- vs California Games 5 → 7 → 7.5 → – → 7.5
- Bike 6 → 6 → 5.5 → – → 5.5 · Bay 4 → 5 → 6 → – → 6.5 · Off-Leash 6 → 5 → 6.5 → – → 7 · Tallboy 6.5 → 6.5 → 6.5 → – → 6 · Regatta 3 → 4 → 4 → – → 4.5 · Parking 6 → – → 8 · Subway 6 → – → 6

Game: 4P Compete in all. DAVE (Mr. Sub, idler/masher), MARCUS (Honest Ed's), KEV (Steam Whistle, quitter), JEN (Pizza Pizza). That's about 29 min of machine time to the podium, so maybe 40 with humans. Marcus took CHAMPION OF TORONTO, 29 pts to 21. REMATCH goes straight to the Bike card.

## 1. Round-4 complaints
- Bay steps on the dots never score: **fixed**. Steps register and GROOVE fills. Double time FINISHED 2207.
- Off-Leash careful players run out the clock: **fixed**. Marcus finished with 25 s left (2025, #4 board) and Kev finished too.
- Red "- WIPEOUTS 0 / - TACKLES 0" line: **fixed**. The line is gone on 0-tackle and 0-wipeout cards.
- Steady A after a BUSTED carries into the next player's run: **better**. Marcus's busted card held on LET GO OF THE BUTTONS through 30 s of 2 Hz A taps. But once, steady A after Jen's bust (she was the last player) went through her card, the Tallboy standings and the medal table in 7 s. I didn't isolate it.
- Round-3 leftovers: name-grid lag **fixed**; frozen-looking card **fixed** (LET GO OF THE BUTTONS); champion sprite over TITLE **fixed**; quitting or idling no longer wins medals **fixed** (Regatta and TTC idlers both score 0, STANDING STILL PAYS 0); Regatta unroundable **better**.

## 2. Regressions / new issues
- [major] pt2r5-party-957463326: Bay's card says LEFT, RIGHT ON BIG DOTS. Doing that misses the train (612), below a 7 Hz masher (626). Only DOUBLE TIME makes Union (2207/2277), and the card never mentions it.
- [major] pt2r5-party-957869750: Regatta. Marcus rounded all 3 marks and held the arrow's heading to the line. ADRIFT! NOBODY STEERED FOR 10 S, with 13 s left. The one full course of the night was punished.
- [minor] pt2r5-party-957553676: Off-Leash tackled card says CROSSING PAID BY DISTANCE, but CROSSING 60 - TACKLES 60 = 0, every time.
- [minor] pt2r5-party-957581068: Off-Leash is decided by a blind B rhythm. Every 40 f: 13 dodges, finished. Every 35 f: 0 dodges, score 0. You don't need to watch the dogs.
- [minor] pt2r5-party-957704699: an idle Regatta boat drifts round mark 1. The card shows MARKS ROUNDED 1 but pays 0, against the manual's "250 per mark".
- [minor] pt2r5-party-957996091: Parking's CALL IT A DAY card shows the quitter cap as "- DINGS+FINES 220" with 0 tickets and no dents.
- [minor] pt2r5-party-957337616: failed Bike card reads TOKENS X50 2 / STYLE 160 / RIDE 303 / = 303. Nothing says style was dropped.
- Note: on the final table the cursor starts on TITLE, not REMATCH. The NO/YES check makes it safe, but it's two taps slower.

## 3. Copy: 7/10
Clear: the Parking instructor is superb: "HOLD DOWN+RIGHT: BACK IN", "GET READY: DOWN+LEFT SOON", "A: PARK IT!", "PARKED. IT'LL DO." So are the Regatta coaching lines ("IN IRONS! STEER RIGHT", "RUN DOWNWIND TO MARK 3!"), "LET GO OF THE BUTTONS", "COP CAUGHT YOU: FINED 1/4" and "QUITTERS KEEP 450 AT MOST". "DOG! PRESS B TO GET SET!" works too.
Unclear: "LEFT, RIGHT ON BIG DOTS" (a losing instruction). "CROSSING PAID BY DISTANCE" over a 0. "THIRD WIPEOUT. NO TIPS!" next to a cyan STYLE 160. "NOBODY STEERED FOR 10 S" when somebody was sailing. "FOLLOW THE YELLOW ARROW!" when the arrow points at a sailable heading, not at the mark. Tallboy's popup "CHALK + B MID-AIR = X3!" contradicts the card's TAP A AT CHALK (the manual says chalk alone pays x3).
Rewrite: Bay card line 3 → **"STEP ◀▶ ON EVERY DOT / SMALL DOTS = DOUBLE TIME"**.

## 4. Mastery
Bay: card-reader 612 → double-timer 2207–2277, which is 3.6x. Skill shows, but only if you've read the manual. Parking: skill shows on the spot box (TIME LEFT +220, CURB/ANGLE/SPACE), which is the best scoring readout in the game. Off-Leash: cadence luck, not skill. Tallboy: one reaction-timed tap got "ON THE CHALK!". Blind hopper Dave (368) still took gold over my sip-and-hop Marcus, who was busted in 30 s. Bike: nobody reached Spadina; best 307 against a record of 6500.

## 5. Report
1. Marcus, the host who passes the one joystick around the couch.
2. 7.5/10. The party shell is better than the C64's, but four of seven events still end in failure for ordinary players. vs CG 7.5/10.
3. Bike 5.5 (all wiped out by 75%). Bay 6.5 (works; the card lies). Off-Leash 7 (finishable). Tallboy 6 (fair turns, cards explain the fine). Regatta 4.5 (rounding is possible with coaching, then ADRIFT; three of four scored 0, Jen spent 90 s for 0). Parking 8 (Marcus and Jen tied 450, shared gold, nicely done). Subway 6 (idle Dave 0 now; three blind leaners tied 120).
4. Loved: the Parking instructor; ties sharing gold, with zero scores shown as "–"; podium → REMATCH in one tap of A, no re-signup.
5. Top problems: 957463326, 957869750, 957553676, 957581068, 957996091.
6. CG gave every turn a satisfying ending. Here Bike, Regatta and Subway rarely do.
7. Toronto: SkyDome and CN Tower behind the Regatta are lovely. Make the ADRIFT card "+++ STILL WAITING FOR THE ISLAND FERRY +++".
8. Quote: "The Bay card told Kev to walk on the big dots, so he walked straight past the 5:42."

## 6. As good as California Games?
Not yet. The biggest thing in the way is still that ordinary players fail: Bike, Regatta and Subway end in wipeout, ADRIFT or PATIENT ZERO for almost everyone. The cards also have to teach the winning move (Bay's double time).
