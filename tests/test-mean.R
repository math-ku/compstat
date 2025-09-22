test_that("mean works", {
  expect_identical(mean(c(1, 2, 3)), 2)
  expect_identical(mean(c(4, 5, 6)), 5)
})
