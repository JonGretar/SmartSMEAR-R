#' Get SMEAR Table Metadata
#'
#' Get metadata for SMEAR data tables. If table_name is provided, returns detailed
#' metadata for that specific table. If no table_name is provided, returns a list
#' of all available tables.
#'
#' @param table_name Optional table name (e.g., "HYY_META")
#' @return A data frame containing table metadata. When a specific table is requested,
#'         includes detailed information about that table's structure and variables.
#' @export
get_table_metadata <- function(table_name = NULL) {
  # Build URL
  api_url <- get_api_url()

  if (!is.null(table_name)) {
    if (!is.character(table_name) || length(table_name) != 1) {
      stop("table_name must be a single character string")
    }
    url <- paste0(api_url, "/search/table/", table_name)
  } else {
    url <- paste0(api_url, "/search/table")
  }

  # Make request and return results
  make_api_request(url, params = list(), format = "json")
}

#' Get All SMEAR Tables
#'
#' Convenience function to get a list of all available SMEAR tables
#'
#' @return A data frame containing information about all tables
#' @export
get_tables <- function() {
  get_table_metadata()
}
