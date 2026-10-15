# pt7 Kenji (SNES pixel art / SPC700 audio), round 10

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10:**
- overall 6 → 7 → 7.5 → 8 → 8.5 → 9 → 9 → 9 → 9 → 9
- vs California Games 5 → 6 → 7 → 7.5 → 8 → 8.5 → 8.5 → 9 → 9 → 9
- Bike 6 → 7 → 8 → 8.5 → 8.5 → 9 → 8.5 → 9 → 9 → 8.5 · Bay 6 → 7 → 7 → 7 → 8 → 8.5 → 9 → 9 → 9 → 9 · Off-Leash 6 → 6 → 7 → 7.5 → 7.5 → 8 → 8 → 8.5 → 8.5 → 9 · Tallboy 7 → 7 → 8 → 8.5 → 8.5 → 8.5 → 8.5 → 8.5 → 8.5 → 8.5 · Regatta 4 → 6 → 7 → 7 → 7.5 → 7 → 7 → 8 → 8.5 → 8.5
- Parking 6 → 7 → 7.5 → 8 → 8.5 → 8.5 → 8.5 → 8.5* · Subway 5 → 7 → 8 → 8.5 → 8.5 → 9 → 9 → 9*
- (*) I only checked the card and the audio; I didn't play it this round.

## 1. My round-9 complaints
- **Bay card: the sub-rows touched (pt7r9-bay-21820481): fixed.** PERFECT STEPS and DOUBLE TIME now sit on the same 12 px spacing as the WALK sub-rows.
- **White sidewalk sprite over the Bike card's right border (pt7r9-bike-21467193): unchanged.** It's still there on both the intro card and the WIPED OUT card (refiled as part of pt7r10-bike-71676888).
- **The Bike trick's tell lasted only 4 f: fixed.** As the 501 overtakes, a blue-white spark sits on its rear bogie for about 60 f, the in-lane rails glow cyan for about 45 f, and a crackle plays across the window.
- **"HANDS OFF THE HELM" copy: fixed, but see the new balance issue below.**
- **◀ ▶ glyphs against spelled-out directions: fixed.** Parking and Regatta now use the glyphs too.
- **"PUSHED OFF!" coming up without a tap, and the amber blinkers on the car in the bike lane:** I didn't retest these.

## 2. Regressions and new issues
- **[major art] pt7r10-bike-71361734.** HOP THE RAILS: B! and RAIL WOBBLE fire with no crossing rail drawn anywhere. I filmed 1059–1099 every 2 f and the road is plain asphalt under me. The title demo's RAILS HOPPED +80 is over plain road too. I'm hopping on a text box, not on something I can see. Maybe it was always like this and I missed it, but now that I've looked, there's nothing there to hop.
- **[minor balance] pt7r10-sail-71665051.** I tapped ◀ once at the gun and let go. The boat drifted round mark 1 by itself and the ADRIFT card paid 264.
- **[minor art] pt7r10-bike-71676888.** The sidewalk sprite still breaks the card border. The grey sub-row values are indented about 2 columns from their parent's value. I've since seen the same indent on the Bay and Tallboy cards, so it's probably deliberate; only the sprite matters.
- **Audio is healthy:**
  - Song AC RMS runs −16.4 to −18.7 dBFS, a 2.3 dB spread.
  - DC is within ±39 on every song.
  - Nothing clips. The peak is −0.9 dBFS while the 501 passes in the demo, which is hot but clean.
  - The Bike fail sting decays to silence.

## 3. Copy: 9/10
- **Clear and funny:**
  - "TACKLED! −1 ♥. SO FRIENDLY"
  - "JOGGER! ON YOUR LEFT! SPLASH"
  - "ON YOUR LEFT! ER, RIGHT!"
  - "COP CAUGHT YOU: FINED 1/4"
  - "15 S GETTING NO CLOSER / 250 A MARK + PART OF NEXT"
  - "B ON ANY ! = SAFE DODGE / LATER B = MORE PTS: RISKY!", which is the best intro-card pair in the game
  - "CRATES! TAP A AT THE CHALK"
