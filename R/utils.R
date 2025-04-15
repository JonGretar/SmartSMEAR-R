# API request utilities

#' Get the base API URL from environment or default
#' @return The base API URL
#' @keywords internal
get_api_url <- function() {
  Sys.getenv("SMEAR_API_URL", "https://smear-backend.2.rahtiapp.fi")
}

#' Make an API request with error handling
#' @param url The full URL for the request
#' @param params List of query parameters
#' @param format Response format ("json", "csv", or "tsv")
#' @return The parsed response content
#' @keywords internal
make_api_request <- function(
  url,
  params = list(),
  format = c("json", "csv", "tsv")
) {
  format <- match.arg(format)

  # Define content type based on format
  content_type <- switch(
    format,
    "json" = "application/json",
    "csv" = "text/csv",
    "tsv" = "text/plain"
  )

  # Make HTTP GET request
  response <- httr::GET(
    url = url,
    query = params,
    httr::timeout(60),
    httr::add_headers(
      "Accept" = content_type,
      "User-Agent" = sprintf(
        "SmartSMEAR-R/%s",
        utils::packageVersion("SmartSMEAR")
      )
    )
  )

  # Check for HTTP errors and provide clear error message
  if (httr::http_error(response)) {
    status <- httr::status_code(response)
    error_content <- tryCatch(
      httr::content(response, "text", encoding = "UTF-8"),
      error = function(e) "Unable to read error response"
    )
    stop(sprintf("API request failed (HTTP %d): %s", status, error_content))
  }

  # Parse response based on format
  content <- httr::content(response, "text", encoding = "UTF-8")

  if (format == "json") {
    parsed <- jsonlite::fromJSON(content, simplifyVector = TRUE)
  } else if (format %in% c("csv", "tsv")) {
    # Create temp file for the content
    tmp <- tempfile()
    on.exit(unlink(tmp))
    writeLines(content, tmp)

    # Read CSV/TSV with fill=TRUE to handle uneven columns
    parsed <- if (format == "csv") {
      utils::read.csv(
        tmp,
        stringsAsFactors = FALSE,
        fill = TRUE,
        na.strings = c("NA", ""),
        blank.lines.skip = TRUE
      )
    } else {
      utils::read.delim(
        tmp,
        stringsAsFactors = FALSE,
        fill = TRUE,
        na.strings = c("NA", ""),
        blank.lines.skip = TRUE
      )
    }
  }

  # Ensure result is a data frame
  if (!is.data.frame(parsed)) {
    parsed <- as.data.frame(parsed)
  }

  return(parsed)
}

#' Format a timestamp for the SMEAR API (ISO 8601 in UTC+2)
#' @param time POSIXt object to format
#' @return Formatted timestamp string
#' @keywords internal
format_timestamp <- function(time) {
  if (attr(time, "tzone") != "EET") {
    time <- format(as.POSIXct(time, tz = "EET"), "%Y-%m-%dT%H:%M:%S")
  } else {
    time <- format(time, "%Y-%m-%dT%H:%M:%S")
  }
  return(time)
}

#' Build API endpoint URL
#' @param base_path Base API path (e.g., "/search/variable")
#' @param format Response format
#' @return Complete endpoint URL
#' @keywords internal
build_endpoint <- function(base_path, format = c("json", "csv", "tsv")) {
  format <- match.arg(format)
  if (format == "json") {
    return(base_path)
  } else {
    return(paste0(base_path, "/", format))
  }
}

#' Add non-NULL parameters to a parameter list
#' @param params Existing parameter list
#' @param new_params Named list of new parameters to add if non-NULL
#' @return Updated parameter list
#' @keywords internal
add_params <- function(params, new_params) {
  for (name in names(new_params)) {
    value <- new_params[[name]]
    if (!is.null(value)) {
      params[[name]] <- value
    }
  }
  return(params)
}

#' Create a list with the same keyname for each value
#' @param params The key to use
#' @param variables List of variables
#' @return Updated parameter list
#' @keywords internal
make_query_list <- function(keyname, variables) {
  params <- rep(keyname, length(variables))
  query_list <- stats::setNames(as.list(variables), params)
  query_list
}
