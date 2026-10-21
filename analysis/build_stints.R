# =============================================================================
# build_stints.R  --  RAPM stint data from PBP (lean: points / possessions / minutes)
# -----------------------------------------------------------------------------
# Reads each season bundle data/el_<scode>.rds, takes its $pbp, and for every game
# rebuilds the 5-on-5 lineups by walking the substitutions, cutting a new STINT
# whenever the 10 players on court change. Possessions are counted event-by-event
# with the EXACT (FIBA/EuroLeague) rules in config.R - no 0.44*FTA.
#
# This is the MODEL input for RAPM: just what the regression needs - the two
# lineups, points for/against, possessions for/against, and minutes.
#
#   in : data/el_<scode>.rds          ($pbp + $fixtures)
#   out: stints/stints_<scode>.rds    one row per stint (home = team, away = opp):
#        GAME_ID, FIXTURE_ID, SEASON_CODE, QUARTER, STINT, HOME_CODE, AWAY_CODE,
#        H1..H5 (team 5), A1..A5 (opponent 5), SEC,
#        POSS, OPP_POSS,  PTS, OPP_PTS,  OK
#        (OK = TRUE when both lineups had exactly 5 players - filter on it for RAPM.)
#
# Runs UNCHANGED locally and in CI (needs only config.R + the bundles):
#   Rscript analysis/build_stints.R                 # FULL: every el_*.rds in data/
#   Rscript analysis/build_stints.R E2024 E2025     # FULL: these seasons
#   Rscript analysis/build_stints.R incremental      # INCREMENTAL: current season, new games
#   Rscript analysis/build_stints.R incremental E2026
# =============================================================================

source("scrapers/config.R")
suppressMessages(library(dplyr))

STINTS_DIR = "stints"
dir.create(STINTS_DIR, showWarnings = FALSE, recursive = TRUE)
stints_path = function(scode) file.path(STINTS_DIR, paste0("stints_", scode, ".rds"))

QLEN = c(FirstQuarter = 600L, SecondQuarter = 600L, ThirdQuarter = 600L,
         ForthQuarter = 600L, ExtraTime = 300L, ExtraTime2 = 300L,
         ExtraTime3 = 300L, ExtraTime4 = 300L)

`%||%` = function(a, b) if (is.null(a) || length(a) == 0) b else a

.clock_sec = function(mt) {                              # "MM:SS" -> seconds remaining; "" -> NA
  mt = trimws(mt); out = rep(NA_real_, length(mt))
  ok = grepl("^[0-9]+:[0-9]{2}$", mt)
  if (any(ok)) {
    p = do.call(rbind, strsplit(mt[ok], ":", fixed = TRUE))
    out[ok] = as.numeric(p[, 1]) * 60 + as.numeric(p[, 2])
  }
  out
}
.ffill = function(x) {
  pos = cummax(ifelse(!is.na(x), seq_along(x), 0L))
  ifelse(pos == 0L, NA_real_, x[ifelse(pos == 0L, 1L, pos)])
}

# per-quarter starting five: first 5 players per team whose first event is a
# non-IN action (or an OUT) - i.e. they were on court before being subbed in.
.infer_starters = function(qe) {
  starters = character(0); subbed_in = character(0)
  for (i in seq_len(nrow(qe))) {
    pid = qe$PLAYER_ID[i]; pt = qe$PLAYTYPE[i]
    if (!is_player(pid)) next
    if (pt == "IN") { subbed_in = c(subbed_in, pid); next }
    if (!(pid %in% starters) && !(pid %in% subbed_in)) starters = c(starters, pid)
  }
  head(starters, 5)
}

# possession-end team per event (exact rules from config.R)
.poss_end = function(g, home, away) {
  opp = function(t) ifelse(t == home, away, home)
  pt  = g$PLAYTYPE; tm = g$CODETEAM; pid = g$PLAYER_ID; clk = g$MARKERTIME
  n = nrow(g)
  is_ft = pt %in% c("FTM", "FTA")                        # FT trips: same player, same clock
  newrun = is_ft & !(is_ft & c(FALSE, is_ft[-n]) & pid == c("", pid[-n]) & clk == c("", clk[-n]))
  runid = cumsum(newrun) * is_ft
  trip_size = rep(0L, n)
  if (any(is_ft)) { sz = tapply(rep(1L, sum(is_ft)), runid[is_ft], sum); trip_size[is_ft] = sz[as.character(runid[is_ft])] }
  is_last_ft = is_ft & (c(runid[-1], -1L) != runid)
  out = rep(NA_character_, n); last_miss_single_ft = FALSE
  for (i in seq_len(n)) {
    p = pt[i]
    if (p %in% c("2FGM", "3FGM")) out[i] = tm[i]                       # made FG -> shooter
    else if (p == "TO")          out[i] = tm[i]                        # turnover
    else if (is_last_ft[i] && trip_size[i] >= 2 && p == "FTM") out[i] = tm[i]  # last made FT of >=2 trip
    else if (p == "D") { if (!last_miss_single_ft) out[i] = opp(tm[i]) }       # opp def-rebound ends shooter poss
    if (p %in% c("2FGA", "3FGA")) last_miss_single_ft = FALSE
    else if (p == "FTA")          last_miss_single_ft = (trip_size[i] <= 1L)
    else if (p %in% c("2FGM", "3FGM", "FTM", "TO", "D", "O")) last_miss_single_ft = FALSE
  }
  out
}

