# Toronto Games: playtest round 2, 2026-10-13

These are the same ten testers as in round 1, playing the build after the music placement work and
the seven-agent fix sprint. This time they used the `tools/pt` harness, re-tested each of their own
round-1 complaints, and filed every finding with a verified repro. That gave 50 findings: 17 major,
32 minor and 1 note. You can list them with `python3 tools/pt/pt.py findings`. The per-tester reports
are in `playtests/2026-10-13-round2/`.

## Scoreboard (round 1 → round 2)

| Tester | Overall | vs CG | Bike | Bay | Off-Leash | Tallboy | Regatta |
|---|---|---|---|---|---|---|---|
| Dana, beginner | 6 → **7** | 6 → 7 | 7 → 6 | 3 → **6** | 6 → 6 | 6 → 4 | 1 → **4** |
| Marcus, party host | 6 → **7** | 5 → **7** | 6 → 6 | 4 → 5 | 6 → 5 | 6.5 → 6.5 | 3 → 4 |
| Priya, YouTuber | 6 → **7** | 5 → 6.5 | 6 → 6 | 5 → 7 | 6 → 7 | 6 → 6 | 3 → **6** |
| Rob, score attack | 5 → **7** | 5 → 6 | 6 → 7 | 6 → 6 | 4 → 6 | 3 → **7** | 7 → 7 |
| Lena, designer | 5 → 6 | 4 → 5 | 6 → 6 | 6 → 7 | 5 → 6 | 4 → 5 | 3 → 4 |
| Gord, Torontonian | 6 → 6 | 5 → 5 | 7 → **5** | 6 → 6 | 5 → 6 | 4 → 5 | 4 → 5 |
| Kenji, art/audio | 6 → **7** | 5 → 6 | 6 → 7 | 6 → 7 | 6 → 6 | 7 → 7 | 4 → 6 |
| Tasha, completionist | 5.5 → **7** | 5 → 6.5 | 6 → 6 | 5 → 6 | 5 → 5 | 4 → 5 | 3 → 4 |
| Hal, tournament host | 5 → 6.5 | 5 → 6.5 | 6 → 6.5 | 6.5 → 7 | 5 → 6.5 | 3 → **7.5** | 3 → 4 |
| Mo, QA | 5 → 6.5 | 5 → 6 | 6 → 7 | 4 → 5 | 6 → 6 | 5 → 5 | 4 → 5 |
| **Average** | **5.6 → 6.7** | **5.0 → 6.2** | 6.2 → 6.3 | 5.2 → **6.2** | 5.4 → 6.0 | 4.9 → **5.8** | 3.5 → **4.9** |

Every tester rated the game the same or higher. The biggest per-event gains were the Regatta
(+1.4), Bay St (+1.0) and Tallboy (+0.9). Gord's Bike score dropped (7 → 5) because the
curb lane is now too punishing for an intermediate player. Dana's Tallboy score dropped (6 → 4)
because being busted now wipes the whole score.

## Verified fixed

The testers confirmed these fixes against their own round-1 repros.

**Scoring and balance**
- No-skill exploits are gone in every event. Hold A on Bike now scores 510; hold B in Tallboy gets you busted in about 4 s for 0.
- A failed run can no longer outscore a finish, and a score of 0 never wins a medal.
- Ties share the place, with "CO-CHAMPIONS … A DEAD HEAT".
- Solo medals are measured against the Toronto Record.
- Per-event seeds are fixed, so a Practice route works the same in a competition (Rob checked this byte for byte).

**Flow and menus**
- Card input lockouts. Retry and REMATCH. Pause with a mosaic overlay.
- A medal table between events with a CN Tower ticker. Marcus: "had us shouting at the TV".
- Blank names, duplicate sponsors and an empty Compete-in-Some are now blocked. All 12 jerseys are distinct, and the menu backdrop band is gone.

**Events**
- Bay St is now a real rhythm event, which Lena called the best change in the build. The Regatta coaches you and recovers you when you run aground. Tallboy's sip-'n'-hop combo has risk and reward; Hal called it "worst to best".
- Every event now fits a bar-night turn: Hal timed them all at about 50–76 s.

**Toronto details**
- Red streetcars, a Bay St tower canyon, Union Station, the Regatta skyline and Billy Bishop airport, and Kensington shopfronts.

**Music**
- Every event has its own track, confirmed by matching the in-game audio against the sound test.
- The podium has a fanfare.
- The audio is stereo with echo and no hum.

