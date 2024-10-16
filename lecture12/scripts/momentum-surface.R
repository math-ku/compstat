source("lecture12/scripts/gd.R")

library(mvtnorm)

set.seed(622)

n <- 1000
Sigma <- matrix(c(1, 0.7, 0.7, 1), 2, 2)
mu <- c(0, 0)
X <- rmvnorm(n, mu, Sigma)
beta <- c(0.5, 1)
y <- X %*% beta + rnorm(n)

res <- gd(X, y)
xi <- 0.3
res_momentum <- gd(X, y, xi = xi)

plot_trajectory <- function(betas) {
  b1 <- betas[1, ]
  b2 <- betas[2, ]
  lines(b1, b2)
  points(b1, b2, cex = 0.5, pch = 19)
}

b1 <- seq(-0.3, 1.4, length.out = 100)
b2 <- seq(0, 1.6, length.out = 100)
f_vec <- Vectorize(function(b1, b2) 0.5 * norm(X %*% c(b1, b2) - y, "2")^2)
z <- outer(b1, b2, f_vec)

xis <- c(0, 0.4, 0.9)

fn <- "lecture12/images/momentum-surface.pdf"
pdf(fn, width = 5.5, height = 3.6, pointsize = 7)
opar <- par(no.readonly = TRUE)
par(
  mfrow = c(1, length(xis)),
  mai = c(1, 0, 1, 0.0),
  oma = c(0, 4, 0.1, 0.1),
  cex = 1
)
for (xi in xis) {
  res <- gd(X, y, xi = xi)
  first_plot <- xi == xis[1]
  contour(
    b1,
    b2,
    z,
    asp = 1,
    col = "dark grey",
    drawlabels = FALSE,
    axes = FALSE,
    frame.plot = TRUE,
    xlab = expression(beta[1])
  )
  axis(1)
  if (first_plot) {
    axis(2)
    mtext(expression(beta[2]), side = 2, line = 3, outer = TRUE)
  }
  plot_trajectory(res$betas)
  text(
    x = par("usr")[1] + 0.05 * diff(par("usr")[1:2]),
    y = par("usr")[4] - 0.07 * diff(par("usr")[3:4]),
    labels = bquote(xi == .(xi)),
    adj = 0
  )
}
par(opar)
dev.off()
knitr::plot_crop(fn)
