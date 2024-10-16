gd <- function(
    X,
    y,
    xi = 0,
    maxit = 100) {
  loss <- double(maxit)

  p <- ncol(X)

  L <- norm(crossprod(X), "2")
  gamma <- 1 / L

  beta <- double(p)
  betas <- matrix(
    NA,
    nrow = p,
    ncol = maxit
  )

  z <- double(p)

  for (it in seq_len(maxit)) {
    betas[, it] <- beta

    eta <- X %*% beta
    gradient <- crossprod(X, eta - y)

    z <- xi * z + gradient
    beta <- beta - gamma * z

    # Compute the loss for the current iteration
    loss[it] <- 0.5 * norm(y - eta, "2")^2
  }

  list(coefficients = beta, loss = loss, betas = betas)
}
