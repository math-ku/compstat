gd <- function(
  X,
  y,
  beta_mom = 0,
  maxit = 100,
  type = c("polyak", "nesterov"),
  gamma = NULL
) {
  loss <- double(maxit)
  type <- match.arg(type)

  p <- ncol(X)

  if (is.null(gamma)) {
    L <- norm(crossprod(X), "2")
    gamma <- 1 / L
  }

  betas <- matrix(0, nrow = p, ncol = maxit)
  rho <- double(p)
  loss[1] <- 0.5 * norm(y, "2")^2

  for (k in 2:maxit) {
    theta <- betas[, k - 1]

    if (type == "polyak") {
      gradient <- drop(crossprod(X, X %*% theta - y))
      rho <- beta_mom * rho + (1 - beta_mom) * gradient
      betas[, k] <- theta - gamma * rho
    } else {
      theta_prev <- betas[, max(1, k - 2)]
      lookahead <- theta + beta_mom * (theta - theta_prev)
      gradient <- drop(crossprod(X, X %*% lookahead - y))
      betas[, k] <- lookahead - gamma * gradient
    }

    loss[k] <- 0.5 * norm(y - X %*% betas[, k], "2")^2
  }

  list(coefficients = betas[, maxit], loss = loss, betas = betas)
}

gd_general <- function(
  par,
  f,
  grad_f,
  L,
  beta_mom = 0,
  type = c("polyak", "nesterov"),
  maxit = 100,
  ...
) {
  loss <- double(maxit)

  p <- length(par)

  type <- match.arg(type)

  x <- matrix(0, p, maxit)
  a <- double(maxit)
  x[, 1] <- par
  a[1] <- 1
  rho <- double(p)

  gamma <- 1 / L

  loss[1] <- f(x[, 1], ...)

  for (k in 2:maxit) {
    if (type == "polyak") {
      gradient <- drop(grad_f(x[, k - 1], ...))
      rho <- beta_mom * rho + (1 - beta_mom) * gradient
      x[, k] <- x[, k - 1] - gamma * rho
    } else {
      a[k] <- (1 + sqrt(1 + 4 * a[k - 1]^2)) / 2
      beta_n <- (a[k - 1] - 1) / a[k]
      lookahead <- x[, k - 1] +
        beta_n * (x[, k - 1] - x[, max(1, k - 2)])
      x[, k] <- lookahead - gamma * drop(grad_f(lookahead, ...))
    }

    # Compute the loss for the current iteration
    loss[k] <- f(x[, k], ...)
  }

  list(coefficients = x[, maxit], loss = loss, x = x)
}
