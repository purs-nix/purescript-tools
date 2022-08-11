{ inputs =
    { deadnix.url = "github:astro/deadnix";
      make-shell.url = "github:ursi/nix-make-shell/1";
      nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      utils.url = "github:ursi/flake-utils/8";
    };

  outputs = { utils, ... }@inputs:
    with builtins;
    utils.apply-systems
      { inherit inputs;
        systems = [ "x86_64-linux" "x86_64-darwin" ];
      }
      ({ deadnix, make-shell, pkgs, ... }:
         let l = pkgs.lib; p = pkgs; in
         rec
         { legacyPackages =
             let
               purescripts =
                 listToAttrs
                   (map
                      (file:
                         let
                           package-name =
                             l.pipe file
                               [ (l.removeSuffix ".nix")
                                 (replaceStrings [ "." ] [ "_" ])
                                 (a: "purescript-${a}")
                               ];
                         in
                         l.nameValuePair
                           package-name
                           (import (./. + "/purescript/${file}") { inherit pkgs; })
                      )
                      (l.pipe ./purescript
                         [ readDir
                           (a: removeAttrs a [ "mkPursDerivation.nix" ])
                           attrNames
                         ]
                      )
                   );

                 common =
                   with packages;
                   { inherit psa pscid purescript-language-server purs-tidy purty; };

                 for-0_15 =
                   with packages;
                   { pulp = pulp-16;
                     purescript = purescript-0_15;
                     zephyr = zephyr-0_5;
                   }
                   // common;

                 for-0_14 =
                   with packages;
                   { pulp = pulp-15;
                     purescript = purescript-0_14;
                     zephyr = zephyr-0_4;
                   }
                   // common ;

                 for-0_13 =
                   with packages;
                   { pulp = pulp-15;
                     purescript = purescript-0_13;
                     zephyr = zephyr-0_4;
                   }
                   // common;

               packages =
                 rec
                 { psa = import ./psa { inherit pkgs; };
                   pscid = import ./pscid { inherit pkgs; };
                   pulp = pulp-16;
                   pulp-16 = import ./pulp/16.0.0-0 { inherit pkgs; };
                   pulp-15 = import ./pulp/15.0.0 { inherit pkgs; };
                   purescript = purescript-0_15;
                   purescript-0_15 = purescripts.purescript-0_15_4;
                   purescript-0_14 = purescripts.purescript-0_14_9;
                   purescript-0_13 = purescripts.purescript-0_13_8;

                   purescript-language-server =
                     import ./purescript-language-server { inherit pkgs; };

                   purs-tidy = import ./purs-tidy { inherit pkgs; };
                   purty = import ./purty.nix { inherit pkgs; };
                   zephyr = zephyr-0_5;
                   zephyr-0_5 = import ./zephyr/0.5.nix { inherit pkgs; };
                   zephyr-0_4 = import ./zephyr/0.4.nix { inherit pkgs; };
                 }
                 // purescripts;
             in
             { inherit for-0_15 for-0_14 for-0_13; }
             // packages;

           checks =
             let
               packages-for-version = version:
                 let name = "packages for version ${version}"; in
                 { ${name} =
                      p.runCommand name
                        { buildInputs =
                            attrValues
                              legacyPackages
                                ."for-${replaceStrings [ "." ] [ "_" ] version}";
                        }
                        ''
                        echo psa
                        psa --version

                        echo pscid
                        pscid --version

                        echo purescript-language-server
                        purescript-language-server --version

                        echo pulp
                        pulp --version

                        echo purs
                        purs --version

                        echo purs-tidy
                        purs-tidy --version

                        echo purty
                        purty version

                        echo zyphyr
                        zephyr --version

                        touch $out
                        '';
                 };
             in
             { lint =
                 p.runCommand "lint" {}
                   ''
                   ${deadnix}/bin/deadnix -f \
                     $(find ${./flake.nix} ${./purescript}/* -name "*.nix")

                   touch $out
                   '';

               "everything builds" =
                  p.runCommand "build-everything" {}
                    (l.concatMapStringsSep "\n"
                       (a: "echo ${a.outPath or ""}; touch $out")
                       (attrValues legacyPackages.for-0_15
                       ++ attrValues legacyPackages.for-0_14
                       ++ attrValues legacyPackages.for-0_13
                       ++ attrValues legacyPackages
                       )
                    );
             }
             // packages-for-version "0.15"
             // packages-for-version "0.14"
             // packages-for-version "0.13";

           devShells.default =
             make-shell
               { packages = [ deadnix ] ++ [ legacyPackages.purescript-language-server ];
                 aliases.lint = ''deadnix flake.nix purescript/*'';
               };
         }
      )
      // { herculesCI.ciSystems = [ "x86_64-linux" ]; };
}
