library(mvtnorm)
library(tikzDevice)

draw_canvas_bg <- function(col = "white") {
  rect(par("usr")[1], par("usr")[3],
      par("usr")[2], par("usr")[4],
      col = col)
}

set.seed(622)

p <- 2
n <- 1000
Sigma <- matrix(c(1, 0.7, 0.7, 1), 2, 2)
mu <- c(0, 0)
X <- rmvnorm(n, mu, Sigma)
beta <- c(0.5, 1)
y <- X %*% beta + rnorm(n)

plot_trajectory <- function(betas) {
  b1 <- betas[1, ]
  b2 <- betas[2, ]
  lines(b1, b2)
  points(b1, b2, cex = 0.5, pch = 19)
}

b1 <- seq(0.1, 0.6, length.out = 100)
b2 <- seq(1.05, 1.25, length.out = 100)
f_vec <- Vectorize(function(b1, b2) 0.5 * norm(X %*% c(b1, b2) - y, "2")^2)
f2 <- outer(b1, b2, f_vec)

L <- norm(crossprod(X), "2")

beta <- c(.2, 1.1)
n_it <- 4
gamma <- 1 / L
alpha <- gamma / 2

twostep_gd <- function(mu = 0, method = c("polyak", "nesterov")) {
  betas <- matrix(0, nrow = p, ncol = n_it)
  betas[, 1] <- beta
  betas[, 2] <- beta
  rs <- matrix(0, nrow = p, ncol = n_it)

  method <- match.arg(method)

  for (k in 2:(n_it - 1)) {
    rs[, k] <- betas[, k] + mu * (betas[, k] - betas[, k - 1])

    if (method == "polyak") {
      gradient <- crossprod(X, X %*% betas[, k] - y)
      betas[, k + 1] <- rs[, k] - gamma * gradient
    } else {
      gradient <- crossprod(X, X %*% rs[, k] - y)
      if (k < 3) {
        alpha <- gamma
      } else {
        alpha <- gamma * 0.8
      }
      betas[, k + 1] <- rs[, k] - alpha * gradient
    }
  }

  list(beta = betas, r = rs)
}

mu <- 0.6

res <- twostep_gd()
rm <- twostep_gd(mu)
rn <- twostep_gd(mu, method = "nesterov")

fn <- "images/momentum-illustration.pdf"
pdf(fn, width = 5.4, height = 3.1, pointsize = 7)
contour(
  b1,
  b2,
  f2,
  asp = 1,
  col = "dark grey",
  levels = c(480, 487.6, 495, 512.2, 526),
  drawlabels = FALSE,
  xlab = expression(x[1]),
  ylab = expression(x[2]),
  panel.first = expression(draw_canvas_bg())
)
draw_canvas_bg()
contour(
  b1,
  b2,
  f2,
  asp = 1,
  col = "dark grey",
  levels = c(480, 487.6, 495, 512.2, 526),
  drawlabels = FALSE,
  add = TRUE
)

b <- res$beta

text(b[1, 1], b[2, 1], expression(x[k - 1]), pos = 2)
text(b[1, 3], b[2, 3], expression(x[k]), pos = 3)

arrows(rm$beta[1, 3], rm$beta[2, 3], rm$r[1, 3], rm$r[2, 3], lty = 2, length = 0.15)

points(b[1, ], b[2, ], pch = 19)
lines(b[1, ], b[2, ], pch = 19)

# lines(c(rm$beta[1, 3], rm$r[1, 3]), c(rm$beta[2, 3], rm$r[2, 3]), lty = 3)

# lines(
#   c(rm$beta[1, 3], rm$beta[1, 4]),
#   c(rm$beta[2, 3], rm$beta[2, 4]),
#   lty = 2
# )

lines(
  c(rm$r[1, 3], rm$beta[1, 4]),
  c(rm$r[2, 3], rm$beta[2, 4]),
  col = "dark orange"
)
points(rm$beta[1, 4], rm$beta[2, 4], pch = 19, col = "dark orange")

lines(
  c(rn$r[1, 3], rn$beta[1, 4]),
  c(rn$r[2, 3], rn$beta[2, 4]),
  col = "steelblue4"
)
points(rn$beta[1, 4], rn$beta[2, 4], col = "steelblue4", pch = 19)
legend("topright", c("GD", "Polyak", "Nesterov"), col = c("black", "dark orange", "steelblue4"), pch = 19, bg = "white")
dev.off()
knitr::plot_crop(fn)

# points(res_momentum$beta[1, ], res_momentum$beta[2, ], col = "steelblue4")
