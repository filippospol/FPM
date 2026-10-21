# =============================================================================
# 25_scrape_shots.R  --  per-shot "shot detail" (shot charts / spatial data)
# -----------------------------------------------------------------------------
# The live.euroleague.net "Points" endpoint returns one row PER SHOT, with court
# coordinates and context flags. This is the raw material for shot charts,
# shot-quality / expected-eFG work, and zone splits.
#
# Feed fields (verified identical 2016-17 .. 2023-24):
#   NUM_ANOT, TEAM, ID_PLAYER, PLAYER, ID_ACTION, ACTION, POINTS,
#   COORD_X, COORD_Y, ZONE, FASTBREAK, SECOND_CHANCE, POINTS_OFF_TURNOVER,
#   MINUTE, CONSOLE, POINTS_A, POINTS_B, UTC
#   - COORD_X / COORD_Y: shot location (free throws are -1 / -1, ZONE blank).
#     X is lateral (can be negative), Y is distance from the baseline/basket;
#     raw feed units (~tenths of a metre). Left as-is - normalise in analysis.
#   - ID_ACTION encodes make/miss: *M = made (2FGM/3FGM/FTM), *A / *AB = missed.
#   - MINUTE is the cumulative game minute (1..40 reg, 41+ OT); PERIOD derived.
#   - PLAYER_ID is normalised to the same key as boxscores/PBP/people, so this
#     file JOINS straight onto the rest of the pipeline on PLAYER_ID.
#
# out:
#   data/shots_<scode>.csv   one row per shot (made & missed FGs; made FTs)
#
# No shot files existed before this script, so it simply scrapes every season
# you ask for - it is BOTH the backfill and the going-forward scraper. Safe to
# re-run: it only ever (over)writes shots_<scode>.csv.
#
# Needs fixtures_<scode>.csv (game list + HOME_CODE for HOME_AWAY). Run 10 first.
#   Rscript R/scrape_shots.R            # honours TEST_SCODE in 00_config.R
#   Rscript R/scrape_shots.R E2016      # or a single season
# =============================================================================

suppressMessages({
  library(dplyr); library(purrr); library(stringr)
  library(httr); library(jsonlite); library(glue)
})
source("scrapers/config.R")

`%||%` = function(a, b) {
  if (is.null(a) || length(a) == 0) return(b)
  if (length(a) == 1 && is.atomic(a) && is.na(a)) return(b)
  a
}
.norm_id   = function(x) gsub("\\s+", "", trimws(x))
# "Last, First" -> "First Last", transliterated to plain ASCII Latin
.flip_name = function(x) to_latin(sub("^(.*),\\s*(.*)$", "\\2 \\1", trimws(x)))

# canonical output columns (used for the empty-file header too)
# FIXTURE_ID = game_key(SEASON_CODE, GAME_ID): unique across seasons (codes restart at 1).
SHOT_COLS = c("GAME_ID","FIXTURE_ID","SEASON_CODE","EVENT_NUM","TEAM_CODE","HOME_AWAY",
               "PLAYER_ID","PLAYER","ACTION_CODE","ACTION","SHOT_TYPE","MADE",
               "POINTS","COORD_X","COORD_Y","ZONE","FASTBREAK","SECOND_CHANCE",
               "POINTS_OFF_TURNOVER","MINUTE","PERIOD","CONSOLE",
               "SCORE_A","SCORE_B","UTC")

