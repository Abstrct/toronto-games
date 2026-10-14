# pt1 Dana (noob) R8

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8:**
- overall 6 → 7 → 7 → – → 7 → 8 → 7 → 8
- vs California Games 6 → 7 → 6 → – → 6 → 7 → 7 → 8
- Bike 7 → 6 → 4 → – → 4 → 6 → 4 → 7 · Bay 3 → 6 → 6 → – → 6 → 7 → 6 → 6 · Off-Leash 6 → 6 → 7 → – → 8 → 7 → 8 → 8 · Tallboy 6 → 4 → 5 → – → 5 → 8 → 8 → 8 · Regatta 1 → 4 → 5 → – → 6 → 6 → 8 → 8
- Parking (R3 → R8) 8 → – → 5 → 4 → 5 → 8 · Subway 4 → – → 4 → – → 4 → 8

I'm Dana. I react in 20–25 frames, I do what the box says, and I quit when I don't know why I lost. This round, doing what the box said worked in six events out of seven. That's new.

## 1. My round-7 complaints
- **Bike rail prompt (bike-999836828): fixed.** HOP THE RAILS: B! now comes up ~30 f before the rails. B at +22, +25 and +28 f all gave TRACK HOP +60. I delivered: "DELIVERED! SIGN HERE.", 2370, 2 wipeouts. That's 130 short of bronze.
- **Bay red ! (bay-90675): better.** At 22 f, following the arrow now beats ignoring it: 1224 with 8 spills vs 1003 with 10 spills. Both made the 5:42. Both still went DECAF.
- **Parking (pk-1068139): fixed.** A script that reads the coach line and obeys it 22 f late parked all three spots: 0 tickets, 2852, #4, "PARKED ON BRUNSWICK!" (and this time it's true). "GOOD PARK! NEXT: HUG CURB" is great coaching.
- **TTC hold (ttc4-1735525): fixed.** The card now says "SOLID: HOLD D-PAD THAT WAY / TAP TO STAY GOLD: SURF X3", and holding is now safe. Same reflex script as R7: 0 germs, 3217, #4. In R7 it was PATIENT ZERO at 160.
- **Regatta stale coach (sail-963410): fixed.** "MARK 1! NOW TAP ◀ 3 TIMES" appears the frame the mark counts. Same at marks 2 and 3. I finished with 0 bumps: 2520, #4, "THE RCYC BAR IS OPEN!"
- **Copy:** "SAFE: B ON ! = 100 PER DOG" is fixed (no stray "A"). "RUN 50 A HURDLE" replaced "RUN HURDLES+ROAD". "THIRD WIPEOUT. NO DELIVERY" replaced "NOT PAID!". "ANOTHER TRICK IN 2 S = X2" is clear and has proper spacing now.

## 2. Regressions and new issues
- [minor] **pt1r8-bay-14135183**: Bay. The red ! shows ~35 f before contact, so a beat-late lane change still often lands on the bump. Following the arrow still means 8 spills and DECAF.
- [minor] **pt1r8-bike2-14137600**: Bike. "CAR IN BIKE LANE. AGAIN. STEER ◀ ROUND IT" pops up when I'm nowhere near the bike lane. I obeyed it and ended up left of the yellow line, with a streetcar coming at me.
- [minor] **pt1r8-sail-14136192**: Regatta card. "LINE HONOURS 300" sits on its own line, then "+ STYLE 500" already contains it. It looks paid twice.
- No crashes and no new majors.

## 3. Copy: 8/10
**Clear:** "HOP THE RAILS: B!" · "501 BEHIND! STEER ◀" · "POTHOLE! HOP IT: B" · "MARK 2! NOW TAP ▶ 4 TIMES" · "LINE HONOURS! NO BUMPS +300" · "WAIT! LET THE BIKE GO BY" · "DELIVERED! SIGN HERE." · "SO LONG, NANA!" · "LET GO OF THE BUTTONS" on every card. That last one is smart, because I mash.
**Unclear:**
- Bay card: "RED !: ▲/▼ AS ARROW, OR A". What arrow? Or A *what*?
- Parking card: "ROLL TO DOWN+LEFT AT NOW!" reads like a typo until you see NOW! on screen.
- Bike/Bay cards: "RIDE 1500+20/S" and "WALK 1000+40/S" are formulas, not words.
- "PASS CLOSER = TIGHT ROUNDING" appears after I'd already passed the mark.

**Rewrite:** Bay card: "RED ! = SOMEONE IN YOUR WAY / ▲▼ WHERE THE ARROW POINTS".

## 4. Mastery
- **Tallboy, the same chalk timing:** dry 2160 (bronze, #5) vs sipping every hop 5124 (silver, #2, 17 SIP 'N' HOPs). That's 2.4×, and skill clearly shows. But I couldn't reach the second layer (the demo's LIQUID COURAGE). Sipping more just got me BUSTED at 367.
- **Off-Leash by B delay:** 22 f gave 3635. 70 f with a step toward the dog gave 4400. Bold pays about +20%.
- **Regatta:** both tacks I tapped at 10/s gave CLEAN TACK +100. Holding A through a tack didn't give the demo's ROLL TACK.
- So yes, an expert pulls away. Every event shows a second thing to master, but a noob can't find it without the demo.

**Hidden tricks:** I found all seven in the title demos (WATCH THAT MOVE!) and pulled off none myself:
Bike TTC TRANSFER +120 (hop sideways across the tracks) · Bay SLALOM X2 +50 (back-to-back dodges) · Off-Leash OLE! MATADOR! +550 (late red-! dodge) · Tallboy LIQUID COURAGE (SIP 'N' HOP on high BUZZ) · Regatta ROLL TACK +250 (tack while hiking) · Parking CLOSE SHAVE! SHE DIDN'T BLINK +200 (back in as the cyclist passes) · TTC LOOK MA, NO HANDS! +100 (at STAND CLEAR).

## 5. PLAYTEST.md sections
- **Verdict:** The first game where the coach is on my side in almost every event.
- **Per event:**
  - Parking 8: obey the coach and park three spots. Last round I got a ticket.
  - TTC 8: "hold" means hold now
  - Regatta 8
  - Tallboy 8
  - Off-Leash 8
  - Bike 7: fair now, but 80 s is long and I got no medal for delivering
  - Bay 6: still DECAF
- **Honesty note:** Bay, Off-Leash, Tallboy, Parking and TTC were played by reflex scripts in `build/pt/scratch/pt1/` (beat jitter −3..+7; reactions 22 f after the !, arrow, chalk or coach line). Bike and Regatta were hand-played in 3–10 s chunks with films. On Bike I missed some prompts because of the chunking, then redid them at 22 f.
- **Loved:** parking all three spots by doing what I was told · DELIVERED! SIGN HERE. · TTC with zero germs.
- **Top problems:** bay (minor), bike2 (minor), sail (minor). The tricks being findable only by watching demos is a design note.
- **CG had:** a trick you could find by wiggling the stick. Here they're only in the demo.
- **More Toronto:** have the parking officer pass by on a clean park ("NOT TODAY, DANA").
- **Quote:** "I did what the box said, and for the first time the box was right."

## 6. Is it as good as California Games yet?
Yes, for a first-timer: 8 vs 8. I medalled in six of seven (not Bike) and finished all seven. The biggest thing in the way now is Bay. The red ! comes too late for a normal reaction, so a noob still goes DECAF.
