# SmartSMEAR

An R package for accessing SmartSMEAR API data. SmartSMEAR is a data visualization and download tool for atmospheric, flux, soil, tree physiological, and water quality measurements from SMEAR research stations of the University of Helsinki and the University of Eastern Finland.

## Installation

```R
# Install from GitHub:
devtools::install_github("JonGretar/SmartSMEAR-R")
```

## Basic Usage

```R
library(SmartSMEAR)

# Get list of all stations
stations <- get_stations()

# Get metadata for a specific measurement table
hyytiala_meta <- get_table_metadata("HYY_META")

# Search for specific variables
par_vars <- search_variables(description = "PAR")

# Get time series data
data <- get_timeseries(
  variables = c("HYY_META.PAR"),
  start_time = "2023-01-01 00:00:00",
  end_time = "2023-01-02 00:00:00"
)

# Result has a 'time' column in POSIXct format:
head(data)
#                    time    PAR
# 1 2023-01-01 00:00:00   0.00
# 2 2023-01-01 00:01:00   0.00
# 3 2023-01-01 00:02:00   0.00
# 4 2023-01-01 00:03:00   0.00
# 5 2023-01-01 00:04:00   0.00
# 6 2023-01-01 00:05:00   0.00
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
  variables = c("HYY_META.PAR"),
  start_time = "2023-01-01 00:00:00",
  end_time = "2023-01-02 00:00:00",
  interval = 60,
  aggregation = "ARITHMETIC"
)

head(hourly_data)
#                    time    PAR
# 1 2023-01-01 00:00:00   0.00
# 2 2023-01-01 01:00:00   0.00
# 3 2023-01-01 02:00:00   0.00
# 4 2023-01-01 03:00:00   0.00
# 5 2023-01-01 04:00:00   0.00
# 6 2023-01-01 05:00:00   0.00
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
https://smear-backend.rahtiapp.fi/swagger-ui/

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
