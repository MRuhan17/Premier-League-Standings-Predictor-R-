# ==========================================
# R/01_feature_engineering.R
# ==========================================
# Purpose:
#  - Read raw match CSVs (data/raw/E0_*.csv)
#  - Read Understat xG files (data/raw/understat/*.json or *.csv)
#  - Produce:
#      * data/team_season_stats.csv
#      * data/xg_team_summary.csv
#      * data/combined_features.csv
#      * data/<team>_summary.csv (one per team)
# Notes:
#  - This script is defensive: it tolerates missing files, different Understat formats,
#    and logs helpful messages so you (or a teammate) can quickly understand issues.
# ==========================================

library(data.table)
library(dplyr)
library(tidyr)
library(lubridate)
library(jsonlite)
library(stringr)

# Paths
RAW_DIR <- "data/raw"
UNDERSTAT_DIR <- file.path(RAW_DIR, "understat")
OUT_DIR <- "data"
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

# -------------------------
# 1) Load football-data CSVs and build team-season stats
# -------------------------
match_files <- list.files(RAW_DIR, pattern = "^E0_.*\\.csv$", full.names = TRUE)
if (length(match_files) == 0) stop("No raw E0 CSVs found in data/raw/. Run the fetch script first.")

# read safely with data.table::fread (fast and flexible)
raw_list <- lapply(match_files, function(f) {
  message("Loading raw file: ", basename(f))
  dt <- tryCatch(fread(f), error = function(e) {
    message("  ✖ failed to read ", f, " : ", e$message); return(NULL)
  })
  dt
})
raw_list <- Filter(Negate(is.null), raw_list)
all_matches <- rbindlist(raw_list, fill = TRUE)

# normalize column names to lowercase for robustness
setnames(all_matches, tolower(names(all_matches)))

# Try to detect home/away/date columns (football-data variants)
# Common column names: Date, HomeTeam, AwayTeam, FTHG, FTAG
if (!all(c("date","hometeam","awayteam","fthg","ftag") %in% names(all_matches))) {
  stop("Expected columns (date, HomeTeam, AwayTeam, FTHG, FTAG) not found. Inspect the raw CSV headers.")
}

# Keep and standardize columns
matches <- all_matches %>%
  transmute(
    date = as.Date(date, format = "%d/%m/%Y"),
    # handle NA dates by attempting alternate format
    date = ifelse(is.na(date),
                  as.Date(all_matches$date, format = "%Y-%m-%d"),
                  date) %>% as.Date(origin = "1970-01-01"),
    home = hometeam,
    away = awayteam,
    fthg = as.integer(fthg),
    ftag = as.integer(ftag)
  ) %>%
  # filter out rows with NA teams (if any)
  filter(!is.na(home) & !is.na(away))

# determine season by convention: season year = year when season starts (Aug -> year)
matches <- matches %>%
  mutate(season = ifelse(month(date) >= 8, year(date), year(date) - 1))

# pivot so each match produces two rows (one per team) — easier aggregation
team_match_rows <- matches %>%
  pivot_longer(cols = c(home, away), names_to = "venue", values_to = "team") %>%
  mutate(
    goals_for = ifelse(venue == "home", fthg, ftag),
    goals_against = ifelse(venue == "home", ftag, fthg),
    win = as.integer(goals_for > goals_against),
    draw = as.integer(goals_for == goals_against),
    loss = as.integer(goals_for < goals_against)
  )

# aggregate per team-season
team_season_stats <- team_match_rows %>%
  group_by(team, season) %>%
  summarise(
    matches = n(),
    goals_for = sum(goals_for, na.rm = TRUE),
    goals_against = sum(goals_against, na.rm = TRUE),
    goal_diff = goals_for - goals_against,
    wins = sum(win, na.rm = TRUE),
    draws = sum(draw, na.rm = TRUE),
    losses = sum(loss, na.rm = TRUE),
    points = 3 * wins + draws,
    .groups = "drop"
  ) %>%
  arrange(season, desc(points))

# Save team-season master CSV
team_season_file <- file.path(OUT_DIR, "team_season_stats.csv")
fwrite(team_season_stats, team_season_file)
message("💾 Saved team-season stats -> ", team_season_file)

