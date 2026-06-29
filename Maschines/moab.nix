# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  lib,
  pkgs,
  home-manager,
  nix-colors,
  inputs,
  ...
}:

{
  imports = [
    ./../Hardware/moab-hardware-configuration.nix
    inputs.onedev.nixosModules.onedev
    inputs.sops-nix.nixosModules.sops
    home-manager.nixosModules.home-manager
  ];

  # boot.kernelParams = [ "split_lock_detect=off" ];

  nix.extraOptions = ''
    trusted-users = root tim
  '';

  #fileSystems."/mnt" = {
  #device = "/dev/sda3";
  #fsType = "ntfs-3g";
  #options = [
  #"rw"
  #"uid=1000"
  #];
  #};
  #
  services.onedev.enable = true;

  services.desktopManager.plasma6.enable = true;
  programs.seahorse.enable = false;

  home-manager.users.tim = import ./../Home/Users/tim-moab-home.nix;
  home-manager.extraSpecialArgs = { inherit nix-colors; };
  home-manager.backupFileExtension = "backup";

  services.yubikey-agent.enable = true;

  sops.defaultSopsFile = ../Secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/tim/.config/sops/age/keys.txt";
  sops.secrets.microstar_tailscale_key = { };
  sops.secrets.autoPullPrivateKey = { };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  services.nginx.enable = true;
  services.nginx.virtualHosts."myhost.org" = {
    root = "/var/www/myhost.org";
    locations."/" = {
      # This injects the autoindex directive directly into the Nginx config
      extraConfig = ''
        autoindex on;

        # Optional but highly recommended formatting tweaks:
        autoindex_exact_size off; # Shows file sizes in KB/MB instead of exact bytes
        autoindex_localtime on;   # Uses your server's local time zone for file dates
      '';
    };
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  hardware.steam-hardware.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "ntfs" ];

  networking.hostName = "moab"; # Define your hostname.

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "de_DE.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # # Enable the X11 windowing system.
  services.xserver.enable = true;

  programs.gamemode.enable = true;

  # Optional: extra nice settings
  programs.gamemode.settings = {
    general = {
      renice = 10; # Give game higher priority
      softrealtime = "auto";
      inhibit_screensaver = 1;
    };
  };

  # virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "tim" ];
  # virtualisation.virtualbox.host.enableExtensionPack = true;
  # virtualisation.virtualbox.guest.enable = true;
  # virtualisation.virtualbox.guest.dragAndDrop = true;

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  # Enable the GNOME Desktop Environment.
  # services.xserver.displayManager.gdm.enable = true;
  # services.displayManager.ly.enable = true;
  # services.displayManager.ly.settings = {
  #   lang = "de";
  # };
  #
  # services.displayManager.sddm.enable = true;
  # services.displayManager.sddm.wayland.enable = false;
  # services.displayManager.sddm.theme = "sugar-dark";
  #

  services.xserver.displayManager.lightdm.enable = true;

  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.windowManager.i3.enable = true;
  programs.hyprland.enable = true;
  programs.niri.enable = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };

  fonts.packages = with pkgs; [
    nerd-fonts.zed-mono
    nerd-fonts.martian-mono
    nerd-fonts.fira-code
  ];

  # Configure console keymap
  console.keyMap = "de";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.tim = {
    isNormalUser = true;
    description = "tim";
    extraGroups = [
      "networkmanager"
      "wheel"
      "dialout"
      "onepassword-cli"
      "plugdev"
      "pcscd"
      "libvirtd"
    ];
  };

  users.groups.plugdev = { };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    mangohud
    age-plugin-yubikey
    age-plugin-1p
    atlauncher
    prismlauncher
    helix
    wezterm
    helix
    htop
    git
    kitty
    sddm-sugar-dark
    sddm-astronaut
    bubblewrap
    inputs.sheets.packages.x86_64-linux.default

    # KDE Utilities
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

    yubico-piv-tool
  ];

  # services.yubikey-agent.enable = true;

  programs._1password.enable = true;
  programs._1password-gui.enable = true;
  programs._1password-gui.polkitPolicyOwners = [ "tim" ];

  # programs._1password-gui.package = pkgs-stable._1password-gui;
  services.pcscd.enable = true;
  systemd.services.pcscd.serviceConfig = {
    PIDFile = lib.mkForce "";
    User = "root";
  };
  # security.polkit.debug = true;

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if ((action.id == "org.debian.pcsc-lite.access_pcsc" ||
           action.id == "org.debian.pcsc-lite.access_card") &&
          subject.isInGroup("pcscd")) {
        return polkit.Result.YES;
      }
    });
  '';

  services.udev.packages = [ pkgs.yubikey-personalization ];

  security.pam.yubico = {
    enable = true;
    debug = false;
    mode = "challenge-response";
    id = [ "13336795" ];
  };

  security.pam.services = {
    login.u2fAuth = true;
    login.unixAuth = true;
    sudo.u2fAuth = true;
    sudo.unixAuth = true;
    i3lock.unixAuth = false;
  };

  programs.corectrl.enable = true;

  # programs.xss-lock =
  #   let
  #     background = pkgs.callPackage ./../Home/Backgrounds/package.nix { };
  #   in
  #   {
  #     enable = true;
  #     lockerCommand = "${pkgs.i3lock}/bin/i3lock --image=${background}/image.png --show-failed-attempts";
  #   };

  # programs.i3lock = {
  #   enable = true;
  #   u2fSupport = true;
  # };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
      X11Forwarding = false;
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 22 ];
  };

  services.udev.extraRules = ''
    ACTION=="remove",\
     ENV{ID_BUS}=="usb",\
     ENV{ID_MODEL_ID}=="0407",\
     ENV{ID_VENDOR_ID}=="1050",\
     ENV{ID_VENDOR}=="Yubico",\
     RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"

     ACTION=="add", SUBSYSTEM=="usb", ATTR{power/autosuspend}="-1"

     SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", GROUP="plugdev", MODE="0660"

     KERNEL=="hidraw*", ATTRS{idVendor}=="04fe", TAG+="uaccess"
     SUBSYSTEM=="hidraw", ATTRS{idVendor}=="04fe", MODE="0666"
     SUBSYSTEM=="usb", ATTRS{idVendor}=="04fe", MODE="0666", GROUP="plugdev"
  '';

  # Authorize the active session for PC/SC access via polkit
  # security.polkit.extraConfig = ''
  #   polkit.addRule(function(action, subject) {
  #     if (action.id == "org.debian.pcsc-lite.access_pcsc" &&
  #         subject.active == true && subject.local == true) {
  #       return polkit.Result.YES;
  #     }
  #   });
  # '';

  system.activationScripts.a.text = ''
    PATH=$PATH:${lib.makeBinPath [ pkgs.age-plugin-yubikey ]}
    ${pkgs.runtimeShell} -c "mkdir -p /var/lib/pcsc && ln -sfn ${pkgs.ccid}/pcsc/drivers /var/lib/pcsc/drivers"
  '';

  programs.nix-ld.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
