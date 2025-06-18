{ config, pkgs, ...}:

{
  # home.file."alacritty.toml" = {
  #   source = ./alacritty.toml ;
  #   target = ".config/alacritty/alacrity.toml";
  # };

  programs.alacritty.enable = true;
  programs.alacritty.settings = {
    font = {
      normal = {
        family = "Fira Code Nerd Font";
        style = "Regular";
      };
      builtin_box_drawing = true;
    };
  
    window = {
      decorations = "Full";
      padding = { x=10; y=10;};
      dynamic_title = true;
    };
    mouse = {
      hide_when_typing = true;
    };

    cursor = {
      style = { shape = "Block"; blinking="On"; };
    };

    colors = {
      primary = {
        background= "#${config.colorScheme.palette.base00}";
        foreground= "#${config.colorScheme.palette.base05}";
      };
    };
  };
}
