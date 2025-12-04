{
  inputs = {
    lint-utils = {
      url = "github:homotopic/lint-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs:
    with builtins;
    inputs.utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ]
      (system:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
          l = pkgs.lib;
          p = pkgs;
          # we can't use a normal input because these flakes depend on each other
          # doing so would cause the flake.lock to grow with every update
          purs-nix = getFlake "github:purs-nix/purs-nix/7bdc233f02c8467250ec90c4bccfe8c45ae5d804";
          lu-pkgs = inputs.lint-utils.packages.${system};
        in
        rec {
          legacyPackages =
            let
              purescripts =
                listToAttrs
                  (map
                    (file:
                      let
                        package-name =
                          l.pipe file
                            [
                              (l.removeSuffix ".nix")
                              (replaceStrings [ "." ] [ "_" ])
                              (a: "purescript-${a}")
                            ];
                      in
                      l.nameValuePair
                        package-name
                        (import (./. + "/purescript/${file}") { inherit pkgs; })
                    )
                    (l.pipe ./purescript
                      [
                        readDir
                        (a: removeAttrs a [ "LICENSE" "mkPursDerivation.nix" ])
                        attrNames
                      ]));

              common = with packages; {
                inherit
                  psa
                  pscid
                  purescript-backend-optimizer
                  purescript-language-server
                  purs-tidy;
              };

              for-0_15 =
                with packages; {
                  purescript = purescript-0_15;
                  zephyr = zephyr-0_5;
                } // common;

              for-0_14 = with packages;
                {
                  purescript = purescript-0_14;
                  zephyr = zephyr-0_4;
                } // common;

              for-0_13 =
                with packages; {
                  purescript = purescript-0_13;
                  zephyr = zephyr-0_4;
                } // common;

              packages = rec {
                psa = import ./psa.nix { inherit pkgs purs-nix system; };
                pscid = import ./pscid.nix { inherit pkgs purs-nix system; };

                purescript-backend-optimizer =
                  import ./purescript-backend-optimizer.nix { inherit pkgs purs-nix system; };

                purescript = purescript-0_15;
                purescript-0_15 = purescripts.purescript-0_15_15;
                purescript-0_14 = purescripts.purescript-0_14_9;
                purescript-0_13 = purescripts.purescript-0_13_8;

                purescript-language-server =
                  import ./purescript-language-server.nix { inherit pkgs purs-nix system; };

                purs-tidy =
                  import ./purs-tidy.nix {
                    pbo = purescript-backend-optimizer;
                    inherit pkgs purs-nix system;
                  };

                zephyr = zephyr-0_5;
                zephyr-0_5 = import ./zephyr/0.5.nix { inherit pkgs; };
                zephyr-0_4 = import ./zephyr/0.4.nix { inherit pkgs; };
              } // purescripts;
            in
            { inherit for-0_15 for-0_14 for-0_13; }
            // packages;

          checks =
            let
              packages-for-version = version:
                let name = "packages for version ${version}"; in {
                  ${name} =
                    p.runCommand name
                      {
                        buildInputs =
                          attrValues
                            legacyPackages."for-${replaceStrings [ "." ] [ "_" ] version}";
                      }
                      ''
                        echo psa
                        psa --version

                        echo pscid
                        pscid --version

                        echo purescript-language-server
                        purescript-language-server --version

                        echo purs-backend-es
                        purs-backend-es --version

                        echo purs
                        purs --version

                        echo purs-tidy
                        purs-tidy --version

                        echo zyphyr
                        zephyr --version

                        touch $out
                      '';
                };

              lu = inputs.lint-utils.linters.${system};
            in
            {
              deadnix = lu.deadnix { src = ./.; };
              formatting = lu.nixpkgs-fmt { src = ./.; };
              statix = lu.statix { src = ./.; };

              "everything builds" =
                p.runCommand "build-everything" { }
                  (l.concatMapStringsSep "\n"
                    (a: "echo ${a.outPath or ""}; touch $out")
                    (attrValues legacyPackages.for-0_15
                    ++ attrValues legacyPackages.for-0_14
                    ++ attrValues legacyPackages.for-0_13
                    ++ attrValues legacyPackages));
            }
            // packages-for-version "0.15"
            // packages-for-version "0.14"
            // packages-for-version "0.13";

          devShells.default =
            p.mkShell {
              packages = [ p.deadnix ] ++ [ legacyPackages.purescript-language-server ];
            };

          formatter = lu-pkgs.nixpkgs-fmt;
        });
}
