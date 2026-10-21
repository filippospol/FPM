# Fair Plus-Minus (FPM)

**A EuroLeague player impact metric.**

Fair Plus-Minus (FPM) estimates how much a player helps his team
outscore the opponent per 100 possessions, once teammates and opposition are
accounted for. One two-way number, built specifically for the EuroLeague.

## Why "Fusion"

FPM **fuses** a EuroLeague-fit box-score prior anchors each player, and
regularized on/off data (RAPM) pulls the estimate toward what actually happened on
the floor.

## Key elements

- **Offense and defense component.**
- **Descriptive and predictive versions.**
- **Luck adjustment.**
- **Age curve.**

## Reading the number

FPM is in **points per 100 possessions** relative to an average rotation player (0 is average).

- *Descriptive*: what actually happened with a player on the floor
- *Predictive*: the player's expected, repeatable true impact going forward.

In other words: descriptive FPM answers “who earned it,” predictive FPM answers “who to trust next,” and the gap between them is how much of it was luck.
