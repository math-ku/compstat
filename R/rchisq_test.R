library(bench)
library(ggplot2)
library(here)
library(profvis)
library(testthat)

source(here("R", "rchisq.R"))

# Test ----

n <- 10000
k <- 8

qqplot(qchisq(ppoints(n), k), rchisq2(n, k), xlim = c(0, 40), ylim = c(0, 40))
abline(0, 1)

density(rchisq2(n, k)) |> plot(xlim = c(0, 40), ylim = c(0, 0.2))
curve(dchisq(x, df = k), add = TRUE, col = "blue")

test_that("Our rchisq() implementation is correct", {
  y <- rchisq2(n, k)
  expect_equal(length(y), n)
  expect_equal(mean(y), k)
  expect_equal(var(y), 2 * k)
})

# Profile ----

profvis(rchisq2(100000, 2))
profvis(rchisq2(100000, 20))
profvis(rchisq2(100000, 200))

# Benchmark ----

rchisq2_faster <- function(n, k) {
  y <- numeric(n)
  x <- matrix(rnorm(n * k), k, n)
  colSums(x^2)
}

n <- 10000
k <- 8

qqplot(qchisq(ppoints(n), k), rchisq2_faster(n, k), xlim = c(0, 40), ylim = c(0, 40))
abline(0, 1)

bench::mark(
  rchisq2(n, k),
  rchisq2_faster(n, k),
  check = FALSE
)

# And even faster again ----

rchisq2_fast <- function(n, k) {
  x <- matrix(rnorm(n * k), n, k)
  rowSums(x^2)
}

qqplot(qchisq(ppoints(n), k), rchisq2_fast(n, k), xlim = c(0, 40), ylim = c(0, 40))
abline(0, 1)

bench::mark(
  rchisq2(n, k),
  rchisq2_faster(n, k),
  rchisq2_fast(n, k),
  check = FALSE
)
