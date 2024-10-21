## ----include=FALSE------------------------------------------------------------
library("tidyverse")
library("CSwR")
knitr::opts_chunk$set(fig.width = 6, fig.height = 4, cache = TRUE, dpi = 144, 
                      out.width = 800, comment = NA,
                      dev.args = list(bg = 'transparent'), fig.align = "center")
theme_replace(plot.background = element_rect(fill = NA, color = NA))


## ----SG-basic, results='hide', message=FALSE, warning=FALSE-------------------
source("SGD.R")


## ----SG-basic-fig, echo=FALSE, out.width = 600--------------------------------
bind_rows(low = SG_trace, high = SG_trace_2, decay = SG_trace_3, .id = "Rate") %>% 
  autoplot(y = value - H(par_hat)) + aes(color = Rate) + geom_line()



## ----SG-mini-batch------------------------------------------------------------
SG <- function(
  par, 
  N,                 # Sample size
  gamma,             # Decay schedule or a fixed learning rate
  epoch = batch,     # Epoch update function #<<
  ...,               # Other arguments passed to epoch updates #<<
  maxiter = 100,     # Max epoch iterations
  sampler = sample,  # How data is resampled. Default is a random permutation
  cb = NULL
) {
  gamma <- if (is.function(gamma)) gamma(1:maxiter) else rep(gamma, maxiter) 
  for(k in 1:maxiter) {
    if(!is.null(cb)) cb()
    samp <- sampler(N)
    par <- epoch(par, samp, gamma[k], ...) #<<
  }
  par
}


## ----batch--------------------------------------------------------------------
batch <- function(
    par, 
    samp,
    gamma,  
    grad,              # Function of parameter and observation index
    m = 50,            # Mini-batch size #<<
    ...
  ) {
    M <- floor(length(samp) / m) #<<
    for(j in 0:(M - 1)) {
      i <- samp[(j * m + 1):(j * m + m)] #<<
      par <- par - gamma * grad(par, i, ...)
    }
    par
}


## ----LS-model-----------------------------------------------------------------
ls_model <- function(X, y) {
  N <- length(y)
  X <- unname(X)
  list(
    par0 = rep(0, ncol(X)),
    H = function(beta)
      drop(crossprod(y - X %*% beta)) / (2 * N),
    # Gradient that works for a mini-batch indexed by i
    grad = function(beta, i) {               
      xi <- X[i, , drop = FALSE]
      drop(crossprod(xi, xi %*% beta - y[i])) / length(i)
    }
  )
}


## ----ls_grad, echo=2,dependson="LS-model", cache=FALSE------------------------
library(zeallot)
c(par0, H, ls_grad) %<-% ls_model(X, y)


## ----SG-4, results='hide', echo=2:3, dependson=c("SG-mini-batch", "grad-obs")----
SG_tracer$clear()
SG(
  par0, N = nrow(X), gamma = 5e-2, grad = ls_grad, 
  m = 1000, maxiter = 200, cb = SG_tracer$tracer
)
SG_trace_4 <- summary(SG_tracer)


## ----SG-5, results='hide', echo=2:3, dependson=c("SG-mini-batch", "grad-obs")----
SG_tracer$clear()
SG(
  par0, N = nrow(X), gamma = 1e-3, grad = ls_grad, 
  m = 20, maxiter = 200, cb = SG_tracer$tracer
)
SG_trace_5 <- summary(SG_tracer)


## ----SG-6, results='hide', echo=2:3, dependson=c("SG-mini-batch", "grad-obs")----
SG_tracer$clear()
SG(
  par0, N = nrow(X), gamma = 5e-3, grad = ls_grad, 
  m = 100, maxiter = 200, cb = SG_tracer$tracer
)
SG_trace_6 <- summary(SG_tracer)


