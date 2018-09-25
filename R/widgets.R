#' HTML Widgets for graphical comparison
#'
#' These widgets can be used at the console and embedded in a R
#' Markdown document or Shiny application.
#'
#' The regular versions take plots or functions as \code{before} and
#' \code{after} arguments (see \code{\link{expect_doppelganger}()}
#' for details). The versions suffixed with underscores take HTML image
#' sources. These can be paths to SVG files or inlined SVG
#' images. Currently, \code{widget_diff_()} is compatible only with
#' inlined images.
#'
#' @inheritParams htmlwidgets::createWidget
#' @param before The picture that is taken as reference.
#' @param after The picture against which the reference is compared.
#' @name htmlwidgets
#' @examples
#' p1 <- function() hist(mtcars$disp)
#' p2 <- function() hist(mtcars$drat)
#'
#' # You can also call these functions in a R Markdown document or
#' # in a Shiny application:
#' widget_toggle(p1, p2)
#' widget_slide(p1, p2)
#' widget_diff(p1, p2)
NULL

#' @rdname htmlwidgets
#' @export
widget_toggle_ <- function(before, after, input, width = NULL, height = NULL) {
  sources <- list(files = list(before = before, after = after))

  htmlwidgets::createWidget("vdiffr-toggle",
    x = sources,
    width = width,
    height = height,
    package = "vdiffr"
  )
}

#' @rdname htmlwidgets
#' @export
widget_slide_ <- function(before, after, input, width = NULL, height = NULL) {
  # Drawing a SVG into a canvas requires that the svg node has 'width'
  # and 'height' attributes set. Otherwise the result is oddly cropped.
  sources <- list(before = before, after = after)
  sources <- list(sources = map(sources, svg_add_dims))

  htmlwidgets::createWidget("vdiffr-slide",
    x = sources,
    width = width,
    height = height,
    package = "vdiffr"
  )
}

#' @rdname htmlwidgets
#' @export
widget_diff_ <- function(before, after, input, width = NULL, height = NULL) {
  sources <- list(before = before, after = after)
  sources <- list(sources = map(sources, svg_add_dims))

  htmlwidgets::createWidget("vdiffr-diff",
    x = sources,
    width = width,
    height = height,
    package = "vdiffr"
  )
}

#' @export
diff_text_ <- function(before, after, input) {
  # https://github.com/brodieG/diffobj/issues/125#issuecomment-414699100
  shiny::HTML(
    as.character(
      diffobj::diffChr(
        before, 
        after, 
        mode = input$mode %||% "unified",
        format = 'html',
        style = list(html.output = 'diff.w.style')
      )
    )
  )
}

#' @rdname htmlwidgets
#' @export
widget_toggle <- function(before, after, input, width = NULL, height = NULL) {
  files <- widget_svgs(before, after)
  widget_toggle_(files$before, files$after, width, height)
}

#' @rdname htmlwidgets
#' @export
widget_slide <- function(before, after, input, width = NULL, height = NULL) {
  files <- widget_svgs(before, after)
  widget_slide_(files$before, files$after, width, height)
}

#' @rdname htmlwidgets
#' @export
widget_diff <- function(before, after, input, width = NULL, height = NULL) {
  files <- widget_svgs(before, after)
  widget_diff_(files$before, files$after, width, height)
}

widget_svgs <- function(before, after) {
  out <- suppressMessages(list(
    before = stringSVG(print_plot(before, "")),
    after = stringSVG(print_plot(after, ""))
  ))

  # widget_diff() does not work if SVG doesn't finish with newline
  out <- map(out, paste0, "\n")

  # Inline SVGs so the widget can be easily embedded anywhere
  out <- map(out, as_inline_svg)

  out
}
