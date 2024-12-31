{ config, pkgs, lib, ... }:

let
  cfg = config.system.autoPull;
in
{
  options = {
    system.autoPull = {
      enable =  lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Enables or disables Automatic pulling an rebuilding of the nixos config.
        '';
      };

      sshKey = lib.mkOption {
        type = lib.types.path;
      };

      repo = lib.mkOption {
        type = lib.types.string;
      };

      dest = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/autoPull";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.services.autoPull = {
      path = with pkgs; [
        ansible
        git
        openssh
        nixos-rebuild
      ];

      script = /* bash */ ''
        ansible-pull \
          --private-key ${cfg.sshKey} \
          --url ${cfg.repo} \
          --only-if-changed \
          --directory ${cfg.dest} \
          --accept-host-key \
          Ansible/rebuild-nixos.yml
      '';
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };
    systemd.timers.autoPull = {
      timerConfig = {
        OnCalendar = "*-*-* *:*:00";
        Persistent = true;
        Unit = "autoPull.service";
      };
    };
  };
}
