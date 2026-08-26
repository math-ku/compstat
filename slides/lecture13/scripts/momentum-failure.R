pch <- 19
cex <- 1

f <- function(x) {
  ifelse(
    x < 1,
    12.5 * x^2,
    ifelse(1 <= x & x < 2, 0.5 * x^2 + 24 * x - 12, 12.5 * x^2 - 24 * x + 36)
  )
}

g <- function(x) {
  ifelse(x < 1, 25 * x, ifelse(1 <= x & x < 2, x + 24, 25 * x - 24))
}

alpha <- 1 / 9
beta_mom <- 4 / 9
gamma <- alpha / (1 - beta_mom)

col <- rgb(0, 0, 0, alpha = 0.2)

maxit <- 100

x0 <- 3.2
x_hist <- double(maxit)
x_hist[1] <- x0
rho <- 0

for (k in 2:maxit) {
  gradient <- g(x_hist[k - 1])
  rho <- beta_mom * rho + (1 - beta_mom) * gradient
  x_hist[k] <- x_hist[k - 1] - gamma * rho
}

fn <- here::here("images", "momentum-failure.pdf")

pdf(fn, width = 2.7, height = 2.9, pointsize = 7)

curve(f(x), -3, 4, xlab = expression(theta), ylab = expression(H(theta)))
lines(x_hist[1:maxit], f(x_hist[1:maxit]), pch = pch, cex = cex, col = col)
points(x_hist[1:maxit], f(x_hist[1:maxit]), pch = pch, cex = cex, col = col)

dev.off()
knitr::plot_crop(fn)
