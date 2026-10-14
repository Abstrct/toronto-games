# pt5 Lena (16-bit sports designer): Round 8

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8:**
- overall 5 → 6 → 7 → 8 → 8 → 8 → 8 → 9
- vs California Games 4 → 5 → 6 → 7 → 7 → 7 → 8 → 8
- Bike 6 → 6 → 7 → 8 → 8 → 8 → 8 → 8 · Bay 6 → 7 → 8 → 8 → 7 → 8 → 7 → 7 · Off-Leash 5 → 6 → 7 → 8 → 8 → 8 → 8 → 9 · Tallboy 4 → 5 → 6 → 7 → 7 → 7 → 8 → 9 · Regatta 3 → 4 → 5 → 5 → 5 → 5 → 7 → 8
- Parking 4 → 7 → 8 → 8 → 8 → 8 · Subway 5 → 6 → 7 → 7 → 7 → 7

I played every event through on-screen perception: the "!" boxes, the beat box, the chalk, the coach text, the Bay arrow. Reactions were 12–15f with jitter.

## 1. My round-7 complaints
- **Fixed: Off-Leash hole at the red "!"** (park-999876280). I swept dog 1 frame by frame from the white "!": DODGE to 60f, NICE 61–114f with no gap, CLOSE SHAVE 115–129f, tackled from 130f.
- **Fixed: shave risk/reward.** CLOSE SHAVE now pays +400 against NICE's +200. Shaving on the lunge with 13f hands scored 5575 with no tackles, beating NICE play (5250). With 15f hands it scored 4175 with 3 tackles. Now the bold verb pays only if your hands are good enough, which is the right way round.
- **Fixed: CLEAN TACK rate** (sail-748755). A coach-obeyer tapping 6 times a second gets +100 ×2, and the README now says "six taps a second".
- **Fixed: Parking card.** It now reads "BACK IN: HOLD DOWN+RIGHT, / ROLL TO DOWN+LEFT AT NOW!", my rewrite word for word. A 936-point spot is headed GOOD PARK, no longer "IT'LL DO".
- **Better: LIQUID COURAGE / RACCOON RUN.** A formula line now shows the maths ("22 X3 CHAIN X2 CHALK"), but it still doesn't say *why* LIQUID COURAGE's base is 42.
- **Unchanged: Bay first-timer margin** (re-filed as **pt5r8-bayb-12444175**). Big dots only, no dodging: MADE THE 5:42 with 1 s left, 764.
- **Not seen:** two dogs' "!" overlapping, and the lingering X5 CHAIN banner.

## 2. Regressions / new
- [minor] **pt5r8-sail-12104384**: Regatta finish card. "LINE HONOURS 300" sits in the sum column above "COURSE 2005 / + STYLE 500 = 2505", so it reads like 2805. The 300 is inside STYLE, and the other 200 (two CLEAN TACKs) isn't named.
- [note] **pt5r8-park-12286497**: the OLE! MATADOR window is 6f on dog 1 while walking (8f standing still), but only 2f, 2f and 1f on later dogs, with no tell.
- [note] **pt5r8-sub-12460825**: on a clean TTC ride, "LEGS LEANED 6" has no denominator and reads like a fault count.
- No regressions found. The wipeout card now reads "THIRD WIPEOUT. NO DELIVERY. / PAID FOR THE RIDE ONLY." and agrees with the sum. Off-Leash callouts now have bordered panels.

## 3. Copy: 8/10
- **Clear:** "BOLD: RED ! 200, LATE 400+", "RED ! = B NOW FOR +200", "CHALK! B MID-AIR PAYS X2", "TIPSY! THE COP'S GAINING", "SLOSHED! 0 PTS, CHAIN OVER", "NO WAY ROUND? A: EXCUSE ME!", "EXCUSE ME? ...NOBODY THERE", "GOOD PARK! NEXT: HUG CURB", "CAR IN BIKE LANE. AGAIN / STEER ◀ ROUND IT", "ANOTHER TRICK IN 2 S = X2" (much better than "NEW TRICK IN 2 S").
- **Jokes that land:** "PHOTOBOMBED A TOURIST! SORRY!", "ON YOUR LEFT! ER, RIGHT!", "SANDWICH BOARD! SORRY!", "CLOSE SHAVE! SHE DIDN'T BLINK", "TACKLED! -150. SO FRIENDLY".
- **Unclear:** the Regatta card (above). "LEGS LEANED 6". The Parking coach says "HOLD DOWN+RIGHT: BACK IN", then "HOLD DOWN+RIGHT: GET READY", so the go comes before the get-ready.
- **Rewrite:** on the Regatta card, put "INCL. LINE HONOURS 300" indented under "+ STYLE".

