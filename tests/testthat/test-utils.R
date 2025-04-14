library(testthat)
library(mockery)
library(httr)

context("Utility functions")

test_that("get_api_url returns correct URL", {
  # Save original environment value if it exists
  original_value <- Sys.getenv("SMEAR_API_URL", unset = NA)

  # Test default URL when env var not set
  Sys.unsetenv("SMEAR_API_URL")
  expect_equal(
    SmartSMEAR:::get_api_url(),
    "https://smear-backend.2.rahtiapp.fi"
  )

  # Test custom URL when env var is set
  test_url <- "https://test-api-url.example.com"
  Sys.setenv(SMEAR_API_URL = test_url)
  expect_equal(SmartSMEAR:::get_api_url(), test_url)

  # Restore original environment value
  if (is.na(original_value)) {
    Sys.unsetenv("SMEAR_API_URL")
  } else {
    Sys.setenv(SMEAR_API_URL = original_value)
  }
})


test_that("make_api_request handles CSV responses correctly", {
  # Create mock response for CSV
  mock_csv <- "column1,column2\nvalue1,value2\nvalue3,value4"
  mock_response <- structure(
    list(
      status_code = 200,
      headers = list(`content-type` = "text/csv"),
      content = charToRaw(mock_csv)
    ),
    class = "response"
  )

  mock_df <- data.frame(
    column1 = c("value1", "value3"),
    column2 = c("value2", "value4")
  )

  # Mock functions
  mock_GET <- mock(mock_response)
  mock_http_error <- mock(FALSE)
  mock_content <- mock(mock_csv)

  with_mock(
    "httr::GET" = mock_GET,
    "httr::http_error" = mock_http_error,
    "httr::content" = mock_content,
    {
      result <- SmartSMEAR:::make_api_request(
        "https://test-url.com",
        format = "csv"
      )
      expect_true(is.data.frame(result))
      expect_equal(nrow(result), 2)
      expect_equal(ncol(result), 2)
    }
  )
})

test_that("make_api_request handles TSV responses correctly", {
  # Create mock response for TSV
  mock_tsv <- "column1\tcolumn2\nvalue1\tvalue2\nvalue3\tvalue4"
  mock_response <- structure(
    list(
      status_code = 200,
      headers = list(`content-type` = "text/plain"),
      content = charToRaw(mock_tsv)
    ),
    class = "response"
  )

  mock_df <- data.frame(
    column1 = c("value1", "value3"),
    column2 = c("value2", "value4")
  )

  # Mock functions
  mock_GET <- mock(mock_response)
  mock_http_error <- mock(FALSE)
  mock_content <- mock(mock_tsv)

  with_mock(
    "httr::GET" = mock_GET,
    "httr::http_error" = mock_http_error,
    "httr::content" = mock_content,
    {
      result <- SmartSMEAR:::make_api_request(
        "https://test-url.com",
        format = "tsv"
      )
      expect_true(is.data.frame(result))
      expect_equal(nrow(result), 2)
      expect_equal(ncol(result), 2)
    }
  )
})


test_that("make_query_list creates the correct list structure", {
  # Test with single variable
  result <- SmartSMEAR:::make_query_list(
    "tablevariable",
    "HYY_META.temperature"
  )
  expect_equal(length(result), 1)
  expect_equal(names(result), "tablevariable")
  expect_equal(result$tablevariable, "HYY_META.temperature")

  # Test with multiple variables
  vars <- c("HYY_META.temperature", "HYY_META.humidity", "HYY_META.pressure")
  result <- SmartSMEAR:::make_query_list("tablevariable", vars)
  expect_equal(length(result), 3)
  expect_equal(names(result), rep("tablevariable", 3))
  expect_equal(unname(unlist(result)), vars)

  # Test with different key name
  result <- SmartSMEAR:::make_query_list("variable", c("temp", "humid"))
  expect_equal(length(result), 2)
  expect_equal(names(result), rep("variable", 2))
  expect_equal(unname(unlist(result)), c("temp", "humid"))

  # Test with empty variables list
  result <- SmartSMEAR:::make_query_list("tablevariable", character(0))
  expect_equal(length(result), 0)
})

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
