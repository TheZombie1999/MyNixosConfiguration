{ config, pkgs, ... }:

{
  services.tlp.enable = true;
  services.thermald.enable = true;
}
