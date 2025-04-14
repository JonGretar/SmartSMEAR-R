# SmartSMEAR

An R package for accessing SmartSMEAR API data. SmartSMEAR is a data visualization and download tool for atmospheric, flux, soil, tree physiological, and water quality measurements from SMEAR research stations of the University of Helsinki and the University of Eastern Finland.

## Installation

```R
# Install from GitHub:
devtools::install_github("JonGretar/SmartSMEAR")
```

## Basic Usage

```R
library(SmartSMEAR)

# Get list of all stations
stations <- get_stations()

# Get metadata for a specific measurement table
hyytiala_meta <- get_table_metadata("HYY_META")

# Search for specific variables
co2_vars <- search_variables(description = "PAR")

# Get time series data
data <- get_timeseries(
  variables = c("HYY_META.PAR"),
  start_time = "2023-01-01 00:00:00",
  end_time = "2023-01-02 00:00:00"
)
```

## Data Timing and Resolution

- Most data is recorded at 1-min or 30-min intervals
- Timestamps are in local standard time (UTC+2)
- Timestamps indicate the beginning of measurement/aggregation interval
- The API supports temporal aggregation between 1-60 minutes

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
```

## API Documentation

Full API documentation is available at:
https://smear-backend.rahtiapp.fi/swagger-ui/

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
