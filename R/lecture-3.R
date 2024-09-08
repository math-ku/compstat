gauss <- function(x, h = 1) {
  exp(-x^2 / (2 * h^2)) / (h * sqrt(2 * pi))
}

gauss_step <- function(x, h = 1) {
  exponent <- x^2 / (2 * h^2)
  numerator <- exp(-exponent)
  denominator <- h * sqrt(2 * pi)
  numerator / denominator
}

kern_dens <- function(x, h, m = 512) {
  rg <- range(x)
  xx <- seq(rg[1] - 3 * h, rg[2] + 3 * h, length.out = m)
  y <- numeric(m)
  for (i in seq_along(xx)) {
    for (j in seq_along(x)) {
      y[i] <- y[i] + gauss_step(xx[i] - x[j], h)
    }
  }
  list(x = xx, y = y)
}

# Test

c(gauss(1), gauss_step(1))
c(gauss(0.1, 0.1), gauss_step(0.1, 0.1))
