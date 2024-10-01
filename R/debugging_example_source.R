my_sum <- function(x) {
  total <- 0
  
  for (i in seq_along(x)) {
    if (is.na(x[i])) {
      next
    }

    total <- total + x[i]
  }
  
  total
}

my_log_sum <- function(y) {
  result <- my_sum(y)
  log(result)
}
