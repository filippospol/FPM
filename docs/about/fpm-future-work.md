# Future work

Everything listed here can be built from the data already in this repository. That data is:

- the twenty season files, 2007-08 to the season in progress, with:
  - fixtures with dates, venues, attendance and capacity;
  - player and team box scores;
  - the head coach for every game;
  - the play-by-play, with every substitution, timeout and game-clock stamp;
  - every shot with coordinates, zone, score state and fast-break, second-chance and off-turnover
    flags;
  - player biographies;
  - for the live season, the full schedule.
- the stints: every stretch of five-on-five with possessions, points and the full box for both
  sides.

Nothing below needs tracking data, injury reports or betting lines, which are not public for the
EuroLeague. The few ideas that would need them are collected at the end.

The reading next to each project is where to start. Some of it was considered for FPM itself and
left out; it is kept here, with the project it belongs to, rather than in the bibliography, which
only lists what the model uses.

## Team stats

**Efficiency and four factors with garbage time removed.** Offensive and defensive rating, pace,
effective field goal percentage, turnover rate, offensive and defensive rebounding, and free-throw
rate, for every team and its opponents. Decided minutes are removed with the EuroLeague rule
described in the design notes. This is the team page Cleaning the Glass built for the NBA.
Reading: [Cleaning the Glass, garbage time](https://cleaningtheglass.com/stats/guide/garbage_time);
Oliver, *Basketball on Paper* (2004).

**How possessions start.** Every possession classified by what came before it:
- an opponent make;
- a defensive rebound;
- a steal;
- a dead-ball turnover;
- an opponent free throw.

Pace and points per possession for each type, on offence and on defence. In the NBA a possession
after a steal is worth far more than one after a made basket; how big that gap is here, and which
teams live off it, is not published anywhere. Reading:
[Inpredictable, pace and efficiency by possession type](https://www.inpredictable.com/2015/03/team-pace-and-efficiency-by-possession.html);
[pbpstats possession documentation](https://pbpstats.readthedocs.io/en/latest/pbpstats.resources.possessions.html).

**Live-ball against dead-ball turnovers.** A steal (the turnover paired with a steal event) gives the
opponent a running start; a ball out of bounds does not. The points each kind costs, the share of
each by team and player, and which ball-handlers give up the expensive ones. Reading:
[Inpredictable, live ball vs dead ball turnovers](https://inpredictable.com/2015/11/live-ball-vs-dead-ball-turnovers.html).

**Play context: halfcourt, transition, putbacks.** Every shot carries fast-break, second-chance and
off-turnover flags, and the clock shows how quickly it came. Those give efficiency in halfcourt, in
transition and on putbacks, for each team and allowed by each defence. The EuroLeague publishes the
point totals; the per-possession rates and the defensive side are not public. Reading:
[Cleaning the Glass, play context](https://cleaningtheglass.com/stats/guide/league_context).

**Shot profiles.** Where a team shoots from and how well, and what it allows, against the league:
rim, short and long mid-range, corner and above-the-break threes, as shares of attempts and as
accuracy. Complete from 2015-16, when the shot feed covers every field goal.

**How much a defence controls opponent three-point shooting.** In college and NBA data, a defence
controls how many threes it allows far more than how many go in, and opponent three-point percentage
barely repeats from season to season. Both halves can be tested here: allowed three-point rate and
allowed percentage, split-half and year to year, for twenty seasons. If the result holds, it also
says how much of a team's defensive rating is luck. Reading:
[KenPom, one last post on 3P defense](https://kenpom.com/blog/one-last-post-on-3p-defense/).

**Offensive rebounding against transition defence.** Sending players to the glass wins second
chances and gives up fast breaks. The play-by-play shows both sides of that trade for every team:
offensive rebound rate after its own misses, and the opponent's transition efficiency on the
possessions that follow a defensive rebound. Reading:
Wiens, Balakrishnan, Brooks & Guttag,
[*To Crash or Not To Crash*](https://www.sloansportsconference.com/research-papers/to-crash-or-not-to-crash),
MIT Sloan (2013);
[KenPom, offense vs defense rebounding](https://kenpom.com/blog/offense-vs-defense-rebounding/).

**Where misses go.** Offensive rebound rate by the zone of the missed shot: rim misses, long twos,
corner threes and above-the-break threes. The expected value of a miss feeds straight into shot
selection, since a missed corner three is not the same as a missed layup. Reading:
[Northwestern Sports Analytics, do longer shot attempts mean longer rebounds?](https://sites.northwestern.edu/nusportsanalytics/2018/02/28/do-longer-shot-attempts-mean-longer-rebounds);
[Hoopsalytics, how much is a missed 3 point shot worth?](https://blog.hoopsalytics.com/how-much-is-a-missed-3-point-shot-worth/).

**Pace and the shot clock.** The length of every possession from the clock stamps; efficiency early,
mid and late in the clock; which teams push and which grind. In the NBA efficiency peaks a few
seconds into a possession and falls away through the clock, and the shape here is unmeasured.
Reading: [Inpredictable, possession types and length](https://www.inpredictable.com/2015/03/team-pace-and-efficiency-by-possession.html).

**Expected record.** Pythagorean wins, with the exponent fitted to EuroLeague scoring rather than
borrowed from the NBA. Records in close games and how quickly they regress, and margin-based power
rankings next to the standings. Reading:
[Pythagorean expectation](https://en.wikipedia.org/wiki/Pythagorean_expectation);
[Pythagorean expectation and other machine learning applications in Euroleague](https://economics.soc.uoc.gr/en/seminar/275/pythagorean-expectation-and-other-machine-learning-applications-in-euroleague).

**Team ratings.** Three ways to rate teams, compared on how well each predicts the next game:
- an adjusted net rating (every margin explained by team, opponent and home court, as in
  Basketball-Reference's SRS);
- an Elo rating with margin of victory and carry-over between seasons;
- the roster's FPM.

Reading:
[FiveThirtyEight, how we calculate NBA Elo ratings](https://fivethirtyeight.com/features/how-we-calculate-nba-elo-ratings);
[Solmos, an Elo rating system for the EuroLeague](https://solmos.netlify.app/post/2020-03-10-elo-rating-system/elo-rating-system/).

**Strength of schedule, played and remaining.** Opponent strength with the home edge added for road
games, over the games already played and over the rest of the season, plus home games left. A
round-robin schedule evens out by the end, so the interesting part is the order. The live season's
schedule table supplies the unplayed games. Reading:
[KenPom ratings FAQ](https://kenpom.com/blog/pomeroy-ratings-faq/);
DeHollander & Karwan,
[*Improving strength of schedule metrics in sports scheduling*](https://www.degruyterbrill.com/document/doi/10.1515/jqas-2024-0171/pdf),
JQAS (2026);
[EuroLeague, strength of schedules could impact playoff race](https://www.euroleaguebasketball.net/euroleague/news/strength-of-schedules-could-impact-playoff-race).

**Home court, team by team.** The home edge for each club and venue. Its relation to attendance and
capacity, both in the fixtures. The empty-arena seasons as a natural experiment on how much of it is
the crowd. Whether weaker teams gain more at home. Reading:
Foteinakis et al.,
[*Home advantage in EuroLeague basketball*](https://www.jhse.es/index.php/jhse/article/view/quantifying-euroleague-home-advantage),
Journal of Human Sport and Exercise (2026);
[*Home-audience advantage in basketball: evidence from a natural experiment in EuroLeague games during the 2019-2021 Covid-19 era*](https://www.researchgate.net/publication/362156724) (2022).

**Schedule congestion and travel.** Double-round weeks, days of rest between EuroLeague games and
distance travelled, from the game dates and venue addresses, against shooting and efficiency. Rest
here only counts EuroLeague games; domestic league games in between are not in the data. Reading:
Sansone, Gasperi, Conte, Scanlan, Sampaio & Gómez-Ruano,
[*Game schedule, travel demands and contextual factors influence key game-related statistics among the top European male basketball teams*](https://iris.uniroma4.it/retrieve/c1c671ca-799b-4086-816e-f2ac8db15633/Game%20schedule%20%20travel%20demands%20and%20contextual%20factors%20influence%20key%20game-related%20statistics%20among%20the%20top%20European%20male%20basketball%20teams.pdf),
Journal of Sports Sciences (2024);
[Eurohoops, double-game weeks](https://eurohoops.net/en/trademarks/398836/double-game-weeks-best-teams-best-players).

**What wins in the EuroLeague.** Which of the four factors separate winners from losers and
playoff teams from the rest, season by season and across formats, and whether the answer has moved
as the league has. Reading:
Kamitsis & Politis,
[*Performance indicators for qualification to the playoffs and the Final Four in Euroleague 2000-2022*](https://journals.sagepub.com/doi/10.1177/22150218251365222),
Journal of Sports Analytics (2025);
Mikołajec, Banyś, Żurowska-Cegielska, Zawartka & Gryko,
[*How to win the basketball Euroleague?*](https://jhk.termedia.pl/How-to-Win-the-Basketball-Euroleague-Game-Performance-Determining-Sports-Results,158529,0,2.html),
Journal of Human Kinetics (2021).

**Competitive balance over twenty seasons.** The spread of team net ratings, the share of close
games and blowouts, and how the closed licences and the moves from 24 to 16 to 18 to 20 teams have
changed both. Reading:
[Basketball Analytics Lab, exploring competitive dynamics across European basketball leagues](https://basketballanalyticslab.substack.com/p/exploring-competitive-dynamics-across).

**Two decades of trends.** Pace, three-point rate, rim rate, free-throw rate, assist rate and
scoring by season since 2007-08: an update of the study that covered the decade before it. Reading:
Štrumbelj et al.,
[*A Decade of Euroleague Basketball*](https://pmc.ncbi.nlm.nih.gov/articles/PMC3827757),
Journal of Human Kinetics (2013).

**Score effects.** How teams play when leading and when trailing, by quarter and margin. Does the
leader slow down, take fewer threes and lose efficiency, and does the trailing team speed up? Hockey
and football analysts adjust for this routinely, and it is rarely measured in basketball. Reading:
[StatsBomb, score effects](https://blogarchive.statsbomb.com/articles/soccer/score-effects/).

**Runs.** Are EuroLeague scoring runs longer than chance would produce, and do they end sooner after
a timeout? Reading:
Schilling, [*Is Basketball a Game of Runs?*](https://arxiv.org/abs/1903.08716) (2019);
Carta, Favero & Maver,
[*Do timeouts matter? A study of Euroleague basketball*](https://journals.sagepub.com/doi/10.1177/22150218261434693),
Journal of Sports Analytics (2026).

## End of games, clutch and strategy

**Clutch time.** Every team's and player's numbers in the moments that decide games. The standard
definition is the NBA's: the last five minutes of the fourth quarter or overtime, with the score
within five points. The play-by-play has the score and the clock on every event, so every clutch
possession of twenty seasons can be found. From them:
- for teams: clutch record, offensive, defensive and net rating, four factors and pace, how many
  games reach clutch time and how often each team wins them;
- for players: clutch minutes, points per 100, shooting by zone, share of the team's clutch shots,
  turnovers and free throws, and on/off within clutch time;
- how the game changes when it tightens: pace, three-point rate, free-throw rate, the assisted
  share of makes (a fall means more one-on-one play) and fouling;
- a EuroLeague definition, since five points is a bigger margin in a lower-scoring league: the
  window and margin set from comeback rates, the way the garbage-time rule was;
- a leverage version once win probability exists, weighting each possession by how much it can
  swing the result rather than by a fixed window;
- the test that matters: whether clutch performance repeats, split-half and from season to season,
  so a clutch reputation can be told apart from a run of luck in a small sample.

Reading:
[NBA.com, coming through in the clutch](https://www.nba.com/news/stats-breakdown-coming-through-in-the-clutch);
[Inpredictable, heroes, goats and garbage men](https://www.inpredictable.com/2016/01/heroes-goats-and-garbage-men-new-clutch.html);
[Is clutch performance predictable?](https://themathchecksout.substack.com/p/is-clutch-performance-predictable)

**Fouling when up three.** In the last seconds, leading by three: foul to give up two free throws, or
defend the three? Every case in twenty seasons is in the play-by-play, with the outcome. Reading:
[Harvard Sports Analysis Collective, up three, time running out, do we foul?](https://harvardsportsanalysis.org/2010/08/intentionally-fouling-up-3-points-the-first-comprehensive-cbb-analysis);
[KenPom, yet another study about fouling when up 3](https://kenpom.com/blog/yet-another-study-about-fouling-when-up-3/).

**Two-for-one.** Possessions that start with roughly 25 to 40 seconds left in a quarter: do teams
that shoot early to get the last possession come out ahead? The clock stamps make this a direct
count.

**Timeouts.** When coaches call them (after runs, before free throws, at the end), and what follows:
- the scoring margin before and after;
- free-throw accuracy after a timeout called to make the shooter wait.

Reading: Carta, Favero & Maver (2026), above;
[*"Icing the shooter" in basketball: the unintended consequences of time-out management when the game is on the line*](https://lida.sport-iat.de/dbb/Record/4085006?lng=en),
Psychology of Sport and Exercise (2023).

**Free throws under pressure.** Accuracy in the last minutes of close games against the rest of the
game, home against away, and by player across seasons, so that a clutch shooter is told apart from a
lucky one. Reading:
[*Performance Under Pressure in the NBA*](https://nbamath.com/wp-content/uploads/2012/02/Performance-Under-Pressure-in-the-NBA-Oregon-State-BYU1.pdf).

**In-game win probability.** The chance of winning at every moment, from:
- score;
- time left;
- possession;
- the teams' strength before the game.

Fitted on twenty seasons of EuroLeague games, it would give win probability charts for every game,
leverage, and win probability added for every player. It would also allow a garbage-time definition
built on the game state rather than a margin rule. Reading:
[Inpredictable, NBA win probability graphs](https://www.inpredictable.com/2013/12/nba-win-probability-graphs-and-box.html);
[*Bayesian estimation of in-game home team win probability for NBA games*](https://arxiv.org/abs/2207.05114);
Deshpande & Jensen,
[*Estimating an NBA Player's Impact on His Team's Chances of Winning*](https://arxiv.org/abs/1604.03186) (2016).

## Lineups and on/off

**Lineup stats.** Five-man units with minutes, net rating and four factors, with garbage time
removed. Also two- and three-man combinations, and the units a coach actually uses next to the ones
that work.

**On/off splits.** For every player, his team's offensive and defensive rating with him on the floor
and off it. These come with a reminder that on/off is noisy and that FPM is the adjusted version of
it.

**With or without you.** Team results in the games a player played against the games he missed,
adjusted for opponent. The box score lists who was dressed, so missed games are known exactly. The
same idea applies to pairs: how two players do together, apart, and with neither. Reading:
[WOWYR, an impact stat available across NBA history](https://hoopslab.rotowire.com/post/151121512171/wowyr-an-impact-stat-available-across-nba);
[databallr WOWY](https://databallr.com/wnba/wowy).

**Pairs and synergy.** Two-man combinations whose on-court results beat the sum of their FPMs, and
those that fall short. A lineup term is the natural next step for the model itself, since EuroLeague
synergies appear larger than the NBA's. Reading:
Petridis & Pelechrinis, [*Lineup RAPM*](https://arxiv.org/abs/2601.15000) (2026);
[*Hypergraph Adjusted Plus-Minus*](https://arxiv.org/abs/2403.20214) (2024);
[German Basketball Analytics, lineup and coach synergies in European basketball](https://germanbasketballanalytics.substack.com/p/lineup-and-coach-synergies-in-european).

**Defensive profile while on the floor.** For each player, what opponents shot while he was on the
floor:
- rim attempt rate;
- three-point attempt rate;
- accuracy at the rim.

These are the rim-deterrence features the box prior already builds, published as stats. The tracking
version of this idea maps a defender's effect across the whole court. Reading:
[DARI, deterrence-adjusted rim impact](https://bkervick.substack.com/p/dari-deterrence-adjusted-rim-impact);
Franks, Miller, Bornn & Goldsberry,
[*Characterizing the spatial structure of defensive skill in professional basketball*](https://arxiv.org/abs/1405.0231) (2015).

**Rotation patterns.** Rotation charts for every game, built from the substitutions:
- minutes by quarter;
- the length of stints and of rests;
- how deep each coach goes;
- when starters sit and return;
- how all of it changes in close games, double-round weeks and the playoffs.

**Continuity.** How much of last season's minutes a roster brings back, how often a team changes its
starting five, and how both relate to results, early in the season especially. Reading:
[Basketball-Reference, team continuity](https://www.basketball-reference.com/blog/indexca63.html?p=3277).

## Players

**Ben Taylor's box metrics.** Three measures, all computable from the box score:
- Box Creation, an estimate of open shots created for teammates;
- Offensive Load, a player's share of the offence including playmaking;
- Passer Rating, which also needs the share of a player's assists that lead to layups (the
  play-by-play links each assist to its shot).

Their weights cannot be used as published. Every coefficient was fitted on NBA data, and the
EuroLeague differs on the things those formulas lean on: 40-minute games, about 70 possessions a
team rather than 100, a shorter three-point line, and different assist and three-point rates.
Applied as they are, the numbers would not mean here what they mean in the NBA. So the project starts
with recalibration:
- refit each coefficient against EuroLeague targets, such as how a player's presence changes his
  teammates' shot quality and accuracy in the stints;
- check that the refitted versions repeat from season to season;
- only then publish them, next to the NBA-weighted versions so the difference is visible.

It is the same lesson the WINSCORE authors drew for box score weights in general: fit native.
Reading:
[Intro to Ben Taylor's passing metrics](https://salnba.substack.com/p/intro-to-ben-taylors-passing-metrics);
Carta & Favero,
[*WINSCORE revisited*](https://iris.unibocconi.it/retrieve/caa8b1e5-4f3d-43cb-8b6d-79868be8818e/carta-favero-2026-winscore-revisited.pdf) (2026).

**Shooting above expected.** The expected-points code the model no longer uses, turned into a
description. Points per shot are split into shot quality (where a player shoots from, valued at
league rates) and shot making (how far above those rates he hits), for players and teams and on
defence. A shooter-specific version, where each player's expected rate is pooled toward the league,
is the better tool here. Reading:
[*Expected Points Above Average*](https://arxiv.org/abs/2405.10453) (2025);
Cervone, D'Amour, Bornn & Goldsberry, [*POINTWISE*](https://arxiv.org/abs/1408.0777) (2014), the
tracking version of grading the process.

**Shot charts.** Hexagon charts for every player and team, coloured against the league, for every
season from 2015-16, with smoothing for small samples. Reading:
Scott, Gee et al., [*Shot charts estimation*](https://link.springer.com/article/10.1007/s00180-025-01599-1) (2025).

**Assist networks.** Who assists whom and from where to where, from the assist event next to each
make and the shot's zone. Playmaker profiles (assists to the rim against assists to threes), and
the duos a team runs through. Only assisted makes are visible, not every pass. Reading:
[*Temporal passing network in basketball*](https://arxiv.org/abs/2506.04808) (2025);
[Network science based basketball analytics](https://en.wikipedia.org/wiki/Network_Science_Based_Basketball_Analytics).

**Self-creation.** Assisted against unassisted makes by zone, and unassisted rim attempts: who
creates his own shot and who finishes what others create. The assisted share is already a model
feature.

**Fouls drawn and foul trouble.** Foul-drawing rates, and-ones, and free-throw trips per shot. Also
how a player's minutes and aggression change once he picks up his third and fourth foul, which
matters more with five fouls than six.

**The hot hand.** Whether a make raises the chance of the next make, tested on twenty seasons of
shot sequences with the correction for the bias that made the original studies find nothing. Free
throws, which are taken in identical conditions, are the cleanest test. Reading:
Miller & Sanjurjo, *Surprised by the Hot Hand Fallacy? A Truth in the Law of Small Numbers*,
Econometrica (2018); [*Do Steph Curry and Klay Thompson Have Hot Hands?*](https://arxiv.org/abs/1706.03442) (2017);
[Hot hand](https://en.wikipedia.org/wiki/Hot_hand).

**Consistency.** Game-to-game volatility of production and impact: who delivers the same every night
and who swings, and whether that is itself repeatable.

**Empty stats and quiet contributors.** Box score production that moves the team's results and
production that does not, from the gap between a player's box prior and his on-court impact, season
after season. Reading:
Berry, [*Finding Empty Stats and Quiet Contributors with RAPM*](https://georgeberry.substack.com/p/finding-empty-stats-and-quiet-contributors) (2026).

**A native box score index.** A PIR replacement with weights fitted on EuroLeague results, simple
enough to compute from a box score, set against PIR, the box prior and FPM. Reading:
Marmarinos, [*A new player-evaluation index*](https://pergamos.lib.uoa.gr/uoa/dl/object/2933718/file.pdf) (2019);
Martínez, *"Valoración ACB"* (2024);
Damoulaki et al., [*Lasso Multinomial Performance Indicators*](https://arxiv.org/abs/2406.09895) (2024).

**Similar players.** Nearest neighbours in the standardized feature space the prior uses: who a
player plays like, across twenty seasons, with the closest historical matches for every rookie.
Reading: [OpenRAPM](https://github.com/bbstats/openrapm), which has a similarity page built on the
same idea.

**Roles and archetypes.** Clusters built from the same features, compared with the role tags on the
leaderboard and with HackaStat's role labels. Reading:
[HackaStat](https://hackastat.eu/en/home-page-eng/);
[*Is Stephen Curry really a guard? A new perspective on player typologies using functional data analysis*](https://arxiv.org/abs/2504.21761) (2025);
Gencoglu, [*The Analytics Behind EuroLeague Success*](https://gencoglumur.substack.com/p/the-analytics-behind-euroleague-success) (2026).

**Careers and aging.** A career page for every player, with FPM season by season. The aging curve
by position and by skill: shooting, rebounding and defence may peak and fade at different ages. The
model fits one aging curve; this would show several. Reading:
Vaci, Cocić, Gula & Bilalić,
[*Large data and Bayesian modeling: aging curves of NBA players*](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6690864/) (2019).

**Game-by-game ratings.** FPM updated after every game rather than recomputed from the season so
far, with a player's level treated as something that drifts. That gives a form chart for each
player and a rating that reacts to a role change within a few games. Reading:
Fearnhead & Taylor, [*On Estimating the Ability of NBA Players*](https://arxiv.org/abs/1008.0705) (2011).

**Minutes projections.** A per-game minutes model, a recency filter with the dressed twelve's
minutes redistributed to sum to 200, already tested at about 4.7 minutes of error per player. It is
the step that turns player ratings into a game forecast. Gains beyond that baseline depend on
knowing who is starting and who is hurt. Reading:
[RotoGrinders, projecting minutes](https://rotogrinders.com/lessons/projecting-minutes-1149307).

**Missed games.** Games missed per player per season, from who is absent from the box score. Runs of
absences, and how teams fare in them. It is the raw material for with-or-without-you, and the
nearest thing to injury data the EuroLeague provides.

**Fantasy projections.** The EuroLeague fantasy game scores players by PIR, so projected minutes
times PIR per minute, adjusted for opponent and venue, is a fantasy projection. Reading:
[Dunkest, EuroLeague Fantasy 2026-27](https://www.dunkest.com/en/euroleague/news/fantasy-basketball/244469/euroleague-fantasy-2026-27-minutes-roles-and-schedule).

## Forecasting

**Pre-game win probability.** Roster FPM times projected minutes, plus home court, as a forecast for
every game. It is judged against a published benchmark: off-the-shelf models reach 67% on picking
the winner, and a crowd of fans did better. Reading:
Giasemidis,
[*Descriptive and Predictive Analysis of Euroleague Basketball Games and the Wisdom of Basketball Crowds*](https://arxiv.org/abs/2002.08465) (2020).

**Season simulation.** Thousands of simulated runs through the remaining schedule, giving the odds
of top-four, top-six, play-in and elimination for every team, updated after each round.

**Preseason projections.** Each team's strength before a ball is bounced, from:
- the roster's FPM;
- the aging curve;
- projected minutes;
- a sensible prior for newcomers.

The projections are then checked against how the season actually goes.

## Coaches and rosters

**Coaches.** Twenty seasons of head coaches, one per game. From these:
- a coach term alongside the players in the regression;
- rotation depth, substitution timing and timeout use;
- how coaches' teams play (pace, shot profile, rebounding choices) as they move between clubs.

Separating a coach from his roster is the hard part. Reading:
Bacco et al.,
[*Causality-inspired adjusted plus-minus*](https://proceedings.mlr.press/v236/bacco24a/bacco24a.pdf) (2024);
[German Basketball Analytics, lineup and coach synergies](https://germanbasketballanalytics.substack.com/p/lineup-and-coach-synergies-in-european).

**Coaching changes.** What happens after a coach is replaced mid-season, compared with similar teams
that kept theirs. The comparison matters because a team that fires its coach is often at a low
point, and some recovery would have come regardless.

**Who plays in the EuroLeague.** Nationality, age, height and experience of rotations by season and
team, from the biographies. The share of imports and of homegrown players, the age of contenders, and
how much young players get to play. Reading:
[EuroLeague, the high bar for EuroLeague youngsters](https://www.euroleaguebasketball.net/euroleague/news/the-high-bar-for-euroleague-youngsters);
[Eurohoops, European players have to fight for their EuroLeague minutes](https://www.eurohoops.net/en/euroleague/1168175/european-players-have-to-fight-for-their-euroleague-minutes/).

**Player movement.** How players' ratings travel when they change clubs, within a season and between
seasons, and which kinds of player keep their level in a new system. The model tested a discount for
changing teams and dropped it; the description of what happens is still worth having.

**Comparisons with other European ratings.** FPM next to the other public European impact measures,
on the same next-season test. That would show where they agree, where they part, and which predicts
better. Reading:
Dewandeler, [*Introducing RAPM-EU*](https://kevindewandeler.substack.com/p/introducing-rapm-eu) (2025);
[German Basketball Analytics, xEuPM](https://germanbasketballanalytics.substack.com/p/a-forward-looking-metric-for-european);
[Clutch Data, measuring player impact](https://clutchdata.substack.com/p/off-season-insights-measuring-player);
[HackaStat](https://hackastat.eu/en/home-page-eng/).

## Ideas for the model itself

Each of these would change FPM and would have to pass the same next-season test as everything
already in it.

**Home court that depends on the team.** The regression uses one home-court term for every team; the
evidence says weaker teams gain more at home. Reading: Foteinakis et al. (2026), above.

**A lineup or synergy term.** Pairs or units as extra terms in the regression, pooled hard toward
zero. Reading: Lineup RAPM (2026) and Hypergraph Adjusted Plus-Minus (2024), above.

**A coach term.** The coach as a column next to the players. Reading: Bacco et al. (2024), above.

**Low-minute players.** A formal treatment of players with too few possessions to rate, instead of
padding them toward a role mean. Reading:
[*Representing Low-Minute Players in Regularized Adjusted Plus-Minus*](https://arxiv.org/abs/2608.19454) (2026).

**Win probability as the target.** Rating players by how much they move the chance of winning
rather than the margin, so that a basket in a close finish counts for more than one in a blowout.
Reading: Deshpande & Jensen (2016), above.

**Ratings that drift within a season.** The game-by-game version above, used as the model rather
than as a description. Reading: Fearnhead & Taylor (2011), above.

## Would need data that is not here

- **Tracking data** (positions of all ten players and the ball): possession value as in POINTWISE,
  spatial defence, screens, contests, passes that are not assists. Not public for the EuroLeague.
- **Injury reports:** availability before a game, and the reason for an absence.
- **Domestic league games:** true rest and workload, since most players play two or three games a
  week across competitions.
- **Betting lines:** a market benchmark for any forecast.
- **Other leagues:** translating ratings to and from the EuroCup, domestic leagues or the NBA.
  Reading: [*Nuthin' but a G League*](https://sponet.de/sponet/Record/4097219) (2026).

## One small change that helps several of these

A short table mapping the six players who carry two IDs across their careers to one, so that their
careers are not split. Similar players, career pages, with-or-without-you and the model's own
recency filter would all use it.