# Also save per-team CSVs (flat under data/)
teams <- unique(team_season_stats$team)
for (t in teams) {
  fname <- file.path(OUT_DIR, paste0(gsub(" ", "_", tolower(t)), "_summary.csv"))
  fwrite(filter(team_season_stats, team == t), fname)
}

message("📈 Saved individual team summary CSVs under data/")

# -------------------------
# 2) Load Understat files (accept JSON or CSV)
# -------------------------
xg_files <- list.files(UNDERSTAT_DIR, pattern = "\\.(json|csv)$", full.names = TRUE)
if (length(xg_files) == 0) {
  message("⚠️  No Understat files found in ", UNDERSTAT_DIR, ". Skipping xG merge. You can add JSON/CSV files there.")
  xg_team_summary <- tibble(team = character(), avg_xG = numeric(), avg_xGA = numeric(), matches = integer())
} else {
  xg_list <- list()
  for (f in xg_files) {
    team_slug <- tolower(str_remove(basename(f), "\\.(json|csv)$"))
    message("Reading xG file: ", basename(f), " -> team slug: ", team_slug)
    ext <- tools::file_ext(f)
    df <- NULL

    if (ext == "csv") {
      df <- tryCatch(read.csv(f, stringsAsFactors = FALSE), error = function(e) {
        message("  ✖ failed to read CSV: ", e$message); return(NULL)
      })
      # try to standardize column names if possible
      df <- df %>% rename_with(~tolower(.x))
      # attempt to find expected goals columns (xg, xga, etc.)
      # common columns: xg (team xG), xga (team xGA), h_team, a_team, date
    } else if (ext == "json") {
      # Understat-style JSON often has "history" array; parse that
      j <- tryCatch(fromJSON(f), error = function(e) {
        message("  ✖ failed to parse JSON: ", e$message); return(NULL)
      })
      if (!is.null(j)) {
        # if j$history exists (list or data.frame), coerce to df
        if (!is.null(j$history)) {
          df <- as.data.frame(j$history, stringsAsFactors = FALSE)
        } else {
          # if the JSON is already an array
          df <- as.data.frame(j, stringsAsFactors = FALSE)
        }
      }
    }

    if (is.null(df)) {
      message("  ⚠️ Skipped ", basename(f), " (could not parse)")
      next
    }

    # Normalize columns: ensure xG and xGA numeric columns exist and identify team columns
    colnames(df) <- tolower(colnames(df))
    possible_xg_cols <- intersect(c("xg", "xg_for", "xg_home", "hxg", "h_xg"), colnames(df))
    possible_xga_cols <- intersect(c("xga", "xg_against", "xga_home", "axg", "a_xg"), colnames(df))

    # If the file contains per-match xG from perspective of the match (h_team / a_team), attempt to map
    if (all(c("h_team", "a_team") %in% colnames(df))) {
      # compute xG for the team slug based on whether they are home or away
      df <- df %>%
        mutate(
          team = case_when(
            tolower(h_team) %in% team_slug ~ h_team,
            tolower(a_team) %in% team_slug ~ a_team,
            TRUE ~ NA_character_
          ),
          xg_val = if ("xg" %in% colnames(df) && "h_team" %in% colnames(df) && "a_team" %in% colnames(df)) {
            # Understat's usual per-row xG is for the team (if file already team-centric)
            # If ambiguous, try to infer: if team == h_team -> use hxg or xg? fallback to xg
            if ("hxg" %in% colnames(df) && "axg" %in% colnames(df)) {
              ifelse(tolower(h_team) %in% team_slug, as.numeric(hxg), as.numeric(axg))
            } else if ("xg" %in% colnames(df) && "h_goal" %in% colnames(df)) {
              # fallback: assume 'xg' is for the row-team
              as.numeric(xg)
            } else {
              NA_real_
            }
          } else {
            NA_real_
          },
          xga_val = NA_real_
        )
      # if we couldn't extract xg_val above, check for columns hxg/axg or xg/xga
      if (all(is.na(df$xg_val))) {
        if ("hxg" %in% colnames(df) & "axg" %in% colnames(df)) {
          df <- df %>% mutate(xg_val = ifelse(tolower(h_team) %in% team_slug, as.numeric(hxg), as.numeric(axg)))
        } else if ("xg" %in% colnames(df) & "xga" %in% colnames(df)) {
          # uncertain perspective; pick xg if team appears in a specific column
          df <- df %>% mutate(xg_val = as.numeric(xg), xga_val = as.numeric(xga))
        } else {
          # last resort: try columns named 'xg' and infer that it's the team's xG
          if ("xg" %in% colnames(df)) df <- df %>% mutate(xg_val = as.numeric(xg))
        }
      }
    } else {
      # If it's already team-centric (columns: team, xg, xga), standardize names
      if ("team" %in% colnames(df)) {
        if ("xg" %in% colnames(df)) df <- df %>% mutate(xg_val = as.numeric(xg))
        if ("xga" %in% colnames(df)) df <- df %>% mutate(xga_val = as.numeric(xga))
      } else {
        # fallback: attempt to find numeric xg-like columns and take averages (best-effort)
        num_cols <- names(df)[sapply(df, is.numeric)]
        xg_candidates <- num_cols[grepl("xg", num_cols)]
        if (length(xg_candidates) >= 1) df <- df %>% mutate(xg_val = as.numeric(.data[[xg_candidates[1]]]))
      }
    }

    # final safety: ensure numeric xg_val/xga_val exist
    if (!("xg_val" %in% colnames(df))) df$xg_val <- NA_real_
    if (!("xga_val" %in% colnames(df))) df$xga_val <- NA_real_

    # compute team-level averages
    avg_xg <- mean(as.numeric(df$xg_val), na.rm = TRUE)
    avg_xga <- mean(as.numeric(df$xga_val), na.rm = TRUE)
    matches_count <- sum(!is.na(df$xg_val))

    xg_list[[team_slug]] <- tibble(
      team = team_slug,
      avg_xG = ifelse(is.nan(avg_xg), NA_real_, avg_xg),
      avg_xGA = ifelse(is.nan(avg_xga), NA_real_, avg_xga),
      xg_matches = matches_count
    )
  } # end loop files

  xg_team_summary <- bind_rows(xg_list)
  # tidy team names (replace underscores with spaces for joining)
  xg_team_summary <- xg_team_summary %>% mutate(team = str_replace_all(team, "_", " "))
}

