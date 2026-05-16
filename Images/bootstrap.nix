{
  pkgs,
  ...
}:

{

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
  users.users.tim = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFSQmujNkQVQHO1+T0BYABedfEn2QFRJIL9ePe0nxTBF tim@nixos"
    ];
  };

  # No passwords anywhere (rely on SSH keys)
  security.sudo.wheelNeedsPassword = false;
  users.users.root.openssh.authorizedKeys.keys = [ ]; # Root has no keys (disabled anyway)

  # Wide range of utilities for disk formatting, system management, and info gathering
  environment.systemPackages = with pkgs; [
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
    kitty
    chromium

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

    # KDE Utilities
    kdePackages.discover # Optional: Software center for Flatpaks/firmware updates
    kdePackages.kcalc # Calculator
    kdePackages.kcharselect # Character map
    kdePackages.kclock # Clock app
    kdePackages.kcolorchooser # Color picker
    kdePackages.kolourpaint # Simple paint program
    kdePackages.ksystemlog # System log viewer
    kdePackages.sddm-kcm # SDDM configuration module
    kdiff3 # File/directory comparison tool

    # Hardware/System Utilities (Optional)
    kdePackages.isoimagewriter # Write hybrid ISOs to USB
    kdePackages.partitionmanager # Disk and partition management
    hardinfo2 # System benchmarks and hardware info
    wayland-utils # Wayland diagnostic tools
    wl-clipboard # Wayland copy/paste support
    vlc # Media player
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

  # State version (update only when you know what you're doing)
  system.stateVersion = "25.11";
}
