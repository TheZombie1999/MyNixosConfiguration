{ config, pkgs, ... }:

{
  # home.file."alacritty.toml" = {
  #   source = ./alacritty.toml ;
  #   target = ".config/alacritty/alacrity.toml";
  # };

  home.packages = [
    pkgs.nerd-fonts.fira-code
  ];

  programs.alacritty.enable = true;
  programs.alacritty.settings = {
    # font = {
    #   normal = {
    #     family = "FiraMono Code Nerd Font";
    #     style = "Regular";
    #   };
    #   builtin_box_drawing = true;
    # };

    window = {
      decorations = "Full";
      padding = {
        x = 10;
        y = 10;
      };
      dynamic_title = true;
    };
    mouse = {
      hide_when_typing = true;
    };

    cursor = {
      style = {
        shape = "Block";
        blinking = "On";
      };
    };

    colors = {
      primary = {
        background = "#${config.colorScheme.palette.base00}";
        foreground = "#${config.colorScheme.palette.base05}";
      };
    };
  };
}
