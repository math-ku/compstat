gd <- function(
  X,
  y,
  mu = 0,
  t = NULL,
  line_search = FALSE,
  maxit = 100
) {
  loss <- double(maxit)

  p <- ncol(X)

  if (is.null(t)) {
    L <- norm(crossprod(X), "2")
    t <- 1 / L
  }

  if (line_search) {
    t <- 1
  }

  betas <- matrix(
    0,
    nrow = p,
    ncol = maxit
  )

  loss[1] <- 0.5 * norm(y - X %*% betas[, 1], "2")^2

  for (k in 2:maxit) {
    eta <- X %*% betas[, k - 1]
    gradient <- crossprod(X, eta - y)

    keep_going <- TRUE

    while (line_search && keep_going) {
      new_eta <- X %*% (betas[, k - 1] - t * gradient)
      new_loss <- 0.5 * norm(y - new_eta, "2")^2

      if (new_loss <= loss[k - 1] - (t / 2) * norm(gradient, "2")^2) {
        keep_going <- FALSE
      } else {
        t <- t / 2
      }
    }

    betas[, k] <- betas[, k - 1] -
      t * gradient +
      mu * (betas[, k - 1] - betas[, max(1, k - 2)])

    # Compute the loss for the current iteration
    loss[k] <- 0.5 * norm(y - eta, "2")^2
  }

  list(coefficients = betas[, maxit], loss = loss, betas = betas)
}


gd_general <- function(
  par,
  f,
  grad_f,
  L,
  mu = 0,
  type = c("polyak", "nesterov"),
  maxit = 100,
  ...
) {
  loss <- double(maxit)

  p <- length(par)

  type <- match.arg(type)

  x <- matrix(0, p, maxit)
  mu_nesterov <- a <- double(maxit)
  x[, 1] <- par
  a[1] <- 1

  gamma <- 1 / L

  loss[1] <- f(x[, 1], ...)

  for (k in 2:maxit) {
    if (type == "polyak") {
      mom <- mu * (x[, max(1, k - 1)] - x[, max(1, k - 2)])
      x[, k] <- x[, k - 1] - gamma * grad_f(x[, k - 1], ...) + mom
    } else {
      a[k] <- (1 + sqrt(1 + 4 * a[k - 1]^2)) / 2
      mu[k] <- (a[k - 1] - 1) / a[k]
      mom <- mu[k] * (x[, max(1, k - 1)] - x[, max(1, k - 2)])

      x[, k] <- x[, k - 1] - gamma * grad_f(x[, k - 1] + mom, ...) + mom
    }

    # Compute the loss for the current iteration
    loss[k] <- f(x[, k], ...)
  }

  list(coefficients = x[, maxit], loss = loss, x = x)
}
