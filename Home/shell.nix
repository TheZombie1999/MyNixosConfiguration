let
  # nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-23.11";
  pkgs = import <nixpkgs> { };
in

pkgs.mkShellNoCC {
  packages = with pkgs; [
    helix
    gitui
  ];
}
