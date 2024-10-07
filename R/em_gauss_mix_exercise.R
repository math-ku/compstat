library(numDeriv)

# The negative log-likelihood function
neg_loglik <- function(par, x) {
  p <- par[1]
  if (p < 0 || p > 1) {
    return(Inf)
  }

  mu1 <- par[2]
  mu2 <- par[3]
  -sum(log(p * exp(-(x - mu1)^2 / (2 * sigma1^2)) / sigma1 +
    (1 - p) * exp(-(x - mu2)^2 / (2 * sigma2^2)) / sigma2))
}

# The EM function factory for Gaussian mixtures
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

# Simulation
sigma1 <- 1.5
sigma2 <- 1.5 # Note, same variances

p <- 0.5
mu1 <- -0.5
mu2 <- 4

n <- 5000
set.seed(321)
z <- sample(c(TRUE, FALSE), n, replace = TRUE, prob = c(p, 1 - p))

# Conditional simulation from the mixture components
x <- numeric(n)
n1 <- sum(z)
x[z] <- rnorm(n1, mu1, sigma1)
x[!z] <- rnorm(n - n1, mu2, sigma2)
EM <- EM_gauss_mix(x)

# Gradients
Q <- function(par, par_prime, EStep) {
  phat <- EStep(par_prime)
  p <- par[1]
  mu1 <- par[2]
  mu2 <- par[3]
  sum(phat * (log(p) - (x - mu1)^2 / (2 * sigma1^2)) +
    (1 - phat) * (log(1 - p) - (x - mu2)^2 / (2 * sigma2^2)))
}

grad1 <- function(par) grad(function(par) -neg_loglik(par, x), par)
grad2 <- function(par) {
  grad(Q, par, par_prime = par, EStep = environment(EM)$EStep)
}
