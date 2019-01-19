
context("Cases")

test_that("Attributes are preserved", {
  cases <- vdiffr:::cases(list(), "pkg_path", "deps")
  new_cases <- filter_cases(cases, "new")

  expect_equal(attr(new_cases, "pkg_path"), "pkg_path")
  expect_equal(attr(new_cases, "deps"), "deps")
})

test_that("mock test cases contain context references", {
  mock_contexts <- vapply(mock_cases, function(x) x$context %||% NA_character_, character(1))
  # the two last ones don't have a context...this is ok
  expect_true(any(!is.na(mock_contexts)))
})
