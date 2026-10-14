# pt7 Kenji (SNES pixel art / SPC700 audio), round 6

**Round 1 → 2 → 3 → 4 → 5 → 6:**
- overall 6 → 7 → 7.5 → 8 → 8.5 → 9
- vs California Games 5 → 6 → 7 → 7.5 → 8 → 8.5
- Bike 6 → 7 → 8 → 8.5 → 8.5 → 9 · Bay 6 → 7 → 7 → 7 → 8 → 8.5 · Off-Leash 6 → 6 → 7 → 7.5 → 7.5 → 8 · Tallboy 7 → 7 → 8 → 8.5 → 8.5 → 8.5 · Regatta 4 → 6 → 7 → 7 → 7.5 → 7
- Parking 6 → 7 → 7.5 → 8 · Subway 5 → 7 → 8 → 8.5

## 1. My round-5 complaints
- Bike forfeit rows (pt7r5-bike2): **fixed**. The card now ends "= SCORE 295" with a grey "FORFEIT TIPS, STYLE 320" below it, and the intro card says TOKENS PAY 50 ON DELIVERY.
- Off-Leash "450 − 450 = 0" (pt7r5-park): **fixed**. It shows the full "− TACKLES X150 450" and "SCORES NEVER GO BELOW 0".
- "TOO FAR OUT. FIX IT, OR A" (pt7r5-pk): **fixed**. The line is now "TOO FAR OUT! A = $75 TICKET". The spot box is still 4 rows at an 8px pitch: **unchanged**.
- Tallboy "HOLD B" flash (pt7r5-cops): **better**. I couldn't reproduce it, and each coach line held for 1–2 s in my films.
- Bare callouts (pt7r5-ttl): **fixed**. All seven events use the same rounded navy panel now ("RAIL WOBBLE! HOP RAILS: B", "IN IRONS! TAP ▶ 4 TIMES"). This was my biggest ask.
- Regatta at −23 dBFS (pt7r5-sail): **fixed**. Every song now sits between −16 and −18 dBFS AC RMS. The DC offset is **worse** (see below).
- Parking hard cut: **fixed**. There's a dip to black of about 10 frames and no stale HUD frame.
- Regatta "MARK 2/3": **fixed** ("TO MARK 2"). Bay card now mentions DOUBLE TIME: **fixed**. Tallboy "RED: HOLD": **fixed** ("RED CHALK: HOLD A").
- **Unchanged**:
  - Bay judge words still sit at x=0, far from the walker.
  - The walker still overlaps tourists.
  - Tallboy "PTS 520 X1 BUZZ" is still crammed.

