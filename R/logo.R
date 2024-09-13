phiphsi <- read.table(file.path("data", "phipsi.tsv"), header = TRUE)

from <- 1.5 * -pi
to <- 1.2 * pi

path <- file.path("images", "logo.png")

png(path, width = 1300, height = 700, res = 192)
par(mar = c(1, 1, 1, 1))

hist(
  phipsi$phi,
  prob = TRUE,
  ann = FALSE,
  yaxt = "n",
  xaxt = "n",
  border = "lightgrey",
  xlim = c(from, to),
)

d1 <- density(phipsi$phi, bw = 0.6, from = from, to = to)
d2 <- density(phipsi$phi, bw = 0.2, from = from, to = to)

lwd <- 3

lines(d1, col = "steelblue", lwd = lwd)
lines(d2, lwd = lwd)
dev.off()
