test_that("failures are pushed to log file", {
  log_path <- file.path(mock_pkg_dir, "tests", "vdiffr.Rout.fail")
  if (!file.exists(log_path)) {
    abort("Can't find log")
  }
  log <- readLines(log_path)

  n_logged <- length(grep("Failed doppelganger:", log))
  n_failures <- length(keep(mock_cases, inherits, "mismatch_case"))
  expect_identical(n_logged, n_failures)
})
