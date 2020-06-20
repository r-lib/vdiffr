test_that("Orphaned figures are found", {
  orphaned <- filter_cases(mock_cases, "orphaned_case")
  expect_equal(map_chr(unname(orphaned), "name"), c("orphaned1", "orphaned2"))
})

test_that("Orphaned files are found and deleted", {
  orphaned <- filter_cases(mock_cases, "orphaned_case")
  files <- map_chr(orphaned, "path")
  files <- map_chr(files, purrr::partial(file.path, mock_pkg_dir, "tests", "testthat"))
  files_exist <- purrr::every(files, file.exists)
  expect_true(files_exist)

  if (files_exist) {
    delete_orphaned_cases(mock_cases)
    expect_false(purrr::some(files, file.exists))
  }
})
