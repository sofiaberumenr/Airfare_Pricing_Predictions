# ============================================================================
# FLIGHT PRICE TIME SERIES ANALYSIS
# Following class exercise format
# ============================================================================

# Load libraries
library(forecast)
library(ggplot2)
library(dplyr)
library(lubridate)
library(plotly)
library(dygraphs)
library(gridExtra)

# Try to load smooth package for SMA, if not available use alternative
if (!require(smooth)) {
  cat("Installing 'smooth' package for SMA...\n")
  install.packages("smooth")
  library(smooth)
}

# ============================================================================
# 1. LOAD DATA AND CREATE TIME SERIES
# ============================================================================

# Load the daily time series data
flight.data <- read.csv("data/flight_daily_timeseries.csv")

# Convert date column to Date type (handle DD/MM/YY format)
flight.data$searchDate <- as.Date(flight.data$searchDate, format = "%d/%m/%y")

# Sort by date
flight.data <- flight.data %>% arrange(searchDate)

# View the data structure
cat("\n=== DATA STRUCTURE ===\n")
str(flight.data)
head(flight.data)
summary(flight.data$totalFare_mean)

# Create time series object (frequency = 7 for weekly seasonality)
# Using weekly frequency since we have ~6 months of daily data
tsfare <- ts(flight.data$totalFare_mean, frequency = 7)

# Check the time series
tsfare

# ============================================================================
# 2. EXPLORATORY GRAPHS
# ============================================================================

# Basic plot
p <- autoplot(tsfare) +
  ggtitle("Daily Average Flight Prices") +
  xlab("Time") +
  ylab("Average Total Fare ($)")
print(p)

# Interactive plotly version
ggplotly(p)

# Interactive dygraphs version (skip if ts object causes issues)
tryCatch({
  dygraph(tsfare, main = "Daily Average Flight Prices") %>%
    dyRangeSelector()
}, error = function(e) {
  cat("Note: Skipping dygraph due to ts object format\n")
})

# Check subset of data
window(tsfare, start = 1, end = 50)  # First 50 days

# ============================================================================
# 3. LAG PLOTS AND AUTOCORRELATION
# ============================================================================

# Lag plots
gglagplot(tsfare, set.lags = 1, diag.col = "black", do.lines = FALSE)
gglagplot(tsfare, set.lags = 7, diag.col = "black", do.lines = FALSE)  # Weekly lag

# ACF and PACF
ggAcf(tsfare, lag.max = 50)
ggPacf(tsfare, lag.max = 50)

# ============================================================================
# 4. SPLIT TRAIN AND TEST DATA
# ============================================================================

# Use 80% for training, 20% for testing
n_total <- length(tsfare)
n_train <- round(0.8 * n_total)
n_test <- n_total - n_train

# Split using subset instead of window
tsfare_train <- ts(tsfare[1:n_train], frequency = 7)
tsfare_test <- ts(tsfare[(n_train + 1):n_total], frequency = 7)

cat("\n=== DATA SPLIT ===\n")
cat("Total observations:", n_total, "\n")
cat("Training observations:", n_train, "\n")
cat("Testing observations:", n_test, "\n")
cat("Training data length:", length(tsfare_train), "\n")
cat("Testing data length:", length(tsfare_test), "\n")

# ============================================================================
# 5. NAIVE FORECAST (BASELINE)
# ============================================================================

cat("\n=== NAIVE FORECAST ===\n")
tsforecast <- forecast(tsfare_train, h = n_test)
autoplot(tsforecast)
summary(tsforecast)

# ============================================================================
# 6. DECOMPOSITION
# ============================================================================

cat("\n=== TIME SERIES DECOMPOSITION ===\n")
fare.decomp <- decompose(tsfare_train, "additive")
autoplot(fare.decomp)

# Check ACF of random component
ggAcf(fare.decomp$random, na.action = na.pass)
checkresiduals(fare.decomp$random)

# ============================================================================
# 7. FITTING MULTIPLE MODELS
# ============================================================================

cat("\n=== FITTING MODELS ===\n")

