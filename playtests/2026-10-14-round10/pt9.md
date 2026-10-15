# pt9 Hal (tournament host), round 10

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10:**
- overall 5 → 6.5 → 7 → 7.5 → 8 → 8 → 8 → 8.5 → 8.5 → **9**
- vs California Games 5 → 6.5 → 7 → 7.5 → 8 → 8 → 8 → 8.5 → 8.5 → **8.5**
- Bike 6 → 6.5 → 7 → 7 → 7.5 → 8 → 8 → 8 → 7.5 → **8** · Bay 6.5 → 7 → 7.5 → 7.5 → 8 → 8 → 8 → 8 → 8 → **8** · Off-Leash 5 → 6.5 → 6.5 → 6.5 → 7 → 7 → 7.5 → 7.5 → 7 → **8** · Tallboy 3 → 7.5 → 7.5 → 7.5 → 7.5 → 7.5 → 7.5 → 7.5 → 7.5 → **7.5** · Regatta 3 → 4 → 5 → 6.5 → 6 → 6.5 → 6.5 → 7.5 → 8 → **8**
- Parking 6.5 → 6 → 7.5 → 7.5 → 8 → 8 → 8.5 → **8.5** · Subway 5 → 7.5 → 8 → 8 → 7.5 → 8.5 → 8.5 → **9**

I'm Hal. I run California Games brackets at conventions. I judge whether strangers can play this fairly, in turns.

## 1. My round-9 complaints
- **Off-Leash tackle cliff (pt9r9-parkc-22272311): FIXED.** Tackles cost a heart and time, never points. Holding ▲ into every dog now banks 300 (it was 0). I ran a bot that reads the screen and presses B 18, 45, 70 and 100 f after the white "!". It scored 6960 / 7010 / 6610 / 7350, a ±5% band a bracket can live with. Only at 130 f (B never really pressed) is it tackled out, and that run still banks 550.
- **"HALF THE DOGS" with no DOGS row (pt9r9-parkc-22273441): FIXED.** The fail card now shows "+ DOGS HALF KEPT 150".
- **"STEER HARD OVER RAILS" (pt9r9-wob-22284079): FIXED.** It now reads "RAIL WOBBLE! / HOP THE RAILS: B", my exact rewrite.
- **No tell for hidden tricks (pt9r9-att-22284626): BETTER.** Bike's 3-frame rail flash is now a blue spark under the 501's back end that lasts about 70 frames, and the rails glow for about 50. I can react to that, but I still didn't land the trick (section 4).
- **Bike 1-in-6 crash (bot data): UNCHANGED.** bike_human is still 237 against a 3505 median.

## 2. Regressions and new issues
- **[minor] pt9r10-lb18-72464885:** the Off-Leash finish card reads "WALK 1000 + TIME 2950", but 2950 is walk and time together, so 1000 + 2950 + 4010 ≠ 6960. Regatta's card already splits this out ("FINISH 1000 / 50 SEC AT 15 750"); Off-Leash should copy it.
- **[minor] pt9r10-sag-72481431:** "AGROUND! TAP ▶ TO BEAR OFF" is the only coach order with no count. I tapped 4 times, like the order before it, and ended up "IN IRONS! TAP ◀ 2 TIMES", about 3 s lost.
- **Not filed:** after mark 1 the coach says "TAP ◀ 3", then "5 more". Tapping all 8 fast, as you would for a CLEAN TACK, turned me back onto mark 1 ("MISS THE BUOY!") and cost my LINE HONOURS. Doing the skilful thing should not walk you into the mark you just rounded.
- **Fairness check, passed:** I played 2P TTC with identical inputs and both scored 546. Same train, a shared gold, and the podium reads "CO-CHAMPIONS OF TORONTO / TIED ON 5 PTS AND MEDALS". That's the best tie screen I've seen in this genre.

## 3. Copy: 8.5/10
**Clear:**
- "B ON ANY ! = SAFE DODGE / LATER B = MORE PTS: RISKY!" fixes the round-9 shorthand.
- "RED ! = B NOW FOR +400"
- "RAIL WOBBLE! HOP THE RAILS: B"
- "KISSED THE 501! DROPPED 2 TOKENS" and "TACKLED! −1 ♥. SO FRIENDLY" both land as jokes.