**Stability**
- No crashes in about 4 hours of fuzzing, and the testers found none either.

## Still open (17 major findings → themes)

1. **The Regatta is still a cliff, not a curve** (Hal, Marcus, Lena, Gord, Dana; 5 majors). Experts post 3240, but honest human attempts score 0. Problems:
   - The sail's point reads as the bow, so you can't tell which way the boat faces.
   - The lee-shore start puts you back aground after each push-off.
   - Mark 1 is off screen, and getting out of irons responds sluggishly.
   - A 4-player party ended on four 0s.

   Fix: a bigger boat with an obvious bow, an open-water start, mark 1 visible from the start, and some points for progress toward the next mark.
2. **The Tallboy bust feels unfair** (Dana, Kenji, Marcus, Priya, Gord, Tasha). The $300 fine zeroes your score, the HUD and card disagree with no explanation, and the callouts are red text on red roofs. Fix: show the fine as a line on the card, keep part of the score, and put callouts on a text panel.
3. **Mashing still passes into the next player's turn** (Marcus, Priya). Fix: the UP NOW card needs a fresh press from the next player after a longer lockout.
4. **A stray B wipes the roster** (Tasha, Mo). Both "B BACK" on the event picker and "B MENU" on the competitors screen do it. Fix: go back one step, and confirm before dropping the roster.
5. **Humans can't make the Bay St train** (Gord, Dana, Marcus, Mo; Tasha took the record with a blind script). Following the beat honestly gets you to 85–90% of the way.
   - A LATE step gives no stride at all, so the score falls off a cliff.
   - Nothing shows how fast you're going or why.
   - Spamming "excuse me" costs nothing.
   - Identical inputs gave Player 1 and Player 2 different scores (Hal), so the crowd isn't the same for every player.
6. **Bike difficulty is uneven** (Lena, Gord). The lane between the streetcar rails is a safe highway (2437 for one tap left and hold A), while the curb lane is a death trap for intermediates. Respawning in the curb lane can chain hits.
7. **Off-Leash dogs chain-tackle** and charge from behind or off screen (Gord, Lena, Dana). Kenji also reports a tree snag.
8. **The attract mode has no gameplay demo** and the title has no © line (Priya).

Fixed after the panel: the garbled Off-Leash card (that was my edit) and stereo width (now 14–17 dB of
side signal versus 22 dB before).

**Minor themes:**
- Presentation:
  - The two-row HUDs have 8 px rows.
  - A dog draws over the tree canopy, and the fireworks over City Hall.
  - White text sits on the white towers.
  - An 8-way tie only draws 4 co-champions on the podium.
  - Truncated progress labels (Q/SP, K/SPA).
  - The event picker's dot-vs-square toggles are unreadable.
  - The medal table reads "PLAYER 11".
  - The name grid swallows the first input.
- Depth:
  - The results card has no score breakdown.
  - There's only one record per event.
  - Bay has a flat ceiling at 2649.
  - Regatta bumps are too cheap.
- Presentation and craft (Kenji): the athletes are still tiny with 2-frame animation.

## The next big step

Every tester who mentioned depth said the same thing: Tallboy's sip-'n'-hop proved a style mechanic
works here, and the other four events need one. Ideas from the panel:
- **Bike:** a track hop, or drafting the 501.
- **Bay St:** combo streaks on PERFECT steps.
- **Off-Leash:** frisbee catch chains.
- **Regatta:** surfing the ferry wake.

That, plus bigger athletes, is what separates "fixed" from "as good as California Games".

## Quotes

- "This time I made it off the beach, rounded one buoy, and got told we'll get 'em next year. Most Toronto thing I've ever played." (Dana)
- "The ticker had us shouting at the TV; then the Regatta sent everyone to the kitchen." (Marcus)
- "Now it teaches you like Epyx did. Next, show off like Epyx did." (Priya)
- "You fixed the cheese. Now give Bay and the Regatta a combo worth chasing, like Tallboy's." (Rob)
- "Bay found its beat. Now make every event dance like that." (Lena)
- "You finally painted the streetcar red and put the city on the lake. Now let me actually get to Union." (Gord)
- "The menus grew up. Now let the athletes grow up too." (Kenji)
- "I took SUITGUY's record without looking at the screen. Then I hit B one time too many and lost my whole roster." (Tasha)
- "Tallboy finally makes the bar lean in. The Regatta still makes them order another round, just a shorter one." (Hal)
- "Round one I broke it by holding A. Round two I had to sign up eight people just to find a bug, and that's progress." (Mo)
