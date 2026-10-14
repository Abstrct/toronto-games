# Toronto Games: playtest round 3, 2026-10-13

The same ten testers played the build after sprint 2: style mechanics in every event, bigger athletes, new courses,
a pause menu, top-5 records, title demos, and two brand-new events (Parallel Parking and TTC Surfing) from the
other session. The build under test was frozen (`build/pt/panel3`). There were 72 findings: 28 major, 42 minor and 2 notes.
List them with `build/pt/panel3/pt findings`. Per-tester reports are in `playtests/2026-10-13-round3/`.

## Scoreboard (round 1 → 2 → 3)

| Tester | Overall | vs CG | Bike | Bay | Off-Leash | Tallboy | Regatta | Parking | Subway |
|---|---|---|---|---|---|---|---|---|---|
| Dana, beginner | 6 → 7 → 7 | 6 → 7 → 6 | 7 → 6 → **4** | 3 → 6 → 6 | 6 → 6 → 7 | 6 → 4 → 5 | 1 → 4 → 5 | **8** | 4 |
| Marcus, party | 6 → 7 → **7.5** | 5 → 7 → **7.5** | 6 → 6 → 5.5 | 4 → 5 → 6 | 6 → 5 → 6.5 | 6.5 | 3 → 4 → 4 | 6 | 6 |
| Priya, YouTuber | 6 → 7 → **7.5** | 5 → 6.5 → 7 | 6 → 6 → 7 | 5 → 7 → 7 | 6 → 7 → 7 | 6 → 6 → 7 | 3 → 6 → 6.5 | 5 | 6 |
| Rob, TAS | 5 → 7 → 7 | 5 → 6 → 7 | 6 → 7 → **8** | 6 → 6 → **8** | 4 → 6 → **8** | 3 → 7 → 7 | 7 → 7 → 6 | 4 | 4 |
| Lena, designer | 5 → 6 → 7 | 4 → 5 → 6 | 6 → 6 → 7 | 6 → 7 → **8** | 5 → 6 → 7 | 4 → 5 → 6 | 3 → 4 → 5 | 4 | 5 |
| Gord, Torontonian | 6 → 6 → 6 | 5 → 5 → 5 | 7 → 5 → 5 | 6 | 5 → 6 → 6 | 4 → 5 → 5 | 4 → 5 → 4 | 6 | 5 |
| Kenji, art/audio | 6 → 7 → **7.5** | 5 → 6 → 7 | 6 → 7 → **8** | 6 → 7 → 7 | 6 → 6 → 7 | 7 → 7 → **8** | 4 → 6 → 7 | 6 | 5 |
| Tasha, completionist | 5.5 → 7 → **7.5** | 5 → 6.5 → 7 | 6 → 6 → 6.5 | 5 → 6 → 6.5 | 5 | 4 → 5 → 5.5 | 3 → 4 → 5.5 | 4.5 | 4 |
| Hal, tournament | 5 → 6.5 → 7 | 5 → 6.5 → 7 | 6 → 6.5 → 7 | 6.5 → 7 → 7.5 | 5 → 6.5 → 6.5 | 3 → 7.5 → 7.5 | 3 → 4 → 5 | 6.5 | 5 |
| Mo, QA | 5 → 6.5 → 7 | 5 → 6 → 6.5 | 6 → 7 → 7.5 | 4 → 5 → 5 | 6 → 6 → 6.5 | 5 → 5 → 5.5 | 4 → 5 → 5 | 6.5 | 4 |
| **Average** | **5.6 → 6.7 → 7.1** | **5.0 → 6.2 → 6.6** | 6.2 → 6.3 → 6.6 | 5.2 → 6.2 → **6.7** | 5.4 → 6.0 → **6.7** | 4.9 → 5.8 → 6.3 | 3.5 → 4.9 → 5.3 | 5.7 | **4.8** |

The game has improved every round. The five original events now average 5.3–6.7, and Bay St and Off-Leash are
the best rated. The experts (Rob, Kenji, Lena) now give 7–8 on the core events. The two new events come in last,
with TTC Surfing lowest at 4.8.

## Is it as good as California Games yet?

All ten testers said no or "close". Their single biggest blockers fall into three groups:

- **Ordinary players can't succeed** (Gord, Dana, Marcus, Hal, Priya). First-timers score 10–25% of bronze. Bike
  wipes out intermediate players in 15–28 s, the Regatta has no middle (about 300 for a struggler against 2200+ for a sailor),
  and steady Bay steppers miss the train. Gord: *"Give every event a forgiving first minute and it's a 7."*
  Marcus: *"Nobody can steal your turn anymore, but half the time nobody gets to Spadina either."*
- **The two new events don't hold up yet** (Mo, Rob, Priya, Kenji, Hal). TTC Surfing is a reaction-time cliff:
  - At a 6-frame reaction you score 2300. At 12 frames, normal human speed, you score about the same as standing still.
  - It caps flat at 2300 and has no style layer.
  - The car never sways, and the gags only appear as captions.

  Parallel Parking is nine presses, and two of the three timings barely matter (Rob). The meter contradicts the outcome (Lena).
  Gold is two good parks away (Priya), and there's no HUD panel.
- **Scores can't be trusted or learned** (Tasha, Lena, Hal).
  - No result card adds up.
  - Some style bonuses are handed out free: ferry surf pays a boat stuck with no input, and the track hop fires on its own.
  - Others punish you for following the coaching: sipping mid-jump lands you on the bench.
  - A tie on medal points is broken silently by raw score, so the event with the widest score range picks the champion.

