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
  result <- make_api_request(url, params, format = "json")
  parse_station_coordinates(result)
}


#' Extract coordinate information from dcmiPoint string
#'
#' This function parses the dcmiPoint string from station data to extract
#' coordinates and elevation information into separate columns
#'
#' @param stations A data frame containing SMEAR station information with a dcmiPoint column
#' @return A data frame with added east, north, and elevation columns
parse_station_coordinates <- function(stations) {
  if (!'dcmiPoint' %in% names(stations)) {
    stop("Input data frame must contain a 'dcmiPoint' column")
  }

  # Initialize new columns
  stations$east <- NA_real_
  stations$north <- NA_real_
  stations$elevation <- NA_real_

  # Extract coordinates from each dcmiPoint string
  for (i in seq_len(nrow(stations))) {
    point_str <- stations$dcmiPoint[i]

    # Extract east coordinate
    east_match <- regexpr("east=([^;]+)", point_str)
    if (east_match > 0) {
      east_str <- regmatches(point_str, east_match)
      stations$east[i] <- as.numeric(sub("east=([^;]+)", "\\1", east_str))
    }

    # Extract north coordinate
    north_match <- regexpr("north=([^;]+)", point_str)
    if (north_match > 0) {
      north_str <- regmatches(point_str, north_match)
      stations$north[i] <- as.numeric(sub("north=([^;]+)", "\\1", north_str))
    }

    # Extract elevation
    elevation_match <- regexpr("elevation=([^;]+)", point_str)
    if (elevation_match > 0) {
      elevation_str <- regmatches(point_str, elevation_match)
      stations$elevation[i] <- as.numeric(sub(
        "elevation=([^;]+)",
        "\\1",
        elevation_str
      ))
    }
  }

  stations
}
