# Acknowledgements

FPM would not be a thing if it wasn't for Nathan Walker's
[OpenRAPM](https://github.com/bbstats/openrapm). OpenRAPM puts out NBA ratings going back to
1996-97, and it doesn't stop at the numbers. The code is there, the data pipeline is there, the
parameters are there, and so is a log of what was tried and didn't work.

That's the part that stuck. Most impact metrics show up as a leaderboard and a methods page, and
you're left to trust whatever happens in between. OpenRAPM does the whole thing out in the open, so
anyone can check it, rerun it, or take it somewhere new. FPM tries to do the same for the EuroLeague.
The play-by-play data, the stints and the documentation all live in the
[repository](https://github.com/filippospol/FPM), and the model gets tuned on how well it predicts
the next season.

Of course, there is so much work online that FPM was also inspired from. Metrics such as DARKO, PIPM,
LEBRON etc. obviously influenced the framework and methodology of this metric.

There's a gap it fills, too. People have done good RAPM and impact work on European basketball, but
what's out there publicly tends to be a write-up and a final set of numbers. As far as public sources
go, nobody has put EuroLeague possession-level data, the ratings and the reasoning behind them out in
the open in one place.
