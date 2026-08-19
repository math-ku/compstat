{
  pkgs,
  ...
}:

{
  packages = [
    pkgs.git
    pkgs.arity
  ];

  # https://devenv.sh/languages/
  languages = {
    r = {
      enable = true;
      package = pkgs.rWrapper.override {
        packages = with pkgs.rPackages; [
          bench
          CSwR
          lme4
          Matrix
          plot3D
          mvtnorm
          numDeriv
          patchwork
          profvis
          reshape2
          Rcpp
          RcppArmadillo
          ggbeeswarm
          webshot2
          foreach
          movMF
          tidyverse
          knitr
          doParallel
          rmarkdown
          here
          dqrng
          usethis
          languageserver
          devtools
          testthat
          zeallot
          future
          cowplot
        ];
      };
    };
  };

  git-hooks.hooks = {
    panache-format.enable = true;
  };
}
