## ----include=FALSE------------------------------------------------------------
library("tidyverse")
library("CSwR")
knitr::opts_chunk$set(
  fig.width = 6, fig.height = 4, cache = TRUE, dpi = 144,
  out.width = 600, comment = NA,
  dev.args = list(bg = "transparent"), fig.align = "center"
)
theme_replace(plot.background = element_rect(fill = NA, color = NA))


## ----SG-basic, results='hide', message=FALSE, warning=FALSE-------------------
source("SGD.R")


## ----SG-basic-fig, echo=FALSE-------------------------------------------------
bind_rows(low = SG_trace, high = SG_trace_2, decay = SG_trace_3, .id = "Rate") %>%
  autoplot(y = value - H(par_hat)) + aes(color = Rate) + geom_line()


## ----SG-mini-batch------------------------------------------------------------
SG <- function(
    par,
    grad, # Function of parameter and observation index
    N, # Sample size
    gamma, # Decay schedule or a fixed learning rate
    m = 50, # Mini-batch size  #<<
    maxiter = 100, # Max epoch iterations
    cb = NULL,
    ...) {
  gamma <- if (is.function(gamma)) gamma(1:maxiter) else rep(gamma, maxiter)
  M <- floor(N / m) #<<
  for (k in 1:maxiter) {
    if (!is.null(cb)) cb()
    samp <- sample(N)
    for (j in 0:(M - 1)) {
      i <- samp[(j * m + 1):(j * m + m)] #<<
      par <- par - gamma[k] * grad(par, i, ...)
    }
  }
  par
}


## ----LS-model-----------------------------------------------------------------
ls_model <- function(X, y) {
  N <- length(y)
  X <- unname(X)

  list(
    par0 = rep(0, ncol(X)),

    # Objective function
    H = function(beta) {
      drop(crossprod(y - X %*% beta)) / (2 * N)
    },

    # Gradient
    grad = function(beta, i) {
      xi <- X[i, , drop = FALSE]
      drop(crossprod(xi, xi %*% beta - y[i])) / length(i)
    }
  )
}


## ----grad-obs, dependson="LS-model"-------------------------------------------
c(par0, H, grad_obs) %<-% ls_model(X, y)


## ----SG-4, results='hide', echo=2:3, dependson=c("SG-mini-batch", "grad-obs")----
SG_tracer$clear()
rate <- decay_scheduler(gamma0 = 1e-2, gamma1 = 1e-4, n1 = 100)
SG(par0, grad_obs, N = nrow(X), gamma = rate, cb = SG_tracer$tracer)
SG_trace_4 <- summary(SG_tracer)


## ----SG-5, results='hide', echo=2:3, dependson=c("SG-mini-batch", "grad-obs")----
SG_tracer$clear()
rate <- decay_scheduler(gamma0 = 1e-3, gamma1 = 1e-4, n1 = 100)
SG(par0, grad_obs, N = nrow(X), gamma = rate, m = 20, cb = SG_tracer$tracer)
SG_trace_5 <- summary(SG_tracer)


## ----SG-6, results='hide', echo=2:3, dependson=c("SG-mini-batch", "grad-obs")----
SG_tracer$clear()
rate <- decay_scheduler(gamma0 = 1e-1, gamma1 = 1e-4, n1 = 100)
SG(par0, grad_obs, N = nrow(X), gamma = rate, m = 200, cb = SG_tracer$tracer)
SG_trace_6 <- summary(SG_tracer)


## ----SG-fig, echo=FALSE, dependson=c("SG-basic", "SG-4", "SG-5", "SG-6")------
bind_rows(
  low = SG_trace, high = SG_trace_2, decay = SG_trace_3,
  m_50 = SG_trace_4, m_20 = SG_trace_5, m_100 = SG_trace_6, .id = "Rate"
) %>%
  autoplot(y = value - H(par_hat)) + aes(color = Rate) + geom_line()


