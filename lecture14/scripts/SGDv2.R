library(CSwR)

#### SG ----

SG <- function(
  par,
  N,                 # Sample size
  gamma,             # Decay schedule or a fixed learning rate
  epoch = batch,     # Epoch update function 
  ...,               # Other arguments passed to epoch updates 
  maxiter = 100,     # Max epoch iterations
  sampler = sample,  # How data is resampled. Default is a random permutation
  cb = NULL
) {
  gamma <- if (is.function(gamma)) gamma(1:maxiter) else rep(gamma, maxiter) 
  for(k in 1:maxiter) {
    if(!is.null(cb)) cb()
    samp <- sampler(N)
    par <- epoch(par, samp, gamma[k], ...) 
  }
  par
}


#### mini-batch ----

batch <- function(
  par,
  samp,
  gamma,
  grad,              # Function of parameter and observation index
  m = 50,            # Mini-batch size 
  ...
) {
  M <- floor(length(samp) / m) 
  for(j in 0:(M - 1)) {
    i <- samp[(j * m + 1):(j * m + m)] 
    par <- par - gamma * grad(par, i, ...)
  }
  par
}

#### momentum -----

momentum <- function() {
  rho <- 0 #<<
  function(
    par,
    samp,
    gamma,
    grad,
    m = 50,             # Mini-batch size
    beta = 0.95,        # Momentum memory 
    ...
  ) {
    M <- floor(length(samp) / m)
    for (j in 0:(M - 1)) {
      i <- samp[(j * m + 1):(j * m + m)]
      rho <<- beta * rho + (1 - beta) * grad(par, i, ...)
      par <- par - gamma * rho
    }
    par
  }
}

#### Adam ------

adam <- function() {
  rho <- v <- 0
  function(
    par,
    samp,
    gamma,
    grad,
    m = 50,          # Mini-batch size
    beta1 = 0.9,     # Momentum memory
    beta2 = 0.9,     # Second moment memory
    ...
  ) {
    M <- floor(length(samp) / m)

    for (j in 0:(M - 1)) {
      i <- samp[(j * m + 1):(j * m + m)]
      gr <- grad(par, i, ...)
      rho <<- beta1 * rho + (1 - beta1) * gr
      v <<- beta2 * v + (1 - beta2) * gr^2
      par <- par - gamma * (rho / (sqrt(v) + 1e-8))
    }
    par
  }
}
