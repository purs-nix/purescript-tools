{ pkgs, purs-nix, system }:
with builtins;
let
  p = pkgs;
  l = p.lib;

  src = fetchGit {
    url = "https://github.com/nwolverson/purescript-language-server.git";
    rev = "5c5754af5cee3f6f47934941ebcb178a50d789e2";
  };

  purs-nix' = purs-nix {
    inherit pkgs system;
    overlays = [
      (_: _: {
        foreign-generic = {
          src.git = {
            repo = "https://github.com/working-group-purescript-es/purescript-foreign-generic.git";
            rev = "53410dd57e9b350d6c233f48f7aa46317c4faa21";
          };
          info = {
            dependencies = [
              "effect"
              "exceptions"
              "foreign"
              "foreign-object"
              "identity"
              "ordered-collections"
              "record"
            ];
          };
        };
        literals = {
          src.git = {
            repo = "https://github.com/ilyakooo0/purescript-literals.git";
            rev = "6875fb28026595cfb780318305a77e79b098bb01";
          };
          info = {
            dependencies = [
              "integers"
              "maybe"
              "numbers"
              "partial"
              "prelude"
              "typelevel-prelude"
              "unsafe-coerce"
            ];
          };
        };
        psc-ide = {
          src.git = {
            repo = "https://github.com/kritzcreek/purescript-psc-ide";
            rev = "5cc2cd48d067f72a760b970080d0ef0a4b427fdf";
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
          };
        };
      })
    ];
  };

  ps = purs-nix'.purs {
    dependencies = [
      "aff"
      "aff-promise"
      "argonaut"
      "argonaut-codecs"
      "argonaut-core"
      "arrays"
      "avar"
      "bifunctors"
      "console"
      "contravariant"
      "control"
      "datetime"
      "effect"
      "either"
      "enums"
      "exceptions"
      "foldable-traversable"
      "foreign"
      "foreign-generic"
      "foreign-object"
      "integers"
      "js-date"
      "js-timers"
      "language-cst-parser"
      "lists"
      "literals"
      "maybe"
      "newtype"
      "node-buffer"
      "node-child-process"
      "node-fs"
      "node-path"
      "node-process"
      "node-streams"
      "nonempty"
      "nullable"
      "ordered-collections"
      "parallel"
      "prelude"
      "profunctor"
      "profunctor-lenses"
      "psc-ide"
      "refs"
      "spec"
      "strings"
      "stringutils"
      "test-unit"
      "transformers"
      "tuples"
      "unsafe-coerce"
      "untagged-union"
      "uuid"
      "node-os"
      "node-event-emitter"
    ];

    foreign =
      let
        node_modules = p.importNpmLock.buildNodeModules
          {
            npmRoot = src;
            inherit (p) nodejs;
          } + /node_modules;
      in
      l.genAttrs [
        "Data.UUID"
        "IdePurescript.Exec"
        "LanguageServer.IdePurescript.Build"
        "LanguageServer.Protocol.Handlers"
        "LanguageServer.Protocol.Setup"
        "LanguageServer.Protocol.Uri"
        "LanguageServer.Protocol.Workspace"
        "Node.Which"
      ]
        (_: { inherit node_modules; });
    dir = src;
  };

  package-json = l.importJSON "${src}/package.json";
in
p.stdenv.mkDerivation {
  pname = package-json.name;
  version = package-json.version;
  inherit src;
  buildInputs = [
    p.nodejs
    (ps.command {
      bundle = {
        esbuild = {
          "banner:js" = "#!${l.getExe p.nodejs}";
          outfile = "purescript-language-server";
          platform = "node";
        };
        module = "LanguageServer.IdePurescript.Main";
      };
    })
  ];
  buildPhase = ''
    purs-nix bundle
    chmod +x purescript-language-server
  '';
  installPhase = ''
    mkdir -p $out/bin
    mv purescript-language-server $out/bin
  '';
}
