pch <- 19
cex <- 1

f <- function(x) 0.1 * x^4 - 0.25 * x^3 - 0.7 * x^2

g <- function(x) 0.4 * x^3 - 0.75 * x^2 - 1.4 * x

alpha <- 0.05

basename <- here::here("images", "escape-minima")

# Use the book convention while preserving the heavy-ball trajectories.
for (beta_mom in c(0, 0.8)) {
  x <- x0 <- -3
  rho <- 0
  gamma <- alpha / (1 - beta_mom)
  maxit <- 10
  x_hist <- double(maxit)
  for (k in 1:maxit) {
    x_hist[k] <- x
    rho <- beta_mom * rho + (1 - beta_mom) * g(x)
    x <- x - gamma * rho

    type <- if (beta_mom == 0) "gd" else "mom"

    fn <- paste0(basename, "-", type, "-", k - 1, ".pdf")
    pdf(fn, width = 2.7, height = 2.9, pointsize = 7)
    curve(
      f(x),
      -3.2,
      4.3,
      xlab = expression(theta),
      ylab = expression(H(theta))
    )
    points(
      x_hist[1:k],
      f(x_hist[1:k]),
      pch = pch,
      cex = cex,
      col = "steelblue4"
    )
    dev.off()
    knitr::plot_crop(fn)
  }
}
