# =============================================================================
# 10_scrape_fixtures.R  --  finished-game fixtures (+ game context) per season
# -----------------------------------------------------------------------------
# out: data/fixtures_<scode>.csv  one row per finished game:
#   identity : FIXTURE_ID, GAME_ID, SEASON, SEASON_CODE, LEAGUE, MATCHUP
#   schedule : GAME_DATE, GAME_UTC (tip-off timestamp, UTC), ROUND, PHASE, GROUP_NAME
#              PHASE = RS (regular season) / PI (play-in) / PO (playoffs) / FF (Final Four)
#   teams    : HOME_CODE, AWAY_CODE, HOME_NAME, AWAY_NAME
#   venue    : VENUE_CODE, VENUE_NAME, VENUE_CAPACITY, VENUE_ADDRESS
#   crowd    : AUDIENCE (real attendance), AUDIENCE_CONFIRMED
#   officials: REF1_/REF2_/REF3_ {CODE, NAME, COUNTRY}  (crew order as in the feed)
# The context fields come from the same games feed as before (they were simply not
# kept); they power phase filters (e.g. regular-season-only MVP ladder), and
# referee, crowd/home-court and schedule/travel studies. Fields the feed omits for
# a season are written as NA so the column set is identical every season.
# Game codes restart at 1 each season; downstream keys on FIXTURE_ID
# (= game_key(SEASON_CODE, GAME_ID)).
# =============================================================================

suppressMessages({
  library(dplyr); library(purrr); library(stringr)
  library(httr); library(jsonlite); library(glue); library(janitor)
})
source("scrapers/config.R")

# first existing column among candidate names, else a vector of NA
.pick_col = function(df, cands) {
  hit = intersect(cands, names(df))
  if (length(hit)) df[[hit[1]]] else rep(NA, nrow(df))
}
# "ROCHA, FERNANDO" -> "FERNANDO ROCHA" (plain ASCII Latin)
.flip_ref = function(x) to_latin(sub("^(.*),\\s*(.*)$", "\\2 \\1", trimws(x)))

# The feed carries referees as an array per game (code, name, number, alias,
# country{code,name}). Flatten to REF1..REF3 x {CODE, NAME, COUNTRY}, ordered by
# the crew number. Robust to the country arriving nested or pre-flattened.
.referee_cols = function(refs, n = 3) {
  cols = paste0("REF", rep(seq_len(n), each = 3), c("_CODE", "_NAME", "_COUNTRY"))
  one = function(r) {
    v = setNames(rep(NA_character_, length(cols)), cols)
    if (is.data.frame(r) && nrow(r)) {
      if ("number" %in% names(r)) r = r[order(suppressWarnings(as.integer(r$number))), , drop = FALSE]
      ctry = if ("country" %in% names(r) && is.data.frame(r$country)) r$country$code
             else if ("country.code" %in% names(r)) r[["country.code"]] else rep(NA, nrow(r))
      for (k in seq_len(min(n, nrow(r)))) {
        v[paste0("REF", k, "_CODE")]    = as.character(r$code[k])
        v[paste0("REF", k, "_NAME")]    = .flip_ref(r$name[k])
        v[paste0("REF", k, "_COUNTRY")] = as.character(ctry[k])
      }
    }
    v
  }
  if (is.null(refs)) return(as.data.frame(matrix(NA_character_, 0, length(cols),
                                                 dimnames = list(NULL, cols))))
  as.data.frame(do.call(rbind, lapply(refs, one)), stringsAsFactors = FALSE)
}

