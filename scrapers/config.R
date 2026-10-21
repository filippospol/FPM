# =============================================================================
# config.R  --  shared configuration for the EuroLeague scraper (FPM)
# -----------------------------------------------------------------------------
# Sourced by every stage. Edit the `SEASONS` table to control what gets scraped
# and pooled. Game codes restart at 1 each season, so everything downstream is
# keyed on SEASON + GAME_ID.
#
# COVERAGE NOTE: scope is 2016-17 .. 2026-27. Play-by-play exists from 2007-08,
# but the box-score Coach field is only populated from 2016-17 onward (empty in
# the feed before that), so starting at 2016-17 keeps PLAYER and COACH data on
# the same span. To go back further for players only, add the older seasons here
# (coaches will be blank for them) - PBP is reliable back to 2007-08 (E2007).
# =============================================================================

# ----- what to scrape / pool -------------------------------------------------
# One row per season. scode is the EuroLeague season code: "E" + start year.
SEASONS = data.frame(
  season = c("2016-17","2017-18","2018-19","2019-20","2020-21",
             "2021-22","2022-23","2023-24","2024-25","2025-26",
             "2026-27"),
  scode  = c("E2016","E2017","E2018","E2019","E2020",
             "E2021","E2022","E2023","E2024","E2025",
             "E2026"),
  stringsAsFactors = FALSE
)

# The CURRENT season - used by the incremental run and as the single-season test.
# Set to NA to make a full run (run_scrape_all.R) scrape every season in SEASONS.
TEST_SCODE = "E2026"

LEAGUE   = "Euroleague"
COMP     = "E"            # competition letter (E = EuroLeague, U = EuroCup)

# ----- endpoints -------------------------------------------------------------
# Reachable from a normal machine / network and from GitHub-hosted runners;
# some sandboxes block them.
EP_FIXTURES = "https://feeds.incrowdsports.com/provider/euroleague-feeds/v2/competitions/{COMP}/seasons/{scode}/games"
EP_BOXSCORE = "https://live.euroleague.net/api/Boxscore?gamecode={gamecode}&seasoncode={scode}"
EP_PBP      = "https://live.euroleague.net/api/PlayByPlay?gamecode={gamecode}&seasoncode={scode}"
# Shot detail ("Points"): one row per shot with court coordinates (COORD_X/COORD_Y),
# zone, make/miss (in ID_ACTION), and context flags (fastbreak / second chance /
# points off turnover). Same host/auth as box + PBP. Schema is stable 2016-26.
EP_SHOTS    = "https://live.euroleague.net/api/Points?gamecode={gamecode}&seasoncode={scode}"
# People / bios (birthdate -> age). Returns ALL people for the season (players,
# coaches, staff) with the role in `type`/`typeName`; we filter in R. Same
# incrowd provider as fixtures (proven reachable). NB: no personType query param
# and NOT the v3 path - that combination returns HTTP 400.
EP_PEOPLE   = "https://feeds.incrowdsports.com/provider/euroleague-feeds/v2/competitions/{COMP}/seasons/{scode}/people"

PAUSE_S = 1               # polite delay between game requests (host is rate-limited)

