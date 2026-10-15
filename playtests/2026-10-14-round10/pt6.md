# pt6 Gord (Leslieville, TTC since the Red Rockets, C64 California Games), round 10

**Round 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10:**
- overall 6 → 6 → 6 → – → 7 → 7.5 → 8 → 8 → 8.5 → 8.5
- vs California Games 5 → 5 → 5 → – → 6.5 → 7 → 7.5 → 7.5 → 8 → 8
- Bike 7 → 5 → 5 → – → 6 → 6.5 → 6.5 → 7.5 → 8 → 8; Bay 6 → 6 → 6 → – → 6 → 7.5 → 7 → 7.5 → 7.5 → 8.5; Off-Leash 5 → 6 → 6 → – → 7 → 7 → 7.5 → 7.5 → 8.5 → 8.5; Tallboy 4 → 5 → 5 → – → 7 → 6.5 → 7.5 → 7.5 → 7.5 → 7.5; Regatta 4 → 5 → 4 → – → 6 → 6 → 8 → 7 → 8 → 8 (opening only)
- Parking (R3→10) 6 → – → 5 → 7 → 7.5 → – → 8 → 8 (card only); Subway (R3→10) 5 → – → 7 → 7.5 → 7.5 → – → 7.5 → 7.5 (opening only)

## 1. Round-9 complaints
- **Bay lanes optional: better (nearly fixed).** Big dots only, no lane changes: 7 spills, DECAF, made the 5:42 with 2 s left, **800** (R9: 1084, 9 s). Dodging on the arrow at 15 f: 4 spills, 6 s left, **1515**. Bulldozing now costs time and points. You still make the train, though, and that's fine for a first-timer.
- **Style lumped on the Bike card (pt6r9-bike-21736032): fixed.** It now lists TTC TOKENS 100 / RAIL HOPS 330 / POTHOLE HOPS 80 / CLOSE+DRAFTS 100. Bay lists DODGES & CUTS and SLALOM.
- **Bay card row overlap (pt6r9-bay-21744125): fixed.** The grey sub-rows are spaced cleanly on both cards I saw.
- **Off-Leash "betting slip" card: fixed.** "B ON ANY ! = SAFE DODGE / LATER B = MORE PTS: RISKY!" is better than my own rewrite.
- **LIQUID COURAGE tell: better.** The gold BUZZ cell lights up, and then the whole of Kensington starts to wobble. That's a lovely drunk tell, but it's an 8-px cell at the top of the screen. I didn't land the trick.
- **Steer-round-car wobble: unchanged, and it now costs.** See pt6r10-bike-71362170.

