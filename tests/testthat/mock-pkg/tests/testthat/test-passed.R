library("vdiffr")

test_that("ggplot doppelgangers pass", {
  p1_orig <- ggplot2::ggplot(mtcars, ggplot2::aes(disp)) + ggplot2::geom_histogram()
  expect_doppelganger("myplot", p1_orig, "")
})

test_that("base doppelgangers pass", {
  p_base <- function() plot(mtcars$disp)
  expect_doppelganger("myplot2", p_base, "")

  p_base_symbol <- function() {
    plot.new()
    text(0.5, 0.8, expression(x[i] + over(x, y)), font = 5)
  }

  expect_doppelganger("Base doppelganger with symbol", p_base_symbol, "")
})

library("grid")
test_that("grid doppelgangers pass", {
  p_grid <- function() {
    grid.newpage()
    grid.text("foobar", gp = gpar(fontsize = 10.1))
    grid.text("foobaz", 0.5, 0.1, gp = gpar(fontsize = 15.05))
  }
  expect_doppelganger("Grid doppelganger", p_grid)
})
