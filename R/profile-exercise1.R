matrix_vector_multiplication <- function(x, y) {
  n <- NROW(x)

  out <- c()

  for (i in seq_len(n)) {
    xi_y <- t(x[, i]) %*% y
    out <- c(out, xi_y)
  }

  out
}
