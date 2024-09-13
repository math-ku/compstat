vMsim_vec_ran <- function(m, kappa) {
  y <- runif(m, - pi, pi)
  u <- runif(m)
  accept <- u <= exp(kappa * (cos(y) - 1))
  y[accept] 
}

vec_sim <- function(generator) {
  j <- 1
  l <- 0  # The number of accepted samples
  alpha <- 1 
  y <- list()
  function(n, ...) {
    while(l < n) {
      m <- ceiling((n - l) / alpha)  
      y[[j]] <- generator(m, ...)
      l <- l + length(y[[j]])
      if (j == 1)
        alpha <<- (l + 1) / m  # Estimate of alpha
      j <- j + 1
    }
    unlist(y)[1:n]
  }
}

vMsim_vec <- vec_sim(vMsim_vec_ran)

f <- function(x, k) exp(k * cos(x)) / (2 * pi * besselI(k, 0))
x <- vMsim_vec(100000, 0.5)
hist(x, breaks = seq(-pi, pi, length.out = 20), prob = TRUE)
curve(f(x, 0.5), -pi, pi, col = "blue", lwd = 2, add = TRUE)
x <- vMsim_vec(100000, 2)
hist(x, breaks = seq(-pi, pi, length.out = 20), prob = TRUE)
curve(f(x, 2), -pi, pi, col = "blue", lwd = 2, add = TRUE)