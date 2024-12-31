{ config, lib, pkgs, ... }:

with lib;

{

  options = {
    mymodules.mybash = {
      enable = mkEnableOption "Bash enable option";
    };
  };
  
  config = mkIf config.mymodules.mybash.enable {
        home.file.".bashrc".source = ./bashrc;
    };
}
