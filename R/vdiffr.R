#' @import rlang
#' @importFrom glue glue
#' @importFrom purrr map map_chr keep walk every partial map2_chr compact
#' @importFrom R6 R6Class
#' @useDynLib vdiffr, .registration = TRUE
"_PACKAGE"

.onLoad <- function(lib, pkg) {
  if (!is_installed("freetypeharfbuzz")) {
    abort("The package `freetypeharfbuzz` is not installed")
  }
  library_load()
}

SVG_ENGINE_VER <- "1.0"

svg_engine_ver <- function() {
  as.numeric_version(SVG_ENGINE_VER)
}
