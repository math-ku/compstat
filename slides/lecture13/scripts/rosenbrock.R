f <- function(x1, x2, a = 1, b = 100) 
  (a - x1)^2 + b * (x2 - x1^2)^2

x1 <- seq(-2, 2, length.out = 100)
x2 <- seq(-1, 3, length.out = 100)
z <- outer(x1, x2, f)
contour(x1, x2, z, nlevels = 20)

