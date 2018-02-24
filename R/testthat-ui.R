#' Does a figure look like its expected output?
#'
#' If the test has never been validated yet, the test is skipped. If
#' the test has previously been validated but \code{fig} does not look
#' like its expected output, an error is issued. Use
#' \code{\link{validate_cases}()} or \code{\link{manage_cases}()} to
#' (re)validate the test.
#'
#' \code{fig} can be a ggplot object, a recordedplot, a function to be
#' called, or more generally any object with a \code{print} method. If
#' a ggplot object, a dependency for ggplot2 is automatically added
#' (see \code{\link{add_dependency}()}).
#' @param title The figure title is used for creating the figure file
#'   names (all non-alphanumeric characters are converted to
#'   \code{-}). Also, ggplot2 figures are appended with
#'   \code{ggtitle(title)}.
#' @param fig A figure to test.
#' @param path The path where the test case should be stored, relative
#'   to the \code{tests/figs/} folder. If \code{NULL} (the default),
#'   the current testthat context is used to create a
#'   subfolder. Supply an empty string \code{""} if you want the
#'   figures to be stored in the root folder.
#' @param ... Additional arguments passed to
#'   \code{\link[testthat]{compare}()} to control specifics of
#'   comparison.
#' @param user_fonts Passed to \code{\link[svglite]{svglite}()} to
#'   make sure SVG are reproducible. Defaults to Liberation fonts for
#'   standard families and Symbola font for symbols.
#' @param verbose If \code{TRUE}, the contents of the SVG files for
#'   the comparison plots are printed during testthat checks. This is
#'   useful to investigate errors when testing remotely.
#'
#'   Note that it is not possible to print the original SVG during
#'   interactive use. This is because there is no way of figuring out
#'   in which directory this SVG lives. Consequently, only the test
#'   case is printed.
#' @export
#' @examples
#' ver <- gdtools::version_freetype()
#'
#' if (ver >= "2.6.0") {
#'   disp_hist_base <- function() hist(mtcars$disp)
#'   expect_doppelganger("disp-histogram-base", disp_hist_base)
#' }
#'
#' if (ver >= "2.6.0" && requireNamespace("ggplot2", quietly = TRUE)) {
#'   library("ggplot2")
#'   disp_hist_ggplot <- ggplot(mtcars, aes(disp)) + geom_histogram()
#'   expect_doppelganger("disp-histogram-ggplot", disp_hist_ggplot)
#' }
expect_doppelganger <- function(title, fig, path = NULL, ...,
                                user_fonts = NULL, verbose = FALSE) {
  if (is_true(peek_option("vdiffr_skip"))) {
    testthat::skip("Skipping vdiffr test")
  }
  if (old_freetype()) {
    ver <- gdtools::version_freetype()
    msg <- paste("vdiffr requires FreeType >= 2.6.0. Current version:", ver)
    testthat::skip(msg)
  }

  fig_name <- str_standardise(title)
  testcase <- make_testcase_file(fig_name)
  write_svg(fig, testcase, title, user_fonts)

  context <- get(".context", envir = testthat::get_reporter())
  context <- str_standardise(context %||% "")
  path <- path %||% context

  # Climb one level as we are in the testthat folder
  path <- file.path(path, paste0(fig_name, ".svg"))
  path <- file.path("..", "figs", path)
  ensure_directories(dirname(path))

  case <- case(list(
    name = fig_name,
    path = path,
    testcase = testcase,
    verbose = verbose
  ))

  if (file.exists(path)) {
    exp <- compare_figs(case)
  } else {
    case <- new_case(case)
    maybe_collect_case(case)
    maybe_print_svgs(case)
    msg <- paste0("Figure not generated yet: ", fig_name, ".svg")
    exp <- new_exp(msg, case)
  }

  signal_expectation(exp)
  invisible(exp)
}

str_standardise <- function(s, sep = "-") {
  stopifnot(is_scalar_character(s))
  s <- gsub("[^a-z0-9]", sep, tolower(s))
  s <- gsub(paste0(sep, sep, "+"), sep, s)
  s <- gsub(paste0("^", sep, "|", sep, "$"), "", s)
  s
}

