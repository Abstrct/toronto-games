# pt5 Lena (16-bit sports designer): Round 10

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10:**
- overall 5 → 6 → 7 → 8 → 8 → 8 → 8 → 9 → 9 → 9
- vs California Games 4 → 5 → 6 → 7 → 7 → 7 → 8 → 8 → 8 → 8
- Bike 6 → 6 → 7 → 8 → 8 → 8 → 8 → 8 → 8 → 9 · Bay 6 → 7 → 8 → 8 → 7 → 8 → 7 → 7 → 7 → 7 · Off-Leash 5 → 6 → 7 → 8 → 8 → 8 → 8 → 9 → 10 → 10 · Tallboy 4 → 5 → 6 → 7 → 7 → 7 → 8 → 9 → 9 → 9 · Regatta 3 → 4 → 5 → 5 → 5 → 5 → 7 → 8 → 8 → 8
- Parking 4 → 7 → 8 → 8 → 8 → 8 → 8 → 8 (not replayed to the end) · Subway 5 → 6 → 7 → 7 → 7 → 7 → 7 → 7

I played from what's on screen: arrows, "!" boxes, the glow, chalk, the beat box and the coach lines. My scripts read screenshots and act 12±3 f late (15 f on some runs). I can't hear the audio, so the sound half of every tell is unverified.

## 1. My round-9 complaints
- **Better: TTC tap** (subt-22267988, re-filed as **pt5r10-ttctap-72122001**). The card now says "TAP ON THE FLASH: GOLD X3". Tapping each flash 12 f late no longer ends PATIENT ZERO. It still loses, though: 18 germs (−720) for one GOLD SURF (225) scores 1042–1088. Holding scores 984–1124 with 8 germs.
- **Better: Bay margin** (re-filed as **pt5r10-bayL1-72131511**). Following the arrow, I made the 5:42 with 3 s and 5 s to spare (1035, 1408). Ignoring lanes left 2 s (857). All 5 runs still spilled 6–9 coffees and went DECAF. Correction to that filing: in the one case I timed, the arrow showed about 40 f before the bump, not "a few frames".
- **Fixed: Regatta card spacing** (sail-22270428). The grey rows TIGHT ROUNDS 200 and CLEAN TACKS 100 now sit at full spacing.
- **Fixed: the Off-Leash card.** "LATER B = MORE PTS: RISKY!" replaces the wrong "B MID-LEAP".
- **Changed: ROLL TACK has no tell.** Round 9's input (hold A, tap, let go about 18 f in) now gives a plain CLEAN TACK +100. I tried 5 variants. The hidden trick has moved, and I didn't find its new form.
- **Not re-tested: the Parking bell** (park-22271760). I didn't get past spot 1.

## 2. Regressions and new issues
- [minor ux] **pt5r10-bayL2-71999475**: the cards fold named tricks into a grey "OTHER STYLE" row (Bay 113, Off-Leash 1450–1560, Tallboy 224). The Bay card also switches between an itemised WALK and a one-line "WALK 1000 + TIME 1200".
- [unfiled] **TTC holding**: my hold bot scored 984–1124 with exactly 8 germs on all 4 runs. Round 9's hold run scored 3642. My bot ignores the dot (it can't correct the new track-joint jolts), so I can't call this a regression.
- [unfiled] **Regatta**: "TAP ▶ 4 TIMES" turned out to be the first half of an 8-tap gybe. "GOOD! TAP ▶ 4 MORE TIMES" came with my bow already near the beach, and I went AGROUND −2 s.

## 3. Copy: 8/10
- **Clear:** "ZIG-ZAG UP: I'LL CALL TACKS", "MISS THE BUOY! TAP ◀ 2 TIMES", "RED ! = B NOW FOR +400", "CRATES! TAP A AT THE CHALK", "THIRD WIPEOUT. NO DELIVERY / PAID FOR THE RIDE ONLY", "LET GO OF THE BUTTONS".
- **Jokes that land:** "TACKLED! −1 ♥. SO FRIENDLY", "SPADINA! YOU LOST HIM!", "CAR IN BIKE LANE. AGAIN.", "BRUSHED PAST! SORRY!".
- **Unclear:**
  - "TAP ON THE FLASH: GOLD X3" promises a payoff it doesn't deliver.
  - "OTHER STYLE" hides the trick you practised.
  - Parking's "NOW! IN THE PANEL: ▼+◀" is cryptic on a first read.
  - The Regatta half-turn order doesn't say it's a half.
- **Rewrite:** "GYBE! TAP ▶ 8: 4 NOW, 4 MORE".

## 4. Mastery
| Event | First-timer | Smart | Expert |
|---|---|---|---|
| Off-Leash (10200) | B on the white "!": 5675, 4 tackles | NICE on red: 7825 | shave at glow +18: 8875; + MATADOR: **10575** (beats DOODLE) |
| Tallboy (6600) | dry: 2288 | sip every hop: 3958 | not run |
| Regatta (3900) | coach-obeyer, one grounding: 2095 | | |

Yes, skill pays. Off-Leash goes 1.9× from first-timer to expert, and the expert has two things to master: the shave timing and MATADOR's direction. One change: the CLOSE SHAVE window on dog 1 is B at glow +14 to +22 f, so a 12 f hand off the glow gets NICE. At glow +12±3 I scored 6775 with 2 tackles, below the NICE line. You have to *wait* a beat, which the card does say ("LATER B"). Tallboy sipping pays 1.7×.

## 5. Hidden tricks by hand
- **Bike, TTC TRANSFER +100:** landed 3 of 5 timings. It now needs the 501: a blue spark at its pole lights the rails blue for about 50 f, and you hop them while they glow. Best new tell in the game.
- **Off-Leash, OLE! MATADOR +600:** landed on my first try, and the full run scored 10575. Tell: the glow.
- **Bay, SLALOM X3:** seen in the demo, not landed.
- **Regatta:** not found (see above).
- **Tallboy, TTC, Parking:** not attempted this round.

## 6. PLAYTEST.md report
1. Lena: I shipped two SNES sports games.
2. **9/10.** Tighter, fairer and better signposted. vs CG: 8/10.
3. Per event:
   - Bike 9: rail hops fair at 12–28 f after the prompt, and the transfer now has a tell.
   - Bay 7: you make the train, but DECAF every time.
   - Off-Leash 10: a ladder of four verbs.
   - Tallboy 9.
   - Regatta 8: the coach is excellent, and the hidden trick is gone.
   - Parking 8: I released ▲ 15 f after LET GO and stopped short.
   - TTC 7: the gold doesn't pay.
4. Loved: the blue rails; MATADOR beating the record; "I'LL CALL TACKS".
5. Problems: ttctap-72122001 [major], bayL1-72131511 [minor], bayL2-71999475 [minor ux], no tell for the Regatta trick [design].
6. California Games' tricks paid more than the safe line. TTC's gold doesn't yet.
7. A "Mind the gap" chime when a gold leg holds. Pigeons scattering when you DECAF.
8. "The streetcar sparked, the rails lit up, and my thumb knew what to do."

## 7. Is it as good as California Games yet?
Bike, Off-Leash and Tallboy are. The biggest thing in the way is still **TTC's gold**. The card names the verb, but tapping it at human speed scores less than holding.
