# ==========================================
# 03_generate_mock_understat_jsons.R
# ==========================================
# Creates synthetic Understat-style JSONs
# for all 20 Premier League teams so the
# project can run without scraping.
# ==========================================

library(jsonlite)

teams <- c(
  "Arsenal", "Aston Villa", "Bournemouth", "Brentford", "Brighton",
  "Chelsea", "Crystal Palace", "Everton", "Fulham", "Ipswich",
  "Leicester", "Liverpool", "Manchester City", "Manchester United",
  "Newcastle", "Nottingham Forest", "Southampton", "Tottenham",
  "West Ham", "Wolves"
)

out_dir <- "data/raw/understat"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

set.seed(42)

for (team in teams) {
  matches <- data.frame(
    h_team = sample(teams, 5, replace = TRUE),
    a_team = sample(teams, 5, replace = TRUE),
    h_goals = sample(0:4, 5, replace = TRUE),
    a_goals = sample(0:4, 5, replace = TRUE),
    xG = round(runif(5, 0.5, 3.0), 2),
    xGA = round(runif(5, 0.5, 3.0), 2),
    date = seq.Date(as.Date("2024-08-10"), by = "week", length.out = 5),
    result = sample(c("w", "d", "l"), 5, replace = TRUE)
  )
  
  json <- list(
    id = as.character(which(teams == team)),
    title = team,
    history = matches
  )
  
  json_path <- file.path(out_dir, paste0(tolower(gsub(" ", "_", team)), ".json"))
  write_json(json, json_path, pretty = TRUE, auto_unbox = TRUE)
  message("✅ Created ", json_path)
}

message("🏁 All 20 mock team JSONs created successfully!")
