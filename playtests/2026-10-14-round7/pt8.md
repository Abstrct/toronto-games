# pt8 Tasha (completionist/UX researcher): Round 7

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7:**
- overall 5.5 → 7 → 7.5 → 8 → 8 → 8.5 → 8.5
- vs California Games 5 → 6.5 → 7 → 7.5 → 7.5 → 8 → 8
- Bike 6 → 6 → 6.5 → 6.5 → 6.5 → 6.5 → 6.5; Bay 5 → 6 → 6.5 → 7 → 6.5 → 7 → 7; Off-Leash 5 → 5 → 5 → 5.5 → 6 → 6 → 6.5; Tallboy 4 → 5 → 5.5 → 5.5 → 5.5 → 5.5 → 6; Regatta 3 → 4 → 5.5 → 5.5 → 5.5 → 7 → 6.5; Parking 4.5 → 6.5 → 7 → 7.5 → 8; Subway 4 → 6 → 6 → 6 → 6.5

## 1. My round-6 complaints
- **Fixed.** Off-Leash "75 FOR EVERY TENTH WALKED" (pt8r6-dog). The card now reads "WALK 50 A TENTH 100".
- **Fixed.** TTC GERMS 21 next to "20 GERMS". The PATIENT ZERO card shows GERMS 20, and `--verify` reports LEGS LEANED as GONE.
- **Fixed.** Tallboy hands-off "FINED 1/4" on 0. It now reads "NOT ONE HURDLE, NO POINTS".
- **Fixed.** Parking fractional TIME LEFT. The boxes show +237, +214 and +156 against a HUD of 23.7, 21.4 and 15.6.
- **Fixed.** Bike RIDE rate. The card reads "RIDE 1 PER 4 M": 343 m pays 85.
- **Better.** Final standings "PLAYER 20 0 0" (pt8r6-comp). There's now a two-character gap and the medal digits are coloured.
- **Better.** Regatta finish copy. "ALL 3! CROSS THE DOTTED LINE" is followed by "TO THE LINE: TAP ▶ ONCE", and the line now runs north-south. I finished on my first try.
- **Unchanged.** Sailing along the line over the pin (pt8r6-sail2). `--verify` says PRESENT (ADRIFT on 400). I didn't re-test it by hand.
- **Unchanged.** Bay: blind walking, with no lane changes, still makes the train with 8 spills and DECAF (955 and 931). The card still never mentions Y/PRESTO.
- **Not re-tested.** The crooked car scored ANGLE GOOD, and the smeared tilted car.

## 2. Regressions and new issues
- [minor ux] **pt8r7-sail2-245986**: Regatta.
  - Clipping mark 1 takes 2 s off the clock at once (86→84 within 10 f), with no popup.
  - "TOUCHED THE MARK! -2 S" appears about 220 f later, beside the ferry dock and 160 px from any mark. It reads as if the dock counts as a mark.
  - The coach box also stays on "TO MARK 1: TAP ▶ ONCE" for about 70 f after the HUD switches to TO MARK 2. The same thing happens at mark 3, with "TO MARK 3" showing under TO LINE!.
- [minor ux] **pt8r7-bay-337057**: Bay shows "LAST SIP! 1 MORE SPILL: DECAF" for about 2 s while the HUD already reads DECAF.
- Unfiled:
  - Regatta: a first-timer who follows the coach now gets **no style at all**: 1000+15×50 = 1750, bronze, against my 3290 in round 6. With nothing earned, the card prints no STYLE row, so it never hints that style exists.
  - Parking: the final card lumps STYLE 1057 together. It is ONE-MOVE 3×150 + TIME LEFT 607, but you have to add it up from the spot boxes yourself.
  - "Compete in some" starts with all 7 events ON. Playing one event takes 12 presses.

## 3. Copy: 8.5/10
**Clear on first read:**
- Parking: "GAS ▲: REAR BUMPER TO LINE", then "LET GO OF ▲: STOP ON THE LINE", then "HOLD DOWN+RIGHT: BACK IN", then "NOW! ROLL TO DOWN+LEFT", then "STRAIGHT! LET GO OF THE PAD", then "A: PARK IT!". All of it works at 15 f.
- Off-Leash: "DOG! PRESS B TO GET SET!" and "RED ! = B NOW FOR +200".
- Tallboy: "DEAD ON! B MID-AIR PAYS X3".
- TTC: "STANDING SURF CHAIN 1 +75".
- Regatta: "AGROUND! TAP ▶ TO BEAR OFF" then "PUSHED OFF! SAIL ON!".

**Funny:** "SORRY, HE'S A RESCUE!", "TACKLED! −150 (SO FRIENDLY)", "FACE-FIRST IN A BACKPACK!", and "COME IN AND GET LOST!" on the sponsor wall.

**Unclear:**
- The late "TOUCHED THE MARK!" at the dock.
- "LAST SIP! 1 MORE SPILL: DECAF" showing under DECAF.
- "3 HEARTS GONE. NO DOGS!" Is that a rule or a joke? It means your dog points are forfeit.

**Rewrite:** "3 HEARTS GONE: DOG POINTS FORFEIT".

## 4. Mastery
- **Regatta:** this is now where first-timer and expert are furthest apart. Following the coach scored 1750 (style 0), against a record of 3900 (2.2×). Tight rounding (6–10 px) is never coached. My style attempt didn't land a single TIGHT ROUNDING, so the skill is real but completely untaught.
- **Parking:** following the coach at 15 f scored 937 + 914 + 786 = 2637 (#4). Every box was "IT'LL DO." with CURB OK, and none had CURB KISS or DEAD CENTRE. The top end therefore has more than one thing to master, curb and centre on top of speed, and the coach teaches neither. That's good design.
- **Bay:** on-beat play scored 1199, the same as round 6. Round 6's double time reached 1882.

**Hidden tricks:** I didn't find any in about 70 commands. I didn't see anything the coach doesn't mention.

## 5. Report sections
1. **Who I am:** Tasha, a completionist UX researcher.
2. **Overall: 8.5/10.** Every card I checked adds up, and the coaches teach the basics. **vs California Games: 8/10.**
3. **Per event:** scores are at the top.
   - Parking is the best-coached event.
   - Regatta is clearer to finish but harsher on style.
   - Bike, TTC and Off-Leash I played only lightly.
4. **Top 3 loved:**
   - the Parking coach chain
   - the itemised spot boxes, where the TIME LEFT tenths now match the clock
   - the sponsor wall showing "TASHA" on the taken slot
5. **Problems:**
   - pt8r7-sail2-245986 [minor]
   - pt8r7-bay-337057 [minor]
   - Regatta's first-timer style of 0 with no hint [minor, unfiled]
   - pt8r6-sail2 still present [minor]
   - Bay lanes still optional [minor]
6. **What California Games did that this doesn't:** a trick that you discover yourself and that the score shows off.
7. **Make it more Toronto:**
   - "ACROSS THE LINE AT THE RCYC"
   - a "GREEN P OWES YOU $75" ticket tally
   - a PRESTO beep on the Bay gold dot
8. **Quote for the wall:** "The coach parked my car for me. The regatta made me find style on my own, and I never did."

## 6. Is it as good as California Games yet?
Close, and the menus, hand-off, records board and arithmetic are better than California Games. The biggest gap is still discovery. Regatta now hides its style, but it hides it so completely that a first-timer can't tell it's there. California Games showed you the trick in the attract demo and then let you work out how to do it.
