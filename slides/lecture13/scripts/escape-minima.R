pch <- 19
cex <- 1

f <- function(x) {
  0.1 * x^4 - 0.25 * x^3 - 0.7 * x^2
}

g <- function(x) {
  0.4 * x^3 - 0.75 * x^2 - 1.4 * x
}


gamma <- 0.05

basename <- here("images", "escape-minima")

# without momentum
for (mu in c(0, 0.8)) {
  x <- x0 <- -3
  maxit <- 10
  x_hist <- double(maxit)
  for (k in 1:maxit) {
    x_hist[k] <- x
    x <- x - gamma * g(x) + mu * (x_hist[k] - x0)
    x0 <- x_hist[k]

    type <- if (mu == 0) "gd" else "mom"

    fn <- paste0(basename, "-", type, "-", k - 1, ".pdf")
    pdf(fn, width = 2.7, height = 2.9, pointsize = 7)
    curve(f(x), -3.2, 4.3)
    points(x_hist[1:k], f(x_hist[1:k]), pch = pch, cex = cex, col = "steelblue4")
    dev.off()
    knitr::plot_crop(fn)
  }
}

# # with momentum
# curve(f(x), -3.2, 4.3, add = FALSE)
#
# x <- x0
#
# mu <- 0.8
#
# # without momentum
# for (k in 1:maxit) {
#   x_hist[k] <- x
#   x <- x - gamma * g(x) + mu * (x_hist[k] - x0)
#   x0 <- x_hist[k]
# }
#
# points(x_hist, f(x_hist), pch = pch, cex = cex)
