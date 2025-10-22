gd <- function(
  X,
  y,
  mu = 0,
  maxit = 100,
  type = c("polyak", "nesterov")
) {
  loss <- double(maxit)
  type <- match.arg(type)

  p <- ncol(X)

  L <- norm(crossprod(X), "2")
  gamma <- 1 / L

  betas <- matrix(
    0,
    nrow = p,
    ncol = maxit
  )

  mu_nesterov <- a <- double(maxit)
  a[1] <- 1

  for (k in 2:maxit) {
    eta <- X %*% betas[, k - 1]
    gradient <- crossprod(X, eta - y)

    beta_update <- switch(
      type,
      polyak = -gamma *
        gradient +
        mu * (betas[, k - 1] - betas[, max(1, k - 2)]),
      nesterov = {
        a[k] <- (1 + sqrt(1 + 4 * a[k - 1]^2)) / 2
        mu[k] <- (a[k - 1] - 1) / a[k]
        mom <- mu[k] * (betas[, max(1, k - 1)] - betas[, max(1, k - 2)])

        -gamma * gradient + mom
      }
    )

    betas[, k] <- betas[, k - 1] + beta_update

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
