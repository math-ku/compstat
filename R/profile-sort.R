profile_sort <- function(n = 5e6) {
  x <- runif(n)
  y <- sqrt(x)
  z <- sort(y)
  sum(z)
}
