# pt9 Hal (tournament host), round 9

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9:**
- overall 5 → 6.5 → 7 → 7.5 → 8 → 8 → 8 → 8.5 → **8.5**
- vs California Games 5 → 6.5 → 7 → 7.5 → 8 → 8 → 8 → 8.5 → **8.5**
- Bike 6 → 6.5 → 7 → 7 → 7.5 → 8 → 8 → 8 → **7.5** · Bay 6.5 → 7 → 7.5 → 7.5 → 8 → 8 → 8 → 8 → **8** · Off-Leash 5 → 6.5 → 6.5 → 6.5 → 7 → 7 → 7.5 → 7.5 → **7** · Tallboy 3 → 7.5 → 7.5 → 7.5 → 7.5 → 7.5 → 7.5 → 7.5 → **7.5** · Regatta 3 → 4 → 5 → 6.5 → 6 → 6.5 → 6.5 → 7.5 → **8**
- Parking 6.5 → 6 → 7.5 → 7.5 → 8 → 8 → **8.5** · Subway 5 → 7.5 → 8 → 8 → 7.5 → 8.5 → **8.5**

I'm Hal. I run California Games brackets at conventions and I judge whether strangers can play this fairly, in turns.

## 1. My round-8 complaints
- **Coach flipped to "MARK 3! NOW TAP ▶ 4 TIMES" after mark 3 (pt9r8-sail3-11884256): FIXED.** I replayed the same slow run. The order holds "GOOD! TAP ▶ 3 MORE TIMES" for 8 s and never flips. The half-turn stall head-to-wind is still there, but the order no longer changes under me.
- **Regatta card lumps style (pt9r8-sail-11893932): FIXED.** The card now reads "+ STYLE 700 / TIGHT ROUNDING 500 / CLEAN TACKS 200", and on my hiking run "LINE HONOURS 300" gets its own row. I can check every point.
- **SCORE column tiebreak unstated: FIXED.** The manual now says "The SCORE column never breaks a tie" and that the tables show "SAME PTS: GOLDS, NOT SCORE". I didn't run a 2P tie this round to see it on screen.
- **Parking's flat top: FIXED.** The bots go park_human 3104, expert 6477, tas 7249.
- **Off-Leash sloppy coin flip: UNCHANGED, and the spread is wider.** park_sloppy scored 0–7200 (sd 2721), and 2 of 6 runs were 0. Holding ▲ by hand earned "WALK 50 A TENTH 150 / − TACKLES X150 450 / = SCORE 0".

## 2. Regressions and new issues
- **[major] pt9r9-parkc-22272311:** the Off-Leash tackle cliff described above.
- **[minor] pt9r9-wob-22284079:** "RAIL WOBBLE! STEER HARD OVER RAILS" came up every time I held the d-pad for 6, 10 or 16 frames to change lanes. The game never says what counts as "hard".
- **[minor] pt9r9-parkc-22273441:** the fail card says "HEARTS GONE: HALF THE DOGS" but has no DOGS row for that line to refer to.
- **[note] pt9r9-att-22284626:** I found no tell for the hidden tricks (section 4).
- **Not filed, bot data only:** bike_human now crashes out 1 run in 6 (237 against a 3505 median), and so does bike_commuter. That spread didn't exist last round.
- **Not filed, bot data only:** the Regatta curve doesn't rise steadily with reaction speed. At 24 f it scores 3112, more than the 2832 at 15 f.
- **Records went up:** Off-Leash is now 10000 (leash_human scores 3977), so solo gold is out of reach.

## 3. Copy: 8.5/10
**Clear:**
- Parking's coach is the best in the game. "LET GO OF ▲: STOP ON THE LINE", "NOW! ROLL TO DOWN+LEFT", "STRAIGHT! LET GO OF THE PAD" and "WAIT! LET THE BIKE GO BY" took me, as a first-timer at 18 f, to a 1035 spot with ONE-MOVE and DEAD CENTRE on my first try.
- "GOOD PARK! NEXT: HUG CURB"
- "THIRD WIPEOUT. NO DELIVERY / PAID FOR THE RIDE ONLY"
- "COP CAUGHT YOU: FINED 1/4"
- "GRAB A POLE, GET GERMS." lands as a joke.

