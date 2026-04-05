{
  config,
  lib,
  options,
  pkgs,
  utils,
  ...
}:

let
  cfg = config.services.onedev;
  opt = options.services.onedev;
  onedev = pkgs.callPackage ./onedev.nix { };
in
{
  imports = [ ];

  options = {
    services.onedev = {
      enable = lib.mkEnableOption "onedev";
      package = lib.mkPackageOption pkgs "onedev" { example = onedev; };
      statePath = lib.mkOption { };

    };

  };

  config = lib.mkIf cfg.enable {

    systemd.services."onedev-server" = {
      serviceConfig = {
        execStart = "${cfg.package}/bin/onedev";
      };
    };

    system.activationScripts.onedev = {
      text = ''
          source="${cfg.package}/opt/onedev"
          target="/opt/onedev"

          find -mindepth 1 | while read -r item; do
            rel="''${item#$source/}"
            mkdir -p "$target/$(dirname "$rel")"
            ln -sfn "$item" "$target/$rel"
          done         
        '';
    };

  };
}
