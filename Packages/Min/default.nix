{
  pkgs ? import <nixpkgs> { },
}:

{
  min = pkgs.callPackage ./min.nix { nodejs = pkgs.nodejs_18; };
}
