{
  pkgs,
  ...
}:

{
  packages = [
    pkgs.git
    pkgs.bashInteractive
    pkgs.go-task
    pkgs.librsvg
    pkgs.quartoMinimal
    pkgs.texliveFull
    pkgs.arity
    (pkgs.rstudioWrapper.override {
      packages = with pkgs.rPackages; [
        Rcpp
        RcppArmadillo
        RcppEigen
        devtools
        knitr
        numDeriv
        rmarkdown
        testthat
        tidyverse
        usethis
        roxygen2
      ];
    })
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
          cyclocomp
        ];
      };
    };
  };

  git-hooks.hooks = {
    panache-format.enable = true;
  };
}
