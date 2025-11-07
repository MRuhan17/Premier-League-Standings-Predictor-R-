# 02_fetch_understat_xg.R

```r
# This script scrapes match-level xG (expected goals) data for all Premier League teams
# directly from Understat.com. Since Understat doesn’t have an official API, we’re using
# rvest + jsonlite to grab the embedded JSON inside each team’s webpage.
# Note: scraping should be done responsibly — avoid hitting the site too fast.

library(rvest)     # For reading HTML pages
library(jsonlite)  # For parsing the JSON data hidden inside scripts

# Full list of all 20 Premier League teams with their Understat-friendly URL names.
# If you ever need to update this, make sure to use underscores instead of spaces.
teams <- c(
  "arsenal",
  "aston_villa",
  "bournemouth",
  "brentford",
  "brighton",
  "chelsea",
  "crystal_palace",
  "everton",
  "fulham",
  "ipswich",
  "leicester",
  "liverpool",
  "manchester_city",
  "manchester_united",
  "newcastle",
  "nottingham_forest",
  "southampton",
  "tottenham",
  "west_ham",
  "wolverhampton"
)

# Folder to store JSON outputs from Understat.
out_dir <- "data/raw/understat"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Loop over each team and fetch its page for the 2020 season (you can modify this later)
for (team in teams) {
  message("⚽ Fetching data for: ", team)

  # Each team has a page like https://understat.com/team/arsenal/2020
  url <- sprintf("https://understat.com/team/%s/2020", team)

  # Read the HTML page
  page <- read_html(url)

  # Grab all <script> tags because Understat embeds JSON inside them
  scripts <- html_nodes(page, "script")
  scripts_text <- scripts %>% html_text()

  # Find the specific script containing match shots and xG data
  j <- scripts_text[grepl("shotsData", scripts_text)]

  if (length(j) > 0) {
    # Extract the JSON text from the messy JavaScript using a regex pattern
    json_text <- sub("^.*(\{\\\"shotsData.*)\\n.*$", "\\1", j)

    # Save JSON for this team locally for later processing
    writeLines(json_text, con = file.path(out_dir, paste0(team, ".json")))
    message("✅ Saved xG data for ", team)

    # A tiny delay between requests so we’re polite to the server
    Sys.sleep(2)
  } else {
    message("⚠️ Could not find xG script for ", team, " — Understat layout may have changed.")
  }
}

# Once done, you’ll have one .json file per team in data/raw/understat/
# Each contains match-by-match expected goals data.
message("📦 All xG files saved to ", out_dir)
```
