# ==========================================
# 01_feature_engineering.R
# ==========================================
# Combines football-data results + Understat xG data
# into a single dataset for modeling Premier League standings.
# ==========================================

library(tidyverse)
library(jsonlite)
library(lubridate)
library(data.table)

message("⚙️ Starting feature engineering pipeline...")

# --- Paths ---
matches_path <- "data/raw/E0_2425.csv"
understat_dir <- "data/raw/understat"
output_path <- "data/combined_features.csv"

# --- Load football-data.co.uk match results ---
if (!file.exists(matches_path)) stop("❌ Missing E0_2425.csv")
matches <- fread(matches_path)

# Clean and rename columns for clarity
matches <- matches %>%
  rename(
    Date = Date,
    HomeTeam = HomeTeam,
    AwayTeam = AwayTeam,
    FTHG = FTHG,   # Full Time Home Goals
    FTAG = FTAG,   # Full Time Away Goals
    FTR = FTR      # Match Result (H/A/D)
  ) %>%
  mutate(Date = as.Date(Date, format = "%d/%m/%Y"))

message("✅ Loaded ", nrow(matches), " matches from football-data.co.uk")

# --- Load all Understat xG data ---
json_files <- list.files(understat_dir, pattern = "\\.json$", full.names = TRUE)
if (length(json_files) == 0) stop("❌ No JSON files found in data/raw/understat")

get_team_xg <- function(path) {
  dat <- fromJSON(path)
  df <- as.data.frame(dat$history)
  df$team <- dat$title
  return(df)
}

xg_data <- lapply(json_files, get_team_xg) %>%
  bind_rows() %>%
  mutate(date = as.Date(date))

message("✅ Loaded xG data for ", length(unique(xg_data$team)), " teams")

# --- Merge results with xG stats ---
combined <- matches %>%
  left_join(
    xg_data,
    by = c("HomeTeam" = "h_team", "AwayTeam" = "a_team"),
    relationship = "many-to-many"
  )

# --- Feature engineering ---
# Create total goals, goal difference, and rolling averages
features <- combined %>%
  mutate(
    HomePoints = case_when(
      FTR == "H" ~ 3,
      FTR == "D" ~ 1,
      TRUE ~ 0
    ),
    AwayPoints = case_when(
      FTR == "A" ~ 3,
      FTR == "D" ~ 1,
      TRUE ~ 0
    )
  ) %>%
  group_by(HomeTeam) %>%
  summarise(
    GoalsFor = sum(FTHG, na.rm = TRUE),
    GoalsAgainst = sum(FTAG, na.rm = TRUE),
    xG = sum(xG, na.rm = TRUE),
    xGA = sum(xGA, na.rm = TRUE),
    Wins = sum(HomePoints == 3),
    Draws = sum(HomePoints == 1),
    Losses = sum(HomePoints == 0),
    Points = sum(HomePoints)
  ) %>%
  arrange(desc(Points))

message("📊 Engineered team-level features")

# --- Save processed dataset ---
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
write.csv(features, output_path, row.names = FALSE)
message("💾 Saved combined feature dataset to: ", output_path)
message("🏁 Feature engineering complete.")
