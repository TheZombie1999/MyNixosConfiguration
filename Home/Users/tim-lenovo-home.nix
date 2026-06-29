let
  nix-colors = import <nix-colors> { };
  default = rec {
    imports = [
      nix-colors.homeManagerModules.default
      ../Common
      # ../Personal
      # ../Scripts
      ../Backgrounds
    ];

    Picom = true;

    programs.bash.initExtra = ''
      setxkbmap de
    '';
    home.username = "tim";
    home.homeDirectory = "/home/tim";

    home.stateVersion = "23.11"; # Please read the comment before changing.
    programs.home-manager.enable = true;

    services.grobi.enable = true;

    services.grobi.rules = [
      {
        name = "Home";
        outputs_connected = [ "DP-1-2" ];
        configure_single = "DP-1-2";
      }
      {
        name = "Home";
        outputs_connected = [ "DP-1-1" ];
        configure_single = "DP-1-1";
      }
      {
        name = "Mobile";
        outputs_connected = [ "eDP-1" ];
        configure_single = "eDP-1";
      }
      {
        name = "Fallback";
        configure_single = "eDP-1";
      }
    ];
  };
in
{
  light =
    { ... }:
    default
    // {
      colorScheme = nix-colors.colorSchemes.github;
      DarkMode = false;
    };
  dark =
    { ... }:
    default
    // {
      colorScheme = nix-colors.colorSchemes.gruvbox-dark-hard;
      DarkMode = true;
    };
}
