test_that("errors reset snapshots", {
  if (nzchar(Sys.getenv("VDIFFR_REGENERATE_SNAPS"))) {
    expect_doppelganger("error resets snapshots", function() plot(1:3))
  } else {
    expect_doppelganger("error resets snapshots", function() stop("failing"))
  }
})

test_that("skips reset snapshots", {
  if (nzchar(Sys.getenv("VDIFFR_REGENERATE_SNAPS"))) {
    expect_doppelganger("skip resets snapshots", function() plot(1:3))
  } else {
    expect_doppelganger("skip resets snapshots", function() skip("skipping"))
  }
})
