{config, pkgs, ...}:

{
  home.packages = with pkgs; [
    zellij
    tree
    moreutils
    duf # Disk Usage 
    aria2 # Better wget
    bat # Better cat
    entr # Run Command on file change
    # zeek # Shell Command example Collection
    eza # Better ls
    nodePackages.bash-language-server # Bash Autocompletion
    alacritty
    nil
    lnav # Logfile navigator
    keepassxc
    meh # Super Light wait image viewer
    chromium
    neofetch
  ];
}
