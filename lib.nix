p:
with builtins; {
  make-completion = command: subcommands:
    let
      file =
        p.writeText "${command}-completion"
          ''complete -W "${toString subcommands}" ${command}'';
    in
    ''
      mkdir -p $out/share/bash-completion/completions
      ln -s ${file} "$_"/${command}
    '';

  node_modules = src: p.importNpmLock.buildNodeModules
    {
      npmRoot = src;
      package = removeAttrs (p.lib.importJSON "${src}/package.json") [ "devDependencies" ];
      inherit (p) nodejs;
    } + /node_modules;
}
