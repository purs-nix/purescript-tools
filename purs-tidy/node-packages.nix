# This file has been generated by node2nix 1.9.0. Do not edit!

{nodeEnv, fetchurl, fetchgit, nix-gitignore, stdenv, lib, globalBuildInputs ? []}:

let
  sources = {
    "purs-tidy-0.11.0" = {
      name = "purs-tidy";
      packageName = "purs-tidy";
      version = "0.11.0";
      src = fetchurl {
        url = "https://registry.npmjs.org/purs-tidy/-/purs-tidy-0.11.0.tgz";
        sha512 = "HZ8AS6J7Ka2YVl6Gr/H5NV17TU10yGYUTxVwRd5tKuwsVdFZewXSzZ/HTpWrkhdR2gxSVk0BdnpJhyu//oRc+w==";
      };
    };
  };
  args = {
    name = "purs-tidy";
    packageName = "purs-tidy";
    version = "0.11.0";
    src = ./.;
    dependencies = [
      sources."purs-tidy-0.11.0"
    ];
    buildInputs = globalBuildInputs;
    meta = {
    };
    production = true;
    bypassCache = true;
    reconstructLock = true;
  };
in
{
  args = args;
  sources = sources;
  tarball = nodeEnv.buildNodeSourceDist args;
  package = nodeEnv.buildNodePackage args;
  shell = nodeEnv.buildNodeShell args;
  nodeDependencies = nodeEnv.buildNodeDependencies (lib.overrideExisting args {
    src = stdenv.mkDerivation {
      name = args.name + "-package-json";
      src = nix-gitignore.gitignoreSourcePure [
        "*"
        "!package.json"
        "!package-lock.json"
      ] args.src;
      dontBuild = true;
      installPhase = "mkdir -p $out; cp -r ./* $out;";
    };
  });
}