get_shots = function(game_id, scode) {
  url = glue(EP_SHOTS, gamecode = game_id, scode = scode)
  raw = fromJSON(content(GET(url), "text", encoding = "UTF-8"), simplifyVector = FALSE)
  rows = raw$Rows
  if (is.null(rows) || !length(rows)) return(NULL)   # empty = missing-game placeholder

  out = lapply(rows, function(s) {
    act = toupper(trimws(s$ID_ACTION %||% ""))
    stype = if (startsWith(act, "3")) "3PT"
             else if (startsWith(act, "2")) "2PT"
             else if (startsWith(act, "FT")) "FT" else NA_character_
    mn = suppressWarnings(as.integer(s$MINUTE %||% NA))
    data.frame(
      GAME_ID = as.character(game_id), FIXTURE_ID = game_key(scode, game_id),
      SEASON_CODE = scode,
      EVENT_NUM = suppressWarnings(as.integer(s$NUM_ANOT %||% NA)),
      TEAM_CODE = toupper(trimws(s$TEAM %||% "")),
      PLAYER_ID = .norm_id(s$ID_PLAYER %||% ""),
      PLAYER    = .flip_name(s$PLAYER %||% ""),
      ACTION_CODE = act, ACTION = trimws(s$ACTION %||% ""),
      SHOT_TYPE = stype,
      MADE   = as.integer(grepl("M$", act)),      # *M = made, *A / *AB = missed
      POINTS = suppressWarnings(as.integer(s$POINTS %||% 0)),
      COORD_X = suppressWarnings(as.integer(s$COORD_X %||% NA)),
      COORD_Y = suppressWarnings(as.integer(s$COORD_Y %||% NA)),
      ZONE = trimws(s$ZONE %||% ""),
      FASTBREAK           = suppressWarnings(as.integer(s$FASTBREAK %||% 0)),
      SECOND_CHANCE       = suppressWarnings(as.integer(s$SECOND_CHANCE %||% 0)),
      POINTS_OFF_TURNOVER = suppressWarnings(as.integer(s$POINTS_OFF_TURNOVER %||% 0)),
      MINUTE = mn,
      PERIOD = if (is.na(mn)) NA_integer_ else as.integer((mn - 1L) %/% 10L + 1L),
      CONSOLE = trimws(s$CONSOLE %||% ""),
      SCORE_A = suppressWarnings(as.integer(s$POINTS_A %||% NA)),
      SCORE_B = suppressWarnings(as.integer(s$POINTS_B %||% NA)),
      UTC = trimws(s$UTC %||% ""),
      stringsAsFactors = FALSE)
  })
  bind_rows(out)
}

scrape_shots = function(scode) {
  fxf = fx_path(scode)
  if (!file.exists(fxf)) {
    message(glue("{scode}: no fixtures file ({fxf}) - run 10_scrape_fixtures.R first; skipping"))
    return(invisible(NULL))
  }
  fx = read.csv(fxf, stringsAsFactors = FALSE)
  home = setNames(toupper(fx$HOME_CODE), as.character(fx$GAME_ID))  # game -> home acronym
  all = list()
  for (i in seq_len(nrow(fx))) {
    Sys.sleep(PAUSE_S)
    sh = tryCatch(get_shots(fx$GAME_ID[i], scode), error = function(e) {
      message(glue("  shots {scode} g{fx$GAME_ID[i]} failed: {conditionMessage(e)}")); NULL })
    if (is.null(sh)) next
    all[[length(all) + 1]] = sh
  }
  shots = bind_rows(all)

  if (nrow(shots)) {
    hc = unname(home[shots$GAME_ID])                 # home acronym for each shot's game
    shots$HOME_AWAY = ifelse(is.na(hc), NA_character_,
                              ifelse(shots$TEAM_CODE == hc, "HOME", "AWAY"))
    shots = shots[, SHOT_COLS]
  } else {
    shots = setNames(data.frame(matrix(nrow = 0, ncol = length(SHOT_COLS))), SHOT_COLS)
  }

  write.csv(shots, shots_path(scode), row.names = FALSE)
  ng = length(unique(shots$GAME_ID))
  message(glue("{scode}: {nrow(shots)} shot rows across {ng} games -> {shots_path(scode)}"))
}

if (sys.nframe() == 0) {
  args = commandArgs(trailingOnly = TRUE)
  scodes = if (length(args)) args else if (!is.na(TEST_SCODE)) TEST_SCODE else SEASONS$scode
  for (sc in scodes) scrape_shots(sc)
}
