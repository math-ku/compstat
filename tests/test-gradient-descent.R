source(test_path("..", "R", "gradient_descent.R"), local = TRUE)

test_that("legacy gradient descent uses the book's smoothed gradient", {
  X <- matrix(1)
  y <- 2

  result <- gd(X, y, beta_mom = 0.5, maxit = 3)

  expect_equal(drop(result$betas), c(0, 1, 2))
  expect_equal(result$loss, c(2, 0.5, 0))
})

test_that("legacy gradient descent evaluates Nesterov at the lookahead", {
  X <- matrix(1)
  y <- 2

  result <- gd(
    X,
    y,
    beta_mom = 0.5,
    maxit = 3,
    type = "nesterov"
  )

  expect_equal(drop(result$betas), c(0, 2, 2))
})

test_that("legacy step-size argument remains available", {
  X <- matrix(1)
  y <- 2

  result <- gd(X, y, t = 0.5, maxit = 2)

  expect_equal(drop(result$betas), c(0, 1))
  expect_error(gd(X, y, gamma = 0.5, t = 0.5), "only one")
})

test_that("legacy general optimizer carries its smoothed gradient", {
  objective <- function(theta) 0.5 * (theta - 2)^2
  gradient <- function(theta) theta - 2

  result <- gd_general(
    0,
    objective,
    gradient,
    L = 1,
    beta_mom = 0.5,
    maxit = 3
  )

  expect_equal(drop(result$x), c(0, 1, 2))
})
