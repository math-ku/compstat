GD <- function(
  par, 
  H,
  gr,
  d = 0.8, 
  c = 0.1, 
  gamma0 = 0.01, 
  epsilon = 1e-4, 
  maxit = 1000,
  cb = NULL
) {
  for(i in 1:maxit) {
    value <- H(par)
    grad <- gr(par)
    h_prime <- sum(grad^2)
    if(!is.null(cb)) cb()
    # Convergence criterion based on gradient norm
    if(h_prime <= epsilon) break
    gamma <- gamma0
    # Proposed descent step
    par1 <- par - gamma * grad
    # Backtracking while descent is insufficient
    while(H(par1) > value - c * gamma * h_prime) {
      gamma <- d * gamma
      par1 <- par - gamma * grad
    }
    par <- par1
  }
  if(i == maxit)
    warning("Maximal number, ", maxit, ", of iterations reached")
  par
}

Newton <- function(
  par, 
  H,
  gr,
  hess,
  d = 0.8, 
  c = 0.1, 
  gamma0 = 1, 
  epsilon = 1e-10, 
  maxit = 50,
  cb = NULL
) {
  for(i in 1:maxit) {
    value <- H(par)
    grad <- gr(par)
    if(!is.null(cb)) cb()
    if(sum(grad^2) <= epsilon) break
    Hessian <- hess(par) 
    rho <- - drop(solve(Hessian, grad)) 
    gamma <- gamma0
    par1 <- par + gamma * rho
    h_prime <- t(grad) %*% rho 
    while(H(par1) > value +  c * gamma * h_prime) { 
      gamma <- d * gamma 
      par1 <- par + gamma * rho
    }
    par <- par1 
  }
  if(i == maxit)
    warning("Maximal number, ", maxit, ", of iterations reached")
  par
}