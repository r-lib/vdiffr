library("vdiffr")

p1_orig <- ggplot2::ggplot(mtcars, ggplot2::aes(disp)) + ggplot2::geom_histogram()
p1_fail <- p1_orig + ggplot2::geom_vline(xintercept = 300)

maintenance <- Sys.getenv("VDIFFR_REGENERATE_TESTS") == "yes"
skip_if_maintenance <- function() {
  if (maintenance) {
    skip("maintenance")
  }
}

test_that("mismatches are hard failures when NOT_CRAN is set", {
  skip_if_maintenance()
  expect_doppelganger("myplot", p1_fail, "")
})

test_that("Duplicated expectations issue a warning", {
  skip_if_maintenance()
  expect_doppelganger("myplot", p1_fail, "")
})

test_that("mismatches are hard failures when CI is set", {
  skip_if_maintenance()
  withr::local_envvar(c(NOT_CRAN = "", CI = "true"))
  expect_doppelganger("myplot", p1_fail, "")
})

test_that("mismatches are skipped when NOT_CRAN is unset", {
  skip_if_maintenance()
  withr::local_envvar(c(NOT_CRAN = "", CI = ""))
  expect_doppelganger("myplot", p1_fail, "")
})


# Maintenance --------------------------------------------------------

test_that("(maintenance) Reset failing figure", {
  if (!maintenance) {
    skip("maintenance")
  }
  expect_doppelganger("myplot", p1_orig, "")
})
