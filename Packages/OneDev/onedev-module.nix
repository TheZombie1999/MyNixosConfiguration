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
      onedev = pkgs.callPackage ./onedev.nix { installDir = cfg.installDir; };
      hibernateConfig = pkgs.callPackage ./hibernate-config.nix { installDir = cfg.installDir; };
      serverConfig = pkgs.callPackage ./server-config.nix { installDir = cfg.installDir; };
    in
    lib.mkIf cfg.enable {

      environment.systemPackages = [ onedev ];
      
      fileSystems = {
        "/opt/onedev" = {
          overlay = {
            workdir = "/opt/overlay/onedev/work";
            upperdir = "/opt/overlay/onedev/upper";
            lowerdir = [
              "${hibernateConfig}"
              "${serverConfig}"
              "${onedev}"
            ];
          };
        };
      };

      systemd.services."onedev-server" = {
        enable = true;
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Environment = "PATH=${
            lib.makeBinPath [
              pkgs.toybox
              pkgs.coreutils
              pkgs.curl
              pkgs.git
              pkgs.fontconfig
              pkgs.dejavu_fonts
            ]
          }";
          Type = "simple";
          ExecStart = "${onedev}/bin/server.sh console";
          User = "root";
        };
      };
    };
}
