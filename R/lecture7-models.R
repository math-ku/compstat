ols_objective <- function(beta, x, y) {
  0.5 * norm(y - x %*% beta, "2")^2
}

ols_gradient <- function(beta, x, y) {
  crossprod(x, x %*% beta - y)
}

ols_gd_model <- function(beta, beta0, x, y, t) {
  ols_objective(beta0, x, y) +
    t(ols_gradient(beta0, x, y)) %*% (beta - beta0) +
    (1 / (2 * t)) * sum((beta - beta0)^2)
}

ols_newton_model <- function(beta, beta0, x, y) {
  H <- crossprod(x)
  ols_objective(beta0, x, y) +
    t(ols_gradient(beta0, x, y)) %*% (beta - beta0) +
    0.5 * t(beta - beta0) %*% H %*% (beta - beta0)
}

nonquadratic_objective <- function(theta) {
  pmax(theta, 0) + log1p(exp(-abs(theta))) + 0.5 * (theta - 2)^2
}

nonquadratic_gradient <- function(theta) {
  plogis(theta) + theta - 2
}

nonquadratic_hessian <- function(theta) {
  1 + plogis(theta) * (1 - plogis(theta))
}

nonquadratic_model <- function(theta, theta0) {
  nonquadratic_objective(theta0) +
    nonquadratic_gradient(theta0) * (theta - theta0) +
    0.5 * nonquadratic_hessian(theta0) * (theta - theta0)^2
}
