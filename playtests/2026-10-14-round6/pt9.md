# pt9 Hal (tournament host), round 6

**Round 1 → 2 → 3 → 4 → 5 → 6:**
- overall 5 → 6.5 → 7 → 7.5 → 8 → **8**
- vs California Games 5 → 6.5 → 7 → 7.5 → 8 → **8**
- Bike 6 → 6.5 → 7 → 7 → 7.5 → **8** · Bay 6.5 → 7 → 7.5 → 7.5 → 8 → **8** · Off-Leash 5 → 6.5 → 6.5 → 6.5 → 7 → **7** · Tallboy 3 → 7.5 → 7.5 → 7.5 → 7.5 → **7.5** · Regatta 3 → 4 → 5 → 6.5 → 6 → **6.5**
- Parking 6.5 → 6 → 7.5 → **7.5** · Subway 5 → 7.5 → 8 → **8**

I'm Hal. I've run California Games brackets at conventions, and I judge whether a room of strangers can play this fairly in turns.

## 1. My round-5 complaints
- **Regatta flailer, 92 s for 0: FIXED (the turn length).** Three random ◀ ▶ flailers now end ADRIFT at 13–17 s with 50–109 points. Idle scores 0 at 11 s, and a flailer now beats idle. But tap-twice-and-let-go (169) still beats the flailer (109). See the new issue below.
- **Off-Leash blind B: FIXED.** Holding ▲ and tapping B every second now ends TACKLED! for 0. The card shows the full sum (246 + 100 − 450) and SCORES NEVER GO BELOW 0.
- **Bay card silent on DOUBLE TIME: FIXED.** The card now says "SMALL DOTS = DOUBLE TIME". "MADE THE 5:42!" is the header I asked for.
- **Bike token line: FIXED.** "FORFEIT TIPS, STYLE 100" sits in grey under = SCORE, and the hearts are gone. "LET GO OF THE BUTTONS" is a smart guard against mashing.
- **"HOP RAILS, DODGE LATE: X8" reads like a password: FIXED.** The line was replaced with "TOKENS PAY 50 ON DELIVERY". It's clear, but the card no longer mentions style at all.
- **PRESS A doesn't always show: FIXED.** Every card now ends "A READY / B OTHER EVENT", or "HAND THE PAD TO…" and then "PRESS A WHEN READY".

## 2. Regressions and new issues
- **[major] pt9r6-sail-989879571.** I played the Regatta by hand at about 18 frames and did exactly what the coach said. I rounded mark 1 (TIGHT ROUNDING +20). Then I followed "TACK NOW! TAP ◀ 5 TIMES", and 3 s later "ADRIFT SOON! TAP ◀ 6 TIMES". The boat swung past mark 2, a boat-length outside its ring, and the race ended with "ADRIFT! GETTING NOWHERE" while I was circling the mark. That was 33 s in, for 445. A finish pays about 2500–3000. That 6–25× cliff for one missed ring decides a bracket.
- **[minor] pt9r6-flail1-990254268.** The same sail_expert bot scores between 3295 and 5675 depending on the seed, with style ranging from 620 to 3100 (sd 870). The TTC expert's sd is 6. One bump appears to cost a style chain worth about 2000, which makes a two-expert final a lottery.
- **[minor] pt9r6-pmash-990168719.** In Off-Leash, holding ▲ and mashing B is an **85 s turn for 0** (the bot takes 109 s). The worst player gets the longest turn while the queue waits. After the third tackle the HUD still shows ♥♥♥.
- **Parking reaction cliff (curve flag).** The coach bot scores 5004 at 8 frames and 1661 at 18. By hand at 18–24 frames I overshot the line, recovered with the coach, and got 775 on spot 1. It's fair, but steep.

Fairness checks that passed:
- 2P with identical Regatta inputs: 215 / 215, a shared gold.
- 2P TTC with an identical lean script: the rides differ (germs 21 vs 20, PATIENT ZERO about 4 s apart), but both scored 160. The expert bot's sd of 6 says the randomised legs don't move skilled scores. That's fair for a bracket.
- "CO-CHAMPIONS OF TORONTO / TIED ON 10 PTS AND MEDALS" appears on both the podium and the final table.

