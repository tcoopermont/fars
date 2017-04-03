#test_that("fars_read loads sample data", {
#  file <- system.file("tests", "accident_2013.csv.bz2", package = "testpackage")
#  fars_data <- fars_read(file)
#  expect_that(nrow(fars_data), equals(30202))
#})

test_that("fars_read_years loads sample data", {
  fars_data <- fars_read_years(2013)
  expect_that(nrow(fars_data[[1]]), equals(30202))
})

test_that("fars_summarize loads sample data", {
  fars_data <- fars_summarize_years(2013)
  expect_that(fars_data[[2]][1], equals(2230))
})

