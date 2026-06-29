{ pkgs, ... }:

let
  stable = import <nixpkgs-stable> { };
in
{
  home.packages = with pkgs; [
    # rauc
    duf # Disk Usage
    sonar-scanner-cli # Scanning Software
    editorconfig-checker # Check .editorConfig
    stable.jetbrains.clion
    asciinema
    ansible
  ];

  nix = {
    package = pkgs.nix;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
