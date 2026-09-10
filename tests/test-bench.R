test_that("bench excludes GC records produced after timing has ended", {
  capture_gc <- getFromNamespace("with_gcinfo", "bench")
  testthat::local_mocked_bindings(
    with_gcinfo = function(expr) {
      capture_gc(expr)
      # The final GC can occur while bench resizes its timing vector.
      paste0(
        "Garbage collection 1 = 1+0+0 (level 0) ...\036",
        "\036",
        "Garbage collection 2 = 1+0+1 (level 2) ...\036",
        "Garbage collection 3 = 1+0+2 (level 2) ..."
      )
    },
    .package = "bench"
  )

  result <- bench::mark(sqrt(2), iterations = 3, memory = FALSE, check = FALSE)

  expect_equal(nrow(result$gc[[1]]), length(result$time[[1]]))
  expect_equal(result$gc[[1]]$level0, c(1L, 0L, 0L))
  expect_equal(result$gc[[1]]$level2, c(0L, 0L, 1L))
  expect_equal(result$n_gc, 2)
  expect_equal(result$n_itr, 1L)
  expect_equal(result$median, result$time[[1]][2])
  expect_no_error(ggplot2::ggplot_build(ggplot2::autoplot(result)))
})
