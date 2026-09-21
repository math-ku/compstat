logistic_comparison_problem <- function(
  n,
  p,
  design_condition,
  seed,
  lambda = 1e-3
) {
  stopifnot(n >= p, p >= 2, design_condition >= 1, lambda > 0)
  set.seed(seed)

  left <- qr.Q(qr(matrix(rnorm(n * p), n, p)))
  right <- qr.Q(qr(matrix(rnorm(p * p), p, p)))
  eigenvalues <- exp(seq(-log(design_condition), 0, length.out = p))

  # Control the design spectrum without giving either optimizer its eigenvectors.
  X <- sweep(left, 2, sqrt(n * eigenvalues), "*") %*% t(right)
  # Keep the signal strength fixed as the dimension and conditioning change.
  beta <- drop(right %*% (2 / sqrt(p * eigenvalues)))
  y <- rbinom(n, 1, plogis(drop(X %*% beta)))

  list(
    X = X,
    y = y,
    lambda = lambda,
    L = max(eigenvalues) / 4 + lambda,
    design_condition = design_condition
  )
}

logistic_evaluate <- function(beta, problem) {
  eta <- drop(problem$X %*% beta)
  signed_eta <- (1 - 2 * problem$y) * eta
  # This form avoids overflow and cancellation for large fitted log odds.
  loss <- mean(pmax(signed_eta, 0) + log1p(exp(-abs(signed_eta)))) +
    problem$lambda * sum(beta^2) / 2
  list(loss = loss, probability = plogis(eta))
}

logistic_gradient <- function(beta, problem, probability = NULL) {
  if (is.null(probability)) {
    probability <- plogis(drop(problem$X %*% beta))
  }
  drop(crossprod(problem$X, probability - problem$y)) /
    nrow(problem$X) +
    problem$lambda * beta
}

logistic_hessian <- function(beta, problem, probability = NULL) {
  if (is.null(probability)) {
    probability <- plogis(drop(problem$X %*% beta))
  }
  weighted_X <- problem$X *
    sqrt(probability * (1 - probability) / nrow(problem$X))
  crossprod(weighted_X) + diag(problem$lambda, ncol(problem$X))
}

fit_logistic_comparison <- function(
  problem,
  method = c("Gradient descent", "Newton"),
  minimum = NULL,
  tolerance = 1e-8,
  maxit = 20000L
) {
  method <- match.arg(method)
  n <- nrow(problem$X)
  p <- ncol(problem$X)
  beta <- rep(0, p)
  state <- logistic_evaluate(beta, problem)
  initial_loss <- state$loss
  history <- data.frame(iteration = 0L, loss = initial_loss, work = 0)

  # Reuse accepted fitted probabilities: a GD step needs two matrix-vector products.
  gd_work <- 4 * n * p
  # Newton also weights X, forms a symmetric Gram matrix, and uses Cholesky.
  hessian_work <- n * p + n * p * (p + 1) + p^3 / 3 + 2 * p^2
  work <- 0

  for (iteration in seq_len(maxit)) {
    gradient <- logistic_gradient(beta, problem, state$probability)
    # Ridge curvature bounds the reference objective's distance from the optimum.
    gap_bound <- sum(gradient^2) / (2 * problem$lambda)
    if (is.null(minimum) && gap_bound <= 1e-16) {
      return(list(beta = beta, history = history, gap_bound = gap_bound))
    }

    if (method == "Newton") {
      hessian <- logistic_hessian(beta, problem, state$probability)
      factor <- chol(hessian)
      direction <- -backsolve(factor, forwardsolve(t(factor), gradient))
      step <- 1
      work <- work + hessian_work
    } else {
      direction <- -gradient
      step <- 1 / problem$L
    }

    candidate <- logistic_evaluate(beta + step * direction, problem)
    evaluations <- 1L
    if (method == "Newton") {
      slope <- sum(gradient * direction)
      while (candidate$loss > state$loss + 0.25 * step * slope) {
        if (evaluations >= 50L) {
          stop("Newton's line search failed to find a sufficient decrease.")
        }
        step <- step / 2
        candidate <- logistic_evaluate(beta + step * direction, problem)
        evaluations <- evaluations + 1L
      }
    }

    beta <- beta + step * direction
    state <- candidate
    # Charge every trial evaluation, including rejected line-search candidates.
    work <- work + 2 * n * p * (1 + evaluations)
    history <- rbind(
      history,
      data.frame(
        iteration = iteration,
        loss = state$loss,
        work = work / gd_work
      )
    )

    if (
      !is.null(minimum) &&
        state$loss - minimum <= tolerance * (initial_loss - minimum)
    ) {
      return(list(beta = beta, history = history))
    }
  }
  stop(method, " did not reach the requested accuracy.")
}

compare_logistic_methods <- function(problem, tolerance = 1e-8) {
  stopifnot(tolerance > 0, tolerance < 1)
  reference <- fit_logistic_comparison(problem, "Newton")
  minimum <- tail(reference$history$loss, 1)

  history <- lapply(c("Gradient descent", "Newton"), function(method) {
    fit <- fit_logistic_comparison(problem, method, minimum, tolerance)
    curve <- fit$history
    curve$method <- method
    curve$relative_gap <- pmax(0, curve$loss - minimum) /
      (curve$loss[1] - minimum)
    curve
  })
  curves <- do.call(rbind, history)

  list(
    history = curves,
    summary = curves[!duplicated(curves$method, fromLast = TRUE), ],
    minimum = minimum,
    reference_gap_bound = reference$gap_bound,
    tolerance = tolerance,
    n = nrow(problem$X),
    p = ncol(problem$X),
    lambda = problem$lambda,
    design_condition = problem$design_condition
  )
}
