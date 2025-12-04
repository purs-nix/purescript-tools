{ pbo, pkgs, system, ... }@args:
with builtins;
let
  p = pkgs;
  l = p.lib;

  src = fetchGit {
    url = "https://github.com/natefaubion/purescript-tidy.git";
    rev = "635958a17562b41f082f817fee419d133dfbb147";
  };

  purs-nix = args.purs-nix { inherit pkgs system; };

  ps = purs-nix.purs {
    dependencies =
      let
        deps = p.runCommand "dependencies" { }
          ''
            cp -r ${src}/. .
            ${l.getExe p.jq} -s '[.[].package.dependencies[] | keys[0]]
                                 | unique' \
                             <(${l.getExe p.yaml2json} < spago.yaml) \
                             <(${l.getExe p.yaml2json} < bin/spago.yaml) \
              > $out
          '';
      in
      filter (d: d != "tidy") (l.importJSON deps);

    dir = src;
    srcs = [ "src" "bin" ];
  };

  package-json = l.importJSON "${src}/package.json";
in
p.stdenvNoCC.mkDerivation {
  pname = package-json.name;
  inherit (package-json) version;
  inherit src;
  buildInputs = [ pbo p.nodejs purs-nix.esbuild ];
  buildPhase = ''
    ln -s ${ps.output { codegen = "corefn"; }} output
    purs-backend-es build --int-tags
    purs-backend-es bundle-module -p node -t bundle/Bin.Worker/index.js -m Bin.Worker -s -y
    purs-backend-es bundle-module -p node -t bundle/Main/index.js -s -y
  '';
  installPhase = ''
    mkdir -p $out/{bin,lib}
    cp -r bin bundle package.json $out/lib
    ln -s $out/lib/bin/index.js $out/bin/purs-tidy
  '';
}