# ----- paths -----------------------------------------------------------------
# Raw per-season scraped CSVs are INTERMEDIATE; the committed artifact is one RDS
# bundle per season (el_<scode>.rds). So CSVs -> RAW_DIR, RDS -> RDS_DIR. In the
# GitHub Action only RDS_DIR/*.rds is committed, so RAW_DIR need never be tracked.
RAW_DIR  = "data-raw"     # intermediate per-season scraped CSVs (not committed)
RDS_DIR  = "data"         # committed per-season RDS bundles (el_<scode>.rds)
OUT_DIR  = "out"          # model outputs (unused by the scraper)
DATA_DIR = RAW_DIR        # back-compat alias: all CSV path helpers write to RAW_DIR
dir.create(RAW_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(RDS_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)

fx_path  = function(scode) file.path(DATA_DIR, paste0("fixtures_", scode, ".csv"))
box_path = function(scode) file.path(DATA_DIR, paste0("boxscores_", scode, ".csv"))
team_box_path = function(scode) file.path(DATA_DIR, paste0("team_boxscores_", scode, ".csv"))
coach_path   = function(scode) file.path(DATA_DIR, paste0("coaches_", scode, ".csv"))
pbp_path = function(scode) file.path(DATA_DIR, paste0("pbp_", scode, ".csv"))
pbp_zip_path = function(scode) file.path(DATA_DIR, paste0("pbp_", scode, ".zip"))
shots_path = function(scode) file.path(DATA_DIR, paste0("shots_", scode, ".csv"))
people_path  = function(scode) file.path(DATA_DIR, paste0("people_", scode, ".csv"))

# per-season RDS bundle (the committed output of merge_to_rds.R / scrape_incremental.R)
season_rds_path = function(scode) file.path(RDS_DIR, paste0("el_", scode, ".rds"))

# ----- shot-zone geometry (FIBA court; feed units = cm, basket at 0,0) ----------
ARC_CM       = 675     # 3-pt arc radius (6.75 m)
CORNER_X_CM  = 660     # corner-3 straight line, 6.60 m from the basket laterally
CORNER_Y_MAX = 150     # corner band: arc meets the straight line at Y=~142 cm (+ tolerance)
RIM_CM       = 150     # "at the rim" radius (1.5 m; 125 = strict restricted area)
SHORTMID_CM  = 400     # rim -> ~free-throw-line band (FT line at ~423 cm)
shot_zone = function(x, y, shot_type) {
  d = sqrt(x^2 + y^2)
  ifelse(shot_type == "FT", "FT",
  ifelse(shot_type == "3PT" & abs(x) >= CORNER_X_CM & y <= CORNER_Y_MAX, "CORNER3",
  ifelse(shot_type == "3PT", "ABOVE_BREAK3",
  ifelse(d <= RIM_CM, "RIM", ifelse(d <= SHORTMID_CM, "SHORT_MID", "LONG2")))))
}

# Read a season's PBP whether it was saved as a plain .csv or a zipped .csv.
read_pbp = function(scode, ...) {
  csv = pbp_path(scode); zipf = pbp_zip_path(scode)
  if (file.exists(csv))  return(read.csv(csv, ...))
  if (file.exists(zipf)) return(read.csv(unz(zipf, basename(csv)), ...))  # single-member zip
  stop("no PBP file for ", scode, " (looked for ", csv, " and ", zipf, ")")
}

# ----- cross-season fixture key ----------------------------------------------
# Game codes restart at 1 every season, so GAME_ID alone is NOT unique across
# seasons - the unique fixture key is SEASON_CODE + GAME_ID. game_key() renders
# that as one sortable string, e.g. game_key("E2025", 42) -> "E2025-042".
game_key = function(season_code, game_id) {
  gid = suppressWarnings(as.integer(game_id))
  paste0(season_code, "-", ifelse(is.na(gid), as.character(game_id),
                                  formatC(gid, width = 3, flag = "0")))
}

# ----- robust player -> team CODE (name-free) --------------------------------
.modal_code = function(d) {
  if (!nrow(d)) return(d)
  aggregate(TEAM_CODE ~ PLAYER_ID, d, function(x) names(which.max(table(x))))
}
player_team_code = function(scode) {
  norm = function(x) gsub("\\s+", "", trimws(as.character(x)))
  bp = box_path(scode)
  if (file.exists(bp)) {
    B = read.csv(bp, stringsAsFactors = FALSE)
    if ("TEAM_CODE" %in% names(B)) {
      ok = !is.na(B$TEAM_CODE) & B$TEAM_CODE != ""
      if (mean(ok) > 0.5)
        return(.modal_code(data.frame(PLAYER_ID = norm(B$PLAYER_ID[ok]),
                                      TEAM_CODE = B$TEAM_CODE[ok], stringsAsFactors = FALSE)))
    }
  }
  p = tryCatch(read_pbp(scode, colClasses = "character"), error = function(e) NULL)
  if (!is.null(p) && nrow(p)) {
    ok = is_player(p$PLAYER_ID) & !is.na(p$CODETEAM) & p$CODETEAM != ""
    return(.modal_code(data.frame(PLAYER_ID = norm(p$PLAYER_ID[ok]),
                                  TEAM_CODE = p$CODETEAM[ok], stringsAsFactors = FALSE)))
  }
  data.frame(PLAYER_ID = character(), TEAM_CODE = character(), stringsAsFactors = FALSE)
}

# Normalise a person id to a common key for joining across feeds.
pid_key = function(x) toupper(gsub("\\s", "", sub("^[Pp]", "", as.character(x))))

# Load & pool people_<scode>.csv across seasons, de-duped (prefer a real birthdate).
load_people = function(scodes = NULL) {
  files = if (is.null(scodes)) list.files(DATA_DIR, "^people_.*\\.csv$", full.names = TRUE)
           else people_path(scodes)
  files = files[file.exists(files)]
  if (!length(files)) return(NULL)
  d = do.call(rbind, lapply(files, read.csv, stringsAsFactors = FALSE, colClasses = "character"))
  if (!nrow(d)) return(NULL)
  d$KEY = pid_key(d$PERSON_ID)
  d$has_bd = !is.na(d$BIRTHDATE) & d$BIRTHDATE != ""
  d = d[order(d$KEY, d$has_bd, d$SEASON_CODE,
               decreasing = c(FALSE, TRUE, TRUE), method = "radix"), ]
  d = d[!duplicated(d$KEY), ]
  d$has_bd = NULL
  d
}

# ----- PBP event dictionary (raw live.euroleague.net feed spelling) ----------
QORD = c(FirstQuarter = 1L, SecondQuarter = 2L, ThirdQuarter = 3L,
          ForthQuarter = 4L, ExtraTime = 5L, ExtraTime2 = 6L,
          ExtraTime3 = 7L, ExtraTime4 = 8L)

SYS_CODES = c("IN","OUT","BP","EP","EG","JB","TOUT","TOUT_TV","CCH")

CODE_2FG_MADE = c("2FGM")
CODE_2FG_MISS = c("2FGA")
CODE_3FG_MADE = c("3FGM")
CODE_3FG_MISS = c("3FGA")
CODE_FT_MADE  = c("FTM")
CODE_FT_MISS  = c("FTA")
CODE_OREB     = c("O")
CODE_DREB     = c("D")
CODE_AST      = c("AS")
CODE_STL      = c("ST")
CODE_TOV      = c("TO")
CODE_BLK      = c("FV")
CODE_FOUL_RV  = c("RV")
is_foul_committed = function(pt) grepl("^CM", pt) | pt == "OF"

# ----- possession counting (EXACT, event-driven) ----------------------------
FT_RETAIN_FOULS = c("CMU", "CMU_DI", "CMU_FL", "CMD")
is_any_foul = function(pt) grepl("^CM", pt) | pt %in% c("OF", "B", "C")
OFF_SHOT_CODES = c("2FGA", "3FGA", "FTA", "O")

# Real person (player) id. "P" followed by 3+ alphanumerics (excludes team codes).
is_player = function(x) grepl("^P[A-Z0-9]{3,}$", trimws(x))

# transliterate any script to plain ASCII Latin. Uses stringi if available.
to_latin = function(x) {
  x = as.character(x)
  if (requireNamespace("stringi", quietly = TRUE)) {
    out = stringi::stri_trans_general(x, "Any-Latin; Latin-ASCII")
  } else {
    out = iconv(x, to = "ASCII//TRANSLIT")
  }
  out[is.na(out)] = x[is.na(out)]
  trimws(out)
}
