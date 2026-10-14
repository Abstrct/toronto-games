# pt3 Priya (retro YouTuber, 200k subs, made the 40-minute California Games retrospective): Round 6

**Round 1 → 2 → 3 → 4 → 5 → 6:**
- overall 6 → 7 → 7.5 → – → 7.5 → 8
- vs California Games 5 → 6.5 → 7 → – → 7 → 7.5
- Bike 6 → 6 → 7 → – → 7 → 7 · Bay 5 → 7 → 7 → – → 7.5 → 7.5 · Off-Leash 6 → 7 → 7 → – → 6.5 → 7 · Tallboy 6 → 6 → 7 → – → 7 → 7 · Regatta 3 → 6 → 6.5 → – → 6 → 7
- Parking (R3 → 4 → 5 → 6) 5 → – → 7 → 7.5 · Subway 6 → – → 7 → 7

## 1. My round-5 complaints
- **Off-Leash 0-clamp card: fixed.** It now prints the real sum: CROSSING 261 − TACKLES X150 450 = 0, then SCORES NEVER GO BELOW 0 and THIRD TACKLE ENDS THE WALK. It's honest. One B press gave 375 + DOGS 250 − 450 = 175.
- **Regatta 0-clamp card: fixed.** ADRIFT pays COURSE 176 (0 marks) or 394 (1 mark) under "250 A MARK + PART OF NEXT". No more fake zero.
- **Bike forfeit lines: fixed.** The forfeit sits on a grey line, "FORFEIT TIPS, STYLE 300", with "THIRD WIPEOUT. NO TIPS!" below it.
- **Bay coffee unexplained: better.** A popup says "NEXT BUMP SPILLS COFFEE: -40", and the card itemises "SPILLS 40 EACH 320". DECAF and GROOVE still aren't on the intro card.
- **Parking attract demo frozen: fixed.** It's now the best demo on the loop: PERFECT PARK 1337, then PERFECT X2 1722. The Regatta demo crosses the line too.
- **P2 card lockout: not retested** (I only played solo).

## 2. Regressions and new issues
- [minor ux] **pt3r6-pk-990182475.** Parking spot 1: "LET GO! STOP ON THE LINE" shows only ~15 frames before the bumper reaches the line. If I let go 250 ms after it appears, the car coasts to PAST IT!. If I let go after 500 ms, I hit the red car (STUCK!). The coach line goes LET GO → BACK IN → PAST IT in ~25 frames. In R5, the same reaction parked first time. **This is a regression.**
- [minor ux] **pt3r6-park-990293324.** "75 FOR EVERY TENTH WALKED" printed under CROSSING 261.
- [note ux] **pt3r6-bike-990302189.** The HUD and intro card say TOKENS, the failure card says TIPS.
- Not filed: on Bay, steady on-beat taps without lane changes ended at 8 spills, DECAF and 813, below bronze. A first-timer won't know the lane change is the whole game.

## 3. Copy: 7.5/10
- **Clear and funny:** DOG! PRESS B TO GET SET!, TACKLED -150 (HE'S FRIENDLY), OOPS! NO DOG THERE, MARK 2 IS UPWIND: ZIG-ZAG!, HELLO? TAP ◀ OR ▶ TO STEER!, HONK! HONK! GOOSED! -2 S, WINDED! STOP BUNNY-HOPPING, NICELY DONE., 20 GERMS: STYLE IS VOID, THE 5:42 LEFT WITHOUT YOU.
- **Unclear:**
  - The 75-a-tenth line next to 261.
  - TIPS vs TOKENS.
  - Tallboy says the same fact twice in two ways: the popup says YOU KEEP 3/4, then the card says FINED 1/4.
  - "PART OF NEXT" is vague.
  - The Parking coach flips three times before I can read it.
- **Rewrite:** add "EASE OFF ▲" a car-length before "LET GO! STOP ON THE LINE".

## 4. Mastery
- **Parking, twice.**
  - First-timer (250 ms reactions): overshot to PAST IT!/STUCK.
  - Careful reactions: NICELY DONE 939 (ONE-MOVE +150, TIME LEFT +239).
  - Demo: 1337, then 1722 with a PERFECT streak.
  
  Curb, angle, space, one-move, clock and streak are six separate things to master. That's California Games-style depth.
- **Bay:** my runs scored 793 and 813, with style 53–73, so rhythm alone barely pays. The bots pull away: rookie 1843, ace 3374, ear 3990. The skill is beat plus lanes, two things to master, but only the beat is obvious.
- **First-timer minutes:** Bike 162, Bay 793, Off-Leash 0 (175 with one B press), Tallboy 107, Regatta 176/394, TTC 120, Parking 939. Off-Leash is the only zero left, and only if you ignore the coach. That's a big step up from R5.

## 5. Report
**Overall 8/10.** The presentation is now honest: every card adds up on camera. **vs California Games: 7.5/10.**
- **Bike 7:** the card is fixed. The rider is still too tiny for a thumbnail, and steering into traffic in the warm-up cost me two hearts in seven seconds.
- **Bay 7.5:** the coffee is finally coached.
- **Off-Leash 7:** the "!" gives about 70 frames of warning, and CLOSE SHAVE +250 feels earned.
- **Tallboy 7:** the Kensington row is still the best thumbnail.
- **Regatta 7:** the coach is readable, and the ferry wake demo is great.
- **Parking 7.5:** the best demo in the loop, but there's the LET GO timing.
- **TTC 7:** still the funniest event.
- **Audio:** play music at rms 3500–5000, no clipping, side −13 to −18 dB. Tallboy's first 3 s is a quiet intro (rms 1684), then it reaches 4457. The result cards are silent. I couldn't check the podium swell.

**Loved:** the Parking demo; honest arithmetic everywhere; the Regatta coach ("TO MARK 1: TAP ▶ ONCE").

**Top problems:**
1. The Parking LET GO window (pt3r6-pk-990182475).
2. Bay never tells you lanes are the game.
3. The per-tenth line (pt3r6-park-990293324).
4. TIPS vs TOKENS (pt3r6-bike-990302189).
5. The tiny bike rider.

**What California Games did that this doesn't:** a result jingle, and a musical swell on the podium.

**More Toronto:** a streetcar bell on Bike's DELIVERED card; a "Mind the gap" chime on TTC's PATIENT ZERO.

**Quote:** "The cards stopped lying. Now make the first ten seconds of every event teach the one thing that matters."

## 6. Is it as good as California Games yet?
Nearly. The biggest thing in the way is that some events still hide their core skill: Bay's lanes, Off-Leash's B press and Parking's early lift. California Games showed you its trick in the first five seconds.
