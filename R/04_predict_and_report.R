# ==========================================
# 04_predict_and_report.R
# ==========================================
# Train ML models (XGBoost + Random Forest)
# to predict final Premier League standings
# from engineered and simulated data.
#
# Input:  data/combined_features.csv
# Output: outputs/final_predictions.csv
#         outputs/prediction_plot.png
#         models/xgb_model.rds, models/rf_model.rds
# ==========================================

library(tidyverse)
library(data.table)
library(xgboost)
library(randomForest)
library(ggplot2)
library(scales)

set.seed(42)

# -------------------------
# 1️⃣ Load data
# -------------------------
input_file <- "data/combined_features.csv"
if (!file.exists(input_file)) stop("❌ combined_features.csv not found! Run 01_feature_engineering.R first.")

data <- fread(input_file)

# Make sure required columns exist
required_cols <- c("points", "wins", "draws", "losses", "goal_diff", "avg_xG", "avg_xGA")
missing_cols <- setdiff(required_cols, names(data))
if (length(missing_cols) > 0) stop("❌ Missing columns: ", paste(missing_cols, collapse = ", "))

# -------------------------
# 2️⃣ Feature prep
# -------------------------
model_data <- data %>%
  mutate(
    points = as.numeric(points),
    goals_for = ifelse(is.na(goals_for), 0, goals_for),
    goals_against = ifelse(is.na(goals_against), 0, goals_against)
  ) %>%
  select(team, season, points, wins, draws, losses, goal_diff, goals_for, goals_against, avg_xG, avg_xGA)

# Drop missing
model_data <- na.omit(model_data)

# Split train/test (last season test)
latest_season <- max(model_data$season)
train <- model_data %>% filter(season < latest_season)
test <- model_data %>% filter(season == latest_season)

# -------------------------
# 3️⃣ Prepare matrices
# -------------------------
x_train <- as.matrix(train %>% select(-team, -season, -points))
y_train <- train$points
x_test <- as.matrix(test %>% select(-team, -season, -points))
teams_test <- test$team

# -------------------------
# 4️⃣ Train XGBoost model
# -------------------------
dtrain <- xgb.DMatrix(data = x_train, label = y_train)
params <- list(
  objective = "reg:squarederror",
  eval_metric = "rmse",
  eta = 0.1,
  max_depth = 4,
  subsample = 0.8
)

message("🚀 Training XGBoost model...")
xgb_model <- xgb.train(params = params, data = dtrain, nrounds = 200, verbose = 0)
message("✅ XGBoost model trained.")

# -------------------------
# 5️⃣ Train Random Forest model
# -------------------------
message("🌲 Training Random Forest model...")
rf_model <- randomForest(
  points ~ wins + draws + losses + goal_diff + goals_for + goals_against + avg_xG + avg_xGA,
  data = train,
  ntree = 500
)
message("✅ Random Forest model trained.")

# -------------------------
# 6️⃣ Save models
# -------------------------
dir.create("models", showWarnings = FALSE)
saveRDS(xgb_model, "models/xgb_model.rds")
saveRDS(rf_model, "models/rf_model.rds")
message("💾 Saved trained models to /models")

# -------------------------
# 7️⃣ Generate predictions
# -------------------------
xgb_pred <- predict(xgb_model, as.matrix(test %>% select(-team, -season, -points)))
rf_pred <- predict(rf_model, test)

# Ensemble average (weighted more toward XGBoost)
pred_points <- (0.7 * xgb_pred + 0.3 * rf_pred)

pred_df <- tibble(
  team = teams_test,
  predicted_points = round(pred_points, 1)
) %>%
  arrange(desc(predicted_points)) %>%
  mutate(rank = row_number())

# -------------------------
# 8️⃣ Save predictions
# -------------------------
dir.create("outputs", showWarnings = FALSE)
fwrite(pred_df, "outputs/final_predictions.csv")
message("💾 Saved final predictions -> outputs/final_predictions.csv")

# -------------------------
# 9️⃣ Visualization
# -------------------------
plot <- ggplot(pred_df, aes(x = reorder(team, predicted_points), y = predicted_points)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +
  labs(
    title = "🏆 Predicted Premier League Final Standings",
    subtitle = paste0("Based on ML models trained on ", latest_season - 1, " seasons of data"),
    x = "",
    y = "Predicted Points"
  ) +
  theme_minimal(base_size = 13) +
  geom_text(aes(label = predicted_points), hjust = -0.2) +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12)
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1)))

ggsave("outputs/prediction_plot.png", plot, width = 8, height = 6, dpi = 300)
message("📊 Saved visualization -> outputs/prediction_plot.png")

# -------------------------
# 🔟 Display top standings
# -------------------------
message("\n🏁 Final Predicted Standings:\n")
print(pred_df)

message("\n✨ Done! Outputs saved in /outputs and /models/")