## 2. Regressions and new issues
- [minor design] **pt6r10-bike-71362170:** CAR IN BIKE LANE. AGAIN. STEER ◀ ROUND IT. I did that and came back right, and a second car in the bike lane splatted me 3 s later with no new call (the old banner was still up as it scrolled in). It cost a heart and 2 tokens. (The `-c` I filed doesn't track the splat: ev_fail stays 0 on a Bike wipeout. Treat it as REPLAYED only.)
- [minor ux] **pt6r10-bike-71436506:** "RIDE 1500 + TIME 2040". 2040 is ride plus time (27 s = 540), so as written it adds up to 4150, not 2650.
- [minor ux] **pt6r10-bay2-71984794:** "WALK 1000 + TIME 1240" has the same problem. The same row is itemised properly (ON THE 5:42 1000 / 2 SEC AT 40 80) when there's no board line, so one row has two layouts.
- [note] Bay: in my one run each, late hands scored more. A lane change 24 f after the arrow gave 1755 (2 spills, SLALOM 25); at 15 f it gave 1515 (4 spills). That's one seed, so not filed.

## 3. Copy: 8.5/10
**Clear the first time:** "DOG! PRESS B TO GET SET!", "RED ! = B NOW FOR +400", "TACKLED! -1 ♥. SO FRIENDLY", "RAILS HOPPED! +80 / ANOTHER TRICK IN 2 S = X2", "TO MARK 1: TAP ▶ ONCE", "MARK 1 ROUNDED! WAIT...", "COP'S WATCHING! DON'T SIP!", "OOF! SPILLED! HE'S GAINING".
**Jokes that land:** "HE'S FRIENDLY!" (every owner in Bellwoods, ever), "BRUSHED PAST! SORRY!" (I asked for the SORRY last round), "KISSED THE 501!", "DELIVERED! SIGN HERE.", "SO LONG, SALMON!", "GRABBED THE STICKY POLE!", "ON YOUR LEFT! ER, RIGHT!".
**Unclear:** the "+ TIME" subtotal rows above. Parking's "NOW! IN THE PANEL: ▼+◀" is cryptic: in what panel? Bike's "CAR IN BIKE LANE. AGAIN." stays up so long it hides the next car.
**Rewrite:** "RIDE 1500 + TIME 2040" → "RIDE 1500 + TIME 540 = 2040".

## 4. Mastery
- Bay, played as three walkers: no lanes 800, dodging at 15 f 1515, late dodges 1755. Skill pulls away from bulldozing (about 2×), but the slow hand beating the quicker one is wrong.
- Off-Leash: a safe DODGE pays +300, and OLE! MATADOR! pays +600. That's a real top end.
- Curve at 0 f vs 15 f (bots): Bike 6035/3440, Bay 3284/1806, Off-Leash 13287/11687, Tallboy 6143/3262, Regatta 5005/3217, Parking 6801/3773, Subway 7632/3653. Off-Leash barely separates (1.1×). Everything else is 1.6–2.1×.
- More than one thing to master: yes in Bike (rails, potholes, chains, drafting), Off-Leash, and now Bay (dodges, cuts, slalom, double time, PRESTO).

**Hidden tricks, by hand:**
- **Off-Leash OLE! MATADOR! +600: 2 of 4.** I held toward the dog and pressed B 1–7 frames after the glow. B at 15 f after the glow got me TACKLED both times. So the glow is a confirmation, not a warning. You have to count the crouch.
- **Bay SLALOM +25: landed by accident** on the late-reaction walk. In the demo the tell is a yellow "‼" at the walkers' feet in RUSH HOUR.
- **Bike TTC TRANSFER: not landed** (1 try). The rails lit blue after a 501 passed, I crossed them holding ◀ and hopped, and got TRACK HOP! +50.
- **Tallboy LIQUID COURAGE: not landed** (the tell is above).
- **Regatta, Parking, Subway: not attempted** (out of budget).

## 5. Report
**Who:** a Leslieville lifer, Leafs and Jays, rode the Red Rockets.
**Overall 8.5/10:** Bay finally punishes the bulldozer, and the cards are honest except for one sum. vs CG: 8/10.
**Per event:** Bike 8 (delivered 2650, 3 rails hopped); Bay 8.5 (lanes matter, SORRY!); Off-Leash 8.5 (matador at +600, HE'S FRIENDLY!); Tallboy 7.5 (the wobble is great; the hurdles are hard to time from the chalk); Regatta 8 (the coach is crisp, but the harbour has no skyline or Island); Parking 8 and Subway 7.5 (I only saw the cards and the opening this round).
**Top 3 loved:** BRUSHED PAST! SORRY!; Kensington wobbling when you're tipsy; the Bike card naming TTC TOKENS.
**Top problems:** 1) the second unannounced bike-lane car [minor, pt6r10-bike-71362170]; 2) the "+ TIME" subtotal rows [minor, pt6r10-bike-71436506, pt6r10-bay2-71984794]; 3) the matador tell comes too late to react to [design]; 4) slower hands scoring more at Bay [note]; 5) Regatta's harbour reads as any harbour [toronto].
**CG had:** tricks you could see coming.
**More Toronto:** the CN Tower and Island ferry on the Regatta horizon; a SHORT-TURNED AT SHAW fail; a raccoon nicking the tennis ball.
**Wall quote:** "I bumped a suit on Bay and the game said SORRY for me. That's Toronto."

## 6. As good as California Games yet?
Not quite: 8/10. Bay is fixed. What's in the way now is that **two of the hidden tricks can't be reacted to**: the matador's glow comes after the moment you have to press, and TTC TRANSFER looks the same as a TRACK HOP until it pays. In CG you could see the half-pipe lip coming.
