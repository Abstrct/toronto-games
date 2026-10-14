# pt3 Priya (retro YouTuber, 200k subs, made a 40-minute California Games retrospective): Round 7

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7:**
- overall 6 → 7 → 7.5 → – → 7.5 → 8 → 8.5
- vs California Games 5 → 6.5 → 7 → – → 7 → 7.5 → 8
- Bike 6 → 6 → 7 → – → 7 → 7 → 7 · Bay 5 → 7 → 7 → – → 7.5 → 7.5 → 7.5 · Off-Leash 6 → 7 → 7 → – → 6.5 → 7 → 7 · Tallboy 6 → 6 → 7 → – → 7 → 7 → 7 · Regatta 3 → 6 → 6.5 → – → 6 → 7 → 8
- Parking (R3 → 7) 5 → – → 7 → 7.5 → 8 · Subway 6 → – → 7 → 7 → 7

## 1. My round-6 complaints
- **Parking LET GO window (pt3r6-pk-990182475): fixed.** "LET GO OF ▲: STOP ON THE LINE" is now up about 40 frames before PAST IT! (it was about 15). I let go at 250 ms and again at 417 ms, and both times got HOLD DOWN+RIGHT: BACK IN. Following the coach at 250 ms reactions scored ONE-MOVE and 934 on spot 1. The card adds up: 200+50+200+100+150+234.
- **The per-tenth line (pt3r6-park-990293324): fixed.** The card now says "WALK 50 A TENTH 150", and 3 tenths × 50 is 150. (The verify tool says PRESENT only because my old condition was just the scene.)
- **TIPS vs TOKENS (pt3r6-bike-990302189): fixed.** The word TIPS is gone. The new wording has its own problem (see 2).
- **Bay never says lanes are the game: fixed.** The intro card's second line is now "RED ! AHEAD? CHANGE LANES." On my off-beat first try I made the train with 1033 (813 in R6).
- **Silent result cards: better.** TTC's PATIENT ZERO card now has audio (rms 966, peak 9.6k), where R6's cards were dead air.
- **Tiny bike rider: unchanged.**

## 2. Regressions and new issues
- [minor ux] **pt3r7-bike-453817.** The Bike WIPED OUT card says "= SCORE 279", then "THIRD WIPEOUT. NOT PAID!" The reason line contradicts the sum shown just above it. (pt3r7-bike-431827 is a duplicate filed mid-ride; ignore it.)
- [minor ux] **pt3r7-sail-434926.** "ZIG-ZAG: WAIT FOR TACK NOW!" reads as "TACK NOW!" at a glance. Also, after each rounding the coach goes quiet for 70–100 frames, right when the new heading matters. When I tapped a stale "▶ 5" about 2.7 s late, the next order was "◀ 6", then "◀ 7", and I ran aground on the pier. When I tapped on time it worked perfectly.
- [note ux] **pt3r7-cops-439176.** Tallboy's line "RUN HURDLES+ROAD 101" is a formula, not a rate. Every other card gives a rate.
- **Bike first-timer floor:** I wiped out three times in about 30 s in both runs (214 and 279). The warnings are fair (HOP THE RAILS about 80 frames ahead, CAR IN BIKE LANE about 60–100 ahead), but riding straight down the bike lane gets you killed.
- **Off-Leash, ignoring the coach:** one DODGE, then I walked through the rest of the dogs, and still scored 0. The card is honest, at least.
- I saw no crashes or slowdown, and no audio clipped anywhere.

## 3. Copy: 8/10
- **Clear and funny:**
  - "RED ! AHEAD? CHANGE LANES."
  - "SET! YOU STEP AS HE LUNGES" → "DODGE! +100"
  - "TACKLED! -150 (SO FRIENDLY)"
  - "JOGGER! ON YOUR LEFT! SPLASH"
  - "CAR IN BIKE LANE. AGAIN."
  - "CHALK! B MID-AIR PAYS X2"
  - "GRABBED THE STICKY POLE!" and "FACE-FIRST IN A BACKPACK!"
  - "HONK! HONK! GOOSED! -2 S"
  - "PUSHED OFF! SAIL ON!"
  - "THE RCYC BAR IS OPEN!" and "#5 ON THE TORONTO BOARD! SO LONG, SEAGULL!" (best card in the game)
  - "PARKED. IT'LL DO."
