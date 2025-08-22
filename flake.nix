{
  description = "A basic flake with a shell";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.systems.url = "github:nix-systems/default";
  inputs.flake-utils = {
    url = "github:numtide/flake-utils";
    inputs.systems.follows = "systems";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        CSwR = pkgs.rPackages.buildRPackage {
          name = "CSwR";
          src = "${
            pkgs.fetchFromGitHub {
              owner = "nielsrhansen";
              repo = "CSwR";
              rev = "698e2c8d3d59d9320bc2f1c4f9484d272f64d3d8";
              hash = "sha256-HHvKHXsfqQTfgKkipUPnI1h+XcyDykvv7BjkMtKG0hA=";
              sparseCheckout = [
                "CSwR_package"
              ];
            }
          }/CSwR_package";
          propagatedBuildInputs = with pkgs.rPackages; [
            ggplot2
            rlang
            bench
          ];
        };
        R = pkgs.rWrapper.override {
          packages = with pkgs.rPackages; [
            bench
            CSwR
            lme4
            Matrix
            mvtnorm
            numDeriv
            patchwork
            profvis
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
            animate
            here
            dqrng
            usethis
            languageserver
            devtools
            testthat
            future
          ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.bashInteractive
            R
            pkgs.quartoMinimal
            pkgs.go-task
            pkgs.ungoogled-chromium
            pkgs.librsvg
          ];
        };
      }
    );
}
