vdiffr_skip_stale()

test_that("ggplot doppelgangers pass", {
  skip_if_not_installed("ggplot2")
  p1_orig <- ggplot2::ggplot(mtcars, ggplot2::aes(disp)) + ggplot2::geom_histogram()
  expect_doppelganger("myplot", p1_orig)
})

test_that("base doppelgangers pass", {
  p_base <- function() plot(mtcars$disp)
  expect_doppelganger("myplot2", p_base)

  p_base_symbol <- function() {
    plot.new()
    text(0.5, 0.8, expression(x[i] + over(x, y)), font = 5)
  }

  expect_doppelganger("Base doppelganger with symbol", p_base_symbol)
})

test_that("grid doppelgangers pass", {
  p_grid <- function() {
    grid::grid.newpage()
    grid::grid.text("foobar", gp = grid::gpar(fontsize = 10.1))
    grid::grid.text("foobaz", 0.5, 0.1, gp = grid::gpar(fontsize = 15.05))
  }
  expect_doppelganger("Grid doppelganger", p_grid)
})

test_that("no 'svglite supports one page' error (#85)", {
  test_draw_axis <- function(add_labels = FALSE) {
    theme <- theme_test() + theme(axis.line = element_line(size = 0.5))
    positions <- c("top", "right", "bottom", "left")

    n_breaks <- 3
    break_positions <- seq_len(n_breaks) / (n_breaks + 1)
    labels <- if (add_labels) as.character(seq_along(break_positions))

    # create the axes
    axes <- lapply(positions, function(position) {
      ggplot2:::draw_axis(break_positions, labels, axis_position = position, theme = theme)
    })
    axes_grob <- gTree(children = do.call(gList, axes))

    # arrange them so there's some padding on each side
    gt <- gtable(
      widths = unit(c(0.05, 0.9, 0.05), "npc"),
      heights = unit(c(0.05, 0.9, 0.05), "npc")
    )
    gtable_add_grob(gt, list(axes_grob), 2, 2, clip = "off")
  }
  environment(test_draw_axis) <- env(ns_env("ggplot2"))

  expect_doppelganger("page-error1", test_draw_axis(FALSE))
  expect_doppelganger("page-error2", test_draw_axis(TRUE))
})

test_that("supports `grob` objects (#36)", {
  circle <- grid::circleGrob(
    x = 0.5,
    y = 0.5,
    r = 0.5,
    gp = grid::gpar(col = "gray", lty = 3)
  )
  expect_doppelganger("grob", circle)
})

test_that("skips and unexpected errors reset snapshots (r-lib/testthat#1393)", {
  regenerate <- FALSE

  if (regenerate) {
    withr::local_envvar(c(VDIFFR_REGENERATE_SNAPS = "true"))
  }

  suppressMessages(
    test_file(
      test_path("test-snapshot", "test-snapshot.R"),
      reporter = NULL
    )
  )

  expect_true(file.exists("test-snapshot/_snaps/snapshot/error-resets-snapshots.svg"))
  expect_true(file.exists("test-snapshot/_snaps/snapshot/skip-resets-snapshots.svg"))
})

test_that("`expect_doppelganger()` supports variants", {
  p1 <- ggplot2::ggplot()
  p2 <- ggplot2::ggplot() + ggplot2::geom_histogram()
  expect_doppelganger("variant", p1, variant = "foo")
  expect_doppelganger("variant", p2, variant = "bar")
})
