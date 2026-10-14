# pt8 Tasha (completionist/UX researcher): Round 8

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8:**
- overall 5.5 → 7 → 7.5 → 8 → 8 → 8.5 → 8.5 → 8.5
- vs California Games 5 → 6.5 → 7 → 7.5 → 7.5 → 8 → 8 → 8.5
- Bike 6 → 6 → 6.5 → 6.5 → 6.5 → 6.5 → 6.5 → 6.5*; Bay 5 → 6 → 6.5 → 7 → 6.5 → 7 → 7 → 7.5; Off-Leash 5 → 5 → 5 → 5.5 → 6 → 6 → 6.5 → 6.5; Tallboy 4 → 5 → 5.5 → 5.5 → 5.5 → 5.5 → 6 → 6*; Regatta 3 → 4 → 5.5 → 5.5 → 5.5 → 7 → 6.5 → 7.5; Parking 4.5 → 6.5 → 7 → 7.5 → 8 → 8*; Subway 4 → 6 → 6 → 6 → 6.5 → 6.5*
- \* card read only, not replayed this round (budget went on Regatta, Bay and the menus)

## 1. My round-7 complaints
- **Fixed.** pt8r7-sail2-245986: TOUCHED THE MARK! -2 S now pops on the mark at contact (f2005, beside buoy 2). The coach switches at the rounding ("MARK 1! NOW TAP ◀ 3 TIMES", "MARK 2! NOW TAP ▶ 3 TIMES"), with no stale TO MARK n.
- **Fixed.** pt8r7-bay-337057: the spill that made DECAF showed "BUMPED A BANKER! SORRY!", then "DECAF! NO MORE DOUBLE TIME". There was no stale LAST SIP.
- **Fixed.** Regatta first-timer style 0. Following the coach at ~15 f got two TIGHT ROUNDINGs (+200, then "2 TIGHT IN A ROW! +270"), 2 CLEAN TACKs and LINE HONOURS: 2960, silver, #3. Round 7 was 1750. "PASS CLOSER = TIGHT ROUNDING" finally names the skill.
- **Fixed.** Compete in some starts with 0 of 7 ticked. START on none says "TICK AT LEAST ONE EVENT!". A one-event competition takes about 10 presses, and REMATCH→A replays in 2.
- **Fixed.** The Bay card now says "Y GOLD = PRESTO". The Bay card also names the bumped ghost ("SO LONG, TIMBIT!").
- **Better.** Final standings now has PTS and SCORE headers.
- **Better.** Bay lanes. A blind on-beat walk still makes the train (10 spills, 960), but that misses bronze (1000). Blind double time gets 1563. Lane-aware bots get 1900–2200 and weavers 3800–4400.
- **Unchanged.** The Regatta card still lumps STYLE (see below).
- **Not re-tested.** Parking STYLE lump, crooked-car ANGLE GOOD.

## 2. Regressions and new issues
- [minor ux] **pt8r8-menu-11300984**: the Regatta finish card reads TIGHT ROUNDING 470, + STYLE 970. The other 500 (2×CLEAN TACK, LINE HONOURS +300) has no row. There is room for two more rows.
- [minor ux] **pt8r8-menu-11644048**: after a +500 rounding of mark 1, the red "MISS THE BUOY! TAP ▶ ONCE" order stays up ~3 s while I sail away from mark 2 on a heading nowhere near a buoy. Obeying it turns you further from the mark. It also showed for mark 1 just before the +500 rounding, so the coach warns you off the best line.
- Unfiled: 5 taps at 10/s got "TAP FASTER FOR A CLEAN TACK", but 5 taps at 6/s earlier got CLEAN TACK +100. That's possibly because I tacked late, but the message contradicts the manual's six-a-second.
- Unfiled: the Bay STYLE row (643) is also unitemised.

## 3. Copy: 8.5/10
- **Clear:** "ZIG-ZAG UP: I'LL CALL TACKS" (a big improvement), "MARK 1! NOW TAP ◀ 3 TIMES", "SET! YOU STEP AS HE LUNGES", "GAVE UP: DOGS FORFEIT" (fixes my round-7 rewrite), "250 A MARK + PART OF NEXT", "TICK AT LEAST ONE EVENT!".
- **Funny:** "THE RCYC BAR IS OPEN!", "PHONE ZOMBIE! SORRY! SORRY!", "PHOTOBOMBED A TOURIST! SORRY!", "HONK! HONK! GOOSED! -2 S".
- **Unclear:**
  - "MISS THE BUOY!" when no buoy is near.
  - "HE'S FRIENDLY!" after a dodge never says to walk up and pat him.
  - Off-Leash card "BOLD: RED ! 200, LATE 400+": "LATE" reads like a penalty.
  - Tallboy "HOLD B: SIP, COP CAN'T SEE" reads as a fact, not a condition.
- **Rewrite:** "HE'S FRIENDLY! WALK UP: PAT".

## 4. Mastery
- **Regatta, played twice.** Coach-follower 2960. My style try turned 5 frames later into mark 1: f+200 TOUCHED (−2 s), f+205 **+500**, f+210 +200, f+215 nothing. A 5-frame window is real, practisable skill. The bots agree: coach and casual 2300–2700, expert ~4900 (1.9×).
- **Top end.** There's more than one thing: rounding distance, tack tempo, line honours, ferry surf, and the 2-in-a-row chain.
- **Bay.** Timing alone pays: GOOD-only steps score no combo, while DEAD ON double time is +643 style. Lanes and weaving roughly double that again. Skill clearly shows.

**Hidden tricks:** I found **Bay's SLALOM**. The title demo flashed WATCH THAT MOVE! with "SLALOM X2! +50" mid-weave. My blind weave got only bumps, so it needs real dodges. In the Bike demo the banner coincided with TRACK HOP +60, which is documented, so I didn't pin that one down. I found no others.

## 5. Report sections
1. **Who I am:** Tasha, a completionist UX researcher.
2. **Overall: 8.5/10.** The menus, picker, standings and coaching are now nearly airtight, and most cards add up. **vs California Games: 8.5/10.**
3. **Per event:**
   - Regatta 7.5: coached to silver, with real style room above. Weakest spot: the card.
   - Bay 7.5: the PRESTO card and DEAD ON feedback are crisp. Blind play no longer medals.
   - Off-Leash 6.5: clean dodge prompts, and the gave-up card adds up (50 + forfeit 200 = 2×100).
4. **Top 3 loved:** the coach's order flips at the rounding; "PASS CLOSER = TIGHT ROUNDING"; the WATCH THAT MOVE! demo banner.
5. **Problems:** pt8r8-menu-11644048 [minor], pt8r8-menu-11300984 [minor], the tack-speed message contradiction [minor, unfiled], the unitemised Bay STYLE [minor], "HE'S FRIENDLY!" [note].
6. **What California Games did that this doesn't:** it made you *want* to copy the demo's trick. SLALOM shows for one second and is never named again.
7. **Make it more Toronto:**
   - a "GOOSED!" tally on the Regatta card
   - Bay SLALOM renamed "PATH SHUFFLE"
   - a PRESTO "TAP AGAIN" double-beep
8. **Quote for the wall:** "Five frames separate a +500 rounding from a −2 s bump. That's a sport."

## 6. Is it as good as California Games yet?
Yes, on presentation and fairness it's at par or better. The single biggest thing in the way of being *better* is that Regatta and Bay still don't itemise style. A completionist can't see which skill earned the points, so she can't tell what to practise.
