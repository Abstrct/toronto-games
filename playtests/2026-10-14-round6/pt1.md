# pt1 Dana (noob) R6

**Round 1 → 2 → 3 → 4 → 5 → 6:**
- overall 6 → 7 → 7 → – → 7 → 8
- vs California Games 6 → 7 → 6 → – → 6 → 7
- Bike 7 → 6 → 4 → – → 4 → 6 · Bay 3 → 6 → 6 → – → 6 → 7 · Off-Leash 6 → 6 → 7 → – → 8 → 7 · Tallboy 6 → 4 → 5 → – → 5 → 8 · Regatta 1 → 4 → 5 → – → 6 → 6
- Parking 8 → – → 5 → 4 · Subway 4 → – → 4 → – (not played properly, see honesty note)

I'm Dana. I played California Games once in 1989, I react in 20–25 frames, and I hate feeling stupid. This round I medalled three times. I've never done that before.

## 1. My round-5 complaints
- **Bike potholes / early wipeouts: better.** If I ride one line I'm untouched for about 27 s. "CAR IN BIKE LANE. AGAIN." comes up roughly 100 f before the car. I dodged both and **delivered for the first time in six rounds**: 2069 ride, then −WIPEOUT X200 = 1869. Bronze is 2000.
- **Bay train / bump tax: fixed.** "MADE THE 5:42!" with 9 s to spare. I scored 1150, which is bronze, even with 8 spills (−320). Lane depth is **unchanged**: a hot dog cart bumped me from the next lane.
- **Regatta ADRIFT / bumps: better, but there's a new cliff.** On my second try I rounded all 3 marks and finished: "THE RCYC BAR IS OPEN!", 1765, bronze, 11 bumps paid in seconds. My first try ended at TIME 75 with 0 marks (below).
- **Parking wedge: unchanged in spirit.** Rolling 20 f late now puts me on the sidewalk instead of into the BMW.
- **Penalty clamp: fixed.** Cards now show "DINGS+FINES 225 … SCORES NEVER GO BELOW 0" and "− TACKLES X150 450".
- **Tallboy card: fixed.** It now uses my exact rewrite: "YELLOW CHALK: TAP A / RED CHALK: HOLD A". Every card says "A READY".
- **Bike card "X8 of what?": fixed.** "B HOP RAILS AND POTHOLES / TOKENS PAY 50 ON DELIVERY".
- **"NOBODY STEERED FOR 10 S": better.** It's now "10 S GETTING NO CLOSER".
- **TTC results copy:** not re-checked. I never got a fair ride.
- **Tallboy warm-up B popup:** not re-checked.

## 2. Regressions and new issues
- [major] **pt1r6-sail-991903771**: Regatta. I drifted past mark 1, then followed "TAP ▶ 7 TIMES" and then "TAP ▶ ONCE". That left me head-to-wind on the white pin float. ADRIFT ended the race at TIME 75 with 0 marks, for 192. One slip in the first 15 s kills the event.
- [major] **pt1r6-park2-990292909**: Off-Leash. A flawless safe run (9 dodged, 0 tackles, 68 s left) scored 1890. That's "110 MORE FOR BRONZE" and "THE BOARD STARTS AT 1900". In R5 the same play got bronze and #5. The SAFE line on the card now feels like a trap.
- [major] **pt1r6-pk-992068943**: Parking. "HOLD DOWN+LEFT: SWING IN" stays on screen until "CURB CHECK! SCRAAAPE −50" and "UP ON THE SIDEWALK! −100". Nothing ever tells me to let go.
- [minor] **pt1r6-bike4-989920608**: Bike. The new −200 per wipeout is the whole gap to bronze on a delivered run.
- [minor] **pt1r6-sail2-992292532**: Regatta. Bump popups (GOOSED, AGROUND, TOUCHED THE MARK) replace the tap-count coach exactly when I need it.

