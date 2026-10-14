# pt9 Hal (tournament host), round 7

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7:**
- overall 5 → 6.5 → 7 → 7.5 → 8 → 8 → **8**
- vs California Games 5 → 6.5 → 7 → 7.5 → 8 → 8 → **8**
- Bike 6 → 6.5 → 7 → 7 → 7.5 → 8 → **8** · Bay 6.5 → 7 → 7.5 → 7.5 → 8 → 8 → **8** · Off-Leash 5 → 6.5 → 6.5 → 6.5 → 7 → 7 → **7.5** · Tallboy 3 → 7.5 → 7.5 → 7.5 → 7.5 → 7.5 → **7.5** · Regatta 3 → 4 → 5 → 6.5 → 6 → 6.5 → **6.5**
- Parking 6.5 → 6 → 7.5 → 7.5 → **8** · Subway 5 → 7.5 → 8 → 8 → **7.5**

I'm Hal. I've run California Games brackets at conventions, and I judge whether strangers can play this fairly in turns.

## 1. My round-6 complaints
- **Regatta coach/ADRIFT cliff (pt9r6-sail): UNCHANGED.** I played by hand at about 18 frames and did what the coach said. My first tap gave TIGHT ROUNDING +500 at mark 1. At mark 2 the boat crossed the ring's dots twice without the mark counting. After I'd tapped "TO MARK 2: TAP ▶ 5 TIMES", the order was still on screen, so I tapped it again and went IN IRONS. ADRIFT ended the race while I was sailing at the mark on green diamonds: 459 at 39 s, and the +500 vanished. That's **pt9r7-sail-999912881 [major]**. My old repro now gives 250.
- **Regatta expert variance (pt9r6-flail1): FIXED.** sail_expert's sd is 96–117 (it was 870). Seeds 1–3 give the same course.
- **Off-Leash masher turn (pt9r6-pmash): FIXED.** Holding ▲ and mashing B is now tackled out in about 18 s for 0, not 85 s. Hearts are empty, and the card reads "3 HEARTS GONE. NO DOGS!"
- **Parking reaction cliff: FIXED.** The coach bot scores ≈3400 at 8 frames and 2709 at 18 (it was 3×). By hand at 18 frames, obeying the coach got 936 on spot 1 with ONE-MOVE. Last round I got 775.

## 2. Regressions and new issues
- **[major] pt9r7-sail-999912881:** see above. A finish is 2300–3600 for the human bots. I got 459 twice, two rounds running.
- **[minor] pt9r7-sail2-374228:** at mark 2 the boat sprite sits across the dotted ring for more than a second and the mark doesn't count. What the room sees has to be what counts.
- **[minor] pt9r7-2p-327091:** in 2P TTC, an identical blind lean script scored 160 for P1 and 200 for P2, and P2 took gold. Last round the same test tied. Experts barely vary (sd 5), so only low-skill heats are a draw.
- **[minor] pt9r7-bike-364265:** the Bike card shows "THIRD WIPEOUT. NOT PAID!" directly under "= SCORE 279".
- **Records now span 3000 (Bay) to 8000 (Off-Leash).** park_ace scores 11162. Medals are per event, so this is cosmetic.
- **Parking spot cliff:** practised timing that's a few frames off gives HALF IN for +75 instead of 943.

## 3. Copy: 8/10
**Clear:**
- The Parking coach line by line: "LET GO OF ▲: STOP ON THE LINE", "NOW! ROLL TO DOWN+LEFT", "STRAIGHT! LET GO OF THE PAD", then "PARKED. IT'LL DO."
- "ZIG-ZAG: WAIT FOR TACK NOW!"
- "RED ! = B NOW FOR +200"
- "THE 5:42 LEFT WITHOUT YOU / WALK PAID BY DISTANCE"
- Every card's sum checks out (Tallboy: 533 + 96 − 157 = 472).

**Unclear:**
- **Regatta.** "TAP ▶ 5 TIMES" stays up after you've done it, and reads as "do it again". "RING AHEAD! HOLD YOUR COURSE" was still showing after the HUD had moved on to TO MARK 2. The ADRIFT card hides the rounding bonus it forfeited (Bike shows forfeits in grey).
- **Parking card.** "DOWN+LEFT ON NOW!" takes a second read.
- **Bike.** "NOT PAID!" (above).

**Rewrite:** clear the order box the moment the taps are done and show "GOOD. HOLD IT…" in its place.

## 4. Mastery
**Reaction speed, 8 f vs 18 f (bot medians):**

| Event | 8 f vs 18 f |
|---|---|
| TTC | 2.1× |
| Bike | 1.9× |
| Off-Leash | 1.75× |
| Bay | 1.7× |
| Tallboy | 1.5× |
| Regatta | 1.4× |
| Parking | 1.25× |

That's a tidy 1.25–2.1× band, and Tallboy no longer ignores skill.

**Style ceilings, human bot vs best bot:**

| Event | Human | Best | Spread |
|---|---|---|---|
| Bike | 3605 | stylist 7195 | 2.0× |
| Bay | rookie 1785 | ear 4080 | 2.3× |
| TTC | 3847 | expert 8049 | 2.1× |
| Off-Leash | 3780 | ace 11162 | 3× |
| Tallboy | 2336 | pro 7445 | 3.2× |
| Regatta | 2765 | expert 4930 | 1.8× |
| Parking | 5420 | expert 5610 | flat |

Most events land at California Games' 2×. Parking's top end is now a single skill, timing; coach-only play is half of that (2312).

**My own two plays:**
- **Regatta,** first-timer and then a practised line into mark 2: both missed the ring.
- **Parking spot 1:** first-timer 936, practised 943 or 75.

**Hidden tricks:** none found by play. I saw the words "ROLL TACK" in the git log. I tried hiking (A) through a tack and got no popup.

## 5. Report sections
- **Overall 8/10:** the fairest build yet everywhere except one event. **vs CG: 8/10.**
- **Per event:**
  - **Bike 8:** honest, with style worth 2×.
  - **Bay 8:** three skills to master.
  - **Parking 8:** the coach is gold, but the top is flat.
  - **Off-Leash 7.5:** mashers are out fast now, but expert turns run 71–78 s.
  - **Tallboy 7.5:** reaction counts now.
  - **TTC 7.5:** a draw in low-skill heats.
  - **Regatta 6.5:** fair between experts, a cliff for first-timers.
- **Turn lengths:**
  - Regatta: finish 21–31 s, ADRIFT 12–39 s
  - Parking 27–33 s
  - Bay 44–63 s
  - Bike 53–57 s
  - TTC 62 s
  - Tallboy 63–69 s
  - Off-Leash 56–83 s
- **Loved:**
  1. The Parking coach and the meter man with the $75 ticket.
  2. Every card adds up.
  3. Consistent skill spreads across events.
- **Top problems:**
  1. [major] pt9r7-sail-999912881
  2. [minor] pt9r7-sail2-374228
  3. [minor] pt9r7-2p-327091
  4. [minor] pt9r7-bike-364265
  5. Parking HALF IN cliff (curve note)
- **CG had:** a botched run that still scored on a slope.
- **More Toronto:** the ferry horn as the Regatta gun, a "please move to the back" chime on TTC.
- **Quote:** "Six events I'd run blind. The seventh still needs a judge at the buoy."

## 6. As good as California Games?
**On six events, yes.** The single biggest thing in the way is still the Regatta's first-timer cliff. Count a pass that crosses the drawn ring, clear the coach's order once it's done, and freeze ADRIFT while the bow is on green diamonds.
