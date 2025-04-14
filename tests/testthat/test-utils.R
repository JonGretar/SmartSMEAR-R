library(testthat)

context("Utility functions")

describe("add_params", {
  test_that("add_params handles NULL and non-NULL values correctly", {
    # Test adding to empty params
    params <- list()
    new_params <- list(
      a = "value1",
      b = NULL,
      c = "value2"
    )
    result <- add_params(params, new_params)

    expect_equal(length(result), 2)
    expect_equal(result$a, "value1")
    expect_equal(result$c, "value2")
    expect_false("b" %in% names(result))

    # Test adding to existing params
    params <- list(x = "existing", y = "old")
    new_params <- list(
      y = "new", # Should override
      z = NULL, # Should not be added
      w = "added" # Should be added
    )
    result <- add_params(params, new_params)

    expect_equal(length(result), 3)
    expect_equal(result$x, "existing")
    expect_equal(result$y, "new")
    expect_equal(result$w, "added")
    expect_false("z" %in% names(result))

    # Test adding empty list
    params <- list(a = "value")
    result <- add_params(params, list())
    expect_equal(result, params)

    # Test adding all NULL values
    params <- list(a = "value")
    new_params <- list(b = NULL, c = NULL)
    result <- add_params(params, new_params)
    expect_equal(result, params)

    # Test adding empty string and zero
    params <- list()
    new_params <- list(
      empty = "",
      zero = 0,
      null = NULL
    )
    result <- add_params(params, new_params)
    expect_equal(length(result), 2)
    expect_equal(result$empty, "")
    expect_equal(result$zero, 0)
    expect_false("null" %in% names(result))
  })

  test_that("add_params preserves data types", {
    params <- list()
    new_params <- list(
      int = 42L,
      double = 3.14,
      logical = TRUE,
      character = "test",
      vector = c(1, 2, 3)
    )
    result <- add_params(params, new_params)

    expect_type(result$int, "integer")
    expect_type(result$double, "double")
    expect_type(result$logical, "logical")
    expect_type(result$character, "character")
    expect_equal(result$vector, c(1, 2, 3))
  })
})

describe("format_timestamp", {
  test_that("format_timestamp handles different timezones correctly", {
    # Test UTC time
    utc_time <- as.POSIXct("2023-01-01 10:00:00", tz = "UTC")
    result <- format_timestamp(utc_time)
    expect_equal(result, "2023-01-01T12:00:00") # UTC+2

    # Test EET time
    eet_time <- as.POSIXct("2023-01-01 10:00:00", tz = "EET")
    result <- format_timestamp(eet_time)
    expect_equal(result, "2023-01-01T10:00:00") # Already in EET

    # Test another timezone (e.g., America/New_York)
    ny_time <- as.POSIXct("2023-01-01 10:00:00", tz = "America/New_York")
    result <- format_timestamp(ny_time)
    expect_equal(result, "2023-01-01T17:00:00") # EST+7=EET
  })

  test_that("format_timestamp produces correct ISO 8601 format", {
    time <- as.POSIXct("2023-01-01 09:08:07", tz = "EET")
    result <- format_timestamp(time)

    # Check format
    expect_match(result, "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}$")
    expect_equal(result, "2023-01-01T09:08:07")

    # Check that single-digit numbers are zero-padded
    time <- as.POSIXct("2023-01-01 01:02:03", tz = "EET")
    result <- format_timestamp(time)
    expect_equal(result, "2023-01-01T01:02:03")
  })
})

describe("build_endpoint", {
  test_that("build_endpoint handles different formats correctly", {
    # Test JSON format (default)
    result <- build_endpoint("/search/variable", "json")
    expect_equal(result, "/search/variable")

    # Test CSV format
    result <- build_endpoint("/search/variable", "csv")
    expect_equal(result, "/search/variable/csv")

    # Test TSV format
    result <- build_endpoint("/search/variable", "tsv")
    expect_equal(result, "/search/variable/tsv")

    # Test with different base paths
    result <- build_endpoint("/search/timeseries", "csv")
    expect_equal(result, "/search/timeseries/csv")

    result <- build_endpoint("/search/station", "json")
    expect_equal(result, "/search/station")
  })

  test_that("build_endpoint validates format parameter", {
    # Should throw error for invalid format
    expect_error(build_endpoint("/search/variable", "invalid"))

    # Should work with partial matching
    expect_equal(build_endpoint("/test", "j"), "/test") # matches "json"
    expect_equal(build_endpoint("/test", "c"), "/test/csv") # matches "csv"
    expect_equal(build_endpoint("/test", "t"), "/test/tsv") # matches "tsv"
  })
})