# 1. Naive
fare.naive <- naive(tsfare_train, h = n_test)

# 2. Average
fare.ave <- meanf(tsfare_train, h = n_test)

# 3. Drift
fare.drift <- rwf(tsfare_train, drift = TRUE, h = n_test)

# 4. Simple Moving Average
# Using smooth package's sma() function
tryCatch({
  fare.sma <- sma(tsfare_train, h = n_test)
}, error = function(e) {
  cat("Note: Using alternative SMA method\n")
  # Alternative: use ma() from forecast package
  fare.sma <<- forecast(ma(tsfare_train, order = 7), h = n_test)
})

# 5. Simple Exponential Smoothing
fare.ses <- ses(tsfare_train, h = n_test)
summary(fare.ses)

# 6. ETS (Exponential Smoothing State Space)
fit.ets <- ets(tsfare_train)
summary(fit.ets)
fare.ets <- forecast(fit.ets, h = n_test)

# 7. ARMA (no differencing, no seasonality)
fit.arma <- auto.arima(tsfare_train, d = 0, seasonal = FALSE)
summary(fit.arma)
fare.arma <- forecast(fit.arma, h = n_test)

# 8. ARIMA (with differencing, no seasonality)
fit.arima <- auto.arima(tsfare_train, seasonal = FALSE)
summary(fit.arima)
fare.arima <- forecast(fit.arima, h = n_test)

# 9. SARIMA (with seasonality)
fit.sarima <- auto.arima(tsfare_train, seasonal = TRUE)
summary(fit.sarima)
fare.sarima <- forecast(fit.sarima, h = n_test)

# ============================================================================
# 8. PLOT ALL FORECASTS TOGETHER
# ============================================================================

cat("\n=== PLOTTING ALL FORECASTS ===\n")

# Create a data frame with actual dates for better plotting
dates_all <- flight.data$searchDate
dates_train <- dates_all[1:n_train]
dates_test <- dates_all[(n_train + 1):n_total]

# Full view with actual dates
df_plot <- data.frame(
  Date = dates_all,
  Actual = as.numeric(tsfare)
)

# Add forecast dates
forecast_dates <- seq(max(dates_train) + 1, by = "day", length.out = n_test)

df_forecasts <- data.frame(
  Date = forecast_dates,
  Naive = as.numeric(fare.naive$mean),
  Average = as.numeric(fare.ave$mean),
  Drift = as.numeric(fare.drift$mean),
  SMA = as.numeric(fare.sma$forecast),
  SES = as.numeric(fare.ses$mean),
  ETS = as.numeric(fare.ets$mean),
  ARMA = as.numeric(fare.arma$mean),
  ARIMA = as.numeric(fare.arima$mean),
  SARIMA = as.numeric(fare.sarima$mean)
)

# Plot with actual dates
p1 <- ggplot() +
  geom_line(data = df_plot, aes(x = Date, y = Actual), color = "black", size = 0.8) +
  geom_line(data = df_forecasts, aes(x = Date, y = Naive, color = "Naive")) +
  geom_line(data = df_forecasts, aes(x = Date, y = Average, color = "Average")) +
  geom_line(data = df_forecasts, aes(x = Date, y = Drift, color = "Drift")) +
  geom_line(data = df_forecasts, aes(x = Date, y = SMA, color = "SMA")) +
  geom_line(data = df_forecasts, aes(x = Date, y = SES, color = "SES")) +
  geom_line(data = df_forecasts, aes(x = Date, y = ETS, color = "ETS")) +
  geom_line(data = df_forecasts, aes(x = Date, y = ARMA, color = "ARMA")) +
  geom_line(data = df_forecasts, aes(x = Date, y = ARIMA, color = "ARIMA")) +
  geom_line(data = df_forecasts, aes(x = Date, y = SARIMA, color = "SARIMA")) +
  geom_vline(xintercept = as.numeric(max(dates_train)), linetype = "dashed", color = "gray50") +
  scale_color_manual(values = c(
    "Naive" = "blue", "Average" = "orange", "Drift" = "green",
    "SMA" = "pink", "SES" = "purple", "ETS" = "cyan",
    "ARMA" = "brown", "ARIMA" = "red", "SARIMA" = "darkblue"
  )) +
  labs(
    title = "Flight Price Forecasts - All Models",
    x = "Date",
    y = "Average Total Fare ($)",
    color = "Model"
  ) +
  theme_minimal() +
  theme(legend.position = "right")

