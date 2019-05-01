
casesCollecter <-
  R6::R6Class("casesCollecter",
    public = list(
      initialize = function(pkg_path) {
        default_deps <- chr()
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

last_error <- new_environment(list(last = NULL))

#' Print last error that occurred during collection
#' @export
last_collection_error <- function() {
  last_error$last
}

vdiffrReporter <-
  R6::R6Class("vdiffrReporter", inherit = testthat::Reporter,
    public = list(
      failure = NULL,
      pkg_path = NULL,

      initialize = function(pkg_path) {
        self$pkg_path <- pkg_path
        collecter <- casesCollecter$new(pkg_path)
        set_active_collecter(collecter)
      },

      add_result = function(context, test, result) {
        cat(single_letter_summary(result))
        private$.result_counter <- private$.result_counter + 1
        if (private$.result_counter >= getOption("width")) {
          cat("\n")
          private$.result_counter <- 0
        }

        case <- attr(result, "vdiffr_case")
        if (expectation_error(result)) {
          self$failure <- result
        }
      },

      end_reporter = function() {
        cat_line()

        if (!is.null(self$failure)) {
          last_error$last <- self$failure
          abort(glue(
            "while collecting vdiffr cases. Last error:
             * test: { self$failure$test }
             * message: { self$failure$message }
             You can inspect this error with `vdiffr::last_collection_error()`"
          ))
        }
      }
    ),
    
    private = list(
      .result_counter = 0
    )
  )

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
