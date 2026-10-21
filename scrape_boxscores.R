# =============================================================================
# 20_scrape_boxscores.R  --  per-player box scores + team box + COACHES
# -----------------------------------------------------------------------------
# The live.euroleague.net Boxscore endpoint returns, per team:
#   $Team (full name), $Coach (head coach name), $PlayersStats[] (per player),
#   $totr / team totals.  This is the authoritative source for the per-player
#   counting stats (exact), and the ONLY source of coach-per-game.
#
# out:
#   data/boxscores_<scode>.csv       one row per player-game (14 metric sources +
#                                    FG splits + minutes), with TEAM_CODE + COACH
#   data/team_boxscores_<scode>.csv  one row per team-game, TOTALS taken from the
#                                    feed's own team-total object `totr` (NOT a
#                                    sum of players) - so the totals correctly
#                                    include team rebounds / team turnovers, etc.
#   data/coaches_<scode>.csv         one row per team-game: GAME_ID, TEAM_CODE, COACH
#
# The feed's `totr` is the real team total (verified: totr = sum(players) + tmr,
# where tmr is the team-only non-player row). We read totr directly and emit a
# warning if that reconciliation ever fails for a game.
#
# Every per-game row also carries FIXTURE_ID = game_key(SEASON_CODE, GAME_ID)
# (e.g. "E2025-042"), the key that is unique ACROSS seasons - game codes restart
# at 1 every season, so GAME_ID alone never joins safely across seasons.
#
# Needs fixtures_<scode>.csv (for the game list + team codes + date). Run 10 first.
# =============================================================================

suppressMessages({
  library(dplyr); library(purrr); library(stringr)
  library(httr); library(jsonlite); library(glue)
})
source("scrapers/config.R")

# Player id in the box feed is padded like " P007200"; normalise to "P007200".
.norm_id   = function(x) str_replace_all(str_squish(x), "\\s+", "")
.norm_name = function(x) str_squish(x)
# "Last, First" -> "First Last", transliterated to plain ASCII Latin
.flip_name = function(x) to_latin(str_replace(.norm_name(x), "^(.*),\\s*(.*)$", "\\2 \\1"))
.min_to_sec = function(mm) {
  mm = ifelse(is.na(mm) | mm %in% c("", "DNP"), "0:00", mm)
  p = str_split(mm, ":", simplify = TRUE)
  as.integer(p[, 1]) * 60 + as.integer(p[, 2])
}

