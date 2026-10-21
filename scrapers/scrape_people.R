# =============================================================================
# 30_scrape_people.R  --  player & staff bios (birthDate -> age)
# -----------------------------------------------------------------------------
# The season "people" feed returns EVERY person linked to the season in one call
# (players, head/assistant coaches, doctors, staff). Each record is:
#   { person: { code, name, birthDate, height, weight, country, ... },
#     type, typeName, position, positionName, dorsal, club, season, ... }
# We keep what we need and tag each row with TYPE/TYPENAME so downstream can
# filter (players = type "J"; coaches = type "E"/"A").
#
# out: data/people_<scode>.csv  (PERSON_ID, NAME, BIRTHDATE, HEIGHT, POSITION,
#        COUNTRY, TYPE, TYPENAME, SEASON_CODE)  one file per season, like the
#        fixtures/boxscores/pbp outputs; de-duped within the season.
#
# NB: people are SEASON-level (no game dimension), so this file carries no
# FIXTURE_ID - it joins on PERSON_ID (via pid_key()) + SEASON_CODE.
# =============================================================================

suppressMessages({
  library(dplyr); library(purrr); library(stringr)
  library(httr); library(jsonlite); library(glue)
})
source("scrapers/config.R")

`%||%` = function(a, b) if (is.null(a) || length(a) == 0 || (length(a) == 1 && is.na(a))) b else a
.flip_name = function(x) to_latin(str_replace(str_squish(x %||% ""), "^(.*),\\s*(.*)$", "\\2 \\1"))
.as_date   = function(x) { x = x %||% NA; if (is.na(x)) NA_character_ else substr(as.character(x), 1, 10) }  # "1983-05-17T00:00:00" -> "1983-05-17"
.country   = function(c) if (is.list(c)) (c$name %||% c$code %||% NA) else (c %||% NA)

get_people = function(scode) {
  url = glue(EP_PEOPLE, COMP = COMP, scode = scode)
  res = GET(url, query = list(limit = 2000))
  if (http_error(res)) { message(glue("  people {scode}: HTTP {status_code(res)}")); return(NULL) }
  dat = fromJSON(content(res, "text", encoding = "UTF-8"), simplifyVector = FALSE)
  recs = dat$data %||% dat
  if (length(recs) == 0) return(NULL)
  map_dfr(recs, function(r) {
    p = r$person %||% r
    data.frame(
      PERSON_ID = str_replace_all(str_squish(p$code %||% ""), "\\s+", ""),
      NAME      = .flip_name(p$name),
      BIRTHDATE = .as_date(p$birthDate),
      HEIGHT    = suppressWarnings(as.numeric(p$height %||% NA)),
      POSITION  = r$positionName %||% NA,
      COUNTRY   = to_latin(.country(p$country)),
      TYPE      = r$type %||% NA,
      TYPENAME  = r$typeName %||% NA,
      SEASON_CODE = scode, stringsAsFactors = FALSE)
  })
}

# one file per season: data/people_<scode>.csv
people_season_path = function(scode) file.path(DATA_DIR, paste0("people_", scode, ".csv"))

scrape_people = function(scodes) {
  cols = c("PERSON_ID","NAME","BIRTHDATE","HEIGHT","POSITION","COUNTRY","TYPE","TYPENAME","SEASON_CODE")
  for (sc in scodes) {
    Sys.sleep(PAUSE_S)
    outp = people_season_path(sc)
    d = tryCatch(get_people(sc), error = function(e) {
      message(glue("  people {sc} failed: {conditionMessage(e)}")); NULL })
    if (is.null(d) || !nrow(d)) {            # nothing came back: write headed empty file, don't crash
      empty = setNames(data.frame(matrix(character(), 0, length(cols))), cols)
      write.csv(empty, outp, row.names = FALSE)
      message(glue("{sc}: 0 people -> {outp}  (check the endpoint/network)"))
      next
    }
    # de-dupe within the season, preferring a record that has a real birthdate
    d$has_bd = !is.na(d$BIRTHDATE) & d$BIRTHDATE != ""
    d = d[order(d$PERSON_ID, -d$has_bd), ]
    d = d[!duplicated(d$PERSON_ID), cols]
    write.csv(d, outp, row.names = FALSE)
    message(glue("{sc}: {nrow(d)} people ({sum(d$TYPE=='J', na.rm=TRUE)} players) -> {outp}"))
  }
}

if (sys.nframe() == 0) {
  scodes = if (!is.na(TEST_SCODE)) TEST_SCODE else SEASONS$scode
  scrape_people(scodes)
}
