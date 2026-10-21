# =============================================================================
# scrape_incremental.R  --  incremental update of ONE season's RDS bundle
# -----------------------------------------------------------------------------
# For the daily GitHub Action on the CURRENT season. Instead of re-scraping the
# whole year, it:
#   1. loads the committed data/el_<scode>.rds (if present),
#   2. refreshes that season's fixtures (one request) to see finished games,
#   3. fetches ONLY the games not already stored (box + team box + coaches + pbp
#      + shots), reusing the per-game fetchers from the scrapers,
#   4. refreshes the people roster,
#   5. merges everything back and rewrites data/el_<scode>.rds.
#
# The per-season file holds exactly one season, so fixtures/people are replaced
# wholesale and the per-game tables get new games appended (idempotent by
# FIXTURE_ID). Needs network to the EuroLeague hosts.
#
#   Rscript scrapers/scrape_incremental.R            # current season (TEST_SCODE)
#   Rscript scrapers/scrape_incremental.R E2026
# =============================================================================

source("scrapers/config.R")
source("scrapers/scrape_fixtures.R")   # scrape_fixtures()
source("scrapers/scrape_boxscores.R")  # get_boxscore(), finalize_team_box(), .apply_canon_names()
source("scrapers/scrape_shots.R")      # get_shots(), SHOT_COLS
source("scrapers/scrape_people.R")     # scrape_people()
source("scrapers/scrape_pbp.R")        # get_pbp()
source("scrapers/merge_to_rds.R")      # append/replace helpers + season_rds_path
suppressMessages(library(dplyr))

scrape_incremental = function(scode = NULL) {
  if (is.null(scode)) scode = if (!is.na(TEST_SCODE)) TEST_SCODE else tail(SEASONS$scode, 1)
  srow = SEASONS[SEASONS$scode == scode, ]
  if (!nrow(srow)) stop("unknown scode '", scode, "' - add it to SEASONS in scrapers/config.R")
  season = srow$season[1]

  # 1) load existing bundle (or start empty on the first ever run)
  el = if (file.exists(season_rds_path(scode))) readRDS(season_rds_path(scode)) else list()
  existing_ids = character(0)
  if (!is.null(el$boxscores) && nrow(el$boxscores))
    existing_ids = unique(as.character(el$boxscores$GAME_ID))

  # 2) refresh fixtures (finished games only) -> data-raw/fixtures_<scode>.csv
  scrape_fixtures(scode)
  fx = read.csv(fx_path(scode), stringsAsFactors = FALSE)
  finished_ids = as.character(fx$GAME_ID)
  new_ids = setdiff(finished_ids, existing_ids)
  message(sprintf("%s: %d finished, %d already stored, %d new game(s)",
                  scode, length(finished_ids), length(existing_ids), length(new_ids)))

  # 3) fetch ONLY the new games (per-game fetchers; polite PAUSE_S between calls)
  if (length(new_ids)) {
    home = setNames(toupper(fx$HOME_CODE), as.character(fx$GAME_ID))   # for shots HOME_AWAY
    np = nt = nc = nsh = npb = list()
    for (gid in new_ids) {
      Sys.sleep(PAUSE_S)
      bs = tryCatch(get_boxscore(gid, scode), error = function(e) { message("  box ", gid, ": ", conditionMessage(e)); NULL })
      if (!is.null(bs)) { np[[length(np)+1]] = bs$players; nt[[length(nt)+1]] = bs$teams; nc[[length(nc)+1]] = bs$coaches }
      Sys.sleep(PAUSE_S)
      mu = fx$MATCHUP[fx$GAME_ID == gid][1]
      pb = tryCatch(get_pbp(gid, scode, season, mu), error = function(e) { message("  pbp ", gid, ": ", conditionMessage(e)); NULL })
      if (!is.null(pb)) npb[[length(npb)+1]] = pb
      Sys.sleep(PAUSE_S)
      sh = tryCatch(get_shots(gid, scode), error = function(e) { message("  shots ", gid, ": ", conditionMessage(e)); NULL })
      if (!is.null(sh)) nsh[[length(nsh)+1]] = sh
    }

    players  = .apply_canon_names(bind_rows(np), fx)
    coaches  = .apply_canon_names(bind_rows(nc), fx)
    team_box = finalize_team_box(bind_rows(nt), fx, scode)
    pbp      = bind_rows(npb)
    shots    = bind_rows(nsh)
    if (nrow(shots)) {
      hc = unname(home[as.character(shots$GAME_ID)])
      shots$HOME_AWAY = ifelse(is.na(hc), NA_character_, ifelse(shots$TEAM_CODE == hc, "HOME", "AWAY"))
      shots = shots[, SHOT_COLS]
    }

    new_fids = game_key(scode, new_ids)   # idempotent: drop these FIXTURE_IDs then re-append
    el$boxscores      = append_rows(drop_fixtures(el$boxscores,      new_fids), players)
    el$team_boxscores = append_rows(drop_fixtures(el$team_boxscores, new_fids), team_box)
    el$coaches        = append_rows(drop_fixtures(el$coaches,        new_fids), coaches)
    el$pbp            = append_rows(drop_fixtures(el$pbp,            new_fids), pbp)
    el$shots          = append_rows(drop_fixtures(el$shots,          new_fids), shots)
  }

  # 4) fixtures + people are one-season & cheap: replace them wholesale
  el$fixtures = fx
  scrape_people(scode)
  ppl = read.csv(people_path(scode), stringsAsFactors = FALSE)
  if (nrow(ppl)) el$people = ppl

  # 5) save the bundle
  el = el[!vapply(el, is.null, logical(1))]
  saveRDS(el, season_rds_path(scode), compress = "xz")
  message(sprintf("wrote %s  [%s]", season_rds_path(scode), paste(names(el), collapse = ", ")))
  invisible(el)
}

if (sys.nframe() == 0) {
  args = commandArgs(trailingOnly = TRUE)
  scrape_incremental(if (length(args)) args[1] else NULL)
}
