{ pkgs, ... }:
# let
# pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
# in
{
  packages = with pkgs; [
    pre-commit
    nixfmt
    statix
    deadnix
  ];

  enterShell = ''
    pre-commit install
  '';
}
