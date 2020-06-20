test_that("ggtitle is set correctly", {
  p <- ggplot2::ggplot()
  expect_doppelganger("Some title", p)
  expect_doppelganger("Some other title", p + ggplot2::ggtitle(NULL))
})
