# Default SVG writer

This is the default SVG writer for vdiffr test cases. It uses embedded
versions of [svglite](https://svglite.r-lib.org),
[harfbuzz](https://harfbuzz.github.io/), and the Liberation and Symbola
fonts in order to create deterministic SVGs.

## Usage

``` r
write_svg(plot, file, title = "")
```

## Arguments

- plot:

  A plot object to convert to SVG. Can be a ggplot2 object, a recorded
  plot, or any object with a
  [print()](https://rdrr.io/r/base/print.html) method.

- file:

  The file to write the SVG to.

- title:

  An optional title for the test case.
