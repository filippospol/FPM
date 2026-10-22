# =============================================================================
# merge_to_rds.R  --  bundle each season's scraped CSVs into ONE .rds PER SEASON
# -----------------------------------------------------------------------------
# Reads the per-season CSVs in RAW_DIR (data-raw/) and writes one self-contained
# bundle per season to RDS_DIR (data/el_<scode>.rds), each a list:
#
#   el_E2026.rds  =  list(fixtures, boxscores, team_boxscores, coaches, shots, people, pbp)
#
# One file per season (not one giant blob): the incremental run only rewrites
# el_E2026.rds, git diffs stay small, and a single year loads without the history.
#
#   Rscript scrapers/merge_to_rds.R               # bundle every season found in data-raw/
#   Rscript scrapers/merge_to_rds.R E2024 E2025   # only these seasons
#
# Load one season:     el <- readRDS("data/el_E2026.rds")
# Load / pool several: el <- load_seasons(c("E2024","E2025","E2026"))
#
# Needs scrapers/config.R (paths + read_pbp) and the `dplyr` package.
# Also defines the append/replace helpers scrape_incremental.R reuses.
# =============================================================================

source("scrapers/config.R")
suppressMessages(library(dplyr))

# tables that make up a season bundle: name -> path function (pbp handled separately)
.SEASON_TABLES = list(
  fixtures       = fx_path,
  boxscores      = box_path,
  team_boxscores = team_box_path,
  coaches        = coach_path,
  shots          = shots_path,
  people         = people_path
)

# ---- shared helpers (also used by scrape_incremental.R) ---------------------
drop_fixtures = function(df, fids) {
  if (is.null(df) || !nrow(df) || !length(fids)) return(df)
  df[!(as.character(df$FIXTURE_ID) %in% fids), , drop = FALSE]
}
append_rows = function(old, new) {
  if (is.null(new) || !nrow(new)) return(old)
  if (is.null(old) || !nrow(old)) return(new)
  # The stored bundle reads IDs via read.csv (GAME_ID -> integer), while a freshly
  # scraped game keeps them as character, so bind_rows aborts on the type clash.
  # Reconcile any shared column whose class differs by coercing both to character.
  for (c in intersect(names(old), names(new))) {
    if (!identical(class(old[[c]]), class(new[[c]]))) {
      old[[c]] = as.character(old[[c]]); new[[c]] = as.character(new[[c]])
    }
  }
  bind_rows(old, new)
}

# ---- build ONE season's bundle ----------------------------------------------
build_season_rds = function(scode, out = NULL) {
  if (is.null(out)) out = season_rds_path(scode)
  rd = function(path) if (file.exists(path)) read.csv(path, stringsAsFactors = FALSE) else NULL
  el = lapply(.SEASON_TABLES, function(fun) rd(fun(scode)))              # named list of frames
  el$pbp = tryCatch(read_pbp(scode, stringsAsFactors = FALSE), error = function(e) NULL)  # plain or zipped
  el = el[!vapply(el, is.null, logical(1))]
  if (!length(el)) { message(scode, ": no CSVs found in ", RAW_DIR, " - skipped"); return(invisible(NULL)) }
  saveRDS(el, out, compress = "xz")
  message(sprintf("%s -> %s  [%s]", scode, out,
                  paste(sprintf("%s:%d", names(el), vapply(el, nrow, integer(1))), collapse = ", ")))
  invisible(el)
}

# ---- build all requested seasons (discover from RAW_DIR when scodes is NULL) --
build_rds = function(scodes = NULL) {
  if (is.null(scodes) || !length(scodes)) {
    fxs = list.files(RAW_DIR, "^fixtures_.*\\.csv$")
    scodes = sub("^fixtures_(.*)\\.csv$", "\\1", fxs)
  }
  if (!length(scodes)) { message("merge: no fixtures_*.csv in ", RAW_DIR, " - nothing to bundle"); return(invisible(NULL)) }
  invisible(lapply(scodes, build_season_rds))
}

# ---- convenience loaders ----------------------------------------------------
load_season = function(scode) { p = season_rds_path(scode); if (file.exists(p)) readRDS(p) else NULL }
load_seasons = function(scodes) {
  els = lapply(scodes, load_season)
  els = els[!vapply(els, is.null, logical(1))]
  if (!length(els)) return(NULL)
  tabs = unique(unlist(lapply(els, names)))
  setNames(lapply(tabs, function(t) bind_rows(lapply(els, function(e) e[[t]]))), tabs)
}

if (sys.nframe() == 0) {
  args = commandArgs(trailingOnly = TRUE)
  build_rds(if (length(args)) args else NULL)
}