get_boxscore = function(game_id, scode) {
  url = glue(EP_BOXSCORE, gamecode = game_id, scode = scode)
  raw = fromJSON(content(GET(url), "text", encoding = "UTF-8"), simplifyVector = FALSE)
  stats = raw$Stats
  if (is.null(stats)) return(NULL)

  players = list(); teams = list(); coaches = list()
  for (ti in seq_along(stats)) {
    tm   = stats[[ti]]
    tname = tm$Team; coach = .flip_name(tm$Coach %||% "")   # .flip_name transliterates
    tcode = toupper(trimws(tm$TeamCode %||% tm$Code %||% ""))  # team acronym if given at team level
    # per-player rows
    ps = tm$PlayersStats
    psum = NULL                         # running sum of player REB/TOV for reconciliation
    for (p in ps) {
      pid = .norm_id(p$Player_ID %||% p$PlayerCode %||% "")
      if (!is_player(pid)) next           # skip team-total / coach pseudo-rows
      pteam = toupper(trimws(p$Team %||% ""))   # canonical team acronym from the feed (e.g. "OLY")
      if (!nzchar(tcode) && nzchar(pteam)) tcode = pteam
      players[[length(players) + 1]] = data.frame(
        GAME_ID = as.character(game_id), FIXTURE_ID = game_key(scode, game_id),
        SEASON_CODE = scode,
        TEAM_NAME = tname, TEAM_CODE = pteam, COACH = coach,
        PLAYER_ID = pid, PLAYER = .flip_name(p$Player %||% ""),
        MIN_SEC = .min_to_sec(p$Minutes %||% "0:00"),
        PTS = p$Points %||% 0,
        FG2M = p$FieldGoalsMade2 %||% 0, FG2A = p$FieldGoalsAttempted2 %||% 0,
        FG3M = p$FieldGoalsMade3 %||% 0, FG3A = p$FieldGoalsAttempted3 %||% 0,
        FTM  = p$FreeThrowsMade %||% 0,  FTA  = p$FreeThrowsAttempted %||% 0,
        OREB = p$OffensiveRebounds %||% 0, DREB = p$DefensiveRebounds %||% 0,
        REB  = p$TotalRebounds %||% 0,
        AST  = p$Assistances %||% 0, STL = p$Steals %||% 0, TOV = p$Turnovers %||% 0,
        BLK  = p$BlocksFavour %||% 0, BLK_AGAINST = p$BlocksAgainst %||% 0,
        PF_COMMITTED = p$FoulsCommited %||% 0, PF_DRAWN = p$FoulsReceived %||% 0,
        PLUSMINUS = p$Plusminus %||% NA, VALUATION = p$Valuation %||% NA,
        stringsAsFactors = FALSE)
      psum = .acc(psum, p)               # accumulate player totals for the check
    }

    # --- TEAM TOTAL ROW (the whole point of this file) ------------------------
    # `totr` is the feed's OWN team total and is authoritative: it already
    # includes team rebounds / team turnovers etc., so we read it verbatim and
    # NEVER sum the players. `tmr` is the team-only (non-player) row; the feed's
    # own invariant is  totr = sum(players) + tmr , which we verify and warn on.
    totr = tm$totr %||% tm$Totr %||% tm$TotalStats %||% NULL
    if (!is.null(totr) && !identical(tname, "N/D")) {
      if (!nzchar(tcode)) tcode = toupper(trimws(totr$Team %||% (tm$tmr %||% list())$Team %||% ""))
      teams[[length(teams) + 1]] = data.frame(
        GAME_ID = as.character(game_id), FIXTURE_ID = game_key(scode, game_id),
        SEASON_CODE = scode,
        TEAM_CODE = tcode, TEAM_NAME = tname,
        HOME_AWAY = if (ti == 1) "HOME" else "AWAY", COACH = coach,
        PTS = totr$Points %||% 0,
        FG2M = totr$FieldGoalsMade2 %||% 0, FG2A = totr$FieldGoalsAttempted2 %||% 0,
        FG3M = totr$FieldGoalsMade3 %||% 0, FG3A = totr$FieldGoalsAttempted3 %||% 0,
        FTM  = totr$FreeThrowsMade %||% 0,  FTA  = totr$FreeThrowsAttempted %||% 0,
        OREB = totr$OffensiveRebounds %||% 0, DREB = totr$DefensiveRebounds %||% 0,
        REB  = totr$TotalRebounds %||% 0,
        AST  = totr$Assistances %||% 0, STL = totr$Steals %||% 0, TOV = totr$Turnovers %||% 0,
        BLK  = totr$BlocksFavour %||% 0, BLK_AGAINST = totr$BlocksAgainst %||% 0,
        PF_COMMITTED = totr$FoulsCommited %||% 0, PF_DRAWN = totr$FoulsReceived %||% 0,
        VALUATION = totr$Valuation %||% NA,
        MIN_SEC = .min_to_sec(totr$Minutes %||% "0:00"),
        stringsAsFactors = FALSE)
      # reconciliation: totr should equal sum(players) + tmr on every field.
      tmr = tm$tmr %||% tm$Tmr %||% list()
      .reconcile_total(game_id, scode, tcode, totr, psum, tmr)
    }

    if (nzchar(coach)) {                 # coach field is empty before 2016-17
      coaches[[length(coaches) + 1]] = data.frame(
        GAME_ID = as.character(game_id), FIXTURE_ID = game_key(scode, game_id),
        SEASON_CODE = scode,
        TEAM_NAME = tname, TEAM_CODE = tcode, COACH = coach, stringsAsFactors = FALSE)
    }
  }
  list(players = bind_rows(players), teams = bind_rows(teams),
       coaches = bind_rows(coaches))
}
`%||%` = function(a, b) {
  if (is.null(a) || length(a) == 0) return(b)
  if (length(a) == 1 && is.atomic(a) && is.na(a)) return(b)  # scalar NA -> fallback
  a                                                          # lists / vectors pass through
}

