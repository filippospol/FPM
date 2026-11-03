# Data

One file per season, `el_E2007.rds` to `el_E2026.rds`, covering 2007-08 to the season in progress. The
season code is the year the season starts, so `E2025` is 2025-26. Each file is an R list with seven
tables, scraped from the EuroLeague's public feeds and kept as data frames:

| Table | One row per | What it holds |
|---|---|---|
| `fixtures` | game | date, round, phase (`RS` regular season, `TS` the old Top 16, then playoffs and Final Four), home and away codes, venue, attendance, referees |
| `boxscores` | player and game | minutes, shooting, rebounds, assists, steals, turnovers, blocks, fouls, plus/minus, PIR (`VALUATION`) |
| `team_boxscores` | team and game | the same lines for the team, with the opponent code |
| `coaches` | team and game | the head coach |
| `shots` | field goal attempt | shooter, type, made or missed, zone and court coordinates, game clock |
| `people` | person and season | players and coaches with birth date, height, listed position and country |
| `pbp` | play | the play-by-play log with quarter, clock, play type and the player involved |

Players are identified by `PLAYER_ID` (the `P` prefix is kept) and teams by their three-letter code.
Read a season with `el <- readRDS("data/el_E2025.rds")`, then `el$boxscores` and so on.

## Stints

`stints/stints_E2007.rds` to `stints/stints_E2026.rds` are built from the play-by-play by
`stints/build_stints.R`. A stint is a stretch of a game in which the ten players on the floor do not
change. Each row holds the home five (`H1` to `H5`), the away five (`A1` to `A5`), seconds played,
possessions and points for each side, the full counting box for each side, and `OK`, which is `TRUE`
when both lineups were exactly five players. Possessions are counted event by event with the FIBA
rules, not estimated from box totals. The model reads only the `OK` rows from the regular season and the
old Top 16.

## Coverage

Every season holds the games its format implies. Two seasons are short for real reasons: 2019-20
stopped at 252 of 306 games, and 2021-22 ended with 278 after the Russian clubs left in February.
2007-08 is the weakest season in the play-by-play, with 93% of stints clean against 99% or better from
2008-09 on. Shot detail is complete from 2015-16; before that the shot feed holds roughly half of the
field goals.

## Other ways to get this data

The same feeds are wrapped by several open packages. None of them is used here, but they are the
quickest route for anyone who wants to rebuild or cross-check the tables above.

- Python: [`euroleague_api`](https://github.com/giasemidis/euroleague_api) (box scores, play-by-play, shots, standings, schedules) and the EuroLeague wrappers in [`sportsdataverse-py`](https://github.com/sportsdataverse/sportsdataverse-py/pull/710).
- R: [`eurolig`](https://github.com/solmos/eurolig) (play-by-play with the five on the floor, shot locations), [`euroleagueR`](https://github.com/JaseZiv/euroleagueR) and [`BAwiR`](https://cran.r-project.org/package=BAwiR) on CRAN (box scores and roster biographies).
- Static dumps: [play-by-play 2007-2020](https://www.kaggle.com/datasets/efehandanisman/euroleague-play-by-play-data-20072020) and a [general collection](https://www.kaggle.com/datasets/babissamothrakis/euroleague-datasets) on Kaggle.
- A validated warehouse: [`euroleague-analytics`](https://github.com/egemeny13/euroleague-analytics), with possessions counted from play-by-play, lineup stats and shot coordinates for the latest seasons.
