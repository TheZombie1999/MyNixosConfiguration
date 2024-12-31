
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
    enable = true;
    jump = true;
  };

  colorScheme = nix-colors.colorSchemes.gruvbox-dark-hard;

  home.username = "bjarne";


  programs.bash.initExtra = ''
    if ! mountpoint -q /home/bjarne/Artifacts; then 
      mkdir -p /home/bjarne/Artifacts
      sudo mount -t vboxsf -o rw,uid=1000,gid=1000 art /home/bjarne/Artifacts
    fi 
  
    if ! mountpoint -q /home/bjarne/Gear; then 
      mkdir -p /home/bjarne/Gear
      sudo mount -t vboxsf -o rw,uid=1000,gid=1000 gir /home/bjarne/Gear
    fi

    if ! mountpoint -q /home/bjarne/Images; then 
      mkdir -p /home/bjarne/Images
      sudo mount -t vboxsf -o rw,uid=1000,gid=1000 img /home/bjarne/Images
    fi


    if ! mountpoint -q /home/bjarne/Logs; then 
      mkdir -p /home/bjarne/Logs
      sudo mount -t vboxsf -o rw,uid=1000,gid=1000 log /home/bjarne/Logs
    fi

    if ! mountpoint -q /home/bjarne/Notes; then 
      mkdir -p /home/bjarne/Notes
      sudo mount -t vboxsf -o rw,uid=1000,gid=1000 not /home/bjarne/Notes
    fi

    if ! mountpoint -q /home/bjarne/Organisarotisches; then 
      mkdir -p /home/bjarne/Organisarotisches
      sudo mount -t vboxsf -o rw,uid=1000,gid=1000 org /home/bjarne/Organisarotisches 
    fi

      
    if ! mountpoint -q /home/bjarne/Pki; then 
      mkdir -p /home/bjarne/Pki
      sudo mount -t vboxsf -o rw,uid=1000,gid=1000 pki /home/bjarne/Pki
    fi
  '';
  
  home.homeDirectory = "/home/bjarne";

  home.packages = with pkgs; [
    ncdu # A Amazing tool to find Large Files that you want to delete
    htop-vim # htop with vim bindings
    hishtory # A tool for a better bash history
    eza
    nil # A Lanuage Server
    glab
    ranger
    broot
    # magic-wormhole
    moreutils
    helix
    gitui
    ventoy-full # Bootable usb tool
    tilda
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  home.stateVersion = "23.11"; # Please read the comment before changing.
}
