{ config, pkgs, ... }:

{
  programs.helix = {
    enable        = true;
    defaultEditor = true;
    settings      = {
      theme = "base16";
      editor.lsp = {
        display-messages = true;
        display-inlay-hints = true;
      };
      editor.whitespace = { render = "all"; };
      keys = {
        insert = { "C-m" = "insert_newline"; };
        normal = {
          "C-m" = ":w";
        };
        normal."C-r" = {
          l = ":run-shell-command ls";
          n = ":run-shell-command neofetch --stdout";
        };
      };
    };
    themes = {
      base16 = let
        transparent = "none";
        gray        = "#${config.colorScheme.palette.base03}";
        dark-gray   = "#${config.colorScheme.palette.base01}";
        white       = "#${config.colorScheme.palette.base07}";
        black       = "#${config.colorScheme.palette.base00}";
        red         = "#${config.colorScheme.palette.base08}";
        green       = "#${config.colorScheme.palette.base0B}";
        yellow      = "#${config.colorScheme.palette.base0A}";
        orange      = "#${config.colorScheme.palette.base09}";
        blue        = "#${config.colorScheme.palette.base0D}";
        magenta     = "#${config.colorScheme.palette.base0E}";
        cyan        = "#${config.colorScheme.palette.base0F}";
          in {
            "ui.menu"                   = transparent;
            "ui.menu.selected"          = { modifiers = [ "reversed" ]; };
            "ui.linenr"                 = { fg = gray; bg = dark-gray; };
            "ui.popup"                  = { modifiers = [ "reversed" ]; };
            "ui.linenr.selected"        = { fg = white; bg = black; modifiers = [ "bold" ]; };
            "ui.selection"              = { fg = black; bg = blue; };
            "ui.selection.primary"      = { modifiers  = [ "reversed" ]; };
            "comment"                   = { fg = gray; };
            "ui.statusline"             = { fg = white; bg = dark-gray; };
            "ui.statusline.inactive"    = { fg = dark-gray; bg   = white; };
            "ui.help"                   = { fg = dark-gray; bg = white; };
            "ui.cursor"                 = { modifiers = [ "reversed" ]; };
            "variable"                  = red;
            "variable.builtin"          = orange;
            "constant.numeric"          = orange;
            "constant"                  = orange;
            "attributes"                = yellow;
            "type"                      = yellow;
            "ui.cursor.match"           = { fg = yellow; modifiers = [ "underlined" ]; };
            "string"                    = green;
            "variable.other.member"     = red;
            "constant.character.escape" = cyan;
            "function"                  = blue;
            "constructor"               = blue;
            "special"                   = blue;
            "keyword"                   = magenta;
            "label"                     = magenta;
            "namespace"                 = blue;
            "diff.plus"                 = green;
            "diff.delta"                = yellow;
            "diff.minus"                = red;
            "diagnostic"                = { modifiers = [ "underlined" ]; };
            "ui.gutter"                 = { bg = black; };
            "info"                      = blue;
            "hint"                      = dark-gray;
            "debug"                     = dark-gray;
            "warning"                   = yellow;
            "error"                     = red;
            };
      };
    };

  xdg.configFile."helix/config.toml".onChange = "${pkgs.busybox}/bin/pkill -USR1 hx";
}
