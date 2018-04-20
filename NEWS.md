
# vdiffr 0.2.2.9000

* Use `last_collection_error()` to print a testthat error that
  occurred while collecting the test cases.

* Added global options to disable vdiffr. Set `vdiffr_skip` to `TRUE`
  to skip all vdiffr expectations.


# vdiffr 0.2.2

* Skip tests if the system version of Cairo (actually the one gdtools
  was compiled with) doesn't match the version of Cairo used to
  generate the testcases. Cairo has an influence on the computation of
  text metrics which can cause spurious test failures.

  We plan to fix these issues once and for all by embedding gdtools,
  svglite, Cairo and FreeType in the vdiffr package.


# vdiffr 0.2.1

This release fixes some CRAN failures.

* Test cases of the mock package were updated to FreeType 2.8.0.

* The unit test log file from the mock package is now preserved.


# vdiffr 0.2.0

This release makes it easier to debug failures on remote systems. It
also makes vdiffr more robust to failures caused by incompatible
installations: instead of failing, the tests are skipped. This
prevents spurious failures on CRAN.


## Troubleshooting on remotes

* `expect_doppelganger()` gains a `verbose` argument to print the
  SVG files for failed cases while testing. This is useful to debug
  failures on remotes.

* When tests are run by `R CMD check`, failures are now recorded in a
  log file called `vdiffr.fail`. This file will show up in the Travis
  log and can be retrieved from artifacts on Appveyor. It includes the
  SVG files for failed cases, which is useful to debug failures on
  remotes.


## Handling of incompatible systems

The tests are now skipped if the FreeType version used to build the
comparison SVGs does not match the version installed on the system
where the tests are run. This is necessary because changes in new
version of FreeType might affect the computation of text extents,
which then causes svglite to produce slightly different SVGs. The
minor version is not taken into account so FreeType 2.7.1 is deemed
compatible with 2.7.2 but not with 2.8.0.

In practice, this means that package contributors should only
validate visual cases if their FreeType version matches the one of
the package maintainer. Also, the maintainer must update the version
recorded in the package repository (in the file
`./tests/figs/deps.txt`) when FreeType has been updated on their
system. Running `vdiffr::validate_cases()` updates the dependency
file even if there are no visual case to update.

In the future, we may provide a version of vdiffr statically
compiled with a specific version of FreeType to prevent these issues.


## Other changes

* The minimal R version required by vdiffr is now R 3.1.0.


# vdiffr 0.1.1

* `expect_doppelganger()` no longer throws an error when FreeType is
  too old. Instead, the test is skipped. This ensures that R CMD check
  passes on those platforms (e.g., CRAN's Solaris test server).

* Depends on gdtools 0.1.2 or later as this version fixes a crash on
  Linux platforms.

* `widget_toggle()`, `widget_slide()` and `widget_diff()` now take
  plots as arguments. This makes it easy to embed a vdiffr widget in
  R Markdown documents. The underscored versions take HTML sources as
  argument (paths to SVG files or inline SVGs).


# vdiffr 0.1.0

* Generated SVGs are now reproducible across platforms thanks to
  recent versions of svglite, gdtools, and the new package fontquiver.
  vdiffr now requires versions of FreeType greater than 2.6.1.

* The figures folder is hardcoded to `tests/figs/`.

* The figures are now stored in subfolders according to the current
  testthat context. `expect_doppelganger()` accepts the `path`
  argument to bypass this behaviour (set it to `""` to store the
  figures in `tests/figs/`).

* The `title` argument of `expect_doppelganger()` now serves as
  `ggtitle()` in ggplot2 figures (unless a title is already set). It
  is also standardised and used as filename to store the figure
  (spaces and non-alphanumeric characters are converted to dashes).

* Add support for handling orphaned cases: you can now remove figures
  left over from deleted tests with `delete_orphaned_cases()` or from
  the Shiny app.

* New `filter` argument to `collect_cases()` and `manage_cases()`.
  This lets you filter the test files from which to collect the cases,
  which is useful to speed up the collection for large codebases with
  a lot of unit tests.

* Fix invalid generation of SVG files (#3)

* Give a warning when multiple doppelgangers have the same name (#4).

* Remove CR line endings before comparing svg files for compatibility
  with Windows


# vdiffr 0.0.0.9000

Initial release