print(p1)

# Zoomed view (last 50 days + forecast)
zoom_days <- 50
zoom_start_idx <- max(1, n_train - zoom_days)
df_plot_zoom <- df_plot[zoom_start_idx:nrow(df_plot), ]

p2 <- ggplot() +
  geom_line(data = df_plot_zoom, aes(x = Date, y = Actual), color = "black", size = 1) +
  geom_line(data = df_forecasts, aes(x = Date, y = Naive, color = "Naive"), size = 0.8) +
  geom_line(data = df_forecasts, aes(x = Date, y = Average, color = "Average"), size = 0.8) +
  geom_line(data = df_forecasts, aes(x = Date, y = Drift, color = "Drift"), size = 0.8) +
  geom_line(data = df_forecasts, aes(x = Date, y = SMA, color = "SMA"), size = 0.8) +
  geom_line(data = df_forecasts, aes(x = Date, y = SES, color = "SES"), size = 0.8) +
  geom_line(data = df_forecasts, aes(x = Date, y = ETS, color = "ETS"), size = 0.8) +
  geom_line(data = df_forecasts, aes(x = Date, y = ARMA, color = "ARMA"), size = 0.8) +
  geom_line(data = df_forecasts, aes(x = Date, y = ARIMA, color = "ARIMA"), size = 0.8) +
  geom_line(data = df_forecasts, aes(x = Date, y = SARIMA, color = "SARIMA"), size = 0.8) +
  geom_vline(xintercept = as.numeric(max(dates_train)), linetype = "dashed", color = "gray50") +
  scale_color_manual(values = c(
    "Naive" = "blue", "Average" = "orange", "Drift" = "green",
    "SMA" = "pink", "SES" = "purple", "ETS" = "cyan",
    "ARMA" = "brown", "ARIMA" = "red", "SARIMA" = "darkblue"
  )) +
  labs(
    title = "Flight Price Forecasts - Zoomed View (Last 50 Days + Forecast)",
    x = "Date",
    y = "Average Total Fare ($)",
    color = "Model"
  ) +
  theme_minimal() +
  theme(legend.position = "right")

print(p2)

# Note: Best models comparison plot will be created after accuracy analysis

# ============================================================================
# 9. CHECK RESIDUALS
# ============================================================================

cat("\n=== CHECKING RESIDUALS ===\n")

checkresiduals(fare.naive)
checkresiduals(fare.ave)
checkresiduals(fare.drift)
checkresiduals(fare.sma)
checkresiduals(fare.ses)
checkresiduals(fare.ets)
checkresiduals(fare.arma)
checkresiduals(fare.arima)
checkresiduals(fare.sarima)

# Alternative: Box-Ljung test
cat("\n=== BOX-LJUNG TESTS ===\n")
Box.test(fare.naive$residuals, lag = 10, type = "Lj")
Box.test(fare.ave$residuals, lag = 10, type = "Lj")
Box.test(fare.drift$residuals, lag = 10, type = "Lj")
Box.test(fare.sma$residuals, lag = 10, type = "Lj")
Box.test(fare.ses$residuals, lag = 10, type = "Lj")
Box.test(fare.ets$residuals, lag = 10, type = "Lj")
Box.test(fare.arma$residuals, lag = 10, type = "Lj")
Box.test(fare.arima$residuals, lag = 10, type = "Lj")
Box.test(fare.sarima$residuals, lag = 10, type = "Lj")

# ============================================================================
# 10. CHECK ACCURACY ON TEST DATA
# ============================================================================

cat("\n=== ACCURACY ON TEST DATA ===\n")

# Convert to numeric vectors to avoid window() issues
test_actual <- as.numeric(tsfare_test)

