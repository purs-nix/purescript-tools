{ pkgs }:

pkgs.stdenv.mkDerivation rec {
  pname = "zephyr";

  version = "0.4.1";

  src =
    if pkgs.stdenv.isDarwin then
      pkgs.fetchurl
        {
          url = "https://github.com/MaybeJustJames/zephyr/releases/download/v${version}/macOS.tar.gz";
          hash = "sha256-noKIwwYwlqezbgch1qe97II+W/CUbN14Lp6HgMPpjYM=";
        }
    else
      pkgs.fetchurl {
        url = "https://github.com/MaybeJustJames/zephyr/releases/download/v${version}/Linux.tar.gz";
        hash = "sha256-XSO7DbEtLvGPQ2fxRYw4K0N0ofmMq6WXzbYGrJDfYd8=";
      };

  nativeBuildInputs = pkgs.lib.optional pkgs.stdenv.isDarwin pkgs.fixDarwinDylibNames;

  buildInputs = [
    pkgs.stdenv.cc.cc.lib
    pkgs.gmp
    pkgs.zlib
    pkgs.ncurses6
  ];

  libPath = pkgs.lib.makeLibraryPath buildInputs;

  dontStrip = true;

  unpackPhase = ''
    mkdir -p $out/bin
    tar xf $src --strip 1 -C $out

    ZEPHYR=$out/bin/zephyr
    install -D -m555 -T $out/zephyr $ZEPHYR

    chmod u+w $ZEPHYR
  '' + pkgs.lib.optionalString (!pkgs.stdenv.isDarwin) ''
    patchelf --interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" --set-rpath ${libPath} $ZEPHYR
  '' + ''
    chmod u-w $ZEPHYR

    mkdir -p $out/etc/bash_completion.d/
    $ZEPHYR --bash-completion-script $ZEPHYR > $out/etc/bash_completion.d/zephyr-completion.bash
  '';

  dontInstall = true;
}
