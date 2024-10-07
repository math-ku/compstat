# Implement the marginal model for the mixed model and solve it using `optim()`
set.seed(211)

beta0 <- 1
beta <- cbind(beta0)
nu <- 2
sigma <- 3

m <- 20
N <- 10
ni <- rep(N, m)
n <- sum(ni)

X <- cbind(rep(1, n))
Z <- Matrix::bdiag(lapply(ni, function(d) matrix(1, nrow = d, ncol = 1)))

u <- rnorm(m, 0, sqrt(nu))
mu <- X %*% beta + Z %*% u
y <- rnorm(n, as.vector(mu), sigma)