## 4. Mastery
| Event | First-timer | Smart | Expert |
|---|---|---|---|
| Off-Leash (record 8500) | B on white "!": 3535 | NICE: 5250 | shave 13f: 5575; shave + MATADOR: 6050 |
| Tallboy (6300) | dry: 2103 | sip every hop: 3750 (sloshed ~10×) | ride the buzz, rest 5 hops after TIPSY: **5707** |
| Regatta (3900) | coach-obeyer: 2505 | | + ROLL TACK (+150 over CLEAN per tack) + tight roundings |

Yes, skill now pulls away: Tallboy 2.7×, Off-Leash 1.7×, Bike curve 3315 → 9085. The top end has more than one thing to master:
- Tallboy: the chalk, plus the buzz meter.
- Off-Leash: the timing ladder, plus each breed's crouch count, plus MATADOR.
- Regatta: the roll tack is a real rhythm verb now.

## 5. Hidden tricks (I watched all seven title demos, then reproduced what I could)
- **Off-Leash, OLE! MATADOR +550:** B late with the d-pad held *toward* the dog. Found by sweeping chords after the demo.
- **Regatta, ROLL TACK +250:** hold A, let go 15–26f after your first turn tap; a 3f tap or a long hold misses. Found by sweep.
- **Bike, TTC TRANSFER +120:** one hop across both rails of a track while steering across. It fires with no 501 present.
- **Tallboy, LIQUID COURAGE:** a SIP 'N' HOP with the BUZZ meter near the red. The base climbs 20 → 42 (+630 at X5). Found in my own runs, then confirmed in the demo.
- **Parking, CLOSE SHAVE:** start backing in during the last ~10f of "WAIT! LET THE BIKE GO BY".
- **Bay, SLALOM X2** (back-to-back dodges in opposite lanes) and **TTC, LOOK MA, NO HANDS! +100** (at doors open after a GOLD SURF): seen in the demos only. I couldn't hold gold by tapping.

## 6. PLAYTEST.md report
1. Lena: I shipped two SNES sports games.
2. **9/10.** The bold verbs finally pay. vs CG: 8/10.
3. Bike 8: BMX; the transfer is a nice second hop, and 15f prompt-following delivered 2980. Bay 7: Summer Games sprint; no slack for a first-timer. Off-Leash 9: footbag ladder, done right. Tallboy 9: roller skating, with buzz as a resource. Regatta 8: surfing; the roll tack has feel. Parking 8: the follower parks all three for 2474. TTC 7: half-pipe; holding is safe, and I never found the gold.
4. Loved: the CLOSE SHAVE maths, LIQUID COURAGE, the ROLL TACK's "hike, then let her come through".
5. Problems: sail-12104384 [minor], bayb-12444175 [minor], park-12286497 [note], sub-12460825 [note], tricks without tells [design].
6. CG's tricks were readable in the animation. Here, MATADOR and ROLL TACK have no visual cue, and only the demo tells you they exist.
7. A raccoon in Off-Leash going for your tennis ball. A Leslieville bandana dog. Ward's Island ferry horn on the roll tack.
8. "Make the hidden trick visible a frame before you need it, and it's California Games."

## 7. Is it as good as California Games yet?
Nearly. The biggest thing in the way is **readable tells for the top-end tricks**. CG showed you the half-pipe lip and the footbag's apex. Here, MATADOR (1–2f on most dogs) and ROLL TACK (let go in a 12f window timed off your own taps) live in frame data. Give each a sprite or sound tell, and give Bay a few seconds of slack.
