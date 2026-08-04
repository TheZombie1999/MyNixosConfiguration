{ pkgs, ... }:

{

  home.packages = [ pkgs.openssh ];

  home.file."sshconfig" = {
    target = ".ssh/config";
    source = ./config;
  };

  home.file."ssh_configs.d" = {
    target = ".ssh/ssh_configs.d";
    source = ./ssh_configs.d;
    recursive = true;
  };

  home.file."known_hosts.d" = {
    target = ".ssh/know_hosts.d";
    source = ./know_hosts.d;
    recursive = true;
  };

  services.ssh-agent = {
    enable = true;
    # pkcs11Whitelist = [ "/nix/store/*" ]; # not available in home-manager 25.05
  };
}