## ----SG-fig, echo=FALSE, dependson=c("SG-basic", "SG-4", "SG-5", "SG-6")------
bind_rows(low = SG_trace, high = SG_trace_2, decay = SG_trace_3, 
          m_1000 = SG_trace_4, m_20 = SG_trace_5, m_100 = SG_trace_6, .id = "Rate") %>% 
  autoplot(y = value - H(par_hat)) + aes(color = Rate) + geom_line()


## ----momentum-----------------------------------------------------------------
momentum <- function() {
  rho <- 0 #<<
  function(
    par, 
    samp,
    gamma,  
    grad,
    m = 50,             # Mini-batch size
    beta = 0.95,        # Momentum memory #<<
    ...
  ) {
    M <- floor(length(samp) / m)
    for(j in 0:(M - 1)) {
      i <- samp[(j * m + 1):(j * m + m)]
      # Using '<<-' assigns the value to rho in the enclosing environment
      rho <<- beta * rho + (1 - beta) * grad(par, i, ...)  #<<
      par <- par - gamma * rho
    }
    par
  }
}


## ----SG-7, results='hide', echo=2:3, dependson=c("SG-momentum", "grad-obs")----
SG_tracer$clear()
SG(
  par0, N = nrow(X), gamma = 5e-2, grad = ls_grad, 
  epoch = momentum(), #<<
  m = 1000, maxiter = 200, cb = SG_tracer$tracer
)
SG_trace_7 <- summary(SG_tracer)


## ----SG-fig-2, echo=FALSE, dependson=c("SG-basic", "SG-4", "SG-5", "SG-6", "SG-7")----
bind_rows(high = SG_trace_2, m_1000 = SG_trace_5, Moment = SG_trace_7, .id = "Rate") %>% 
  autoplot(y = value - H(par_hat)) + aes(color = Rate) + geom_line()


## ----Adam---------------------------------------------------------------------
adam <- function() {
  rho <- v <- 0 #<<
  function(
    par, 
    samp,
    gamma,   
    grad,
    m = 50,          # Mini-batch size
    beta1 = 0.9,     # Momentum memory     
    beta2 = 0.9,     # Second moment memory #<<
    ...
  ) {
    M <- floor(length(samp) / m)
   
    for(j in 0:(M - 1)) {
      i <- samp[(j * m + 1):(j * m + m)]
      gr <- grad(par, i, ...) 
      rho <<- beta1 * rho + (1 - beta1) * gr 
      v <<- beta2 * v + (1 - beta2) * gr^2 #<<
      par <- par - gamma * (rho / (sqrt(v) + 1e-8))  
    }
    par
  }
}


## ----SG-8, results='hide', echo=2:3, dependson=c("SG-adam", "grad-obs")-------
SG_tracer$clear()
SG(
  par0, N = nrow(X), gamma = 1e-2, grad = ls_grad, 
  epoch = adam(), #<<
  m = 1000, maxiter = 200, cb = SG_tracer$tracer
)
SG_trace_8 <- summary(SG_tracer)


## ----SG-9, results='hide', echo=2:3, dependson=c("SG-adam", "grad-obs")-------
SG_tracer$clear()
SG(
  par0, N = nrow(X), 
  gamma = decay_scheduler(gamma0 = 0.5, gamma1 = 2e-3, a = 0.5, n1 = 150), #<<
  grad = ls_grad, epoch = adam(), m = 1000, maxiter = 200, cb = SG_tracer$tracer
)
SG_trace_9 <- summary(SG_tracer)


## ----SG-fig-3, echo=FALSE, dependson=c("SG-basic", "SG-4", "SG-5", "SG-6", "SG-7", "SG-8")----
bind_rows(decay = SG_trace_3, m_20 = SG_trace_5, Moment = SG_trace_7, 
          adam = SG_trace_8, adam_decay = SG_trace_9, .id = "Rate") %>% 
  autoplot(y = value - H(par_hat)) + aes(color = Rate) + geom_line()


## ----Rcpp---------------------------------------------------------------------
library(Rcpp)
library(RcppArmadillo)
library(dqrng)


