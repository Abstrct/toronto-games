# pt2 Marcus, C64 sleepover host (4P party), Round 7

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7:**
- overall 6 → 7 → 7.5 → – → 7.5 → 8 → 8.5
- vs California Games 5 → 7 → 7.5 → – → 7.5 → 7.5 → 8
- Bike 6 → 6 → 5.5 → – → 5.5 → 6 → 6.5 · Bay 4 → 5 → 6 → – → 6.5 → 7.5 → 7 · Off-Leash 6 → 5 → 6.5 → – → 7 → 7.5 → 8 · Tallboy 6.5 → 6.5 → 6.5 → – → 6 → 6.5 → 7 · Regatta 3 → 4 → 4 → – → 4.5 → 4.5 → 7 · Parking (R3 → 7) 6 → – → 8 → 8 → 8 · Subway 6 → – → 6 → 6 → 7.5

The game: 4P Compete in all. DAVE (Mr. Sub) holds A or mashes, MARCUS (Honest Ed's) is me reacting at ~15 f, KEV (MuchMusic) is quicker at ~10–12 f, JEN (Swiss Chalet) is a slower first-timer. Sign-up to podium: **27.5 min of machine time (R6: 42)**. Kev won, 27 pts to my 25; Jen 11, Dave 0. REMATCH had the Bike card up 2 frames later.

## 1. Round-6 complaints
- Regatta ADRIFT ends an active sailor's race (991169431): **fixed**. All three of us who steered finished, in 25–33 s each. By hand, I followed the coach and finished with 58 s left. To get ADRIFT I had to ignore the coach for 15 s, and even then the HUD warned me in red, "ADRIFT IN 4".
- Off-Leash bold lunge out of reach (991751108): **fixed**. The card now says "BOLD: B ON RED ! = 200-450", and the red ! stays up ~20 f. B 15 f after it pays NICE TIMING +200; B late pays CLOSE SHAVE +300.
- Tackle card maths (991475124): **better**. It now reads "- TACKLES X150 450" over "3 HEARTS GONE. NO DOGS!", but the fail card still has no TACKLES count row.
- Podium names only the champion (991491460): **fixed**. It now shows "2 MARCUS HONEST ED'S / 3 JEN SWISS CHALET".
- A quitter takes a medal: **better**. Calling it a day at 10 s now pays 69, less than any real ride.
- Idle player holds up Parking: **fixed** (towed after 14 s). DECAF does nothing: **better** (it now switches off DOUBLE TIME).

## 2. Regressions / new issues
- [minor] pt2r7-party-109277: after Bay, KEV, JEN and MARCUS were all on 6 PTS. The table ranked us 1, 1, 3, and the ticker said "AT THE TOP ON 6 PTS". Nothing on screen says golds break the tie, so I lost an argument I couldn't see.
- [minor] pt2r7-dog-418237: the first dog has a 2-frame hole. B at f893–894 or f897–904 pays +200, but B at f895–896 pays DODGE +100.
- [minor] pt2r7-quit-599566: Bike fail cards say "NOT PAID!" right under a score (69, 279). Two wiped-out riders then split the bronze by 1 point.
- [minor] pt2r7-copy-cops-673678: Tallboy's finish popup (RUN 970 + MADE SPADINA 300 + STYLE 1885 + NO SPILLS 200) and its result card (RUN HURDLES+ROAD 1270 + STYLE 2085) add up the same 3355 two different ways.
- Balance note: at 15 f, Bay's DOUBLE TIME is a trap. I scored 1705 (5 spills) and 1320 (9 spills) going for it, while Jen's plain walk with EXCUSE ME scored 1907.

## 3. Copy: 8.5/10
Clear: "RED ! = B NOW FOR +200", "LAST SIP! 1 MORE SPILL: DECAF", "TACK NOW! TAP ▶ 5 TIMES", "PUSHED OFF! SAIL ON!", the Parking instructor, "GO! D-PAD ▶". Jokes that land: "SORRY, HE'S A RESCUE!", "TACKLED! -150 (SO FRIENDLY)", "CARD DECLINED! GOLD DOTS ONLY", "THE RCYC BAR IS OPEN!".
These lines aren't clear: "ZIG-ZAG: WAIT FOR TACK NOW!" reads like an order to wait for something called TACK NOW. "MARK 1! NOW TAP ◀ 8 TIMES" means counting eight taps out loud. "NOT PAID!" sits over a score. "RUN HURDLES+ROAD" hides the Spadina bonus.
Rewrite: "THIRD WIPEOUT. NOT PAID!" → **"THIRD WIPEOUT: RIDE ONLY, NO TIPS"**.

## 4. Mastery
Off-Leash is the best of it. I walked it twice with the same 15 f hands. As a first-timer pressing B on the white ! I scored 3420 (1 tackle). Going for style with B on the red ! I scored 5400, with 0 tackles and #3 on the board. The bot ace scores 11112 with close shaves and pat chains: more than one thing to master. Subway (1240 → 3826) and Tallboy (1195 → 3266 → 3966) pull away too. Regatta is the weak spot: going by the coach I scored 1870–2200, and Kev reached 2655. The top end (TIGHT ROUNDING, CLEAN TACK, FERRY SURF) exists, but the coach never mentions it and the couch can't see it happen.
Hidden tricks: I didn't find one by playing. I tried hiking (A) during a tack and nothing showed up. Bay's PRESTO (Y on the gold dot) is in the manual but on no card. You only learn it from "CARD DECLINED!".

## 5. Report
1. I'm Marcus, the host passing one joystick round the couch.
2. 8.5/10. Every turn now has an ending and the party shell is tight. vs CG 8/10.
3. Loved: the podium naming all three; idle players gone in ~14 s; red-! timing I can actually hit.
4. Top problems: 109277, 599566, 673678, 418237 (all minor). Nothing major this round.
5. CG's tricks were spectacle the couch could watch. Here a lot of the style happens in numbers, not on screen, and Regatta is a 30-second tap-counting drill.
6. Toronto: a crowd on the podium chanting the champion's sponsor. A Regatta trick named "ISLAND FERRY WAKE".
7. Quote: "Four of us, seven events, one joystick, under half an hour. That's a sleepover."

## 6. As good as California Games yet?
Nearly. The biggest thing in the way is that the coach sails the Regatta for you. Everyone finishes within ~500 points of each other, and the kid who can actually sail has no visible way to show off.
