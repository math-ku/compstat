(0.1 + 0.1 + 0.1) > 0.3

filt <- function(x, h) 
  x[x > h]

filt(seq(0, 1, 0.1), 0.3)
options(digits = 20)
filt(seq(0, 1, 0.1), 0.3)
0.3
options(digits = 7)

filt(c(1, 2, 3), 2)
filt(seq(0, 1, 0.1), 0.3)

filt(c(-Inf, 1, 2, Inf), 3)
filt(c(NA, 1, 2, 4), 3)

filt <- function(x, h){
  x <- x[!is.na(x)]
  x[x > h]
}

