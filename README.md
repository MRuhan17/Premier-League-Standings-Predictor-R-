# 🏆 Premier League Standings Predictor (R)

**A simple, streamlined R script that predicts Premier League final standings using machine learning.**

## 🎯 What It Does

This project uses a **Random Forest** model to predict how Premier League teams will finish the season. The script:
- Generates sample historical data for 20 Premier League teams
- Trains a machine learning model on team statistics
- Predicts final standings with point totals and probabilities
- Outputs predictions to a CSV file

## 🚀 Quick Start

### Prerequisites
- R (version 4.0 or higher)
- RStudio (optional but recommended)

### Installation & Usage

1. **Clone the repository:**
```bash
git clone https://github.com/MRuhan17/Premier-League-Standings-Predictor-R-.git
cd Premier-League-Standings-Predictor-R-
```

2. **Run the prediction script:**
```r
Rscript predict_standings.R
```

That's it! The script will:
- Automatically install required packages (`randomForest`, `readr`)
- Generate sample data
- Train the model
- Display predicted standings
- Save results to `outputs/predicted_standings.csv`

## 📊 Example Output

The script displays a table like this:

```
 Pos              Team Pts  GD Top4% Rel%
   1   Manchester City  89  45   75%   0%
   2         Liverpool  85  38   85%   0%
   3           Arsenal  82  32   88%   0%
   4         Tottenham  75  18   75%   0%
   ...
  18    Nottingham F.  35 -22    0%  65%
  19  Sheffield United  32 -28    0%  70%
  20       Luton Town   28 -35    0%  80%
```

## 🛠️ How It Works

1. **Data Generation**: Creates 3 seasons of historical data with realistic team statistics
2. **Feature Engineering**: Calculates metrics like win rate, attack/defense strength, goal difference
3. **Model Training**: Uses Random Forest regression to learn patterns from historical performance
4. **Prediction**: Applies the model to current season data to predict final points
5. **Probability Calculation**: Estimates Top 4 and relegation probabilities based on predicted points

## 📁 What's Included

```
Premier-League-Standings-Predictor-R-/
├── predict_standings.R    # Main script - does everything!
├── outputs/               # Generated predictions saved here
├── README.md             # This file
└── LICENSE               # MIT License
```

## 🎨 Features

- ✅ **Self-contained**: Everything in one script
- ✅ **No external data required**: Generates sample data automatically  
- ✅ **Auto-installs packages**: No manual setup needed
- ✅ **Readable output**: Clear console display and CSV export
- ✅ **Realistic predictions**: Based on actual Premier League team performance patterns

## 🔮 Future Enhancements

 Want to make this even better? Consider:
- Fetching real match data from APIs like football-data.co.uk
- Adding expected goals (xG) statistics from Understat
- Building a Shiny dashboard for interactive visualization
- Implementing Monte Carlo simulations for probability estimation
- Including player-level data and injury information

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Ruhulalemeen Mulla**  
Data Science & Sports Analytics Enthusiast  
📧 ruhanmulla07@gmail.com  
🔗 [LinkedIn](https://www.linkedin.com/in/ruhulalemeen-mulla)

---

*Predicting football is chaos, but modeling it is art.* ⚽🧮
