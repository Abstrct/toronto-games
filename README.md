# Toronto Games

A Super Nintendo game in the spirit of *California Games*: seven events
across Toronto, 1–8 players taking turns, each with a name and a classic
Toronto sponsor. Written in 65816 assembly; all art and music are generated
by the Python tools in `tools/`.

**ROM:** `toronto_games.sfc` (LoROM, 512 KB, battery SRAM for the records).
It runs in any SNES emulator (Snes9x, bsnes, Mesen) or on a flash cart.
`make run` builds and opens a small macOS player app with the ROM inside.

## The events

Every event opens with a card that shows where you are, what to do, your
controls and the Toronto Record. Read it, then press A.

| # | Event | Where | Controls | Goal |
|---|-------|-------|----------|------|
| 1 | Bike Courier | Queen St W, top-down | D-pad steer · A pedal (hold, or tap) · B hop · ▼ brake | Get the package to Spadina in time, preferably alive. The first 20 seconds are a gentle warm-up, and nobody is punished for riding one line in the first 30. Then car doors, potholes, a car stopped in the bike lane (again), wrong-way cyclists and the 501 close in, but never two at once in the bike lane. Style: hop the streetcar rails (TRACK HOP), hop a pothole (POTHOLE HOP), slip out of the way of a car or the 501 at the last moment (CLOSE CALL), or tuck in behind the 501 (DRAFTING). Chain different moves for X2–X8. Crossing the rails without a hop gets you a RAIL WOBBLE. Tokens pay 50 each, and tokens and style pay only on delivery; a failed card shows what you forfeited. Three wipeouts and you're out, and stopping for 8 seconds gets you fired. |
| 2 | Bay St Power Walk | Bay at King, side view | ◀ ▶ alternately on the big dots (the beat); small dots too = DOUBLE TIME · ▲ ▼ (or X / B) change lane · A "EXCUSE ME!" · Y on a gold dot: PRESTO | Make the 5:42 GO train at Union. Step on the big dots and you'll make it; step on the small dots too for DOUBLE TIME, a longer stride and double style. WALK pays 1000 plus 40 a second to spare. GOOD steps build the POWER WALK combo (x2–x8) and PERFECT ones score it, more if DEAD ON. A red "!" and a red ring mark whoever is in your lane: change lanes, and cut it fine for a CLOSE SHAVE. Every bump after the first spills coffee (−40); eight spills and it's DECAF. Carts and sandwich boards won't budge, and mashing trips you. |
| 3 | Off-Leash Alert | Trinity Bellwoods, 3/4 view | D-pad walk · B when a "!" shows: sidestep (hold ◀ or ▶ to pick a side) · A throw a tennis ball | Walk from the Queen St gate to the Dundas gate. A dog with a "!" is about to charge. Press B as soon as the "!" shows to get set: you sidestep safely as he lunges (DODGE +50). Or wait and press B as he lunges: NICE TIMING +150, CLOSE SHAVE +250, and CLOSE SHAVEs in a row pay more, up to +550. Then walk up and pat him (DODGE 'N' PAT). Every 3 dogs in a row wins back a heart; three tackles and you're done. A tackle costs 150. Run out of time or get tackled out and you're paid 75 for every tenth of the walk. Pressing B with no dog about leaves you off balance, more so each time. |
| 4 | Tallboy Trot | Kensington Market, side-scroller | Yellow chalk: tap A hop · red chalk: hold A big jump · B sip | The bike cop saw that tallboy: run to Spadina. The first 30 seconds are a warm-up. Yellow chalk: tap A to hop; red chalk: hold A for the big jump. Clip a hurdle and you can still press A to scramble over it. A spill costs ground on the cop, not points. B sips, and sips score only while the cop can't see you. A sip in mid-air over a hurdle is a SIP 'N' HOP: 8 points (16 over a green bin or a raccoon) × your chain (X1–X5) × the chalk (X2 if you took off on it, X3 DEAD ON). A dry hop on the chalk keeps the chain; one off it ends it. Each sip fills the BUZZ meter. In the red you're TIPSY: the cop closes in to watch, and a sip is SLOSHED (no points, chain over). Get busted and the cop fines you a quarter of your score. |
| 5 | Harbour Regatta | Toronto Harbour, top-down | Tap ◀ ▶ turn one notch (hold to keep turning) · A hike out in gusts | Round marks 1, 2 and 3 in order, then cross the line. The wind blows from the top of the screen and you can't sail into it, so zig-zag. A mark counts as rounded the moment you sail inside its dotted ring. The yellow arrow marks the next mark; the diamonds ahead of the bow turn green on the course to steer, and the coach tells you how many taps to make. Each bump (a buoy, a goose, the shore) costs 2 seconds of clock. A finish pays 1000 + 25 a second left + style: TIGHT ROUNDING (the closer the better, X2/X3 in a row), CLEAN TACK +100 (up to 3), FERRY SURF +200/+200 (she leaves Ward's as you round mark 3) and LINE HONOURS +300 for no bumps. No finish pays 250 a mark rounded plus part of the next leg. Ten seconds getting no closer ends the race (ADRIFT); so does never touching ◀ ▶, which scores 0. |
| 6 | Parallel Parking | The Annex, from above | ▲ gas · ▼ reverse · ◀ ▶ steer · A park it | Three spots on Brunswick (lengths vary): roomy, snug, then tight with 25 s, the last two with a cyclist to wait for. Drive up until your rear bumper is on the yellow line, back in with a d-pad roll (▼+▶, then ▼+◀), and press A once you've stopped. The coach line talks you through it, including how to get unstuck. The CURB, ANGLE and SPACE lamps show what you'd score now; the spot box itemises every point and the score moves by its SPOT line. Style: ONE-MOVE (on the line, one clean reverse, nothing touched), TIME LEFT (+10 a second), CURB KISS, DEAD CENTRE and PERFECT streaks. Every hit says what it costs (it's a BMW). Half in pays +150 (+50 if way off) and a $75 ticket. Out of the spot when time runs out, or 10 seconds without driving, and you're towed. Calling it a day keeps the spots you finished. |
| 7 | TTC Surfing | Line 1, Bloor-Yonge to Union | D-pad lean | Ride Line 1 to Union hands-free. Every lurch is announced: beeps, a squeal or the brake hiss, and a hollow arrow blinks by the ring: get ready (leaning early is safe, just weaker). When it goes solid, press the D-pad the way it points to keep the dot in the ring. Leave the ring and you grab something: a germ costs 40. Past TMU (it was Dundas) no two rides are alike: ride out the signal-problems E-brake and a swinging backpack for +100 each. A stop-to-stop leg with no grab is a STANDING SURF (75 × the chain); keep the dot gold from the STAND CLEAR chime to the next stop for a GOLD SURF (×3); dead centre during a push scores every frame. Twenty germs and you're PATIENT ZERO: the ride pays 40 a leg you leaned on, no style. |

Controls change as the events are tuned, so the in-game card is always the
final word.

### Pause

Press **START** during any event to pause. The music stops and the scene
goes to mosaic behind a menu:
- **PLAY ON** (or START again) carries on from the same frame.
- **CALL IT A DAY** ends your turn at once, scored as a failed run. In a
  multiplayer game it ends only your turn; everyone else still plays.

## Playing

The main menu has four options:
- **Compete in all events**: all seven, in order.
- **Compete in some**: tick the events you want on the picker.
- **Practice one event**: pick one and play it as often as you like.
- **Toronto Records**: the records board.

**Sign-up.** Enter each competitor's name on the letter grid (A types, B
deletes, START finishes; a blank name becomes PLAYER n). Then pick a sponsor:
Honest Ed's, Sam the Record Man, Eaton's, Pizza Pizza, Swiss Chalet, Mr. Sub,
Canadian Tire, Roots, Laura Secord, Shopsy's, Steam Whistle or MuchMusic.
Each sponsor can be picked by only one player, and your athlete wears their
colours. B on the sponsor wall goes back to your name with the name kept.

