# =============================================================================
# run_scrape_all.R  --  scraper driver (full rebuild OR incremental current season)
# -----------------------------------------------------------------------------
# Two modes (first CLI argument):
#
#   Rscript scrapers/run_scrape_all.R                 # FULL: scrape every season in
#                                                     #  scope, then convert all CSVs
#                                                     #  -> one RDS per season (data/)
#   Rscript scrapers/run_scrape_all.R incremental     # INCREMENTAL: update only the
#                                                     #  current season's RDS with the
#                                                     #  games not already stored
#   Rscript scrapers/run_scrape_all.R incremental E2026   # ... an explicit season
#   Rscript scrapers/run_scrape_all.R full E2025          # ... full, one season
#
# FULL honours TEST_SCODE in config.R (one season, or NA = all of SEASONS).
# Designed to run from the REPO ROOT (the GitHub Action does). Set PROJECT_DIR
# only for a local launch from elsewhere.
#
# Layout: scripts in scrapers/, intermediate CSVs in data-raw/, committed RDS
# bundles (el_<scode>.rds) in data/. Needs network to the EuroLeague hosts.
# =============================================================================

# Optional: run from a fixed project dir locally. Empty (default) = current dir
# (repo root), which is what the GitHub Action uses. Can also be set via env var.
PROJECT_DIR = Sys.getenv("PROJECT_DIR", "")
if (nzchar(PROJECT_DIR)) {
  if (!dir.exists(PROJECT_DIR)) stop("PROJECT_DIR does not exist: ", PROJECT_DIR)
  setwd(PROJECT_DIR)
}

source("scrapers/config.R")

args  = commandArgs(trailingOnly = TRUE)
MODE  = if (length(args) >= 1) tolower(args[1]) else "full"
ARGSC = if (length(args) >= 2) args[2] else NA_character_

message("working directory: ", getwd())

if (MODE %in% c("incremental", "inc", "update")) {
  # ---- INCREMENTAL: current season only ------------------------------------
  sc = if (!is.na(ARGSC)) ARGSC else if (!is.na(TEST_SCODE)) TEST_SCODE else tail(SEASONS$scode, 1)
  message("incremental update: ", sc)
  source("scrapers/scrape_incremental.R")
  scrape_incremental(sc)
  message("done (incremental ", sc, ").")

} else {
  # ---- FULL: scrape, then convert all CSVs -> one RDS per season -----------
  scodes = if (!is.na(ARGSC)) ARGSC else if (!is.na(TEST_SCODE)) TEST_SCODE else SEASONS$scode
  message("full scrape, seasons: ", paste(scodes, collapse = ", "))

  source("scrapers/scrape_fixtures.R");  scrape_fixtures(scodes)
  source("scrapers/scrape_boxscores.R"); for (sc in scodes) scrape_boxscores(sc)
  source("scrapers/scrape_shots.R");     for (sc in scodes) scrape_shots(sc)    # shot detail (coords)
  source("scrapers/scrape_people.R");    scrape_people(scodes)
  source("scrapers/scrape_pbp.R");       for (sc in scodes) scrape_pbp(sc)

  # convert all scraped CSVs -> one RDS bundle per season (data/el_<scode>.rds)
  source("scrapers/merge_to_rds.R");     build_rds(scodes)
  message("done (full). RDS bundles in ", RDS_DIR, "/")
}
