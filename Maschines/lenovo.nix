{ pkgs, lib, ... }:

{
  imports = [
    <home-manager/nixos>
    ./../Hardware/lenovo-hardware-configuration.nix
    ./../Modules/laptop.nix
  ];

  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = true;

  sound.enable = true;
  networking.hostName = "lenovo";
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.wireless.enable = true; # Enables wireless support via wpa_supplicant.
  networking.wireless.networks = {
    FritzBox = {
      psk = lib.strings.fileContents ./wlanPassword.txt;
    };
  };
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
  users.users.tim = {
    name = "tim";
    home = "/home/tim";
    extraGroups = [
      "wheel"
      "audio"
    ];
    isNormalUser = true;
  };

  environment.pathsToLink = [ "/libexec" ];

  services.xserver = {
    enable = true;

    desktopManager = {
      xterm.enable = false;
    };

    displayManager = {
      defaultSession = "none+i3";
    };

    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu # application launcher most people use
        i3status # gives you the default i3 status bar
        i3lock # default i3 screen locker
        i3blocks # if you are planning on using i3blocks over i3status
        alacritty
      ];
    };
  };

  environment.systemPackages = with pkgs; [ ];

  boot.loader.grub.configurationLimit = 10;

  home-manager.users.tim = (import ./../MyHomeConfiguration/Users/tim-lenovo-home.nix).dark;

  services.openssh.enable = true;

  system.stateVersion = "22.05"; # Did you read the comment?
}
