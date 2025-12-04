{ pkgs, system, ... }@args:
with builtins;
let
  p = pkgs;
  l = p.lib;

  src = fetchGit {
    url = "https://github.com/kritzcreek/pscid.git";
    rev = "15fbe136765abde38b0421dd3f52679a28de59d4";
  };

  node_modules = (import ./lib.nix p).node_modules src;

  purs-nix = args.purs-nix {
    inherit pkgs system;

    overlays = [
      (_: _: {
        node-child-process.src.registry.version = "9.0.0";
        node-fs-aff.src.registry.version = "9.2.0";
        node-fs.src.registry.version = "8.2.0";
        node-process.src.registry.version = "10.0.0";
        node-streams.src.registry.version = "7.0.0";
        optparse.src.registry.version = "5.0.0";
        psc-ide = {
          src.git = {
            repo = "https://github.com/kritzcreek/purescript-psc-ide";
            rev = "ccd4260b9b5ef8903220507719374a70ef2dd8f1";
          };
          info = {
            dependencies = [
              "aff"
              "argonaut"
              "argonaut-codecs"
              "argonaut-core"
              "arrays"
              "bifunctors"
              "control"
              "datetime"
              "effect"
              "either"
              "exceptions"
              "foldable-traversable"
              "foreign-object"
              "integers"
              "maybe"
              "node-buffer"
              "node-child-process"
              "node-fs"
              "node-path"
              "nullable"
              "parallel"
              "prelude"
              "random"
              "strings"
            ];

            foreign."Node.Which" = { inherit node_modules; };
          };
        };
        suggest = {
          src.git = {
            repo = "https://github.com/nwolverson/purescript-suggest.git";
            rev = "c866dd7408902313c45bb579715f479f7f268162";
          };
          info = {
            dependencies = [
              "argonaut-codecs"
              "argonaut-core"
              "arrays"
              "bifunctors"
              "console"
              "effect"
              "either"
              "foldable-traversable"
              "lists"
              "maybe"
              "node-buffer"
              "node-fs"
              "node-process"
              "node-streams"
              "ordered-collections"
              "prelude"
              "psa-utils"
              "refs"
              "strings"
            ];
          };
        };
      })
    ];
  };

  ps = purs-nix.purs {
    dependencies = [
      "aff"
      "ansi"
      "argonaut"
      "arrays"
      "bifunctors"
      "console"
      "control"
      "effect"
      "either"
      "exceptions"
      "foldable-traversable"
      "maybe"
      "node-buffer"
      "node-child-process"
      "node-fs"
      "node-process"
      "node-streams"
      "optparse"
      "ordered-collections"
      "partial"
      "prelude"
      "psa-utils"
      "psc-ide"
      "refs"
      "strings"
      "suggest"
      "transformers"
      "typelevel-prelude"
    ];

    foreign =
      l.genAttrs [
        "Pscid.Keypress"
        "Pscid.Options"
        "Main"
      ]
        (_: { inherit node_modules; });

    dir = src;
  };

  package-json = l.importJSON "${src}/package.json";
in
p.stdenvNoCC.mkDerivation {
  pname = package-json.name;
  inherit (package-json) version;
  inherit src;
  buildInputs = [ p.nodejs ];
  buildPhase = ''
    cp -r ${ps.output {}} output
    chmod -R +w output
  '';
  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/lib
    mv index.js output package.json $out/lib
    ln -s $out/lib/index.js $out/bin/pscid
  '';
}
