vMsim_slow <- function(n, kappa) {
  y <- numeric(n)
  for (i in 1:n) {
    reject <- TRUE
    while (reject) {
      y0 <- runif(1, -pi, pi)
      u <- runif(1)
      reject <- u > exp(kappa * (cos(y0) - 1))
    }
    y[i] <- y0
  }
  y
}

vMsim_vec <- function(n, kappa) {
  fact <- 1
  j <- 1
  l <- 0 ## The number of accepted samples
  y <- list()
  while (l < n) {
    m <- floor(fact * (n - l)) ## equals n the first time
    y0 <- runif(m, -pi, pi)
    u <- runif(m)
    accept <- u <= exp(kappa * (cos(y0) - 1))
    l <- l + sum(accept)
    y[[j]] <- y0[accept]
    j <- j + 1
    if (fact == 1) fact <- n / l
  }
  unlist(y)[1:n]
}

tfun <- function(y, a) {
  b <- 1 / (3 * sqrt(a))
  (y > -1 / b) * a * (1 + b * y)^3 ## 0 when y <= -1/b
}

qfun <- function(y, r) {
  a <- r - 1 / 3
  tval <- tfun(y, a)
  exp(a * log(tval / a) - tval + a)
}

rng_stream <- function(m, rng, ...) {
  args <- list(...)
  cache <- do.call(rng, c(m, args))
  j <- 0
  fact <- 1
  next_rn <- function(r = m) {
    j <<- j + 1
    if (j > m) {
      if (fact == 1 && r < m) fact <<- m / (m - r)
      m <<- floor(fact * (r + 1))
      cache <<- do.call(rng, c(m, args))
      j <<- 1
    }
    cache[j]
  }
  next_rn
}

gammasim <- function(n, r, trace = FALSE) {
  count <- 0
  y <- numeric(n)
  y0 <- rng_stream(n, rnorm)
  u <- rng_stream(n, runif)
  for (i in 1:n) {
    reject <- TRUE
    while (reject) {
      count <- count + 1
      z <- y0(n - i)
      reject <- u(n - i) > qfun(z, r) * exp(z^2 / 2)
    }
    y[i] <- z
  }
  if (trace) {
    cat("r =", r, ":", (count - n) / count, "\n")
  } ## Rejection frequency
  tfun(y, r - 1 / 3)
}