- **Unclear:**
  - Parking's "NOW! IN THE PANEL: ▼+◀". On first read I went looking for a panel.
  - Bike's "HOP THE RAILS: B!" when there are no rails on screen.
- **Rewrite:** "NOW! IN THE PANEL: ▼+◀" → "COACH SAYS NOW!: ▼+◀".

## 4. Mastery
- **Bay, played lane-blind both times:**
  - First-timer on big dots at ±3 f: 894, MADE THE 5:42, 8 spills.
  - Expert DOUBLE TIME at ±1 f: 1072, 10 spills.
  - That's only 1.2×. The −40 spills swamp the timing skill, so reading lanes is the real top end, and I didn't have the budget to play it by hand.
- **Off-Leash has a real ladder:**
  - B on the white ! is a safe dodge.
  - B on the red ! pays +400.
  - B 4–12 f after the glow is CLOSE SHAVE +500. At 15 f you're tackled.
  - **The hidden trick, by hand:** hold the d-pad sideways in one direction while pressing B 8 f after the glow. It pays +600, and the demo chains it to +700. I landed it on try 7. The glow plus the tag jingle tell you *when*; nothing tells you *which way*. I found the direction by luck, the way CG's tricks were found.
  - So Off-Leash has three things to master: timing, direction and the chain.
- **Tallboy:** ON THE CHALK +36. The take-off grading still works.
- **Hidden tricks overall:**
  - **Off-Leash:** landed, 7 tries.
  - **Bike:** 0 of 4. The tell is long and lovely now. I hopped onto the 501's tracks inside the spark and got TRACK HOP +50 and then DRAFTING THE 501 X2–X4 (+120/+240), but never the demo's payoff. A second hop while drafting, or hopping back across, paid nothing. The tell says *now*; nothing says *what*.
  - **Bay:** in the demo, the nearest walker's red ! turns into a big yellow ! burst, with a yellow ring and arrow, about 15 f before SLALOM +50, and it escalates X2 → X3 → X4. 15 f is just inside my reaction time. I couldn't pick out a distinct SFX from the step taps. I didn't attempt it by hand.
  - **Other events:** not attempted.

## 5. Report
1. Kenji, pixels and SPC.
2. **9/10.** The tells now last long enough to read, and the cards are honest. vs CG **9**.
3. Per event:
   - **Bike 8.5:** the spark and cyan tell are great; the hop prompt has nothing on screen to hop.
   - **Bay 9:** the yellow-! tell reads well; spills dominate the score.
   - **Off-Leash 9:** the glow plus jingle is textbook, and the ladder is real.
   - **Tallboy 8.5:** gorgeous Kensington storefronts, and a hazard diamond about 60 f ahead. The chalk chevron is thin and faint.
   - **Regatta 8.5:** a clean ADRIFT card.
   - **Parking and TTC:** cards and audio only.
4. Loved:
   - the 501's bogie spark
   - Off-Leash's white glow
   - the yellow-! burst on Bay
5. Problems:
   - [major] pt7r10-bike-71361734
   - [minor] pt7r10-sail-71665051
   - [minor] pt7r10-bike-71676888
   - [minor] "IN THE PANEL" copy
   - [minor] Bike's tell doesn't hint at the input
6. CG's tricks were findable by fooling about. Off-Leash is now; Bike still isn't.
7. Toronto ideas:
   - draw the crossing tracks at the Bathurst/Spadina intersections, with a streetcar stop island
   - a Porter prop plane over the harbour
   - amber hazard blinkers on the car in the bike lane
8. Quote: "The spark says now. Make the rails say where."

## 6. As good as California Games?
About 9: yes on presentation and audio. The single biggest thing in the way is **Bike's readability**. The crossing rails you're told to hop aren't drawn, and the 501 trick has a perfect *when* tell but no *what*. Draw the crossing rails, and let the spark point at the move (for example, the rider's shadow flashing on the rail to land on).