## #include <RcppArmadillo.h>
## #include <dqrng.h>
## using namespace Rcpp;
## using namespace arma;

## // [[Rcpp::export]]
## NumericVector lin_grad(
##     NumericVector beta,
##     IntegerVector ii,
##     NumericMatrix X,
##     NumericVector y
## ) {
##   int m = ii.length(), p = beta.length();
##   NumericVector grad(p), yhat(m);
##   // Shift indices one down due to zero-indexing in C++
##   IntegerVector iii = clone(ii) - 1;
## 
##   for(int i = 0; i < m; ++i) {
##     for(int j = 0; j < p; ++j) {
##       yhat[i] += X(iii[i], j) * beta[j];
##     }
##   }
##   for(int i = 0; i < m; ++i) {
##     for(int j = 0; j < p; ++j) {
##       grad[j] += X(iii[i], j) * (yhat[i]- y[iii[i]]);
##     }
##   }
##   return grad / m;
## }

## // [[Rcpp::export]]
## NumericVector lin_batch(
##     NumericVector par,
##     IntegerVector ii,
##     double gamma,
##     NumericMatrix X,
##     NumericVector y,
##     int m = 50
## ) {
##   int p = par.length(), N = ii.length();
##   int M = floor(N / m);
##   NumericVector grad(p), yhat(N), beta = clone(par);
##   IntegerVector iii = clone(ii) - 1;
## 
##   for(int j = 0; j < M; ++j) {
##     for(int i = j * m; i < (j + 1) * m; ++i) {
##       for(int k = 0; k < p; ++k) {
##         yhat[i] += X(iii[i], k) * beta[k];
##       }
##     }
##     for(int k = 0; k < p; ++k) {
##       grad[k] = 0;
##       for(int i = j * m; i < (j + 1) * m; ++i) {
##         grad[k] += X(iii[i], k) * (yhat[i] - y[iii[i]]);
##       }
##     }
##     beta = beta - gamma * (grad / m);
##   }
##   return beta;
## }

## ----SG-10, results='hide', echo=2:3, dependson=c("SG-mini-batch", "grad-obs")----
SG_tracer$clear()
SG(
  par0, N = nrow(X), gamma = 5e-2, 
  grad = lin_grad,  #<< 
  X = X, y = y, #<<
  m = 1000, maxiter = 200, cb = SG_tracer$tracer
)
SG_trace_10 <- summary(SG_tracer)


## ----SG-11, results='hide', echo=2:3, dependson=c("SG-mini-batch", "grad-obs")----
SG_tracer$clear()
SG(
  par0, N = nrow(X), gamma = 5e-2, 
  epoch = lin_batch,  #<< 
  X = X, y = y, #<<
  m = 1000, maxiter = 200, cb = SG_tracer$tracer
)
SG_trace_11 <- summary(SG_tracer)


## ----SG-12, results='hide', echo=2:3, dependson=c("SG-mini-batch", "grad-obs")----
SG_tracer$clear()
SG(
  par0, N = nrow(X), gamma = 5e-5, 
  epoch = lin_batch, X = X, y = y, 
  m = 1, #<<
  maxiter = 200, cb = SG_tracer$tracer
)
SG_trace_12 <- summary(SG_tracer)


## ----SG-fig-4, echo=FALSE, dependson=c("SG-basic", "SG-4", "SG-5", "SG-6")----
bind_rows(high = SG_trace_2, Rcpp_grad_mini = SG_trace_10, Rcpp_epoch_mini = SG_trace_11,
          Rcpp_epoch = SG_trace_12, .id = "Rate") %>% 
  autoplot(y = value - H(par_hat)) + aes(color = Rate) + geom_line()


