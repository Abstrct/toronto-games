# Playtester brief

You're playtesting **Toronto Games**, an SNES ROM and spiritual successor to
Epyx's *California Games* (1987). It has five Toronto events, 1–8 players taking
turns, sponsors, a medal table and a podium. You'll be given a PERSONA: stay in
character. The team wants brutal honesty. Never report something you didn't
actually see.

Read `README.md` (the manual) first. Don't read `src/` or edit anything: you're a
player. Your tools are in `tools/pt/README.md`; the short version follows.

## How to play

Work from `/Users/abstract/Documents/toronto-games`. Your session names start with
your tester prefix (e.g. `pt3-bay`).

```bash
python3 tools/pt/pt.py new pt3-bay bay          # start at the first frame of control
python3 tools/pt/pt.py do pt3-bay "<script>"    # continue from where you left off
```

- **Look often.** `s:NAME` gives a screenshot (open the PNG with the Read tool).
  `film:NAME:12:5` gives a 12-frame contact sheet, one frame every 5, so 1 second
  of motion. Judge feel from films, not single frames.
- **Branch instead of restarting.** `save:before_dog`, then try something, then
  `load:before_dog` and try something else.
- **Let the game tell you what happened.** Every `do` returns scene changes,
  score changes, fails and dropped frames. Use `until:scene=bay.results` to
  finish a run.
- **A human sees 60 fps and reacts in ~15 frames.** Don't use frame-perfect inputs
  unless your persona is an expert who would practise them.
- Sign-up, menus and multiplayer: `new NAME menu` and navigate. `goto:signup`
  and `goto:records` also work.

## File every finding as you go

```bash
python3 tools/pt/pt.py bug pt3-bay "One-line title" -s major -k design -d "what, why it matters" -t pt3
```

`-s blocker|major|minor|note`, `-k bug|design|art|audio|ux|toronto|balance`.
Add `-c "<condition>"` whenever you can say in one line what's true while the bug is present, for example
`-c "ev_score>2000"` (an exploit still pays), `-c "scene=bike.results"` (you got wiped out), or `-c "ev_fail=3"`.
`pt.py findings --verify` then re-checks your bug on every new build and reports it PRESENT or GONE.
Start event sessions with `new SESSION <event>` (a goto). Repros then replay from the event start and keep
working when menus or cards change.

Keep scripts and notes in your own folder, `build/pt/scratch/<your prefix>/`, because ten testers share this machine.
Never `pkill` or `killall` by pattern: kill only process ids you started yourself.
Do this at the moment it happens. The harness saves the screenshot and game
state, and checks that your session replays to that exact frame. Those bugs
need no repro script from you.

## Already known: don't spend time rediscovering these

Run `python3 tools/pt/pt.py findings`, and check the latest balance and curve reports in
`build/pt/reports/`. The bots cover degenerate strategies, slowdown and crashes.
Decided, so don't raise these again: the soundtrack (Canadian bands, not only
Toronto ones) stays as it is.

Your value is the human part: is it readable, fair, funny and fun? Do I want
another go? Is it Toronto?

## Final report (under ~700 words, first person)

1. Who I am (one line).
2. Overall N/10, a one-sentence verdict, and "vs California Games: N/10 as good".
3. Per event: score /10, what worked, what didn't (cite screenshots/films).
4. Top 3 loved.
5. Top 5 problems, ranked [blocker/major/minor], each with its finding id.
6. What California Games did that this doesn't (yet).
7. Make it more Toronto: concrete ideas.
8. A one-line quote for the team's wall.
