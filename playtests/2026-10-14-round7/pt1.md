# pt1 Dana (noob) R7

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7:**
- overall 6 → 7 → 7 → – → 7 → 8 → 7
- vs California Games 6 → 7 → 6 → – → 6 → 7 → 7
- Bike 7 → 6 → 4 → – → 4 → 6 → 4 · Bay 3 → 6 → 6 → – → 6 → 7 → 6 · Off-Leash 6 → 6 → 7 → – → 8 → 7 → 8 · Tallboy 6 → 4 → 5 → – → 5 → 8 → 8 · Regatta 1 → 4 → 5 → – → 6 → 6 → 8
- Parking 8 → – → 5 → 4 → 5 · Subway 4 → – → 4 → – → 4

I'm Dana. I react in 20–25 frames, I do what the box tells me, and I quit when I don't know why I lost. This round I medalled in Off-Leash, Tallboy and Regatta. I lost Bike, Parking and TTC by doing exactly what the box said.

## 1. My round-6 complaints
- **Regatta early ADRIFT (sail): fixed.** I obeyed every coach line, finished on my first try and got "THE RCYC BAR IS OPEN!": 2015, bronze, #5, 1 bump. "RING AHEAD! HOLD YOUR COURSE" and "MARK 2! NOW TAP ◀ 7 TIMES" are perfect.
- **A safe Off-Leash run doesn't medal (park2): fixed.** Pressing B 22 f after the "!" scored 3630, bronze, #5, "SO LONG, SQUIRREL!"
- **No let-go cue in Parking (pk): better, but still not usable.** "STRAIGHT! LET GO OF THE PAD" exists now, but it comes 5 f before "CURB CHECK! SCRAAAPE −50", or after it (pt1r7-pk-1068139).
- **Bump popups hide the coach (sail2): not re-checked.** My only bump was at the line.
- **Bike wipeout tax (bike4): not re-checked.** I never delivered. The card now says "TOKENS 50, WIPEOUT DROPS 2", which fixes the "counted twice" copy.
- **Copy:** "SPLAT! CAR IN BIKE LANE / DROPPED 2 TOKENS" fixed. "(SO FRIENDLY)" fixed. GERMS now stops at 20, fixed. The PRESTO line is gone from the Bay card.

## 2. Regressions and new issues
- [major] **pt1r7-bike-999836828**: "HOP THE RAILS: B!" pops up ~100 f before the rails reach me, before they're even on screen. B 25 f after the prompt gave RAIL WOBBLE. B as the rails arrived gave TRACK HOP +60. It punished me twice before I worked it out.
- [major] **pt1r7-bay-90675**: The red "!" and the RED ! AHEAD? box come ~20 f before the bump. Changing lane a beat after seeing it: 17 spills, MISSED THE TRAIN, 229. Ignoring it: 8 spills, MADE THE 5:42, 865. Caveat: my script picked up or down blindly. Also new: spills keep costing past DECAF.
- [major] **pt1r7-pk-1068139**: Parking, every cue obeyed 22 f late. Spot 1 went to the curb, then the sidewalk, half in with a ticket, −175. Spot 2 was +613 with CURB HIT. The HUD showed SCORE 0 after the −175, then rose 438 for a +613 spot.
- [major] **pt1r7-ttc4-1735525**: TTC. "SOLID: D-PAD THAT WAY NOW" made me hold the button. Holding pushes the dot out the far side in ~45 f. Tapping keeps it gold. Leaning while the arrow showed ended PATIENT ZERO at 22 f (160) and at 10 f (200), so it's the verb, not my reflexes.
- [minor] **pt1r7-sail-963410**: After rounding mark 1, "TO MARK 1: TAP ▶ ONCE" stays up ~85 f under "TO MARK 2". "MARK 1 ROUNDED!" shows ~250 f late.
- Bike: the 501 came from behind and hit me while "HOP THE RAILS" was up. The only warning was a tiny ⚠ at the bottom edge.

## 3. Copy: 7/10
**Clear:** "RED ! AHEAD? ↑/↓ CHANGE LANE" · "RED ! = B NOW FOR +200" · "RING AHEAD! HOLD YOUR COURSE" · "WAIT! LET THE BIKE GO BY" · "THIRD WIPEOUT. NOT PAID!" · "20 GERMS: STYLE IS VOID / ONLY LEGS YOU LEANED PAY" · "FERRY SURF! +200 / LONG SURF! +200 MORE" (that one made me grin).
**Unclear:**
- "HOP THE RAILS: B!": it's timed wrong (above).
- "SOLID: D-PAD THAT WAY NOW": I read it as hold.
- "SAFE: B ON ! = 100 A DOG": the "A" reads like the A button.
- "MIND THE BMW: HOLD DOWN ONLY", flashed between "KEEP DOWN+RIGHT" and "NOW! ROLL".
- "RUN HURDLES+ROAD": what's ROAD?
- "PARKED ON BRUNSWICK!" when I parked 1 spot of 3 and got 2 tickets.

**Rewrite:** TTC card line 5: "SOLID: TAP THAT WAY, DON'T HOLD".

## 4. Mastery
- **Tallboy, first-timer vs style, with the same chalk timing.** Dry: 2100, bronze, #5. Sipping on every hop: 4924, silver, #2, 17 SIP 'N' HOPs, style 830 → 3654. Skill shows. But BUZZ never reached the red, so "always sip" is a toll, not a choice.
- **Off-Leash, by B delay after the white "!".** 22 f and 46 f: 3630. 60 f: 3760. 72 f: 4410 (#4, 1 tackle). 84 f: 4110. Bold is worth ~+20%. The record is 8000, so the top end is pats, balls and chains I can't reach.
- **Bike, Parking, TTC:** I never got past "survive", so I can't judge.
- **Hidden tricks:** none found by playing. Honest note: a commit title in the repo mentions an undocumented Regatta "ROLL TACK". I saw it there, not in the game, and didn't try it.

## 5. PLAYTEST.md sections
- **Verdict:** I can now medal in half the events by following the coach. The other half still punish me for following it.
- **Per event:**
  - Regatta 8: the coach is now a real coach
  - Off-Leash 8
  - Tallboy 8
  - Bay 6
  - Parking 5: there's a ticket lady! But the curb comes before the cue.
  - Bike 4
  - TTC 4
- **Honesty note:** Bay, Off-Leash, Tallboy and TTC were played with reflex scripts in `build/pt/scratch/pt1/` (beat with −4..+8 f jitter, B a fixed delay after the "!", chalk ±7 f, lean on the arrow). Bike, Regatta and Parking were hand-played in 1–4 s chunks with films. Bike run 1 had a 5 s stretch where I didn't steer.
- **Loved:** FERRY SURF / LONG SURF · finishing the regatta first time · SPADINA! YOU LOST HIM! at #2.
- **Top problems:** ttc4, pk, bay, bike (all major), sail (minor).
- **CG had:** prompts that matched the moment you act.
- **More Toronto:** the parking officer is great; give her a line ("$75. HAVE A NICE DAY.").
- **Quote:** "The coach finally sailed me round the harbour, then the rail prompt, the red ! and the TTC arrow all told me the right thing at the wrong time."

## 6. Is it as good as California Games yet?
Not quite. The single biggest thing in the way is cue timing and wording. Four events now tell a beginner what to do, but at a moment, or with a verb, that makes doing it fail: rails, red !, straighten, TTC hold. Regatta proved this round that a coach timed to a human makes the event a joy.
