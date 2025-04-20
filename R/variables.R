#' Search SMEAR Variables
#'
#' Search for variables in the SMEAR database using various filters. Returns
#' detailed information about each matching variable including its description,
#' metadata, measurement periods, and quality indicators.
#'
#' @param category Filter by variable category (e.g., "EDDY", "MET", "HYD")
#' @param description Filter by variable description text
#' @param source Filter by data source
#' @param station Filter by station identifier (e.g., "HYY" for Hyytiälä)
#' @param table Filter by table name (e.g., "HYY_META")
#' @param variable Filter by variable name
#' @param tablevariable Filter by table.variable combination
#'                      (e.g., "HYY_META.CO2")
#' @param format Response format ("json", "csv", or "tsv")
#' @return A data frame containing matching variables with the following
#'         columns:
#'   \itemize{
#'     \item \code{variable} - Variable identifier
#'     \item \code{description} - Human-readable description of the variable
#'     \item \code{tableName} - Name of the table containing this variable
#'     \item \code{tableId} - Numeric identifier of the table
#'     \item \code{title} - Title of the variable
#'     \item \code{unit} - Measurement unit
#'     \item \code{source} - Data source identifier
#'     \item \code{category} - Variable category
#'     \item \code{periodStart} - Start of measurement period as POSIXct
#'     \item \code{periodEnd} - End of measurement period as POSIXct
#'     \item \code{timestamp} - Last update time as POSIXct
#'     \item \code{rights} - Data usage rights
#'     \item \code{identifier} - Unique identifier
#'     \item \code{type} - Data type
#'     \item \code{coverage} - Spatial coverage information
#'     \item \code{mandatory} - Whether the variable is mandatory
#'   }
#' @export
search_variables <- function(
  category = NULL,
  description = NULL,
  source = NULL,
  station = NULL,
  table = NULL,
  variable = NULL,
  tablevariable = NULL,
  format = c("json", "csv", "tsv")
) {
  # Input validation
  format <- match.arg(format)

  # Build query parameters
  params <- list()
  params <- add_params(
    params,
    list(
      category = category,
      description = description,
      source = source,
      station = station,
      table = table,
      variable = variable,
      tablevariable = tablevariable
    )
  )

  # Build URL
  api_url <- get_api_url()
  endpoint <- build_endpoint("/search/variable", format)
  url <- paste0(api_url, endpoint)

  # Make request and get results
  result <- make_api_request(url, params, format)

  # Convert timestamp columns to POSIXct
  time_columns <- c("periodStart", "periodEnd", "timestamp")
  for (col in time_columns) {
    if (col %in% names(result) && !is.null(result[[col]])) {
      # Handle both ISO8601 strings and numeric timestamps
      if (is.character(result[[col]])) {
        result[[col]] <- as.POSIXct(result[[col]], tz = "EET")
      } else if (is.numeric(result[[col]])) {
        # Assuming Unix timestamp in milliseconds
        result[[col]] <- as.POSIXct(
          result[[col]] / 1000,
          origin = "1970-01-01",
          tz = "EET"
        )
      }
    }
  }

  return(result)
}
