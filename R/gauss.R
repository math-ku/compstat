gauss <- function(x, h = 1) {
  exp(-x^2 / (2 * h^2)) / (h * sqrt(2 * pi))
}

gauss_step <- function(x, h = 1) {
  exponent <- x^2 / (2 * h^2)
  numerator <- exp(-exponent)
  denominator <- h * sqrt(2 * pi)
  numerator / denominator
}
