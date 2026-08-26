decay_scheduler <- function(t0 = 1, a = 1, K = 1, t1 = NULL, k1 = NULL) {
  force(a)

  if (!is.null(t1) && !is.null(k1)) {
    K <- k1^a * t1 / (t0 - t1)
  }

  b <- t0 * K

  function(k) b / (K + k^a)
}

logreg_sgd <- function(
  X,
  y,
  batch_size = 1,
  max_epochs = 100,
  t0 = NULL,
  loss_optim = 0,
  K = 5,
  a = 1,
  beta_mom = 0,
  # Momentum memory (0 = no momentum).
  momentum_type = "polyak" # "polyak" or "nesterov"
) {
  loss <- double(max_epochs)

  n <- nrow(X)
  p <- ncol(X)
  it <- 0

  if (is.null(t0)) {
    L <- 0.25 * norm(crossprod(X), "2") / n
    learning_rate <- 1 / L
  } else {
    learning_rate <- t0
  }

  scheduler <- decay_scheduler(t0 = learning_rate, K = K, a = a)

  full_batch <- n == batch_size

  # Initialize the coefficients
  beta <- double(p)
  beta_prev <- double(p)
  rho <- double(p)

  beta_history <- matrix(
    NA,
    nrow = p,
    ncol = max_epochs * ceiling(n / batch_size)
  )

  for (epoch in seq_len(max_epochs)) {
    n_seen <- 0
    while (n_seen < n) {
      it <- it + 1
      beta_history[, it] <- beta
      n_seen <- n_seen + batch_size

      if (!full_batch) {
        learning_rate <- scheduler(it)
      }

      ind <- sample(n, size = batch_size)

      X_batch <- X[ind, , drop = FALSE]
      y_batch <- y[ind]

      beta_current <- beta

      if (momentum_type == "nesterov" && beta_mom > 0) {
        beta_lookahead <- beta + beta_mom * (beta - beta_prev)
        z <- X_batch %*% beta_lookahead
      } else {
        z <- X_batch %*% beta
      }

      p_hat <- 1 / (1 + exp(-z))

      gradient <- drop(crossprod(X_batch, p_hat - y_batch)) / batch_size

      if (momentum_type == "polyak") {
        rho <- beta_mom * rho + (1 - beta_mom) * gradient
        beta_new <- beta - learning_rate * rho
      } else if (beta_mom > 0) {
        beta_new <- beta_lookahead - learning_rate * gradient
      } else {
        beta_new <- beta - learning_rate * gradient
      }

      beta_prev <- beta_current
      beta <- beta_new
    }

    # Compute the loss for the current iteration
    z <- X %*% beta
    p_hat <- 1 / (1 + exp(-z))
    loss[epoch] <- -mean(y * log(p_hat) + (1 - y) * log(1 - p_hat))

    if (loss[epoch] - loss_optim < 1e-6 * loss_optim) {
      break
    }
  }

  list(coefficients = beta, loss = loss, beta_history = beta_history)
}