## 3. Copy: 8/10
**Clear:** "CAR IN BIKE LANE. AGAIN." (warning and joke in one). "DOG! PRESS B TO GET SET!" "DEAD ON! B MID-AIR PAYS X3" "TIP: STEP AS BIG DOTS LAND" "TACK NOW! TAP ◀ 4 TIMES" "MARK 2 IS UPWIND: ZIG-ZAG!" Parking's itemised spot box (HALF IN +150, CURB HIT −50, $75 TICKET −75). "110 MORE FOR BRONZE". "TACKLED −150 (HE'S FRIENDLY)" and "SORRY, HE'S A RESCUE!" landed.
**Unclear:**
- "SPLAT!" doesn't say what I hit.
- "SHE JUST WANTS TO PLAY!" is followed by "(HE'S FRIENDLY)".
- "SAFE: B WHEN ! SHOWS: 50": 50 what?
- "Y ON A GOLD DOT: PRESTO!": I never worked out what PRESTO does.
- The Bike card lists "TTC TOKENS X50 2 / STYLE 100" and then "+ TIPS, STYLE 200", which reads like it's counted twice.
- "TO MARK 1: TAP ▶ ONCE" pointed me into the wind.

**Rewrite:** Parking, when the angle lamp goes green: "LET GO! STRAIGHT BACK ▼".

## 4. Mastery
- **Off-Leash, played six times.** Pressing B 22 f after the "!" scored 1890. Waiting 46 f gave 2055, 58 f gave 2625 with 0 tackles, and 66 f gave 2520 with 1 tackle. So the bold play is worth about +40%. Late presses that land are paid, late presses that miss get tackled, and pats and balls sit on top of that.
- **Tallboy.** Clean chalk hops alone scored 1470 (bronze, #5). Adding a sip on every hop scored 2518 (silver, #3, 17 SIP 'N' HOPs), and the BUZZ/cop meter is the risk. That's two separate skills: chalk accuracy and sip timing.

So yes, skill now pulls away, and there's more than one thing to master. My best runs are still ~45% of the records, though, so I can't tell whether the top end opens up further.

## 5. PLAYTEST.md sections
- **Verdict:** for the first time, a noob finishes most events and medals in some of them.
- **Per event:**
  - Tallboy 8: SPADINA! YOU LOST HIM!, SO LONG, NANA!
  - Bay 7
  - Off-Leash 7: white squirrel, still lovely
  - Bike 6
  - Regatta 6: the Rogers Centre dome and Billy Bishop runway in view
  - Parking 4
- **Honesty note:** Off-Leash and Tallboy were finished with small reflex scripts in my scratch folder: B a fixed 22–66 f after the "!", and A at the chalk with ±5–8 f jitter. Bike, Bay, Regatta and Parking were hand-played in 1–3 s chunks with films. I idled out Parking after spot 1. My TTC script never saw the arrows (PATIENT ZERO, 120), so I'm not scoring TTC.
- **Loved:** "CAR IN BIKE LANE. AGAIN.", making the 5:42, THE RCYC BAR IS OPEN!
- **Top problems:** Regatta early ADRIFT (sail), safe Off-Leash missing bronze (park2), the Parking swing cue (pk), the bump popups hiding the coach (sail2), the Bike wipeout tax (bike4).
- **CG had:** a fail state that cost you points, not the run. Regatta's ADRIFT still ends the event.
- **More Toronto:** a raccoon in the Bike lane; geese with "HONK" bubbles on the Regatta results card.
- **Quote:** "I made the 5:42, lost the cop and found the RCYC bar, then the dogs I never let touch me wouldn't give me a medal."

## 6. As good as California Games yet?
Nearly. The single biggest thing in the way is the run-enders that a beginner can't recover from: Regatta's ADRIFT in the first 15 s, and Parking's swing with no "let go" cue. Off-Leash proved last round that a forgiving fail state works, and this round it scores a perfect safe run below a medal.