**Competitors.** The roster screen lists everyone signed up, with three actions:
- **ADD PLAYER**: up to 8 players.
- **REMOVE**: takes off the last player, after a NO / YES check. The cursor
  starts on NO, so mashing A can't delete anyone.
- **START!**: on to the events.

B leaves for the main menu, but first asks whether you want to lose the
players you've signed up. On the event picker, B goes back to the roster
with everyone still signed up.

**Turns.** Players take turns at each event. An UP NOW card names whose
turn it is and says HAND THE PAD TO the next player, so a mashed button
can't start their turn. In Practice, B on the event card goes back to the
event list.

**Scores.** The result card shows how the score adds up. A score never goes
below 0: if the penalties are bigger than the rest, the card still shows the
full sum and says SCORES NEVER GO BELOW 0. A failed Bike run forfeits its
tips and style, and the card shows them in grey.

**Medals.** Equal scores share a place and its medal. A score of 0 never
wins a medal.
- **Multiplayer:** each event awards gold, silver and bronze (5, 3 and 1
  medal points). A medal table with a CN Tower ticker follows each event. After
  the last event comes the podium at Nathan Phillips Square, then the final
  table.
- **Solo:** you race the Toronto Record. Matching it wins gold, two thirds of
  it wins silver and one third wins bronze. The event card shows all three
  marks.

