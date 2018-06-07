
# vdiffr

[![Travis-CI Build Status](https://travis-ci.org/lionel-/vdiffr.svg?branch=master)](https://travis-ci.org/lionel-/vdiffr)
[![Build status](https://ci.appveyor.com/api/projects/status/github/lionel-/vdiffr?branch=master)](https://ci.appveyor.com/project/lionel-/vdiffr)

vdiffr is an extension to the package testthat that makes it easy to
test for visual regressions. It provides a Shiny app to manage failed
tests and visually compare a graphic to its expected output.


## Installation

Get the development version from github with:

```{r}
# install.packages("devtools")
devtools::install_github("lionel-/vdiffr")
```

or the last CRAN release with:

```{r}
install.packages("vdiffr")
```

vdiffr requires FreeType greater than 2.6.0. It is automatically
installed on Windows along with gdtools and comes with X11 on
macOS. If you run an old Linux distribution, it is possible you will
have to update the relevant package. See the section on Travis-CI
below for some indications.


## How to use vdiffr

Getting started with vdiffr is a three step process:

1) Add expectations to by including `expect_doppelganger()` in your test files
1) Run `manage_cases()` to generate the plots which vdiffr will test against in 
the future. This will launch a shiny gadget which will ask you to confirm
that each plot is correct
1) Run `devtools::test()` to execute the tests as normal

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

### RStudio integration

An addin to launch `manage_cases()` is provided with vdiffr. Use the
addin menu to launch the Shiny app in an RStudio dialog.

![RStudio addin](https://raw.githubusercontent.com/lionel-/vdiffr/readme/rstudio-vdiffr.png)


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


## Technical Aspects

### FreeType dependency

The software FreeType plays a key role in vdiffr. It is used to
compute the extents of text boxes and thus determine the dimensions of
graphical elements containing text. These dimensions are then recorded
in the SVG files.

Small changes in the algorithm implemented in FreeType to compute text
extents will produce different SVGs. For this reason, it is important
that the FreeType version that was used to create validated cases be
the same as the one on the system running the tests. To avoid false
failures, the visual tests are skipped when that's not the case. The
minor version is not taken into account so FreeType 2.7.1 is deemed
compatible with 2.7.2 but not with 2.8.0.

In practice, this means that package contributors should only validate
visual cases if their FreeType version matches the one of the package
maintainer. Also, the maintainer must update the version recorded in
the package repository (in the file `./tests/figs/deps.txt`) when
FreeType has been updated on their system. Running
`vdiffr::validate_cases()` updates the dependency file even if there
are no visual case to update.


### Windows platforms

Appveyor does not require any configuration since FreeType 2.6.0 is
automatically installed on this platform along with gdtools. However,
Fontconfig builds a cache of all system fonts the first time it is
run, which can take a while. It is a good idea to add the following in
a `fontconfig-helper.R` testthat file in order to speed up the cache
building on Appveyor and on CRAN's Windows servers:

```{r}
on_appveyor <- function() {
  identical(Sys.getenv("APPVEYOR"), "True")
}
on_cran <- function() {
  !identical(Sys.getenv("NOT_CRAN"), "true")
}

# Use minimal fonts.conf to speed up fc-cache
if (on_appveyor() || on_cran()) {
  gdtools::set_dummy_conf()
}
```


### Dependency notes

vdiffr currently uses svglite to save the plots in a text format that
makes it easy to perform comparisons. This makes the test cases
dependent on that package as the SVG translation of the plot may
change across different versions of svglite (though that should not
happen often). For this reason, whenever you validate a graphical test
case, the `tests/figs/deps.txt` file is updated with a note containing
the svglite version. This works the same way as the roxygen version
note.

Your graphics might be dependent on other packages besides svglite. If
your package is an extension to ggplot2 for instance, the appearance
of your plot may change as ggplot2 evolves (as with the 2.0 version
which tweaked the grayness of the background color among other
changes). For this reason, `expect_doppelganger()` adds a dependence
on ggplot2 when you supply a ggplot2 object. You can also manually add
a dependency on any other package by calling `vdiffr::add_dependency()`
anywhere in a test file.


## Implementation

### testthat Reporter

vdiffr extends testthat through a custom `Reporter`.
[Reporters](https://github.com/hadley/testthat/blob/master/R/reporter.R)
are classes (R6 classes in recent versions of testthat) whose
instances collect cases and output a summary of the tests. While
reporters are usually meant to provide output for the end user, you
can also use them in functions to interact with testthat.

vdiffr has a
[special reporter](https://github.com/lionel-/vdiffr/blob/master/R/testthat-reporter.R)
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
[vdiffr's issue #1](https://github.com/lionel-/vdiffr/issues/1) for a
discussion on this. vdiffr may gain additional comparison backends in
the future to make the tests more stringent.
