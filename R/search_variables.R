#' Search SMEAR Variables
#'
#' Search for variables in the SMEAR database using various filters
#'
#' @param category Filter by variable category
#' @param description Filter by variable description
#' @param source Filter by data source
#' @param station Filter by station
#' @param table Filter by table name
#' @param variable Filter by variable name
#' @param tablevariable Filter by table.variable combination
#' @param format Response format ("json", "csv", or "tsv")
#' @return A data frame containing the search results
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

  # Make request and return results
  make_api_request(url, params, format)
}
