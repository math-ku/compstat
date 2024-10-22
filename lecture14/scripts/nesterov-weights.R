library(here)

fn <- here("images", "nesterov-weights.pdf")

draw_canvas_bg <- function(col = "white") {
  rect(par("usr")[1], par("usr")[3],
      par("usr")[2], par("usr")[4],
      col = col)
}

n <- 50
k <- 1:n
mu <- a <- double(n)
a[1] <- 1

for (k in seq_len(n - 1)) {
  a[k + 1] <- (1 + sqrt(1 + 4 * a[k]^2)) / 2
  mu[k] <- (a[k] - 1) / a[k + 1]
}

k <- 1:n

pdf(fn, width = 2.4, height = 2.9, pointsize = 7)
plot(1:(n-1), mu[-n], type = "b", pch = 19, cex = 0.7, ylab = expression(mu[k]), xlab = "k", col = "steelblue4")
draw_canvas_bg()
points(1:(n-1), mu[-n], type = "b", pch = 19, cex = 0.7, ylab = expression(mu[k]), xlab = "k")
dev.off()
knitr::plot_crop(fn)
