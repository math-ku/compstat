source(test_path("..", "R", "kernel.R"), local = TRUE)

test_that("binned density separates bins from evaluation points", {
  x <- c(-1, -0.25, 0.5, 1.5)
  h <- 0.4
  m <- 21
  B <- 5

  result <- kern_dens_bin(x, h, m = m, B = B)

  rg <- range(x) + c(-3 * h, 3 * h)
  centers <- seq(rg[1], rg[2], length.out = B)
  weights <- kern_bin(x, rg[1], rg[2], B)
  expected <- vapply(
    result$x,
    function(point) sum(weights * dnorm(point, centers, h)),
    numeric(1)
  )

  expect_length(result$x, m)
  expect_length(result$y, m)
  expect_equal(result$y, expected)
})
