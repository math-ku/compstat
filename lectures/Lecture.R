x <- c(-1, 0, 1, 2)
y <- logical(length(x))
for(i in 1:length(x)) {
  y[i] <- x[i] > 0
}
y

y <- x > 0

is_pos <- function(x) {
  y <- logical(length(x))
  for(i in 1:length(x)) {
    y[i] <- x[i] > 0
  }
  y
}

is_pos2 <- function(x) x > 0
  

