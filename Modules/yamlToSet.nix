pkgs: path:
(builtins.fromJSON (
  builtins.readFile (
    pkgs.runCommand "yaml-to-json" { } ''
      ${pkgs.yq-go}/bin/yq eval -o=json ${path} > $out
    ''
  )
))
