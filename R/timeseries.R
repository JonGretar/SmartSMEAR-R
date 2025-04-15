#' Get SMEAR Time Series Data
#'
#' Fetch time series data for specified variables within a time range
#'
#' @param variables Character vector of table.variable combinations
#' @param start_time Start time as character in format "YYYY-MM-DD HH:MM:SS" or POSIXt object
#' @param end_time End time as character in format "YYYY-MM-DD HH:MM:SS" or POSIXt object
#' @param interval Optional aggregation interval (1-60 minutes)
#' @param aggregation Aggregation method (NONE, ARITHMETIC, GEOMETRIC, etc.)
#' @param quality Optional quality flag filter
#' @param processing_level Processing level filter (ANY or CHECKED)
#' @return A data frame containing the time series data with a 'time' column in POSIXct format
#' @export
get_timeseries <- function(
  variables,
  start_time,
  end_time,
  interval = NULL,
  aggregation = "NONE",
  quality = NULL,
  processing_level = "ANY"
) {
  # Input validation
  if (!is.character(variables) || length(variables) == 0) {
    stop("variables must be a non-empty character vector")
  }

  # Convert text dates to POSIXct if needed
  if (is.character(start_time)) {
    start_time <- as.POSIXct(start_time, tz = "EET")
    if (is.na(start_time)) {
      stop("Invalid start_time format. Use 'YYYY-MM-DD HH:MM:SS'")
    }
  }
  if (is.character(end_time)) {
    end_time <- as.POSIXct(end_time, tz = "EET")
    if (is.na(end_time)) {
      stop("Invalid end_time format. Use 'YYYY-MM-DD HH:MM:SS'")
    }
  }

  if (!inherits(start_time, "POSIXt") || !inherits(end_time, "POSIXt")) {
    stop(
      "start_time and end_time must be either time strings or POSIXt objects"
    )
  }

  if (start_time >= end_time) {
    stop("start_time must be before end_time")
  }

  if (!is.null(interval)) {
    if (
      !is.numeric(interval) ||
        interval < 1 ||
        interval > 60 ||
        interval != round(interval)
    ) {
      stop("interval must be NULL or an integer between 1 and 60")
    }
  }

  valid_aggregations <- c(
    "NONE",
    "ARITHMETIC",
    "GEOMETRIC",
    "SUM",
    "MEDIAN",
    "MIN",
    "MAX",
    "CIRCULAR",
    "AVAILABILITY"
  )
  if (!aggregation %in% valid_aggregations) {
    stop(
      "invalid aggregation method. Must be one of: ",
      paste(valid_aggregations, collapse = ", ")
    )
  }

  if (!is.null(quality) && !is.character(quality)) {
    stop("quality must be NULL or a character value")
  }

  valid_processing <- c("ANY", "CHECKED")
  if (!processing_level %in% valid_processing) {
    stop(
      "processing_level must be one of: ",
      paste(valid_processing, collapse = ", ")
    )
  }

  # Build query parameters
  params <- make_query_list("tablevariable", variables)
  params <- add_params(
    params,
    list(
      from = format_timestamp(start_time),
      to = format_timestamp(end_time),
      interval = if (!is.null(interval)) as.integer(interval) else NULL,
      aggregation = if (aggregation != "NONE") aggregation else NULL,
      quality = quality,
      processing_level = if (processing_level != "ANY") processing_level else
        NULL
    )
  )

  # Build URL - always use CSV endpoint
  api_url <- get_api_url()
  url <- paste0(api_url, "/search/timeseries/csv")

  # Make request and get results
  result <- make_api_request(url, params, format = "csv")

  # Convert Year, Month, Day, Hour, Minute, Second columns to POSIXct time
  if (
    all(
      c("Year", "Month", "Day", "Hour", "Minute", "Second") %in% names(result)
    )
  ) {
    time_str <- with(
      result,
      sprintf(
        "%04d-%02d-%02d %02d:%02d:%02d",
        Year,
        Month,
        Day,
        Hour,
        Minute,
        Second
      )
    )
    result$time <- as.POSIXct(time_str, tz = "EET")

    # Remove individual time component columns
    result <- result[,
      !(names(result) %in%
        c("Year", "Month", "Day", "Hour", "Minute", "Second"))
    ]

    # Reorder columns to put time first
    result <- result[, c("time", setdiff(names(result), "time"))]
  }

  # Check for missing variables
  missing_vars <- setdiff(variables, names(result))
  if (length(missing_vars) > 0) {
    warning(
      "Some requested variables were not found in the response: ",
      paste(missing_vars, collapse = ", ")
    )
  }

  return(result)
}


#' Clean column names by removing table prefixes
#' @param df Data frame with column names to clean
#' @return Data frame with cleaned column names
#' @export
clear_column_prefix <- function(df) {
  # Get current column names
  col_names <- colnames(df)

  # For each column name containing a dot, extract the part after the last dot
  new_names <- sapply(col_names, function(x) {
    if (grepl("\\.", x)) {
      # Split by dot and take the last element
      utils::tail(strsplit(x, "\\.")[[1]], 1)
    } else {
      x # Return unchanged if no dot
    }
  })

  # Assign new column names
  colnames(df) <- new_names

  df
}

#' Merge columns with device suffixes and optionally record device used
#' @param df Data frame with device-suffixed columns
#' @param record_device Logical, whether to create additional columns recording which device was used
#' @return Data frame with merged columns and optionally device information
#' @export
merge_device_columns <- function(df, record_device = TRUE) {
  device_suffixes <- c("_PIC", "_LI77", "_LI72", "_LI70", "_LGR")

  # Get all column names
  col_names <- colnames(df)

  # Find base variable names (without device suffix)
  base_vars <- unique(unlist(lapply(device_suffixes, function(suffix) {
    # Find columns ending with this suffix
    cols_with_suffix <- col_names[grepl(paste0(suffix, "$"), col_names)]
    # Remove suffix to get base names
    gsub(suffix, "", cols_with_suffix)
  })))

  # Create new dataframe to store results
  result_df <- df

  # Process each base variable
  for (base_var in base_vars) {
    # Find all columns for this base variable
    device_cols <- c()
    for (suffix in device_suffixes) {
      col_name <- paste0(base_var, suffix)
      if (col_name %in% col_names) {
        device_cols <- c(device_cols, col_name)
      }
    }

    if (length(device_cols) > 0) {
      # Create new merged column
      merged_values <- Reduce(
        function(x, y) ifelse(is.na(x), y, x),
        lapply(device_cols, function(col) df[[col]])
      )
      result_df[[base_var]] <- merged_values

      # Record which device was used (if requested)
      if (record_device) {
        device_col_name <- paste0(base_var, "_device")
        result_df[[device_col_name]] <- NA_character_

        # For each row, find which device column had the non-NA value
        for (i in seq_len(nrow(df))) {
          for (col in device_cols) {
            if (!is.na(df[i, col])) {
              # Extract device suffix and remove leading underscore
              device <- sub(".*(_.*)", "\\1", col)
              device <- sub("^_", "", device)
              result_df[i, device_col_name] <- device
              break
            }
          }
        }
      }

      # Remove original device-specific columns
      result_df <- result_df[, !colnames(result_df) %in% device_cols]
    }
  }

  return(result_df)
}
