{ pkgs, system, ... }@args:
with builtins;
let
  p = pkgs;
  l = p.lib;

  src = fetchGit {
    url = "https://github.com/aristanetworks/purescript-backend-optimizer.git";
    rev = "cd03c12e82ec80be45fbb0810e3fb9a312752512";
  };

  purs-nix = args.purs-nix {
    inherit pkgs system;

    overlays = [
      (_: _: {
        dodo-printer.src.registry.version = "2.2.1";
        node-child-process.src.registry.version = "9.0.0";
        node-fs-aff.src.registry.version = "9.1.0";
        node-fs.src.registry.version = "8.1.0";

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

        node-process.src.registry.version = "10.0.0";
        node-streams.src.registry.version = "7.0.0";
      })
    ];
  };

  ps = purs-nix.purs {
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
  inherit (package-json) version;
  inherit src;
  buildInputs = [ p.nodejs purs-nix.esbuild ];
  buildPhase = ''
    ln -s ${ps.output { codegen = "corefn,js"; }} output
    node ./backend-es/index.dev.js bundle-module --int-tags -p node -t backend-es/bundle/index.js -y
  '';
  installPhase = ''
    mkdir -p $out/{bin,lib}
    cd backend-es
    mv bundle index.js package.json runtime.js $out/lib
    ln -s $out/lib/index.js $out/bin/purs-backend-es
  '';
}
