library(testthat)
library(mockery)

test_that("time column is created correctly from components", {
  # Mock data frame with time components
  df <- data.frame(
    Year = 2023,
    Month = 1,
    Day = 15,
    Hour = 10,
    Minute = 30,
    Second = 0,
    Value = 42.0,
    stringsAsFactors = FALSE
  )

  mock_request <- mock(df)

  with_mock(
    "SmartSMEAR:::make_api_request" = mock_request,
    {
      result <- get_timeseries(
        variables = "TEST.VALUE",
        start_time = "2023-01-15 10:00:00",
        end_time = "2023-01-15 11:00:00"
      )

      # Check time column
      expect_true("time" %in% names(result))
      expect_false(any(
        c("Year", "Month", "Day", "Hour", "Minute", "Second") %in% names(result)
      ))
      expect_equal(result$time, as.POSIXct("2023-01-15 10:30:00", tz = "EET"))
      expect_equal(names(result)[1], "time") # Should be first column
    }
  )
})
