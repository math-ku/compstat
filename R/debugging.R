## An implementation of gradient descent
gradient_descent <- function(
    par,
    objective,
    gradient,
    t0 = 1e-4,
    alpha = 0.1,
    beta = 0.5,
    epsilon = 1e-4,
    maxit = 1000,
    ...) {
  for (i in 1:maxit) {
    obj <- objective(par, ...)
    grad <- gradient(par, ...)
    grad_norm <- norm(grad, "2")

    # Convergence criterion based on gradient norm
    if (grad_norm <= epsilon) {
      break
    }

    t <- t0

    # Proposed descent step
    x_new <- par - t * grad

    # Backtracking line search
    while (objective(x_new, ...) > obj - alpha * t * grad_norm^2) {
      t <- beta * t
      x_new <- par - t * grad
    }

    par <- x_new
  }

  if (i == maxit) {
    warning("Maximal number, ", maxit, ", of iterations reached")
  }

  par
}

# A buggy implementation of the Newton algorithm. This algorithm
# attempts to store all objective values in a vector and return
# those values in a list together with the final parameter vector.
newton_method <- function(
    x,
    objective,
    gradient,
    hessian,
    alpha = 0.1,
    beta = 0.5,
    t0 = 1,
    epsilon = 1e-10,
    maxit = 50) {
  obj_history <- rep(NA, maxit)

  for (i in 1:maxit) {
    obj <- objective(x)
    grad <- gradient(x)

    if (norm(grad, "2") <= epsilon) {
      break
    }

    hess <- hessian(x)
    d <- drop(solve(hess, grad))
    t <- t0
    x_new <- x + t * d
    grad_d_prod <- crossprod(grad, d)

    while (objective(x_new) > obj_history[i] + alpha * t * grad_d_prod) {
      gamma <- beta * t
      x_new <- x + gamma * d
    }

    x <- x_new
  }

  list(par = x, values = obj_history[!is.na(obj_history)])
}
