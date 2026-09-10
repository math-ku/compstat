{
  pkgs,
  ...
}:

let
  pandoc = pkgs.callPackage ./pandoc-bin.nix { };
  quarto = pkgs.quartoMinimal.override { inherit pandoc; };
  # Keep bench's GC records aligned with its measured iterations.
  benchPatched = pkgs.rPackages.bench.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./patches/bench-gc-records.patch ];
  });
in
{
  packages = [
    pkgs.git
    pkgs.bashInteractive
    pkgs.go-task
    pkgs.librsvg
    pandoc
    quarto
    pkgs.texliveFull
    (pkgs.rstudioWrapper.override {
      packages = with pkgs.rPackages; [
        benchPatched
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
          benchPatched
          svglite
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
          htmltools
          httr2
          xml2
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

  # git-hooks.hooks = {
  #   panache-format.enable = true;
  # };
}
