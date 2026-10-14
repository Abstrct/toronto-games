# pt7 Kenji (SNES pixel art / SPC700 audio), round 5

**Round 1 → 2 → 3 → 4 → 5:**
- overall 6 → 7 → 7.5 → 8 → 8.5
- vs California Games 5 → 6 → 7 → 7.5 → 8
- Bike 6 → 7 → 8 → 8.5 → 8.5 · Bay 6 → 7 → 7 → 7 → 8 · Off-Leash 6 → 6 → 7 → 7.5 → 7.5 · Tallboy 7 → 7 → 8 → 8.5 → 8.5 · Regatta 4 → 6 → 7 → 7 → 7.5
- Parking 6 → 7 → 7.5 · Subway 5 → 7 → 8

I'm Kenji. I push pixels and write SPC drivers, and I judge the screen and the speaker.

## 1. My round-4 complaints
- Result cards at 8px with empty navy below (pt7r4-bay-951024035): **fixed**. Every card is on 16px rows now. Bay (WALK / + STYLE / − SPILLS / = SCORE), Tallboy (RUN / + STYLE / − COP'S FINE) and Off-Leash all add up, and a coloured fail line fills the gap.
- Solo standings mostly empty (pt7r4-bike-950980660): **fixed**. It now reads "1887 MORE FOR BRONZE", "THE BOARD STARTS AT 2600", with maple-leaf wallpaper behind.
- TTC "CURVE LEFT!" while the arrow points UP (pt7r4-sub-951234092): **fixed**. It's "CURVE! LEAN ▲/▼" and "GO! LEAN ▶" now, with an arrow on the rider too. That's my own rewrite, thanks.
- Parking ticket maths (pt7r4-pk-951187462): **fixed**. HALF IN +150 / $75 TICKET −75 / SPOT +75.
- Parking HUD cram (pt7r4-pk-951149608): **better**. Rows are on a 12px pitch and the lamps are real squares that go red or orange. "◀WHEEL▶" still touches the right edge.
- Tallboy bar in overscan (pt7r4-cops-951109161): **fixed**.
- Demo caption bare over traffic (pt7r4-ttl-951432638): **fixed** (navy band). But see the new issue below.
- Loudness spread (pt7r4-cops-951477379): **better**. Tallboy is up to −18 dBFS. Regatta is the only outlier left.
- Callout strips one glyph tall: **better** in Tallboy and Parking (padded rounded panels), **unchanged** in Bay, TTC and Bike.
- Parking hard cut between spots: **unchanged**. One stale HUD frame shows on the cut.
- Ceremony fireworks / podium clip / sponsor-wall overscan: **not re-tested**. I didn't play a full competition. The verify run's "GONE" desynced at standings, so don't trust it.

## 2. Regressions and new issues
- [minor ux] **pt7r5-bike2-957629393**: the Bike wipeout card lists TTC TOKENS ×50 = 2 and STYLE 80, then "= SCORE 280" is the RIDE row alone. The forfeited rows aren't marked, so the sum looks wrong. The new TIME and TOKENS HUD isn't on the intro card either.
- [minor ux] **pt7r5-park-957610625**: Off-Leash card shows "CROSSING 450 − TACKLES 450 = 0" under "CROSSING PAID BY DISTANCE". Regatta does the same: "COURSE 252 − BUMPS 252 = 0". The penalty landing exactly on the base looks rigged.
- [minor ux] **pt7r5-pk-957620383**: Parking coaching line "TOO FAR OUT. FIX IT, OR A" reads as cut off. The post-park spot box stacks 4 rows at 8px pitch.
- [minor ux] **pt7r5-cops-957708988**: "COP CAN'T SEE YOU: HOLD B!" is up for about 3 frames before "OOF! SPILLED!" overwrites it.
- [minor art] **pt7r5-ttl-957735387**: Bike callouts are bare orange text ("RAIL WOBBLE! HOP RAILS: B" crosses a white car). Regatta's red "IN IRONS! STEER RIGHT ▶▶" floats on water. And the attract demo shows a RAIL WOBBLE.
- [minor audio] **pt7r5-sail-957664885**: Regatta plays at −23 dBFS while the others sit at −16.5 to −19. DC offset is still −0.2k to −3k on every track.
- Unfiled:
  - Bay judge words (PERFECT/EARLY/MISS) sit at x=0–60, far from the walker's eye line.
  - "COMBO X2" is jammed under GROOVE.
  - The Tallboy "PTS 82 X1 BUZZ" row has no gap.
  - The walker clips through people in the neighbouring lane.

## 3. Copy: 7.5/10
**Clear:**
- "SOLID: D-PAD THAT WAY NOW"
- "LEFT/RIGHT: TURN  A: HIKE" (the old two-controls muddle is gone)
- "B: SIP WHILE COP CAN'T SEE" (ground sips are explained at last)
- "HOLD DOWN+RIGHT: BACK IN" / "GET READY: DOWN+LEFT SOON"
- "COP CAUGHT YOU: FINED 1/4"

**Jokes that land:**
- "THE 5:42 LEFT WITHOUT YOU"
- "BUMPED A BANKER! SORRY!"
- "HOT DOG CART! OOF! SORRY!"
- "SO LONG, DECAF!"
- the COFFEE meter turning into red **DECAF** when empty, which is the best HUD gag in the game

**Unclear:**
- "TOO FAR OUT. FIX IT, OR A"
- "TAP A AT CHALK. RED: HOLD" (hold what?)
- Bay card "LEFT, RIGHT ON BIG DOTS" never mentions DOUBLE TIME, which is where the score is
- Regatta HUD "MARK 2/3" when you've rounded 1 (heading-for or done?)
- "CROSSING PAID BY DISTANCE" on a 0

**Rewrite:** "TOO FAR OUT. FIX IT, OR A" → "TOO FAR OUT: FIX IT, OR A = TICKET".

## 4. Mastery
- **Bay:** the gap is clear. As a first-timer I tapped ◀ ▶ "roughly in time", drifted into MISS, got pinned on a cart and scored 507, MISSED THE TRAIN. Then I locked to the beat (PERFECT is about ±2 frames, GOOD ±4) and stepped on the small dots too. That run made the train with 7 s left, scored 2112 and went #4 on the board, even though I never dodged a single "!" (8 spills). That's 4× the first-timer, and a dodging expert would go higher. It's the closest thing here to CG's trick ladder.
- **Tallboy:** the gap is huge. A take-off ON THE CHALK plus a mid-air sip shows "SIP 'N' HOP X3! +24" on one bench. My two first-timer runs were 266 and 392 (busted). The cops_eyes bot reaches 5342.
- **Bike:** it doesn't separate yet. Both of my runs were around 250 because a wipeout forfeits all style and tokens, so the first-timer never sees what skill would have paid.

## 5. Report
1. Kenji, pixel art and audio.
2. **8.5/10**: the screens around the events finally got the 16 pixels they needed. vs CG: **8/10 as good**.
3. Per event:
   - Bike 8.5: TOKENS and TIME give the ride a goal; the callouts are still bare text.
   - Bay 8: it's a real rhythm game now. Royal Bank gold facade, DECAF.
   - Off-Leash 7.5: lovely autumn trees and gate arch; the card maths stings.
   - Tallboy 8.5: panel popups, the bench sprawl, ON THE CHALK.
   - Regatta 7.5: the water finally moves (wave dabs), but the music is quiet.
   - Parking 7.5: the officer tickets the windshield, the rotated car reads well, the cut is still hard.
   - TTC 8: the curve arrow and words agree, the gags are drawn.
4. Loved:
   - COFFEE→DECAF
   - the Bay PERFECT/COMBO feel on the beat
   - every card adds up on 16px rows
5. Problems:
   - [minor] pt7r5-bike2-957629393
   - [minor] pt7r5-park-957610625
   - [minor] pt7r5-cops-957708988
   - [minor] pt7r5-ttl-957735387
   - [minor] pt7r5-sail-957664885
6. CG transitions between scenes and spots; one callout style everywhere.
7. Toronto: Green P tow truck for TOWED; "PLEASE STAND CLEAR OF THE DOORS" chime on TTC STAND CLEAR!; a PRESTO-tap SFX on the gold dot.
8. Quote: "The numbers got their 16 pixels. Now give the callouts a box."

## 6. As good as California Games?
Nearly (8/10). The biggest remaining gap is presentation consistency: three different callout styles (panel, band, bare text), hard cuts where CG wiped, and Bike's forfeit maths hiding skill. The core events now hold up.
