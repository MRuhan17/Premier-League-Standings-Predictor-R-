# ==========================================
# 00_setup.R
# ==========================================
# Environment setup script for:
# Premier League Standings Predictor (R)
#
# Installs + loads required packages,
# creates folder structure, and sets constants.
# Run this once before the rest of the pipeline.
# ==========================================

# --- Helper function to install missing packages ---
install_if_missing <- function(pkgs) {
  new_pkgs <- pkgs[!(pkgs %in% installed.packages()[, "Package"])]
  if (length(new_pkgs)) {
    message("📦 Installing missing packages: ", paste(new_pkgs, collapse = ", "))
    install.packages(new_pkgs, dependencies = TRUE)
  }
}

# --- Core package dependencies ---
required_pkgs <- c(
  "tidyverse", "jsonlite", "data.table", "lubridate", "xgboost",
  "randomForest", "understatr", "rvest", "httr", "ggplot2"
)

install_if_missing(required_pkgs)

# --- Load them into the session ---
invisible(lapply(required_pkgs, library, character.only = TRUE))

message("✅ All packages loaded successfully.")

# --- Directory structure setup ---
dirs <- c(
  "data/raw",
  "data/processed",
  "data/raw/understat",
  "models",
  "outputs"
)

for (d in dirs) {
  if (!dir.exists(d)) {
    dir.create(d, recursive = TRUE, showWarnings = FALSE)
    message("📁 Created folder: ", d)
  }
}

# --- Constants (season, league codes, etc.) ---
SEASON <- "2425"
LEAGUE_CODE <- "E0"  # Premier League (football-data.co.uk)

message("⚙️ Environment initialized.")
message("🏁 Ready to run 01_fetch_football_data.R and 02_fetch_understat_xg_api.R")
