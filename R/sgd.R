decay_scheduler <- function(
  gamma0 = 1,
  a = 1,
  K = 1,
  gamma1 = NULL,
  n1 = NULL
) {
  force(a)

  if (!is.null(gamma1) && !is.null(n1)) {
    K <- n1^a * gamma1 / (gamma0 - gamma1)
  }

  b <- gamma0 * K

  function(n) b / (K + n^a)
}


logreg_sgd <- function(
    X,
    y,
    batch_size = 1,
    max_epochs = 100,
    gamma0 = NULL,
    loss_optim = 0,
    K = 5,
    a = 1) {
  loss <- double(max_epochs)

  n <- nrow(X)
  p <- ncol(X)
  it <- 0

  if (is.null(gamma0)) {
    L <- 0.25 * norm(crossprod(X), "2") / n
    learning_rate <- 1 / L
  } else {
    learning_rate <- gamma0
  }

  scheduler <- decay_scheduler(gamma0 = learning_rate, K = K, a = a)

  full_batch <- n == batch_size

  # Initialize the coefficients
  beta <- double(p)
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

      # Compute the predictions
      z <- X_batch %*% beta
      p_hat <- 1 / (1 + exp(-z))

      # Compute the gradient
      gradient <- crossprod(X_batch, p_hat - y_batch) / batch_size

      # Update the coefficients
      beta <- beta - learning_rate * gradient
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
