test_that("Error during tests is detected", {
  expect_true(TRUE)
  stop("error")
})