- **Unclear:**
  - "THIRD WIPEOUT. NOT PAID!" next to a score that was paid.
  - "ZIG-ZAG: WAIT FOR TACK NOW!"
  - "RUN HURDLES+ROAD".
  - "3 HEARTS GONE. NO DOGS!" ("NO DOGS" means the dog points are forfeit, but you have to work that out).
  - "NOT ONE HURDLE, NO POINTS" and "NO LEANING, NO POINTS" are the same template, so the joke wears thin by the second one.
- **Rewrite:** "ZIG-ZAG: WAIT FOR TACK NOW!" → "HOLD IT... I'LL CALL THE TACK."

## 4. Mastery
- **Regatta, two ways.** Ignoring orders (R6) paid 176–394. This time I obeyed the coach late but in the right direction: 2135, with FERRY SURF +400 and 2 bumps, enough for #5 on the board. The expert bot gets 3305 by adding tight roundings, clean tacks and line honours. So the coach gets you to bronze/silver and the rest is skill. That's California Games-shaped.
- **Parking:** 934 on spot 1 at human reactions. Curb (I only got OK), angle, space, one-move, clock and streaks are six separate things to master.
- **Bay:** I made the train at 1033 even though the dots said MISS on most of my steps. The ear bot gets 2629–2798 with style around 909. The beat is skill, and so are the lanes.
- **Gaps elsewhere:** Bike 279 vs bot 5682 and Tallboy 113 vs 5312 are huge. The top end is real, but the bottom is steep.
- **Hidden tricks:** I didn't find any this round. I'm not going to claim one I didn't see.

## 5. Report
**Overall 8.5/10.** Every complaint I filed last round is fixed, and the cards add up on camera. **vs California Games: 8/10.**
- **Bike 7:** the warnings are good, but it's still a 30-second death for a newcomer, and the rider is too small for a thumbnail.
- **Bay 7.5:** the lanes are on the card now.
- **Off-Leash 7:** "SET!" then "DODGE!" reads well.
- **Tallboy 7:** the Kensington row is still the best background in the game. The intro is quiet: rms 1887 in the first 4 s.
- **Regatta 8:** the ferry-wake surf along the Island shore is my thumbnail.
- **Parking 8:** the coach now fits human reactions.
- **TTC 7:** the jokes still land.
- **Audio levels:** title rms 3162; Bay 4495; TTC 4920; Regatta is quiet at 2031; Off-Leash is the narrowest mix (side −20 dB).
- **Attract loop:** about 13 s of title, then HOW TO PLAY, records, and a Bike demo. The demo shows a RAIL WOBBLE: the showcase makes a mistake.

**Loved:** THE RCYC BAR IS OPEN; the ferry surf; Parking's coach.

**Top problems:**
1. The Bike newcomer floor.
2. NOT PAID! (pt3r7-bike-453817).
3. Regatta coach gaps and the WAIT FOR TACK line (pt3r7-sail-434926).
4. Off-Leash still scores 0 for anyone who ignores the coach.
5. RUN HURDLES+ROAD (pt3r7-cops-439176).

**What California Games did that this doesn't:** a podium swell I could check (I still haven't), and an attract demo that never fumbles.

**More Toronto:** a streetcar bell on Bike's DELIVERED card.

**Quote:** "The coach finally talks at human speed. Now make the Bike's first 30 seconds as kind as Parking's."

## 6. Is it as good as California Games yet?
Very close. The biggest thing in the way is the newcomer floor on Bike and Tallboy: three wipeouts or a bust inside about 30 s, worth 100–280 points. Parking, Regatta and Bay now coach you to a real score in the first minute. Bike and Tallboy still punish you before they teach you.
