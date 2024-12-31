# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, home-manager, nix-colors, inputs, ... }:

{
  imports =
    [
      ./../Hardware/microstar-hardware-configuration.nix
      ./../Modules/ansible-pull.nix
      inputs.sops-nix.nixosModules.sops
      home-manager.nixosModules.home-manager
    ];

  system.autoPull = {
    enable = true;
    sshKey = config.sops.secrets."autoPullPrivateKey".path;
    repo = "git@github.com:TheZombie1999/MyNixosConfiguration.git";
  };

  sops.defaultSopsFile = ../Secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/tim/.config/sops/age/keys.txt";
  sops.secrets.microstar_tailscale_key = { };
  sops.secrets.autoPullPrivateKey = { };

  networking.hostName = "microstar";

  home-manager.users.tim = import ./../Home/Users/tim-microstar-home.nix;
  home-manager.extraSpecialArgs = { inherit nix-colors; };

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.minecraft-server = {
    enable = true;
    eula = true;

    package = let
      version = "1.21.3";
      url = "https://piston-data.mojang.com/v1/objects/45810d238246d90e811d896f87b14695b7fb6839/server.jar";
      sha256 = "1ddgz0dh830869v82q0cp3zkyanl1p45f7ccbvgrr0y00advhlz1";
     in (pkgs.minecraft-server.overrideAttrs (old: rec{
      name = "minecraft-server-${version}";
      inherit version;

      src = pkgs.fetchurl {
        inherit url sha256;
      };
    }));
  };

  services.openvscode-server.enable = true;
  services.openvscode-server.host = "0.0.0.0";
  services.openvscode-server.user = "tim";
  services.openvscode-server.withoutConnectionToken = false;
  services.openvscode-server.connectionToken = "Test";

  services.tailscale = { 
    enable = true; 
    authKeyFile = config.sops.secrets."microstar_tailscale_key".path;
  };

  # services.tailscale.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
 
  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # services.synergy.client = {
  #   enable = true;
  #   autoStart = true;
  #   serverAddress = "192.168.1.201";
  #   screenName = "client";
  # };

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  users.users.tim = {
    isNormalUser = true;
    home = "/home/tim";
    description = "My Standard User";
    extraGroups = [ "wheel" "networkmanager" "audio" "minecraft" ];
  };

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
  #   keyMap = "us";
    useXkbConfig = true; # use xkb.options in tty.
  };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;


  # Enable the Plasma 5 Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;
  

  # Configure keymap in X11
  # services.xserver.xkb.layout = "de";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;


  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     firefox
  #     tree
  #   ];
  # };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    alacritty
    helix
    git
    sops
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.vikunja = {
    enable = true;
    frontendScheme = "http";
    frontendHostname = "microstar";
  };

  

  # services = {
  #     syncthing = {
  #         enable = true;
  #         user = "tim";
  #         dataDir = "/home/tim/Sync";    # Default folder for new synced folders
  #         configDir = "/home/tim/.config/syncthing";   # Folder for Syncthing's settings and keys
  #     };
  # };


  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;
  system.stateVersion = "24.05";
}

