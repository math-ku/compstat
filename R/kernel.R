kern_dens <- function(x, h, m = 512) {
  rg <- range(x)
  grid_points <- seq(rg[1] - 3 * h, rg[2] + 3 * h, length.out = m)
  y <- numeric(m)
  for (i in seq_along(grid_points)) {
    for (j in seq_along(x)) {
      y[i] <- y[i] + exp(-(grid_points[i] - x[j])^2 / (2 * h^2))
    }
  }
  y <- y / (sqrt(2 * pi) * h * length(x))
  list(x = grid_points, y = y)
}

kern_dens_detail <- function(x, h, m = 512) {
  rg <- range(x)
  grid_points <- seq(rg[1] - 3 * h, rg[2] + 3 * h, length.out = m)
  y <- numeric(m)
  for (i in seq_along(grid_points)) {
    for (j in seq_along(x)) {
      ## y[i] <- y[i] + exp(- (xx[i] - x[j])^2 / (2 * h^2))
      z <- grid_points[i] - x[j]
      z <- z^2
      z <- z / (2 * h^2)
      z <- exp(-z)
      y[i] <- y[i] + z
    }
  }
  y <- y / (sqrt(2 * pi) * h * length(x))
  list(x = grid_points, y = y)
}

kern_dens_vec <- function(x, h, m = 512) {
  rg <- range(x)
  grid_points <- seq(rg[1] - 3 * h, rg[2] + 3 * h, length.out = m)
  y <- numeric(m)
  const <- (sqrt(2 * pi) * h * length(x))
  for (i in seq_along(grid_points)) {
    y[i] <- sum(exp(-(grid_points[i] - x)^2 / (2 * h^2))) / const
  }
  list(x = grid_points, y = y)
}

## Binning is done by constructing an equidistant grid of centers from
## lo to hi with a distance delta between each center, that is
##     lo, lo + delta, lo + 2 delta, ..., lo + (m - 1) delta = hi
## There are m centers in this sequence. A convenient technique for finding
## the correct bin for x[i] is via floor, which below will give j if and only if
## lo + (j - 0.5) delta <= x[i] < lo + (j + 0.5) delta


kern_bin <- function(x, lo, hi, m) {
  w <- numeric(m)
  delta <- (hi - lo) / (m - 1)
  for (j in seq_along(x)) {
    i <- floor((x[j] - lo) / delta + 0.5) + 1
    w[i] <- w[i] + 1
  }
  w / sum(w)
}

## This implementation assumes a symmetric kernel!
## It's possible to avoid the symmetry assumption,
## but it's a little more complicated.

kern_dens_bin <- function(x, h, m = 512) {
  rg <- range(x) + c(-3 * h, 3 * h)
  xx <- seq(rg[1], rg[2], length.out = m)
  weights <- kern_bin(x, rg[1], rg[2], m)
  kerneval <- exp(-(xx - xx[1])^2 / (2 * h^2)) / (sqrt(2 * pi) * h)
  kerndif <- toeplitz(kerneval)
  y <- colSums(weights * kerndif)
  list(x = xx, y = y, h = h)
}
