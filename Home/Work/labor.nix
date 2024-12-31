{ config, lib, pkgs, ...}:

with lib;

let 
  cfg = config.mymodules.labor;
in
{
   options = {
    mymodules.labor = {
      enable = mkEnableOption "Labor enable option";
      jump = mkOption {
        type = types.bool;
        default = true;
        description = ''If Enabled will cause ssh to use jumper as a jump host'';
      };
    };
    
  };

  config = mkIf cfg.enable {

    programs.ssh = {
      extraConfig = ''
        Host field-gate
          Hostname field-gate.varta-storage.com
          PKCS11Provider /usr/lib/x86_64-linux-gnu/libykcs11.so
          User vpn-jumper
       
        Host debrepo.varta-storage.com
          PKCS11Provider /usr/lib/x86_64-linux-gnu/libykcs11.so
          User rwimmer
          ProxyJump field-gate
        
        Host ssh-proxy
            Hostname ssh-proxy.varta-storage.com
            PKCS11Provider /usr/lib/x86_64-linux-gnu/libykcs11.so
            ProxyJump field-gate
            User vpnjumper
        
        Host battery-*
            ProxyJump ssh-proxy
            User devel
      '';
      
      matchBlocks = {
        "hvb" = {
          hostname = "192.168.178.210";
          user = "devel";
        };
        "jumper" = {
          hostname = "100.92.91.11";
          user = "jumper";
          identityFile = [ "~/.ssh/jumperkey_rsa" ];
        };     
        "XtremeXolo" = {
          hostname = "10.0.215.185";
          user = "devel";
          proxyJump = mkIf cfg.jump "jumper";
        };
        "WoolyWookie" = {
          hostname = "10.0.215.197";
          user = "devel";
          proxyJump = mkIf cfg.jump "jumper";
        };
        "YellowYak" = {
          hostname = "10.0.215.182";
          user = "devel";
          proxyJump = mkIf cfg.jump "jumper";
        };
        "Duck" = {
          hostname = "10.0.215.188";
          user = "devel";
          proxyJump = mkIf cfg.jump "jumper";
        };
        "Chipmunk" = {
          hostname = "10.0.215.187";
          user = "devel";
          proxyJump = mkIf cfg.jump "jumper";
        };
        "Biber" = {
          hostname = "10.0.215.101";
          user = "devel";
          proxyJump = mkIf cfg.jump "jumper";
        };
        "Aligator" = {
          hostname = "10.0.215.183";
          user = "devel";
          proxyJump = mkIf cfg.jump "jumper";
        };
        "Zebra" = {
          hostname = "10.0.215.186";
          user = "devel";
          proxyJump = mkIf cfg.jump "jumper";
        };
        "pulse-neo-130100000" = {
          hostname = "10.0.215.131";
          user = "devel";
          proxyJump = mkIf cfg.jump "jumper";
        };
        "pulse-neo-luegfix" = {
          hostname = "10.0.215.60";
          user = "devel";
          proxyJump = mkIf cfg.jump "jumper";
        };
        "serialPi" = {
          hostname = "10.0.215.11";
          user = "devel";
          proxyJump = mkIf cfg.jump "jumper";
        };
      };  
    };
  };
}