## // [[Rcpp::depends(dqrng)]]
## // [[Rcpp::export]]
## NumericVector SG_Rcpp(
##     NumericVector par, int N, NumericVector gamma,
##     NumericMatrix X, NumericVector y,
##     int m = 50, int maxiter = 100
## ) {
##   int p = par.length(), M = floor(N / m);
##   NumericVector grad(p), yhat(N), beta = clone(par);
##   IntegerVector ii;
## 
##   for(int l = 0; l < maxiter; ++l) {
##     // Note that dqsample_int samples from {0, 1, ..., N - 1}
##     ii = dqrng::dqsample_int(N, N);
##     for(int j = 0; j < M; ++j) {
##       for(int i = j * m; i < (j + 1) * m; ++i) {
##         yhat[i] = 0;
##         for(int k = 0; k < p; ++k) {
##           yhat[i] += X(ii[i], k) * beta[k];
##         }
##       }
##       for(int k = 0; k < p; ++k) {
##         grad[k] = 0;
##         for(int i = j * m; i < (j + 1) * m; ++i) {
##           grad[k] += X(ii[i], k) * (yhat[i] - y[ii[i]]);
##         }
##       }
##       beta = beta - gamma[l] * (grad / m);
##     }
##   }
##   return beta;
## }

## // [[Rcpp::depends(RcppArmadillo)]]
## // [[Rcpp::export]]
## arma::colvec SG_arma(
##     NumericVector par,
##     int N,
##     NumericVector gamma,
##     const arma::mat& X,
##     const arma::colvec& y,
##     int m = 50,
##     int maxiter = 100
## ) {
##   int p = par.length(), M = floor(N / m);
##   arma::colvec grad(p), yhat(N), beta = clone(par);
##   uvec ii, iii;
## 
##   for(int l = 0; l < maxiter; ++l) {
##     ii = as<arma::uvec>(dqrng::dqsample_int(N, N));
##     for(int j = 0; j < M; ++j) {
##       iii = ii.subvec(j * m, (j + 1) * m - 1);
##       beta = beta - gamma[l] * (X.rows(iii).t() * (X.rows(iii) * beta - y(iii)) / m);
##     }
##   }
##   return beta;
## }

## ----mark-SG-batch, warning=FALSE, dependson=c("SG-Armadillo", "SG-Rcpp", "epoch-Rcpp", "grad-Rcpp", "ls-grad-update", "LS-model", "SG-mini-batch", "batch")----
bench::mark(
  SG = SG(par0, nrow(X), 1e-4, maxiter = 10, grad = ls_grad),
  SG_lin_grad = SG(par0, nrow(X), 1e-4, maxiter = 10, grad = lin_grad, X = X, y = y),
  SG_lin_batch = SG(par0, nrow(X), 1e-4, lin_batch, maxiter = 10, X = X, y = y),
  SG_Rcpp = SG_Rcpp(par0, nrow(X), rep(1e-4, 10), X = X, y = y, maxiter = 10),
  SG_arma = SG_arma(par0, nrow(X), rep(1e-4, 10), X = X, y = y, maxiter = 10), 
  check = FALSE, iterations = 5
)


## ----mark-SG-basic, warning=FALSE, dependson=c("SG-Armadillo", "SG-Rcpp", "epoch-Rcpp", "grad-Rcpp", "ls-grad-update", "LS-model", "SG-mini-batch", "batch")----
bench::mark(
  SG = SG(par0, nrow(X), 1e-4, maxiter = 10, m = 1, grad = ls_grad),
  SG_lin_grad = SG(par0, nrow(X), 1e-4, maxiter = 10, m = 1, grad = lin_grad, X = X, y = y),
  SG_lin_batch = SG(par0, nrow(X), 1e-4, lin_batch, maxiter = 10, m = 1, X = X, y = y),
  SG_Rcpp = SG_Rcpp(par0, nrow(X), rep(1e-4, 10), X = X, y = y, maxiter = 10, m = 1),
  SG_arma = SG_arma(par0, nrow(X), rep(1e-4, 10), X = X, y = y, maxiter = 10, m = 1), 
  check = FALSE, memory = FALSE, iterations = 5
)

