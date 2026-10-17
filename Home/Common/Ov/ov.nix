{ pkgs, ... }:
# https://github.com/noborus/ov?tab=readme-ov-file#not-supported
{
  home.packages = [ pkgs.ov ];

  home.file."ov" = {
    target = ".config/ov/config.yaml";
    source = ./config.yaml;
  };
}
