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

logreg_batch_problem <- function(
  batch_size,
  epochs = 25L,
  t0 = 3,
  seed = NULL
) {
  n <- 1000L
  stopifnot(batch_size > 0, n %% batch_size == 0, epochs > 0)
  set.seed(123)
  Sigma <- matrix(c(1, 0.8, 0.8, 1), nrow = 2)
  X <- mvtnorm::rmvnorm(n, sigma = Sigma)
  y <- rbinom(n, 1, plogis(drop(X %*% c(1, 2))))
  updates <- epochs * n / batch_size

  if (!is.null(seed)) {
    set.seed(seed)
  }
  # Share sampled batches so language differences cannot change the update path.
  indices <- matrix(
    replicate(updates, sample.int(n, batch_size)),
    nrow = batch_size
  )
  rates <- if (batch_size == n) {
    rep(t0, updates)
  } else {
    t0 * 5 / (5 + seq_len(updates))
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

logreg_batches_path_r <- function(
  X,
  y,
  indices,
  rates,
  updates_per_epoch
) {
  epochs <- ncol(indices) / updates_per_epoch
  beta <- numeric(ncol(X))
  batch_size <- nrow(indices)
  loss <- numeric(epochs + 1L)
  elapsed <- numeric(epochs + 1L)
  evaluate_loss <- function(beta) {
    eta <- drop(X %*% beta)
    mean(pmax(eta, 0) - y * eta + log1p(exp(-abs(eta))))
  }
  loss[1] <- evaluate_loss(beta)
  start <- as.numeric(Sys.time())

  for (k in seq_len(ncol(indices))) {
    ind <- indices[, k]
    X_batch <- X[ind, , drop = FALSE]
    residual <- plogis(drop(X_batch %*% beta)) - y[ind]
    gradient <- drop(crossprod(X_batch, residual)) / batch_size
    beta <- beta - rates[k] * gradient
    if (k %% updates_per_epoch == 0) {
      epoch <- k / updates_per_epoch
      loss[epoch + 1L] <- evaluate_loss(beta)
      elapsed[epoch + 1L] <- as.numeric(Sys.time()) - start
    }
  }

  list(coefficients = beta, loss = loss, elapsed = elapsed)
}

logreg_batch_path <- function(
  batch_size,
  t0,
  seed,
  epochs = 25L,
  language = c("C++", "R")
) {
  language <- match.arg(language)
  problem <- logreg_batch_problem(batch_size, epochs, t0, seed)
  implementation <- if (language == "C++") {
    logreg_batches_path_cpp
  } else {
    logreg_batches_path_r
  }
  result <- do.call(
    implementation,
    c(
      problem,
      list(updates_per_epoch = nrow(problem$X) / batch_size)
    )
  )
  data.frame(
    epoch = 0:epochs,
    loss = result$loss,
    seconds = result$elapsed
  )
}

logreg_batch_convergence <- function() {
  problem <- logreg_batch_problem(1000L)
  X <- problem$X
  y <- problem$y
  optimum <- glm.fit(X, y, family = binomial())$coefficients
  eta <- drop(X %*% optimum)
  minimum <- mean(pmax(eta, 0) - y * eta + log1p(exp(-abs(eta))))
  batch_sizes <- c(1L, 10L, 100L, 1000L)
  rate_grid <- c(0.3, 1, 3, 5, 10, 15)

  best_rates <- vapply(
    batch_sizes,
    function(size) {
      scores <- vapply(
        rate_grid,
        function(rate) {
          gaps <- vapply(
            101:103,
            function(seed) {
              tail(logreg_batch_path(size, rate, seed)$loss, 1) -
                minimum
            },
            numeric(1)
          )
          mean(pmax(gaps, 0))
        },
        numeric(1)
      )
      rate_grid[which.min(scores)]
    },
    numeric(1)
  )

  paths <- lapply(seq_along(batch_sizes), function(i) {
    implementations <- lapply(c("R", "C++"), function(language) {
      runs <- lapply(201:205, function(seed) {
        path <- logreg_batch_path(
          batch_sizes[i],
          best_rates[i],
          seed,
          language = language
        )
        path$batch_size <- batch_sizes[i]
        path$language <- language
        path$gap <- pmax(path$loss - minimum, 1e-10)
        path
      })
      do.call(rbind, runs)
    })
    do.call(rbind, implementations)
  })

  data <- do.call(rbind, paths) |>
    dplyr::group_by(language, batch_size, epoch) |>
    dplyr::summarize(
      milliseconds = 1000 * median(seconds),
      lower = quantile(gap, 0.25),
      upper = quantile(gap, 0.75),
      gap = median(gap),
      .groups = "drop"
    )
  data$batch <- factor(
    data$batch_size,
    levels = batch_sizes,
    labels = paste0(
      c("1", "10", "100", "GD (1000)"),
      " [",
      best_rates,
      "]"
    )
  )
  data$language <- factor(data$language, levels = c("R", "C++"))
  data
}
