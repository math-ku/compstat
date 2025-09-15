sample_vonmises_slow <- function(n, kappa) {
  replicate(n, get_one_sample_vmises(kappa))
}

get_one_sample_vmises <- function(kappa) {
  repeat {
    Y <- runif(1, -pi, pi)
    U <- runif(1)
    if (U <= exp(kappa * (cos(Y) - 1))) {
      break
    }
  }
  Y
}
