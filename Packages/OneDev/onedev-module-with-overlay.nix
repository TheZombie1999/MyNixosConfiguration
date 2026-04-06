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

    fileSystems = {
      "/opt/onedev" = {
        overlay = {
          workdir = "/opt/overlay/onedev/work";
          upperdir = "/opt/overlay/onedev/upper";
          lowerdir = ["${onedev}/opt/onedev"];
        };
      };
    };

    systemd.services."onedev-server" = {
      enable = true;
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStartPre = "${pkgs.coreutils}/bin/ls /opt/onedev/conf";
        ExecStart = "${onedev}/bin/onedev";
        User = "root";
      };
    };
  };
}
