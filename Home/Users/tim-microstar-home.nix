{ nix-colors, ... }:
{
  imports = [
    nix-colors.homeManagerModules.default
    ../Common
    ../Backgrounds
  ];

  home.username = "tim";
  home.homeDirectory = "/home/tim";
  home.stateVersion = "22.05"; # Please read the comment before changing.
  programs.home-manager.enable = true;
  colorScheme = nix-colors.colorSchemes.gruvbox-dark-hard;
}
