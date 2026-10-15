# pt8 Tasha (completionist/UX researcher): Round 10

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10:**
- overall 5.5 → 7 → 7.5 → 8 → 8 → 8.5 → 8.5 → 8.5 → 8 → 8.5
- vs California Games 5 → 6.5 → 7 → 7.5 → 7.5 → 8 → 8 → 8.5 → 8 → 8.5
- Bike 6 → 6 → 6.5 → 6.5 → 6.5 → 6.5 → 6.5 → 6.5 → 6.5 → 7*; Bay 5 → 6 → 6.5 → 7 → 6.5 → 7 → 7 → 7.5 → 7.5 → 7.5*; Off-Leash 5 → 5 → 5 → 5.5 → 6 → 6 → 6.5 → 6.5 → 6.5 → –; Tallboy 4 → 5 → 5.5 → 5.5 → 5.5 → 5.5 → 6 → 6 → 6 → –; Regatta 3 → 4 → 5.5 → 5.5 → 5.5 → 7 → 6.5 → 7.5 → 6.5 → 7.5; Parking 4.5 → 6.5 → 7 → 7.5 → 8 → 8 → 8 → –; Subway 4 → 6 → 6 → 6 → 6.5 → 6.5 → 6.5 → –
- \* fragments only (Bike: the 501 trick; Bay: one blind walk). "–" = only the intro card this round. Most of my budget went on two full Regattas.

## 1. My round-9 complaints
- **Fixed.** 21402136, the coach circling mark 2. I obeyed every order at ~15 f and finished with 69 s left and LINE HONOURS (2535). But see 71463475.
- **Fixed.** 21420427: the GAVE UP card shows FORFEIT STYLE 400 (TIGHT ROUNDS 300, CLEAN TACKS 100) plus "STYLE PAYS AT THE LINE". RACE 315 = 250 + 65 for part of the next leg, but the 65 isn't on the card.
- **Fixed.** 21734149: the records board uses plain rank numbers, and there's a new "◀ 1 OF 7 ▶" pager.
- **Unchanged.** "RING AHEAD! HOLD YOUR COURSE" is still up ~15 f after the HUD says TO MARK 3. Now it also goes the other way: "MARK 3! NOW TAP ▶ 4 TIMES" appears ~6 f before the HUD flips to TO LINE!.
- **Unchanged.** Tack speed. I tapped 5 times, got "GOOD! TAP ▶ ONCE MORE", tapped again ~1 s later, and still got CLEAN TACK! +100.
- Not re-tested: the Parking LET GO window, the Tallboy STYLE sub-row, standings ignoring A, the Off-Leash TACKLED card.

## 2. Regressions and new issues
- **[major ux] pt8r10-sail-71407026.** At mark 1 the coach says "MARK 1 ROUNDED! WAIT...". I kept the same pass line and changed only when I turned:
  - +16 f and +22 f: TOUCHED THE MARK.
  - **+28 f: TIGHT ROUNDING +300.**
  - +34 f: nothing.
  - +40 f, the frame NOW TAP ◀ 3 TIMES appears: nothing.
  - +52 f: nothing.

  So the whole window sits under WAIT. An obedient player can never get the move. The follow-up hint "PASS CLOSER = TIGHT ROUNDING" blames the line when the miss came from the timing.
- **[minor ux] pt8r10-sail-71463475.** "GOOD! HOLD YOUR COURSE", then the diamonds go white ~20 f later and "DRIFTED! NOW TAP ▶ ONCE" comes ~45 f later, with no input from me. That happened on 3 of 4 obeyed turns, so the orders look one notch short.
- **Still present: pt8r10-sail-36978487** (filed earlier this round). With three style rows, the finish card goes back to "RACE 1000 + TIME 2050". That reads as 1000 + 2050, but 2050 is race and time together (70 s × 15 = 1050). With two style rows the card is itemised: FINISH 1000, 69 SEC AT 15 1035, RACE 2035. Both totals add up: 2050 + 800 = 2850 and 2035 + 500 = 2535.
- Unfiled:
  - Bay: the HUD reads 5:41:57 but the card says "2 SEC AT 40".
  - On the Off-Leash card, the SOLO "●10200" has no gap after the medal icon.

