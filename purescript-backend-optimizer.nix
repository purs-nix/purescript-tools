{ pkgs, purs-nix, system }:
with builtins;
let
  p = pkgs;
  l = p.lib;

  src = fetchGit {
    url = "https://github.com/aristanetworks/purescript-backend-optimizer.git";
    rev = "cd03c12e82ec80be45fbb0810e3fb9a312752512";
  };

  node_modules = (import ./lib.nix p).node_modules "${src}/backend-es";

  purs-nix' = purs-nix {
    inherit pkgs system;

    overlays = [
      (_: _: {
        dodo-printer = {
          src.git = {
            repo = "https://github.com/natefaubion/purescript-dodo-printer.git";
            rev = "831c5c963a57ca4bfd62f96335267d7d0785851d";
          };
          info = {
            version = "2.2.1";
            dependencies = [
              "ansi"
              "foldable-traversable"
              "lists"
              "maybe"
              "strings"
            ];
          };
        };
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
            rev = "ac9b6fd272eb52c906b490be1c714423dd36a5bf";
          };
          info = {
            version = "9.1.0";
            dependencies = [ "aff" "either" "node-fs" "node-path" ];
          };
        };
        node-fs = {
          src.git = {
            repo = "https://github.com/purescript-node/purescript-node-fs.git";
            rev = "2629cb37c7a6987ed95401d55b64871b93a31c3e";
          };
          info = {
            version = "8.1.0";
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
        node-glob-basic = {
          src.git = {
            repo = "https://github.com/natefaubion/purescript-node-glob-basic.git";
            rev = "d20f2866c3bb472c68848be5b153e28933c07a38";
          };
          info = {
            version = "1.2.2";
            dependencies = [
              "aff"
              "console"
              "effect"
              "lists"
              "maybe"
              "node-fs-aff"
              "node-path"
              "node-process"
              "ordered-collections"
              "strings"
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
      })
    ];
  };

  ps = purs-nix'.purs {
    dependencies = [
      "aff"
      "ansi"
      "argonaut"
      "argparse-basic"
      "arrays"
      "bifunctors"
      "console"
      "control"
      "datetime"
      "debug"
      "dodo-printer"
      "effect"
      "either"
      "enums"
      "filterable"
      "foldable-traversable"
      "foreign-object"
      "integers"
      "language-cst-parser"
      "lazy"
      "lists"
      "maybe"
      "newtype"
      "node-buffer"
      "node-child-process"
      "node-fs"
      "node-fs-aff"
      "node-glob-basic"
      "node-path"
      "node-process"
      "node-streams"
      "now"
      "numbers"
      "ordered-collections"
      "orders"
      "parallel"
      "partial"
      "posix-types"
      "prelude"
      "refs"
      "safe-coerce"
      "st"
      "strings"
      "transformers"
      "tuples"
      "unsafe-coerce"
    ];

    dir = src;
    srcs = [ "src" "backend-es/src" ];
  };

  package-json = l.importJSON "${src}/backend-es/package.json";
in
p.stdenvNoCC.mkDerivation {
  pname = package-json.name;
  version = package-json.version;
  inherit src;
  buildInputs = [ p.nodejs purs-nix'.esbuild ];
  buildPhase = ''
    ln -s ${ps.output { codegen = "corefn,js"; }} output
    node ./backend-es/index.dev.js bundle-module -m Main --timing --int-tags --platform=node --minify --to=./backend-es/bundle/index.js
  '';
  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/lib
    cd backend-es
    mv bundle index.js package.json runtime.js $out/lib
    ln -s $out/lib/index.js $out/bin/purs-backend-es
  '';
}