# running accumulator of the player counting stats we reconcile the total against
.FIELDS_CHK = c(PTS="Points", FG2M="FieldGoalsMade2", FG2A="FieldGoalsAttempted2",
                 FG3M="FieldGoalsMade3", FG3A="FieldGoalsAttempted3",
                 FTM="FreeThrowsMade", FTA="FreeThrowsAttempted",
                 OREB="OffensiveRebounds", DREB="DefensiveRebounds", REB="TotalRebounds",
                 AST="Assistances", STL="Steals", TOV="Turnovers",
                 BLK="BlocksFavour", BLK_AGAINST="BlocksAgainst",
                 PF_COMMITTED="FoulsCommited", PF_DRAWN="FoulsReceived")
.acc = function(acc, p) {
  v = vapply(.FIELDS_CHK, function(f) as.numeric(p[[f]] %||% 0), numeric(1))
  if (is.null(acc)) v else acc + v
}
# Warn (don't stop) if the feed's own invariant  totr = sum(players) + tmr  breaks
# on any counting field. A mismatch means the team total we wrote may be off.
.reconcile_total = function(game_id, scode, tcode, totr, psum, tmr) {
  if (is.null(psum)) psum = setNames(numeric(length(.FIELDS_CHK)), names(.FIELDS_CHK))
  tv = vapply(.FIELDS_CHK, function(f) as.numeric(totr[[f]] %||% 0), numeric(1))
  mv = vapply(.FIELDS_CHK, function(f) as.numeric(tmr[[f]]  %||% 0), numeric(1))
  diff = tv - (psum + mv)
  bad  = names(diff)[abs(diff) > 1e-6]
  if (length(bad))
    message(glue("  !! total<>players+team mismatch {scode} g{game_id} {tcode}: ",
                 paste0(bad, " (totr=", tv[bad], " vs ", psum[bad] + mv[bad], ")",
                        collapse = ", ")))
}

# Apply canonical team names (from fixtures) to any frame carrying a TEAM_CODE.
.apply_canon_names = function(df, fx) {
  if (!nrow(df) || !all(c("HOME_CODE","AWAY_CODE") %in% names(fx))) return(df)
  hn = if ("HOME_NAME" %in% names(fx)) fx$HOME_NAME else fx$HOME_CODE
  an = if ("AWAY_NAME" %in% names(fx)) fx$AWAY_NAME else fx$AWAY_CODE
  c2n = c(setNames(hn, toupper(fx$HOME_CODE)), setNames(an, toupper(fx$AWAY_CODE)))
  c2n = c2n[!duplicated(names(c2n))]
  hit = df$TEAM_CODE %in% names(c2n)
  df$TEAM_NAME[hit] = to_latin(unname(c2n[df$TEAM_CODE[hit]]))
  df
}

