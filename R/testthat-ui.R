#' Does a figure look like its expected output?
#'
#' @description
#'
#' `expect_doppelganger()` takes a figure to check visually.
#'
#' * If the figure has yet to be validated, the test is skipped. Call
#'   [manage_cases()] to validate the new figure, so vdiffr knows what
#'   to compare against.
#'
#' * If the test has been validated, `fig` is compared to the
#'   validated figure. If the plot differs, a failure is issued
#'   (except on CRAN, see section on regression testing below).
#'
#'   Either fix the problem, or call [manage_cases()] to validate the
#'   new figure appearance.
#'
#' @param title A brief description of what is being tested in the
#'   figure. For instance: "Points and lines overlap".
#'
#'   If a ggplot2 figure doesn't have a title already, `title` is
#'   applied to the figure with `ggtitle()`.
#'
#'   The title is also used as file name for storing SVG (in a
#'   sanitzed form, with special characters converted to `"-"`).
#' @param fig A figure to test. This can be a ggplot object, a
#'   recordedplot, or more generally any object with a `print` method.
#'
#'   For plots that can't be represented as printable objects, you can
#'   pass a function. This function must construct the plot and print
#'   it.
#' @param path The path where the test case should be stored, relative
#'   to the `tests/figs/` folder. If `NULL` (the default), the current
#'   testthat context is used to create a subfolder. Supply an empty
#'   string `""` if you want the figures to be stored in the root
#'   folder.
#' @param ... Additional arguments passed to [testthat::compare()] to
#'   control specifics of comparison.
#' @param verbose Soft-deprecated. See the debugging section.
#' @param writer A function that takes the plot, a target SVG file,
#'   and an optional plot title. It should transform the plot to SVG
#'   in a deterministic way and write it to the target file. See
#'   [write_svg()] (the default) for an example.
#'
#' @section Regression testing versus Unit testing:
#'
#' Failures to match a validated appearance are only reported when the
#' tests are run locally, on Travis, Appveyor, or any environment
#' where the `Sys.getenv("CI")` or `Sys.getenv("NOT_CRAN")` variables
#' are set. Because vdiffr is more of a monitoring than a unit testing
#' tool, it shouldn't cause R CMD check failures on the CRAN machines.
#'
#' Checking the appearance of a figure is inherently fragile. It is
#' similar to testing for errors by matching exact error messages:
#' these messages are susceptible to change at any time. Similarly,
#' the appearance of plots depends on a lot of upstream code, such as
#' the way margins and spacing are computed. vdiffr uses a special
#' ggplot2 theme that should change very rarely, but there are just
#' too many upstream factors that could cause breakages. For this
#' reason, figure mismatches are not necessarily representative of
#' actual failures.
#'
#' Visual testing is not an alternative to writing unit tests for the
#' internal data transformations performed during the creation of your
#' figure. It is more of a monitoring tool that allows you to quickly
#' check how the appearance of your figures changes over time, and to
#' manually assess whether changes reflect actual problems in your
#' package.
#'
#' If you need to override the default vdiffr behaviour on CRAN (not
#' recommended) or Travis (for example to run the tests in a
#' particular builds but not others), set the `VDIFFR_RUN_TESTS`
#' environment variable to "true" or "false".
#'
#' @section Debugging:
#'
#' It is sometimes difficult to understand the cause of a failure.
#' This usually indicates that the plot is not created
#' deterministically. Potential culprits are:
#'
#' * Some of the plot components depend on random variation. Try
#'   setting a seed.
#'
#' * The plot depends on some system library. For instance sf plots
#'   depend on libraries like GEOS and GDAL. It might not be possible
#'   to test these plots with vdiffr (which can still be used for
#'   manual inspection, add a [testthat::skip()] before the
#'   `expect_doppelganger()` call in that case).
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
                                path = NULL,
                                ...,
                                verbose = NULL,
                                writer = write_svg) {
  if (!is_collecting()) {
    abort(paste_line(
      "`expect_doppelganger()` can't be called interactively.",
      "* Call `vdiffr::manage_cases()` to validate or revalidate figures.",
      "* Call `devtools::test()` to test the figures."
    ))
  }

  if (!is_null(verbose)) {
    signal_soft_deprecated(paste_line(
      "The `verbose` argument is soft-deprecated as of vdiffr 0.3.0.",
      "Please use the log file intead. See section 'Debugging' of `?expect_doppelganger`."
    ))
  }

  fig_name <- str_standardise(title)
  testcase <- make_testcase_file(fig_name)
  writer(fig, testcase, title)

  context <- get(".context", envir = testthat::get_reporter())
  context <- str_standardise(context %||% "")
  path <- path %||% context

  # Climb one level as we are in the testthat folder
  path <- file.path(path, paste0(fig_name, ".svg"))
  path <- testthat::test_path("..", "figs", path)
  ensure_directories(dirname(path))

  case <- case(list(
    name = fig_name,
    path = path,
    testcase = testcase,
    context = context
  ))

  if (file.exists(path)) {
    exp <- case_compare(case)
  } else {
    exp <- case_declare(case, fig_name)
  }

  signal_expectation(exp)
}

