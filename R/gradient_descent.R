gd <- function(
  X,
  y,
  beta_mom = 0,
  gamma = NULL,
  line_search = FALSE,
  maxit = 100,
  t = NULL,
  type = c("polyak", "nesterov")
) {
  loss <- double(maxit)
  type <- match.arg(type)

  p <- ncol(X)

  if (!is.null(t)) {
    if (!is.null(gamma)) {
      stop("Specify only one of `gamma` and the legacy `t` argument.")
    }
    gamma <- t
  }

  if (is.null(gamma)) {
    L <- norm(crossprod(X), "2")
    gamma <- 1 / L
  }

  gamma0 <- gamma

  betas <- matrix(0, nrow = p, ncol = maxit)
  rho <- double(p)

  loss[1] <- 0.5 * norm(y - X %*% betas[, 1], "2")^2

  for (k in 2:maxit) {
    theta <- betas[, k - 1]

    if (type == "polyak") {
      base <- theta
      gradient <- drop(crossprod(X, X %*% base - y))
      rho <- beta_mom * rho + (1 - beta_mom) * gradient
      direction <- -rho
    } else {
      theta_prev <- betas[, max(1, k - 2)]
      base <- theta + beta_mom * (theta - theta_prev)
      gradient <- drop(crossprod(X, X %*% base - y))
      direction <- -gradient
    }

    keep_going <- TRUE
    gamma <- gamma0

    while (line_search && keep_going) {
      new_eta <- X %*% (base + gamma * direction)
      new_loss <- 0.5 * norm(y - new_eta, "2")^2
      base_loss <- 0.5 * norm(y - X %*% base, "2")^2

      if (new_loss <= base_loss + gamma / 2 * sum(gradient * direction)) {
        keep_going <- FALSE
      } else {
        gamma <- gamma / 2
      }
    }

    betas[, k] <- base + gamma * direction

    loss[k] <- 0.5 * norm(y - X %*% betas[, k], "2")^2
  }

  list(coefficients = betas[, maxit], loss = loss, betas = betas)
}

newton <- function(X, y, maxit = 100, t = NULL, line_search = TRUE) {
  loss <- double(maxit)
  p <- ncol(X)
  betas <- matrix(0, nrow = p, ncol = maxit)
  loss[1] <- 0.5 * norm(y - X %*% betas[, 1], "2")^2

  if (is.null(t)) {
    t <- 1
  }

  t0 <- t

  H <- crossprod(X) # Hessian: X^T X

  for (k in 2:maxit) {
    eta <- X %*% betas[, k - 1]
    gradient <- crossprod(X, eta - y)
    direction <- -solve(H, gradient) # Newton direction

    keep_going <- TRUE
    t <- t0

    while (line_search && keep_going) {
      new_eta <- X %*% (betas[, k - 1] + t * direction)
      new_loss <- 0.5 * norm(y - new_eta, "2")^2

      if (
        new_loss <=
          loss[k - 1] +
            t * sum(gradient * direction) +
            (t^2 / 2) * sum(direction * (H %*% direction))
      ) {
        keep_going <- FALSE
      } else {
        t <- t / 2
      }
    }

    betas[, k] <- betas[, k - 1] + t * direction

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

    loss[k] <- f(x[, k], ...)
  }

  list(coefficients = x[, maxit], loss = loss, x = x)
}
