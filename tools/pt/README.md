# pt: the Toronto Games playtest harness

`tools/run.py` replays a button script from power-on and hands back PNGs.
`pt` turns that into a proper test rig:

| Need | pt gives you |
|---|---|
| Play without replaying from power-on | **Sessions**: each `do` resumes from a savestate, then saves again |
| Try two ideas from the same moment | **Checkpoints**: `save:x` / `load:x`, so branches cost nothing |
| Get to an event fast | **Cached scenes**: `goto:bay` loads the first frame of control in ~0.1 s |
| Know what's going on without guessing from pixels | **Telemetry**: scene (read from the 65816 call stack), score, fails, players, records, slowdown, audio level |
| Judge motion and feel | **Film**: contact sheet + GIF of N frames |
| Wait for "the right moment" | `until:scene=bay.results`, `until:ev_fail>=1` |
| Reproduce any bug | Every session is a replayable input log. `replay` proves it, and `bug` files the finding with a verified repro |
| Find exploits and balance problems | **Bots**: policies per event, run in parallel, with design flags |
| Find crashes and soft-locks | **Fuzz**: hours of random input in seconds, plus scene coverage |
| Catch visual regressions | **Golden**: frame hashes of every key scene |

Everything is deterministic. `ptcore` (C, built automatically into `build/pt/`)
keeps one snes9x core per process; `pt.py` drives it over a pipe at about 2000 fps.

## Playing (human or AI tester)

```bash
python3 tools/pt/pt.py scenes                        # goto targets
python3 tools/pt/pt.py new dana bay                  # session "dana", at Bay St, controls live
python3 tools/pt/pt.py do dana "s:start (pLEFT pRIGHT)*20 s:after"
python3 tools/pt/pt.py do dana "save:corner hUP w20 rUP film:dodge:12:5"
python3 tools/pt/pt.py do dana "load:corner hDOWN w20 rDOWN film:dodge2:12:5"
python3 tools/pt/pt.py do dana "until:scene=bay.results:4000 w30 s:card"
python3 tools/pt/pt.py state dana                    # full telemetry: players, records, call stack
python3 tools/pt/pt.py bug dana "Coffee meter empties in 10 s whatever you do" -s major -k design
```

Each `do` prints JSON: the state afterwards, what happened (`@1557 LAG 7 frame(s)
dropped`, `@3352 FAIL #1`, `@3352 score 0->2942`, scene changes, turn changes),
and the paths of any screenshots and films. Screenshots go to
`build/pt/sessions/<name>/shots/`.

### Script language
Space-separated tokens. It's a superset of `tools/run.py`'s.

| Token | Meaning |
|---|---|
| `wN` | run N frames with the held buttons |
| `hBTN` `rBTN` `rALL` | hold / release (`hA+RIGHT` for a chord) |
| `pBTN` | tap: 3 frames down, 3 up |
| `(…)*N`, `pA*5` | repeat |
| `s:NAME` | screenshot |
| `film:NAME:N:K` | N frames, one every K: `NAME_sheet.png` (with frame labels) + `NAME.gif` |
| `save:L` `load:L` | checkpoints (they keep the held buttons and the replay log) |
| `goto:T` | jump to a cached scene (`title menu signup records intro:<ev> <ev>`) |
| `until:COND[:MAX]` | step until COND (`scene=bay.play`, `scene!=title`, `ev_fail>=1`, `ev_score>500`, `a\|b`, `a&b`) |
| `state` | full telemetry in the output |
| `seed:N` | set the RNG |
| `mADDR:LEN` | WRAM hex dump |

Scenes: `title menu signup pick records transition standings final ceremony`, and
`<ev>.intro <ev>.countdown <ev>.play <ev>.results` for ev in `bike bay park cops sail`.

## Bots and balance

```bash
python3 tools/pt/pt.py balance -n 8          # every event x its default policies
python3 tools/pt/pt.py bot cops -p hold_b -p cops_jump -n 20
```

Policies live in `tools/pt/policies.py`. The no-skill ones (`idle`, `hold_a`,
`hold_b`, `mash_a`, `hold_up`, `hold_right`) are exploit detectors. Balance flags:
- a no-skill policy beats the default record or every skilled bot
- standing still scores
- no bot can score at all
- turns shorter than 20 s or longer than 120 s
- no variance between runs
- frames dropped to slowdown during play
- score scales that differ wildly across events

Results go to `build/pt/reports/`. To add a skilled bot, write a class with
`act(t, telemetry, rng) -> mask` and add it to `DEFAULTS`.

## Human curve

```bash
python3 tools/pt/pt.py curve bike            # skilled bot at 0..24 frames of reaction latency
```

The skilled bot's decisions land `latency ± latency/4` frames late, and 3% of them are missed. That's
roughly how a human hand differs from a bot with perfect RAM perception. A well-tuned event degrades
gracefully. At 15 frames (250 ms, an average adult) the run should finish at least half the time and clearly
beat standing still, and the expert should score no more than about 3× the average human.

Caveats:
- The bot plans with perfect information and only acts late. Give it a human-like look-ahead (react to what's
  on screen, plan from hazards that have been visible for a while), or the curve measures the bot's myopia, not the game.
- Rhythm and anticipation inputs, like Bay's beat taps, aren't reactions. A plain delay only shifts their phase, so
  rhythm events need their own human model (e.g. timing noise around the beat, plus latency only on hazards).
- Plug-ins choose the bot with `CURVE = {'<event>': 'policy'}`.

## Presentation lint

`pt.py lint [targets]` samples each scene and flags text in the top/bottom 8 scanlines (hidden by CRT overscan)
and sprites overlapping text glyphs. These are heuristics; a sprite meant to sit behind a card panel is fine.

## Findings that re-check themselves

`pt.py bug SESSION "title" -c "COND"` stores a repro relative to the session's last `goto` (when it has one),
and a condition that holds while the bug is present. `pt.py findings --verify [--file F]` replays every finding
on the current ROM. It reports PRESENT/GONE when there's a condition, REPLAYED when the replay reached the same scene, and DESYNC? when
an old power-on repro wandered off because the menus changed. Archived rounds live in `build/pt/findings_round*.jsonl`.

## Robustness

```bash
python3 tools/pt/pt.py fuzz -n 12 -f 36000     # 12 x 10 min of random input
python3 tools/pt/pt.py fuzz --start bike        # fuzz from a scene
python3 tools/pt/pt.py golden record            # after an intended visual change
python3 tools/pt/pt.py golden check             # exit 1 if any key scene changed or can't be reached
python3 tools/pt/pt.py replay SESSION --print   # determinism check + the full input script
```

The fuzzer flags:
- the NMI stopping
- the CPU running outside ROM
- an unrecognised call stack
- more than 10 s between screens
- 300 s stuck on a non-play screen
- 30 s of frozen picture under input

Each finding is saved under `build/pt/fuzz/` with its state, screenshot and repro.

## Running a playtest panel

Give each tester persona `tools/pt/PLAYTEST.md` plus a persona and a session
prefix. Testers file findings with `pt.py bug`, so `pt.py findings` is the
merged, severity-sorted list with screenshots and verified repros. Run
`balance` and `fuzz` alongside them so the panel spends its time on feel and
fun, not on rediscovering exploits a bot finds in ten seconds.