## What landed (verified by testers)

- **Meta-loop.**
  - Top-5 records with ghost rivals ("SO LONG, TOWTRUCK!", "+450 OVER GREEN P / WE THE NORTH!").
  - Pause with PLAY ON / CALL IT A DAY, solid in all 7 events.
  - RETRY / OTHER EVENT, and REMATCH / 1 EVENT.
  - Safe handoff: mashing can't steal a turn.
  - The leave-roster confirm.
  - The readable event picker.
  - Tasha: *"the meta-loop now beats California Games."*
- **Title.** Gameplay demos that show off the named tricks, and the © line.
- **Core events.**
  - Bay St's rhythm, PRESTO and POWER WALK.
  - Off-Leash's DODGE 'N' PAT.
  - Bike's TRACK HOP and drafting chains.
  - Tallboy's coaching and RACCOON RUN.
  - Rob rates Bike, Bay and Off-Leash 8/10 as score attacks, and no failed run beats a finish in any of the 7 events.
- **Fairness.** Identical inputs give identical scores across players. Ties share medals, and the 8-way dead heat works.
- **Art.** Bigger athletes with real animation: the courier's side-on tumble and the Tallboy faceplant. Kenji: *"The athletes finally grew up."*
- **Toronto.** Spelled-out stop names and Queen West storefronts. The two new events have the best jokes in the game:
  "BUMPER TAP! (IT'S A BMW)", the "$75 TICKET!" officer, "BO! BO! BO!", "SAT ON A STRANGER! SORRY!".
- **Stability.** No crashes, freezes or soft-locks across about 133 minutes of tester fuzzing, plus the automated runs.

## Fix list for the next sprint (ranked)

1. **A forgiving first minute in every event.** Bike: a safe starting line, wider gaps between hazards early on, and stable steering with no slide after a hop.
   Regatta: the boat sails as soon as the race starts, gentler steering, mark 2 away from the ferry slip, and partial credit
   for each leg. Bay: make it clear why a steady stepper is slow (spills, lanes). Tallboy: a gentler first bench.
   Gold that a TAS can reach (the Regatta's 3000 is above Rob's 2900).
2. **TTC Surfing rework.** These are the other session's files, so coordinate with it.
   - Telegraph each lurch about 20 frames ahead, with the "please stand clear" chime and a readable cue.
   - A slower dot, a bigger balance ring that sits on the rider, and the car swaying.
   - Draw the gags on the rider instead of only captioning them.
   - A style layer, such as a "standing surf" chain per station.
   - Fix the card text ("fewest germs" vs highest score), and fix a pause race that can turn 10 points into 0.
3. **Parallel Parking depth.** Also the other session's files.
   - Make all three presses matter, and make the meter agree with the result.
   - Add steering or style.
   - Add a HUD panel.
   - Replace the "BEST GAP PX" jargon and the 99 sentinel value.
   - Raise the gold bar.
4. **Score you can trust and learn.**
   - A real breakdown on each result card (base + style − penalties = score).
   - Break medal-point ties on golds, then call a shared title, not raw score.
   - Normalise score ranges across events.
   - No passive style: ferry surf, the automatic track hop and the airborne-sip trap.
5. **UI leftovers.**
   - HOW TO PLAY and the README still say "five events" (6 testers).
   - The champion sprite covers TITLE, and REMATCH is the default, so one press restarts the set (5 testers).
   - Mashing a card resets its lockout and no prompt shows (3).
   - The name grid's ~45-frame delay, and the REMOVE cursor deleting a player.
   - The pause-open race.
   - The podium can be skipped too early, and the athletes wear no medals.
   - Demos for the new events.
   - The #5 ghost scores are too low.
   - 8-way tie step layout.
   - Dog over canopy and fireworks over the towers (Kenji).
   - HUD rows in the overscan area, and DC offset in the audio.

## Harness lessons from this round

- **Our "human" bots are still too good.** They finish events that intermediate testers can't (Bike, Bay, Regatta, Subway).
  Hal and Mo measured each event's reaction-time curve by hand. That should be a standard `pt.py curve <event>` sweep
  over reaction times of 6 to 24 frames, with a flag when an average-human reaction scores about the same as idling.
- **Testers need an audio token.** Priya couldn't check music placement: add `wav:NAME:FRAMES` to the script language.
- **Testers need isolation.** All ten testers share one scratch folder, so one clobbered another's script. One tester's `pkill` may also have
  killed other testers' bot pools. Each tester should get their own scratch folder, and `pt` worker pools should be tagged.
- **Findings need an event-relative repro and a verify step,** as discussed after round 2.

## Quote wall

- "Give every event a forgiving first minute and it's a 7." (Gord)
- "I parallel parked on Brunswick, got a medal, and immediately sat on a stranger on Line 1." (Dana)
- "Nobody can steal your turn anymore, but half the time nobody gets to Spadina either." (Marcus)
- "It shows off like Epyx now. The two new kids just need tuning." (Priya)
- "Bay, the park and Queen St are worth a record attempt now. Parking and the subway are done the second you stop failing them." (Rob)
- "You taught every event to talk. Now make every point mean something." (Lena)
- "Big athletes, small subway. Draw the gag, don't caption it." (Kenji)
- "I beat GREEN P by 450 and the game yelled WE THE NORTH … and I still don't know how my score was counted." (Tasha)
- "Tallboy and Bay make the bar lean in now. TTC Surfing makes half of them lean in and the other half catch the germs." (Hal)
- "I needed a 4-frame robot to get off the subway at Union." (Mo)