## 3. Copy: 8.5/10
- **Clear:**
  - "ZIG-ZAG UP: I'LL CALL TACKS" (the best new line)
  - "STYLE PAYS AT THE LINE"
  - "DOCKED EARLY: 250 A MARK"
  - "LET GO OF THE BUTTONS" on the card
  - "B ON ANY ! = SAFE DODGE / LATER B = MORE PTS: RISKY!"
  - "HOLLOW ARROW: GET READY"
- **Funny:**
  - "THE RCYC BAR IS OPEN!"
  - "CAR IN BIKE LANE. AGAIN."
  - "SO LONG, SEAGULL!"
- **Unclear:**
  - "PASS CLOSER = TIGHT ROUNDING": the real lever is turning sooner.
  - "GOOD! HOLD YOUR COURSE" just before DRIFTED!
  - "RACE 1000 + TIME 2050".
- **Rewrite:** "MARK 1 ROUNDED! WAIT..." → "MARK 1! TURN NOW = TIGHT", shown inside the window.

## 4. Mastery (Regatta, twice)
- First-timer, obeying the coach: 2535, bronze. The card was 1000 + 1035 + CLEAN TACKS 200 + LINE HONOURS 300.
- Style run: the mark-1 tight rounding (+300) and a dodged MISS THE BUOY gave 2850, only +12%. Mark 3 never paid a tight rounding at any of the 4 turn timings I tried; the approach line was too wide.
- Skill does show up, and there's more than one thing to master: turn timing, tack tempo, gusts and the line. But the top end hides behind a 6-frame window that the coach tells you to wait through, so the gap stays small. California Games' tricks were things you could see yourself landing.
- Bay, a blind on-beat walk: 789. 1000 + 80 + 29 − 320 = 789, which adds up. DECAF, no medal, which is right.

**Hidden tricks:**
- **Bike TTC TRANSFER: not landed, after ~6 tries this round (~17 in all).** The demo shows a TRACK HOP while drafting the 501, then a second hop about 45 f later across its track. The tell is much better than round 9's 2-frame flash:
  - **On screen:** while you're DRAFTING THE 501 (+60), its pole sparks blue and the along-Queen rails glow cyan for ~15 f in my runs (~50 f in the demo).
  - **Sound:** not judged; I couldn't hear it in the harness.
  - **What beat me:** a cross-street "HOP THE RAILS: B!" kept arriving mid-attempt and my second hop became a RAIL WOBBLE.
- **The other six:** not attempted.

## 5. Report sections
1. **Who I am:** Tasha, a completionist UX researcher.
2. **Overall: 8.5/10.** An obedient sailor now gets round the course, and every card I opened adds up. **vs California Games: 8.5/10.**
3. **Per event:**
   - Regatta 7.5: the coach is finally sound, but the WAIT conflicts with the trick.
   - Bike 7: drafting now has a visible tell.
   - Bay 7.5: the card adds up.
4. **Top 3 loved:** "ZIG-ZAG UP: I'LL CALL TACKS"; the itemised GAVE UP forfeit; the records pager.
5. **Problems:**
   1. 71407026 [major]
   2. 71463475 [minor]
   3. 36978487 [minor]
   4. RING AHEAD and the HUD out of sync [minor, unfiled]
   5. Tack-speed leniency [note]
6. **What California Games did that this doesn't:** it didn't hide the scoring move behind an instruction to wait.
7. **Make it more Toronto:**
   - Show a paper transfer on TTC TRANSFER.
   - A "BIKE LANE!" yell.
   - GOOSED! tallied on the Regatta card.
8. **Quote for the wall:** "The coach said WAIT. The +300 was in the wait."

## 6. Is it as good as California Games yet?
On cards, menus and fairness it's level now. The single biggest thing in the way is that **the style moves aren't taught by the very coach that runs the race**. Make the coach's NOW land inside the tight-rounding window, and make the hint name the real lever.
