fooFactory <- function(y) {
  foo <- function(x) {
    browser()
    y * x^2 + x + 1
  }
  foo(1)
  foo
}

foo <- fooFactory(2)

fooCaller <- function() {
  foo(1)
}
