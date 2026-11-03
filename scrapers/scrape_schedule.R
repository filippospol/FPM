# =============================================================================
# scrape_schedule.R  --  the full season schedule, played and still to play
# -----------------------------------------------------------------------------
# Same games feed as the fixtures, without the finished-games filter, kept lean.
# out: data-raw/schedule_<scode>.csv  one row per game of the season:
#   identity : FIXTURE_ID, GAME_ID, SEASON, SEASON_CODE
#   schedule : GAME_DATE, GAME_UTC, ROUND, PHASE, GROUP_NAME
#   teams    : HOME_CODE, AWAY_CODE, HOME_NAME, AWAY_NAME
#   venue    : VENUE_CODE, VENUE_NAME, VENUE_ADDRESS
#   state    : STATUS (as the feed gives it), PLAYED (TRUE once it has a result)
# Dates of games still to play are the feed's current plan and can move; the
# table is replaced wholesale on every run, so it always holds the latest plan.
# Only the season in progress is scraped (scrape_incremental.R calls this); the
# historical bundles do not need it, since every game in them has been played.
# Needs scrapers/config.R and scrape_fixtures.R (fetch_games_feed).
#
#   Rscript scrapers/scrape_schedule.R          # current season (TEST_SCODE)
#   Rscript scrapers/scrape_schedule.R E2026
# =============================================================================

source("scrapers/config.R")
if (!exists("fetch_games_feed")) source("scrapers/scrape_fixtures.R")
suppressMessages({ library(dplyr); library(glue) })

get_schedule = function(season, scode) {
  fetch_games_feed(scode) %>%
    mutate(SEASON = season, SEASON_CODE = scode,
           GAME_DATE  = as.Date(substr(DATE, 1, 10)),
           GAME_UTC   = as.character(DATE),
           FIXTURE_ID = game_key(scode, CODE),
           STATUS     = as.character(STATUS),
           PLAYED     = STATUS == "result") %>%
    select(FIXTURE_ID, GAME_ID = CODE, SEASON, SEASON_CODE,
           GAME_DATE, GAME_UTC, ROUND, PHASE, GROUP_NAME,
           HOME_CODE, AWAY_CODE, any_of(c("HOME_NAME", "AWAY_NAME")),
           VENUE_CODE, VENUE_NAME, VENUE_ADDRESS, STATUS, PLAYED) %>%
    arrange(GAME_DATE, GAME_ID)
}

scrape_schedule = function(scode = NULL) {
  if (is.null(scode)) scode = if (!is.na(TEST_SCODE)) TEST_SCODE else tail(SEASONS$scode, 1)
  srow = SEASONS[SEASONS$scode == scode, ]
  if (!nrow(srow)) stop("unknown scode '", scode, "' - add it to SEASONS in scrapers/config.R")
  sch = get_schedule(srow$season[1], scode)
  write.csv(sch, sched_path(scode), row.names = FALSE)
  message(glue("{srow$season[1]}: schedule {nrow(sch)} games, {sum(sch$PLAYED)} played -> {sched_path(scode)}"))
  invisible(sch)
}

if (sys.nframe() == 0) {
  args = commandArgs(trailingOnly = TRUE)
  scrape_schedule(if (length(args)) args[1] else NULL)
}
