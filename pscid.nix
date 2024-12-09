{ pkgs, purs-nix, system }:
with builtins;
let
  p = pkgs;
  l = p.lib;

  src = fetchGit {
    url = "https://github.com/kritzcreek/pscid.git";
    rev = "15fbe136765abde38b0421dd3f52679a28de59d4";
  };

  node_modules = (import ./lib.nix p).node_modules src;

  purs-nix' = purs-nix {
    inherit pkgs system;

    overlays = [
      (_: _: {
        node-child-process = {
          src.git = {
            repo = "https://github.com/purescript-node/purescript-node-child-process.git";
            rev = "ceaa5dcd21697da24a916b81c73ba013592cf378";
          };
          info = {
            version = "9.0.0";
            dependencies = [
              "exceptions"
              "foreign"
              "foreign-object"
              "functions"
              "node-fs"
              "node-streams"
              "nullable"
              "posix-types"
              "unsafe-coerce"
            ];
          };
        };
        node-fs-aff = {
          src.git = {
            repo = "https://github.com/purescript-node/purescript-node-fs-aff.git";
            rev = "5ed121e14bdc7000a93b7768865ef912c21927b7";
          };
          info = {
            version = "9.2.0";
            dependencies = [ "aff" "either" "node-fs" "node-path" ];
          };
        };
        node-fs = {
          src.git = {
            repo = "https://github.com/purescript-node/purescript-node-fs.git";
            rev = "24fc929abaf59835cb185cdb5ba6f323c1e43c18";
          };
          info = {
            version = "8.2.0";
            dependencies = [
              "datetime"
              "effect"
              "either"
              "enums"
              "exceptions"
              "functions"
              "integers"
              "js-date"
              "maybe"
              "node-buffer"
              "node-path"
              "node-streams"
              "nullable"
              "partial"
              "prelude"
              "strings"
              "unsafe-coerce"
            ];
          };
        };
        node-process = {
          src.git = {
            repo = "https://github.com/purescript-node/purescript-node-process.git";
            rev = "9d126d9d4f898723e7cab69895770bbac0c3a0b8";
          };
          info = {
            version = "10.0.0";
            dependencies = [
              "effect"
              "foreign-object"
              "maybe"
              "node-streams"
              "posix-types"
              "prelude"
              "unsafe-coerce"
            ];
          };
        };
        node-streams = {
          src.git = {
            repo = "https://github.com/purescript-node/purescript-node-streams.git";
            rev = "8395652f9f347101fe042f58726edc592ae5086c";
          };
          info = {
            version = "7.0.0";
            dependencies = [
              "effect"
              "either"
              "exceptions"
              "node-buffer"
              "nullable"
              "prelude"
            ];
          };
        };
        optparse = {
          src.git = {
            repo = "https://github.com/f-o-a-m/purescript-optparse.git";
            rev = "dbc4c385e6c436eed4299ae2c0bb2cc278cf2410";
          };
          info = {
            version = "5.0.0";
            dependencies = [
              "aff"
              "arrays"
              "bifunctors"
              "console"
              "control"
              "effect"
              "either"
              "enums"
              "exists"
              "exitcodes"
              "foldable-traversable"
              "free"
              "gen"
              "integers"
              "lazy"
              "lists"
              "maybe"
              "newtype"
              "node-buffer"
              "node-process"
              "node-streams"
              "nonempty"
              "numbers"
              "open-memoize"
              "partial"
              "prelude"
              "quickcheck"
              "strings"
              "tailrec"
              "transformers"
              "tuples"
            ];
          };
        };
        psc-ide = {
          src.git = {
            repo = "https://github.com/kRITZCREEK/purescript-psc-ide.git";
            rev = "ccd4260b9b5ef8903220507719374a70ef2dd8f1";
          };
          info = {
            version = "19.0.0";
            dependencies =
              [
                "aff"
                "argonaut"
                "arrays"
                "console"
                "maybe"
                "node-child-process"
                "node-fs"
                "parallel"
                "random"
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

  ps = purs-nix'.purs {
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
  version = package-json.version;
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