get_fixtures = function(season, scode) {
  url = glue(EP_FIXTURES, COMP = COMP, scode = scode)
  res = GET(url, query = list(limit = 600))          # 600 > any season's game count
  stop_for_status(res)
  dat = fromJSON(content(res, "text", encoding = "UTF-8"), flatten = TRUE)
  g = dat$data
  refs = .referee_cols(g$referees)
  if (!nrow(refs)) refs = .referee_cols(vector("list", nrow(g)))
  flat = g %>%
    as_tibble() %>%
    select(where(~ !is.list(.))) %>%
    clean_names("all_caps") %>%
    bind_cols(refs)

  # context columns, stable across seasons (NA when the feed omits one)
  flat$ROUND          = suppressWarnings(as.integer(.pick_col(flat, c("ROUND_ROUND", "ROUND"))))
  flat$PHASE          = toupper(as.character(.pick_col(flat, c("PHASE_TYPE_CODE", "PHASE_TYPE"))))
  flat$GROUP_NAME     = as.character(.pick_col(flat, c("GROUP_NAME", "GROUP_RAW_NAME")))
  flat$VENUE_CODE     = as.character(.pick_col(flat, "VENUE_CODE"))
  flat$VENUE_NAME     = to_latin(as.character(.pick_col(flat, "VENUE_NAME")))
  flat$VENUE_CAPACITY = suppressWarnings(as.integer(.pick_col(flat, "VENUE_CAPACITY")))
  flat$VENUE_ADDRESS  = to_latin(gsub("\\s*<br\\s*/?>\\s*", ", ", as.character(.pick_col(flat, "VENUE_ADDRESS"))))
  flat$AUDIENCE       = suppressWarnings(as.integer(.pick_col(flat, "AUDIENCE")))
  flat$AUDIENCE_CONFIRMED = as.logical(.pick_col(flat, "AUDIENCE_CONFIRMED"))

  flat %>%
    filter(STATUS == "result") %>%                    # finished games only
    mutate(SEASON = season, SEASON_CODE = scode, LEAGUE = LEAGUE,
           GAME_DATE  = as.Date(substr(DATE, 1, 10)),
           GAME_UTC   = as.character(DATE),
           FIXTURE_ID = game_key(scode, CODE),          # unique across seasons
           MATCHUP    = paste0(GAME_DATE, ", ", HOME_CODE, " vs ", AWAY_CODE)) %>%
    select(FIXTURE_ID, GAME_ID = CODE, SEASON, SEASON_CODE, LEAGUE,
           GAME_DATE, GAME_UTC, ROUND, PHASE, GROUP_NAME, MATCHUP,
           HOME_CODE, AWAY_CODE, any_of(c("HOME_NAME","AWAY_NAME")),
           VENUE_CODE, VENUE_NAME, VENUE_CAPACITY, VENUE_ADDRESS,
           AUDIENCE, AUDIENCE_CONFIRMED,
           starts_with("REF1_"), starts_with("REF2_"), starts_with("REF3_")) %>%
    arrange(GAME_ID)
}

# Team lookup per season: code => full name => acronym.
# Derived from the fixtures/games feed itself (which carries team codes AND
# names), so there is no separate /teams endpoint to 404. If the games feed has
# no *_NAME column in a given season, TEAM_NAME falls back to the code.
derive_teams = function(fx, season, scode) {
  hn = if ("HOME_NAME" %in% names(fx)) fx$HOME_NAME else fx$HOME_CODE
  an = if ("AWAY_NAME" %in% names(fx)) fx$AWAY_NAME else fx$AWAY_CODE
  d = rbind(
    data.frame(TEAM_CODE = fx$HOME_CODE, TEAM_NAME = hn, stringsAsFactors = FALSE),
    data.frame(TEAM_CODE = fx$AWAY_CODE, TEAM_NAME = an, stringsAsFactors = FALSE))
  d = d[!is.na(d$TEAM_CODE) & d$TEAM_CODE != "", ]
  d = d[!duplicated(d$TEAM_CODE), ]
  d = d[order(d$TEAM_CODE), ]
  data.frame(SEASON = season, SCODE = scode,
             TEAM_CODE = d$TEAM_CODE, TEAM_NAME = to_latin(d$TEAM_NAME),
             TEAM_ACRONYM = d$TEAM_CODE, stringsAsFactors = FALSE)
}

scrape_fixtures = function(scodes = NULL) {
  rows = if (is.null(scodes)) SEASONS else SEASONS[SEASONS$scode %in% scodes, ]
  for (i in seq_len(nrow(rows))) {
    fx = get_fixtures(rows$season[i], rows$scode[i])
    write.csv(fx, fx_path(rows$scode[i]), row.names = FALSE)
    message(glue("{rows$season[i]}: {nrow(fx)} finished games -> {fx_path(rows$scode[i])}"))
    tm = derive_teams(fx, rows$season[i], rows$scode[i])
    tp = file.path(DATA_DIR, paste0("teams_", rows$scode[i], ".csv"))
    write.csv(tm, tp, row.names = FALSE)
    message(glue("  {nrow(tm)} teams -> {tp}"))
  }
}

if (sys.nframe() == 0) {
  scodes = if (!is.na(TEST_SCODE)) TEST_SCODE else SEASONS$scode
  scrape_fixtures(scodes)
}