**After an event.**
- **Practice:** choose **RETRY** (same event, same player), **OTHER EVENT**
  (the picker opens on the next event) or **MENU**.
- **Competition:** after the final table (the cursor starts on it), choose **REMATCH** (the same
  events with the same crew), **1 EVENT** (one more event, as a one-event
  competition; B goes back to the final table) or **TITLE**.

**The Toronto board.** Each event keeps a top 5, saved to the cartridge's
battery RAM. The first time the cart boots, the board is filled with ghost
rivals: COURIER and SALMON on Queen St, SUITGUY and DECAF on Bay, GREEN P
and TOWTRUCK in the Annex, and so on.
- A score that makes the board bumps a ghost off it: "#4 ON THE TORONTO
  BOARD! SO LONG, TOWTRUCK!".
- A new #1 gets the full moment: "NEW TORONTO RECORD! +450 OVER GREEN P /
  WE THE NORTH!".

On the board screen, ◀ ▶ turn the pages, one event per page.

**Title screen.** Leave the title alone and it plays an attract loop: a
HOW TO PLAY panel, the records, then a real gameplay demo of the next event
in the rotation. The demos are recorded play, showing off the named tricks.
Any button ends a demo and brings you back to the title.

## Music

Most tracks are 8-bit loops after Canadian bands: the chords, tempo and
groove follow the original, and the melodies wander just far enough off.
The two newest tracks are originals.

To hear them all, press **SELECT** on the title screen to open the sound test:
- **MUSIC**: the 11 songs, each with the band it's after.
- **SOUND**: the 18 sound effects.

▲ ▼ pick a line, ◀ ▶ browse (each one plays as you land on it), A plays the
selection again, SELECT skips to the next song, B closes the panel and
START goes to the main menu.