# FIXME: Use TESTTHAT_PKG envvar after devtools and testthat release
is_collecting <- function() {
  !inherits(testthat::get_reporter(), "StopReporter")
}

str_standardise <- function(s, sep = "-") {
  stopifnot(is_scalar_character(s))
  s <- gsub("[^a-z0-9]", sep, tolower(s))
  s <- gsub(paste0(sep, sep, "+"), sep, s)
  s <- gsub(paste0("^", sep, "|", sep, "$"), "", s)
  s
}

case_compare <- function(case) {
  # Skipping early to avoid running `compare_files()` on machines
  # performing sanitizer checks
  if (!is_ci()) {
    return(new_expectation("Skipping on CRAN", case, "skip", "vdiffr_skip"))
  }

  equal <- compare_files(case$testcase, normalizePath(case$path))

  if (equal) {
    case <- success_case(case)
    maybe_collect_case(case)
    return(match_exp("TRUE", case))
  }

  case <- mismatch_case(case)
  maybe_collect_case(case)

  if (is_null(active_collecter())) {
    push_log(case)
  }

  msg <- paste0("Figures don't match: ", case$name, ".svg\n")
  mismatch_exp(msg, case)
}
case_declare <- function(case, fig_name) {
  case <- new_case(case)
  maybe_collect_case(case)

  msg <- paste_line(
    sprintf("Figure not generated yet: %s.svg", fig_name),
    "Please run `vdiffr::manage_cases()` to validate the figure."
  )
  new_exp(msg, case)
}

new_expectation <- function(msg, case, type, vdiffr_type) {
  exp <- testthat::expectation(type, msg)
  classes <- c(class(exp), vdiffr_type)
  structure(exp, class = classes, vdiffr_case = case)
}

new_exp <- function(msg, case) {
  new_expectation(msg, case, "skip", "vdiffr_new")
}
match_exp <- function(msg, case) {
  new_expectation(msg, case, "success", "vdiffr_match")
}
mismatch_exp <- function(msg, case) {
  if (is_vdiffr_stale()) {
    msg <- "The vdiffr engine is too old. Please update vdiffr and revalidate the figures."
    new_expectation(msg, case, "skip", "vdiffr_mismatch")
  } else if (is_ci()) {
    new_expectation(msg, case, "failure", "vdiffr_mismatch")
  } else {
    new_expectation(msg, case, "skip", "vdiffr_mismatch")
  }
}

# FIXME: Should probably be exported from testthat
signal_expectation <- function(exp) {
  withRestarts(
    if (expectation_broken(exp)) {
      stop(exp)
    } else {
      signalCondition(exp)
    },
    continue_test = function(e) NULL
  )
  invisible(exp)
}
expectation_broken <- function(exp) {
  expectation_type(exp) %in% c("failure", "mismatch", "error")
}

#' Add a vdiffr dependency
#'
#' It is useful to record the version number of all the packages on
#' which your visual test cases depend. A note containing a version
#' number is added to the `DESCRIPTION` file for each dependency.
#' Dependencies on svglite and ggplot2 are automatically added. In
#' addition, `add_dependency()` can be called in any testthat file to
#' manually add a dependency to a package.
#'
#' @param deps A vector containing the names of the packages for which
#'   a dependency should be added.
#'
#' @keywords internal
#' @export
add_dependency <- function(deps) {
  signal_soft_deprecated("`add_dependency()` is soft-deprecated as of vdiffr 0.3.0, without replacement")
  collecter <- active_collecter()
  if (!is.null(collecter)) {
    walk(deps, collecter$add_dep)
  }
}
