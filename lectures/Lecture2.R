fhat <- function(x, h) mean(dnorm(x, phipsi$psi, h))
fhat <- Vectorize(fhat)
