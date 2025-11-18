# Flight Price Time Series Analysis Guide

## Overview
This guide will help you perform comprehensive time series analysis on flight prices using R.

## Prerequisites

### 1. First, run the Python notebook
Run the time series export cell in your Jupyter notebook to generate the CSV files:
- `flight_daily_timeseries.csv` (main file for analysis)
- `flight_weekly_timeseries.csv`
- `flight_monthly_timeseries.csv`
- And others...

### 2. Install R packages
Open R or RStudio and run:
```r
install.packages(c("forecast", "tseries", "ggplot2", "dplyr", 
                   "lubridate", "prophet", "zoo"))
```

## How to Run the Analysis

### Option 1: Run the complete script
```r
source("flight_timeseries_analysis.R")
```

### Option 2: Run step-by-step in RStudio
1. Open `flight_timeseries_analysis.R` in RStudio
2. Run sections one at a time (Ctrl+Enter or Cmd+Enter)
3. Review outputs and plots as you go

## What the Analysis Does

### 1. **Data Loading & Preparation**
- Loads the daily aggregated flight price data
- Converts to proper time series format
- Shows summary statistics

### 2. **Exploratory Analysis**
- Plots the original time series
- Decomposes into trend, seasonal, and random components
- Creates ACF/PACF plots to identify patterns

### 3. **Stationarity Testing**
- Augmented Dickey-Fuller (ADF) test
- KPSS test
- Applies differencing if needed

### 4. **ARIMA Modeling**
- Automatically selects best ARIMA model
- Tests residuals for white noise
- Validates model assumptions

### 5. **Forecasting**
- Forecasts next 30 days of prices
- Provides confidence intervals (80% and 95%)
- Creates forecast plots

### 6. **Exponential Smoothing (ETS)**
- Alternative forecasting method
- Automatically selects best ETS model
- Compares with ARIMA

### 7. **Prophet (Optional)**
- Facebook's Prophet algorithm
- Handles multiple seasonality
- Robust to missing data and outliers

### 8. **Model Comparison**
- Compares ARIMA vs ETS using AIC/BIC
- Shows accuracy metrics (RMSE, MAE, MAPE)
- Helps you choose the best model

## Output Files

After running the script, you'll find:

### Plots (in `plots/` folder):
- `ts_original_series.png` - Original time series
- `ts_decomposition.png` - Trend, seasonal, and residual components
- `ts_acf_pacf.png` - Autocorrelation plots
- `ts_differenced.png` - Differenced series (if needed)
- `arima_residuals.png` - Residual diagnostics
- `arima_forecast.png` - ARIMA forecast with confidence intervals
- `ets_forecast.png` - ETS forecast
- `prophet_forecast.png` - Prophet forecast (if installed)
- `prophet_components.png` - Prophet decomposition

### Results (in `results/` folder):
- `arima_forecast.csv` - Forecast values with confidence intervals
- `model_summary.txt` - Detailed model summaries and comparison

## Interpreting Results

### Stationarity Tests
- **ADF test**: p-value < 0.05 means series is stationary
- **KPSS test**: p-value > 0.05 means series is stationary

### Model Selection
- **Lower AIC/BIC** = Better model
- **Lower RMSE/MAE** = Better predictions
- **MAPE** = Mean Absolute Percentage Error (lower is better)

### Residual Diagnostics
- Residuals should look like white noise (random)
- ACF of residuals should show no significant autocorrelation
- Ljung-Box test p-value > 0.05 (residuals are white noise)

## Common Time Series Models

### ARIMA(p,d,q)
- **p** = autoregressive order
- **d** = differencing order
- **q** = moving average order
- Good for: Linear trends, stationary data

### ETS (Error, Trend, Seasonal)
- Exponential smoothing
- Good for: Data with clear trend/seasonality
- More robust to outliers than ARIMA

### Prophet
- Developed by Facebook
- Good for: Multiple seasonality, holidays, missing data
- Very user-friendly

## Tips for Better Results

1. **Check for outliers**: Extreme values can affect forecasts
2. **Try different frequencies**: Weekly (7), monthly (30), etc.
3. **Use cross-validation**: Test on holdout data
4. **Consider external factors**: Holidays, events, fuel prices
5. **Ensemble methods**: Combine multiple models

## Advanced Analysis (Optional)

### Seasonal ARIMA (SARIMA)
```r
sarima_model <- auto.arima(ts_price, 
                           seasonal = TRUE,
                           D = 1,  # seasonal differencing
                           max.P = 2, max.Q = 2)
```

### Vector Autoregression (VAR)
If you have multiple time series (e.g., prices for different routes):
```r
library(vars)
# Combine multiple series
multi_ts <- cbind(route1_prices, route2_prices)
var_model <- VAR(multi_ts, p = 2)
```

### GARCH Models
For modeling volatility:
```r
library(rugarch)
spec <- ugarchspec(variance.model = list(model = "sGARCH"))
garch_model <- ugarchfit(spec, ts_price)
```

## Troubleshooting

### Error: "Series is not stationary"
- Apply differencing: `diff(ts_price)`
- Or use `ndiffs()` to find optimal differencing order

### Error: "Not enough observations"
- Use weekly or monthly aggregation instead of daily
- Reduce forecast horizon

### Warning: "Model did not converge"
- Try different starting parameters
- Simplify the model (reduce p, q values)

## Next Steps

1. **Run the script** and review all outputs
2. **Compare models** using AIC/BIC and accuracy metrics
3. **Validate forecasts** against actual future data
4. **Refine models** based on residual diagnostics
5. **Document findings** for your analysis

## Resources

- [Forecasting: Principles and Practice](https://otexts.com/fpp3/) - Free online book
- [ARIMA Tutorial](https://www.datascience.com/blog/introduction-to-forecasting-with-arima-in-r-learn-data-science-tutorials)
- [Prophet Documentation](https://facebook.github.io/prophet/docs/quick_start.html)

## Questions?

Common questions and answers:

**Q: Which model should I use?**
A: Start with auto.arima() - it automatically selects the best ARIMA model. Compare with ETS and Prophet.

**Q: How far ahead can I forecast?**
A: Generally, shorter forecasts are more accurate. Start with 7-30 days.

**Q: My forecasts look flat - is that normal?**
A: Yes, if there's no strong trend or seasonality, forecasts converge to the mean.

**Q: Should I use daily, weekly, or monthly data?**
A: Daily for short-term forecasts, weekly/monthly for long-term trends.

Good luck with your analysis! 🚀