# ---- one game -> stint rows --------------------------------------------------
build_stints_game = function(g, home, away) {
  g = g[order(suppressWarnings(as.integer(g$NUMBEROFPLAY))), ]
  g$PLAYER_ID = trimws(g$PLAYER_ID); g$CODETEAM = trimws(g$CODETEAM)
  g$qord = QORD[g$QUARTER]; g = g[!is.na(g$qord), ]
  g$clk = ave(.clock_sec(g$MARKERTIME), g$QUARTER, FUN = .ffill)
  g$pts = c(`2FGM` = 2, `3FGM` = 3, FTM = 1)[g$PLAYTYPE]; g$pts[is.na(g$pts)] = 0
  g$pe  = .poss_end(g, home, away)

  # period-end charge: ball live at the buzzer (missed shot / oreb after the last
  # terminal) -> one possession to the offensive team (config.R rule).
  for (q in unique(g$QUARTER)) {
    idx = which(g$QUARTER == q)
    lt  = which(!is.na(g$pe[idx])); lt = if (length(lt)) max(lt) else 0L
    if (lt < length(idx)) {
      post = idx[(lt + 1L):length(idx)]
      off  = post[g$PLAYTYPE[post] %in% c("2FGA", "3FGA", "FTA", "O")]
      if (length(off)) { j = tail(off, 1); g$pe[j] = g$CODETEAM[j] }
    }
  }

  stints = list()
  for (q in unique(g$QUARTER)) {
    qe = g[g$QUARTER == q, ]
    on_h = .infer_starters(qe[qe$CODETEAM == home, ])
    on_a = .infer_starters(qe[qe$CODETEAM == away, ])
    cur_sig = NULL; sid = 0L; qlen = QLEN[[q]] %||% 600L
    qe$stint = NA_integer_; H = list(); A = list()
    for (i in seq_len(nrow(qe))) {
      p = qe$PLAYTYPE[i]; tm = qe$CODETEAM[i]; pid = qe$PLAYER_ID[i]
      if (p == "IN")  { if (tm == home) on_h = union(on_h, pid) else if (tm == away) on_a = union(on_a, pid); next }
      if (p == "OUT") { if (tm == home) on_h = setdiff(on_h, pid) else if (tm == away) on_a = setdiff(on_a, pid); next }
      sig = paste(paste(sort(on_h), collapse = "|"), paste(sort(on_a), collapse = "|"), sep = "#")
      if (is.null(cur_sig) || sig != cur_sig) { sid = sid + 1L; cur_sig = sig; H[[sid]] = on_h; A[[sid]] = on_a }
      qe$stint[i] = sid
    }
    if (sid == 0L) next
    firstclk = tapply(qe$clk, qe$stint, function(x) x[which(!is.na(x))[1]])
    starts = as.numeric(firstclk[as.character(seq_len(sid))]); starts[is.na(starts)] = qlen
    ends = c(starts[-1], 0); ends[is.na(ends)] = 0
    for (s in seq_len(sid)) {
      es = qe[!is.na(qe$stint) & qe$stint == s, ]
      h5 = head(c(H[[s]], rep(NA, 5)), 5); a5 = head(c(A[[s]], rep(NA, 5)), 5)
      stints[[length(stints) + 1]] = data.frame(
        GAME_ID = g$GAME_ID[1], FIXTURE_ID = g$FIXTURE_ID[1], SEASON_CODE = g$SEASON[1],
        QUARTER = q, STINT = s, HOME_CODE = home, AWAY_CODE = away,
        H1 = h5[1], H2 = h5[2], H3 = h5[3], H4 = h5[4], H5 = h5[5],
        A1 = a5[1], A2 = a5[2], A3 = a5[3], A4 = a5[4], A5 = a5[5],
        SEC = max(0, round(starts[s] - ends[s])),
        POSS = sum(es$pe == home, na.rm = TRUE), OPP_POSS = sum(es$pe == away, na.rm = TRUE),
        PTS  = sum(es$pts[es$CODETEAM == home]), OPP_PTS  = sum(es$pts[es$CODETEAM == away]),
        OK = (length(H[[s]]) == 5 && length(A[[s]]) == 5),
        stringsAsFactors = FALSE)
    }
  }
  if (!length(stints)) return(NULL)
  bind_rows(stints)
}

