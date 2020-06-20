test_that("Mismatches are skipped except on CI and interactively", {
  notcran_result <- subset_results(test_results, "test-failed.R", "mismatches are hard failures when NOT_CRAN is set")[[1]]
  expect_match(notcran_result$message, "Figures don't match: myplot.svg\n")
  expect_is(notcran_result, "expectation_failure")

  failed_result <- subset_results(test_results, "test-failed.R", "mismatches are hard failures when CI is set")[[1]]
  expect_match(failed_result$message, "Figures don't match: myplot.svg\n")
  expect_is(failed_result, "expectation_failure")

  skipped_result <- subset_results(test_results, "test-failed.R", "mismatches are skipped when NOT_CRAN is unset")[[1]]
  expect_match(skipped_result$message, "Skipping on CRAN")
  expect_is(skipped_result, "expectation_skip")
})

test_that("Duplicated expectations issue warning", {
  expect_true(any(grepl("Duplicated expectations: myplot", mock_cases_outputs$warnings)))
})

test_that("Doppelgangers pass", {
  ggplot_result <- subset_results(test_results, "test-passed.R", "ggplot doppelgangers pass")[[1]]
  base_result <- subset_results(test_results, "test-passed.R", "base doppelgangers pass")[[1]]
  expect_is(ggplot_result, "expectation_success")
  expect_is(base_result, "expectation_success")
})

test_that("skip mismatches if vdiffr is stale", {
  withr::local_envvar(c(NOT_CRAN = "true"))
  mock_dir <- create_mock_pkg("mock-pkg-skip-stale")

  mock_test_dir <- file.path(mock_dir, "tests", "testthat")
  test_results <- testthat::test_dir(mock_test_dir, reporter = "silent")
  result <- test_results[[1]]$results[[1]]

  expect_is(result, "expectation_skip")
  expect_match(result$message, "The vdiffr engine is too old")
})
