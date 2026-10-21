# Fair Plus-Minus (FPM)

**A EuroLeague player impact metric.**

Fair Plus-Minus (FPM) estimates how much a player helps his team
outscore the opponent per 100 possessions, once teammates and opposition are
accounted for. One two-way number, built specifically for the EuroLeague.

## Why "Fair"

Two kinds of signal measure impact, and each is flawed on its own:

- On/off plus-minus reflects everything a player affects, but it's noisy and tangled up with his teammates.
- Box-score stats are stable, but miss everything that doesn't show up in the box score.

## Key elements

- **Offense and defense component.**
- **Descriptive and predictive versions.**
- **Luck adjustment.**
- **Age curve.**
- **Recency decay**.

## Reading the number

FPM is in **points per 100 possessions** relative to an average rotation player (0 is average).

- *Descriptive*: what actually happened with a player on the floor
- *Predictive*: the player's expected, repeatable true impact going forward.

In other words: descriptive FPM answers “who earned it,” predictive FPM answers “who to trust next,” and the gap between them is how much of it was luck.

### Status

FPM is in active development. The data pipeline (EuroLeague box scores, play-by-play, shot detail, exact-possession stints) is in place.
