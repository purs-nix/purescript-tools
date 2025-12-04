{ pkgs ? import <nixpkgs> { }, system ? pkgs.stdenv.hostPlatform.system }:

let
  version = "v0.15.9";

  urls = {
    "x86_64-linux" = {
      url = "https://github.com/purescript/purescript/releases/download/${version}/linux64.tar.gz";
      sha256 = "0rabinklsd8bs16f03zv7ij6d1lv4w2xwvzzgkwc862gpqvz9jq3";
    };
    "x86_64-darwin" = {
      url = "https://github.com/purescript/purescript/releases/download/${version}/macos.tar.gz";
      sha256 = "1xxg79rlf7li9f73wdbwif1dyy4hnzpypy6wx4zbnvap53habq9f";
    };
    "aarch64-darwin" = {
      url = "https://github.com/purescript/purescript/releases/download/${version}/macos-arm64.tar.gz";
      sha256 = "16ci26pgrw0zmnyn1zj129y9624cqwzrhqglc8mgfg4k7rxvqy2a";
    };
  };

  src =
    if builtins.hasAttr system urls then
      (pkgs.fetchurl urls.${system})
    else
      throw "Architecture not supported: ${system}";
in
import ./mkPursDerivation.nix {
  inherit pkgs version src;
}
