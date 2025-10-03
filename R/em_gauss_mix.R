e_step_gauss <- function(par, x, sigma1 = 1, sigma2 = sigma1) {
  p <- par[1]
  mu1 <- par[2]
  mu2 <- par[3]
  a <- p * exp(-(x - mu1)^2 / (2 * sigma1^2)) / sigma1
  b <- (1 - p) * exp(-(x - mu2)^2 / (2 * sigma2^2)) / sigma2
  a / (a + b)
}

m_step_gauss <- function(p_hat, x) {
  n <- length(x)
  N1 <- sum(p_hat)
  N2 <- n - N1
  c(N1 / n, sum(p_hat * x) / N1, sum((1 - p_hat) * x) / N2)
}

EM_gauss_mix_step <- function(x, sigma1 = 1, sigma2 = sigma1) {
  force(x)
  force(sigma1)
  force(sigma2)

  function(par) m_step_gauss(e_step_gauss(par, x, sigma1, sigma2), x)
}

em_gauss_step <- EM_gauss_mix_step(x, sigma1, sigma2)