# ---- build stints for a set of GAME_IDs within a season bundle ---------------
.stints_for_games = function(p, fx, gids) {
  ha = setNames(data.frame(H = fx$HOME_CODE, A = fx$AWAY_CODE, stringsAsFactors = FALSE), c("H", "A"))
  rownames(ha) = as.character(fx$GAME_ID)
  out = vector("list", length(gids))
  for (i in seq_along(gids)) {
    gid = gids[i]; g = p[p$GAME_ID == gid, ]
    home = ha[as.character(gid), "H"]; away = ha[as.character(gid), "A"]
    if (is.na(home) || is.na(away)) next
    out[[i]] = tryCatch(build_stints_game(g, home, away),
                        error = function(e) { message("  g", gid, ": ", conditionMessage(e)); NULL })
  }
  bind_rows(out)
}
.drop_games = function(st, gids) {
  if (is.null(st) || !nrow(st)) return(st)
  st[!(as.character(st$GAME_ID) %in% as.character(gids)), , drop = FALSE]
}

# ---- FULL rebuild of a season ------------------------------------------------
build_stints_season = function(scode, el = NULL) {
  if (is.null(el)) el = readRDS(season_rds_path(scode))
  if (is.null(el$pbp) || !nrow(el$pbp)) { message(scode, ": no pbp - skipped"); return(invisible(NULL)) }
  gids = unique(el$pbp$GAME_ID)
  st = .stints_for_games(el$pbp, el$fixtures, gids)
  saveRDS(st, stints_path(scode), compress = "xz")
  message(sprintf("%s FULL: %d games -> %d stints (%.1f%% 5v5-clean) -> %s",
                  scode, length(gids), nrow(st), 100 * mean(st$OK), stints_path(scode)))
  invisible(st)
}

# ---- INCREMENTAL: add only the games not already in stints/stints_<scode>.rds -
build_stints_incremental = function(scode = NULL, el = NULL) {
  if (is.null(scode)) scode = if (!is.na(TEST_SCODE)) TEST_SCODE else tail(SEASONS$scode, 1)
  if (is.null(el)) el = readRDS(season_rds_path(scode))
  if (is.null(el$pbp) || !nrow(el$pbp)) { message(scode, ": no pbp - skipped"); return(invisible(NULL)) }
  existing = if (file.exists(stints_path(scode))) readRDS(stints_path(scode)) else NULL
  done = if (!is.null(existing)) unique(as.character(existing$GAME_ID)) else character(0)
  all_g = unique(as.character(el$pbp$GAME_ID)); new_g = setdiff(all_g, done)
  message(sprintf("%s INCREMENTAL: %d games total, %d already stinted, %d new",
                  scode, length(all_g), length(done), length(new_g)))
  if (length(new_g)) {
    new_st = .stints_for_games(el$pbp, el$fixtures, new_g)
    st = bind_rows(.drop_games(existing, new_g), new_st)
  } else st = existing
  if (is.null(st) || !nrow(st)) { message("  nothing to write"); return(invisible(st)) }
  saveRDS(st, stints_path(scode), compress = "xz")
  message(sprintf("  -> %d stints (%.1f%% 5v5-clean) -> %s", nrow(st), 100 * mean(st$OK), stints_path(scode)))
  invisible(st)
}

# ---- FULL driver across all requested seasons (discover el_*.rds in data/) ----
build_stints = function(scodes = NULL) {
  if (is.null(scodes) || !length(scodes)) {
    f = list.files(RDS_DIR, "^el_.*\\.rds$")
    scodes = sub("^el_(.*)\\.rds$", "\\1", f)
  }
  if (!length(scodes)) { message("no el_*.rds in ", RDS_DIR); return(invisible(NULL)) }
  invisible(lapply(scodes, build_stints_season))
}

if (sys.nframe() == 0) {
  args = commandArgs(trailingOnly = TRUE)
  if (length(args) && tolower(args[1]) %in% c("incremental", "inc", "update")) {
    build_stints_incremental(if (length(args) >= 2) args[2] else NULL)
  } else {
    build_stints(if (length(args)) args else NULL)
  }
}
