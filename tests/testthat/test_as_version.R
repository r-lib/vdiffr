context("as_version")

test_that("Bad version string", {
  version_string_good <- "1.14.6"
  version_string_bad  <- "Cairo: 1.14.6"

  ver_good <- structure( list(as.integer(c(1, 14, 6))),
                         class = c("package_version", "numeric_version") )

  expect_equal(ver_good, as_version(version_string_good) )
  expect_equal(ver_good, as_version(version_string_bad)  )
})
