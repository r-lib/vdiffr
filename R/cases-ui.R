#' Manage visual test cases with a Shiny app
#'
#' @inheritParams devtools::test
#' @inheritParams shiny::shinyApp
#' @param package Package description, can be path or package
#'   name. See [devtools::as.package()] for more information.
#' @param invert should the regexp supplied to `filter` be inverted? Defaults to `FALSE`.
#' @param ... Unused.
#' @seealso [vdiffrAddin()], [collect_cases()], and [validate_cases()]
#' @export
manage_cases <- function(package = ".", filter = NULL,
                         invert = FALSE, ..., options = list()) {
  cases <- collect_cases(package, filter = filter, invert = invert)
  cases <- filter_cases(cases, c("new_case", "mismatch_case", "orphaned_case", "success_case"))

  vdiffrApp <- shiny::shinyApp(
    ui = vdiffrUi(cases),
    server = vdiffrServer(cases),
    options = options
  )
  shiny::runApp(vdiffrApp)
}

#' RStudio Addin for managing visual cases
#'
#' The package is detected by looking for the currently active
#' project, then for the current folder if no project is active.
#' @seealso [manage_cases()], [collect_cases()], and [validate_cases()]
#' @export
vdiffrAddin <- function() {
  pkg_path <- rstudioapi::getActiveProject() %||% "."
  cases <- collect_cases(pkg_path)
  cases <- filter_cases(cases, c("new_case", "mismatch_case", "orphaned_case", "success_case"))

  vdiffrApp <- shiny::shinyApp(
    ui = vdiffrUi(cases),
    server = vdiffrServer(cases)
  )
  viewer <- shiny::dialogViewer("vdiffr", width = 1000, height = 800)
  shiny::runGadget(vdiffrApp, viewer = viewer)
}
