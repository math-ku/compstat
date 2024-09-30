##----
vegetables <- read.table(
  "../Week 4 Optimization/vegetablesSale.txt",
  header = TRUE,
  colClasses = c("numeric", "numeric", "factor", "factor",
                 "numeric", "numeric", "numeric")
)[, c(1, 2, 3)]

##----

X <- model.matrix(
  sale ~ log(normalSale) + store, 
  data = vegetables
)
y <- vegetables$sale
t_map <- drop(crossprod(X, y))
beta0 <- rep(0.1, ncol(X))

H <- function(beta) 
  drop(sum(exp(X %*% beta)) - beta %*% t_map) / nrow(X)

H(beta0)

##----

rm(X)

H(beta0)

##----

X <- model.matrix(
  sale ~  store, 
  data = vegetables
)
t_map <- drop(crossprod(X, y))
beta0 <- rep(0.1, ncol(X))

pois_loglikelihood <- function(X, y)  {
  t_map <- drop(crossprod(X, y))
  function(beta) 
    drop(sum(exp(X %*% beta)) - beta %*% t_map) / nrow(X)
}

H1 <- pois_loglikelihood(X, y)

H(beta0)

##----

rm(X)

H1(beta0)

##----

X <- model.matrix(
  sale ~  store, 
  data = vegetables
)

pois_loglikelihood <- function(X, t_map)  {
  force(X)
  force(t_map)
  function(beta) 
    drop(sum(exp(X %*% beta)) - beta %*% t_map) / nrow(X)
}

H2 <- pois_loglikelihood(X, t_map)

##----


X <- model.matrix(
  sale ~ log(normalSale) + store, 
  data = vegetables
)
t_map <- drop(crossprod(X, y))
beta0 <- rep(0.1, ncol(X))

H2(beta0)





##---- glm trace ----

veg_glm <- glm.fit(X, y, family = poisson())

library(CSwR)
glm_tracer <- tracer("value", N = 1, expr = quote(value <- H(fit$coefficients)))
veg_glm <- glm.fit(X, y, family = poisson())
summary(glm_tracer)

eval(expression(value <- H(beta0)))
eval(quote(value <- H(beta0)))

















