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
  params <- list(
    tablevariable = paste(variables, collapse = ","),
    from = format_timestamp(start_time),
    to = format_timestamp(end_time)
  )

  params <- add_params(
    params,
    list(
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
