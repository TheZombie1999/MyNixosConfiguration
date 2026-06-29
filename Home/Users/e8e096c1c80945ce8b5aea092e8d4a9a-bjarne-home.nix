{ config, pkgs, ... }:

let
  nix-colors = import <nix-colors> { };
in
{
  imports = [
    nix-colors.homeManagerModules.default
    ../Common
    ../Work
    ../Scripts
  ];

  mymodules.labor = {
    enable = false;
    jump = true;
  };

  colorScheme = nix-colors.colorSchemes.gruvbox-dark-hard;

  programs.bash.initExtra = ''
    # if ! mountpoint -q /mnt/servicebot ; then
    #   sudo mkdir -p /mnt/servicebot
    #   sudo mount -t cifs //10.0.215.28/share /mnt/servicebot -o credentials=/home/bjarne/.config/Servicebot/credentials -o uid=1000 -o gid=1000 &
    # fi

    # if ! ssh-add -l | rg -q bjarne@bjarne-sdk ; then
    #   ssh-add ~/Github/MyNixosConfiguration/Home/Keys/bjarne-bjarne-sdk
    # fi

    if ! mountpoint -q /home/bjarne/Documents; then
      mkdir -p /home/bjarne/Documents
      sudo mount -t vboxsf -o rw,uid=1000,gid=1000 doc /home/bjarne/Documents
    fi

    export LANG=de_DE.UTF-8

    PATH="$PATH:/snap/bin"
  '';

  home = {
    username = "bjarne";
    homeDirectory = "/home/bjarne";
    packages = with pkgs; [
      cifs-utils
      ncdu # A Amazing tool to find Large Files that you want to delete
      htop-vim # htop with vim bindings
      hishtory # A tool for a better bash history
      eza
      nil # A Lanuage Server
      glab
      # ranger
      broot
      # magic-wormhole
      moreutils
      # helix
      gitui
      ventoy-full # Bootable usb tool
      # tilda
      # mygit
      git
    ];

    stateVersion = "23.11"; # Please read the comment before changing.
  };
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