acc_naive <- accuracy(as.numeric(fare.naive$mean), test_actual)
acc_ave <- accuracy(as.numeric(fare.ave$mean), test_actual)
acc_drift <- accuracy(as.numeric(fare.drift$mean), test_actual)
acc_sma <- accuracy(as.numeric(fare.sma$forecast), test_actual)
acc_ses <- accuracy(as.numeric(fare.ses$mean), test_actual)
acc_ets <- accuracy(as.numeric(fare.ets$mean), test_actual)
acc_arma <- accuracy(as.numeric(fare.arma$mean), test_actual)
acc_arima <- accuracy(as.numeric(fare.arima$mean), test_actual)
acc_sarima <- accuracy(as.numeric(fare.sarima$mean), test_actual)

# Print accuracies
cat("\nNaive:\n")
print(acc_naive)
cat("\nAverage:\n")
print(acc_ave)
cat("\nDrift:\n")
print(acc_drift)
cat("\nSMA:\n")
print(acc_sma)
cat("\nSES:\n")
print(acc_ses)
cat("\nETS:\n")
print(acc_ets)
cat("\nARMA:\n")
print(acc_arma)
cat("\nARIMA:\n")
print(acc_arima)
cat("\nSARIMA:\n")
print(acc_sarima)

# ============================================================================
# 11. COMPARE MODELS
# ============================================================================

cat("\n=== MODEL COMPARISON ===\n")

# Create comparison table - extract test set metrics (row 2)
comparison <- data.frame(
  Model = c("Naive", "Average", "Drift", "SMA", "SES", "ETS", "ARMA", "ARIMA", "SARIMA"),
  RMSE = c(acc_naive[1, "RMSE"], acc_ave[1, "RMSE"], acc_drift[1, "RMSE"], 
           acc_sma[1, "RMSE"], acc_ses[1, "RMSE"], acc_ets[1, "RMSE"], 
           acc_arma[1, "RMSE"], acc_arima[1, "RMSE"], acc_sarima[1, "RMSE"]),
  MAE = c(acc_naive[1, "MAE"], acc_ave[1, "MAE"], acc_drift[1, "MAE"], 
          acc_sma[1, "MAE"], acc_ses[1, "MAE"], acc_ets[1, "MAE"], 
          acc_arma[1, "MAE"], acc_arima[1, "MAE"], acc_sarima[1, "MAE"]),
  MAPE = c(acc_naive[1, "MAPE"], acc_ave[1, "MAPE"], acc_drift[1, "MAPE"], 
           acc_sma[1, "MAPE"], acc_ses[1, "MAPE"], acc_ets[1, "MAPE"], 
           acc_arma[1, "MAPE"], acc_arima[1, "MAPE"], acc_sarima[1, "MAPE"])
)

# Sort by RMSE (lower is better)
comparison <- comparison[order(comparison$RMSE), ]

cat("\n=== MODEL RANKING (by RMSE) ===\n")
print(comparison)

cat("\n🏆 BEST MODEL:", comparison$Model[1], "\n")
cat("   RMSE:", round(comparison$RMSE[1], 2), "\n")
cat("   MAE:", round(comparison$MAE[1], 2), "\n")
cat("   MAPE:", round(comparison$MAPE[1], 2), "%\n")

