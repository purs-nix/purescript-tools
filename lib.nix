p:
with builtins; {
  node_modules = src: p.importNpmLock.buildNodeModules
    {
      npmRoot = src;
      package = removeAttrs (p.lib.importJSON "${src}/package.json") [ "devDependencies" ];
      inherit (p) nodejs;
    } + /node_modules;
}