# Save xg summary
xg_file <- file.path(OUT_DIR, "xg_team_summary.csv")
fwrite(xg_team_summary, xg_file)
message("💾 Saved xG team summary -> ", xg_file)

# -------------------------
# 3) Combine team-season stats with xG features
# -------------------------
# Normalize team naming in team_season_stats to match xg summary (lowercase, trim spaces)
team_season_join <- team_season_stats %>%
  mutate(team_join = tolower(str_trim(team)))

xg_join <- xg_team_summary %>%
  mutate(team_join = tolower(str_trim(team)))

combined <- team_season_join %>%
  left_join(xg_join %>% select(team_join, avg_xG, avg_xGA, xg_matches),
            by = "team_join") %>%
  select(-team_join)

# If some teams have NA xG features, log them
missing_xg <- combined %>% filter(is.na(avg_xG)) %>% distinct(team) %>% pull(team)
if (length(missing_xg) > 0) {
  message("⚠️ xG missing for teams: ", paste(missing_xg, collapse = ", "))
  message("You can add their JSON/CSV files to data/raw/understat/ and re-run the script.")
}

# Write combined features
combined_file <- file.path(OUT_DIR, "combined_features.csv")
fwrite(combined, combined_file)
message("💾 Saved combined features -> ", combined_file)

# -------------------------
# 4) Final quick summaries and sanity checks
# -------------------------
message("📊 Quick top-5 by points in latest season:")
latest_season <- max(team_season_stats$season, na.rm = TRUE)
print(team_season_stats %>% filter(season == latest_season) %>% arrange(desc(points)) %>% head(5))

message("🎯 Feature engineering complete. Files written to: ", normalizePath(OUT_DIR))
