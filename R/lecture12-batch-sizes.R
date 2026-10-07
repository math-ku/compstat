logreg_batches_r <- function(X, y, indices, rates) {
  beta <- numeric(ncol(X))
  batch_size <- nrow(indices)

  for (k in seq_len(ncol(indices))) {
    ind <- indices[, k]
    X_batch <- X[ind, , drop = FALSE]
    residual <- plogis(drop(X_batch %*% beta)) - y[ind]
    gradient <- drop(crossprod(X_batch, residual)) / batch_size
    beta <- beta - rates[k] * gradient
  }

  beta
}

logreg_batch_problem <- function(batch_size, epochs = 25L) {
  n <- 1000L
  stopifnot(batch_size > 0, n %% batch_size == 0, epochs > 0)
  set.seed(123)
  Sigma <- matrix(c(1, 0.8, 0.8, 1), nrow = 2)
  X <- mvtnorm::rmvnorm(n, sigma = Sigma)
  y <- rbinom(n, 1, plogis(drop(X %*% c(1, 2))))
  updates <- epochs * n / batch_size

  # Share sampled batches so language differences cannot change the update path.
  indices <- matrix(
    replicate(updates, sample.int(n, batch_size)),
    nrow = batch_size
  )
  rates <- if (batch_size == n) {
    rep(3, updates)
  } else {
    3 * 5 / (5 + seq_len(updates))
  }

  list(X = X, y = y, indices = indices, rates = rates)
}

benchmark_logreg_batches <- function() {
  results <- lapply(
    c(1L, 10L, 100L, 1000L),
    function(batch_size) {
      problem <- logreg_batch_problem(batch_size)
      X <- problem$X
      y <- problem$y
      indices <- problem$indices
      rates <- problem$rates

      timings <- bench::mark(
        R = logreg_batches_r(X, y, indices, rates),
        Cpp = logreg_batches_cpp(X, y, indices, rates),
        iterations = 10,
        check = TRUE
      )

      data.frame(
        batch_size = batch_size,
        language = c("R", "C++"),
        milliseconds = 1000 * as.numeric(timings$median)
      )
    }
  )

  do.call(rbind, results)
}
