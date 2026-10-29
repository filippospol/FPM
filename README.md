# Fair Plus-Minus (FPM)

**A EuroLeague player impact metric.**

Fair Plus-Minus (FPM) estimates how much a player helps his team outscore the opponent per 100
possessions, once teammates and opposition are accounted for. One two-way number, built specifically
for the EuroLeague, and tuned to measure how good a player is *now*.

## Why "Fair"


FPM combines a regularized on/off rating (RAPM) anchored to an era-neutral, position-aware
box-score prior. The box score sets what to expect, the scoreboard says what actually happened, and
the blend is both stable and honest. Every parameter is chosen by out-of-sample testing, not by hand.

## Key elements

- **Offense and defense components**: O-FPM and D-FPM, split out.
- **Prior-informed RAPM**: single-season on/off anchored to a box-score prior, so one noisy season can't run away.
- **Luck adjustment**: impact is measured on *expected* points (shot quality), so shooting variance doesn't leak in.
- **Era-neutral**: every season from 2007-08 to today, each player judged against his own league.
- **Position-aware**: guard / wing / forward / big tiers, plus a box-score role tag (Star … Too Few Games).
- **Age curve**: an empirical aging curve pulls veterans off their primes.
- **Recency decay**: each season is weighed against the player's own recent form; the current season tracks this year's play as games accumulate.

## Reading the number

FPM is in **points per 100 possessions** relative to an average rotation player (0 is average). The
scale is set by the data: one point of FPM is worth about one point per 100 possessions of a lineup's
margin in the following season. A season runs from roughly −6 to +7; about +3 or better is a top-20
player, and the best reach +6 to +7.
