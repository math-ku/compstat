library(tidyverse)
library(patchwork)

library(mvtnorm)

source("R/sgd.R")

theme_set(theme_bw(base_size = 10))

set.seed(123)

n <- 1000
p <- 2
Sigma <- matrix(c(1, 0.8, 0.8, 1), nrow = 2)
mu <- c(0, 0)

X <- rmvnorm(n, mean = mu, sigma = Sigma)
beta <- c(1, 2)
y <- rbinom(n, 1, plogis(X %*% beta))

res_glm <- glm.fit(X, y, family = binomial())
loss_optim <- loss_2d(res_glm$coefficients[1], res_glm$coefficients[2], X, y)

loss_2d <- function(beta1, beta2, X, y) {
  beta <- c(beta1, beta2)
  z <- X %*% beta
  p_hat <- 1 / (1 + exp(-z))
  -mean(y * log(p_hat) + (1 - y) * log(1 - p_hat))
}

conv_data <- data.frame(b = NULL, epoch = NULL, loss = NULL)

for (b in c(1, 10, 100, n)) {
  res_sgd <- logreg_sgd(X, y, max_epochs = 100, batch_size = b, a = 1, gamma0 = 3)

  conv_data <- rbind(
    conv_data,
    data.frame(b = b, epoch = seq_len(100), loss = res_sgd$loss - loss_optim)
  )
}

ggplot(conv_data, aes(epoch, loss, col = as.factor(b))) +
  geom_line() +
  scale_y_log10() +
  labs(color = "Batch size", y = "Suboptimality")

ggsave("images/lecture12-batch-sizes.png", width = 4, height = 2.7, dpi = 192)
