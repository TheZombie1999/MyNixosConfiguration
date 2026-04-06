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
in
{
  imports = [ ];

  options = {
    services.onedev = {
      enable = lib.mkEnableOption "onedev";
      installDir = lib.mkOption {
        type = lib.types.str;
        default = "/opt/onedev/";
        description = "The folder Onedev reads and writes to.";
      };

    };

  };

  config =
    let
      onedev = pkgs.callPackage ./onedev.nix { };
      hibernateConfig = pkgs.callPackage ./hibernate-config.nix { installDir = cfg.installDir; };
      serverConfig = pkgs.callPackage ./server-config.nix { installDir = cfg.installDir; };
    in
    lib.mkIf cfg.enable {

      fileSystems = {
        "/opt/onedev" = {
          overlay = {
            workdir = "/opt/overlay/onedev/work";
            upperdir = "/opt/overlay/onedev/upper";
            lowerdir = [
              "${hibernateConfig}/opt/onedev"
              "${serverConfig}/opt/onedev"
              "${onedev}/opt/onedev"
            ];
          };
        };
      };

      systemd.services."onedev-server" = {
        enable = true;
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${onedev}/bin/onedev";
          User = "root";
        };
      };
    };
}
