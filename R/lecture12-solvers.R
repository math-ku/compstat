library(tidyverse)
library(patchwork)

theme_set(theme_bw(base_size = 10))

decay_scheduler <- function(
    gamma0 = 1,
    a = 1,
    K = 1,
    gamma1,
    n1) {
  force(a)

  if (!missing(gamma1) && !missing(n1)) {
    K <- n1^a * gamma1 /
      (gamma0 - gamma1)
  }

  b <- gamma0 * K

  function(n) b / (K + n^a)
}

logreg_sgd <- function(
    X,
    y,
    batch_size = 1,
    max_epochs = 100,
    learning_rate = 0.1,
    loss_optim = 0,
    K = 5,
    a = 1) {
  loss <- double(max_epochs)

  n <- nrow(X)
  p <- ncol(X)
  it <- 0

  L <- 0.25 * norm(crossprod(X), "2") / n
  learning_rate <- 1 / L

  scheduler <- decay_scheduler(gamma0 = learning_rate, K = K, a = a)

  full_batch <- n == batch_size

  # Initialize the coefficients
  beta <- double(p)
  beta_history <- matrix(
    NA,
    nrow = p,
    ncol = max_epochs * ceiling(n / batch_size)
  )

  for (epoch in seq_len(max_epochs)) {
    n_seen <- 0
    while (n_seen < n) {
      it <- it + 1
      beta_history[, it] <- beta
      n_seen <- n_seen + batch_size

      if (!full_batch) {
        learning_rate <- scheduler(it)
      }

      ind <- sample(n, size = batch_size)

      X_batch <- X[ind, , drop = FALSE]
      y_batch <- y[ind]

      # Compute the predictions
      z <- X_batch %*% beta
      p_hat <- 1 / (1 + exp(-z))

      # Compute the gradient
      gradient <- crossprod(X_batch, p_hat - y_batch) / batch_size

      # Update the coefficients
      beta <- beta - learning_rate * gradient
    }

    # Compute the loss for the current iteration
    z <- X %*% beta
    p_hat <- 1 / (1 + exp(-z))
    loss[epoch] <- -mean(y * log(p_hat) + (1 - y) * log(1 - p_hat))

    if (loss[epoch] - loss_optim < 1e-6 * loss_optim) {
      break
    }
  }

  list(coefficients = beta, loss = loss, beta_history = beta_history)
}

library(mvtnorm)

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

res_sgd <- logreg_sgd(X, y, max_epochs = 100, batch_size = 1)
res_sgd2 <- logreg_sgd(X, y, max_epochs = 100, batch_size = 1, K = 5, a = 0.5)
res_gd <- logreg_sgd(X, y, max_epochs = 100, batch_size = n)

pal <- palette.colors(palette = "Okabe-Ito")

fn <- "images/lecture12-gd-vs-sgd.png"
png(fn, width = 2.8, height = 3.2, res = 192, units = "in", pointsize = 8)
contour(beta1, beta2, z, col = "dark grey", drawlabels = FALSE)

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

lines(
  res_gd$beta_history[1, ],
  res_gd$beta_history[2, ],
  col = pal[1]
)
points(
  res_gd$beta_history[1, ],
  res_gd$beta_history[2, ],
  col = pal[1],
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

legend(
  "bottomright",
  legend = c("SGD", "GD"),
  col = pal[c(3, 1)],
  pch = 19,
  cex = 0.8
)

dev.off()
knitr::plot_crop(fn)

loss_optim <- loss_2d(res_glm$coefficients[1], res_glm$coefficients[2], X, y)
loss1 <- loss_2d_vectorized(res_gd$beta_history[1, ], res_gd$beta_history[2, ])
loss2 <- loss_2d_vectorized(res_sgd$beta_history[1, ], res_sgd$beta_history[2, ])
loss3 <- loss_2d_vectorized(res_sgd2$beta_history[1, ], res_sgd2$beta_history[2, ])

n1 <- length(loss1)
n2 <- length(loss2)
n3 <- length(loss3)

conv_data <- tibble(
  method = rep(c("GD", "SGD"), times = c(length(loss1), length(loss2))),
  epoch = c(seq_len(n1), seq_len(n2) / n),
  loss = c(loss1 - loss_optim, loss2 - loss_optim),
  iteration = c(seq_len(n1), seq_len(n2))
)

epochs_plot <- ggplot(conv_data, aes(epoch, loss, col = method)) +
  geom_line() +
  scale_y_log10() +
  labs(y = "Suboptimality", color = NULL)

iteration_plot <- ggplot(conv_data, aes(iteration, loss, col = method)) +
  geom_line() +
  scale_y_log10() +
  labs(y = "Suboptimality", color = NULL)

ggpl <- epochs_plot + iteration_plot + plot_layout(axes = "collect_y", guides = "collect")

ggsave("images/lecture12-gd-sgd-convergence1.png", ggpl, width = 6, height = 3.5, dpi = 192)

conv_data2 <- tibble(
  method = rep(c("GD", "SGD"), times = c(length(loss1), length(loss3))),
  epoch = c(seq_len(n1), seq_len(n3) / n),
  loss = c(loss1 - loss_optim, loss3 - loss_optim),
  iteration = c(seq_len(n1), seq_len(n3))
)

epochs_plot <- ggplot(conv_data2, aes(epoch, loss, col = method)) +
  geom_line() +
  scale_y_log10() +
  labs(y = "Suboptimality", color = NULL)

iteration_plot <- ggplot(conv_data2, aes(iteration, loss, col = method)) +
  geom_line() +
  scale_y_log10() +
  labs(y = "Suboptimality", color = NULL)

ggpl2 <- epochs_plot + iteration_plot + plot_layout(axes = "collect_y", guides = "collect")
ggsave("images/lecture12-gd-sgd-convergence2.png", ggpl2, width = 6, height = 3.5, dpi = 192)
