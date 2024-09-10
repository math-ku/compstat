matrix_vector_dot <- function(x, y) {
  p <- NCOL(x)
  
  out <- c()
  
  for (i in seq_len(p)) {
    xi_y <- t(x[, i]) %*% y
    out <- c(out, xi_y)
  }
  
  out
}