# FPM: Design Notes, Sources and Limitations

How the metric came together, what it borrows and from whom, and where it falls short.

## How the model came together

The starting point is a complaint about PIR. The EuroLeague's official efficiency number is a counting
stat in a suit: it adds the good, subtracts the bad, and never minds that a possession used isn't worth
the same as a possession saved, or that the weights were never really justified. A high-volume scorer on
a weak team can out-PIR a player who quietly makes his team much better. FPM is meant to answer the
question PIR dodges: when a player is on the floor, does his team outscore the opponent by more?

The honest tool for that is plus-minus, and specifically RAPM, which is adjusted plus-minus run through
a ridge regression so a player is separated from the teammates and opponents he shares the floor with.
That thread starts with Rosenbaum's statistical plus-minus and Sill's ridge-RAPM paper. The catch is
that raw RAPM over a single EuroLeague season is barely usable. The season is short, rotations are
tight, the same five play together constantly, and the regression can't cleanly tell them apart. One
season of on/off is mostly noise.

The fix is a solved problem in the NBA, and it keeps showing up under different names. EPM, LEBRON,
PIPM, BPM, DARKO and RAPTOR all do the same two things under the branding: start from a box-score prior
(a model of what a player's production should be worth), then let the regularized on/off pull that prior
around. The box score is steady but blind; the scoreboard sees everything but lies; put one on top of
the other and you get something that's both. That is the skeleton of FPM: a prior-informed RAPM, offense
and defense split out, fit on the actual score, with single-season offensive on/off pulled back
toward the prior so one hot month can't run away with the leaderboard.

The rest is a matter of doing it for the EuroLeague instead of importing NBA numbers, which matters more
than it sounds. The WINSCORE authors showed that box-score weights fit on the NBA don't transfer to
Europe, which is reason enough to fit everything from scratch. Earlier European work points at both the
approach and the pitfalls: Olivo's thesis (elastic-net RAPM on these very seasons), Dewandeler's
RAPM-EU, German Basketball Analytics' xEuPM, Clutch Data's possession-weighted RAPM, and the Grassetti
papers warning that EuroLeague lineup synergies run larger than the NBA's, which makes individual effects
harder to pin down here. So the prior is era-neutral, position-aware, and padded toward role baselines
for thin samples. Era-neutral means every player is judged against his own season, since the three-point
line moved out in 2010 (Štrumbelj and colleagues measured what that did to shooting and pace) and the
format of the competition changed more than once over the years.

Luck handling is the one place the design changed after testing, and it is worth dwelling on. A
standard RAPM regresses the actual point margin of each possession, so made shots help and missed shots
hurt, and a hot or cold shooting run feeds straight into the ratings. The first version of FPM changed
the target: instead of actual points, the regression was fit on expected points from the shot detail,
every shot valued by what a shot of that type from that spot is worth on average, not by whether it
fell. Grade the shot, not the make. The idea follows Macdonald's ridge APM with a custom response and
the expected-goals plus-minus common in hockey, with LUMA on court-share as the reference for a
possession-level, shot-aware version. It is sound in principle and it failed the next-season test. At
every ridge penalty, with or without the prior, a regression on the actual score predicted the following
season better, and so did two softer versions, one valuing shots at each shooter's own stabilized rate
and one adjusting the defensive side only. The reading is that in the EuroLeague shot-making and
forcing misses are persistent skills, and valuing every shot at the league rate removes them along with
the noise. So the regression is fit on the actual score, and the box-score prior, which carries a
stabilized true-shooting rate, together with the offensive shrink is what keeps a hot month in check.
On top of that sit a couple of ideas from the dynamic-talent world: Engelmann's aging-to-peak and
opponent-luck notes, and
Medvedovsky and Patton's DARKO, which treats talent as a moving thing you keep updating rather than a season you average.
That's where the aging curve and the recency decay come from. A player's rating leans mostly on his own
recent form, with older seasons fading out and the current season loosened so it tracks how he's playing
now.

The last choice is a habit more than a feature. The tuning parameters are set by retrodiction, so a
piece stays in only if it helps predict what a player does next, not because it makes the current
leaderboard look right. That rule threw out a few reasonable-sounding ideas: docking players who change
teams, piling shot-location features into the prior, a four-factor prior and, as above, the
expected-points target all failed the test, so none of them made it in. The tests live in the engine
next to the model, and every setting has a number from them: the ridge penalty, how far the offensive
on/off is pulled back toward the prior (halfway; the defensive side is left alone, since shrinking it
hurt at every setting) and the stiffness of the recency filter.

## Garbage time

Blowout minutes are not real basketball, and leaving them in flatters whoever happened to be on the
floor once the game was already decided. The team efficiency numbers on the site strip those possessions
out, the way Cleaning the Glass does for the NBA. The definition, though, is the EuroLeague's own, not a
copy of theirs.

Cleaning the Glass calls a fourth-quarter possession garbage time when the lead clears a time-scaled bar
(25 points with nine to twelve minutes left, 20 with six to nine, 10 after that) and both benches are in,
with two or fewer starters on the floor between the teams. Neither half of that travels. Scoring is lower
here, so a lead is safe at a smaller number: across 2015 to 2026 the leading team wins 99% of the time
once it is up about 15 with nine minutes left, 10 with five, and single digits inside the last two,
roughly six-tenths of the NBA thresholds. And the bench condition barely fires. EuroLeague coaches keep
their starters on the floor even when the game is gone, partly because rosters are shorter and partly
because point differential breaks ties in the standings. In clearly decided late states an average of 4.3
starters are still playing, and the two-or-fewer rule would flag only about one percent of possessions.

So the EuroLeague rule leans on the scoreboard alone. A fourth-quarter possession is garbage time when
the lead is at least 18 with seven to ten minutes left, 14 with four to seven, or 10 inside four, and
those possessions are removed outright. Checked season by season back to 2007, a team at any of those
thresholds goes on to win at least 98.6% of the time, so the cut is safe without being greedy. The model
itself is gentler: rather than delete blowout possessions it down-weights them, since a regression would
sooner keep thin data than throw it away.

## Bibliography

Grouped by family, with a brief note on each. Links were valid at compile time. Most entries here
contributed something to FPM: a method, a target, a parameter, a decision that was tested, or a claim
made in these notes. One group near the end earns its place differently, as comparison: the public
metrics that share FPM's shape without feeding into it. Work that points at what could be built next rather than at what is built is in
the [future work](https://github.com/filippospol/FPM/blob/main/docs/about/fpm-future-work.md) file,
next to the project it belongs to. A short list of surveys closes the section.

### RAPM and adjusted plus-minus (foundations)

- **Rosenbaum, D. (2004).** *Measuring How NBA Players Help Their Teams Win.* The original box-score plus-minus. https://www.82games.com/comm30.htm
- **Sill, J. (2010).** *Improved NBA Adjusted +/− Using Regularization.* MIT Sloan. The founding ridge-RAPM paper. https://supermariogiacomazzo.github.io/STOR538_WEBSITE/Articles/Basketball/Basketball_Sill.pdf
- **Macdonald, B. (2012).** *Adjusted Plus-Minus using Ridge Regression.* Ridge APM with a custom response; the template for the expected-points version that was tried and dropped. https://arxiv.org/abs/1201.0317
- **Jacobs, J. (Squared Statistics).** The clearest public walk-through of how RAPM is actually built: a multi-part series covering the design matrix, the ridge penalty read as a zero-centered prior, how stint-building and possession counting swing the result, and standard errors near two to two-and-a-half points per 100 that leave most top players statistically tied. The blog ranges well past RAPM, into shot charts, tracking and general statistical method. https://squared2020.com, with the RAPM build-up at https://squared2020.com/2018/12/24/regularized-adjusted-plus-minus-part-iii-what-had-really-happened-was/ and the error work at https://squared2020.com/2019/10/03/exercising-error-quantifying-statistical-tests-under-rapm-part-iv/

### All-in-one metrics and box priors (the architecture FPM mirrors)

- **Myers, D. (BPM 2.0).** Basketball-Reference. A box prior with role interactions. https://www.basketball-reference.com/about/bpm2.html
- **Snarr, T. (EPM).** Dunks & Threes. Box prior plus luck-adjusted RAPM; the closest public analogue. https://dunksandthrees.com/about/epm
- **Goldstein, J. (PIPM).** BBall Index. Box prior plus luck-adjusted on/off. https://www.bball-index.com/player-impact-plus-minus/
- **BBall Index (LEBRON).** Box prior plus role-aware RAPM. https://www.bball-index.com/lebron-introduction/
- **FiveThirtyEight (RAPTOR).** A box/tracking and on-off blend. https://fivethirtyeight.com/methodology/how-our-raptor-metric-works/
- **Medvedovsky, K. & Patton, A. (DARKO).** A daily-updating talent model with aging built in. https://kmedved.com/
- **LUMA Basketball Research (ARC, LOKI).** An open, community-run NBA project: ARC is its attribution rating, an expected-box-value-prior RAPM in points per 100 against an average possession, and LOKI is the matching forward projection; the same group runs the open Hoop Impact Bench, which scores these metrics against real games. LUMA's possession-value framing was the reference for the shot-aware, expected-points target FPM tried and dropped. https://lumahoops.org (leaderboard https://court-share.com/luma, bench https://hoopimpactbench.org)
- **CourtSignal (PULSE).** A Bayesian prior-informed RAPM for the NBA: a box-score prior trained walk-forward on a career RAPM target, cross-fit by player, with a REML-tuned lineup update on the points-per-100 scale. An independent build that converged on the same architecture as FPM, down to leaning the prior harder on offense than defense, and split into a retrospective season rating (Season PULSE) and a forward expected-impact number (Current PULSE). https://courtsignal.net/

### Other public impact metrics (parallel work, for comparison)

Contemporary all-in-one metrics that share FPM's prior-and-regularized-on/off skeleton without feeding into it. They sit here as reference points, not sources.

- **Wijaya, T. (MAMBA).** A box prior built on Synergy play-type points over expectation, laid over a time-decayed, multi-year RAPM target that the prior is regressed toward; retrodiction-tested against LEBRON and EPM. The clearest public case for folding play-type data into the box side. https://www.teemohoop.com/mamba
- **nbarapm.com (Six-Factor RAPM).** One RAPM fit split into offensive and defensive shooting, turnovers and rebounding by running three ridge regressions on the same stints, the six parts summing back to the total. The cleanest public version of the kind of offense/defense-and-factor breakdown FPM reports. https://nbarapm.com
- **nbacouchside (Stable Player Impact, SPI).** PIPM-style box plus luck-adjusted on/off, with padding on every component and a games-started term, on a 1997-2022 database; its regression toward the mean is stronger early in a season and eases as the sample fills, the same instinct as FPM's recency loosening. https://nbacouchside.net/2022/11/05/introducing-nba-stable-player-impact-spi/
- **Alleygorithm (Estimated Wins Added, EWA).** Ridge RAPM fit on the change in win probability per possession rather than point margin, with role-aware interactions and an empirical-Bayes shrink for thin samples, checked on rolling out-of-sample seasons. A win-probability target in place of raw score. https://www.alleygorithm.com/methodology
- **Oliver, D. (Net Points, ESPN).** A single-game contribution stat rather than a forward rating: a RAPM signal multiplied by possessions, then regressed on raw stat totals to set the weights, read against league average per 100 and broken into the four factors. The box-prior step aimed at one game instead of next season. https://global.espn.com/nba/story/_/id/44093220/introducing-net-points-latest-nba-metric-amazing-early-findings (method notes: https://jeremiasengelmann.substack.com/p/espn-just-released-net-points-a-new)

### Prior, stabilization, luck and aging

- **Engelmann, J.** *xRAPM / RPM.* Aging-to-peak and opponent-luck ideas. https://jeremiasengelmann.substack.com/
- **Medvedovsky, K.** *Stabilization and Padding.* The padding/stabilization formula. https://kmedved.com/
- **Wakim, A. & Jin, J. (2014).** *Aging Curves in Sports.* Fitting a native aging curve. https://arxiv.org/abs/1403.7548
- **James, B.** *The "safe lead" rule.* The logic behind a time-scaled garbage-time threshold, recalibrated here from EuroLeague comeback rates.
- **Cleaning the Glass (B. Falk).** *Garbage time.* The NBA removal rule the team stats adapt; the EuroLeague version drops the bench condition and lowers the margins to fit a lower-scoring league. https://cleaningtheglass.com/stats/guide/garbage_time

### EuroLeague and European RAPM / impact (closest prior art)

- **Olivo, F. (2024).** *Advanced Basketball Analytics* (MSc thesis, Bologna). Elastic-net RAPM on these seasons; the closest template. https://amslaurea.unibo.it/id/eprint/30803/1/olivo_thesis.pdf
- **Grassetti, L. et al. (2020; 2026).** *Extended RAPM / ME-RAPM.* EuroLeague lineup synergy is large. https://air.uniud.it/retrieve/e960ecb3-0eae-49e9-a4c9-b8f48a93ad73/10.1515_jqas-2024-0138.pdf
- **Dewandeler, K. (2025).** *Introducing RAPM-EU.* A full-stack Euro RAPM write-up. https://kevindewandeler.substack.com/p/introducing-rapm-eu
- **German Basketball Analytics (2026).** *xEuPM* and *Best players in Europe.* Box prior on Euro RAPM; career ratings. https://germanbasketballanalytics.substack.com/p/a-forward-looking-metric-for-european
- **Clutch Data (2025).** *Measuring Player Impact.* A 3-year Euro RAPM with an O/D split. https://clutchdata.substack.com/p/off-season-insights-measuring-player

### EuroLeague box ratings, PIR critique and possessions

- **Carta, G. & Favero, C. A. (2026).** *WINSCORE revisited.* NBA weights don't transfer; fit native. https://iris.unibocconi.it/retrieve/caa8b1e5-4f3d-43cb-8b6d-79868be8818e/carta-favero-2026-winscore-revisited.pdf
- **Charamis, E. et al. (2023).** *Estimating team possessions.* The EuroLeague possession formula. https://journals.sagepub.com/doi/10.1177/17479541211070788

### Shot quality and expected points (the target that was tested and dropped)

- **"Predictive Analysis of Successful Basketball Shots: The EuroLeague Case."** The expected-FG basis. https://www.researchgate.net/publication/327703497
- **"Expected Points Above Average" (2025).** A Bayesian hierarchical shot model that pools each shooter's skill instead of using league rates; the idea behind the shooter-specific version that was also tested and lost. https://arxiv.org/abs/2405.10453
- **"Biases in Expected Goals Models Confound Finishing Ability" (2024).** Context-free expected values absorb part of real shooting skill, so good shooters can read as lucky. This is exactly how the expected-points target failed here. https://arxiv.org/abs/2401.09940

### Box-score frameworks, possessions, roles

- **Oliver, D. (2004).** *Basketball on Paper.* Four Factors, possessions, ratings. (ISBN 978-1-57488-688-0.)
- **Kubatko, J. et al. (2007).** *Analyzing Basketball Statistics.* Per-100 and pace conventions. https://doi.org/10.2202/1559-0410.1070
- **BBall Index.** *Player roles.* The role taxonomy. https://www.bball-index.com/about/about-the-data/

### Validation and openness

- **Walker, N. (OpenRAPM).** Open NBA RAPM, 1996-97 to now: plain RAPM, a box prior, an out-of-sample shrink, every change judged on games it never saw. The validation-first approach this project follows. https://github.com/bbstats/openrapm
- **Franks, A., D'Amour, A., Cervone, D. & Bornn, L. (2016).** *Meta-analytics: tools for understanding the statistical properties of sports metrics.* Discrimination, stability and independence as the tests of a metric; the formal version of the next-season and split-half tests in the engine. https://arxiv.org/abs/1609.09830

### The league itself

- **Štrumbelj, E., Vračar, P., Robnik-Šikonja, M., Dežman, B. & Erčulj, F. (2013).** *A Decade of Euroleague Basketball: an Analysis of Trends and Recent Rule Change Effects.* Journal of Human Kinetics. The measured effect of the 2010 rule changes, the three-point line out to 6.75 m among them, on shooting and pace; the basis for judging each season on its own curve. https://pmc.ncbi.nlm.nih.gov/articles/PMC3827757
- **Foteinakis, P. F. et al. (2026).** *Home advantage in EuroLeague basketball: quantifying the interactions between team quality, competitive balance, and season dynamics.* Journal of Human Sport and Exercise. 2,154 games from 2016 to 2025: home teams win 62.9%, and the edge is larger for weaker teams. The regression here carries one home-court term for every team; a quality-dependent one is untested. https://www.jhse.es/index.php/jhse/article/view/quantifying-euroleague-home-advantage

### Data sources and parallel public work

- **EuroLeague feeds.** The data endpoints (boxscore, play-by-play, shots, bio, schedule).
- **egemeny13, `euroleague-analytics`.** A parallel play-by-play warehouse with possessions counted event by event, five-man lineup stats, on/off splits and shot coordinates for the latest seasons, with an archive being backfilled; the one independent check on the stints here. https://github.com/egemeny13/euroleague-analytics
- **Other ways to get this data.** The Python and R packages that wrap the same feeds are listed in the data folder's readme.

### Background

Surveys and reviews that shaped the thinking without supplying a specific piece of the model.

- **Engelmann, J. (2017).** *Possession-based player performance analysis in basketball.* In the Handbook of Statistical Methods and Analyses in Sports (Chapman & Hall/CRC). The canonical RAPM method chapter, by the author of RPM. https://www.routledge.com/products/9780367331016
- **Hvattum, L. M. (2019).** *A comprehensive review of plus-minus ratings.* The literature map. https://www.researchgate.net/publication/335324879
- **Terner, Z. & Franks, A. (2021).** *Modeling Player and Team Performance.* A box / APM / tracking survey. https://arxiv.org/abs/2007.10550
- **Gelade, G. & Hvattum, L. M. (2020).** *On the relationship between +/- ratings and event-level performance statistics.* Plus-minus and box-score metrics tested head to head; each captures value the other misses, the case for blending them. https://doi.org/10.3233/JSA-200432
- **Matano, F., Richardson, L. & Pospisil, T. (2018).** *Augmenting Adjusted Plus-Minus in Soccer with FIFA Ratings.* An outside rating entered as the ridge prior mean; the same prior-as-offset architecture, proven in another sport. https://arxiv.org/abs/1810.08032

## Limitations

A metric is only as honest as the caveats it admits. These are the ones that matter.

**Perimeter defense is under-measured.** With no public tracking data, a guard's off-ball work (ball
pressure, fighting over screens, forcing a contested miss that still counts as a miss) is nearly
invisible to both the box score and on/off. FPM reads rim protection well and catches good perimeter
defenders when the scoreboard agrees, but it will consistently under-credit some elite on-ball guards.
That's a limit of the data, not a tuning problem, and it's the single biggest known weakness.

**Thin samples and overlapping lineups.** The EuroLeague season is short and rotations are tight, so the
same lineups recur and RAPM struggles to separate players who almost always share the floor. The prior
and the recency weighting paper over most of this, but two stars who never play apart look, to the
regression, partly like one player. Defensive on/off in particular is close to noise over a single
season, which is why defense leans harder on the prior and carries wider error bars.

**No explicit synergy term.** The model estimates individual effects and has no lineup-interaction term.
The EuroLeague literature (Grassetti et al.) finds synergies here are larger than in the NBA, so some
pair- and unit-level value gets absorbed into individual ratings rather than credited to the
combination.

**The prior can over-correct.** Pulling single-season on/off toward a box-score prior trades some
accuracy for stability: it cuts the noise, but a season that genuinely breaks from the prior (a real
leap, a role change) gets pulled back more than it should. The strength of that pull was set for average
accuracy, which won't be right for every individual case.

**Impact is tied to team context and style, not pure skill.** FPM measures what happened with a player
on the floor, inside his team, role and system. Scheme, usage, pace and the quality of his teammates all
feed into the number, and no RAPM can fully separate them from the player. One visible effect is that
players in strong, stable setups tend to sit high season after season: a rim finisher like Tavares is
set up by the passers around him, and a shooter like Vezenkov gains from the spacing and shot creation
his team generates. That does not make the ratings wrong, both are genuinely excellent, but some of the
figure belongs to the situation as much as the player, and a move to a new team or role can shift an FPM
even when the player has not changed.

**Early-season and low-minute ratings lean on the past.** Until a player logs enough possessions, his
rating is mostly his age-adjusted baseline. That's the right call statistically, but it means the live
board is slow to reward a real early breakout, which is exactly what the uncertainty column is there to
flag.

**Era and cross-season comparability is approximate.** Features are standardized within each season and
the scale is set from past seasons, but comparing a 2009 rating to a 2026 one still assumes that
within-season standardization fully absorbs the changes in rules, pace and format. It mostly does, but
there's no guarantee.

**The first four seasons' prior is in-sample.** Each season's box-score prior is trained only on the
seasons before it, the same rule the live season follows, so the backtests are honest from 2011-12 on.
The first four seasons (2007-08 to 2010-11) share a prior trained on those same four, since there is
nothing earlier to learn from.

**Data quality degrades in the early seasons.** Shot detail, coach fields and some box lines are less
clean before roughly 2015-16, so a few features are weaker in those early years.

**Home court is one number.** The regression controls for home court with a single term shared by every
team. Foteinakis and colleagues find the EuroLeague home edge is larger for weaker teams, so a term that
varies with team strength might fit better; it has not been tested here.

**Luck is damped, not removed.** The regression counts the real score, so a hot or cold shooting run
does reach a single-season rating; the box-score anchor and the offensive shrink soften it rather than
take it out. Opponent free-throw variance, loose-ball and foul-call luck, and small-sample schedule luck
aren't modeled either.
