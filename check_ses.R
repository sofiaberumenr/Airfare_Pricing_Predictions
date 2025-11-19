# Quick check of SES model
library(forecast)

# Load data
flight.data <- read.csv("data/flight_daily_timeseries.csv")
flight.data$searchDate <- as.Date(flight.data$searchDate, format = "%d/%m/%y")
flight.data <- flight.data[order(flight.data$searchDate), ]

# Create time series
tsfare <- ts(flight.data$totalFare_mean, frequency = 7)

# Split data
n_total <- length(tsfare)
n_train <- round(0.8 * n_total)
tsfare_train <- ts(tsfare[1:n_train], frequency = 7)

# Fit SES
fare.ses <- ses(tsfare_train, h = 34)

# Print model details
cat("=== SES MODEL DETAILS ===\n")
print(summary(fare.ses))

cat("\n=== MODEL PARAMETERS ===\n")
cat("Alpha (smoothing parameter):", fare.ses$model$par["alpha"], "\n")
cat("Initial level:", fare.ses$model$par["l"], "\n")
cat("Final level:", tail(fare.ses$fitted, 1), "\n")

cat("\n=== FORECAST VALUES (first 10) ===\n")
print(head(fare.ses$mean, 10))

cat("\n=== LAST 10 TRAINING VALUES ===\n")
print(tail(tsfare_train, 10))
