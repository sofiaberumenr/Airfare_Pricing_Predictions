# Understanding Time Series Plots - X-Axis Explained

## What Does the X-Axis Mean?

### In Your Original Plot (Before Fix):
- **X-axis showed**: Generic "Time" units (0, 5, 10, 15, 20, 25)
- **What it meant**: "Cycles" based on frequency setting
- **With frequency = 7**: Each unit ≈ 1 week (7 days)
  - 0 = Start
  - 5 = ~5 weeks (35 days)
  - 10 = ~10 weeks (70 days)
  - 20 = ~20 weeks (140 days)
  - 25 = ~25 weeks (175 days)

### In Your Fixed Plot (After Update):
- **X-axis shows**: Actual calendar dates
- **What it means**: Real dates from your dataset
- **Example**: "2022-04-16", "2022-05-01", "2022-06-15", etc.
- **Much clearer!** You can see exactly when prices change

## Why This Matters

### Your Data:
- **Daily flight prices** (one observation per day)
- **Date range**: April 2022 to October 2022 (about 6 months)
- **Total observations**: ~171 days

### The Forecast:
- **Training period**: First 80% of data (~137 days)
- **Test period**: Last 20% of data (~34 days)
- **Forecast horizon**: 34 days into the future

## Understanding the Plot Elements

### Black Line (Historical Data):
- Shows actual flight prices from your dataset
- Each point = average price for that day
- Shows the trend and patterns over time

### Colored Lines (Forecasts):
- Each color = different forecasting model
- Start where the dashed line is (end of training data)
- Show predicted prices for the test period

### Dashed Vertical Line:
- Marks the split between training and test data
- Everything left = used to train models
- Everything right = predictions being tested

## Time Series Frequency Explained

### What is `frequency = 7`?
- Tells R that data has **weekly seasonality**
- Means patterns repeat every 7 days
- Makes sense for flight prices (weekday vs weekend patterns)

### Other Common Frequencies:
- **frequency = 1**: No seasonality (random walk)
- **frequency = 12**: Monthly data with yearly seasonality
- **frequency = 365**: Daily data with yearly seasonality
- **frequency = 52**: Weekly data with yearly seasonality

### For Your Flight Data:
- **Daily observations** with **weekly patterns**
- **frequency = 7** is appropriate
- Captures Monday-Sunday price variations

## Reading Your Plot

### What to Look For:

1. **Trend**: Is price generally going up or down?
   - Your data shows a **downward trend** over time

2. **Seasonality**: Do prices repeat in patterns?
   - Look for regular ups and downs
   - Weekly patterns (weekday vs weekend)

3. **Volatility**: How much do prices jump around?
   - Your data shows **high volatility** (lots of spikes)

4. **Forecast Accuracy**: Do colored lines match actual prices?
   - Lines closer to black line = better model
   - Flat lines (like "Average") = poor forecast

## Model Behavior in Your Plot

### Flat Lines (Average, SMA):
- Predict same price every day
- Ignore trends and patterns
- Usually perform poorly

### Sloped Lines (Drift):
- Predict linear trend
- Don't capture seasonality
- Better than flat, but still simple

### Curved/Adaptive Lines (ETS, ARIMA, SARIMA):
- Adapt to patterns in data
- Capture trends and seasonality
- Usually perform best

## Time Scale Summary

| Your Data | Time Unit | Meaning |
|-----------|-----------|---------|
| **Observations** | Daily | One price per day |
| **Total Period** | ~171 days | ~6 months |
| **Training** | ~137 days | ~4.5 months |
| **Testing** | ~34 days | ~1 month |
| **Frequency** | 7 | Weekly seasonality |

## Key Takeaways

✅ **X-axis now shows actual dates** - much easier to interpret!

✅ **Each point = 1 day** - daily average flight prices

✅ **Dashed line = forecast start** - separates history from predictions

✅ **Colored lines = different models** - compare which predicts best

✅ **Black line = truth** - what actually happened

## Next Steps

1. **Look at the zoomed plot** - easier to see forecast details
2. **Check the accuracy table** - which model has lowest RMSE?
3. **Examine residuals** - are they random (white noise)?
4. **Choose best model** - based on accuracy and residual diagnostics

The fixed plots now show **real calendar dates** on the x-axis, making it much clearer when prices change and how far ahead you're forecasting!
