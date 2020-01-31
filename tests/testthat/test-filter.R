context("Filtering")

test_that("Can filter to test certain cases", {
  mock_pkg_dir <- create_mock_pkg("mock-pkg")
  mock_test_dir <- file.path(mock_pkg_dir, "tests", "testthat")
  cases <- collect_cases(mock_test_dir, filter = "ggplot")
  case_contexts <- purrr::map_chr(cases, "context")
  expect_true(all(case_contexts == "ggplot"))
})

test_that("Can invert filtering of test cases", {
  mock_pkg_dir <- create_mock_pkg("mock-pkg")
  mock_test_dir <- file.path(mock_pkg_dir, "tests", "testthat")
  cases <- collect_cases(mock_test_dir, filter = "ggplot", invert = TRUE)
  case_contexts <- purrr::map_chr(cases, "context")
  expect_false("ggplot" %in% case_contexts)
})
