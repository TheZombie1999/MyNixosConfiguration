{ pkgs, ... }:
{

  home.packages = [
    pkgs.wl-clipboard
    (pkgs.writeShellScriptBin "group" (builtins.readFile ./group.sh))
    (pkgs.writeScriptBin "selectlayout" (builtins.readFile ./selectLayout.sh))
  ];

  programs.zellij = {
    enable = true;
  };

  xdg.configFile."config.kdl" = {
    source = ./config.kdl;
    target = "zellij/config.kdl";
  };

  xdg.configFile."plugins" = {
    source = ./plugins;
    target = "zellij/plugins";
    recursive = true;
  };
  xdg.configFile."layouts" = {
    source = ./layouts;
    target = "zellij/layouts";
    recursive = true;
  };
}
