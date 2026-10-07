#include <Rcpp.h>
#include <algorithm>
#include <cmath>

// [[Rcpp::export]]
Rcpp::NumericVector
logreg_batches_cpp(const Rcpp::NumericMatrix& X,
                   const Rcpp::NumericVector& y,
                   const Rcpp::IntegerMatrix& indices,
                   const Rcpp::NumericVector& rates)
{
  const int p = X.ncol();
  const int batch_size = indices.nrow();
  const int updates = indices.ncol();
  if (batch_size < 1 || y.size() != X.nrow() || rates.size() != updates) {
    Rcpp::stop("Incompatible data, batches, or learning rates");
  }
  for (R_xlen_t i = 0; i < indices.size(); ++i) {
    if (indices[i] < 1 || indices[i] > X.nrow()) {
      Rcpp::stop("Batch indices must be between 1 and nrow(X)");
    }
  }

  Rcpp::NumericVector beta(p);
  Rcpp::NumericVector gradient(p);
  for (int k = 0; k < updates; ++k) {
    std::fill(gradient.begin(), gradient.end(), 0.0);
    for (int i = 0; i < batch_size; ++i) {
      const int row = indices(i, k) - 1;
      double eta = 0.0;
      for (int j = 0; j < p; ++j) {
        eta += X(row, j) * beta[j];
      }
      const double residual = 1.0 / (1.0 + std::exp(-eta)) - y[row];
      for (int j = 0; j < p; ++j) {
        gradient[j] += X(row, j) * residual;
      }
    }
    for (int j = 0; j < p; ++j) {
      beta[j] -= rates[k] * gradient[j] / batch_size;
    }
  }
  return beta;
}
