rchisq2 <- function(n, k) {
  y <- numeric(n)
  for (i in 1:n) {
    x <- rnorm(k)
    y[i] <- sum(x^2)
  }
  y
}

