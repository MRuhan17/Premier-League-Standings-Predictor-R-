# Premier League Standings Predictor - Simplified Version
# A single script that does everything: data loading, modeling, and prediction

# ============================================================================
# SETUP AND DEPENDENCIES
# ============================================================================

cat("Premier League Standings Predictor\n")
cat("=====================================\n\n")

# Install and load required packages
required_packages <- c("randomForest", "readr")

for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("Installing", pkg, "...\n")
    install.packages(pkg, dependencies = TRUE, repos = "https://cloud.r-project.org")
    library(pkg, character.only = TRUE)
  }
}

cat("\nPackages loaded successfully!\n\n")

# ============================================================================
# SAMPLE DATA GENERATION
# ============================================================================

cat("Generating sample Premier League data...\n")

# Premier League teams
teams <- c(
  "Arsenal", "Aston Villa", "Bournemouth", "Brentford", "Brighton",
  "Chelsea", "Crystal Palace", "Everton", "Fulham", "Liverpool",
  "Luton Town", "Manchester City", "Manchester United", "Newcastle",
  "Nottingham Forest", "Sheffield United", "Tottenham", "West Ham",
  "Wolves", "Burnley"
)

# Generate historical data (last 3 seasons)
set.seed(42)
n_seasons <- 3
historical_data <- data.frame()

for (season in 1:n_seasons) {
  for (team in teams) {
    # Simulate team performance with some realistic variation
    base_strength <- runif(1, 0.3, 0.9)
    
    goals_for <- rpois(1, base_strength * 60 + 20)
    goals_against <- rpois(1, (1 - base_strength) * 50 + 20)
    wins <- rpois(1, base_strength * 20 + 5)
    draws <- rpois(1, 10)
    losses <- 38 - wins - draws
    points <- wins * 3 + draws
    
    historical_data <- rbind(historical_data, data.frame(
      Season = season,
      Team = team,
      GoalsFor = goals_for,
      GoalsAgainst = goals_against,
      Wins = wins,
      Draws = draws,
      Losses = losses,
      Points = points,
      GoalDifference = goals_for - goals_against
    ))
  }
}

cat("Sample data generated for", nrow(historical_data), "team-seasons\n\n")

# ============================================================================
# FEATURE ENGINEERING
# ============================================================================

cat("Creating features for machine learning model...\n")

# Calculate rolling averages for the current season prediction
historical_data$WinRate <- historical_data$Wins / 38
historical_data$AttackStrength <- historical_data$GoalsFor / 38
historical_data$DefenseStrength <- historical_data$GoalsAgainst / 38

cat("Features created successfully\n\n")

# ============================================================================
# MODEL TRAINING
# ============================================================================

cat("Training Random Forest model to predict points...\n")

# Prepare training data
features <- c("GoalsFor", "GoalsAgainst", "Wins", "Draws", 
              "GoalDifference", "WinRate", "AttackStrength", "DefenseStrength")

train_data <- historical_data[, c(features, "Points")]

# Train Random Forest model
rf_model <- randomForest(
  Points ~ .,
  data = train_data,
  ntree = 100,
  importance = TRUE
)

cat("Model trained successfully!\n")
cat("Model R-squared:", round(tail(rf_model$rsq, 1), 3), "\n\n")

# ============================================================================
# CURRENT SEASON PREDICTION
# ============================================================================

cat("Predicting current season standings...\n\n")

# Generate current season data (with some randomness)
set.seed(123)
current_season <- data.frame()

for (team in teams) {
  # Get team's historical average with some variation for current season
  team_history <- historical_data[historical_data$Team == team, ]
  avg_gf <- mean(team_history$GoalsFor) + rnorm(1, 0, 5)
  avg_ga <- mean(team_history$GoalsAgainst) + rnorm(1, 0, 5)
  
  goals_for <- max(15, round(avg_gf))
  goals_against <- max(15, round(avg_ga))
  
  # Estimate wins/draws based on goal difference
  gd <- goals_for - goals_against
  wins <- max(5, min(30, round(15 + gd * 0.3 + rnorm(1, 0, 3))))
  draws <- round(runif(1, 5, 12))
  losses <- 38 - wins - draws
  
  current_season <- rbind(current_season, data.frame(
    Team = team,
    GoalsFor = goals_for,
    GoalsAgainst = goals_against,
    Wins = wins,
    Draws = draws,
    Losses = losses,
    GoalDifference = goals_for - goals_against,
    WinRate = wins / 38,
    AttackStrength = goals_for / 38,
    DefenseStrength = goals_against / 38
  ))
}

# Make predictions
current_season$PredictedPoints <- predict(rf_model, current_season[, features])

# Round and ensure reasonable values
current_season$PredictedPoints <- round(pmax(20, pmin(100, current_season$PredictedPoints)))

# Sort by predicted points
standings <- current_season[order(-current_season$PredictedPoints), ]
standings$Position <- 1:nrow(standings)

# Calculate probabilities (simplified)
standings$Top4Prob <- pmax(0, pmin(1, (105 - standings$PredictedPoints) / 35))
standings$Top4Prob[1:4] <- pmax(0.75, standings$Top4Prob[1:4])
standings$RelegationProb <- pmax(0, pmin(1, (standings$PredictedPoints - 20) / 30))
standings$RelegationProb <- 1 - standings$RelegationProb
standings$RelegationProb[18:20] <- pmax(0.60, standings$RelegationProb[18:20])

# ============================================================================
# DISPLAY RESULTS
# ============================================================================

cat("\n========================================\n")
cat("   PREDICTED PREMIER LEAGUE STANDINGS\n")
cat("========================================\n\n")

# Display top section
results <- standings[, c("Position", "Team", "PredictedPoints", "GoalDifference", "Top4Prob", "RelegationProb")]
names(results) <- c("Pos", "Team", "Pts", "GD", "Top4%", "Rel%")
results$`Top4%` <- paste0(round(results$`Top4%` * 100), "%")
results$`Rel%` <- paste0(round(results$`Rel%` * 100), "%")

print(results, row.names = FALSE)

cat("\n========================================\n")
cat("\nChampionship Favorite:", standings$Team[1], "(", standings$PredictedPoints[1], "pts)\n")
cat("Top 4 (Champions League):")
cat(paste(standings$Team[1:4], collapse = ", "), "\n")
cat("Relegation Zone:")
cat(paste(standings$Team[18:20], collapse = ", "), "\n\n")

# ============================================================================
# SAVE OUTPUT
# ============================================================================

cat("Saving predictions to file...\n")

# Create outputs directory if it doesn't exist
if (!dir.exists("outputs")) {
  dir.create("outputs")
}

# Save predictions
write.csv(standings, "outputs/predicted_standings.csv", row.names = FALSE)

cat("\n✓ Predictions saved to outputs/predicted_standings.csv\n")
cat("\nPrediction complete!\n")
