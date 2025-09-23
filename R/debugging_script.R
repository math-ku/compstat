set.seed(1)

# Data
n <- 1000
x <- rnorm(n)
y <- rpois(n, exp(x))
X <- model.matrix(y ~ x)

gradient_descent(
  c(0, 0),
  objective,
  gradient,
  t0 = 1,
  epsilon = 1e-8,
  X = X,
  y = y
)

glm(y ~ x, family = "poisson")

newton_method(
  c(0, 0),
  objective,
  gradient,
  hessian,
  X = X,
  y = y
)