**Unclear:**
- "AGROUND! TAP ▶ TO BEAR OFF"
- "WALK 1000 + TIME 2950"
- "OTHER STYLE 110" on Off-Leash: other than what?
- The Parking card's "NOW! IN THE PANEL: ▼+◀" still reads like a typo until you've played.
- "MARK 1 ROUNDED! WAIT..." Wait for what?

**Rewrite:** "AGROUND! TAP ▶ ONCE TO BEAR OFF".

## 4. Mastery
**Curves, 8 f vs 18 f medians:** Bike 1.8×, Bay 1.6×, Off-Leash 1.5×, Tallboy 1.5×, Regatta 1.5×, Parking 1.2×, TTC 2.0×.

**Human bot vs best bot:** Off-Leash 6792 vs 13950 (2.05×, bang on CG), Bay 2.3×, Parking 2.1×, TTC 2.1×, Regatta 1.75×, Tallboy 2508 vs 8944 (3.6×, steeper than round 9).

**My Regatta, played twice:**
- First-timer at 18 f: 2050.
- Practised, with fast tacks, a hike and the ferry surf: 2285.

That's only 1.1× by my own hand. The top end needs tight roundings chained, and I didn't land one on purpose. There is more than one thing to master: roundings, tacks, ferry, line honours. Off-Leash now has a real risk ladder: the CLOSE SHAVE window is about 893–897 f, just after the glow, and I hit it 3 times in 3 tries.

**Hidden tricks:**

| Event | Trick | Tries | What I got | Tell |
|---|---|---|---|---|
| Bike | TTC TRANSFER | 8 | TRACK HOP +50, DRAFTING THE 501 +60 and two KISSED THE 501! | Spark plus glowing rails, clear on screen. It tells me *when*, not *what*. |
| Off-Leash | OLE! | 6 | NICE TIMING and CLOSE SHAVE | None beyond the documented glow. |
| Others | – | 0 | Not tried this round | – |

I can't judge sound from the harness.

## 5. Report sections
- **Overall 9/10:** the last fairness hole I cared about is closed. **vs CG: 8.5**, because the tricks are still demo-only.
- **Per event:**
  - **TTC 9:** same train and a proper tie.
  - **Parking 8.5:** bots only this round.
  - **Off-Leash 8:** the cliff is gone, and the spread matches CG's.
  - **Bike 8:** the wobble copy and the spark.
  - **Regatta 8:** the card adds up, but the aground order has no count.
  - **Bay 8:** bots only.
  - **Tallboy 7.5:** a 3.6× spread is too steep for mixed brackets.
- **Turn lengths:**
  - Regatta 30–40 s
  - Off-Leash 42 s
  - Bike ~43 s (to the 3rd wipeout)
  - TTC 62 s
- **Loved:**
  1. CO-CHAMPIONS OF TORONTO.
  2. Off-Leash scoring that forgives.
  3. The 501's spark.
- **Top problems:**
  1. [minor] pt9r10-sag-72481431
  2. [minor] pt9r10-lb18-72464885
  3. Tallboy's 3.6× spread (bot data)
  4. Bike's 1-in-6 crash (bot data)
  5. Hidden tricks with no "what"
- **CG had:** tricks you could figure out by trying.
- **More Toronto:** have the spark come with a trolley-pole *zap* in the audio, and let the coach mutter "TRANSFER'S GOOD FOR TWO HOURS" the first time you see it.
- **Quote:** "Two players, same train, same score, two golds. That's a tournament."

## 6. Is it as good as California Games yet?
For running a bracket, yes: ties, turn lengths, same conditions and score spread all hold up. The single biggest thing in the way of matching CG is still the hidden tricks. Bike now shows you *when* its trick is possible but not *what* to press, and the rest give no hint at all. Until a player can find a trick by experimenting, a heat can go to whoever watched the attract loop.
