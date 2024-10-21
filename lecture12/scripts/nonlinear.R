library(tidyverse)
library(plotly)
library(viridis)
library(zeallot)  # For the '%<-%' assignment operator
library(numDeriv)
library(CSwR)
library(here)

source("scripts/SGDv2.R")

## -----------------------------------------------------------------------------
Loss <- function(data, f, df) {
  force(data); force(f); force(df)
  loss <- function(par, ...) {
    mean((data$y - f(data$x, par))^2) / 2
  }
  gradient <- function(par, ...) {
    df <- df(data$x, par)
    dq <- (f(data$x, par) - data$y) 
    drop(df %*% dq) / nrow(data)
  }
  gradient_batch <- function(par, i, ...) {
    df <- df(data$x[i], par)
    dq <- (f(data$x[i], par) - data$y[i]) 
    drop(df %*% dq) / length(i)
  }
  list(loss = loss, 
       gradient = gradient, 
       gradient_batch = gradient_batch)
}


## ----sim_oscillation----------------------------------------------------------
N <- 1000
alpha <- 1
beta <- 10
sigma <- 0.1

f <- function(x, par)
 par[1] * cos(par[2] * x)

osc <- tibble::tibble(
  x = seq(0, 5, length.out = N),
  f = f(x, c(alpha, beta)),
  y = f + rnorm(N, sd = sigma)
)    

fn1 <- here("images", "nonlinear-data.pdf")
pdf(fn1, width = 2.9, height = 2.6, pointsize = 8)
plot(
  osc$x,
  osc$y,
  pch = 19,
  col = "dark grey",
  xlab = "x",
  ylab = expression(f(x)),
  cex = 0.7
)
lines(osc$x, osc$f)
dev.off()
knitr::plot_crop(fn1)

df <- function(x, par)
  rbind(cos(par[2] * x), - par[1] * x * sin(par[2] * x))

lossList <- Loss(osc, f, df)

c(H, grad, grad_batch) %<-% Loss(osc, f, df)

alpha_seq <- seq(-2, 2, length.out = 26)
beta_seq <- seq(8, 12, length.out = 26)
z <- Heval <- outer(alpha_seq, beta_seq, Vectorize(function(a, b) H(c(a, b))))
nrz <- nrow(z)
ncz <- ncol(z)

nbcol <- 100

pal <- function(n) hcl.colors(n, "viridis", rev = TRUE)
color <- pal(nbcol)

zfacet <- z[-1, -1] + z[-1, -ncz] + z[-nrz, -1] + z[-nrz, -ncz]
facetcol <- cut(zfacet, nbcol)

fn2 <- here("images", "nonlinear-persp.pdf")
pdf(fn2, width = 3.3, height = 4, pointsize = 7)
persp(
  beta_seq,
  alpha_seq,
  Heval,
  col = color[facetcol],
  theta = 20,
  phi = 50,
  xlab = expression(beta),
  ylab = expression(alpha),
  zlab = expression(f(alpha,beta))
)
dev.off()
knitr::plot_crop(fn2)

fn3 <- here("images", "nonlinear-contour.pdf")
pdf(fn3, width = 3.2, height = 2.8, pointsize = 7)
filled.contour(beta_seq, alpha_seq, z, color.palette = pal, key.border = NA)
dev.off()
knitr::plot_crop(fn3)

Heval_df <- cbind(expand.grid(alpha_seq, beta_seq), as.vector(Heval))
colnames(Heval_df) <- c("alpha", "beta", "H")

# p <- ggplot(Heval_df, aes(alpha, beta, fill = H)) + 
# 
#   geom_raster() +
#   scale_fill_continuous(type = "viridis") +
#   geom_contour(color = "white", aes(z = H), binwidth = 0.1) +
#   coord_cartesian(xlim = c(-2, 2), ylim = c(8,12), expand = FALSE) +
#   xlab(quote(alpha)) + ylab(quote(beta))
# p


# alpha_seq <- seq(-0.5, 0.25, 0.005)
# beta_seq <- seq(8, 12, 0.02)
# z <- outer(alpha_seq, beta_seq, Vectorize(function(a, b) H(c(a, b))))

# plot_ly(x = ~beta_seq, y = ~alpha_seq, z = ~Heval2, colors = viridis(100)) %>% add_surface() %>% 
#  layout(scene = list(aspectmode = "manual", aspectratio = list(x=1, y=1, z=1), 
#                       camera = list(eye = list(x = 1, y = 1, z = 1))))

par <- runif(2)
# numDeriv::grad(H, par)
# grad(par)

