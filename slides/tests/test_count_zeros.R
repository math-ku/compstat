expect_equal(count_zeros(c(0, 0, 1e-9, 25)), 2)
expect_equal(count_zeros(c(-0, 1.1, -2)), 1)
expect_equal(count_zeros(c()), 0)
