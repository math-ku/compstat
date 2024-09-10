library(profvis)

x <- rnorm(1e3)

kern_dens(x, 0.2)

kern_dens_detail(x, 0.2)

n <- 1
p <- 100000

x <- matrix(rnorm(n * p), n)
y <- rnorm(n)

matrix_vector_dot(x, y)