## 3. Copy: 8/10
**Clear:**
- The Parking coach ("PAST IT! ↓ BACK TO THE LINE", "NOW! ROLL TO DOWN+LEFT", "STRAIGHT! LET GO TO STOP"), with "PARKED. IT'LL DO." as the payoff.
- The Off-Leash card's "SAFE: B WHEN ! SHOWS: 50 / BOLD: B AS HE LUNGES: 150+", the best risk/reward line in the game.
- "COP CAUGHT YOU: FINED 1/4", and the sum is honest (157 − 39 = 118).

**Unclear:**
- **Regatta.** "TACK NOW! TAP ◀ 5 TIMES" followed by "TAP ◀ 6 TIMES" feels like the coach changing its mind. "ADRIFT! GETTING NOWHERE" fired while I was beside the mark. The card never mentions ADRIFT or that bumps cost time.
- **Off-Leash.** The card never warns that a B with no dog about leaves you off balance.
- **Bike.** The card has lost every word about style.

**Rewrite:** Regatta coach → "HOLD ◀ TILL THE DIAMONDS GO GREEN". It replaces a count that's wrong by the time you've finished tapping.

## 4. Mastery
**Bay, played twice from the same start:**

| Play | Score |
|---|---|
| First-timer (±8 f) | 808–813 (made it with 1 s spare) |
| Steady metronome | 1238 |
| Blind double time | 2094 (#4 on the board) |
| bay_ear bot | 4066 |

That's 2.6× from technique alone and 5× at the top. There are three things to master: the beat, double time, and lanes/EXCUSE ME (blind lane hops *lose* points, so lanes reward looking).

**Reaction speed, 8 f vs 18 f:**

| Event | 8 f vs 18 f |
|---|---|
| Parking | 3.0× |
| TTC | 2.1× |
| Bike | 1.7× |
| Bay | 1.4× |
| Off-Leash | 1.2× |
| Regatta | 1.1× |
| Tallboy | 1.04× |

Style pulls Bike (rider 6978 vs human 3490), Off-Leash (ace 7100 vs human 1775), Tallboy (pro 4670 vs human 1617) and TTC (expert 8050 vs human 3824) to 2–4×. That's California Games territory. The Regatta is the exception: its gap is a cliff, not a slope.

## 5. Report sections
- **Overall 8/10:** still the build I'd put on the bar TV. **vs CG: 8/10.**
- **Per event:**
  - **Bike 8:** honest card, style worth 2×.
  - **Bay 8:** taught on the card now.
  - **TTC 8:** random but fair.
  - **Tallboy 7.5:** unchanged.
  - **Parking 7.5:** great coach, steep curve.
  - **Off-Leash 7:** the exploit is gone, but mashers get long turns.
  - **Regatta 6.5:** short turns now, but all-or-nothing.
- **Turn lengths:**
  - Regatta: ADRIFT 11–33 s, finish 23–33 s
  - Bay 45–63 s
  - Bike 43–56 s
  - Tallboy: busted 33 s, finished 64 s
  - Parking 14–44 s
  - TTC 62 s
  - Off-Leash: up to 85–109 s for a masher
- **Loved:**
  1. The co-champions ceremony.
  2. The Parking coach.
  3. Every result card now adds up on screen.
- **Top problems:**
  1. [major] Regatta coach/ADRIFT cliff (pt9r6-sail-989879571).
  2. [minor] Regatta expert variance (pt9r6-flail1-990254268).
  3. [minor] Off-Leash masher turn (pt9r6-pmash-990168719).
  4. Parking 3× reaction cliff (curve flag).
  5. Records still range from 3000 to 6000 across events.
- **CG had:** a bad run that still scored on a slope, not 1/10th of a good one.
- **More Toronto:** the ferry horn as the start gun, "please move all the way to the back" on TTC, a Green P ticket guy.
- **Quote:** "Nobody asked me the rules tonight. They argued about the Regatta, which is the one I'd still leave out of the final."

## 6. As good as California Games?
**On six events, yes.** The single biggest thing in the way is the Regatta's cliff. You either finish (~2500+) or you're ADRIFT (100–450), and a first-timer obeying the coach can be ended next to the mark. Don't fire "no closer" within about two ring radii of the next mark, and give the coach one instruction per tack. Then it's a full bracket.
