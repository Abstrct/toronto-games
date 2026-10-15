# pt2 Marcus, C64 sleepover host (4P party), Round 10

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10:**
- overall 6 → 7 → 7.5 → – → 7.5 → 8 → 8.5 → 8.5 → 8.5 → 9
- vs California Games 5 → 7 → 7.5 → – → 7.5 → 7.5 → 8 → 8.5 → 8.5 → 9
- Bike 6 → 6 → 5.5 → – → 5.5 → 6 → 6.5 → 7 → 7.5 → 7.5 · Bay 4 → 5 → 6 → – → 6.5 → 7.5 → 7 → 7 → 6.5 → 7.5 · Off-Leash 6 → 5 → 6.5 → – → 7 → 7.5 → 8 → 8 → 7.5 → 7.5 · Tallboy 6.5 → 6.5 → 6.5 → – → 6 → 6.5 → 7 → 7 → 7 → 7.5 · Regatta 3 → 4 → 4 → – → 4.5 → 4.5 → 7 → 7.5 → 8 → 8 · Parking (R3 → 10) 6 → – → 8 → 8 → 8 → 8 → 8.5 → 8.5 · Subway 6 → – → 6 → 6 → 7.5 → 7.5 → 7 → 7.5

The main game was 4P Compete in all, played through to the podium. DAVE (Mr. Sub) just holds or mashes a button. MARCUS (Honest Ed's) is me at ~15 f. KEV (MuchMusic) reacts at ~11 f and JEN (Swiss Chalet) at ~20 f. Sign-up to podium took **27.3 min**. Final: KEV 33 (6 golds), MARCUS 21, JEN 9, DAVE 0. REMATCH reached the Bike card in **20 f**. I also played a 2P Compete in some (Parking + Subway) where both players used identical Subway hands. They tied at 3389, both got gold, and the medal table plus ticker ("1 OF 2 DONE +++ TOM LEADS") showed after event 1.

## 1. Round-9 complaints
- Bay rewards slower hands (22148547): **fixed**. In the party Kev 2042 > Marcus 1493 > Jen 1279. `curve bay` falls steadily: 3284 at 0 f, 1806 at 15 f, 1590 at 18 f.
- Squashed grey style rows (22135089): **fixed**. Every row is full height.
- Silent DOGS 2000 cap (22136486): **fixed**. DOGS paid 8900, 11350 and 6390, and TACKLES stays on the card when the board line shows.
- Regatta "LEFT/RIGHT: TURN": **fixed**. The card now says "TAP ◀ ▶ TURN  HOLD A HIKE".
- Subway "LEGS LEANED 5 OF 5" and the one-lump style: **fixed**. It now says "GOLD SURFS 0 OF 6" and itemises SURF CHAIN, GOLD SURF X3, DEAD CENTRE and GAGS RIDDEN.
- Tallboy one-lump style: **fixed**. It itemises TAKE-OFFS, LUCKY SIPS, SIP 'N' HOPS and CHAIN BONUS.
- "+ TOKENS+STYLE" double take: **unchanged**. CLOSE+DRAFTS, TIME+STYLE and DINGS+FINES are the same pattern.
- Regatta ROLL TACK: no longer on the card or in the manual, so I couldn't re-test it.
- Bike TTC TRANSFER by hand: **worse** for me. I landed 0 of 5 this round (6/6 in R9). See §4.

## 2. Regressions / new issues
- [minor ux] **pt2r10-card-72039737**: on a card with a board line, the ride, walk or race line squeezes to "RIDE 1500 + TIME 2020". The couch reads it as 1500 + 2020, but 2020 is the total. It happens on Bike, Bay, Off-Leash and Regatta. Jen's unsqueezed card ("DELIVERY 1500 / 26 SEC AT 20 520") is perfect.
- [minor ux] **pt2r10-card2-72077478**: the best runs get the worst breakdown. With a board line the style rows collapse to "OTHER STYLE 4100" (my record Off-Leash), "OTHER STYLE 183" (Bay) or "ALL THE REST 1150" (Parking).
- [minor balance] **pt2r10-card2-72205590**: on Off-Leash, a 15 f first try beats the 10200 record (`curve park` median 11687). It pays 3–4× any other event, so it carries the SCORE column on the final table.
- [note] Bay: all four of us finished **DECAF** with 4–7 spills, Kev at 11 f included. DOUBLE TIME is gone for everybody by the end.
- [note] Tallboy: Jen's card has a "SIP 'N' HOPS 11" count row that the cards with a board line drop.

## 3. Copy: 8.5/10
Clear the first time: "THIRD WIPEOUT. NO DELIVERY / PAID FOR THE RIDE ONLY", "NO HELM IN 10 S PAYS 0", "10 S WITHOUT DRIVING", "ON THE DOTS = FASTER WALK", and "B ON ANY ! = SAFE DODGE / LATER B = MORE PTS: RISKY!" (the best intro line in the game). Jokes that land: "PREFERABLY ALIVE.", "DON'T DENT A BMW.", "THE RCYC BAR IS OPEN!" and, once again, "#4! SO LONG, MARCUS!".
Unclear:
- "RIDE 1500 + TIME 2020".
- "OTHER STYLE" / "ALL THE REST".
- "TRACK HOP! +50" vs "RAILS HOPPED! +80". They look like the same hop to the couch.
- "LUCKY SIPS". Dave got 32 by holding B.
- "NOW! IN THE PANEL: ▼+◀" is cryptic until you've seen NOW!.

Rewrite: "RIDE 1500 + TIME 2020" → **"RIDE 1500 + 26 S = 2020"**.

## 4. Mastery
- Party: KEV 34481, MARCUS 29466, JEN 22905, DAVE 897. The faster hand won 6 of 7 golds. I took Regatta off him by 40 (3430 vs 3390: my TIGHT ROUNDS 670 beat his FERRY SURF 400).
- Curves from 0 f to 15 f to 24 f:
  - Tallboy 6143 / 3262 / 1787
  - Regatta 5005 / 3217 / 2630
  - Bay 3284 / 1806 / 1653
  - Off-Leash 13287 / 11687 / 7772, but flat from 0 to 9 f: the top end doesn't separate there.
- Skill shows in the score everywhere now, Bay included. Several events have more than one thing to master: Tallboy, Subway, Regatta and Bay each itemise four style sources.
- Honest caveat: these are latency hands. My own first-timer vs stylist pair this round was only the Bike rails.
- Hidden tricks by hand:
  - Bike TTC TRANSFER: **0/5**. Hopping at prompt+10 or +15 always gave "RAILS HOPPED! +80". Steering while hopping gave RAIL WOBBLE, or "TRACK HOP +50" and then a car. I didn't see the blue-rail tell in my films this time.
  - The other six events: not attempted by hand this round. Kev's hand earned BIKE SHAVE 400 in Parking without trying.

## 5. Report
1. Marcus, passing one pad round the couch.
2. 9/10. The party shell is done, and the one event where the better kid lost now ranks the kids correctly. vs CG 9/10.
3. Per event: see the scores above. Bay is fixed but everyone goes DECAF. Off-Leash's scale is out of line.
4. Loved: the identical Subway rides tied and both got gold; Bay's order finally matches the players' skill; the Tallboy and Subway cards itemised.
5. Top problems: 72039737, 72077478, 72205590, all minor. Nothing major.
6. CG put one number per row on the couch. The squeezed cards still make us do sums.
7. Toronto: tie the ticker to the board ("KEV HAS BUMPED MARCUS 4 TIMES TONIGHT").
8. Quote: "Finally, the fastest thumbs win Bay too."

## 6. As good as California Games yet?
Yes as a party machine, and just about as a sport. The biggest thing left in the way is reading the cards. Your best run should get the clearest card, and right now it gets the most squeezed one.
