test_that("can override is_ci()", {
  with_override <- function(var) {
    withr::with_envvar(c(VDIFFR_RUN_TESTS = var, CI = "", NOT_CRAN = ""), is_ci())
  }
  expect_true(with_override("true"))
  expect_false(with_override("false"))
  expect_error(with_override("falsish"), "must be")
})
