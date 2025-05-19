{ lib, config, ... }:

{

  options = {
    DarkMode = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = true;
      description = "Wheather the current theme is a Dark theme or not.";
    };
  };

  # home.file."config" = {
  #   source = ./config;
  #   target = ".config/i3/config";
  # };

  # client.focused          #504945 #504945 #ebdbb2 #2e9ef4   #285577
  # client.focused_inactive #1d2021 #1d2021 #ebdbb2 #484e50   #5f676a
  # client.unfocused        #1d2021 #1d2021 #ebdbb2 #292d2e   #222222
  # client.urgent           #cc241d #cc241d #ebdbb2 #900000   #900000
  # client.placeholder      #000000 #0c0c0c #ebdbb2 #000000   #0c0c0c
  # client.background       #282828
  config = {
    xsession.windowManager.i3.enable = true;
    xsession.windowManager.i3.extraConfig = ''
      default_border normal 0
      title_align center
    '';
    xsession.windowManager.i3.config = rec {
      modifier = "Mod1";
      keybindings = lib.mkOptionDefault {
        "${modifier}+h" = "focus left";
        "${modifier}+j" = "focus down";
        "${modifier}+k" = "focus up";
        "${modifier}+l" = "focus right";
        "${modifier}+Shift+h" = "move left";
        "${modifier}+Shift+j" = "move down";
        "${modifier}+Shift+k" = "move up";
        "${modifier}+Shift+l" = "move right";
        "${modifier}+Return" = "exec alacritty";
        "${modifier}+p" = "exec alacritty";
        "${modifier}+q" = "exec loginctl lock-session";
      };
      colors = {
        background = "#282828";
        focused = {
          background = "#${config.colorScheme.palette.base03}";
          border = "#${config.colorScheme.palette.base03}";
          childBorder = "#${config.colorScheme.palette.base03}";
          indicator = "#${config.colorScheme.palette.base03}";
          text = "#${config.colorScheme.palette.base07}";
        };
        focusedInactive = {
          background = "#${config.colorScheme.palette.base00}";
          border = "#${config.colorScheme.palette.base00}";
          childBorder = "#${config.colorScheme.palette.base00}";
          indicator = "#${config.colorScheme.palette.base00}";
          text = "#${config.colorScheme.palette.base05}";
        };
        unfocused = {
          background = "#${config.colorScheme.palette.base00}";
          border = "#${config.colorScheme.palette.base00}";
          childBorder = "#${config.colorScheme.palette.base00}";
          indicator = "#${config.colorScheme.palette.base00}";
          text = "#${config.colorScheme.palette.base07}";
        };
        urgent = {
          background = "#${config.colorScheme.palette.base08}";
          border = "#${config.colorScheme.palette.base08}";
          childBorder = "#${config.colorScheme.palette.base08}";
          indicator = "#${config.colorScheme.palette.base08}";
          text = "#${config.colorScheme.palette.base05}";
        };
        placeholder = {
          background = "#${config.colorScheme.palette.base0E}";
          border = "#${config.colorScheme.palette.base0E}";
          childBorder = "#${config.colorScheme.palette.base0E}";
          indicator = "#${config.colorScheme.palette.base0E}";
          text = "#${config.colorScheme.palette.base0E}";
        };
      };
    };

    services.random-background = {
      enable = true;
      imageDirectory = if config.DarkMode then "%h/Backgrounds/Dark" else "%h/Backgrounds/Light";
      interval = "10min";
    };
  };
}
