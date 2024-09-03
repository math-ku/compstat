## Additional kernel implementations


kern_dens_apply <- function (x, h, m = 512) {
  rg <- range(x)
  xx <- seq(rg[1] - 3 * h, rg[2] + 3 * h, length.out = m)
  y <- sapply(xx, function(z) sum(exp(-(z - x)^2 / (2 * h^2)) / (sqrt(2 * pi) * h * length(x))))
  list(x = xx, y = y)
}

kern_dens_outer <- function (x, h, m = 512) {
  rg <- range(x)
  xx <- seq(rg[1] - 3 * h, rg[2] + 3 * h, length.out = m)
  y <- outer(xx, x, function(zz, z) exp(-(zz - z)^2 / (2 * h^2)))
  y <- rowMeans(y) / (sqrt(2 * pi) * h)
  list(x = xx, y = y)
}

## And binning

kern_bin <- function(x, lo, hi, m) {
  w <- numeric(m)
  delta <- (hi - lo) / (m - 1)
  for(i in seq_along(x)) {
    ii <- floor((x[i] - lo) / delta + 0.5) + 1
    w[ii] <- w[ii] + 1
  }
  w / sum(w)
}

## This implementation assumes a symmetric kernel! 
## It's possible to avoid the symmetry assumption, 
## but it's a little more complicated.
kern_dens_bin_toep <- function(x, h, m = 512) {
  rg <- range(x) + c(- 3 * h, 3 * h)
  xx <- seq(rg[1], rg[2], length.out = m)
  weights <- kern_bin(x, rg[1], rg[2], m)
  kerneval <- exp(- (xx - xx[1])^2 / (2 * h^2)) / (sqrt(2 * pi) * h)
  kerndif <- matrix(kerneval[toeplitz(1:m)], m, m)
  y <- colSums(weights * kerndif)
  list(x = xx, y = y, h = h)
}

kern_dens_bin_conv <- function(x, h, m = 512) {
  rg <- range(x) + c(- 3 * h, 3 * h)
  xx <- seq(rg[1], rg[2], length.out = m)
  weights <- kern_bin(x, rg[1], rg[2], m)
  kerneval <- exp(- (xx - xx[1])^2 / (2 * h^2)) / (sqrt(2 * pi) * h)
  browser()
  y <- fft(fft(weights) * Conj(fft(c(kerneval, rev(kerneval)))), inverse = TRUE)
  list(x = xx, y = y, h = h)
}



