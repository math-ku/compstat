library(CSwR)
library(profvis)

max_Q <- function(xi, zeta, x, ni) {
  # t is hat{X}^T x, where hat{X} depends on xi
  t <- c(sum(x), sum(rep(xi, times = ni) * x))
  ni_xi <- sum(ni * xi)
  S_hat <- matrix(
    c(
      sum(ni), ni_xi,
      ni_xi, sum(ni * zeta)
    ),
    ncol = 2,
    nrow = 2
  )
  hat <- solve(S_hat, t)
  sigmasq_hat <- (sum(x^2) - sum(t * hat)) / sum(ni)
  c(hat, sigmasq_hat)
}


beta0 <- 1
nu <- 5
sigma <- 1

m <- 20
ni <- rep(10, m)
n <- sum(ni)

cond_exp <- function(par, x, A, AAt) {
  beta0 <- par[1]
  nu <- par[2]
  sigmasq <- par[3]
  m <- ncol(A)
  n <- nrow(A)
  Sigma <- nu^2 * AAt + diag(sigmasq, n)
  xi <- nu * drop(t(A) %*% solve(Sigma, x - beta0))
  zeta <- 1 - nu^2 * diag(t(A) %*% solve(Sigma, A)) + xi^2
  list(xi = xi, zeta = zeta)
}


EM_mixed <- function(x, ni) {
  force(x)

  A <- as.matrix(Matrix::bdiag(lapply(ni, function(d) matrix(1, nrow = d, ncol = 1))))
  AAt <- A %*% t(A)

  EStep <- function(par) {
    cond_exp(par, x, A, AAt)
  }

  MStep <- function(zz) {
    max_Q(zz$xi, zz$zeta, x, ni)
  }

  EM <- function(par, epsilon = 1e-10, cb = NULL, maxit = 1e4) {
    for (i in 1:maxit) {
      par0 <- par
      E_update <- EStep(par)
      par <- MStep(E_update)
      if (!is.null(cb)) cb()
      if (sum((par - par0)^2) <= epsilon * (sum(par^2) + epsilon)) {
        break
      }
    }
    par
  }
}


EM <- EM_mixed(x, ni)
EM(c(0, 4, 1))

# profvis(EM(c(0, 4, 1)))
