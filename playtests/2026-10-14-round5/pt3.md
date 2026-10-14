# pt3 Priya (retro YouTuber, 200k subs, made the 40-minute California Games retrospective): Round 5

**Round 1 → 2 → 3 → 4 → 5:**
- overall 6 → 7 → 7.5 → – → 7.5
- vs California Games 5 → 6.5 → 7 → – → 7
- Bike 6 → 6 → 7 → – → 7 · Bay 5 → 7 → 7 → – → 7.5 · Off-Leash 6 → 7 → 7 → – → 6.5 · Tallboy 6 → 6 → 7 → – → 7 · Regatta 3 → 6 → 6.5 → – → 6
- Parking (R3→4→5) 5 → – → 7 · Subway 6 → – → 7

## 1. My round-4 complaints
- **Parking attract demo frozen: unchanged.** The car turns once and sits wedged against the white car from TIME 29 until METER MAID! 10 SECONDS!. The coaching line is still overprinted by DEMO – PRESS START (pt3r5-pkdemo-957275610).
- **Parking result arithmetic: fixed.** The spot box itemises every line (+200 PARKED, CURB OK +50 … SPOT +840). Spots 840 + 830 − 225 = 1445, and the card's PARKING 1050 + STYLE 770 − DINGS+FINES 375 = 1445. I could explain it on camera.
- **Parking card missing "pull up first": fixed.** The card says "UP: REAR BUMPER TO LINE", and live coaching follows (GAS ▲ → HOLD DOWN+RIGHT → GET READY → NOW! ROLL TO DOWN+LEFT → STRAIGHT! LET GO TO STOP). Reacting about 15 frames after each prompt, I parked GOOD/GREAT on my first try.
- Carried over from R3: the attract loop now includes TTC (a good demo, GOLD DOT SURF X2) and Parking (broken, above). **TTC skill cliff: fixed.** The 250 ms human scores 3188, just under silver (3333); the expert scores 6648. **Podium PRESS A too early: better.** You now get about 15 s of marquee, fireworks and City Hall before PRESS A appears. Still no medal on the athlete.

## 2. Regressions and new issues
- [major ux] pt3r5-park-957538336. Off-Leash TACKLED card: CROSSING 209 + STYLE 20 − TACKLES 229 = 0, sitting under "CROSSING PAID BY DISTANCE". The penalty is exactly whatever reaches zero, so the card looks rigged.
- [major ux] pt3r5-sail-957560909. Regatta OUT OF TIME card: COURSE 364 − BUMPS 364 = 0 under "250 PER MARK ROUNDED" (1 mark rounded). Same clamp, same lie.
- [minor ux] pt3r5-bike-957424685. Bike WIPED OUT card lists TTC TOKENS 2 and STYLE 80, but SCORE = RIDE 280. Nothing says they're forfeited.
- [minor ux] pt3r5-bay-957639801. Bay coffee drains to "OUT OF COFFEE! HALF GROOVE" at ~30 s, even when every step is PERFECT. Neither coffee nor DOUBLE TIME is on the card. There were also 14 lag frames early in Bay.
- Not filed: in a 2P game, an A press 66 frames after P2's UP NOW card appeared started P2's countdown. The lockout is only about 1 s.

## 3. Copy: 7/10
Clear and funny: PHOTOBOMBED A TOURIST! SORRY!, JOGGER! ON YOUR LEFT! SPLASH!, FACE-FIRST INTO A BACKPACK!, GRABBED THE STICKY POLE!, STANDING STILL PAYS 0, OOF! SPILLED! HE'S GAINING, COP'S WATCHING! DON'T SIP!, SO LONG, TOWTRUCK!, LET GO OF THE BUTTONS. The Parking coaching is the best tutorial in the game.
Didn't match what happened:
- "CROSSING PAID BY DISTANCE" and "250 PER MARK ROUNDED" both appear on a 0 score.
- "HOP RAILS, DODGE LATE: X8": x8 of what?
- "DING DING! BIKE! WAIT FOR IT": I didn't wait and nothing happened.
- The Parking spot box opens with "PARKED." and then "PARKED +200", in cramped lines.
- Bay's coffee and GROOVE are never introduced.

Rewrite: "THIRD TACKLE ENDS THE WALK / TACKLES ATE YOUR CROSSING". Better still, pay the distance and print what each tackle costs.

## 4. Mastery
Bay, played twice:
- First-timer (taps jittered ±5 frames on the big dots): 1610, bronze, style 50.
- Style run (on the beat plus DOUBLE TIME): 2406, style 626.

Style shows up, but spills (8 both times) decide gold, and rhythm alone can't get there. From the bot curves, a 250 ms human scores about half the expert everywhere: Bike 3914/7252, Off-Leash 2180/4165, Tallboy 2862/5342, TTC 3188/6648. That's a healthy California Games-style gap. The gap that hurts is between a first-timer and a competent player. My blind first runs scored Bike 80–280, Off-Leash 0, Tallboy 111, Regatta 0 and TTC (idle) 0. Parking is the most learnable: the same inputs paid 840 and 830 on spots 1 and 2.

## 5. Report
**Overall 7.5/10.** This is the best-presented build yet, but four events end a first-timer's minute on a 0 card. **vs California Games: 7/10 as good.**
- **Bike 7:** the rider is tiny for a thumbnail. Weaving gave 3 wipeouts in 17 s, while holding a straight line lasted 43 s.
- **Bay 7.5:** "on the beat" is real (a 30-frame beat, PERFECT flashes, Royal Bank gold at Union). The coffee timer is unexplained.
- **Off-Leash 6.5:** the 0 card.
- **Tallboy 7:** the Kensington storefront row is the game's best thumbnail. The busted card adds up.
- **Regatta 6:** the coaching is good, but a first-timer gets 0.
- **Parking 7:** fixed, honest and learnable.
- **TTC 7:** the funniest event, and the curve is now fair.
- **Audio:** every event's music is at rms 3500–4700, with no clipping. Stereo side is −13 to −18 dB, up from −22 in R2, so it now sounds stereo. The podium (rms 4349) is no louder than the events: still no swell.

**Loved:** Parking's coaching and itemised box; the TTC demo and its jokes; the podium you now actually sit through.
**Top problems:** the two 0-clamp cards (major); forfeited lines on the Bike card (minor); the frozen Parking demo (minor); Bay coffee (minor); the ~1 s P2 card lockout (note).
**What California Games did that this doesn't:** a first run always ended on something worth laughing at, never a fake zero. The podium had a musical lift.
**More Toronto:** a Leafs groan on a 0 card; a ferry horn on Regatta's last mark; a raccoon in Parking spot 3.
**Quote:** "Every card tells a joke now. Make sure none of them tells a lie."

## 6. Is it as good as California Games yet?
Not yet. The single biggest thing in the way is the first-timer's first minute. Off-Leash, Regatta, TTC and (nearly) Bike end in 0 or close to it, on result cards whose arithmetic looks fudged. California Games never sent you away with nothing.
