collect_silently <- function(pkg) {
  capture.output(suppressMessages(collect_cases(pkg)))
}

test_that("Error during testing is detected", {
  mock_pkg_dir <- create_mock_pkg("mock-pkg-error")
  mock_test_dir <- file.path(mock_pkg_dir, "tests", "testthat")
  expect_error(collect_silently(mock_test_dir), "while collecting vdiffr cases")
})
