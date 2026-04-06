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
      # package = lib.mkPackageOption pkgs "onedev" { example = onedev; };
      statePath = lib.mkOption { };

    };

  };

  config = lib.mkIf cfg.enable {

    systemd.tmpfiles.rules = [
      "f /opt/onedev/logs/server.log 0660 root root -"
      "f /opt/onedev/logs/console.log 0660 root root -"
    ];

    systemd.services."onedev-server" = {
      enable = true;
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStartPre = "${pkgs.coreutils}/bin/ls /opt/onedev/conf";
        ExecStart = "${onedev}/bin/onedev";
        User = "root";

        BindPaths = [
          "${onedev}/opt/onedev/conf/:/opt/onedev/conf/"
          "${onedev}/opt/onedev/incompatibilities/incompatibilities.md:/opt/onedev/incompatibilities/incompatibilities.md"
          "${onedev}/opt/onedev/release.properties:/opt/onedev/release.properties"
          "${onedev}/opt/onedev/agent/bin:/opt/onedev/agent/bin"
          "${onedev}/opt/onedev/agent/conf:/opt/onedev/agent/conf"
          "${onedev}/opt/onedev/lib:/opt/onedev/lib"

          "${onedev}/opt/onedev/site/assets:/opt/onedev/site/assets"
          "${onedev}/opt/onedev/site/assets/avatars:/opt/onedev/site/assets/avatars"
          "${onedev}/opt/onedev/site/lib:/opt/onedev/site/lib"
        ];
      };
    };

    system.activationScripts.onedev = {
      text = ''
        mkdir -p /opt/onedev/
        mkdir -p /opt/onedev/site
        mkdir -p /opt/onedev/temp
      '';
    };

  };
}
