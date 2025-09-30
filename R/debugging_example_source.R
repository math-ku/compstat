my_sum <- function(x) {
  total <- 0

  for (i in 1:length(x)) {
    total <- total + x[i]
  }

  total
}

my_log_sum <- function(y) {
  result <- my_sum(y)
  log(result)
}
