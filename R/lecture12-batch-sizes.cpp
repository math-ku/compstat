#include <Rcpp.h>
#include <algorithm>
#include <chrono>
#include <cmath>

void
validate_logreg_batches(const Rcpp::NumericMatrix& X,
                        const Rcpp::NumericVector& y,
                        const Rcpp::IntegerMatrix& indices,
                        const Rcpp::NumericVector& rates)
{
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
}

void
logreg_batch_update(const Rcpp::NumericMatrix& X,
                    const Rcpp::NumericVector& y,
                    const Rcpp::IntegerMatrix& indices,
                    const Rcpp::NumericVector& rates,
                    int k,
                    Rcpp::NumericVector& beta,
                    Rcpp::NumericVector& gradient)
{
  const int p = X.ncol();
  const int batch_size = indices.nrow();
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

double
logreg_batch_loss(const Rcpp::NumericMatrix& X,
                  const Rcpp::NumericVector& y,
                  const Rcpp::NumericVector& beta)
{
  double loss = 0.0;
  for (int i = 0; i < X.nrow(); ++i) {
    double eta = 0.0;
    for (int j = 0; j < X.ncol(); ++j) {
      eta += X(i, j) * beta[j];
    }
    // Evaluate the log loss without overflow at large fitted log odds.
    loss +=
      std::max(eta, 0.0) - y[i] * eta + std::log1p(std::exp(-std::abs(eta)));
  }
  return loss / X.nrow();
}

// [[Rcpp::export]]
Rcpp::NumericVector
logreg_batches_cpp(const Rcpp::NumericMatrix& X,
                   const Rcpp::NumericVector& y,
                   const Rcpp::IntegerMatrix& indices,
                   const Rcpp::NumericVector& rates)
{
  validate_logreg_batches(X, y, indices, rates);
  Rcpp::NumericVector beta(X.ncol());
  Rcpp::NumericVector gradient(X.ncol());
  for (int k = 0; k < indices.ncol(); ++k) {
    logreg_batch_update(X, y, indices, rates, k, beta, gradient);
  }
  return beta;
}

// [[Rcpp::export]]
Rcpp::List
logreg_batches_path_cpp(const Rcpp::NumericMatrix& X,
                        const Rcpp::NumericVector& y,
                        const Rcpp::IntegerMatrix& indices,
                        const Rcpp::NumericVector& rates,
                        int updates_per_epoch)
{
  validate_logreg_batches(X, y, indices, rates);
  if (updates_per_epoch < 1 || indices.ncol() % updates_per_epoch != 0) {
    Rcpp::stop("Updates must form complete epochs");
  }
  const int epochs = indices.ncol() / updates_per_epoch;
  Rcpp::NumericVector beta(X.ncol());
  Rcpp::NumericVector gradient(X.ncol());
  Rcpp::NumericVector loss(epochs + 1);
  Rcpp::NumericVector elapsed(epochs + 1);
  loss[0] = logreg_batch_loss(X, y, beta);
  const auto start = std::chrono::steady_clock::now();
  for (int k = 0; k < indices.ncol(); ++k) {
    logreg_batch_update(X, y, indices, rates, k, beta, gradient);
    if ((k + 1) % updates_per_epoch == 0) {
      const int epoch = (k + 1) / updates_per_epoch;
      loss[epoch] = logreg_batch_loss(X, y, beta);
      elapsed[epoch] =
        std::chrono::duration<double>(std::chrono::steady_clock::now() - start)
          .count();
    }
  }
  return Rcpp::List::create(Rcpp::Named("coefficients") = beta,
                            Rcpp::Named("loss") = loss,
                            Rcpp::Named("elapsed") = elapsed);
}
