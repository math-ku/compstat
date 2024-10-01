EM_gauss_mix <- function(x) {
  n <- length(x)

  EStep <- function(par) {
    p <- par[1]
    mu1 <- par[2]
    mu2 <- par[3]
    a <- p * exp(-(x - mu1)^2 / (2 * sigma1^2)) / sigma1
    b <- (1 - p) * exp(-(x - mu2)^2 / (2 * sigma2^2)) / sigma2
    a / (a + b)
  }

  MStep <- function(p_hat) {
    N1 <- sum(p_hat)
    N2 <- n - N1
    c(N1 / n, sum(p_hat * x) / N1, sum((1 - p_hat) * x) / N2)
  }

  function(par, epsilon = 1e-12, maxit = 50, cb = NULL) {
    for (i in 1:maxit) {
      par0 <- par
      par <- MStep(EStep(par))
      if (!is.null(cb)) cb()
      if (sum((par - par0)^2) <= epsilon * (sum(par^2) + epsilon)) break
    }
    par
  }
}