# Shared finisher for the TEAM box file: canonical names, then derive the opponent
# code, points allowed and the win flag from the two rows of each game. Used by
# both this scraper and the 21_ backfill, so the output is byte-identical.
finalize_team_box = function(teams, fx, scode) {
  if (!nrow(teams))
    return(data.frame(GAME_ID=character(), FIXTURE_ID=character(), SEASON_CODE=character(),
                      TEAM_CODE=character(), TEAM_NAME=character(),
                      HOME_AWAY=character(), OPP_CODE=character(), COACH=character(),
                      PTS=numeric(), FG2M=numeric(), FG2A=numeric(), FG3M=numeric(),
                      FG3A=numeric(), FTM=numeric(), FTA=numeric(), OREB=numeric(),
                      DREB=numeric(), REB=numeric(), AST=numeric(), STL=numeric(),
                      TOV=numeric(), BLK=numeric(), BLK_AGAINST=numeric(),
                      PF_COMMITTED=numeric(), PF_DRAWN=numeric(), VALUATION=numeric(),
                      MIN_SEC=numeric(), PTS_AGAINST=numeric(), WIN=integer()))
  teams = .apply_canon_names(teams, fx)
  # opponent = the OTHER team row in the same game; points allowed = its PTS.
  teams = teams %>%
    group_by(GAME_ID) %>%
    mutate(
      OPP_CODE    = if (n() == 2) rev(TEAM_CODE) else NA_character_,
      PTS_AGAINST = if (n() == 2) rev(PTS)       else NA_real_,
      WIN         = as.integer(PTS > PTS_AGAINST)) %>%
    ungroup()
  # column order: identity first, then the totals, then derived result fields.
  teams[, c("GAME_ID","FIXTURE_ID","SEASON_CODE","TEAM_CODE","TEAM_NAME","HOME_AWAY","OPP_CODE","COACH",
            "PTS","FG2M","FG2A","FG3M","FG3A","FTM","FTA","OREB","DREB","REB","AST","STL",
            "TOV","BLK","BLK_AGAINST","PF_COMMITTED","PF_DRAWN","VALUATION","MIN_SEC",
            "PTS_AGAINST","WIN")]
}

scrape_boxscores = function(scode) {
  fx = read.csv(fx_path(scode), stringsAsFactors = FALSE)
  allp = list(); allt = list(); allc = list()
  for (i in seq_len(nrow(fx))) {
    Sys.sleep(PAUSE_S)
    bs = tryCatch(get_boxscore(fx$GAME_ID[i], scode), error = function(e) {
      message(glue("  box {scode} g{fx$GAME_ID[i]} failed: {conditionMessage(e)}")); NULL })
    if (is.null(bs)) next
    allp[[length(allp) + 1]] = bs$players
    allt[[length(allt) + 1]] = bs$teams
    allc[[length(allc) + 1]] = bs$coaches
  }
  players = bind_rows(allp); teams = bind_rows(allt); coaches = bind_rows(allc)

  # CANONICAL team names: key on the acronym (TEAM_CODE, from the feed) and take
  # the one authoritative name from fixtures, so box scores + coaches carry the
  # SAME team names as fixtures/teams - no name-matching needed downstream.
  players = .apply_canon_names(players, fx)
  coaches = .apply_canon_names(coaches, fx)
  teams   = finalize_team_box(teams, fx, scode)

  if (!nrow(coaches))              # no coach names before 2016-17: write a headed empty file
    coaches = data.frame(GAME_ID = character(), FIXTURE_ID = character(), SEASON_CODE = character(),
                          TEAM_NAME = character(), TEAM_CODE = character(), COACH = character())
  write.csv(players, box_path(scode), row.names = FALSE)
  write.csv(teams,   team_box_path(scode), row.names = FALSE)
  write.csv(coaches, coach_path(scode), row.names = FALSE)
  note = if (!nrow(coaches)) "  (no coach names in this season's feed; coaches start 2016-17)" else ""
  message(glue("{scode}: {nrow(players)} player-game rows, {nrow(teams)} team-game rows, ",
               "{nrow(coaches)} coach-game rows{note}"))
}

if (sys.nframe() == 0) {
  scodes = if (!is.na(TEST_SCODE)) TEST_SCODE else SEASONS$scode
  for (sc in scodes) scrape_boxscores(sc)
}
