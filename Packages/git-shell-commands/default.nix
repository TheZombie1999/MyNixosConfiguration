{
  pkgs ? import <nixpkgs> { },
}:

{
  git-shell-commands = pkgs.callPackage ./package.nix { };
}
