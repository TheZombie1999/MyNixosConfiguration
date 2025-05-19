{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.mymodules.labor;
  laborConfig =
    {
      ip_suffix,
      jump ? false,
    }:
    addPkcs11 (
      addCertificate "~/.ssh/TimSchneider2024-cert.pub" {
        hostname = "10.0.215.${ip_suffix}";
        user = "devel";
        proxyJump = mkIf jump "jumper";
      }
    );
  addPkcs11 =
    attr:
    attr
    // {
      extraOptions = {
        PKCS11Provider = "/usr/lib/x86_64-linux-gnu/libykcs11.so";
      };
    };
  addCertificate = path: attr: attr // { certificateFile = "${path}"; };
in
{
  options = {
    mymodules.labor = {
      enable = mkEnableOption "Labor enable option";
      jump = mkOption {
        type = types.bool;
        default = true;
        description = "If Enabled will cause ssh to use jumper as a jump host";
      };
    };
  };
  config = mkIf cfg.enable {
    programs.ssh = {
      controlMaster = "auto";
      controlPath = "/run/user/%i/ssh_master_%r@%h:%p";
      controlPersist = "yes";
      serverAliveInterval = 60;
      addKeysToAgent = "yes";
      compression = true;
      forwardAgent = true;
      serverAliveCountMax = 1000;
      extraConfig = ''
        Host field-gate
          Hostname field-gate.varta-storage.com
          PKCS11Provider /usr/lib/x86_64-linux-gnu/libykcs11.so
          ForwardAgent yes
          User vpn-jumper

        Host ssh-proxy
            Hostname ssh-proxy.varta-storage.com
            PKCS11Provider /usr/lib/x86_64-linux-gnu/libykcs11.so
            ProxyJump field-gate
            User vpnjumper

        Host battery-?????????
            PKCS11Provider /usr/lib/x86_64-linux-gnu/libykcs11.so
            CertificateFile ~/.ssh/TimSchneider2024-cert.pub
            ProxyJump ssh-proxy
            User devel

        Host vsjumper
          Hostname vstsjumper.tailbf4e.ts.net
          PKCS11Provider /usr/lib/x86_64-linux-gnu/libykcs11.so
          ForwardAgent yes
          User jumper

        Host varta-storage.netzfabrik.cloud
          User git
          IdentityFile ~/.ssh/bjarne-bjarne-sdk
          IdentitiesOnly yes
          AddKeysToAgent yes

        # Host buildservervm
        #   Hostname BuildServerVM
        #   PKCS11Provider /usr/lib/x86_64-linux-gnu/libykcs11.so
        #   ProxyJump vsjumper
        #   User tschneider
      '';
      matchBlocks = {
        "buildservervm" = addPkcs11 (
          addCertificate "~/.ssh/TimSchneider2024-cert.pub" {
            hostname = "BuildServerVM";
            user = "tschneider";
            proxyJump = "vsjumper";
          }
        );
        "hvb" = {
          hostname = "192.168.178.210";
          user = "devel";
        };
        "jumper" = {
          hostname = "10.0.215.87";
          user = "jumper";
          forwardAgent = true;
        };
        "xtremeXolo" = laborConfig { ip_suffix = "185"; };
        "woolyWookie" = laborConfig { ip_suffix = "197"; };
        "yellowYak" = laborConfig { ip_suffix = "182"; };
        "duck" = laborConfig { ip_suffix = "188"; };
        "chipmunk" = laborConfig { ip_suffix = "187"; };
        "biber" = laborConfig { ip_suffix = "191"; };
        "aligator" = laborConfig { ip_suffix = "183"; };
        "zebra" = laborConfig { ip_suffix = "186"; };
        "kangaroo" = laborConfig { ip_suffix = "134"; };
        "pulse-neo-130100000" = laborConfig { ip_suffix = "131"; };
        "pulse-neo-luegfix" = laborConfig { ip_suffix = "60"; };
        "serialPi" = {
          hostname = "10.0.215.11";
          user = "devel";
          proxyJump = mkIf cfg.jump "jumper";
        };
        "ansibleNode" = {
          hostname = "10.0.215.48";
          user = "ansible";
          proxyJump = mkIf cfg.jump "jumper";
        };
        "serviceBotVM" = {
          hostname = "10.0.215.5";
          user = "devel";
          proxyJump = mkIf cfg.jump "jumper";
          extraOptions = {
            ForwardAgent = "none";
          };
        };
        "pulse-neo-jenkins-11" = {
          hostname = "10.0.215.151";
          user = "devel";
          proxyJump = mkIf cfg.jump "jumper";
        };
        "pulse-neo-jenkins-9" = {
          hostname = "10.0.215.150";
          user = "devel";
          proxyJump = mkIf cfg.jump "jumper";
        };
        "fallbackip" = {
          hostname = "169.254.0.5";
          user = "devel";
        };
        "debrepoTim" = addPkcs11 {
          hostname = "debrepo.varta-storage.com";
          user = "tschneider";
          proxyJump = "field-gate";
          certificateFile = "~/.ssh/TimSchneider2024-cert.pub";
        };
        "odroid" = addPkcs11 (
          addCertificate "~/.ssh/TimSchneider2024-cert.pub" {
            hostname = "10.0.215.224";
            user = "devel";
            setEnv = {
              TERM = "xterm";
            };
          }
        );
        "jenkins" = addPkcs11 (
          addCertificate "~/.ssh/TimSchneider2024-cert.pub" {
            hostname = "10.0.215.6";
            user = "jenkins";
          }
        );
        "flashserver" = addPkcs11 (
          addCertificate "~/.ssh/TimSchneider2024-cert.pub" {
            hostname = "10.0.215.8";
            user = "devel";
          }
        );
        "proxMox" = addPkcs11 (
          addCertificate "~/.ssh/TimSchneider2024-cert.pub" {
            hostname = "10.0.215.1";
            user = "root";
          }
        );
        "hippo" = addPkcs11 (
          addCertificate "~/.ssh/TimSchneider2024-cert.pub" {
            hostname = "10.0.215.207";
            user = "devel";
          }
        );
        "hvbSubotVM" = addPkcs11 (
          addCertificate "~/.ssh/TimSchneider2024-cert.pub" {
            hostname = "10.0.215.9";
            user = "devel";
          }
        );
        "aux4" = {
          hostname = "10.0.215.220";
          user = "user";
        };
      };
    };
  };
}
