#!/usr/bin/env python3
import pandas as pd
import matplotlib.pyplot as plt

print("=" * 80)
print("CLEANING OUTLIERS")
print("=" * 80)

df = pd.read_csv('data/flight_daily_timeseries.csv')
df['searchDate'] = pd.to_datetime(df['searchDate'])

print(f"\nOriginal: {df.shape[0]} days")
print(f"Mean fare: ${df['totalFare_mean'].mean():.2f}")

# Find outliers
Q1 = df['totalFare_mean'].quantile(0.25)
Q3 = df['totalFare_mean'].quantile(0.75)
IQR = Q3 - Q1
upper_bound = Q3 + 1.5 * IQR

outliers = df[df['totalFare_mean'] > upper_bound]
print(f"\nOutliers found: {len(outliers)}")
print(outliers[['searchDate', 'totalFare_mean']])

# Clean
df_clean = df.copy()
for idx, row in outliers.iterrows():
    date = row['searchDate']
    surrounding = df[
        (df['searchDate'] >= date - pd.Timedelta(days=7)) & 
        (df['searchDate'] <= date + pd.Timedelta(days=7)) &
        (df['searchDate'] != date)
    ]
    replacement = surrounding['totalFare_mean'].median()
    print(f"\n{date.strftime('%Y-%m-%d')}: ${row['totalFare_mean']:.2f} → ${replacement:.2f}")
    df_clean.loc[df_clean['searchDate'] == date, 'totalFare_mean'] = replacement
    df_clean.loc[df_clean['searchDate'] == date, 'totalFare_median'] = surrounding['totalFare_median'].median()

df_clean.to_csv('data/flight_daily_timeseries.csv', index=False)
print(f"\n✓ Cleaned! New mean: ${df_clean['totalFare_mean'].mean():.2f}")
