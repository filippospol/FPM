# =============================================================================
# 40_scrape_pbp.R  --  EuroLeague play-by-play scraper (multi-season)
# -----------------------------------------------------------------------------
# Generalised from Filippos Polyzos's EL-scraper.R. Writes one file per season:
#   data/pbp_<scode>.csv   (input to 50_build_stints.R)
#
# The PlayByPlay payload splits events into one array per period
# (FirstQuarter..ForthQuarter -- the feed's own spelling -- plus ExtraTime*),
# stacked here into one long table tagged with QUARTER. Needs fixtures_<scode>.csv
# (run 10 first). Game codes restart at 1 each season -> every row tagged SEASON
# and FIXTURE_ID (= game_key(scode, GAME_ID), unique across seasons).
# =============================================================================

suppressMessages({
  library(dplyr); library(purrr); library(tidyr); library(stringr)
  library(httr); library(jsonlite); library(glue)
})
source("scrapers/config.R")

quarter_fields = names(QORD)

get_pbp = function(game_id, scode, season, matchup) {
  url = glue(EP_PBP, gamecode = game_id, scode = scode)
  raw = fromJSON(content(GET(url), "text", encoding = "UTF-8"))
  # keep only period arrays that actually have events
  parts = quarter_fields %>% keep(~ is.data.frame(raw[[.x]]) && nrow(raw[[.x]]) > 0)
  if (length(parts) == 0) return(NULL)                 # no PBP for this game (forfeit / not recorded)
  tb = suppressWarnings(
    parts %>%
      map_dfr(~ as_tibble(raw[[.x]]) %>% mutate(QUARTER = .x)) %>%
      janitor::clean_names("all_caps") %>%
      mutate(across(where(is.character), str_squish),
             GAME_ID = game_id, FIXTURE_ID = game_key(scode, game_id),
             SEASON = season, LEAGUE = LEAGUE, MATCHUP = matchup)
  )
  # transliterate "Last, First" -> "First Last" ONLY if a PLAYER column exists
  # (some odd/empty games have no PLAYER field; guard so the game doesn't crash)
  if ("PLAYER" %in% names(tb))
    tb$PLAYER = to_latin(str_replace(tb$PLAYER, "^(.*),\\s*(.*)$", "\\2 \\1"))
  tb %>%
    select(any_of(c("GAME_ID","FIXTURE_ID","SEASON","LEAGUE","MATCHUP","QUARTER",
                    "NUMBEROFPLAY","MINUTE","MARKERTIME",
                    "CODETEAM","TEAM","PLAYER","PLAYER_ID","DORSAL",
                    "PLAYTYPE","PLAYINFO","POINTS_A","POINTS_B","COMMENT")))
}

# Zip a csv into <name>.zip (flat, single member). Uses the `zip` package
# (pure C, cross-platform, no external tool) and falls back to base utils::zip.
zip_csv = function(csv_path) {
  zip_path = sub("\\.csv$", ".zip", csv_path)
  if (file.exists(zip_path)) unlink(zip_path)
  ok = FALSE
  if (requireNamespace("zip", quietly = TRUE)) {
    try(zip::zip(zipfile = zip_path, files = basename(csv_path),
                 root = dirname(csv_path)), silent = TRUE)
    ok = file.exists(zip_path)
  }
  if (!ok) {                                   # fallback: base R (needs a zip binary on PATH)
    old = setwd(dirname(csv_path)); on.exit(setwd(old))
    try(utils::zip(basename(zip_path), basename(csv_path), flags = "-j9Xq"), silent = TRUE)
    ok = file.exists(file.path(dirname(csv_path), basename(zip_path)))
  }
  if (ok) zip_path else NA_character_
}

# ZIP_PBP: write pbp_<scode>.zip (the zipped csv) and delete the raw csv to save
# disk (PBP is the large file). Set to FALSE to keep a plain csv instead.
ZIP_PBP = TRUE

scrape_pbp = function(scode, zip_output = ZIP_PBP) {
  srow = SEASONS[SEASONS$scode == scode, ]
  season = srow$season[1]
  fx = read.csv(fx_path(scode), stringsAsFactors = FALSE)
  all_pbp = vector("list", nrow(fx))
  for (i in seq_len(nrow(fx))) {
    Sys.sleep(PAUSE_S)
    all_pbp[[i]] = tryCatch(
      get_pbp(fx$GAME_ID[i], scode, season, fx$MATCHUP[i]),
      error = function(e) { message(glue("  pbp {scode} g{fx$GAME_ID[i]} failed: {conditionMessage(e)}")); NULL })
  }
  pbp = bind_rows(all_pbp)
  csv = pbp_path(scode)
  write.csv(pbp, csv, row.names = FALSE)
  if (zip_output) {
    z = zip_csv(csv)
    if (!is.na(z)) {
      unlink(csv)                              # keep only the zip
      message(glue("{season}: wrote {z}  ({nrow(pbp)} rows, csv zipped)"))
    } else {
      message(glue("{season}: wrote {csv}  ({nrow(pbp)} rows) - zip step unavailable, kept csv"))
    }
  } else {
    message(glue("{season}: wrote {csv}  ({nrow(pbp)} rows)"))
  }
}

if (sys.nframe() == 0) {
  scodes = if (!is.na(TEST_SCODE)) TEST_SCODE else SEASONS$scode
  for (sc in scodes) scrape_pbp(sc)
}
