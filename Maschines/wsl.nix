# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ pkgs, ... }:

{
  imports = [
    # include NixOS-WSL modules
    <nixos-wsl/modules>
    <home-manager/nixos>
  ];

  nixpkgs.config.allowUnfree = true;

  wsl.enable = true;
  wsl.defaultUser = "tim";

  # virtualisation.docker.enable = true;

  users.users.tim = {
    name = "tim";
    home = "/home/tim";
    extraGroups = [
      "wheel"
      "audio"
      "docker"
    ];
    isNormalUser = true;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # services.jenkins.enable = true;
  # services.paperless.enable = true;
  # services.paperless.passwordFile = /home/tim/pass;
  # services.vsftpd.enable = true;
  # services.vsftpd.writeEnable = true;
  # services.vsftpd.userlistEnable = true;
  # services.vsftpd.userlist = [ "tim" "root" ];
  # services.vsftpd.localUsers = true;

  services.youtrack.enable = true;
  services.youtrack.package = pkgs.youtrack;

  networking.hostName = "nixosWsl";

  home-manager.users.tim = (import ./../MyHomeConfiguration/Users/tim-nixosWsl.nix).dark;
  services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
