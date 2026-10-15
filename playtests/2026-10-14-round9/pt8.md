# pt8 Tasha (completionist/UX researcher): Round 9

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9:**
- overall 5.5 → 7 → 7.5 → 8 → 8 → 8.5 → 8.5 → 8.5 → 8
- vs California Games 5 → 6.5 → 7 → 7.5 → 7.5 → 8 → 8 → 8.5 → 8
- Bike 6 → 6 → 6.5 → 6.5 → 6.5 → 6.5 → 6.5 → 6.5 → 6.5*; Bay 5 → 6 → 6.5 → 7 → 6.5 → 7 → 7 → 7.5 → 7.5; Off-Leash 5 → 5 → 5 → 5.5 → 6 → 6 → 6.5 → 6.5 → 6.5*; Tallboy 4 → 5 → 5.5 → 5.5 → 5.5 → 5.5 → 6 → 6 → 6; Regatta 3 → 4 → 5.5 → 5.5 → 5.5 → 7 → 6.5 → 7.5 → 6.5; Parking 4.5 → 6.5 → 7 → 7.5 → 8 → 8 → 8; Subway 4 → 6 → 6 → 6 → 6.5 → 6.5 → 6.5*
- \* I only played fragments, a baseline run or the card, not a full skilled run. Most of my budget went on two Regattas and the hidden tricks.

## 1. My round-8 complaints
- **Fixed.** pt8r8-menu-11300984: the Regatta card now itemises style. + STYLE 200 has CLEAN TACKS 200 under it, and 1000+15×54 = 1810, +200 = 2010, which adds up. I didn't get a finish card with TIGHT ROUNDING or LINE HONOURS rows on it.
- **Fixed (one sample).** pt8r8-menu-11644048: after a +500 rounding of mark 1, the coach went straight to TACK NOW, with no stray MISS THE BUOY.
- **Fixed.** The Bay STYLE row is itemised: PERFECT STEPS 57. 1240 + 57 − 360 = 937.
- **Fixed.** Off-Leash card: "RED ! 200, B MID-LEAP 400+". "LATE" is gone.
- **Better.** The card now says "DODGE DOGS, THEN PAT THEM!". The popup still just says "HE'S FRIENDLY!".
- **Better.** Tallboy: "HOLD B: SIPS PAY UNSEEN". Still a little cryptic.
- **Worse, in a new way.** The tack-speed contradiction: I tapped 5 times, waited ~2.5 s through "GOOD! TAP ▶ ONCE MORE", tapped once, and got CLEAN TACK! +100. That isn't six taps a second.
- **Fixed.** The Parking spot box itemises everything: 200+50+200+100+150+227 = 927.

## 2. Regressions and new issues
- **[major ux] pt8r9-sail2-21402136.** I obeyed every coach order at 6 taps a second, ~15 f late, and circled mark 2 for 25 s.
  - The order changed with no taps from me: TAP ▶ 4 → 5, then 3 → 5.
  - The second half of a long turn read like a fresh order ("TO MARK 2: TAP ▶ 3 TIMES"). Only once did it say "3 MORE".
  - "TO MARK 2: TAP ▶ 5 TIMES" came straight after "GOOD! HOLD YOUR COURSE", and those 5 taps pointed me dead downwind, away from the mark.
  - ADRIFT IN 5 counted down under "GOOD! TAP ▶ ONCE MORE".
  - I gave up with 454.
- **[minor ux] pt8r9-sail2-21420427.** The Regatta GAVE UP card silently drops the +500 TIGHT ROUNDING and both CLEAN TACKs. Bike shows FORFEIT rows; Regatta should too.
- **[minor ux] pt8r9-sail-21734149.** The records board uses the medal icons for rank 1–3 (FERRYMAN 2800 = bronze) and also for the SOLO thresholds on the same page, where 2800 is silver.
- Unfiled:
  - "RING AHEAD! HOLD YOUR COURSE" is still up 18 f after the HUD has switched to TO MARK 2.
  - Parking spot 2: "LET GO OF ▲" lasts ~24 f before "*DING DING*" replaces it. Letting go 15 f after it appears stops you well short of the line, and the coach then says GAS again.
  - The Tallboy STYLE 181 has no sub-row.
  - Standings ignore A for the first second.

