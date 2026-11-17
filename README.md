# Fair Plus-Minus (FPM)

**A EuroLeague player impact metric, with the data and the reasoning behind it out in the open.**

Fair Plus-Minus estimates how much a player helps his team outscore the opponent per 100 possessions,
once his teammates and the opposition are accounted for. One two-way number, built for the EuroLeague
rather than borrowed from the NBA, and tuned to measure how good a player is *now*.

The live leaderboard, the player pages and the full write-up are at
**[filippospol.github.io/FPM](https://filippospol.github.io/FPM)**.

## What's in this repo

This is the open side of the project: the data, the possession-level stints, the scrapers that build
them, and the documentation. The engine that turns the data into the ratings lives in a separate private
repo and pushes only the finished numbers back here.

- **`data/`**: one file per season, 2007-08 to the season in progress, scraped from the EuroLeague's
  public feeds. Each season is an R list of seven tables: fixtures (with venue, attendance and
  referees), player and team box scores, coaches, every shot with its zone and coordinates, player and
  coach biographies, and the full play-by-play. `data/data-readme.md` describes every column.
- **`stints/`**: the play-by-play cut into stints, each a stretch where the ten players on the floor do
  not change, with possessions counted event by event rather than estimated from box totals. This is
  what the model reads.
- **`scrapers/`**: the R scripts that pull and clean the feeds, so anyone can rebuild the data or carry
  it forward.
- **`docs/`**: the method write-up and the leaderboard site.

As far as we can tell, nobody had put EuroLeague possession-level data, the ratings, and the reasoning
behind them out in the open in one place before. That is the point of the repo. Take the data anywhere
you like.

## Why "fair"

Plus-minus on its own is unfair: it credits a player for whatever his four teammates did. FPM separates
him from the specific teammates and opponents he shared the floor with, and then checks the box score
against the scoreboard instead of trusting either one. The box score is steady but blind. The scoreboard
sees everything but lies. Laying one over the other is where the "fair" comes from.

## How it works

FPM is a regularized on/off rating (RAPM) anchored to an era-neutral, position-aware box-score prior.
The box score sets what to expect from a player, the scoreboard says what actually happened, and the
blend is steadier than either on its own. A few things worth knowing:

- **Offense and defense split out**, as O-FPM and D-FPM.
- **The on/off counts real points, not expected ones.** Valuing every shot at league rates was tried and
  predicted the next season worse, so shot-making is treated as a skill and the box prior and the shrink
  are left to damp the luck.
- **Every season is judged on its own**, so a 2009 player and a 2024 one meet on equal footing even
  though the three-point line and the pace moved in between.
- **An aging curve and a recency filter** keep the number tracking how a player is doing now, with older
  seasons fading and the current season loosening as games pile up.

Every setting is chosen by how well it predicts the following season, not by hand, and the tests that
choose them sit next to the model.

## Reading the number

FPM is in **points per 100 possessions** relative to an average rotation player, so 0 is average. One
point of FPM is worth about one point per 100 of a lineup's margin the next season. A season runs from
roughly −7 to +8. Around +2.5 or better is a top-20 player, and the best reach +6 or +7.

## The write-up

- [How FPM works, in plain terms](docs/about/fpm-explained.md)
- [Design notes, sources and limitations](docs/about/fpm-design.md)
- [Scope](docs/about/fpm-scope.md) · [Future work](docs/about/fpm-future-work.md) · [Acknowledgements](docs/about/fpm-acknowledgements.md)
