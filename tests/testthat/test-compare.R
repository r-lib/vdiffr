write_tempfile <- function(lines) {
  path <- tempfile()

  file <- file(path)
  open(file, "w")
  writeLines(lines, file)
  close(file)

  path
}

test_that("files are correctly compared", {
  original <- write_tempfile(letters)
  good <- write_tempfile(letters)
  bad <- write_tempfile(LETTERS)

  expect_true(compare_files(original, good))
  expect_false(compare_files(original, bad))
})

test_that("CR are removed before comparison", {
  crlf_path <- tempfile()
  lf_path <- tempfile()
  writeChar("foo\r\nbar\nbaz\r\nbam", crlf_path, useBytes = TRUE)
  writeChar("foo\nbar\nbaz\nbam", lf_path, useBytes = TRUE)

  expect_true(compare_files(lf_path, crlf_path))
})
