{ ... }:
{
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
  };

  home.file."yazi.toml" = {
    enable = true;
    source = ./yazi.toml;
    target = ".config/yazi/yazi.toml";
  };

  home.file."init.lua" = {
    enable = true;
    source = ./init.lua;
    target = ".config/yazi/init.lua";
  };

  home.file."yazi-plugins" = {
    enable = true;
    source = ./plugins;
    target = ".config/yazi/plugins";
    recursive = true;
  };
}
