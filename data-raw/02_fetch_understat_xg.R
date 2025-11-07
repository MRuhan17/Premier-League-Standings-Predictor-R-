# ==========================================
# 02_fetch_understat_xg_api.R
# ==========================================
# Fetches xG data for all Premier League
# 2024–25 teams using the Understatr API
# and saves them as CSVs.
# ==========================================

library(understatr)
library(dplyr)

teams <- c(
  "Arsenal", "Aston Villa", "Bournemouth", "Brentford", "Brighton",
  "Chelsea", "Crystal Palace", "Everton", "Fulham", "Ipswich",
  "Leicester", "Liverpool", "Manchester City", "Manchester United",
  "Newcastle United", "Nottingham Forest", "Southampton",
  "Tottenham", "West Ham", "Wolves"
)

out_dir <- "data/raw/understat"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

for (team in teams) {
  message("⚽ Fetching xG data for: ", team)
  df <- us_get_team_results(team)
  out_path <- file.path(out_dir, paste0(gsub(" ", "_", tolower(team)), ".csv"))
  write.csv(df, out_path, row.names = FALSE)
  message("✅ Saved: ", out_path)
  Sys.sleep(1)
}

message("🏁 All team xG CSVs saved under data/raw/understat/")
