set.seed(1)

n <- 1000
x <- rnorm(n)
y <- rpois(n, exp(x))
X <- model.matrix(y ~ x)

Xty <- drop(crossprod(X, y))

objective <- function(beta) {
  (sum(exp(X %*% beta)) - beta %*% Xty) / nrow(X)
}

gradient <- function(beta) {
  (colSums(drop(exp(X %*% beta)) * X) - Xty) / nrow(X)
}

hessian <- function(beta) {
  (crossprod(X, drop(exp(X %*% beta)) * X)) / nrow(X)
}

newton_method(c(0, 0), objective, gradient, hessian)

glm(y ~ x, family = "poisson")
