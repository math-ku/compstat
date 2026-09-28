source(here::here("R", "em-coins.R"), local = TRUE)

test_that(
  "one EM update agrees with an independently derived answer",
  {
    for (fit in list(em_coins, em_coins_counts)) {
      result <- fit(c(0, 10), theta = c(0.75, 0.25), maxit = 2)
      expect_equal(unname(result$theta[1, ]), c(0.75, 0.25))
      expect_equal(
        unname(result$theta[2, ]),
        c(3^10, 1) / (1 + 3^10)
      )
      expect_equal(
        result$loglik[1],
        2 * log((0.75^10 + 0.25^10) / 2)
      )
    }
  }
)

test_that(
  "EM histories satisfy probability and likelihood guarantees",
  {
    heads <- rep(
      0:10,
      times = c(1, 3, 5, 12, 18, 15, 13, 18, 20, 12, 4)
    )

    for (fit in list(em_coins, em_coins_counts)) {
      result <- fit(heads)
      expect_true(all(is.finite(result$theta)))
      expect_true(all(result$theta >= 0 & result$theta <= 1))
      expect_true(all(is.finite(result$loglik)))
      expect_true(all(diff(result$loglik) >= -1e-8))

      likelihood <- apply(
        result$theta,
        1,
        function(theta) {
          sum(log(
            (dbinom(heads, 10, theta[1]) +
              dbinom(heads, 10, theta[2])) /
              2
          ))
        }
      )
      expect_equal(result$loglik, likelihood)

      swapped <- fit(heads, theta = c(0.5, 0.6))
      expect_equal(
        unname(swapped$theta),
        unname(result$theta[, 2:1])
      )
      expect_equal(swapped$loglik, result$loglik)
    }
  }
)

test_that("counting outcomes preserves the full EM trajectory", {
  examples <- list(
    rep(0:10, times = 1:11),
    c(7, 4, 9),
    rep(0, 10),
    rep(10, 10)
  )

  for (heads in examples) {
    for (maxit in c(1, 2, 20)) {
      reference <- em_coins(heads, maxit = maxit)
      counted <- em_coins_counts(heads, maxit = maxit)
      expect_true(all(is.finite(counted$loglik)))
      expect_true(all(is.finite(counted$theta)))
      expect_equal(counted, reference, tolerance = 1e-10)
    }
  }
})
