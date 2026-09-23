{
  pkgs ? import <nixpkgs> { },
}:

let
  git-shell-commands = pkgs.callPackage ./package.nix { };
in
pkgs.mkShell {
  packages = [ git-shell-commands ];
}