## 3. Copy: 8.5/10
- **Clear:**
  - "590 MORE FOR SILVER" on the results (new, and exactly what a completionist wants)
  - "NEXT: HUG CURB"
  - "RED ! = B NOW FOR +200"
  - "MARK 2 ROUNDED! HOLD COURSE"
  - "SAFE: B ON ! = 100 PER DOG"
- **Funny:**
  - "THE TRAIN DID ALL THE WORK" (idle TTC run)
  - "HONK! HONK! GOOSED! -2 S"
  - "SO LONG, SEAGULL!"
- **Unclear:**
  - The Regatta turn orders above.
  - Off-Leash TACKLED card: "HEARTS GONE: HALF THE DOGS" sits under a card with no DOGS row (0 dogs).
- **Rewrite:** "GOOD! 3 MORE ▶", every time a turn's second half is ordered.

## 4. Mastery
- **Regatta, twice.**
  - First-timer: I followed the coach, touched mark 1 and got goosed. 2010, bronze.
  - Style run, the mark-1 rounding window: turning at f+22 pays +200, f+25 +300, f+28 **+500**, and f+31 touches the mark. A 3-frame staircase is real, learnable skill, and nothing on screen tells you when.
  - The style run then died to the mark-2 coaching. That is the problem: the top end exists, but the coach can sabotage you on the way to it.
- **Blind baselines.**
  - A Bay on-beat walk got 937, no medal, which is right.
  - Tallboy tapping A at 3 per second got 1281, under bronze 2100, which is fine.
  - An idle TTC ride got 0.
- **More than one thing?** Yes: Regatta has rounding distance, tack tempo, gusts (A to hike) and the chain; Bay has timing and lanes.

**Hidden tricks:**
- **Bike: not landed.** The demo shows TRACK HOP +50, then ~12 f later **TTC TRANSFER! +100**, as the courier drifts left across the along-Queen tracks. The tell I spotted is that those rails flash cyan for ~2 frames just before the hop. In ~11 by-hand tries (hop and steer at once, hop-hop, hop then steer) I got RAILS HOPPED +80, TRACK HOP +50 or RAIL WOBBLE, never the transfer.
- **The other six:** no time left. The Off-Leash demo flashes WATCH THAT MOVE! several times, but I couldn't pin which callout it was.

## 5. Report sections
1. **Who I am:** Tasha, a completionist UX researcher.
2. **Overall: 8/10.** The cards finally all itemise, and the "N MORE FOR SILVER" line is lovely, but the Regatta coach can now steer an obedient player in circles. **vs California Games: 8/10.**
3. **Per event:**
   - Parking 8: the coach and the spot box are model UX.
   - Bay 7.5: the itemised card.
   - Regatta 6.5: great skill window, broken mark-2 coaching.
   - Tallboy 6, Off-Leash 6.5: cards add up.
4. **Top 3 loved:** "590 MORE FOR SILVER"; the itemised style everywhere; the Parking spot box.
5. **Problems:** 21402136 [major], 21420427 [minor], 21734149 [minor], the Parking LET GO window [minor, unfiled], the Tallboy STYLE sub-row [note].
6. **What California Games did that this doesn't:** its tricks were landable from what you see. TTC TRANSFER's cyan flash lasts 2 frames.
7. **Make it more Toronto:**
   - The TTC TRANSFER callout could show a paper transfer.
   - GOOSED! could tally on the Regatta card.
   - The cyclist could get a "BIKE LANE!" yell.
8. **Quote for the wall:** "Three frames is the difference between +300 and +500. Now let the coach get me there."

## 6. Is it as good as California Games yet?
On cards and menus it's past it. The single biggest thing in the way is **Regatta coaching consistency**: an obedient player must never be steered away from the mark.
