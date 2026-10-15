# pt1 Dana (noob) R10

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10:**
- overall 6 → 7 → 7 → – → 7 → 8 → 7 → 8 → 8 → 8
- vs California Games 6 → 7 → 6 → – → 6 → 7 → 7 → 8 → 8 → 8
- Bike 7 → 6 → 4 → – → 4 → 6 → 4 → 7 → 8 → 8 · Bay 3 → 6 → 6 → – → 6 → 7 → 6 → 6 → 7 → 6 · Off-Leash 6 → 6 → 7 → – → 8 → 7 → 8 → 8 → 7 → 9 · Tallboy 6 → 4 → 5 → – → 5 → 8 → 8 → 8 → 8 → 7 · Regatta 1 → 4 → 5 → – → 6 → 6 → 8 → 8 → 8 → 8
- Parking (R3 → R10) 8 → – → 5 → 4 → 5 → 8 → 8 → 7 · Subway 4 → – → 4 → – → 4 → 8 → 8 → 8

I'm Dana: I react in 20–25 frames, I read the box once, and I quit when I don't know why I lost. I medalled in all seven again, but this time the "go for it" runs paid off too.

## 1. My round-9 complaints
- **Bike rear-ends a car in the warm-up (bike0): fixed.** I held A for 15 s and nothing hit me. I made two deliveries with 0 wipeouts once I steered on "STEER ◀ ROUND IT".
- **Off-Leash 10000 record vs my 3855 (dog): fixed.** The card now says "B ON ANY ! = SAFE DODGE / LATER B = MORE PTS: RISKY!". B at 22 f on every ! scored **7525, silver**.
- **Squeezed grey style rows (sail card): fixed** on the Regatta, Bay, Bike and Off-Leash cards.
- **Formulas:** Bay and Regatta are **fixed**, in my words: "ON THE 5:42 1000 / 0 SEC AT 40 0" and "65 SEC AT 15 975". Bike and Off-Leash are **unchanged**: "RIDE 1500 + TIME 2080" (pt1r10-bike2-71836713).
- **Regatta HOLD vs TAP: fixed.** It now says "MARK 1 ROUNDED! WAIT..." and then "MARK 1! NOW TAP ◀ 3 TIMES".
- **Parking card NOW! (iparking): better.** The card reads "NOW! IN THE PANEL: ▼+◀", but in play the NOW! is now the problem (see below).
- **Bay red ! arrow: unchanged.** Following the arrow got me MADE THE 5:42 at 1068 (bronze by 1 point, 3 spills). Ignoring it missed the train (397–505).
- "PASS CLOSER = TIGHT ROUNDING" after the mark: **unchanged**.

## 2. Regressions and new issues
- [major ux] **pt1r10-park2-72273650**: Parking. "NOW! ROLL TO ▼+◀" shows for about 8 frames, then flips back to "KEEP HOLDING ▼+▶" with no input from me. When I obey the NOW! at 22 f I get "TOO SOON! BACK TO ▼+▶". This happens on all three spots, and on spot 3 the coach ping-pongs a dozen times. I still parked all 3 (2562), but I felt stupid the whole time.
- [minor ux] **pt1r10-bike2-71836713**: "RIDE 1500 + TIME 2080" and "WALK 1000 + TIME 2925". TIME is the subtotal, so the sum never matches.
- [minor ux] **pt1r10-dog-72325479**: I got ten "NICE TIMING! +400" popups, but the card says "NICE TIMING 1000".
- [minor ux] **pt1r10-cops-72338192**: Tallboy. Hop early and you land on the crates with "OOF! SPILLED!", but nothing says TOO EARLY, while a late hop gets "BIT LATE, BUD!". A dry first-timer run made Spadina with 1959, no medal (R9 was 2294, bronze).
- No crashes or soft-locks.