**Unclear:**
- "STEER HARD OVER RAILS"
- "HEARTS GONE: HALF THE DOGS / DUNDAS PAYS THEM ALL"
- The Off-Leash card line "SAFE: B ON ! = 100 PER DOG" is shorthand, not a sentence.
- The grey style rows are packed at half-line spacing. On Bay, "PERFECT STEPS 107 / DOUBLE TIME 18" touch each other.

**Rewrite:** "RAIL WOBBLE! HOP RAILS WITH B".

## 4. Mastery
**Reaction speed, curve medians at 8 f vs 18 f:**

| Event | 8 f | 18 f | Ratio |
|---|---|---|---|
| Bike | ~5500 | 3320 | 1.7× |
| Off-Leash | ~10000 | 5490 | 1.8× |
| Tallboy | ~4650 | 3150 | 1.5× |
| Regatta | ~3950 | 2980 | 1.3× |
| Parking | ~3800 | 3110 | 1.2× |

**Style ceilings, human bot vs best bot (n = 6):**

| Event | Human | Best | Spread |
|---|---|---|---|
| Bike | 2958 | 8628 | 2.9× |
| Bay | 1906 | 4281 | 2.2× |
| Off-Leash | 3977 | 14004 | 3.5× |
| Tallboy | 2766 | 8366 | 3.0× |
| Regatta | 2828 | 4928 | 1.7× |
| Parking | 3104 | 7249 | 2.3× |
| TTC | 4139 | 8389 | 2.0× |

Every event now pulls an expert clearly away from a first-timer, and Parking finally does too. Off-Leash and Tallboy are steeper than CG's 2×.

**My Regatta, played twice:**
- First-timer: 2315.
- Second run: I held A through the second tack in a gust. The boat didn't bump, so LINE HONOURS paid +300 and I finished 2 s sooner, for **2645**.

There's more than one thing to master:
- Regatta: roundings, tack speed, hiking.
- Parking: line, swing, NONSTOP, curb kiss.

**Hidden tricks: 0 of 7 landed by hand.** I watched every demo, so I know the names:

| Event | Trick (as seen in the demo) | What I tried | Tries |
|---|---|---|---|
| Bike | TTC TRANSFER. In the demo the rails flash blue for about 3 frames and it hops on the flash. | I never saw the flash in ~1000 frames of my own riding. | 3 |
| Off-Leash | OLE! MATADOR | Sidesteps and a late B. I only got DODGE and NICE TIMING. | 5 |
| Regatta | ROLL TACK | Hiking through tacks. | 2 |
| Parking | BIKE SHAVE | Reversing 0–18 f after the cyclist. | 4 |
| TTC | LOOK MA, NO HANDS | Hands off at STAND CLEAR. | 2 |
| Bay | SLALOM | Not tried | – |
| Tallboy | LIQUID COURAGE | Not tried | – |

The Bike flash is the only tell I saw, and it's far too short to react to.

## 5. Report sections
- **Overall 8.5/10:** the cards and coaches are now clear enough for a convention floor. **vs CG: 8.5/10.**
- **Per event:**
  - **Parking 8.5:** the coach.
  - **TTC 8.5:** the same train for everyone.
  - **Regatta 8:** the card adds up.
  - **Bay 8**
  - **Bike 7.5:** the new 1-in-6 crash spread, and the wobble line.
  - **Tallboy 7.5**
  - **Off-Leash 7:** the cliff.
- **Turn lengths:**
  - Parking 26–31 s
  - Regatta 20–29 s
  - Bay 42–63 s
  - Bike 51–56 s
  - TTC 62 s
  - Tallboy 63–68 s
  - Off-Leash 39–70 s
- **Loved:**
  1. The Parking coach.
  2. Regatta cards a judge can check.
  3. The tiebreak, written down.
- **Top problems:**
  1. [major] pt9r9-parkc-22272311
  2. [minor] pt9r9-wob-22284079
  3. [minor] pt9r9-parkc-22273441
  4. [note] pt9r9-att-22284626
  5. The Bike crash spread (bot data)
- **CG had:** tricks you could see coming.
- **More Toronto:** turn the Bike trick's 3-frame rail flash into a proper trolley-pole spark from an oncoming 501, big enough to react to.
- **Quote:** "A trick only the attract loop knows isn't a trick, it's a rumour."

## 6. Is it as good as California Games yet?
For running a bracket, yes, on six events. The biggest thing in the way is still Off-Leash: three late Bs can take a competent walk to 0. I'd also want the hidden tricks to have a tell a human can catch, or a heat goes to whoever watched the demo.