| # | Track | After | Plays during |
|---|-------|-------|--------------|
| 1 | KC Incidental | Broken Social Scene, "KC Accidental" | title |
| 2 | Bobcaygeese | The Tragically Hip, "Bobcaygeon" | menus, sign-up, records |
| 3 | Gold Guns Gulls | Metric, "Gold Guns Girls" | Bike Courier |
| 4 | Ahead by a Centimetre | The Tragically Hip, "Ahead by a Century" | event standings, final table |
| 5 | Whelp, I'm Alive | Metric, "Help I'm Alive" | Bay St Power Walk |
| 6 | Hay, Officer | Mother Mother, "Hayloft" | Tallboy Trot |
| 7 | Brother Downwind | Sam Roberts, "Brother Down" | Harbour Regatta |
| 8 | If I Had a Million Collars | Barenaked Ladies, "If I Had $1000000" | Off-Leash Alert |
| 9 | Podium Reprise | the title theme behind a fanfare | podium at Nathan Phillips Square |
| 10 | Green P Shuffle | original: an F major swing | Parallel Parking |
| 11 | Please Stand Clear | original: E minor at 150 | TTC Surfing |

Every event has its own song. The standings song carries straight on into
the final table, and the podium brings the title theme back. The mix is
stereo: the lead is slightly left and the harmony slightly right, with a
short SPC echo on both.

Songs are written in `tools/songs.py` (one 16th note per token, NES-style
lead / harmony / triangle bass / drums) and compiled by `tools/audio.py`.

## Building

Needs `cc65` (ca65/ld65) and Python 3 with Pillow.

```bash
make            # the ROM
make run        # the ROM in the macOS player app (build/Toronto Games.app)
```

`make` does the following:
- regenerates the art and audio (`tools/build.py` → `build/*.bin`)
- checks the register-width bookkeeping (`tools/modecheck.py`)
- assembles `src/*.s` and links them with `snes.cfg`
- patches the header checksum

## Layout

- `src/boot.s`: reset, NMI (OAM, CGRAM, text and queued VRAM DMA), joypads, the pause menu
- `src/ppu.s`, `src/text.s`, `src/math.s`: video, text and maths helpers
- `src/audio.s`: the SPC700 register-writer driver; the sequencer and sound effects run on the 65816
- `src/game.s`: the game director, scoring, medals, SRAM records, the attract demos and shared helpers
- `src/title.s`: the title, its attract panels and the sound test
- `src/menu.s`, `src/register.s`: the main menu, event picker and sign-up
- `src/cards.s`, `src/ceremony.s`: the event cards, results, standings, records board and podium
- `src/ev_*.s`: the seven events
- `src/demo.s`, `src/demo_data.inc`: the recorded attract-demo joypad streams
- `tools/art_*.py`: the pixel art for each screen
- `tools/audio.py`, `tools/songs.py`: samples and songs
- `tools/font.py`: the text tiles

## Dev tools

- `python3 tools/run.py "<script>"` runs the ROM headless (the snes9x
  libretro core in `build/emu`) with a button script, and saves screenshots
  to `build/shots/`. For example, `"w200 pSTART w40 s:menu"`. Tokens:
  - `wN`: wait N frames
  - `pBTN`: tap a button
  - `hBTN` / `rBTN`: hold / release a button
  - `s:name`: screenshot
  - `c`: CPU registers
  - `v:file` / `V`: audio capture
- `python3 tools/pt/pt.py` is the playtest harness. It gives you persistent,
  branchable play sessions with game telemetry (scene, score, fails,
  slowdown) and films. It also runs bots, balance flags, the reaction-time
  curve, fuzzing, golden-scene checks, and bug filing with verified repros.
  See `tools/pt/README.md`. `make qa` runs the automated checks: golden
  scenes, fuzzing, bot balance, presentation lint and human reaction curves.
- `python3 tools/pt/copylint.py` lints every player-facing string: line
  length, stale text, jargon and reused gags.
- `python3 tools/gallery.py` captures showcase screenshots into `build/gallery/`.
- `python3 tools/jukebox.py [seconds] [song ...]` records songs from the
  ROM's sound test into `build/music/NN.wav`. `JUKEBOX=--gram` adds a
  notegram PNG.
- `python3 tools/modecheck.py` flags branches into code assembled for the
  wrong accumulator/index width. `make` runs it too.
