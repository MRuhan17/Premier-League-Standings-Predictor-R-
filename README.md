# 🏆 Premier League Standings Predictor (R)

Machine learning meets football analytics — this R project predicts **Premier League final standings** using **real match data**, **expected goals (xG)** statistics, and **Monte Carlo simulations**.

It trains advanced models (XGBoost, Random Forest) on historical data from [football-data.co.uk](https://www.football-data.co.uk/) and [Understat](https://understat.com/), then simulates the current season thousands of times to estimate each club’s probability of finishing positions (Top 4, relegation, etc.).

---

## 🚀 Features

* 📊 **Real Premier League data** — automatically fetched from open football datasets
* ⚙️ **Feature engineering** — goals for/against, xG, home/away form, goal difference, etc.
* 🧠 **Machine learning models** — XGBoost + Random Forest ensemble to predict season points
* 🎲 **Monte Carlo simulations** — generates probabilistic standings for all 20 teams
* 📦 **Fully modular pipeline** — reproducible data → model → output workflow
* 🐳 **Docker & CI ready** — portable builds with GitHub Actions integration

---

## 📁 Project Structure

```
pl-standings-predictor-R/
├── README.md
├── LICENSE
├── data-raw/                  # Data fetching scripts (football-data, Understat)
├── data/                      # Raw and processed datasets
├── R/                         # Core R scripts (feature engineering, models, simulation)
├── models/                    # Saved ML models (.rds)
├── outputs/                   # Predictions, simulation results
├── docker/                    # Dockerfile for reproducible builds
├── .github/workflows/         # CI pipeline
└── example_notebook.Rmd       # End-to-end reproducible notebook
```

---

## 🧩 Installation

### Option 1: Run locally

```bash
git clone https://github.com/<your-username>/pl-standings-predictor-R.git
cd pl-standings-predictor-R
Rscript data-raw/01_fetch_football_data.R
Rscript R/00_setup.R
Rscript R/01_feature_engineering.R
Rscript R/02_models.R
Rscript R/04_predict_and_report.R
```

### Option 2: Run with Docker

```bash
docker build -t pl-predictor .
docker run --rm -v $(pwd)/outputs:/app/outputs pl-predictor
```

---

## 🧠 Models

| Model             | Description                                         | Package        |
| ----------------- | --------------------------------------------------- | -------------- |
| **XGBoost**       | Gradient-boosted regression predicting total points | `xgboost`      |
| **Random Forest** | Baseline ensemble model for interpretability        | `randomForest` |

The final predicted standings are derived by sorting teams by predicted total points.

A Monte Carlo simulation (`R/03_simulation.R`) uses a Poisson-based attack/defense model to estimate probabilities of each finishing position.

---

## 📊 Example Output

| Rank | Team            | Predicted Points | Top 4 Probability |
| ---- | --------------- | ---------------- | ----------------- |
| 1    | Manchester City | 85.3             | 0.94              |
| 2    | Arsenal         | 80.7             | 0.88              |
| 3    | Liverpool       | 76.5             | 0.75              |
| 4    | Tottenham       | 71.1             | 0.60              |
| ...  | ...             | ...              | ...               |

*(Example — real values depend on current season data.)*

---

## ⚽ Data Sources

* [football-data.co.uk](https://www.football-data.co.uk/) — historical Premier League match results
* [Understat](https://understat.com/) — expected goals (xG) and match-level advanced stats

All data used is publicly available for non-commercial analytical use.

---

## 🧭 Next Steps / Ideas

* Integrate **Elo ratings** or **Glicko** as dynamic performance features
* Add **player-level features** (xG/xA contributions, injuries, transfers)
* Build a **Shiny dashboard** for live updating standings
* Include a **time-series model** (rolling forecasts as season progresses)

---

## 📜 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

Ruhulalemeen Mulla
Data Science & Sports Analytics Enthusiast
📧 [ruhanmulla07@gmail.com](mailto:ruhanmulla07@gmail.com)
🔗 [www.linkedin.com/in/ruhulalemeen-mulla](www.linkedin.com/in/ruhulalemeen-mulla) ·

---

*Predicting football is chaos, but modeling it is art.* ⚽🧮
