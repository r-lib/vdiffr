
mock_path <- file.path("mock-pkg", "tests")
cases_ver <- vdiffr:::cases_freetype_version(mock_path)
system_ver <- vdiffr:::system_freetype_version()

cat(glue::glue("system: { as.character(gdtools::version_freetype()) }"), "\n")
cat(glue::glue("cases: { as.character(cases_ver) }"), "\n")

if (cases_ver != system_ver) {
  cat(glue::glue(
    "Skipping tests because the mock package was generated with a different FreeType version
     Mock package: { cases_ver }
     System: { system_ver }

    "
  ))

  # Return without error if called from R CMD check
  idx <- purrr::detect_index(sys.calls(), is_call, "test_check")

  if (idx) {
    cat("returning from ", idx, "\n")
    testthat_frame <- sys.frame(idx)
    return_from(testthat_frame)
  } else {
    abort("Please update vdiffr dependencies or testcases")
  }
}
