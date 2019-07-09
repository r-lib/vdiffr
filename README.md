
# vdiffr

<!-- badges: start -->
[![Travis Build Status](https://travis-ci.org/r-lib/vdiffr.svg?branch=master)](https://travis-ci.org/r-lib/vdiffr)
[![AppVeyor Build status](https://ci.appveyor.com/api/projects/status/github/r-lib/vdiffr?branch=master&svg=true)](https://ci.appveyor.com/project/r-lib/vdiffr)
[![Codecov test coverage](https://codecov.io/gh/r-lib/vdiffr/branch/master/graph/badge.svg)](https://codecov.io/gh/r-lib/vdiffr?branch=master)
[![CRAN status](https://www.r-pkg.org/badges/version/vdiffr)](https://cran.r-project.org/package=vdiffr)
<!-- badges: end -->

vdiffr is an extension to the package testthat that makes it easy to
test for visual regressions. It provides a Shiny app to manage failed
tests and visually compare a graphic to its expected output.


## Installation

Get the development version from github with:

```{r}
# install.packages("remotes")
remotes::install_github("r-lib/vdiffr")
```

or the last CRAN release with:

```{r}
install.packages("vdiffr")
```


## How to use vdiffr

Getting started with vdiffr is a three step process:

1) Add expectations to by including `expect_doppelganger()` in your test files.

1) Run `manage_cases()` to generate the plots which vdiffr will test against in
the future. This will launch a shiny gadget which will ask you to confirm
that each plot is correct.

1) Run `devtools::test()` to execute the tests as normal.

When a figure doesn't matched the saved version, vdiffr signals a failure when it is run interactively, or when it is run on Travis or Appveyor. Mismatches do not cause R CMD check to fail on CRAN machines. See the testing versus monitoring section below.


### Adding expectations

vdiffr integrates with testthat through the `expect_doppelganger()`
expectation. It takes as arguments:

- A title. This title is used in two ways. First, the title is
  standardised (it is converted to lowercase and any character that is
  not alphanumeric or a space is turned into a dash) and used as
  filename for storing the figure. Secondly, with ggplot2 figures the
  title is automatically added to the plot with `ggtitle()` (only if
  no ggtitle has been set).

- A figure. This can be a ggplot object, a recordedplot, a function to
  be called, or more generally any object with a `print` method.

- Optionally, a path where to store the figures, relative to
  `tests/figs/`. They are stored in a subfolder according to the
  current testthat context by default. Supply `path` to change the
  subfolder.

For example, the following tests will create figures in
`tests/figs/histograms/` called `base-graphics-histogram.svg` and
`ggplot2-histogram.svg`:

```{r}
context("Histograms")

disp_hist_base <- function() hist(mtcars$disp)
disp_hist_ggplot <- ggplot(mtcars, aes(disp)) + geom_histogram()

vdiffr::expect_doppelganger("Base graphics histogram", disp_hist_base)
vdiffr::expect_doppelganger("ggplot2 histogram", disp_hist_ggplot)
```

Note that in addition to automatic ggtitles, ggplot2 figures are
assigned the minimalistic theme `theme_test()` (unless they already
have been assigned a theme).


### Managing the tests

When you have added new test cases or detected regressions, you can
manage those from the R command line with the functions
`collect_cases()`, `validate_cases()`, and `delete_orphaned_cases()`.
However it's easier to run the shiny application `manage_cases()`.
With this app you can:

- Check how a failed case differs from its expected output using three
  widgets: Toggle (click to swap the images), Slide and Diff. If you
  use Github, you may be familiar with [the last two](https://github.com/blog/817-behold-image-view-modes).

- Validate cases. You can do so groupwise (all new cases or all failed
  cases) or on a case by case basis. When you validate a failed case,
  the old expected output is replaced by the new one.

- Delete orphaned cases. During a refactoring of your unit tests, some
  visual expectations may be removed or renamed. This means that some
  unused figures will linger in the `tests/figs/` folder. These
  figures appear in the Shiny application under the category
  "Orphaned" and can be cleaned up from there.

Both `manage_cases()` and `collect_cases()` take `package` as first
argument, the path to your package sources. This argument has exactly
the same semantics as in devtools. You can use vdiffr tools the same
way as you would use `devtools::check()`, for example. The default is
`"."`, meaning that the package is expected to be found in the current
folder.

All validated cases are stored in `tests/figs/`. This folder may be
handy to showcase the different graphs offered in your package. You
can also keep track of how your plots change as you tweak their layout
and add features by checking the history on Github.


### Running tests

You can run the tests the usual way, for example with
`devtools::test()`. New cases for which you just wrote an expectation
will be skipped. Failed tests will show as an error.


### Testing versus Monitoring

When a figure doesn't match its saved version, it is only reported as a failure under these circumstances:

- When the `NOT_CRAN` environment variable is set. In particular, devtools sets this when running the tests interactively.

- On Travis, Appveyor, or any environment where `Sys.getenv("CI")` is set.

Otherwise, the failure is ignored. The motivation for this is that vdiffr is a monitoring tool and shouldn't cause R CMD check failures on the CRAN machines.

Checking the appearance of a figure is inherently fragile. It is a bit like testing for errors by matching exact error messages. These messages are susceptible to change at any time. Similarly, the appearance of plots depends on a lot of upstream code, such as the way margins and spacing are computed. vdiffr uses a special ggplot2 theme that should change very rarely, but there are just too many upstream factors that could cause breakages. For this reason, figure mismatches are not necessarily representative of actual failures.

Visual testing is not an alternative to writing unit tests for the internal data transformations performed during the creation of your figure. It is more of a monitoring tool that allows you to quickly check how the appearance of your figures changes over time, and to manually assess whether changes reflect actual problems in your packages.

If you need to override the default vdiffr behaviour on CRAN (not recommended) or Travis (for example to run the tests in a particular builds but not others), set the `VDIFFR_RUN_TESTS` environment variable to "true" or "false".


### RStudio integration

An addin to launch `manage_cases()` is provided with vdiffr. Use the
addin menu to launch the Shiny app in an RStudio dialog.

![RStudio addin](https://raw.githubusercontent.com/r-lib/vdiffr/readme/rstudio-vdiffr.png)


### ESS integration

To use the Shiny app as part of ESS devtools integration with `C-c C-w
C-v`, include something like this in your init file:

```lisp
(defun ess-r-vdiffr-manage-cases ()
  (interactive)
  (ess-r-package-send-process "vdiffr::manage_cases(%s)\n"
                              "Manage vdiffr cases for %s"))

(define-key ess-r-package-dev-map "\C-v" 'ess-r-vdiffr-manage-cases)
```


## Debugging

It is sometimes difficult to understand the cause of a failure.  This usually indicates that the plot is not created deterministically. Potential culprits are:

* Some of the plot components depend on random variation. Try setting a seed.

* The plot depends on some system library. For instance sf plots depend on libraries like GEOS and GDAL. It might not be possible to test these plots with vdiffr (which can still be used for manual inspection, add a [testthat::skip()] before the `expect_doppelganger()` call in that case).

To help you understand the causes of a failure, vdiffr automatically logs the SVG diff of all failures when run under R CMD check. The log is located in `tests/vdiffr.Rout.fail` and should be displayed on Travis.

You can also set the `VDIFFR_LOG_PATH` environment variable with `Sys.setenv()` to unconditionally (also interactively) log failures in the file pointed by the variable.


## Implementation

### testthat Reporter

vdiffr extends testthat through a custom `Reporter`.
[Reporters](https://github.com/hadley/testthat/blob/master/R/reporter.R)
are classes (R6 classes in recent versions of testthat) whose
instances collect cases and output a summary of the tests. While
reporters are usually meant to provide output for the end user, you
can also use them in functions to interact with testthat.

vdiffr has a
[special reporter](https://github.com/r-lib/vdiffr/blob/master/R/testthat-reporter.R)
that does nothing but activate a collecter for the visual test
cases. `collect_cases()` calls `devtools::test()` with this
reporter. When `expect_doppelganger()` is called, it first checks
whether the case is new or failed. If that's the case, and if it finds
that vdiffr's collecter is active, it calls the collecter, which in
turns records the current test case.

This enables the user to run the tests with the usual development
tools and get feedback in the form of skipped or failed cases. On the
other hand, when vdiffr's tools are called, we collect information
about the tests of interest and wrap them in a data structure.


### SVG comparison

Comparing SVG files is convenient and should work correctly in most
situations. However, SVG is not suitable for tracking really subtle
changes and regressions. See
[vdiffr's issue #1](https://github.com/r-lib/vdiffr/issues/1) for a
discussion on this. vdiffr may gain additional comparison backends in
the future to make the tests more stringent.