compare_figs <- function(case) {
  equal <- compare_files(case$testcase, normalizePath(case$path))

  if (equal) {
    case <- success_case(case)
    maybe_collect_case(case)
    return(match_exp("TRUE", case))
  }

  case <- mismatch_case(case)
  maybe_collect_case(case)
  push_log(case)

  check_versions_match("FreeType", system_freetype_version(), strip_minor = TRUE)
  check_versions_match("Cairo", gdtools::version_cairo(), strip_minor = FALSE)

  msg <- paste0("Figures don't match: ", case$name, ".svg\n")
  mismatch_exp(msg, case)
}

check_versions_match <- function(dep, system_ver, strip_minor = FALSE) {
  cases_ver <- cases_pkg_version(dep, strip = strip_minor)

  if (is_null(cases_ver)) {
    msg <- glue(
      "Failed doppelganger but vdiffr can't check its FreeType version.
       Please revalidate cases with a more recent vdiffr"
    )
    return_from(caller_env(), skipped_mismatch_exp(msg, case))
  }

  if (cases_ver < system_ver) {
    msg <- glue(
      "Failed doppelganger was generated with an older { dep } version.
       Please revalidate cases with vdiffr::validate_cases() or vdiffr::manage_cases()"
    )
    return_from(caller_env(), skipped_mismatch_exp(msg, case))
  }

  if (cases_ver > system_ver) {
    msg <- glue(
      "Failed doppelganger was generated with a newer FreeType version.
       Please install FreeType {cases_ver} on your system"
    )
    return_from(caller_env(), skipped_mismatch_exp(msg, case))
  }
}

# Go back up one level by default as we should be in the `testthat`
# folder
cases_pkg_version <- function(pkg, path = "..", strip_minor = FALSE) {
  deps <- readLines(file.path(path, "figs", "deps.txt"))
  ver <- purrr::detect(deps, function(dep) grepl(sprintf("^%s:", pkg), dep))

  if (is_null(ver)) {
    return(NULL)
  }

  # Strip prefixes like "FreeType: " or "Cairo: "
  ver <- substr(ver, nchar(pkg) + 3, nchar(ver))
  # Strip minor version
  if (strip_minor) {
    ver <- sub(".[0-9]+$", "", ver)
  }

  as_version(ver)
}
cases_freetype_version <- function(path = "..") {
  cases_pkg_version("FreeType", path, strip_minor = TRUE)
}

system_freetype_version <- function() {
  ver <- sub(".[0-9]+$", "", gdtools::version_freetype())
  as_version(ver)
}
as_version <- function(ver) {
  ver <- strsplit(ver, ".", fixed = TRUE)[[1]]
  ver <- as.integer(ver)
  structure(list(ver), class = c("package_version", "numeric_version"))
}

# Print only if we're not collecting. The testthat reporter prints
# verbose cases at a later point.
maybe_print_svgs <- function(case, pkg_path = NULL) {
  if (case$verbose && is_null(active_collecter())) {
    meow(svg_files_lines(case, pkg_path))
  }
}

new_expectation <- function(msg, case, type, vdiffr_type) {
  exp <- testthat::expectation(type, msg)
  classes <- c(class(exp), vdiffr_type)
  set_attrs(exp, class = classes, vdiffr_case = case)
}
new_exp <- function(msg, case) {
  new_expectation(msg, case, "skip", "vdiffr_new")
}
match_exp <- function(msg, case) {
  new_expectation(msg, case, "success", "vdiffr_match")
}
mismatch_exp <- function(msg, case) {
  new_expectation(msg, case, "failure", "vdiffr_mismatch")
}
skipped_mismatch_exp <- function(msg, case) {
  new_expectation(msg, case, "skip", "vdiffr_mismatch")
}

# From testthat
expectation_broken <- function(exp) {
  expectation_type(exp) %in% c("failure", "mismatch", "error")
}
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

#' Add a vdiffr dependency
#'
#' It is useful to record the version number of all the packages on
#' which your visual test cases depend. A note containing a version
#' number is added to the \code{DESCRIPTION} file for each dependency.
#' Dependencies on svglite and ggplot2 are automatically added. In
#' addition, \code{add_dependency()} can be called in any testthat
#' file to manually add a dependency to a package.
#'
#' @param deps A vector containing the names of the packages for which
#'   a dependency should be added.
#' @export
add_dependency <- function(deps) {
  collecter <- active_collecter()
  if (!is.null(collecter)) {
    walk(deps, collecter$add_dep)
  }
}
