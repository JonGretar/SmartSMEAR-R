test_that("parse_station_coordinates extracts values correctly", {
  # Create test data
  test_stations <- data.frame(
    dcmiPoint = c(
      "name=Test1; east=24.123; north=60.123; elevation=100;",
      "name=Test2; east=25.456; north=61.456; elevation=200;",
      "name=Test3; north=62.789; east=26.789; elevation=300;", # Different order
      "name=Test4; elevation=400; east=27.101; north=63.101;" # Different order
    ),
    id = 1:4,
    name = c("Test1", "Test2", "Test3", "Test4"),
    stringsAsFactors = FALSE
  )

  # Process the test data
  result <- parse_station_coordinates(test_stations)

  # Check that original columns are preserved
  expect_equal(result$id, 1:4)
  expect_equal(result$name, c("Test1", "Test2", "Test3", "Test4"))

  # Check that coordinates were extracted correctly
  expect_equal(result$east, c(24.123, 25.456, 26.789, 27.101))
  expect_equal(result$north, c(60.123, 61.456, 62.789, 63.101))
  expect_equal(result$elevation, c(100, 200, 300, 400))
})

test_that("parse_station_coordinates handles missing values", {
  # Create test data with missing values
  test_stations <- data.frame(
    dcmiPoint = c(
      "name=Missing1; east=28.123; north=64.123;", # No elevation
      "name=Missing2; east=29.456; elevation=500;", # No north
      "name=Missing3; north=65.789; elevation=600;", # No east
      "name=Empty;" # No coordinates
    ),
    id = 1:4,
    name = c("Missing1", "Missing2", "Missing3", "Empty"),
    stringsAsFactors = FALSE
  )

  # Process the test data
  result <- parse_station_coordinates(test_stations)

  # Check that coordinates were extracted correctly where present
  expect_equal(result$east, c(28.123, 29.456, NA, NA))
  expect_equal(result$north, c(64.123, NA, 65.789, NA))
  expect_equal(result$elevation, c(NA, 500, 600, NA))
})

test_that("parse_station_coordinates validates input", {
  # Test with data frame missing dcmiPoint column
  invalid_data <- data.frame(id = 1:3, name = c("A", "B", "C"))
  expect_error(
    parse_station_coordinates(invalid_data),
    "must contain a 'dcmiPoint' column"
  )
})
