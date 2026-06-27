{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;
  home.packages = with pkgs; [
    zellij
    tree
    moreutils
    duf # Disk Usage
    aria2 # Better wget
    bat # Better cat
    bats # Bash Unit testing
    (chromium.override { enableWideVine = true; })
    csvtool
    entr # Run Command on file change
    eza # Better ls
    imagemagickBig
    jq
    keepassxc
    lnav # Logfile navigator
    meh # Super Light wait image viewer
    nil
    nixfmt
    shfmt
    sttr # Easy String manipulation cli tool
    tree-sitter
    yamlfmt
    yaml-language-server
    yazi
    brave
    rofi
    unar
    usbutils
    yubikey-manager
    yubico-pam
    claude-code
  ];
}