i <- sample(N, 50)
# numDeriv::grad(Loss(osc[i, ], f, df)$loss, par)
# grad_batch(par, i)

gamma <- 1e-2
par_init <- expand.grid(
  alpha = c(-1.5, -1, -0.5, 0, 0.5, 1, 1.5),
  beta = c(8.4, 8.8, 9.3, 10.7, 11.2, 11.6)
) %>% as.matrix()
SG_tracer <- tracer(c("value", "par"), Delta = 50, expr = quote(value <- H(par)))

set.seed(123)

paths <- vector("list", nrow(par_init))

for(i in 1:nrow(par_init)) {
  SG(par_init[i, ], grad = grad_batch, N = N, gamma = gamma, cb = SG_tracer$tracer)
  SG_trace_batch <- summary(SG_tracer)
  SG_tracer$clear()
  SG(par_init[i, ], grad = grad_batch, epoch = momentum(), N = N, gamma = gamma, cb = SG_tracer$tracer)
  SG_trace_momentum <- summary(SG_tracer)
  SG_tracer$clear()
  SG(par_init[i, ], grad = grad_batch, epoch = adam(), N = N, gamma = 0.1 * gamma, cb = SG_tracer$tracer)
  SG_trace_adam <- summary(SG_tracer)
  SG_tracer_comb <- bind_rows(batch = SG_trace_batch,  
                              momentum = SG_trace_momentum, 
                              adam = SG_trace_adam,
                              .id = "Alg")
  SG_tracer_comb$init <- i
  paths[[i]] <- SG_tracer_comb
  SG_tracer$clear()
}

SG_tracer_comb <- do.call(bind_rows, paths)

# comb <- bind_cols(par_init, init = 1:42) |>
#   right_join(SG_tracer_comb)

bind_cols(par_init, init = 1:42) %>% 
  right_join(SG_tracer_comb) %>% 
  ggplot(aes(x = .time, y = par.alpha, color = Alg, group = interaction(Alg, init))) +
  geom_line(size = 1) +
  facet_grid(vars(alpha), vars(beta), scales = "free_y", 
             labeller = label_bquote(rows = paste(alpha, " = ", .(alpha)), cols = paste(beta, " = ", .(beta)))) + 
  coord_cartesian(xlim = c(0, 0.025)) +
  scale_x_continuous("time", breaks = c(0, 0.01, 0.02)) +
  scale_y_continuous(quote(alpha))

bind_cols(par_init, init = 1:42) %>% 
  right_join(SG_tracer_comb) %>% 
ggplot(aes(x = .time, y = par.beta, color = Alg, group = interaction(Alg, init))) +
  geom_line(size = 1) +
  facet_grid(vars(beta), vars(alpha), scales = "free_y", 
             labeller = label_bquote(cols = paste(alpha, " = ", .(alpha)), rows = paste(beta, " = ", .(beta)))) + 
  coord_cartesian(xlim = c(0, 0.025)) +
  scale_x_continuous("time", breaks = c(0, 0.01, 0.02)) +
  scale_y_continuous(quote(beta))

p + geom_path(data = SG_tracer_comb, mapping = aes(x = par.alpha, y = par.beta, fill = NULL, color = Alg, group = interaction(Alg, init)), 
              size = 1, arrow = arrow(length = unit(0.015, "npc")))


# filled.contour(beta_seq, alpha_seq, z, color.palette = pal, key.border = NA)

cols <- c("steelblue4", "dark orange", "black")
algs <- c("ADAM", "momentum", "batch")

init <- c(1, 5, 10, 15, 20, 25, 30, 42)

fn4base <- here("images", "nonlinear-convergence-")

for (k in seq_along(init)) {
  s <- init[k]
  fn4 <- paste0(fn4base, k - 1, ".pdf")
  pdf(fn4, width = 6, height = 3.5, pointsize = 8)
  par(mfrow = c(1, 3))
  for (i in seq_along(algs)) {
    contour(alpha_seq, beta_seq, z, drawlabels = FALSE, col = "dark grey", main = algs[i])
    alg <- tolower(algs[i[]])
    dd <- filter(SG_tracer_comb, Alg == alg, init == s)
    points(dd$par.alpha[1], dd$par.beta[1], col = cols[i])
    lines(dd$par.alpha, dd$par.beta, col = cols[i])
    points(dd$par.alpha[nrow(dd)], dd$par.beta[nrow(dd)], pch = 19, col = cols[i])
  }
  par(mfrow = c(1, 1))
  dev.off()
  knitr::plot_crop(fn4)
}

