original <- ggplot2::ggplot(mtcars)
failing <- ggplot2::ggplot(mtcars) + ggplot2::geom_vline(xintercept = 0)

test_that("this fails", {
  expect_doppelganger("failing", failing)
})
