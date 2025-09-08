kern_dens <- function(x, h, m = 512) {
  rg <- range(x)
  xx <- seq(rg[1] - 3 * h, rg[2] + 3 * h, length.out = m)
  y <- numeric(m)

  for (i in seq_along(xx)) {
    for (j in seq_along(x)) {
      y[i] <- y[i] + exp(-(xx[i] - x[j])^2 / (2 * h^2))
    }
  }

  y <- y / (sqrt(2 * pi) * h * length(x))

  list(x = xx, y = y)
}

kern_dens_vec <- function(x, h, m = 512) {
  rg <- range(x)
  xx <- seq(rg[1] - 3 * h, rg[2] + 3 * h, length.out = m)
  y <- numeric(m)

  for (i in seq_along(xx)) {
    y[i] <- sum(exp(-(xx[i] - x)^2 / (2 * h^2)))
  }

  y <- y / (sqrt(2 * pi) * h * length(x))

  list(x = xx, y = y)
}

kern_bin <- function(x, l, u, B) {
  w <- numeric(B)
  delta <- (u - l) / (B - 1)
  for (j in seq_along(x)) {
    i <- floor((x[j] - l) / delta + 0.5) + 1
    w[i] <- w[i] + 1
  }
  w / sum(w)
}

kern_dens_bin <- function(x, h, m = 512) {
  rg <- range(x) + c(-3 * h, 3 * h)
  xx <- seq(rg[1], rg[2], length.out = m)
  weights <- kern_bin(x, rg[1], rg[2], m)
  kerneval <- exp(-(xx - xx[1])^2 / (2 * h^2)) / (sqrt(2 * pi) * h)
  kerndif <- toeplitz(kerneval)
  y <- colSums(weights * kerndif)
  list(x = xx, y = y, h = h)
}
