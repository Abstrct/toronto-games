# pt5 Lena (16-bit sports designer): Round 7

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7:**
- overall 5 → 6 → 7 → 8 → 8 → 8 → 8
- vs California Games 4 → 5 → 6 → 7 → 7 → 7 → 8
- Bike 6 → 6 → 7 → 8 → 8 → 8 → 8* · Bay 6 → 7 → 8 → 8 → 7 → 8 → 7 · Off-Leash 5 → 6 → 7 → 8 → 8 → 8 → 8 · Tallboy 4 → 5 → 6 → 7 → 7 → 7 → 8 · Regatta 3 → 4 → 5 → 5 → 5 → 5 → 7
- Parking 4 → 7 → 8 → 8 → 8 · Subway 5 → 6 → 7 → 7 → 7*

(*card and coach read only; numbers from the 15f curve bots: Bike 3252, Subway 3770.)

I played every event through on-screen perception: the "!" sprites, the beat box, the chalk chevrons and the coach text, with 15f reactions and timing jitter.

## 1. Round-6 complaints
- **Fixed: Regatta ADRIFT beside the mark** (adrift-990059561, verify GONE). Eight coach-obeying runs at 15–18f, five of them miscounting 35% of tap orders, all finished: 2040–2635, 55–64 s left, never ADRIFT. "RING AHEAD! HOLD YOUR COURSE" is my rewrite from last round, word for word. Thank you.
- **Fixed (not seen): ferry pin** (sail-990007861). No ferry contact in eight runs. "FERRY'S OFF! SURF HER WAKE!" fires after mark 3.
- **Fixed: Tallboy idle card** (cops-990734852). Verify says PRESENT only because the condition is the scene. The card now reads "RUN HURDLES+ROAD 0 / NOT ONE HURDLE, NO POINTS", with no FINED line.
- **Not seen:** the goose on mark 1 and the empty callout panel.

## 2. Regressions / new
- [minor] **pt5r7-park-999876280**: Off-Leash dog 1, B timed from the white "!" (@803). 15–68f gives DODGE +100. 70–91f gives NICE +200. **92–93f gives DODGE +100**: that's the frame the red "!" goes out and the lunge starts. 94–104f is NICE again, 108–112f CLOSE SHAVE +300, and 116f gets you tackled. The most natural "B as he lunges" press lands in the hole.
- [minor] **pt5r7-bayb-744900**: Bay with big dots only, ±3f timing and no dodging: MADE THE 5:42! with **0 s left**, 793. In R6 the same play had 9 s to spare. The double-time version misses the train (255). Dodging is now mandatory. That's fine, but the first-timer margin has gone.
- [minor] **pt5r7-sail-748755**: CLEAN TACK needs about 10 taps a second (6f per tap got +100 ×2; 10f per tap got none). Neither the card nor the coach says so.
- Two dogs' "!" can overlap ("SORRY, HE'S A RESCUE!" then "SHE JUST WANTS TO PLAY!" 150f apart). My shave runs lost track there.

## 3. Copy: 8/10
- **Clear:** "SAFE: B ON ! = 100 A DOG / BOLD: B ON RED ! = 200-450", "RED ! = B NOW FOR +200", "OOPS! NO DOG THERE" → "WOBBLY! ONE MORE AND YOU FALL" (a fair two-step warning), "DEAD ON! B MID-AIR PAYS X3", "RING AHEAD! HOLD YOUR COURSE", "LINE AHEAD! HOLD YOUR COURSE", and Parking's whole chain.
- **Jokes that land:** "IT'S DUNDAS, BUD", "JOGGER! ON YOUR LEFT! SPLASH", "THE RCYC BAR IS OPEN!", "HE'S NEVER DONE THIS!", "SORRY, HE'S A RESCUE!", "*CRACK* FRESH TALLBOY".
- **Unclear:** "DOWN+LEFT ON NOW! A: PARK" (Parking card) reads as a typo until the coach says NOW!. "PARKED. IT'LL DO" heads a 936-point spot with ANGLE GREAT and ONE-MOVE, which undersells it. "LIQUID COURAGE!" and "RACCOON RUN!" pay big, but nothing tells me what earned the name. Tallboy's "X5 CHAIN" banner lingers between callouts.
- **Rewrite:** Parking card: "BACK IN: HOLD DOWN+RIGHT, / ROLL TO DOWN+LEFT AT NOW!"

## 4. Mastery
- **Off-Leash, played four ways:**

  | Approach | Result | Score |
  |---|---|---|
  | First-timer (B 15f after the white "!") | 15 dodged, 0 tackles | **3630** (bronze, #5) |
  | Red "!" + 15f | 15 NICE | **5285** (50 short of silver) |
  | Going for CLOSE SHAVE | anywhere from 3 hearts gone to 5 shaves | **0 to 4675** |

  That's a real CG footbag ladder, and the top end is nerve. The catch: a shave pays +100 over NICE, and a tackle costs 150, a heart and the chain. My best shave run scored *less* than playing NICE. The 8000 record needs near-perfect shave chains. That's honest, but the middle rung is the smart play.
- **Tallboy:** the chalk window is 209–221 (DEAD ON at 212, ±1f), with BIT LATE out to 233. No sips: 1776. Sipping every hop: 2845, even with 16 SLOSHED. SIP 'N' HOP now pays +75, +176 and RACCOON RUN +280, so it's a real second verb with a BUZZ-management layer on top. Big improvement.
- **Regatta:** obeyers sit in a tight band (2040–2635). The headroom is in TIGHT ROUNDING chains, fast tacks and the ferry surf. I couldn't push past 2635, so I can't yet say an expert pulls away.
- More than one thing to master: Off-Leash (timing ladder + pats + ball), Tallboy (chalk + sip/buzz), Bay (beat + lanes). Regatta is still mostly "count the taps."

## 5. Hidden tricks
None confirmed. "ROLL TACK" was visible to me in a git commit title before I started, so I tried hiking with A around three tacks (A held, A mid-tack, A after). Nothing fired, and holding A lost style (420 vs 600). Fast tapping gives CLEAN TACK, but the README documents that.

## 6. PLAYTEST.md report
1. Lena, shipped two SNES sports games.
2. **8/10.** The coach no longer loses you the regatta. vs CG: 8/10.
3. Bike 8 (BMX, not replayed). Bay 7 (Summer Games sprint: honest beat, but the margin has gone). Off-Leash 8 (footbag-style nerve ladder; hole bug). Tallboy 8 (roller skating: sip is finally a trick). Regatta 7 (surfing: finishable; the verb is obedience). Parking 8 (the coach follower parks all three, 2476). TTC 7 (half-pipe balance: 40f AHEAD→D-PAD lead).
4. Loved: the Regatta fix, Tallboy's SIP 'N' HOP maths, Off-Leash's dog-owner lines.
5. Problems: park-999876280 [minor], bayb-744900 [minor], sail-748755 [minor], shave risk/reward [design note], Parking card line [ux].
6. In CG the risky trick always paid more than the safe one. Off-Leash's CLOSE SHAVE doesn't, yet.
7. Toronto: the RCYC bar, "IT'S DUNDAS, BUD" and the white squirrel are perfect. Next: a Leslieville dog with a bandana and a raccoon cameo in Off-Leash.
8. "The coach finally sails with you, not against you."

## 7. Is it as good as California Games yet?
Close: 8/10. The biggest thing in the way now is **risk/reward at the top end**. CLOSE SHAVE (+300 vs NICE +200) and the regatta's style don't pay enough over the safe line to tempt a good player. Make the bold verb worth the tackle.
