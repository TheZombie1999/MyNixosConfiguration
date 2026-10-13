# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  lib,
  pkgs,
  pkgs-unstable,
  home-manager,
  nix-colors,
  inputs,
  ...
}:

{
  imports = [
    ./../Hardware/moab-hardware-configuration.nix
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
  services.tailscale.enable = true;

  services.desktopManager.plasma6.enable = true;
  programs.seahorse.enable = false;

  home-manager.users.tim = import ./../Home/Users/tim-moab-home.nix;
  home-manager.extraSpecialArgs = { inherit nix-colors pkgs-unstable; };
  home-manager.backupFileExtension = "backup";

  services.yubikey-agent.enable = true;

  sops.defaultSopsFile = ../Secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
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

  # Allow SteamVR to set real-time thread priorities (vrserver calls setschedparam directly)
  security.pam.loginLimits = [
    {
      domain = "tim";
      type = "-";
      item = "rtprio";
      value = "99";
    }
    {
      domain = "tim";
      type = "-";
      item = "memlock";
      value = "unlimited";
    }
  ];

  # vrcompositor-launcher needs CAP_SYS_NICE; vrserver needs CAP_SYS_NICE+CAP_NET_ADMIN to manage
  # the USB dongle AP interface. The path units re-apply caps automatically after SteamVR updates.
  system.activationScripts.steamvr-caps = {
    text = ''
      launcher="/home/tim/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher"
      vrserver="/home/tim/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrserver"
      if [ -f "$launcher" ]; then
        ${pkgs.libcap}/bin/setcap CAP_SYS_NICE=eip "$launcher"
      fi
      if [ -f "$vrserver" ]; then
        ${pkgs.libcap}/bin/setcap CAP_SYS_NICE,CAP_NET_ADMIN=eip "$vrserver"
      fi
    '';
  };

  systemd.services.steamvr-setcap-launcher = {
    description = "Set CAP_SYS_NICE on SteamVR vrcompositor-launcher";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.libcap}/bin/setcap CAP_SYS_NICE=eip /home/tim/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher";
    };
  };

  systemd.paths.steamvr-setcap-launcher = {
    description = "Re-apply CAP_SYS_NICE when SteamVR updates vrcompositor-launcher";
    wantedBy = [ "multi-user.target" ];
    pathConfig.PathModified = "/home/tim/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher";
  };

  systemd.services.steamvr-setcap-vrserver = {
    description = "Set capabilities on SteamVR vrserver (CAP_SYS_NICE + CAP_NET_ADMIN for dongle AP)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.libcap}/bin/setcap CAP_SYS_NICE,CAP_NET_ADMIN=eip /home/tim/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrserver";
    };
  };

  systemd.paths.steamvr-setcap-vrserver = {
    description = "Re-apply capabilities when SteamVR updates vrserver";
    wantedBy = [ "multi-user.target" ];
    pathConfig.PathModified = "/home/tim/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrserver";
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  # graceful: don't fail the rebuild if bootctl update exits non-zero (spurious in systemd 260.x)
  boot.loader.systemd-boot.graceful = true;
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
  # networking.networkmanager.unmanaged = [ "mac:9c:04:b6:88:b1:9a" ]; # Steam Frame VR dongle

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

  services.desktopManager.gnome.enable = true;
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
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # wireplumber.extraConfig = {
    #   "10-blue-mic" = {
    #     "monitor.alsa.rules" = [
    #       {
    #         matches = [ { "device.name" = "alsa_card.usb-Generic_Blue_Microphones_2226BAH00HE8-00"; } ];
    #         actions.update-props = {
    #           "api.acp.auto-profile" = true;
    #           "api.acp.auto-port" = true;
    #         };
    #       }
    #     ];
    #   };
    # };
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
      "docker"
    ];
  };

  users.groups.plugdev = { };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = false;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages =
    (with pkgs; [
      thunderbird
      mangohud
      age-plugin-yubikey
      age-plugin-1p
      atlauncher
      prismlauncher
      helix
      wezterm
      htop
      git
      kitty
      sddm-sugar-dark
      sddm-astronaut
      bubblewrap
      teams-for-linux
      libreoffice
      xournalpp
      # inputs.sheets.packages.x86_64-linux.default
      # inputs.finanzbro.packages.x86_64-linux.default
      inputs.tuicr.packages.x86_64-linux.default

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
      gamescope # Nested Wayland compositor for Steam Remote Play screen capture
      wayland-utils # Wayland diagnostic tools
      wl-clipboard # Wayland copy/paste support
      vlc # Media player

      yubico-piv-tool
    ])
    ++ (with pkgs-unstable; [
      thunderbird-cli
    ]);

  environment.plasma6.excludePackages = with pkgs; [
    kdePackages.kwallet
    kdePackages.kwallet-pam
    kdePackages.kwalletmanager
  ];

  # services.yubikey-agent.enable = true;

  programs._1password.enable = true;
  programs._1password-gui.enable = true;
  programs._1password-gui.polkitPolicyOwners = [ "tim" ];
  programs._1password.package = pkgs-unstable._1password-cli;

  # programs._1password-gui.package = pkgs-unstable._1password-gui;
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
    ACTION=="add", SUBSYSTEM=="usb", ATTR{power/autosuspend}="-1"

     SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", GROUP="plugdev", MODE="0660"

     KERNEL=="hidraw*", ATTRS{idVendor}=="04fe", TAG+="uaccess"
     SUBSYSTEM=="hidraw", ATTRS{idVendor}=="04fe", MODE="0666"
     SUBSYSTEM=="usb", ATTRS{idVendor}=="04fe", MODE="0666", GROUP="plugdev"
  '';
  services.gvfs.enable = true;

  security.chromiumSuidSandbox.enable = true;

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

  virtualisation.docker.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
