library(tidyverse)
library(patchwork)

library(mvtnorm)

source("R/sgd.R")

set.seed(123)

n <- 1000
p <- 2
Sigma <- matrix(c(1, 0.8, 0.8, 1), nrow = 2)
mu <- c(0, 0)

X <- rmvnorm(n, mean = mu, sigma = Sigma)
beta <- c(1, 2)
y <- rbinom(n, 1, plogis(X %*% beta))

res_glm <- glm.fit(X, y, family = binomial())

loss_2d <- function(beta1, beta2, X, y) {
  beta <- c(beta1, beta2)
  z <- X %*% beta
  p_hat <- 1 / (1 + exp(-z))
  -mean(y * log(p_hat) + (1 - y) * log(1 - p_hat))
}

beta1 <- seq(-1, 3, length = 100)
beta2 <- seq(-1, 3, length = 100)

loss_2d_vectorized <- Vectorize(function(b1, b2) loss_2d(b1, b2, X, y))

z <- outer(beta1, beta2, loss_2d_vectorized)

for (a in c(0.5, 1)) {
  res_sgd <- logreg_sgd(X, y, max_epochs = 100, batch_size = 1, a = a, gamma0 = 0.5)

  pal <- palette.colors(palette = "Okabe-Ito")

  type <- if (a == 0.5) "slow" else "fast"

  fn <- paste0("images/lecture12-lrdecay-", type, ".png")
  png(fn, width = 2.6, height = 2.9, res = 192, units = "in", pointsize = 8)
  contour(beta1, beta2, z, col = "dark grey", drawlabels = FALSE, asp = 1)

  lines(
    res_sgd$beta_history[1, ],
    res_sgd$beta_history[2, ],
    col = pal[3]
  )
  points(
    res_sgd$beta_history[1, ],
    res_sgd$beta_history[2, ],
    col = pal[3],
    pch = 19,
    cex = 0.5
  )

  points(
    res_glm$coefficients[1],
    res_glm$coefficients[2],
    col = pal[2],
    pch = 19,
    cex = 1
  )
  dev.off()
  knitr::plot_crop(fn)
}
