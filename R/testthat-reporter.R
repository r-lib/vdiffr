
casesCollecter <-
  R6::R6Class("casesCollecter",
    public = list(
      initialize = function(pkg_path) {
        default_deps <- c("vdiffr", "svglite")
        private$.cases <- cases(list(), pkg_path, default_deps)
      },

      add_case = function(case) {
        case <- set_names(list(case), case$name)
        private$.cases = c(private$.cases, case)
      },

      add_dep = function(dep) {
        deps <- attr(private$.cases, "deps")
        attr(private$.cases, "deps") <- unique(c(deps, dep))
      },

      get_cases = function() {
        private$.cases
      }
    ),

    private = list(
      .cases = NULL
    )
  )

vdiffr_env <- new.env(parent = emptyenv())

set_active_collecter <- function(collecter) {
  vdiffr_env$active_collecter <- collecter
}

active_collecter <- function() {
  vdiffr_env$active_collecter
}

maybe_collect_case <- function(case) {
  collecter <- active_collecter()

  if (!is.null(collecter)) {
    collecter$add_case(case)
  }
}

expectation_error <- function(exp) {
  exp <- gsub("^expectation_", "", class(exp)[[1]])
  exp == "error"
}

last_error_save <- NULL

#' Print last error that occurred during collection
#' @export
last_collection_error <- function() {
  last_error_save
}

vdiffrReporter <-
  R6::R6Class("vdiffrReporter", inherit = testthat::Reporter,
    public = list(
      failure = NULL,
      verbose_cases = list(),
      pkg_path = NULL,

      initialize = function(pkg_path) {
        self$pkg_path <- pkg_path
        collecter <- casesCollecter$new(pkg_path)
        set_active_collecter(collecter)
      },

      add_result = function(context, test, result) {
        cat(single_letter_summary(result))

        case <- attr(result, "vdiffr_case")
        if (expectation_error(result)) {
          self$failure <- result
        }
        if (is_verbose(result)) {
          self$verbose_cases <- c(self$verbose_cases, list(case))
        }
      },

      end_reporter = function() {
        meow()

        if (!is.null(self$failure)) {
          last_error_save <<- self$failure
          abort(glue(
            "while collecting vdiffr cases. Last error:
             * test: { self$failure$test }
             * message: { self$failure$message }
             You can inspect this error with `vdiffr::last_collection_error()`"
          ))
        }
        if (length(self$verbose_cases)) {
          meow(
            glue(
              "====================
               vdiffr failing cases
               ===================="
            ),
            map(self$verbose_cases, svg_files_lines, self$pkg_path),
            (
              "===================="
            )
          )
        }
      }
    )
  )

is_verbose <- function(x) {
  case <- attr(x, "vdiffr_case")
  !is_null(case) && case$verbose
}

expectation_type <- function(exp) {
  stopifnot(inherits(exp, "expectation"))
  if (inherits(exp, "vdiffr_new")) return("new")
  if (inherits(exp, "vdiffr_mismatch")) return("mismatch")
  if (inherits(exp, "vdiffr_match")) return("match")

  gsub("^expectation_", "", class(exp)[[1]])
}
single_letter_summary <- function(x) {
  switch(expectation_type(x),
    new      = "N",
    mismatch = "X",
    match    = "o",
    skip     = "S",
    success  = ".",
    error    = "E",
    failure  = "F",
    warning  = "W",
    "?"
  )
}
