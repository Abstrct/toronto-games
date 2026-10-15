# pt3 Priya (retro YouTuber, 200k subs, 40-minute California Games retrospective): Round 10

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10:**
- overall 6 → 7 → 7.5 → – → 7.5 → 8 → 8.5 → 8.5 → 8.5 → 8.5
- vs California Games 5 → 6.5 → 7 → – → 7 → 7.5 → 8 → 8.5 → 8.5 → 8.5
- Bike 6 → 6 → 7 → – → 7 → 7 → 7 → 7.5 → 7.5 → 7.5 · Bay 5 → 7 → 7 → – → 7.5 → 7.5 → 7.5 → 7 → 7.5 → 7.5 · Off-Leash 6 → 7 → 7 → – → 6.5 → 7 → 7 → 7 → 7 → 7.5 · Tallboy 6 → 6 → 7 → – → 7 → 7 → 7 → 7.5 → 8 → 7.5 · Regatta 3 → 6 → 6.5 → – → 6 → 7 → 8 → 8 → 8 → 7.5
- Parking (R3 → 10) 5 → – → 7 → 7.5 → 8 → 8 → 8 → 8 · Subway 6 → – → 7 → 7 → 7 → 7 → 7 → 7 (Parking and Subway: card and audio only)

## 1. My round-9 complaints
- **Off-Leash coach-ignorer scores 0: better.** Walking north, I got tackled out for 300. The card now has a DOGS DODGED 0 row, so "HALF THE DOGS" finally has something to point at.
- **CLOSE SHAVE used three ways: fixed.** The names are now SET! (B at +80) → NICE TIMING +400 (+140 to +156) → CLOSE SHAVE +500 (+162). The card says it plainly: "B ON ANY ! = SAFE DODGE / LATER B = MORE PTS: RISKY!"
- **Parking cards in words: fixed.** They use arrows now: "▲ TO THE LINE, ▼+▶ BACK IN".
- **Cramped breakdown rows: better.** Groups now have blank lines between them. The grey sub-rows still sit flush, but they read as itemised.
- **Bike floor: unchanged.** Riding straight still gets 279 with 3 wipeouts.
- **Tiny bike rider: unchanged.**
- **Bike ⚠ baits you into the 501: not seen.** The 501 passed beside me twice with no popup.
- **MATADOR has no tell: unchanged.** 0 of 5 this round: late B, B plus a sidestep, a ball at the spring, a double B and a stand-still B. That's 0 of 18 across rounds.
- **ROLL TACK has no tell: unchanged.** 0 of 3, hiking through fast taps (pt3r9-sail-21658533).
- **Tallboy floor: worse.** See §2.

