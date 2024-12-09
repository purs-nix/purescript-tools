{ pkgs, purs-nix, system }:
with builtins;
let
  p = pkgs;
  l = p.lib;

  src = fetchGit {
    url = "https://github.com/natefaubion/purescript-psa.git";
    rev = "c0e787386dfdb9ccbc943d84711f420ee1dcd80e";
  };

  node_modules = (import ./lib.nix p).node_modules src;

  purs-nix' = purs-nix { inherit pkgs system; };

  ps = purs-nix'.purs {
    dependencies = [
      "console"
      "effect"
      "prelude"
      "node-fs"
      "node-buffer"
      "node-child-process"
      "node-process"
      "node-streams"
      "st"
      "foreign-object"
      "now"
      "datetime"
      "psa-utils"
      "refs"
      "ordered-collections"
      "versions"
      "debug"
    ];

    dir = src;
  };

  package-json = l.importJSON "${src}/package.json";
in
p.stdenvNoCC.mkDerivation {
  pname = package-json.name;
  version = package-json.version;
  inherit src;
  buildPhase =
    let
      bundle = ps.bundle {
        esbuild = {
          "banner:js" = "#!${l.getExe p.nodejs}";
          outfile = "psa";
          platform = "node";
        };
      };
    in
    ''
      cp ${bundle} psa
      chmod +x psa
    '';
  installPhase = ''
    mkdir -p $out/bin
    mv psa $out/bin
  '';
}