## 3. Copy: 8/10
**Clear:** "STEER ◀ ROUND IT" · "DING DING! BIKE COMING UP!" / "WAIT! LET THE BIKE GO BY" · "BIT LATE, BUD!" · "CHALK! B MID-AIR PAYS X2" · "MARK 1 ROUNDED! WAIT..." · "TAP ON THE FLASH: GOLD X3" · "TTC TOKENS 200". These jokes land: "SO LONG, SALMON!", "SORRY! SPILLED THEIR LATTE", "SORRY, HE'S A RESCUE!", "THE RCYC BAR IS OPEN!".
**Unclear:** "GAGS RIDDEN 300" (what's a gag?) · "NOW! IN THE PANEL" (which panel?) · NOW! → "TOO SOON!" · "OOF! SPILLED!" with no reason · "PASS CLOSER = TIGHT ROUNDING" after I've already passed.
**Rewrite:** "RIDE 1500 + TIME 2080" → "RIDE 1500 / 29 S LEFT AT 20 580", the same as Regatta now does.

## 4. Mastery
- **Off-Leash** (same 22 f hands): B on the first ! 7525 → B on the red ! 7800 → B 12 f later **9075** (CLOSE SHAVE X3, close to the 10200 gold) → 24 f later 550 (tackled out). That's a proper risk curve, and the best of the seven.
- **Tallboy:** dry 1959 vs a sip every hop **3730** (1.9×, BUSTED and fined, still bronze). The top end has two things to master, chalk timing and chain/BUZZ.
- **TTC:** hold 2943 vs mash on TAP 3763 (1.3×). **Regatta:** hiking 2475 → 2535, both bronze; I couldn't find the skill.
- So yes, the expert pulls away in Off-Leash and Tallboy and barely at all in Regatta and TTC.

**Hidden tricks (I watched the demos, then tried at 22 f): 1 landed.**
- **LIQUID COURAGE:** first try, from a sip on every hop. The tell is that the houses go wavy and BUZZ goes red, then "TIPSY! THE COP'S GAINING". It's readable, but I landed it by accident.
- **ROLL TACK:** 3 tries. The HUD shows GUST/HIKE on the same frame as "TACK NOW!", and the demo rolls 4–8 frames later. A tack with A held inside HIKE was still a CLEAN TACK. That's out of reach at my speed.
- **OLE! MATADOR:** 5 tries (late B, a sidestep before or after). I got CLOSE SHAVE X3 every time, never OLE.
- **BIKE SHAVE:** 1 try (I ignored WAIT), nothing.
- I didn't try TTC TRANSFER, SLALOM or LOOK MA.
- I can't judge sound tells: I played headless and didn't listen.

## 5. PLAYTEST.md sections
- **Verdict:** this is the first round where trying harder clearly paid me more.
- **Per event:**
  - Bike 8: 3080, DELIVERED, bronze, 0 wipeouts.
  - Bay 6: you only make the train by following the arrow, and then by a whisker.
  - Off-Leash 9: silver as a noob, 9075 going for it.
  - Tallboy 7: the dry run doesn't medal.
  - Regatta 8: 2475–2535, clean cards.
  - Parking 7: the NOW! flicker.
  - TTC 8: 2943/3763.
- **Honesty note:** my reflex scripts in `build/pt/scratch/pt1/` played these. They read the on-screen text and pixels (the ! box, the Bay arrow, the chalk) and acted 20–25 f later. Bay's beat had −3..+7 f jitter, and Tallboy's chalk anticipation had −4..+8.
- **Loved:** LATER B = MORE PTS: RISKY! · the itemised Bay and Regatta cards · TTC TOKENS.
- **Top problems:** park2 (major), bike2, dog, cops (minor).
- **CG had:** a trick you could find by wiggling the stick.
- **More Toronto:** call Bike tokens "PRESTO TAPS"? Have the Off-Leash dog owner yell "HE'S NEVER DONE THIS!" (it already does: keep it).
- **Quote:** "I took the risk and the game paid me. Do that everywhere."

## 6. Is it as good as California Games yet?
For a first-timer, nearly: 8 vs 8. The biggest thing in the way is still that the coach sometimes outpaces a slow human: Parking's 8-frame NOW!, ROLL TACK's 4-frame window, and Bay's arrow that only scrapes you onto the train. When the game waits for me, as Off-Leash and Bike now do, it's as good as CG.
