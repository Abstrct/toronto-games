# pt8 Tasha (completionist/UX researcher): Round 6

**Round 1 → 2 → 3 → 4 → 5 → 6:**
- overall 5.5 → 7 → 7.5 → 8 → 8 → 8.5
- vs California Games 5 → 6.5 → 7 → 7.5 → 7.5 → 8
- Bike 6 → 6 → 6.5 → 6.5 → 6.5 → 6.5; Bay 5 → 6 → 6.5 → 7 → 6.5 → 7; Off-Leash 5 → 5 → 5 → 5.5 → 6 → 6; Tallboy 4 → 5 → 5.5 → 5.5 → 5.5 → 5.5; Regatta 3 → 4 → 5.5 → 5.5 → 5.5 → 7; Parking 4.5 → 6.5 → 7 → 7.5; Subway 4 → 6 → 6 → 6

## 1. My round-5 complaints
- **Fixed.** Regatta hands-off rounding mark 1 by itself (pt8r5-sail-957700622). The idle card now reads MARKS ROUNDED 0 / "HANDS OFF THE HELM PAYS 0".
- **Fixed.** Bike failed card. The forfeit is now a grey row under the sum: "FORFEIT TIPS, STYLE 100". Tips and style still share one number, though.
- **Fixed.** Parking coach order on spot 3. The card now says "SPOT 3: TIGHT, 25 S, BIKES", and DING DING comes before BACK IN.
- **Fixed.** Parking box stutter and squashed rows. It now heads "NICELY DONE." / "IT'LL DO.", rows are spaced, and the HUD moves by exactly the SPOT line (1325, +656, +711 = 2692). I had no hits this run, so I couldn't re-test the −175 case.
- **Fixed.** Regatta arrow unexplained. The card says "YELLOW ARROW: NEXT MARK / GREEN DIAMONDS: ON COURSE".
- **Fixed.** B on the intro card ("B OTHER EVENT"), and the first A being eaten: practice accepts A at 15 f, and compete shows "HAND THE PAD TO…" for about 80 f, then "PRESS A WHEN READY".
- **Fixed.** Final standings now default to REMATCH.
- **Fixed.** "STANDING STILL PAYS 0" became "NO LEANING, NO POINTS" (TTC). PATIENT ZERO now appears once.
- **Better.** Rates now stated: COURSE +25 A SEC, BUMPS (2 S EACH), WALK 1000+40/S, SPILLS 40 EACH, RIDE 40 A LEG. Still missing: Bike RIDE (= metres/4), Tallboy RUN, and the Regatta STYLE 1140, which isn't itemised.
- **Fixed.** A Bay first-timer can't finish: plain on-beat taps made the 5:42 with 10 s spare.
- **Unchanged.** A tilted parked car still looks smeared and double-edged (pt8r5-parkx).

## 2. Regressions and new issues
- [minor ux] **pt8r6-sail2-989895802**: in Regatta, after mark 3 I sailed along the dotted finish line, over the red pin. It didn't count. The coach said "TO THE LINE: TAP ◀ 8 TIMES" and the run went ADRIFT on 988 with all 3 marks rounded.
- [minor ux] **pt8r6-ttc1-990145044**: I leaned on one leg only and the TTC card says LEGS LEANED 2. GERMS reads 21 beside "20 GERMS: STYLE IS VOID".
- [minor ux] **pt8r6-comp-990341617**: the final standings row "PLAYER 2 0 0 0" reads as "PLAYER 20 0 0".
- [note ux] **pt8r6-dog-990407595**: "75 FOR EVERY TENTH WALKED" sits beside CROSSING 315. (pt8r6-dog-990397853 is a duplicate I filed at the wrong frame. Ignore it.)
- Unfiled:
  - Tallboy hands-off says "COP CAUGHT YOU: FINED 1/4" on 0, with no fine row. It's the only event without a hands-off line.
  - Bay: blind walking took 8 spills, went DECAF and still made the train. Lane changes are optional, and DECAF does nothing I could see. The Bay card never mentions Y/PRESTO.
  - Parking TIME LEFT is fractional (+225 with the HUD on 23).
  - The crooked spot-2 car still got ANGLE GOOD.

## 3. Copy: 8.5/10
**Clear:**
- Regatta coach tap counts: "TACK NOW! TAP ▶ 5 TIMES" and "MARK 2 IS UPWIND: ZIG-ZAG!". I followed them cold and finished.
- Parking coach: "KEEP DOWN+RIGHT: GET READY", then "NOW! ROLL TO DOWN+LEFT", then "STRAIGHT! LET GO TO STOP". All three work at 15 f.
- "HAND THE PAD TO TASHA".

**Funny:** "SO LONG, DECAF!" (said while my HUD read DECAF), "OOF! RACCOON STOLE THE CAN", "THE RCYC BAR IS OPEN!", "HONK! HONK! GOOSED! −2 S".

**Unclear:**
- "75 FOR EVERY TENTH WALKED" (see above).
- "GOLD DOT ALL LEG: SURF X3" is telegraphic.
- Regatta: "AGROUND! −2 S" for hitting the ferry dock.
- Regatta: "IN IRONS! TAP ◀ ONCE" flashed while my green diamonds showed I was on course.
- Regatta: "ALL 3! NOW CROSS THE LINE!" doesn't say which way.

**Rewrite:** "ALL 3! CROSS BETWEEN THE PINS ▲".

## 4. Mastery
- **Bay:** the gap is real. On-beat taps scored 1199 (WALK 1400 + 119 − 320). Double time, same lanes, scored 1882 (1680 + 522 − 320, #4). Both cards add up.
- **Regatta:** a first-timer following the coach scored 3290 (2150 + style 1140, #3, silver). The top end has several separate things to master: graded TIGHT ROUNDING X2/X3, CLEAN TACK, FERRY SURF, and LINE HONOURS for no bumps. My style attempt died at the finish line, so I can't show the ceiling.
- **Parking:** the coach flattens the curve. As a first-timer obeying it at 15 f I scored 2692, which beats my practised round-5 2620. Skill now mostly means "react faster to the coach".

So skill does pay, but nothing yet rewards a California Games-style trick you discovered yourself rather than one you were told about.

## 5. Report sections
1. **Who I am:** Tasha, a completionist UX researcher.
2. **Overall: 8.5/10.** The cards add up everywhere and the coaches teach. **vs California Games: 8/10.**
3. **Per event:** see the scores above.
   - Regatta jumped: tap counts plus arrow and diamonds.
   - Parking: the best boxes in the game.
   - Bike shows no coach on the road to teach style.
   - I played Tallboy and Off-Leash only lightly.
4. **Top 3 loved:**
   - the Regatta tap-count coach
   - Parking's itemised spot boxes
   - "N MORE FOR GOLD" with the board-bump line
5. **Problems:** see section 2, ranked in that order.
6. **What California Games did that this doesn't:** a trick you find for yourself that the score shows off.
7. **Make it more Toronto:**
   - "ACROSS THE LINE AT THE RCYC" on the Regatta finish
   - a "GREEN P OWES YOU $75" ticket tally
   - a PRESTO beep on the Bay gold dot
8. **Quote for the wall:** "I followed the coach and made the podium. Then I sailed straight down the finish line and it didn't count."

## 6. Is it as good as California Games yet?
Very close. The menus, records board, hand-off and arithmetic are better than California Games now. The biggest gap is depth: coaches tell you the trick, so an expert pulls away only by reacting faster. I'd like a trick the coach never mentions.
