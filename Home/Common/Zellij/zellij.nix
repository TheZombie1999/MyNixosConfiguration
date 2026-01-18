{ pkgs, ...}:
{

  home.packages = [
    (pkgs.writeShellScriptBin "bundle" (builtins.readFile ./launch.sh) )
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
}
