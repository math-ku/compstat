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
  arg <- list(...)
  cache <- do.call(rng, c(m, arg))
  j <- 0
  fact <- 1
  next_rn <- function(r = m) {
    j <<- j + 1
    if (j > m) {
      if (fact == 1 && r < m) {
        fact <<- m / (m - r)
      }
      m <<- floor(fact * (r + 1))
      cache <<- do.call(rng, c(m, arg))
      j <<- 1
    }
    cache[j]
  }
  next_rn
}

gamma_sim <- function(n, r, trace = FALSE) {
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

new_rejection_sampler <- function(generator) {
  function(n, ...) {
    alpha <- 1
    y <- numeric(0)
    n_accepted <- 0
    while (n_accepted < n) {
      m <- ceiling((n - n_accepted) / alpha)
      y_new <- generator(m, ...)
      n_accepted <- n_accepted + length(y_new)
      if (length(y) == 0) {
        alpha <- (n_accepted + 1) / (m + 1)
      }
      y <- c(y, y_new)
    }
    list(x = y[seq_len(n)], alpha = alpha)
  }
}
