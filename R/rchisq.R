my_rchisq <- function(n, k) {
  y <- numeric(n)
  for (i in seq_len(n)) {
    x <- rnorm(k)
    y[i] <- sum(x^2)
  }
  y
}
