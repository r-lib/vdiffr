
as_inline_svg <- function(svg) {
  paste0("data:image/svg+xml;utf8,", svg)
}

make_testcase_file <- function(fig_name) {
  file <- tempfile(fig_name, fileext = ".svg")
  structure(file, class = "vdiffr_testcase")
}

get_aliases <- function() {
  aliases <- fontquiver::font_families("Liberation")
  aliases$symbol$symbol <- fontquiver::font_symbol("Symbola")
  aliases
}

write_svg <- function(p, file, title, user_fonts = NULL) {
  UseMethod("write_svg")
}

write_svg.plotly <- function(p, file, title, user_fonts = NULL) {
  withr::with_dir(dirname(file), plotly::orca(p, basename(file)))
}

write_svg.default <- function(p, file, title, user_fonts = NULL) {
  user_fonts <- user_fonts %||% get_aliases()
  svglite(file, user_fonts = user_fonts)
  on.exit(grDevices::dev.off())
  print_plot(p, title)
}

print_plot <- function(p, title) {
  UseMethod("print_plot")
}

print_plot.default <- function(p, title) {
  print(p)
}

print_plot.ggplot <- function(p, title) {
  add_dependency("ggplot2")
  if (title != "" && !"title" %in% names(p$labels)) {
    p <- p + ggplot2::ggtitle(title)
  }
  if (!length(p$theme)) {
    p <- p + ggplot2::theme_test()
  }
  print(p)
}

print_plot.recordedplot <- function(p, title) {
  grDevices::replayPlot(p)
}

print_plot.function <- function(p, title) {
  p()
}

# 'width' and 'height' attributes are necessary for correctly drawing
# a SVG into a canvas
svg_add_dims <- function(svg) {
  inline_pattern <- "^data:image/svg\\+xml;utf8,"
  is_inline <- grepl(inline_pattern, svg)

  if (is_inline) {
    tmp <- gsub(inline_pattern, "", svg)
  } else {
    tmp <- svg
  }

  xml <- xml2::read_xml(tmp)

  # Check if height or width are already defined, because the hack
  # below would create duplicates
  dim_attrs <- map(c("height", "width"), partial(xml2::xml_attr, xml))

  if (all(is.na(dim_attrs))) {
    viewbox <- strsplit(xml2::xml_attr(xml, "viewBox"), " ")[[1]]
    natural_width <- viewbox[[3]]
    natural_height <- viewbox[[4]]

    replacement <- sprintf("<svg width='%s' height='%s' ",
      natural_width, natural_height)

    # Ugly hack until xml2 can modify nodes
    svg <- gsub("<svg ", replacement, tmp)

    if (is_inline) {
      svg <- as_inline_svg(svg)
    }
  }

  svg
}