## ----SG-momentum--------------------------------------------------------------
SG_mom <- function(
    par,
    grad, # Function of parameter and observation index
    N, # Sample size
    gamma, # Decay schedule or a fixed learning rate
    beta = 0.9, # Momentum memory #<<
    m = 50, # Mini-batch size
    maxiter = 100, # Max epoch iterations
    cb = NULL,
    ...) {
  gamma <- if (is.function(gamma)) gamma(1:maxiter) else rep(gamma, maxiter)
  M <- floor(N / m)
  rho <- 0
  for (k in 1:maxiter) {
    if (!is.null(cb)) cb()
    samp <- sample(N)
    for (j in 0:(M - 1)) {
      i <- samp[(j * m + 1):(j * m + m)]
      rho <- beta * rho + (1 - beta) * grad(par, i, ...) #<<
      par <- par - gamma[k] * rho
    }
  }
  par
}


## ----SG-7, results='hide', echo=3:4, dependson=c("SG-momentum", "grad-obs")----
SG_tracer$clear()
c(par0, H, grad_obs) %<-% ls_model(X, y)
rate <- decay_scheduler(gamma0 = 1e-3, gamma1 = 5e-5, n1 = 100)
SG_mom(par0, grad_obs, N = nrow(X), gamma = rate, m = 10, cb = SG_tracer$tracer)
SG_trace_7 <- summary(SG_tracer)


## ----SG-fig-2, echo=FALSE, dependson=c("SG-basic", "SG-4", "SG-5", "SG-6", "SG-7")----
bind_rows(decay = SG_trace_3, m_20 = SG_trace_5, Moment = SG_trace_7, .id = "Rate") %>%
  autoplot(y = value - H(par_hat)) + aes(color = Rate) + geom_line()


## ----SG-adam------------------------------------------------------------------
SG_adam <- function(
    par,
    grad, # Function of parameter and observation index
    N, # Sample size
    gamma, # Decay schedule or a fixed learning rate
    beta = c(0.9, 0.99), # Momentum and weight memory #<<
    m = 50, # Mini-batch size
    maxiter = 100, # Max epoch iterations
    cb = NULL,
    ...) {
  gamma <- if (is.function(gamma)) gamma(1:maxiter) else rep(gamma, maxiter)
  M <- floor(N / m)
  rho <- v <- 0
  for (k in 1:maxiter) {
    if (!is.null(cb)) cb()
    samp <- sample(N)
    for (j in 0:(M - 1)) {
      i <- samp[(j * m + 1):(j * m + m)]
      gr <- grad(par, i, ...)
      rho <- beta[1] * rho + (1 - beta[1]) * gr
      v <- beta[2] * v + (1 - beta[2]) * gr^2 #<<
      rho_tilde <- rho / (1 - beta[1]^k) #<<
      v_tilde <- v / (1 - beta[2]^k) #<<
      par <- par - gamma[k] * (rho_tilde / sqrt(v_tilde)) #<<
    }
  }
  par
}


## ----SG-8, results='hide', echo=3:4, dependson=c("SG-adam", "grad-obs")-------
SG_tracer$clear()
c(par0, H, grad_obs) %<-% ls_model(X, y)
rate <- decay_scheduler(gamma0 = 0.1, gamma1 = 5e-5, n1 = 100)
SG_adam(par0, grad_obs, N = nrow(X), gamma = rate, m = 50, cb = SG_tracer$tracer)
SG_trace_8 <- summary(SG_tracer)


## ----SG-fig-3, echo=FALSE, dependson=c("SG-basic", "SG-4", "SG-5", "SG-6", "SG-7", "SG-8")----
bind_rows(
  decay = SG_trace_3, m_20 = SG_trace_5, Moment = SG_trace_7,
  adam = SG_trace_8, .id = "Rate"
) %>%
  autoplot(y = value - H(par_hat)) + aes(color = Rate) + geom_line()

