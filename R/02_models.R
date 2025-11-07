# ==========================================
# 02_models.R
# ==========================================
# Trains ensemble ML models (Random Forest + XGBoost)
# to predict total season points and final standings.
# ==========================================

library(tidyverse)
library(randomForest)
library(xgboost)
library(data.table)

message("⚙️ Starting model training pipeline...")

# --- Load processed feature dataset ---
features_path <- "data/combined_features.csv"
if (!file.exists(features_path)) stop("❌ Missing combined_features.csv")

data <- fread(features_path)

message("✅ Loaded combined features: ", nrow(data), " teams")

# --- Data prep ---
# We'll predict 'Points' using xG, xGA, GoalsFor, GoalsAgainst
model_data <- data %>%
  select(Team = HomeTeam, GoalsFor, GoalsAgainst, xG, xGA, Points)

if ("Team" %in% names(model_data)) {
  rownames(model_data) <- model_data$Team
  model_data$Team <- NULL
}

# --- Split into features + target ---
X <- as.matrix(model_data[, c("GoalsFor", "GoalsAgainst", "xG", "xGA")])
y <- model_data$Points

# --- Random Forest model ---
set.seed(42)
rf_model <- randomForest(X, y, ntree = 500)
rf_pred <- predict(rf_model, X)

message("🌲 Trained Random Forest model")

# --- XGBoost model ---
dtrain <- xgb.DMatrix(data = X, label = y)
params <- list(
  objective = "reg:squarederror",
  eval_metric = "rmse",
  max_depth = 4,
  eta = 0.1,
  subsample = 0.8
)

xgb_model <- xgb.train(params = params, data = dtrain, nrounds = 100, verbose = 0)
xgb_pred <- predict(xgb_model, dtrain)

message("⚡ Trained XGBoost model")

# --- Ensemble (average predictions) ---
pred_points <- (rf_pred + xgb_pred) / 2

# --- Combine and rank standings ---
predicted_standings <- data.frame(
  Team = rownames(model_data),
  PredictedPoints = round(pred_points, 1)
) %>%
  arrange(desc(PredictedPoints)) %>%
  mutate(Rank = row_number())

# --- Save outputs ---
dir.create("outputs", showWarnings = FALSE, recursive = TRUE)
write.csv(predicted_standings, "outputs/predicted_standings.csv", row.names = FALSE)

message("💾 Saved predicted standings to outputs/predicted_standings.csv")

# --- Print final table ---
message("\n🏆 Predicted Premier League Standings:")
print(predicted_standings, row.names = FALSE)

message("✅ Model training complete.")
