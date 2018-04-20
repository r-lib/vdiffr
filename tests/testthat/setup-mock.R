
create_mock_pkg <- function(pkg = "mock-pkg") {
  dir <- tempfile()

  dir.create(dir, recursive = TRUE)
  file.copy(pkg, dir, recursive = TRUE)

  # Enable `R CMD check` logging
  from <- file.path(dir, pkg)
  to <- paste0(from, ".Rcheck")
  file.rename(from, to)

  to
}

subset_results <- function(results, file, test) {
  subset <- purrr::keep(results, function(result) {
    result$file == file && result$test == test
  })
  subset[[1]]$results
}

on_load <- function() {
  identical(Sys.getenv("DEVTOOLS_LOAD"), "true")
}
skip_old_freetype <- function() {
  if (old_freetype()) {
    skip("FreeType too old for vdiffr")
  }
}

is_checking <- function() {
  nzchar(Sys.getenv("R_TESTS"))
}


if (!old_freetype()) {
  mock_pkg_dir <- create_mock_pkg()
  mock_test_dir <- file.path(mock_pkg_dir, "tests", "testthat")

  # So the mock package writes the log file
  old <- Sys.getenv("R_TESTS")
  Sys.setenv(R_TESTS = TRUE)

  test_results <- testthat::test_dir(mock_test_dir, reporter = "silent")
  mock_cases_outputs <- purrr::quietly(purrr::safely(collect_cases))(mock_pkg_dir)

  Sys.setenv(R_TESTS = old)

  quietly_out <- mock_cases_outputs$result
  if (inherits(quietly_out$error, "condition")) {
    cat("While collecting testing cases:\n")
    stop(quietly_out$error)
  }

  log_path <- file.path(mock_pkg_dir, "tests", "vdiffr.Rout.fail")
  if (file.exists(log_path)) {
    copied <- file.copy(log_path, "../mock.Rout.fail", overwrite = TRUE)
    if (!copied) {
      warning("Failed to copy mock package log")
    }
  }

  mock_cases <- quietly_out$result
  validate_cases(mock_cases)
}
