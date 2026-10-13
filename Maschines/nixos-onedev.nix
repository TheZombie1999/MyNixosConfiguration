{
  pkgs,
  modulesPath,
  ...
}:

let
  git-shell-commands = pkgs.callPackage ../Packages/git-shell-commands/package.nix { };
in
{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  # SSH: Enabled, passwordless (key-only) authentication, no root login
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
    # Optional: allow SSH agent forwarding (useful for git etc.)
    allowSFTP = true;
  };

  # Main user: tim (sudo without password, SSH key auth only)
  users.users = {
    tim = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        "video"
        "audio"
      ];
      openssh.authorizedKeys.keys = [
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIK5ynhdh9jUSrKGll4ZOw4Krji+ipGNfsFKu6EmbEpVMAAAABHNzaDo= ssh:"
        # YubiKey PIV authentication slot (RSA), added as a second factor
        # alongside the FIDO key above for reaching this host via the
        # hetzner-nbg1 jump bastion. (Previous commit added an ECDSA key here
        # by mistake -- it was read from a different YubiKey that was still
        # plugged in at the time, not this one.)
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDE8efig7RNbO23eNgnRkg1BoBA5pqdQ52DpaTihGcT+iAiw5Ni5pShFQ8qYzh11vArRBcCP4ULpJ1uR71SECUjy8M+DKgF7vH2UkrrGoRmbE4+Yb2hKIJCep1bHfPw9lLqiSh3IJshvLXnApR7FtclnEEux/GTFz/E9qGiZ8lh6dgnA3NS1NuySU251OHJJiV6np+Rp/sDi2z/etNnzGY0a3lrBI3ADCDm8aQddUzU3N3w54qo6WLQR4RTBy1RUUlPSe/edDQCI2pd5q26SClRYpF7X431HfS/FYLv5wKhAMvq8bFX0rkz91ixH66umAT2AujJenZGkB4XbgARxvFR"
      ];
    };

    git = {
      isNormalUser = true;
      home = "/home/git";
      description = "user to access git repos on this server";
      openssh.authorizedKeys.keys = [
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIK5ynhdh9jUSrKGll4ZOw4Krji+ipGNfsFKu6EmbEpVMAAAABHNzaDo= ssh:"
      ];
      shell = "${pkgs.git}/bin/git-shell";
      linger = true;
    };
  };

  # No passwords anywhere (rely on SSH keys)
  security.sudo.wheelNeedsPassword = false;
  users.users.root.openssh.authorizedKeys.keys = [ ]; # Root has no keys (disabled anyway)

  # Wide range of utilities for disk formatting, system management, and info gathering
  environment.systemPackages = with pkgs; [
    tree
    # Core system tools
    helix
    git
    curl
    wget
    rsync
    jq
    tmux
    screen
    fastfetch
    htop
    iotop
    iftop
    ncdu
    nmon

    # Disk formatting & partitioning
    parted
    gptfdisk
    util-linux # includes lsblk, blkid, wipefs
    e2fsprogs
    btrfs-progs
    xfsprogs
    dosfstools
    ntfs3g
    cryptsetup
    lvm2
    mdadm
    f2fs-tools

    # Filesystem & disk inspection / repair
    smartmontools
    nvme-cli
    hdparm
    sdparm
    testdisk
    gparted # (CLI-focused; gparted has ncurses mode too)

    # Hardware / system information
    lshw
    dmidecode
    pciutils
    usbutils
    hwinfo
    fastfetch # neofetch for quick system overview

    # Network / management extras
    iproute2
    ethtool
    tcpdump
    nmap
    mtr

    ncdu
  ];

  # QEMU guest agent (essential for Proxmox VM management: shutdown, IP reporting, etc.)
  services.qemuGuest.enable = true;

  # Nix settings (modern & convenient for remote management)
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  services = {
    desktopManager.plasma6.enable = true;
    displayManager.sddm.enable = true;
    displayManager.sddm.wayland.enable = true;
  };

  systemd.user.tmpfiles.users."git".rules = [
    "L /home/git/git-shell-commands - - - - ${git-shell-commands}/share/git-shell-commands"
  ];

  # State version (update only when you know what you're doing)
  system.stateVersion = "25.11";
}
