# pt7 Kenji (SNES pixel art / SPC700 audio), round 9

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9:**
- overall 6 → 7 → 7.5 → 8 → 8.5 → 9 → 9 → 9 → 9
- vs California Games 5 → 6 → 7 → 7.5 → 8 → 8.5 → 8.5 → 9 → 9
- Bike 6 → 7 → 8 → 8.5 → 8.5 → 9 → 8.5 → 9 → 9 · Bay 6 → 7 → 7 → 7 → 8 → 8.5 → 9 → 9 → 9 · Off-Leash 6 → 6 → 7 → 7.5 → 7.5 → 8 → 8 → 8.5 → 8.5* · Tallboy 7 → 7 → 8 → 8.5 → 8.5 → 8.5 → 8.5 → 8.5 → 8.5 · Regatta 4 → 6 → 7 → 7 → 7.5 → 7 → 7 → 8 → 8.5
- Parking 6 → 7 → 7.5 → 8 → 8.5 → 8.5 → 8.5* · Subway 5 → 7 → 8 → 8.5 → 8.5 → 9 → 9*
- (*) card and audio checked only; not played this round.

## 1. My round-8 complaints
- **Regatta HUD ghost behind the result card (pt7r8-sail-11736809): fixed.** The ADRIFT card has one clean border now. A sprite still pokes over its top-right corner.
- **Tip held the coach line after a mark (pt7r8-sail-11753048): fixed as far as I saw.** After mark 1 the order came straight away: "MARK 1! NOW TAP ◀ 3 TIMES". "PASS CLOSER = TIGHT ROUNDING" showed only once I was back on course with green diamonds.
- **Red "MISS THE BUOY!" after a clean rounding: fixed.** I didn't see it.
- **Regatta −0.5 dBFS peak: better.** It peaks at −1.1 dBFS now, with no clipping.
- **"TACK NOW! TAP ◀ ONCE": not retested.** This time the order read "TACK NOW! TAP ◀ 5 TIMES".
- **Empty Off-Leash demo panel, and TAP FASTER at 6/s: not retested.**
- **Off-Leash and Bay card shorthand: fixed.** Off-Leash reads "SAFE: B ON ! = 100 PER DOG / RED ! 200, B MID-LEAP 400+". Bay reads "RED ! = SOMEONE IN THE WAY … NO LANE? A = EXCUSE ME".

## 2. Regressions and new issues
- **[minor art] pt7r9-bay-21820481.** On the Bay finish card, the grey "PERFECT STEPS 127" row sits 8 px under "+ STYLE 127" with no gap, so the shadows touch. The empty row under PLAYER 1 is free.
- **[minor art] pt7r9-bike-21467193.** A white sidewalk sprite draws over the right border of the Bike intro card and the WIPED OUT! card.
- **pt7r9-bike-21402812: withdrawn, my error** (note filed). "CAR IN BIKE LANE. AGAIN. STEER ◀ ROUND IT" was a warning about the next car, which was still off screen, not the taxi beside me. I ignored it and that car hit me. That's good coaching. A stopped car still has no hazard-blinker tell, though; amber blinks would sell it.
- **Unfiled:**
  - I tapped ◀ once, still went ADRIFT, and the card says "HANDS OFF THE HELM PAYS 0".
  - When I ran aground, "PUSHED OFF! SAIL ON!" came up without my tapping.
  - Audio is healthy. Song AC RMS runs −16.9 to −18.5 dBFS (Bike idle −19.4), DC is within ±42 on every song, and the fail sting decays to silence.

## 3. Copy: 9/10
- **Clear:**
  - "RED ! = SOMEONE IN THE WAY"
  - "CHALK! B MID-AIR PAYS X2"
  - "RAILS HOPPED! +80 / ANOTHER TRICK IN 2 S = X2"
  - "WIPED OUT! … THIRD WIPEOUT. NO DELIVERY / PAID FOR THE RIDE ONLY", which is an honest card
- **Inconsistent:**
  - Parking spells out "HOLD DOWN+RIGHT, ROLL TO DOWN+LEFT" and Regatta writes "LEFT/RIGHT", while Bay and Bike use the ◀ ▶ glyphs.
- **Unclear:**
  - "HANDS OFF THE HELM" after I'd touched the helm.
- **Rewrite:** "LET GO OF THE HELM: PAYS 0" → "ONE TAP ISN'T SAILING: 0".

## 4. Mastery
- **Bay, first-timer** (big dots ±3 f, lane-blind): 1167, MADE THE 5:42, 11 spills, DECAF. That's the same as round 8's 1119. I ran out of budget for the style run. Round 8's numbers (1.35× for double time, about 4k for the lane-reading bots) should still hold.
- **Tallboy take-off** is graded every 4 frames: 86 / 81 / 76 for the same crate. That's a real timing skill.
- **Bike rail hop:** pressing B 12, 20 or 30 f after HOP THE RAILS: B! all paid +80. That's kind to newcomers, but the rails no longer separate players. Skill on the bike now lives in tokens, close calls and chains.
- **Hidden tricks:** I landed **0** by hand.
  - **Bike:** I found the tell in the demo. For 4 frames (2620–2623) all four in-lane rails flash cyan, and a broadband SPC crackle fires on the same frame (an HF spike about 30× the bed). The demo hops 3 f later: TRACK HOP +50, then TTC TRANSFER +100. It's a lovely, readable tell, but 4 frames is under my 12 f reaction unless it's anticipated. In 40 s of my own riding, with the 501 passing from behind, the rails never flashed. I couldn't tell what sets it up; in the demo the 501 was ahead.
  - **Bay:** the demo still shows SLALOM X2 +50. I didn't attempt it.
  - **Other events:** not attempted.

## 5. Report
1. Kenji, pixels and SPC.
2. **9/10.** Every Regatta presentation complaint I had is closed, and the cards finally read in plain words. vs CG **9**.
3. Per event:
   - **Bike 9:** steel rails, honest coach forecasts, a generous hop window.
   - **Bay 9:** good beat strip; the card sub-row is cramped.
   - **Tallboy 8.5:** the take-off grades work.
   - **Regatta 8.5:** a clean card, an immediate order after the mark.
   - **Off-Leash, Parking, TTC:** cards and audio only.
4. Loved:
   - the cyan rail crackle (flash plus SFX is textbook)
   - the 2.4 dB song spread holds
   - plain-words intro cards
5. Problems:
   - [minor] pt7r9-bay-21820481
   - [minor] pt7r9-bike-21467193
   - [minor] Bike crackle is only 4 f and I never saw it outside the demo
   - [minor] "HANDS OFF THE HELM" copy
   - [minor] glyph and word inconsistency across cards
6. CG's tricks could be stumbled into. Here the tell is beautiful but too short, and I can't find the setup.
7. Toronto ideas:
   - a Porter prop plane over the harbour
   - the TTC "PLEASE STAND CLEAR" chime
   - amber hazard blinkers on the car in the bike lane (that's Toronto)
8. Quote: "The rails crackle blue. Let them crackle long enough to answer."

## 6. As good as California Games?
About 9: yes on presentation. The biggest thing in the way is still **landable hidden tricks**. The Bike tell exists now (cyan flash plus crackle), but it lasts 4 frames and its setup isn't readable. Make the tell a warning that lasts about 15 f or more before the window, not the window itself.
