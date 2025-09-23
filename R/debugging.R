# Poisson regression via gradient descent and Newton's method
objective <- function(beta, X, y) {
  Xty <- drop(crossprod(X, y))
  (sum(exp(X %*% beta)) - beta %*% Xty) / nrow(X)
}

gradient <- function(beta, X, y) {
  Xty <- drop(crossprod(X, y))
  (colSums(drop(exp(X %*% beta)) * X) - Xty) / nrow(X)
}

hessian <- function(beta, X, y) {
  (crossprod(X, drop(exp(X %*% beta)) * X)) / nrow(X)
}

# An implementation of gradient descent
gradient_descent <- function(
  par,
  objective,
  gradient,
  t0 = 1e-4,
  alpha = 0.1,
  gamma = 0.5,
  epsilon = 1e-6,
  maxit = 1000,
  verbosity = 0,
  ...
) {
  obj_history <- rep(NA, maxit)

  for (i in 1:maxit) {
    obj <- objective(par, ...)
    obj_history[i] <- obj
    grad <- gradient(par, ...)
    grad_norm <- norm(grad, "2")

    # Convergence criterion based on gradient norm
    if (grad_norm <= epsilon) {
      break
    }

    t1 <- t0

    # Proposed descent step
    par_new <- par - t1 * grad

    # Backtracking line search
    while (objective(par_new, ...) > obj - alpha * t1 * grad_norm^2) {
      if (verbosity == 1) {
        cat("objective: ", objective(par_new, ...), "\n")
      }

      t1 <- gamma * t1
      par_new <- par - t1 * grad
    }

    par <- par_new
  }

  if (i == maxit) {
    warning("Maximal number, ", maxit, ", of iterations reached", call. = FALSE)
  }

  list(par = par, obj = obj_history[1:i])
}

# A buggy implementation of the Newton algorithm. This algorithm
# attempts to store all objective values in a vector and return
# those values in a list together with the final parameter vector.
newton_method <- function(
  par,
  objective,
  gradient,
  hessian,
  t0 = 1,
  alpha = 0.1,
  gamma = 0.5,
  epsilon = 1e-6,
  maxit = 50,
  verbosity = 0,
  ...
) {
  obj_history <- rep(NA, maxit)

  for (i in 1:maxit) {
    obj <- objective(par, ...)
    obj_history[i] <- obj
    grad <- gradient(par, ...)

    if (norm(grad, "2") <= epsilon) {
      break
    }

    hess <- hessian(par, ...)
    d <- -drop(solve(hess, grad))
    t1 <- t0
    par_new <- par + t1 * d
    grad_d_prod <- crossprod(grad, d)

    while (
      objective(par_new, ...) > obj_history[i] + alpha * t1 * grad_d_prod
    ) {
      if (verbosity == 1) {
        cat("objective: ", objective(par_new, ...), "\n")
      }

      t1 <- gamma * t1
      par_new <- par + t1 * d
    }

    par <- par_new
  }

  if (i == maxit) {
    warning("Maximal number, ", maxit, ", of iterations reached", call. = FALSE)
  }

  list(par = par, obj = obj_history[1:i])
}

