# Acknowledgements

FPM is built almost entirely on other people's work. These are the sources it owes the most to. The
complete list, with a note on what each one contributed, is in the
[bibliography](https://github.com/filippospol/FPM/blob/main/docs/about/fpm-design.md#bibliography).

## Plus-minus as a regression

The whole approach goes back to Dan Rosenbaum's
[adjusted plus-minus](https://www.82games.com/comm30.htm) and Joe Sill's
[ridge-regression paper](https://supermariogiacomazzo.github.io/STOR538_WEBSITE/Articles/Basketball/Basketball_Sill.pdf),
which made RAPM usable. Brian Macdonald showed that the regression
[can be fit on something other than the raw score](https://arxiv.org/abs/1201.0317), and that is
the basis of FPM's expected-points target. Jeremias Engelmann's work on RAPM, and J. Jacobs' writing on
[RAPM standard errors](https://squared2020.com/2019/10/03/exercising-error-quantifying-statistical-tests-under-rapm-part-iv/),
shaped how the ratings and their uncertainty are reported.

## The box-score prior

The design of a box-score prior with on/off layered on top comes from the NBA's all-in-one metrics:
Taylor Snarr's [EPM](https://dunksandthrees.com/about/epm) at Dunks & Threes, Jacob Goldstein's
[PIPM](https://www.bball-index.com/player-impact-plus-minus/) and BBall Index's
[LEBRON](https://www.bball-index.com/lebron-introduction/), Daniel Myers'
[BPM](https://www.basketball-reference.com/about/bpm2.html), and FiveThirtyEight's
[RAPTOR](https://fivethirtyeight.com/methodology/how-our-raptor-metric-works/). BBall Index's
[role taxonomy](https://www.bball-index.com/about/about-the-data/) is the model for FPM's roles.

## Talent that moves

Kostya Medvedovsky and Andrew Patton's [DARKO](https://kmedved.com/) is the reason FPM treats a
player's level as something that keeps updating rather than a season to be averaged, and
Medvedovsky's stabilization and padding work is behind the way thin samples are handled. The aging
curve follows Engelmann's aging-to-peak notes and [Wakim and Jin](https://arxiv.org/abs/1403.7548).

## Grading the shot

[LUMA](https://court-share.com/luma) at court-share was the reference for a possession-level,
shot-aware model, and the EuroLeague
[shot-success study](https://www.researchgate.net/publication/327703497) gave the basis for
expected field goals in this league.

## The European work

A few people have done this for Europe before, and their work set both the method and the warnings.
F. Olivo's [thesis](https://amslaurea.unibo.it/id/eprint/30803/1/olivo_thesis.pdf) ran RAPM on
these same seasons. L. Grassetti and colleagues
[showed](https://air.uniud.it/retrieve/e960ecb3-0eae-49e9-a4c9-b8f48a93ad73/10.1515_jqas-2024-0138.pdf)
that lineup synergy is larger in the EuroLeague than in the NBA. G. Carta and C. A. Favero's
[WINSCORE revisited](https://iris.unibocconi.it/retrieve/caa8b1e5-4f3d-43cb-8b6d-79868be8818e/carta-favero-2026-winscore-revisited.pdf)
is why every weight here is fit on EuroLeague data instead of borrowed from the NBA, and E. Charamis
and colleagues supplied the
[possession formula](https://journals.sagepub.com/doi/10.1177/17479541211070788). Kevin
Dewandeler's [RAPM-EU](https://kevindewandeler.substack.com/p/introducing-rapm-eu),
German Basketball Analytics'
[xEuPM](https://germanbasketballanalytics.substack.com/p/a-forward-looking-metric-for-european) and
Clutch Data's [European RAPM](https://clutchdata.substack.com/p/off-season-insights-measuring-player)
are parallel efforts worth reading.

## Garbage time

The garbage-time rule adapts [Cleaning the Glass](https://cleaningtheglass.com/stats/guide/garbage_time)
and Bill James' "safe lead" logic, recalibrated to EuroLeague comeback rates.

## Testing and openness

Nathan Walker's [OpenRAPM](https://github.com/bbstats/openrapm) is the model for judging every
change on games the ratings never saw, and for doing all of it in public. Franks, D'Amour, Cervone
and Bornn's [meta-analytics](https://arxiv.org/abs/1609.09830) is the formal case for testing a
metric that way. OpenRAPM, DARKO, Dunks & Threes and BBall Index also inspired the look of this
site.

## Data

The data comes from the EuroLeague's public feeds. egemeny13's
[euroleague-analytics](https://github.com/egemeny13/euroleague-analytics) served as an independent
cross-check on possessions.
