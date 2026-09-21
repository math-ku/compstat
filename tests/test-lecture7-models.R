source(here::here("R", "gradient_descent.R"), local = TRUE)
source(here::here("R", "lecture7-models.R"), local = TRUE)

x <- cbind(1, c(-2, 0, 3, 1))
y <- c(1, -1, 4, 2)

test_that("the plotted OLS objective agrees with optimizer losses", {
  result <- gd(x, y, t = 0.02, maxit = 4)
  plotted_loss <- apply(result$betas, 2, ols_objective, x = x, y = y)

  expect_equal(plotted_loss, result$loss)
})

test_that("the Newton model equals the quadratic objective everywhere", {
  points <- rbind(c(0, 0), c(-0.6, 0.7), c(1.2, -1.5), c(2, 3))
  objective <- apply(points, 1, ols_objective, x = x, y = y)

  for (i in seq_len(nrow(points))) {
    model <- apply(points, 1, function(beta) {
      drop(ols_newton_model(beta, points[i, ], x, y))
    })
    expect_equal(model, objective)
  }
})

test_that("both models match the objective and gradient at the expansion point", {
  beta0 <- c(-0.6, 0.7)
  direction <- c(0.4, -0.3)
  h <- 1e-5
  slope <- (ols_objective(beta0 + h * direction, x, y) -
    ols_objective(beta0 - h * direction, x, y)) /
    (2 * h)

  models <- list(
    function(beta) ols_gd_model(beta, beta0, x, y, t = 0.02),
    function(beta) ols_newton_model(beta, beta0, x, y)
  )

  for (model in models) {
    expect_equal(drop(model(beta0)), ols_objective(beta0, x, y))
    model_slope <- drop(
      (model(beta0 + h * direction) - model(beta0 - h * direction)) / (2 * h)
    )
    expect_equal(model_slope, slope, tolerance = 1e-7)
  }
})

test_that("minimizing the GD model gives the optimizer's next iterate", {
  for (step in c(0.02, 0.1)) {
    result <- gd(x, y, t = step, maxit = 2)
    model_minimum <- optim(
      c(0, 0),
      function(beta) drop(ols_gd_model(beta, c(0, 0), x, y, t = step)),
      method = "BFGS",
      control = list(reltol = 1e-12)
    )

    expect_equal(model_minimum$convergence, 0L)
    expect_equal(model_minimum$par, result$betas[, 2], tolerance = 1e-5)
  }
})

test_that("one full Newton step solves the OLS example", {
  result <- newton(x, y, t = 1, maxit = 2, line_search = FALSE)

  expect_equal(drop(result$coefficients), unname(qr.solve(x, y)))
  expect_equal(
    ols_objective(result$coefficients, x, y),
    result$loss[2]
  )
})

test_that("the nonquadratic example's derivatives agree with finite differences", {
  theta <- c(-3, -1, 0, 1, 3)
  h <- 1e-4
  gradient <- (nonquadratic_objective(theta + h) -
    nonquadratic_objective(theta - h)) /
    (2 * h)
  hessian <- (nonquadratic_gradient(theta + h) -
    nonquadratic_gradient(theta - h)) /
    (2 * h)

  expect_equal(nonquadratic_gradient(theta), gradient, tolerance = 1e-7)
  expect_equal(nonquadratic_hessian(theta), hessian, tolerance = 1e-7)
})

test_that("the nonquadratic Taylor model is accurate locally but not exact", {
  theta0 <- -2
  expect_equal(
    nonquadratic_model(theta0, theta0),
    nonquadratic_objective(theta0)
  )

  steps <- c(0.1, 0.05)
  error <- abs(
    nonquadratic_model(theta0 + steps, theta0) -
      nonquadratic_objective(theta0 + steps)
  )

  expect_gt(error[1] / error[2], 7)
  expect_lt(error[1] / error[2], 9)
  expect_gt(abs(nonquadratic_model(3, theta0) - nonquadratic_objective(3)), 0.1)
})
