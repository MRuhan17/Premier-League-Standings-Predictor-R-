# 01_fetch_football_data.R

```r
# This script downloads historical Premier League data from football-data.co.uk
# Each season is saved locally as a CSV inside data/raw/ for later feature engineering.
# Basically, we’re grabbing multiple seasons of results so the model can learn long-term trends.

# Define the seasons we want to fetch. The codes match football-data’s naming conventions.
season_map <- list(
  "2020-21" = "2021",
  "2019-20" = "2020",
  "2018-19" = "2019",
  "2017-18" = "2018",
  "2016-17" = "2017",
  "2015-16" = "2016"
)

# Create the output directory if it doesn’t already exist
out_dir <- "data/raw"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Loop over every season and download the corresponding CSV
for (code in season_map) {
  # football-data.co.uk uses the pattern mmz4281/<season_code>/E0.csv for Premier League data
  url <- sprintf("https://www.football-data.co.uk/mmz4281/%s/E0.csv", code)
  dest <- file.path(out_dir, paste0("E0_", code, ".csv"))

  # Try to download the file. If something fails (like missing season), it just prints a message.
  tryCatch({
    download.file(url, destfile = dest, mode = "wb")
    message("✅ Downloaded: ", dest)
  }, error = function(e) {
    message("⚠️ Failed to download: ", url)
  })
}

# When the script finishes, you should see CSV files in data/raw/ named like:
#   E0_2021.csv, E0_2020.csv, etc.
# Each one has columns for Date, HomeTeam, AwayTeam, FTHG (home goals), FTAG (away goals), and more.

# Quick sanity check: list all downloaded files
message("📁 Files downloaded:")
print(list.files(out_dir, pattern = "E0_.*\\.csv", full.names = TRUE))
```
