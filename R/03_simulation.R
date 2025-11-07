# ==========================================
# 03_simulation.R
# ==========================================
# Monte Carlo Premier League Season Simulation
# using Poisson attack/defense strength model
#
# Input:  data/combined_features.csv
# Output: outputs/standings_simulations.csv
#          outputs/team_probabilities.csv
#
# Notes:
#  - Uses expected goals (xG, xGA) to estimate attack/defense
#  - Simulates N seasons (default: 10,000)
#  - Calculates probabilities of finishing positions
# ==========================================

library(dplyr)
library(tidyr)
library(data.table)
library(lubridate)
library(purrr)

set.seed(42)

# -------------------------
# 1️⃣ Load data
# -------------------------
input_file <- "data/combined_features.csv"
if (!file.exists(input_file)) stop("❌ combined_features.csv not found! Run 01_feature_engineering.R first.")

teams_df <- fread(input_file)
teams_df <- teams_df %>%
  filter(!is.na(points)) %>%
  mutate(team = trimws(team))

if (!all(c("avg_xG", "avg_xGA") %in% names(teams_df))) {
  stop("❌ Missing xG columns. Did you run 01_feature_engineering.R with Understat data?")
}

teams <- teams_df$team
n_teams <- length(teams)

# -------------------------
# 2️⃣ Estimate team strengths
# -------------------------
# Attack strength ~ relative xG
# Defense strength ~ relative xGA (inverted)
mean_xg <- mean(teams_df$avg_xG, na.rm = TRUE)
mean_xga <- mean(teams_df$avg_xGA, na.rm = TRUE)

teams_df <- teams_df %>%
  mutate(
    attack_strength = avg_xG / mean_xg,
    defense_strength = mean_xga / avg_xGA
  )

# sanity check for missing xG
teams_df <- teams_df %>%
  mutate(
    attack_strength = ifelse(is.na(attack_strength), 1, attack_strength),
    defense_strength = ifelse(is.na(defense_strength), 1, defense_strength)
  )

# -------------------------
# 3️⃣ Match simulation function
# -------------------------
simulate_match <- function(home_team, away_team, teams_df, home_adv = 1.15) {
  home_row <- filter(teams_df, team == home_team)
  away_row <- filter(teams_df, team == away_team)

  lambda_home <- home_adv * home_row$attack_strength * away_row$defense_strength * mean_xg
  lambda_away <- away_row$attack_strength * home_row$defense_strength * mean_xg

  home_goals <- rpois(1, lambda_home)
  away_goals <- rpois(1, lambda_away)

  home_points <- ifelse(home_goals > away_goals, 3,
                        ifelse(home_goals == away_goals, 1, 0))
  away_points <- ifelse(away_goals > home_goals, 3,
                        ifelse(away_goals == home_goals, 1, 0))

  tibble(
    home_team, away_team,
    home_goals, away_goals,
    home_points, away_points
  )
}

# -------------------------
# 4️⃣ Full season simulation
# -------------------------
simulate_season <- function(teams_df) {
  fixtures <- expand.grid(home_team = teams_df$team, away_team = teams_df$team) %>%
    filter(home_team != away_team)

  results <- pmap_dfr(
    list(fixtures$home_team, fixtures$away_team),
    simulate_match,
    teams_df = teams_df
  )

  standings <- results %>%
    pivot_longer(cols = c(home_points, away_points), names_to = "side", values_to = "points") %>%
    mutate(team = ifelse(side == "home_points", home_team, away_team)) %>%
    group_by(team) %>%
    summarise(
      total_points = sum(points, na.rm = TRUE),
      goals_scored = sum(ifelse(side == "home_points", home_goals, away_goals), na.rm = TRUE),
      goals_against = sum(ifelse(side == "home_points", away_goals, home_goals), na.rm = TRUE),
      goal_diff = goals_scored - goals_against,
      .groups = "drop"
    ) %>%
    arrange(desc(total_points), desc(goal_diff), desc(goals_scored)) %>%
    mutate(rank = row_number())

  standings
}

# -------------------------
# 5️⃣ Monte Carlo loop
# -------------------------
n_sims <- 10000
message("🎲 Running ", n_sims, " simulated seasons...")

sim_list <- vector("list", n_sims)

pb <- txtProgressBar(min = 0, max = n_sims, style = 3)
for (i in 1:n_sims) {
  sim_list[[i]] <- simulate_season(teams_df)
  setTxtProgressBar(pb, i)
}
close(pb)

message("\n✅ Simulation complete.")

# combine all seasons
sim_data <- bind_rows(sim_list, .id = "sim_id")

# -------------------------
# 6️⃣ Compute probabilities
# -------------------------
prob_table <- sim_data %>%
  group_by(team, rank) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(team) %>%
  mutate(prob = n / sum(n)) %>%
  ungroup()

# probability of finishing positions
prob_summary <- prob_table %>%
  group_by(team) %>%
  summarise(
    title_prob = sum(prob[rank == 1]),
    top4_prob = sum(prob[rank <= 4]),
    midtable_prob = sum(prob[rank >= 5 & rank <= 10]),
    relegation_prob = sum(prob[rank >= 18]),
    avg_rank = sum(rank * prob),
    .groups = "drop"
  ) %>%
  arrange(avg_rank)

# -------------------------
# 7️⃣ Save outputs
# -------------------------
dir.create("outputs", showWarnings = FALSE)
fwrite(sim_data, "outputs/standings_simulations.csv")
fwrite(prob_summary, "outputs/team_probabilities.csv")

message("💾 Saved all simulation results to /outputs/")
message("🏆 Example probabilities:\n")
print(head(prob_summary, 8))