# Visualize comparison
ggplot(comparison, aes(x = reorder(Model, RMSE), y = RMSE)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +
  ggtitle("Model Comparison - RMSE (Lower is Better)") +
  xlab("Model") +
  ylab("RMSE")

ggplot(comparison, aes(x = reorder(Model, MAPE), y = MAPE)) +
  geom_bar(stat = "identity", fill = "darkgreen") +
  coord_flip() +
  ggtitle("Model Comparison - MAPE (Lower is Better)") +
  xlab("Model") +
  ylab("MAPE (%)")

# Plot top 3 models based on RMSE
top3_models <- as.character(comparison$Model[1:3])
cat("\n📊 Plotting top 3 models:", paste(top3_models, collapse = ", "), "\n")

# Create zoomed data for better visualization
zoom_days <- 50
zoom_start_idx <- max(1, n_train - zoom_days)
df_plot_zoom <- data.frame(
  Date = dates_all[zoom_start_idx:n_total],
  Actual = as.numeric(tsfare[zoom_start_idx:n_total])
)

# Prepare data for top 3 models
df_top3 <- data.frame(
  Date = forecast_dates,
  Model1 = df_forecasts[[top3_models[1]]],
  Model2 = df_forecasts[[top3_models[2]]],
  Model3 = df_forecasts[[top3_models[3]]]
)

# Create color palette
model_colors <- c(
  "Actual" = "black",
  "Naive" = "blue", "Average" = "orange", "Drift" = "green",
  "SMA" = "pink", "SES" = "purple", "ETS" = "cyan",
  "ARMA" = "brown", "ARIMA" = "red", "SARIMA" = "darkblue"
)

# Build plot with top 3 models
p_best <- ggplot() +
  geom_line(data = df_plot_zoom, aes(x = Date, y = Actual, color = "Actual"), size = 1.2) +
  geom_line(data = df_top3, aes(x = Date, y = Model1, color = top3_models[1]), size = 1) +
  geom_line(data = df_top3, aes(x = Date, y = Model2, color = top3_models[2]), size = 1) +
  geom_line(data = df_top3, aes(x = Date, y = Model3, color = top3_models[3]), size = 1) +
  geom_vline(xintercept = as.numeric(max(dates_train)), linetype = "dashed", color = "gray50") +
  scale_color_manual(
    values = model_colors,
    breaks = c("Actual", top3_models[1], top3_models[2], top3_models[3])
  ) +
  labs(
    title = "Flight Price Forecasts - Top 3 Models by RMSE",
    subtitle = paste("🥇", top3_models[1], "| 🥈", top3_models[2], "| 🥉", top3_models[3]),
    x = "Date",
    y = "Average Total Fare ($)",
    color = "Series"
  ) +
  theme_minimal() +
  theme(legend.position = "right")

print(p_best)

# ============================================================================
# 12. SAVE RESULTS TO CSV
# ============================================================================

cat("\n=== SAVING RESULTS ===\n")

# Put all forecasts together
results <- data.frame(
  Naive = fare.naive$mean,
  Average = fare.ave$mean,
  Drift = fare.drift$mean,
  SMA = fare.sma$forecast,
  SES = fare.ses$mean,
  ETS = fare.ets$mean,
  ARMA = fare.arma$mean,
  ARIMA = fare.arima$mean,
  SARIMA = fare.sarima$mean,
  Actual = tsfare_test
)

print(head(results, 10))

# Save to CSV
write.csv(results, "results/forecast_comparison.csv", row.names = FALSE)
write.csv(comparison, "results/model_accuracy_comparison.csv", row.names = FALSE)

cat("\nResults saved to:\n")
cat("  - results/forecast_comparison.csv\n")
cat("  - results/model_accuracy_comparison.csv\n")

# ============================================================================
# 13. BEST MODEL DETAILS
# ============================================================================

cat("\n=== BEST MODEL DETAILS ===\n")

best_model_name <- as.character(comparison$Model[1])
cat("Best model based on RMSE:", best_model_name, "\n\n")

if (best_model_name == "SARIMA") {
  cat("SARIMA Model Summary:\n")
  print(summary(fit.sarima))
  cat("\nForecast:\n")
  print(fare.sarima)
  autoplot(fare.sarima) +
    ggtitle("SARIMA Forecast with Confidence Intervals")
} else if (best_model_name == "ARIMA") {
  cat("ARIMA Model Summary:\n")
  print(summary(fit.arima))
  cat("\nForecast:\n")
  print(fare.arima)
  autoplot(fare.arima) +
    ggtitle("ARIMA Forecast with Confidence Intervals")
} else if (best_model_name == "ETS") {
  cat("ETS Model Summary:\n")
  print(summary(fit.ets))
  cat("\nForecast:\n")
  print(fare.ets)
  autoplot(fare.ets) +
    ggtitle("ETS Forecast with Confidence Intervals")
}

cat("\n=== ANALYSIS COMPLETE ===\n")
