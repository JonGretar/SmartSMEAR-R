#' Search SMEAR Stations
#'
#' Get information about SMEAR measurement stations
#'
#' @param station Optional station name to filter results (e.g., "HYY")
#' @param name Optional station's human readable name to filter results (e.g., "Hyytiälä")
#' @return A data frame containing station information including id, name, location, and other metadata
#' @export
search_stations <- function(station = NULL, name = NULL) {
  # Build query parameters
  params <- list()
  params <- add_params(
    params,
    list(
      station = station,
      name = name
    )
  )

  # Build URL
  api_url <- get_api_url()
  url <- paste0(api_url, "/search/station")

  # Make request and return results
  make_api_request(url, params, format = "json")
}

#' Get all SMEAR stations
#'
#' Convenience function to get information about all SMEAR stations
#'
#' @return A data frame containing information about all stations
#' @export
get_stations <- function() {
  search_stations()
}
