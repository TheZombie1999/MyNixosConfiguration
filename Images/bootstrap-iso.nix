{
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  # ---------------------------------------------------------------------------
  # PLACEHOLDER: add your SSH public keys here (one string per key).
  # The build fails on purpose until at least one key is present, so you
  # can't accidentally ship an ISO nobody can log into.
  # ---------------------------------------------------------------------------
  sshKeys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIK5ynhdh9jUSrKGll4ZOw4Krji+ipGNfsFKu6EmbEpVMAAAABHNzaDo="
  ];
in
{
  imports = [
    # Minimal (no desktop) installer. Swap for
    # installation-cd-graphical-calamares-gnome.nix if you want a GUI.
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # --- Safety check -----------------------------------------------------------
  assertions = [
    {
      assertion = sshKeys != [ ];
      message = "iso.nix: add at least one SSH public key to `sshKeys`.";
    }
  ];

  # --- SSH --------------------------------------------------------------------
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      # Installer default is "yes"; force key-only root login.
      PermitRootLogin = lib.mkForce "prohibit-password";
    };
  };

  # The installer module registers sshd but doesn't start it at boot.
  systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];

  users.users.root.openssh.authorizedKeys.keys = sshKeys;
  users.users.nixos.openssh.authorizedKeys.keys = sshKeys;

  # --- ZFS --------------------------------------------------------------------
  # Loads the ZFS kernel module and puts zpool/zfs tools on the ISO.
  # The installer's default kernel is an LTS release that ZFS supports;
  # don't switch to linuxPackages_latest unless ZFS has caught up with it.
  boot.supportedFilesystems.zfs = true;
  boot.zfs.forceImportRoot = false;

  # ZFS requires a hostId (8 hex chars). Any value is fine for a live ISO;
  # generate a fresh one with: head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = "8425e349";

  # --- Networking -------------------------------------------------------------
  networking.hostName = "nixos-installer";
  networking.useDHCP = lib.mkDefault true;

  # Reach the machine as `nixos-installer.local` on the LAN (mDNS).
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  # --- Convenience ------------------------------------------------------------
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    htop
    tmux
    parted
  ];

  # Faster builds, slightly bigger ISO. Remove for max compression.
  isoImage.squashfsCompression = "zstd -Xcompression-level 6";
}
