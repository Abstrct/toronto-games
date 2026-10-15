# pt1 Dana (noob) R9

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9:**
- overall 6 → 7 → 7 → – → 7 → 8 → 7 → 8 → 8
- vs California Games 6 → 7 → 6 → – → 6 → 7 → 7 → 8 → 8
- Bike 7 → 6 → 4 → – → 4 → 6 → 4 → 7 → 8 · Bay 3 → 6 → 6 → – → 6 → 7 → 6 → 6 → 7 · Off-Leash 6 → 6 → 7 → – → 8 → 7 → 8 → 8 → 7 · Tallboy 6 → 4 → 5 → – → 5 → 8 → 8 → 8 → 8 · Regatta 1 → 4 → 5 → – → 6 → 6 → 8 → 8 → 8
- Parking (R3 → R9) 8 → – → 5 → 4 → 5 → 8 → 8 · Subway 4 → – → 4 → – → 4 → 8 → 8

I'm Dana. I react in 20–25 frames, I read the box once, and I quit when I don't know why I lost. This round I medalled in all seven events, and that's a first.

## 1. My round-8 complaints
- **Bay red ! (bay-14135183): better.** At 22 f, following the arrow scored 1361 (4 spills, DECAF) and 1582 (1 spill, no DECAF). Ignoring it scored 1139 with 9 spills. Both arrow runs got bronze. In R8 the arrow got 8 spills.
- **Bike "CAR IN BIKE LANE" far from the lane (bike2-14137600): not seen.** It didn't pop once in my run. `--verify` says PRESENT, but my R8 condition only checked the scene, so it can't tell.
- **Regatta LINE HONOURS paid twice (sail-14136192): fixed.** It's now grey under + STYLE: CLEAN TACKS 200 / LINE HONOURS 300.
- **Copy:** the Bay card is fixed, nearly in my words: "RED ! = SOMEONE IN THE WAY / ▲▼ WHERE THE ARROW POINTS / NO LANE? A = EXCUSE ME". "ROLL TO DOWN+LEFT AT NOW!" is **unchanged**, and so are the formulas on the result cards: "RIDE 1500+20/S", "WALK 500+25/S", "COURSE 1000+15/S". "PASS CLOSER = TIGHT ROUNDING" still shows after the mark: **unchanged**.

## 2. Regressions and new issues
- [minor] **pt1r9-bike0-21399643**: Bike. Hold A from the start and about 5 s in you rear-end a slower car in your own lane: SPLAT, a heart gone, and no coach line first. That happened in both my runs, during the "gentle warm-up".
- [minor] **pt1r9-dog-23072659**: Off-Leash. The record jumped to 10000. My flawless 22 f run (14 dodged, 0 tackles) scored 3855, which is only bronze. Late B or a sidestep tops out around 4200. Nothing on screen tells me where the other 6000 points come from.
- [minor] **pt1r9-sail-23074408**: On the Regatta and Bay cards, the grey style rows are squeezed half a row under + STYLE and the letters touch.
- [minor] **pt1r9-iparking-23075639**: the Parking card's NOW! line (carried over from R8).
- Regatta: "MARK 1 ROUNDED! HOLD COURSE" is followed a beat later by "MARK 1! NOW TAP ◀ 3 TIMES". Hold, or tap?
- No crashes, no soft-locks, no majors.

## 3. Copy: 8/10
**Clear:** "HOP THE RAILS: B!" · "RAILS HOPPED! +80" · "501 BEHIND! STEER ◀" · "SPLAT! RAN INTO A CAR / DROPPED 1 TOKEN" (I knew why I'd lost) · "ZIG-ZAG UP: I'LL CALL TACKS" (lovely) · "TACK NOW! TAP ◀ 5 TIMES" · "GOOD PARK! NEXT: HUG CURB" · "COP CAUGHT YOU: FINED 1/4" · "HOLD B: SIPS PAY UNSEEN" (better than R8's "COP CAN'T SEE").
**Unclear:** "RED ! 200, B MID-LEAP 400+" (mid what? the dog's leap?) · "ROLL TO DOWN+LEFT AT NOW!" · "+ TOKENS+STYLE 650" right under "STYLE 500" (the extra 150 is the tokens, but it took me a minute) · the formulas.
**Rewrite:** "WALK 1000+40/S" → "MADE IT 1000 / 11 S SPARE ×40 = 440".

## 4. Mastery
- **Tallboy, same chalk timing:** dry 2294 (bronze) vs a sip every hop 5729 (silver, #2). That's 2.5×. Extra sips to fill BUZZ got me BUSTED at 3944–4086, and I still never saw LIQUID COURAGE.
- **Off-Leash:** a 22 f B scored 3855, and 70 f with a step toward the dog only 4160. The top end is 10000, but I couldn't find the second skill.
- **Regatta:** both of my tacks were CLEAN TACK +100 (2520, just short of silver at 2600). Tacking with A held during HIKE still gave CLEAN TACK, not ROLL TACK.
- So the expert does pull away (about 2.5× in Tallboy and Off-Leash), and every event has a hidden second layer. A noob can't find any of them.

**Hidden tricks (by hand, at 22 f): 0 landed.** I saw them in the demos: TTC TRANSFER (Bike), SLALOM X2 (Bay), LIQUID COURAGE (Tallboy).
- SLALOM X2: no hint. In 3 runs my dodges never came back-to-back.
- LIQUID COURAGE: 5 tries. The demo's BUZZ bar was about ⅔ red, but nothing marks where "brave" ends and "tipsy" begins.
- ROLL TACK: 1 try. HIKE showed in the HUD, but by the time I tacked it was gone.
- SHE DIDN'T BLINK (Parking): 1 try. The WAIT line lasts about 8 f, so by the time I'd reacted the cyclist had gone.
- OLE! (Off-Leash): 2 tries, nothing.
- I didn't try TTC TRANSFER or LOOK MA. **No event gave me a sound or screen tell I could react to.**

## 5. PLAYTEST.md sections
- **Verdict:** I medalled in all seven events, but none of the clever stuff is mine.
- **Per event:**
  - Bike 8: a 50 s ride, DELIVERED, 2690, my first Bike medal. Rails and potholes hop every time at 22 f.
  - Bay 7: following the arrow finally pays.
  - Tallboy 8
  - Regatta 8: 24 s and "THE RCYC BAR IS OPEN!"
  - Parking 8 and TTC 8: identical to R8 (2852 and 3216).
  - Off-Leash 7: same skill, a lower medal.
- **Honesty note:** I hand-played Bike and Regatta, stopping at each coach popup and acting 22 f after it. Bay, Off-Leash, Tallboy, Parking and TTC were played by my reflex scripts in `build/pt/scratch/pt1/` (22 f after each cue; beat jitter −3..+7 f).
- **Loved:** DELIVERED! SIGN HERE. after a ride I didn't hate · ZIG-ZAG UP: I'LL CALL TACKS · the Bay card in plain words.
- **Top problems:** bike0 (minor), dog (minor), sail card (minor), iparking (minor). Undiscoverable tricks are the design note.
- **CG had:** a trick you could find by wiggling the stick. Here they're in the demo only.
- **More Toronto:** after SPLAT, the driver yells "BIKE LANE'S OVER THERE, BUD".
- **Quote:** "Seven medals, zero tricks. I'm good at this game, but I'm not *in* it."

## 6. Is it as good as California Games yet?
For a first-timer, yes: 8 vs 8, with medals in all seven. The biggest thing in the way now is that a casual player can't find the tricks on their own. CG's tricks felt like secrets I'd found myself; these are only in the demos, and none of them has a tell I can react to.
