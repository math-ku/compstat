kern_dens_vec <- function(x, h, m = 512) {
  rg <- range(x)
  xx <- seq(rg[1] - 3 * h, rg[2] + 3 * h, length.out = m)
  y <- numeric(m) 
  # The inner loop from 'kern_dens' has been vectorized, and only the 
  # outer loop over the grid points remains. 
  const <- (sqrt(2 * pi) * h * length(x))
  for (i in seq_along(xx))
    y[i] <- sum(exp(-(xx[i] - x)^2 / (2 * h^2))) / const
  list(x = xx, y = y)
}