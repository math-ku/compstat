source(test_path("..", "R", "gd.R"), local = TRUE)
source(test_path("..", "R", "sgd.R"), local = TRUE)

test_that("Polyak momentum uses the book's smoothed gradient", {
  X <- matrix(1)
  y <- 2

  result <- gd(X, y, beta_mom = 0.5, maxit = 3)

  expect_equal(drop(result$betas), c(0, 1, 2))
})

test_that("Nesterov momentum evaluates the gradient at the look-ahead point", {
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

test_that("logistic SGD carries a smoothed gradient between updates", {
  X <- matrix(1)
  y <- 1

  result <- logreg_sgd(
    X,
    y,
    batch_size = 1,
    max_epochs = 2,
    t0 = 1,
    beta_mom = 0.5
  )

  gradient_1 <- plogis(0) - y
  rho_1 <- 0.5 * gradient_1
  theta_1 <- -rho_1
  gradient_2 <- plogis(theta_1) - y
  rho_2 <- 0.5 * rho_1 + 0.5 * gradient_2

  expect_equal(drop(result$beta_history), c(0, theta_1))
  expect_equal(result$coefficients, theta_1 - rho_2)
})
