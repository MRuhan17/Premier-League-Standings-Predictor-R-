# ==========================================
# Premier League Standings Predictor (R)
# Dockerfile
# ==========================================

# ---- Base image ----
FROM rocker/tidyverse:4.4.0

# Maintainer
LABEL maintainer="Your Name <your.email@example.com>" \
      description="Premier League Standings Predictor in R with ML and simulation" \
      version="1.0"

# ---- Install system dependencies ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev libssl-dev libxml2-dev libgit2-dev \
    libxt6 libglpk40 libharfbuzz-dev libfribidi-dev \
    && rm -rf /var/lib/apt/lists/*

# ---- Set working directory ----
WORKDIR /app

# ---- Copy project files ----
COPY . /app

# ---- Install R package dependencies ----
# (Prevents reinstallation if packages are cached)
RUN R -e "install.packages(c('data.table','dplyr','tidyr','lubridate','jsonlite','xgboost','randomForest','rvest','httr','Metrics','ggplot2','scales','purrr','readr'))"

# ---- Create output and model folders ----
RUN mkdir -p data/raw data/processed data/raw/understat models outputs

# ---- Default command ----
# Runs the full pipeline when the container starts
CMD ["bash", "-c", "Rscript R/00_setup.R && Rscript R/01_feature_engineering.R && Rscript R/03_simulation.R && Rscript R/04_predict_and_report.R && Rscript R/05_model_summary.R && Rscript R/06_generate_predictions.R"]
