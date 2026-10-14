# pt5 Lena (16-bit sports designer) — Round 6

**Round 1 → 2 → 3 → 4 → 5 → 6:**
- overall 5 → 6 → 7 → 8 → 8 → 8
- vs California Games 4 → 5 → 6 → 7 → 7 → 7
- Bike 6 → 6 → 7 → 8 → 8 → 8 · Bay 6 → 7 → 8 → 8 → 7 → 8 · Off-Leash 5 → 6 → 7 → 8 → 8 → 8 · Tallboy 4 → 5 → 6 → 7 → 7 → 7 · Regatta 3 → 4 → 5 → 5 → 5 → 5
- Parking 4 → 7 → 8 → 8 · Subway 5 → 6 → 7 → 7

## 1. Round-5 complaints
- **Fixed:** Bay card (bay-957401403, verify GONE). The card now says "ALTERNATE ◀ ▶ ON BIG DOTS / SMALL DOTS = DOUBLE TIME". Big dots only, ±3f jitter, no dodging at all: MADE THE 5:42!, 9 s left, 1150. Off-Leash coach after an early B now reads "SET! YOU STEP AS HE LUNGES". Regatta yellow arrow: it now sits over the mark or at the screen edge, never at the bow. Bike forfeit line: "FORFEIT TIPS, STYLE 100" in grey.
- **Better:** Tallboy SIP 'N' HOP callout shows its maths ("+24 / 8 X1 CHAIN X3 DEAD ON").
- **Unchanged:** Regatta ADRIFT (sail-957327564 verify PRESENT), now in a worse form (see below). Tallboy idle card: RUN 0 with the bar ~40% full, "FINED 1/4" on 0 (filed this time).
- **Not re-tested:** TTC "GOLD DOT SURF X1" (I couldn't keep a full gold leg in budget; I got STANDING SURF CHAIN 1 +75).

## 2. Regressions / new
- [major] **pt5r6-adrift-990059561**: I obeyed every coach line. After the 5-tap tack I'm sailing into mark 2's ring. "ADRIFT SOON! TAP ▶ 3 TIMES" bears me off along the ring's edge without counting the mark. "TO MARK 2: TAP ▶ ONCE" then turns me away. About 4 s after my closest approach I get ADRIFT, and the card's reason reads "10 S GETTING NO CLOSER". Branching left from the same frame rounds the mark fine.
- [major] **pt5r6-sail-990007861**: the docked Ward's ferry sits under mark 3's approach. Once I touched it I stayed pinned: "WATCH THE FERRY! -2 S" again and again, TIME 27→16 in about 4 real seconds, with the coach cycling IN IRONS / NO HEADWAY.
- [minor] **pt5r6-cops-990734852**: the Tallboy idle card (above).
- Unfiled: goose sitting on the exit line of mark 1, "HONK! HONK! GOOSED! -2 S", unavoidable for a first-timer. One empty callout panel flashed after MARK 1.

## 3. Copy: 8/10
- **Clear, first read:** "BOLD: B AS HE LUNGES: 150+", "SET! YOU STEP AS HE LUNGES", "NEXT BUMP SPILLS COFFEE: -40", "TO MARK 1: TAP ▶ ONCE", Parking's full chain ("LET GO! STOP ON THE LINE" → "KEEP DOWN+RIGHT: GET READY" → "NOW! ROLL TO DOWN+LEFT" → "STRAIGHT! LET GO TO STOP"), "NO LEANING, NO POINTS", "MADE THE 5:42!"
- **Jokes that land:** "PHOTOBOMBED A TOURIST! SORRY!", "TACKLED -150 (HE'S FRIENDLY)", "FACE-FIRST IN A BACKPACK!", "GRABBED THE STICKY POLE!", "EASY! IT'S A RENTAL!"
- **Doesn't match the game:** "ADRIFT SOON! TAP ▶ 3 TIMES" (wrong near the mark). "10 S GETTING NO CLOSER" (it was ~4 s). "MARK 2 IS UPWIND: ZIG-ZAG!" (which way?). "COP CAUGHT YOU: FINED 1/4" on a 0.
- **Rewrite:** within two boat-lengths of the ring, drop tap counts and say **"RING AHEAD! HOLD YOUR COURSE"**.

## 4. Mastery
- **Bay:** big dots 1150 → double time 1784 (no dodging either way). The skill is now honest, and dodging is a second layer.
- **Off-Leash, the real CG trick.** Dog 1 from the "!": B ≤49f DODGE +50, 52–58f NICE +150, 61–67f CLOSE SHAVE +250, 70f tackled. You judge the dog's closing distance, with no wind-up frame. The safe first-timer (B ~15f after the "!") went 9/9, 1890. A fixed bold rhythm (+62f) went 6 dodges, 2 tackles, 1875: windows vary by dog, so you can't metronome it. That's good. Practised per-dog timing got 2160. The gap is small at my level because CROSSING (~1400) dominates. The 6000 record is reachable only with CLOSE SHAVE chains (+550). So the top end exists, but it's one verb.
- **Tallboy:** the clear window is ~20f (947–966), ON THE CHALK 954–962, DEAD ON ±2f. That's a fair ramp of precision. SIP 'N' HOP +24 is still small next to a 50 hop.
- **Parking:** following the coach with 12f reactions on spot 1 gave NICELY DONE +700 incl. ONE-MOVE.
- More than one thing to master? Bay (rhythm + lanes) and Bike yes. Off-Leash and Tallboy are one verb each.

## 5. PLAYTEST.md report
1. Lena, shipped two SNES sports games.
2. **8/10.** Every card now tells the truth except Regatta's coach. vs CG: 7/10.
3. Bike 8 (BMX: the card is honest now). Bay 8 (Summer Games sprint: card fixed, rhythm is the core). Off-Leash 8 (footbag-style nerve trick, ladder doubled in value). Tallboy 7 (roller skating: chalk precision fair, sip still garnish). Regatta 5 (surfing: arrow fixed, coach and ferry now kill runs: 2 marks, 11 bumps, ADRIFT, 678). Parking 8 (best tutorial). TTC 7 (half-pipe balance: 36–40f hollow→solid lead, very fair).
4. Loved: Parking coach chain. The Off-Leash DODGE/NICE/CLOSE ladder. TTC's STAND CLEAR → GO! D-PAD ▶ telegraph.
5. Top problems: adrift-990059561 [major], sail-990007861 [major], sail-957327564 [major, still present], cops-990734852 [minor], unavoidable goose at mark 1 [minor].
6. CG never let its own hint kill you. Regatta's coach does.
7. Toronto: the CN Tower/Dome skyline at mark 2 is lovely. Give the ferry a horn two seconds before it moves, and give pinned boats a "PUSHED OFF THE FERRY! SAIL ON!"
8. "The cards finally tell the truth. Now make the coach tell it too."

## 6. As good as CG?
Not yet: 7/10. The single biggest thing in the way is still **Regatta**: a first-timer who obeys every line still can't medal. Make the coach aim for the ring, and make ADRIFT need SPD ≈ 0.
