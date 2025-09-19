#' Does a figure look like its expected output?
#'
#' @description
#'
#' `expect_doppelganger()` is a testthat expectation for graphical
#' plots. It generates SVG snapshots that you can review graphically
#' with [testthat::snapshot_review()]. You will find more information
#' about snapshotting in the [testthat snapshots
#' vignette](https://testthat.r-lib.org/articles/snapshotting.html).
#'
#' Note that `expect_doppelganger()` requires R version 4.1.0. If run
#' on an earlier version of R, it emits a `testthat::skip()` so that you
#' can still run other checks on old versions of R.
#'
#' @param title A brief description of what is being tested in the
#'   figure. For instance: "Points and lines overlap".
#'
#'   If a ggplot2 figure doesn't have a title already, `title` is
#'   applied to the figure with `ggtitle()`.
#'
#'   The title is also used as file name for storing SVG (in a
#'   sanitized form, with special characters converted to `"-"`).
#' @param fig A figure to test. This can be a ggplot object, a
#'   recordedplot, or more generally any object with a `print` method.
#'
#'   If you need to test a plot with non-printable objects (e.g. base
#'   plots), `fig` can be a function that generates and prints the
#'   plot, e.g. `fig = function() plot(1:3)`.
#' @param path,... `r lifecycle::badge('deprecated')`.
#' @param writer A function that takes the plot, a target SVG file,
#'   and an optional plot title. It should transform the plot to SVG
#'   in a deterministic way and write it to the target file. See
#'   [write_svg()] (the default) for an example.
#' @param cran If `FALSE` (the default), mismatched snapshots only
#'   cause a failure when you run tests locally or in your CI (Github
#'   Actions or any platform that sets the `CI` environment variable).
#'   If `TRUE`, failures may also occur on CRAN machines.
#'
#'   Failures are disabled on CRAN by default because testing the
#'   appearance of a figure is inherently fragile. Changes in the R
#'   graphics engine or in ggplot2 may cause subtle differences in the
#'   aspect of a plot, such as a slightly smaller or larger margin.
#'   These changes will cause spurious failures because you need to
#'   update your snapshots to reflect the upstream changes.
#'
#'   It would be distracting for both you and the CRAN maintainers if
#'   such changes systematically caused failures on CRAN. This is why
#'   snapshot expectations do not fail on CRAN by default and should
#'   be treated as a monitoring tool that allows you to quickly check
#'   how the appearance of your figures changes over time, and to
#'   manually assess whether changes reflect actual problems in your
#'   package.
#'
#'   Internally, this argument is passed to
#'   [testthat::expect_snapshot_file()].
#'
#' @inheritParams testthat::expect_snapshot_file
#'
#' @section Debugging:
#' It is sometimes difficult to understand the cause of a failure.
#' This usually indicates that the plot is not created
#' deterministically. Potential culprits are:
#'
#' * Some of the plot components depend on random variation. Try
#'   setting a seed.
#'
#' * The plot depends on some system library. For instance sf plots
#'   depend on libraries like GEOS and GDAL. It might not be possible
#'   to test these plots with vdiffr.
#'
#' To help you understand the causes of a failure, vdiffr
#' automatically logs the SVG diff of all failures when run under R
#' CMD check. The log is located in `tests/vdiffr.Rout.fail` and
#' should be displayed on Travis.
#'
#' You can also set the `VDIFFR_LOG_PATH` environment variable with
#' `Sys.setenv()` to unconditionally (also interactively) log failures
#' in the file pointed by the variable.
#'
#' @examples
#' if (FALSE) {  # Not run
#'
#' library("ggplot2")
#'
#' test_that("plots have known output", {
#'   disp_hist_base <- function() hist(mtcars$disp)
#'   expect_doppelganger("disp-histogram-base", disp_hist_base)
#'
#'   disp_hist_ggplot <- ggplot(mtcars, aes(disp)) + geom_histogram()
#'   expect_doppelganger("disp-histogram-ggplot", disp_hist_ggplot)
#' })
#'
#' }
#' @export
expect_doppelganger <- function(title,
                                fig,
                                path = deprecated(),
                                ...,
                                writer = write_svg,
                                cran = FALSE,
                                variant = NULL) {
  testthat::local_edition(3)

  if (!is_string(title)) {
    abort("title argument must be a string")
  }
  
  fig_name <- str_standardise(title)
  file <- paste0(fig_name, ".svg")

  # Announce snapshot file before touching `fig` in case evaluation
  # causes an error. This allows testthat to restore the files
  # (see r-lib/testthat#1393).
  testthat::announce_snapshot_file(name = file)

  testcase <- make_testcase_file(fig_name)
  writer(fig, testcase, title)

  if (!missing(...)) {
    lifecycle::deprecate_soft(
      "1.0.0",
      "vdiffr::expect_doppelganger(... = )",
    )
  }
  if (lifecycle::is_present(path)) {
    lifecycle::deprecate_soft(
      "1.0.0",
      "vdiffr::expect_doppelganger(path = )",
    )
  }

  if (is_graphics_engine_stale()) {
    testthat::skip(paste_line(
      "The R graphics engine is too old.",
      "Please update to R 4.1.0 and regenerate the vdiffr snapshots."
    ))
  }

  withCallingHandlers(
    testthat::expect_snapshot_file(
      testcase,
      name = file,
      cran = cran,
      variant = variant,
      compare = testthat::compare_file_text
    ),
    expectation_failure = function(cnd) {
      if (is_snapshot_stale(title, testcase)) {
        warn(paste_line(
          "SVG snapshot generated under a different vdiffr version.",
          "i" = "Please update your snapshots."
        ))
      }

      if (!is_null(snapshotter <- get_snapshotter())) {
        path_old <- snapshot_path(snapshotter, file)
        path_new <- snapshot_path(snapshotter, paste0(fig_name, ".new.svg"))

        if (all(file.exists(path_old, path_new))) {
          push_log(fig_name, path_old, path_new)
        }
      }
    }
  )
}

# From testthat
get_snapshotter <- function() {
  x <- getOption("testthat.snapshotter")
  if (is.null(x)) {
    return()
  }

  if (!x$is_active()) {
    return()
  }

  x
}
snapshot_path <- function(snapshotter, file) {
  file.path(snapshotter$snap_dir, snapshotter$file, file)
}

is_graphics_engine_stale <- function() {
  getRversion() < "4.1.0"
}

str_standardise <- function(s, sep = "-") {
  stopifnot(is_scalar_character(s))
  s <- gsub("[^a-z0-9]", sep, tolower(s))
  s <- gsub(paste0(sep, sep, "+"), sep, s)
  s <- gsub(paste0("^", sep, "|", sep, "$"), "", s)
  s
}

is_snapshot_stale <- function(title, testcase) {
  if (is_null(snapshotter <- get_snapshotter())) {
    return(FALSE)
  }

  file <- paste0(str_standardise(title), ".svg")
  path <- snapshot_path(snapshotter, file)

  if (!file.exists(path)) {
    return(FALSE)
  }

  lines <- readLines(path)

  match <- regexec(
    "data-engine-version='([0-9.]+)'",
    lines
  )
  match <- Filter(length, regmatches(lines, match))

  # Old vdiffr snapshot that doesn't embed a version
  if (!length(match)) {
    return(TRUE)
  }

  if (length(match) > 1) {
    abort("Found multiple vdiffr engine versions in SVG snapshot.")
  }

  snapshot_version <- match[[1]][[2]]
  svg_engine_ver() != snapshot_version
}
