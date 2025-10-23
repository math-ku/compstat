source(here::here("R", "gd.R"))

library(mvtnorm)

set.seed(622)

n <- 1000
p <- 100

X <- matrix(rnorm(n * p), n, p)
beta <- runif(p)
y <- rbinom(n, 1, plogis(X %*% beta))

res_glm <- glm.fit(X, y, family = binomial())

f <- function(beta, X, y) {
  z <- X %*% beta
  p_hat <- 1 / (1 + exp(-z))
  p_hat[p_hat < 1e-6] <- 1e-6
  p_hat[p_hat > 1 - 1e-6] <- 1 - 1e-6
  -mean(y * log(p_hat) + (1 - y) * log(1 - p_hat))
}

grad_f <- function(beta, X, y) {
  z <- X %*% beta
  p_hat <- 1 / (1 + exp(-z))
  crossprod(X, p_hat - y) / length(y)
}

beta0 <- double(p)
L <- 0.25 * norm(crossprod(X), "2") / n

maxit <- 500
res <- gd_general(beta0, f, grad_f, X = X, y = y, L = L, maxit = maxit)
res_nesterov <- gd_general(
  beta0,
  f,
  grad_f,
  X = X,
  y = y,
  L = L,
  type = "nesterov",
  maxit = maxit
)

coef(res_glm)
coef(res)
coef(res_nesterov)

optim <- min(res_nesterov$loss, 1) - 1e-10

k <- seq_along(res$loss)

fn <- here::here("images", "momentum-convergence.pdf")
pdf(fn, width = 2.7, height = 3.2, pointsize = 8)
plot(
  seq_along(res_nesterov$loss),
  res_nesterov$loss - optim,
  type = "l",
  log = "y",
  ylab = expression(f(x[k]) - f * "*"),
  xlab = "k",
  col = "steelblue4"
)
lines(seq_along(res$loss), res$loss - optim, type = "l", log = "y")
legend(
  "topright",
  c("GD", "Nesterov"),
  lty = 1,
  col = c(1, "steelblue4"),
  bg = "white"
)
dev.off()
knitr::plot_crop(fn)
