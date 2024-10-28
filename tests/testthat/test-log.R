vdiffr_skip_stale()

test_that("Failures are logged", {
  skip_on_cran()

  reporter <- testthat::SilentReporter$new()

  path <- create_mock_pkg()
  vars <- c("CI" = "true")
  suppressMessages(withr::with_envvar(vars,
    testthat::test_dir(
      file.path(path, "tests", "testthat"),
      reporter = reporter,
      stop_on_failure = FALSE,
      stop_on_warning = FALSE
    )
  ))

  log_path <- file.path(path, "tests", "vdiffr.Rout.fail")
  if (!file.exists(log_path)) {
    abort("Can't find log.")
  }

  on.exit(file.remove(log_path))

  log <- readLines(log_path)
  
  results <- reporter$expectations()
  n_expected <- sum(vapply(results, inherits, NA, "expectation_failure"))

  n_logged <- length(grep("Failed doppelganger:", log))
  expect_equal(n_logged, n_expected)
})
