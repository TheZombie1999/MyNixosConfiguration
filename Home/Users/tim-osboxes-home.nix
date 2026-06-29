let
  nix-colors = import <nix-colors> { };
  default = rec {
    imports = [
      nix-colors.homeManagerModules.default
      ../Common
      # ../Personal
      ../Scripts
      ../Backgrounds
    ];
    # colorScheme = nix-colors.colorSchemes.github;

    programs.bash.initExtra = ''
      setxkbmap de
      ssh-add ~/Github/MyHomeConfiguration/Keys/osboxes_ubuntu_rsa 2> /dev/null 1> /dev/null
      if ! mountpoint -q /home/${default.home.username}/MyFiles; then
        mkdir -p /home/${default.home.username}/MyFiles
        sudo mount -t vboxsf -o rw,uid=1000,gid=1000 myf /home/${default.home.username}/MyFiles
      fi
    '';

    # wayland.windowManager.hyprland.enable = true;

    home.username = "tim";
    home.homeDirectory = "/home/tim";

    home.stateVersion = "23.11"; # Please read the comment before changing.
    programs.home-manager.enable = true;
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

# { config, pkgs, ... }:

# let
#   nix-colors = import <nix-colors> { };
# in
# {
#   # imports = [
#   #   nix-colors.homeManagerModules.default
#   #   ../Common
#   #   # ../Personal
#   #   ../Scripts
#   # ];

#   colorScheme = nix-colors.colorSchemes.github;

#   programs.bash.initExtra = ''
#     setxkbmap de
#     ssh-add ~/Github/MyHomeConfiguration/Keys/osboxes_ubuntu_rsa
#     mkdir -p /home/${config.home.username}/MyFiles
#     sudo mount -t vboxsf -o rw,uid=1000,gid=1000 myf /home/${config.home.username}/MyFiles
#   '';

#   wayland.windowManager.hyprland.enable = true;

#   home.username = "tim";
#   home.homeDirectory = "/home/tim";

#   home.stateVersion = "23.11"; # Please read the comment before changing.
#   programs.home-manager.enable = true;
# }
