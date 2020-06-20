
if (getRversion() < "4.1.0") {
  library("testthat")
  library("vdiffr")
  test_check("vdiffr")
}
