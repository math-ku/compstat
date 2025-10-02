library(ggplot2)

# Set seed for reproducibility
set.seed(123)

# Generate synthetic data
n <- 300
mu1 <- -2
mu2 <- 3
sigma1 <- 0.5
sigma2 <- 1
pi1 <- 0.4
pi2 <- 0.6

data <- c(rnorm(n * pi1, mu1, sigma1), rnorm(n * pi2, mu2, sigma2))
data <- data.frame(x = data)

# Initialize parameters
mu1_est <- runif(1, min(data$x), max(data$x))
mu2_est <- runif(1, min(data$x), max(data$x))
sigma1_est <- runif(1, 0.1, 2)
sigma2_est <- runif(1, 0.1, 2)
pi1_est <- 0.5
pi2_est <- 0.5

# Define the E-step
e_step <- function(data, mu1, mu2, sigma1, sigma2, pi1, pi2) {
  gamma1 <- pi1 * dnorm(data$x, mu1, sigma1)
  gamma2 <- pi2 * dnorm(data$x, mu2, sigma2)
  gamma_sum <- gamma1 + gamma2
  gamma1 <- gamma1 / gamma_sum
  gamma2 <- gamma2 / gamma_sum
  list(gamma1 = gamma1, gamma2 = gamma2)
}

# Define the M-step
m_step <- function(data, gamma1, gamma2) {
  n1 <- sum(gamma1)
  n2 <- sum(gamma2)
  mu1 <- sum(gamma1 * data$x) / n1
  mu2 <- sum(gamma2 * data$x) / n2
  sigma1 <- sqrt(sum(gamma1 * (data$x - mu1)^2) / n1)
  sigma2 <- sqrt(sum(gamma2 * (data$x - mu2)^2) / n2)
  pi1 <- n1 / length(data$x)
  pi2 <- n2 / length(data$x)
  list(mu1 = mu1, mu2 = mu2, sigma1 = sigma1, sigma2 = sigma2, pi1 = pi1, pi2 = pi2)
}

# Iterate the EM algorithm and plot the results
iterations <- 20
plots <- list()

for (i in 1:iterations) {
  # E-step
  gamma <- e_step(data, mu1_est, mu2_est, sigma1_est, sigma2_est, pi1_est, pi2_est)

  # M-step
  params <- m_step(data, gamma$gamma1, gamma$gamma2)
  mu1_est <- params$mu1
  mu2_est <- params$mu2
  sigma1_est <- params$sigma1
  sigma2_est <- params$sigma2
  pi1_est <- params$pi1
  pi2_est <- params$pi2

  # Plot the data and the current Gaussian distributions
  p <- ggplot(data, aes(x = x)) +
    geom_histogram(aes(y = ..density..), bins = 30, fill = "grey", alpha = 0.5) +
    stat_function(fun = function(x) pi1_est * dnorm(x, mu1_est, sigma1_est), color = "blue", size = 1) +
    stat_function(fun = function(x) pi2_est * dnorm(x, mu2_est, sigma2_est), color = "red", size = 1) +
    ggtitle(paste("Iteration", i)) +
    theme_minimal()

  plots[[i]] <- p
}

# Create an animation
# animation <- gganimate::animate(ggplot2::ggplot_build(plots), nframes = iterations, fps = 2)
# gganimate::anim_save("em_algorithm.gif", animation)
