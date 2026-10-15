# pt2 Marcus, C64 sleepover host (4P party), Round 9

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9:**
- overall 6 → 7 → 7.5 → – → 7.5 → 8 → 8.5 → 8.5 → 8.5
- vs California Games 5 → 7 → 7.5 → – → 7.5 → 7.5 → 8 → 8.5 → 8.5
- Bike 6 → 6 → 5.5 → – → 5.5 → 6 → 6.5 → 7 → 7.5 · Bay 4 → 5 → 6 → – → 6.5 → 7.5 → 7 → 7 → 6.5 · Off-Leash 6 → 5 → 6.5 → – → 7 → 7.5 → 8 → 8 → 7.5 · Tallboy 6.5 → 6.5 → 6.5 → – → 6 → 6.5 → 7 → 7 → 7 · Regatta 3 → 4 → 4 → – → 4.5 → 4.5 → 7 → 7.5 → 8 · Parking (R3 → 9) 6 → – → 8 → 8 → 8 → 8 → 8.5 · Subway 6 → – → 6 → 6 → 7.5 → 7.5 → 7

The game was 4P Compete in all, played through to the podium. DAVE (Mr. Sub) just holds or mashes a button. MARCUS (Honest Ed's) is me, reacting at ~15 f. KEV (MuchMusic) reacts at ~11 f and JEN (Swiss Chalet) at ~20 f. The hands were human-latency policies, plus my own eye-script for Off-Leash, since the old bot hands score 0 there on this build. Sign-up to podium took **~28 min** of machine time (R8 31). Final: KEV 33, MARCUS 19, JEN 11, DAVE 0 medals. REMATCH reached the Bike card **20 frames** later.

## 1. Round-8 complaints
- DAVEER 1 (11222791): **fixed**. Blank name, START, B back, then typing DAVE gives DAVE on the wall, the roster and every card.
- Regatta card names one style source (12249129): **fixed**. It now lists TIGHT ROUNDING / CLEAN TACKS / FERRY SURF / LINE HONOURS / ROLL TACKS, and every sum I checked adds up. That's basically my rewrite.
- Parking HUD −545 over "SCORE 0" (11984616): **not reproduced**. Dave's tow showed HUD 0 = card 0, but no run of mine went negative.
- No-skill bronzes: **fixed** this game. Dave scored 279, 0, 0, 224, 0, 0 and 200, and won no medals. 0 never medals ("–" on the board).
- Bay DOUBLE TIME trap: **unchanged** (pt2r9-bayace-22148547). My 15 f walk 2277 beat Kev's 11 f ace 2160 again. In Practice the same ace line scores *more* at 15 f (2366–2441) than at 11 f (1950–2244), and the DOUBLE TIME line at 15 f misses the train (417–441).
- Regatta "LEFT/RIGHT: TURN" while every other card says D-PAD: **unchanged**.
- Bike forfeit card dropping its second line: **fixed** ("FORFEIT STYLE 200" plus both reason lines).
- Style happens only in text: **better**. Bike rails now flash blue as you drift across the streetcar track. Parking's spot box itemises BIKE SHAVE. ROLL TACKS appears on the card by name.

## 2. Regressions / new issues
- [minor] pt2r9-sh-sail_expert-22135089: the grey style rows on the Bay and Regatta cards are squashed to half height, four rows in the space of two. The breakdown I begged for is there but unreadable from the couch.
- [minor] pt2r9-leash-bold-22136486: in Off-Leash, 9 dogs and 8 dogs (bold runs) both paid **+ DOGS 2000** exactly. It looks like a cap, and nothing says so. The TACKLES count row also disappears whenever the board line shows.
- [note] The Subway PATIENT ZERO card says Dave (holding ▶ the whole ride) "LEGS LEANED 5 OF 5", while the other cards say "OF 6". Style is one lump (Jen 2263 with 0 gold surfs; why?). Jen at 20 f beat me 3263 to 1534.
- [note] The Tallboy and Subway style lines are still single lumps, unlike Bay and Regatta.

## 3. Copy: 8.5/10
Clear the first time: "HOP THE RAILS: B!" → "RAILS HOPPED! +80 / ANOTHER TRICK IN 2 S = X2", "OOPS! NO DOG THERE", "HEARTS GONE: HALF THE DOGS / DUNDAS PAYS THEM ALL", "HANDS OFF THE HELM PAYS 0", "20 GERMS: STYLE IS VOID / ONLY LEGS YOU LEANED PAY", "NONSTOP +300: KEEP ROLLING", "SAFE: B ON ! = 100 PER DOG". The ticker "PLAYOFF RUN +++ EVENT 3 OF 7" is great couch copy. Jokes: "THE RCYC BAR IS OPEN!" lands. Kev got "SO LONG, MARCUS!" **four times** (Bike, Off-Leash, Tallboy, Parking). That got the biggest laugh of the night, and the second biggest groan.
Unclear: "+ TOKENS+STYLE 600" right under separately listed TOKENS and STYLE rows (a double take every time), "+ DOGS 2000", and "LEGS LEANED 5 OF 5".
Rewrite: "+ DOGS 2000" → **"DODGES 9 / SHAVES 3 / PATS X4 = DOGS 2000 (MAX)"**.

## 4. Mastery
- Off-Leash, played first-timer then stylist with my own 15 f eyes: safe B on the white ! scored **2760**, bold B on the red ! scored **4100** (1.49×).
- Regatta at 15 f: first-timer 2245–2715, stylist 3075–3395, record 3900.
- Tallboy: me 1940, Kev 4251 (2.2×).
- Bike: 2640 vs 3860.

Skill pulls away everywhere except Bay, where it goes backwards. The top end has more than one thing to master in Regatta (rounding, roll tacks, ferry surf, line honours) and Bike (chains, rails, transfers).

Hidden tricks by hand:
- **Bike TTC TRANSFER +100**: landed **6/6** on my first session once I knew it. Steer across the streetcar track and double-tap B, any first hop at 4–12 f and a gap of 10–14 f. The tell is the rails flashing blue under you.
- **Regatta ROLL TACK**: hiking through every tack credited **0** roll tacks to my first-timer hand, and only the stylist got ROLL TACKS 500. Round 8's "hold A through the tack" recipe no longer works reliably, and I couldn't find the tell.
- **Off-Leash MATADOR**: 0/8. My sweep was mistimed, so this isn't a verdict.
- **Bay SLALOM X2 +50, Tallboy LIQUID COURAGE +378, Parking BIKE SHAVE +200 (renamed from CLOSE SHAVE; good), Subway**: seen only in the demos (WATCH THAT MOVE!). I didn't try them by hand.

## 5. Report
1. I'm Marcus, the host passing one pad round the couch.
2. 8.5/10. The party shell is basically done: a 28-minute night, 0 can't medal, the button-masher goes home empty, rematch in a third of a second. vs CG 8.5/10.
3. Loved: "SO LONG, MARCUS!" ×4; the CN Tower ticker; the TTC TRANSFER, readable from the couch because the rails light up.
4. Top problems: 22148547 (Bay rewards slower hands), 22135089 (squashed style rows), 22136486 (silent DOGS cap).
5. CG's scores were readable at a glance. Here the cards are honest now, but cramped.
6. Toronto: tie the ticker to the board ("KEV HAS BUMPED MARCUS 4 TIMES TONIGHT").
7. Quote: "The cartridge kept score of the trash talk for us."

## 6. As good as California Games yet?
Yes as a party machine; nearly as a sport. The biggest thing in the way is Bay: the one event where the better player reliably loses. At a sleepover that's the event the kids stop picking.