## 2. Regressions and new issues
- **[major art] pt3r10-bike-71345345.** "HOP THE RAILS: B!" comes up, and RAIL WOBBLE follows 34 frames later. The window is fair, but no crossing rails are drawn. Three frames before the wobble, the lane ahead of the rider is empty. You're hopping an invisible thing, and it'll never make a thumbnail.
- **[minor balance] pt3r10-cops-71748076.** A steady A tap (every 20 or 30 frames) now gets BUSTED about 40% of the way, for 338 to 403. In R9 the same tapping made Spadina for 1281.
- **[minor balance] pt3r10-bay-71750950.** Changing lanes every beat without looking scores 1825 to 1895, good for #4 on the board. Walking straight on the beat scores 1015 with 9 spills.
- **[minor ux] pt3r10-bay-71529428.** The Bay card says "WALK 1000 + TIME 1400" on some runs, which reads as 2400. Other runs itemise it properly: "ON THE 5:42 1000 / 4 SEC AT 40 160". It's the same bug pt8 and pt10 filed for Regatta.
- **[minor ux] pt3r10-sail-71762277.** The coach said "TAP ◀ 4 TIMES". I tapped four times and got "GOOD! TAP ◀ 5 MORE TIMES".
- **Copy vs manual:** a ball at the spring showed **FETCH! +300**. The manual says +100.
- **Changed trick:** the R9 TTC TRANSFER recipe (one hop on the glowing rails) now gives TRACK HOP +50.
- No crashes and no clipping. Audio rms:
  - Title 4124, Bike demo 4608
  - Bay 4588, Off-Leash 4283 (side −18.5 dB), Tallboy 3622, Regatta 3882, Parking 3749, TTC 4794
  - Bike was 1693 when idle (not comparable to R9's 3544).

## 3. Copy: 8.5/10
- **Lands:**
  - "PHOTOBOMBED A TOURIST! SORRY!" and "BUMPED A BANKER! SORRY!"
  - "LAST SIP! 1 MORE SPILL: DECAF", then "DECAF! NO MORE DOUBLE TIME". A warning and then the consequence: textbook.
  - "OOF! RACCOON STOLE THE CAN"
  - "CAR IN BIKE LANE. AGAIN. STEER ◀ ROUND IT"
  - "DOG! PRESS B TO GET SET!" → "RED ! = B NOW FOR +400"
  - Tallboy's "STUCK? TAP A TO SCRAMBLE"
- **Doesn't land:**
  - "WALK 1000 + TIME 1400" (the maths is wrong on sight).
  - "TAP ◀ 5 MORE TIMES" right after I'd done the four it asked for.
  - The Parking card's "NOW! IN THE PANEL: ▼+◀" is cryptic.
  - The Bay demo flashes "BRUSHED PAST! SORRY!" six times in 10 s. To a viewer, the showcase looks clumsy.
- **Rewrite:** "WALK 1000 + 11 S × 40 = 1440".

## 4. Mastery
- **Bay, played twice:**
  - First-timer on the beat: 1015.
  - Style run: 1825 to 1895, with DODGES & CUTS 285 to 335 and PERFECT STEPS 320.
  - The ceiling is real, but the cheap version of it is blind weaving, not reading.
- **Off-Leash:** a 22-frame ladder from SET to NICE to CLOSE SHAVE, told by the wind-up glow and the jingle. Skill shows. This is the CG pattern done right.
- **Hidden tricks by hand:**
  - **Bike TTC TRANSFER: 2 of 3** once I copied the demo (hop the near glowing rail, then hop again across the second). 0 of 5 with single hops. The blue glow is the tell, and the bonus thumbnail is DRAFTING THE 501 with the pantograph spark.
  - **Bay SLALOM: 0 of 2.**
  - **MATADOR: 0 of 5.**
  - **ROLL TACK: 0 of 3.**
  - **LIQUID COURAGE, Parking and TTC:** not tried.
- **Verdict:** yes, there's more than one thing to master. But only Bike's trick has a readable tell.

## 5. Report
**Overall 8.5/10.** The cards and coaching are the best they've been, but there's one new art hole and two floors moved the wrong way. **vs California Games: 8.5/10.**

**Loved:**
1. Drafting behind the 501 in a shower of blue sparks.
2. The Off-Leash timing ladder.
3. The Bay coffee gags and the DECAF warning.

**Top problems:**
1. Invisible rail crossings [major] (pt3r10-bike-71345345).
2. MATADOR and ROLL TACK still have no tell [note] (pt3r9-sail-21658533).
3. The Tallboy blind floor [minor] (pt3r10-cops-71748076).
4. Blind weaving pays on Bay [minor] (pt3r10-bay-71750950).
5. "1000 + TIME" card maths [minor] (pt3r10-bay-71529428).

**What CG did that this doesn't:** you could see every obstacle, and the athlete was big.

**More Toronto:** a streetcar bell on TTC TRANSFER, and a "CROSSING AT SPADINA" sign where the rails cross.

**Quote:** "Hop the rails! …which rails?"

## 6. Is it as good as California Games yet?
It's level on presentation, but not past it. The biggest thing in the way is legibility: you have to be able to see what you're reacting to. That means drawn rails on Bike, and a glow for MATADOR and ROLL TACK like Bike's blue rails.