## 2. Regressions and new issues
- **[major ux] pt7r6-sail-991962863**: My first-time Regatta ended at 371 with 66 s left on the clock.
  - I overshot mark 2 and ended up on the north beach. The coach said "TO MARK 2: TAP ▶ 3 TIMES". I tapped three times and the heading didn't change on the sand.
  - "ADRIFT! GETTING NOWHERE" appeared about 2 s before the race ended. The ADRIFT clock kept running while I was obeying the coach. (The finding's title says ~1 s; I measured ~2 s on a re-run.)
- **[minor audio] pt7r6-au-sail-989924052**: The DC offset has grown.
  - Regatta sits at −2.8k/−4.6k, and the ADRIFT alarm drives it to −8.4k, which is −12 dBFS of pure DC.
  - When the Bike song stops on the results card, the DC drops from −2.9k to 0 in 50 ms. On real speakers that's a thump.
- **[minor ux] pt7r6-parkt-992522198**: The tackled card says "75 FOR EVERY TENTH WALKED" above CROSSING 201, which isn't a multiple of 75. The three footer lines also butt into PRESS A.
- Unfiled:
  - Tallboy's two-line panel "RACCOON RUN! +16 / 16 X1 CHAIN" has no leading, and it says 16 twice.
  - Regatta flashes an empty coach panel for 1 frame between messages (@1019).
  - "TIGHT ROUNDING! +310" arrives after "MARK 2 IS UPWIND", so the reward comes 1.5 s late and out of order.
  - The Regatta HUD label "HIKE" touches its bar.
  - The Off-Leash walker's head draws over the gate arch.
  - Parking never says that the spot box advances on its own. I pressed A to dismiss it and got "THAT'S NOT A SPOT!" on spot 2.

## 3. Copy: 8/10
**Clear:**
- "GAS ▲: REAR BUMPER TO LINE" → "LET GO! STOP ON THE LINE" → "PAST IT! ▼ BACK TO THE LINE" is a textbook coach.
- "SET! YOU STEP AS HE LUNGES"
- "CRATES! TAP A AT THE CHALK"
- "IN IRONS! TAP ▶ 4 TIMES"

**Jokes that land:**
- "TACKLED −150 (HE'S FRIENDLY)"
- "PHOTOBOMBED A TOURIST! SORRY!"
- "GRABBED THE STICKY POLE!"
- "SO LONG, SQUIRREL!"
- "UNION! EVERYBODY OFF!"

**Unclear:**
- "SAFE: B WHEN ! SHOWS: 50" (a bare number at the end)
- "75 FOR EVERY TENTH WALKED"
- "MARK 2 IS UPWIND: ZIG-ZAG!" (which way first?)
- "TO MARK 2: TAP ▶ 3 TIMES" while aground
- "LEGS LEANED"

**Rewrite:** when beached, show "AGROUND! TAP ◀ TO BEAR OFF" and count down "ADRIFT IN 3…".

## 4. Mastery
- **Bay:** a first-timer tapping "about in time" scored 344 (MISSED THE TRAIN). Locked to the beat (~30.25 f) in DOUBLE TIME without dodging anyone, I scored 1454, #5 on the board. That's 4.2×, and dodging is a second skill on top.
- **Off-Leash:** a safe B at 15 f reactions gave 9 dodges for 1890. A bold B as the dog lunged gave 2695, and 4 f later it was a tackle. That's only 1.4× from timing. Pats are the second axis: the park_ace bot reaches 7100.
- **Tallboy:** my hands got busted twice (217, 529) because BUZZ management and chalk timing fight each other. It's real depth, but it's punishing.
- **TTC:** 15 f reactions scored 3456 (#4). Twitchy 3 f leans scored 2025 with 5 germs. It rewards control, not speed. That's right.

Skill shows like CG's in Bay and Off-Leash. Tallboy and TTC have two things to master.

## 5. Report
1. Kenji, pixels and SPC.
2. **9/10**: one panel style, cards that add up, songs at matched levels. vs CG **8.5/10**.
3. Per event:
   - **Bike 9:** panels over traffic, honest forfeit line.
   - **Bay 8.5:** Royal Bank gold, panel band; the judge words are still adrift.
   - **Off-Leash 8:** autumn reds, the dog's pat-heart.
   - **Tallboy 8.5:** the TIPSY raster wobble on the storefronts is the best effect in the game.
   - **Regatta 7:** the skyline with the dome is gorgeous, but the beach-ADRIFT trap ended my first race.
   - **Parking 8:** the coach and the fade.
   - **TTC 8.5:** tunnel windows going dark, the germ sprite.
4. Loved:
   - the TIPSY wobble
   - one callout style everywhere
   - the Parking coach line
5. Problems:
   - [major] pt7r6-sail-991962863
   - [minor] pt7r6-au-sail-989924052
   - [minor] pt7r6-parkt-992522198
   - [minor] Tallboy two-line panel leading (unfiled)
   - [minor] Bay judge words at x=0 (unfiled)
6. CG's surf and BMX had a ceremony between every run. Here the transitions are still blinks, not wipes.
7. Toronto ideas:
   - a Billy Bishop Porter prop plane crossing the Regatta sky
   - PRESTO "beep" on Bay's gold dot
   - "PLEASE STAND CLEAR OF THE DOORS" chime sample on TTC
8. Quote: "Every callout got its box. Now high-pass the DC."

## 6. As good as California Games?
Close (8.5). The presentation is there now. The single biggest thing in the way is **Regatta's first-timer experience**. It's the only event where following the on-screen advice can end your race.
