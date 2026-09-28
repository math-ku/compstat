em_coins <- function(heads, theta = c(0.6, 0.5), maxit = 20L) {
  theta_hist <- matrix(NA_real_, nrow = maxit, ncol = 2)
  colnames(theta_hist) <- c("thetaA", "thetaB")
  loglik <- numeric(maxit)

  for (t in seq_len(maxit)) {
    theta_hist[t, ] <- theta
    pA <- dbinom(heads, 10, theta[1])
    pB <- dbinom(heads, 10, theta[2])
    loglik[t] <- sum(log(0.5 * pA + 0.5 * pB))
    if (t == maxit) {
      break
    }
    gamma <- pA / (pA + pB)
    theta[1] <- sum(gamma * heads) / (10 * sum(gamma))
    theta[2] <- sum((1 - gamma) * heads) / (10 * sum(1 - gamma))
  }

  list(theta = theta_hist, loglik = loglik)
}

em_coins_counts <- function(
  heads,
  theta = c(0.6, 0.5),
  maxit = 20L
) {
  counts <- tabulate(heads + 1L, nbins = 11L)
  # Empty categories contribute nothing and could otherwise produce 0 * log(0).
  occupied <- counts > 0
  k <- (0:10)[occupied]
  counts <- counts[occupied]
  theta_hist <- matrix(NA_real_, nrow = maxit, ncol = 2)
  colnames(theta_hist) <- c("thetaA", "thetaB")
  loglik <- numeric(maxit)

  for (t in seq_len(maxit)) {
    theta_hist[t, ] <- theta
    pA <- dbinom(k, 10, theta[1])
    pB <- dbinom(k, 10, theta[2])
    loglik[t] <- sum(counts * log(0.5 * pA + 0.5 * pB))
    if (t == maxit) {
      break
    }
    gamma <- pA / (pA + pB)
    theta[1] <- sum(counts * gamma * k) /
      (10 * sum(counts * gamma))
    theta[2] <- sum(counts * (1 - gamma) * k) /
      (10 * sum(counts * (1 - gamma)))
  }

  list(theta = theta_hist, loglik = loglik)
}
