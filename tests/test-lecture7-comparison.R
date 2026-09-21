source(here::here("R", "lecture7-comparison.R"), local = TRUE)

test_that("the logistic objective and its derivatives agree", {
  problem <- logistic_comparison_problem(
    40,
    5,
    design_condition = 10,
    seed = 71
  )
  beta <- seq(-1, 1, length.out = 5)
  eta <- drop(problem$X %*% beta)
  expected <- -mean(dbinom(problem$y, 1, plogis(eta), log = TRUE)) +
    problem$lambda * sum(beta^2) / 2
  expect_equal(logistic_evaluate(beta, problem)$loss, expected)

  step <- 1e-5
  perturbations <- diag(step, length(beta))
  numeric_gradient <- vapply(
    seq_along(beta),
    function(j) {
      (logistic_evaluate(beta + perturbations[, j], problem)$loss -
        logistic_evaluate(beta - perturbations[, j], problem)$loss) /
        (2 * step)
    },
    numeric(1)
  )
  numeric_hessian <- vapply(
    seq_along(beta),
    function(j) {
      (logistic_gradient(beta + perturbations[, j], problem) -
        logistic_gradient(beta - perturbations[, j], problem)) /
        (2 * step)
    },
    numeric(length(beta))
  )

  expect_equal(
    logistic_gradient(beta, problem),
    numeric_gradient,
    tolerance = 1e-8
  )
  expect_equal(
    logistic_hessian(beta, problem),
    numeric_hessian,
    tolerance = 1e-8
  )
  expect_gt(
    max(abs(
      logistic_hessian(beta, problem) - logistic_hessian(beta * 0, problem)
    )),
    1e-3
  )
  expect_true(is.finite(logistic_evaluate(beta * 1e4, problem)$loss))

  spectrum <- eigen(
    logistic_hessian(beta * 0, problem),
    symmetric = TRUE
  )$values
  expect_equal(max(spectrum), problem$L)
  expect_gte(min(spectrum), problem$lambda)
})

test_that("both methods reach the same nonquadratic optimum", {
  problem <- logistic_comparison_problem(
    60,
    5,
    design_condition = 10,
    seed = 71
  )
  comparison <- compare_logistic_methods(problem)
  reference <- optim(
    rep(0, 5),
    function(beta) logistic_evaluate(beta, problem)$loss,
    function(beta) logistic_gradient(beta, problem),
    method = "BFGS",
    control = list(reltol = 1e-13, maxit = 2000)
  )
  expect_equal(comparison$minimum, reference$value, tolerance = 1e-10)
  expect_lt(comparison$reference_gap_bound, 1e-12)

  for (method_name in unique(comparison$history$method)) {
    curve <- comparison$history[comparison$history$method == method_name, ]
    expect_equal(curve$relative_gap[1], 1)
    expect_equal(curve$work[1], 0)
    expect_true(all(diff(curve$work) > 0))
    expect_true(all(diff(curve$relative_gap) <= 0))
    expect_lte(tail(curve$relative_gap, 1), comparison$tolerance)
    expect_true(all(head(curve$relative_gap, -1) > comparison$tolerance))
  }

  newton_summary <- subset(comparison$summary, method == "Newton")
  expect_gt(newton_summary$iteration, 1)
  expect_gt(newton_summary$work, newton_summary$iteration)
})

test_that("the contrasting logistic examples have the claimed work advantage", {
  large <- compare_logistic_methods(
    logistic_comparison_problem(2000, 400, design_condition = 2, seed = 72)
  )
  ill_conditioned <- compare_logistic_methods(
    logistic_comparison_problem(200, 20, design_condition = 100, seed = 73)
  )

  work <- function(comparison, method) {
    comparison$summary$work[comparison$summary$method == method]
  }

  expect_lt(work(large, "Gradient descent"), work(large, "Newton"))
  expect_lt(
    work(ill_conditioned, "Newton"),
    work(ill_conditioned, "Gradient descent")
  )
})
