# SmartSMEAR

An R package for accessing [SmartSMEAR](https://smear.avaa.csc.fi/) API data.

SmartSMEAR is a data visualization and download tool for atmospheric, flux, soil, tree physiological, and water quality measurements from SMEAR research stations of the [University of Helsinki](https://helsinki.fi) and the [University of Eastern Finland](https://uef.fi).

## Installation

```R
# Install from GitHub:
devtools::install_github("JonGretar/SmartSMEAR-R")
```

## Basic Usage

```R
library(SmartSMEAR)

# Get list of all stations
stations <- search_stations()

# Get metadata for a specific measurement table
hyytiala_meta <- search_tables("HYY_META")

# Search for specific variables
par_vars <- search_variables(description = "PAR")
hyy_meta_vars <- search_variables(table = "HYY_META")

# Get time series data
data <- get_timeseries(
  variables = c("HYY_META.PAR", "HYY_META.PAR2", "HYY_META.NDVI"),
  start_time = "2023-01-01 00:00:00",
  end_time = "2023-01-02 00:00:00"
)

# Result has a 'time' column in POSIXct format:
head(data)
#                    time    HYY_META.PAR  HYY_META.PAR2 HYY_META.NDVI
# 1 2023-01-01 00:00:00   0.00      0.00     0.00
# 2 2023-01-01 00:01:00   0.00      0.00     0.00
# 3 2023-01-01 00:02:00   0.00      0.00     0.00
# 4 2023-01-01 00:03:00   0.00      0.00     0.00
# 5 2023-01-01 00:04:00   0.00      0.00     0.00
# 6 2023-01-01 00:05:00   0.00      0.00     0.00
```

## Data Timing and Resolution

- Most data is recorded at 1-min or 30-min intervals
- Timestamps are in local standard time (UTC+2)
- Timestamps indicate the beginning of measurement/aggregation interval
- The API supports temporal aggregation between 1-60 minutes
- Time values are returned as POSIXct in EET timezone

## Data Quality

- Processing level flags indicate automatic vs human-checked data
- Additional quality flags describe observation accuracy
- Use `processing_level = "CHECKED"` to get only quality-checked data

## Variable Aggregation

Different variables require different aggregation methods:

- `ARITHMETIC`: Standard measurements (default)
- `SUM`: Cumulative measurements (e.g., precipitation)
- `CIRCULAR`: Wind direction
- `NONE`: Original data without aggregation

Example with aggregation:

```R
# Get hourly averages
hourly_data <- get_timeseries(
  variables = c("HYY_META.PAR", "HYY_META.PAR2", "HYY_META.NDVI"),
  start_time = "2023-01-01 00:00:00",
  end_time = "2023-01-02 00:00:00",
  interval = 30,
  aggregation = "ARITHMETIC"
)

head(hourly_data)
#                    time    HYY_META.PAR  HYY_META.PAR2 HYY_META.NDVI
# 1 2023-01-01 00:00:00   0.00      0.00     0.00
# 2 2023-01-01 00:01:00   0.00      0.00     0.00
# 3 2023-01-01 00:02:00   0.00      0.00     0.00
# 4 2023-01-01 00:03:00   0.00      0.00     0.00
# 5 2023-01-01 00:04:00   0.00      0.00     0.00
# 6 2023-01-01 00:05:00   0.00      0.00     0.00
```

## Cleanup functions

There are a few convenience related functions available. `clear_column_prefix`
remove the table prefixes from the column names.

Note that it does not do any checks of duplicity. So if a dataframes has both
"SII1_EDDY.F_c_LI72" and "SII2_EDDY.F_c_LI72" it will result in loss of data.

```R
hyy_df <- get_timeseries(
  variables = c("SII1_EDDY.NEE","SII1_EDDY.F_c_LI72", "SII1_EDDY.F_c_LI70"),
  start_time = "2023-01-01 00:00:00", end_time = "2023-01-02 00:00:00"
)
#    time                   SII1_EDDY.F_c_LI72 SII1_EDDY.F_c_LI70 SII1_EDDY.NEE
# 1  2023-01-01 00:00:00            0.25421                NaN       0.25421
# 2  2023-01-01 00:30:00            NaN                0.22673       0.21579
# 3  2023-01-01 01:00:00           -0.19346                NaN      -0.20133

hyy_df <- clear_column_prefix(hyy_df)
#                   time   F_c_LI72   F_c_LI70   NEE
# 1  2023-01-01 00:00:00   0.25421    NaN        0.25421
# 2  2023-01-01 00:30:00   NaN        0.22673    0.21579
# 3  2023-01-01 01:00:00   -0.19346   NaN        -0.20133
```

Another helper function is `merge_device_columns` which looks for columns ending
with `c("_PIC", "_LI77", "_LI72", "_LI70", "_LGR")` and merges into a single
column. For value it uses the first non-NaN value it finds.

Optionally it saves the device whose value was used in the \_device postfix.

```R
merge_device_columns(hyy_df, record_device = TRUE)
#                   time      NEE      F_c F_c_device
# 1  2023-01-01 00:00:00  0.25421  0.25421       LI72
# 2  2023-01-01 00:30:00  0.21579  0.22673       LI70
# 3  2023-01-01 01:00:00 -0.20133 -0.19346       LI72
```

## Working with Time Data

The time series data is returned with a `time` column that is already in POSIXct format with the correct timezone (EET). This makes it easy to use with time series analysis packages and plotting libraries:

```R
# Filter data for daytime only
daytime <- subset(data, format(time, "%H") >= "06" & format(time, "%H") <= "18")

# Get daily averages using base R
daily_avg <- aggregate(PAR ~ as.Date(time), data = data, FUN = mean)

# Or use with dplyr
library(dplyr)
daily_avg <- data %>%
  group_by(date = as.Date(time)) %>%
  summarize(PAR = mean(PAR))
```

## API Documentation

Full API documentation is available at:
https://smear-backend.2.rahtiapp.fi/q/openapi-ui/

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
