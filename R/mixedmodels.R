library(lme4)
data("sleepstudy")

# Fit a mixed model with random intercepts for each subject
model <- lmer(Reaction ~ 1 + (1 | Subject), data = sleepstudy, REML = FALSE)
summary(model)

beta0 <- 1
nu <- 5
sigma <- 1
m <- 20
ni <- rep(10, m)
n <- sum(ni)

z <- rnorm(m)
mu <- beta0 + nu * rep(z, times = ni)
x <- rnorm(n, mu, sigma)

beta0 <- 1
Z <- matrix(0, nrow = n, ncol = m)
G <- diag()
