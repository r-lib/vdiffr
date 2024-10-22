# vdiffr

<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/vdiffr)](https://cran.r-project.org/package=vdiffr)
[![R-CMD-check](https://github.com/r-lib/vdiffr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/r-lib/vdiffr/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/r-lib/vdiffr/graph/badge.svg)](https://app.codecov.io/gh/r-lib/vdiffr)
<!-- badges: end -->

vdiffr is a testthat extension for monitoring the appearance of R plots. It generates reproducible SVG files and registers them as [testthat snapshots](https://testthat.r-lib.org/articles/snapshotting.html).


## How to use vdiffr

1) Add graphical expectations by including `expect_doppelganger()` in your test files.

1) Run `devtools::test()`.

1) If `test()` detected new snapshots or changes to existing snapshots, run `testthat::snapshot_review()` to review them.

There may be many reasons for a snapshot to fail. Upstream changes (e.g. to the R graphics engine or to ggplot2) may cause subtle differences in your plots that are not actual failures. For this reason, snapshots do not cause failures on CRAN by default. You will only see failures locally or on CI platforms such as Github Actions.


### Adding expectations

vdiffr integrates with testthat through the `expect_doppelganger()` expectation. It takes as arguments:

- A title. This title is used in two ways. First, the title is standardised (it is converted to lowercase and any character that is not alphanumeric or a space is turned into a dash) and used as filename for storing the figure. Secondly, with ggplot2 figures the title is automatically added to the plot with `ggtitle()` (only if no ggtitle has been set).

- A figure. This can be a ggplot object, a recorded plot, a function to be called, or more generally any object with a `print` method.

The snapshots are recorded in subfolders of the `_snaps/` directory.

```{r}
disp_hist_base <- function() hist(mtcars$disp)
disp_hist_ggplot <- ggplot(mtcars, aes(disp)) + geom_histogram()

vdiffr::expect_doppelganger("Base graphics histogram", disp_hist_base)
vdiffr::expect_doppelganger("ggplot2 histogram", disp_hist_ggplot)
```

Note that in addition to automatic ggtitles, ggplot2 figures are
assigned the minimalistic theme `theme_test()` (unless they already
have been assigned a theme).


### Debugging

It is sometimes difficult to understand the cause of a doppelganger failure. A frequent cause of failure is undeterministic generation of plots. Potential culprits are:

* Some of the plot components depend on random variation. Try setting a seed, for instance with [`withr::local_seed()`](https://withr.r-lib.org/reference/with_seed.html).

* The plot depends on some system library. For instance sf plots depend on libraries like GEOS and GDAL. It might not be possible to test these plots with vdiffr (which can still be used for manual inspection, add a [testthat::skip()] before the `expect_doppelganger()` call in that case).

To help you understand the causes of a failure, vdiffr automatically logs the SVG diff of all failures when run under R CMD check. The log is located in `tests/vdiffr.Rout.fail` and should be displayed in your CI logs.

You can also set the `VDIFFR_LOG_PATH` environment variable with `Sys.setenv()` to unconditionally (also interactively) log failures in the file pointed by the variable.


### Skipping all vdiffr checks on some platforms

See ggplot2's approach which wraps `expect_doppelganger()` with a version that that calls `testthat::skip()` on the relevant platforms (as determined by environment variables): https://github.com/tidyverse/ggplot2/blob/ddd207e926cc1c1847dc661d9a099b8ec19c4010/tests/testthat/helper-vdiffr.R#L1-L15.


## Building vdiffr

_This section is only relevant for building vdiffr from scratch, as opposed to installing from a pre-built package on CRAN._

Building vdiffr requires the system dependency libpng. As vdiffr doesn't have any build-time configuration, your R configuration must point to libpng's `include` and `lib` folders.

For instance on macOS, install libpng with:

```sh
brew install libpng
```

And make sure your `~/.R/Makevars` knows about Homebrew's `include` and `lib` folders where libpng should now be installed. On arm64 hardware, this would be:

```mk
CPPFLAGS += -I/opt/homebrew/include
LDFLAGS += -L/opt/homebrew/lib
```
