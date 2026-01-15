{ pkgs, ... }:

{
  home.packages = with pkgs; [
    zellij
    tree
    moreutils
    duf # Disk Usage
    aria2 # Better wget
    bat # Better cat
    bats # Bash Unit testing
    chromium
    csvtool
    duf # Disk Usage
    entr # Run Command on file change
    eza # Better ls
    imagemagickBig
    jq
    keepassxc
    lnav # Logfile navigator
    meh # Super Light wait image viewer
    moreutils
    neofetch
    nil
    nixfmt-rfc-style
    nodePackages.bash-language-server # Bash Autocompletion
    shfmt
    sttr # Easy String manipulation cli tool
    tree
    tree-sitter
    yamlfmt
    yaml-language-server
    yazi
    brave
    rofi
    unar
  ];
}
