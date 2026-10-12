{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;
  home.packages = with pkgs; [
    obsidian
    zellij
    tree
    moreutils
    duf # Disk Usage
    aria2 # Better wget
    bat # Better cat
    bats # Bash Unit testing
    csvtool
    entr # Run Command on file change
    eza # Better ls
    imagemagickBig
    jq
    keepassxc
    lnav # Logfile navigator
    moreutils
    nil
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
    nodejs # required by claude-code plugins that bundle a node-based MCP server (e.g. hx-remote)
    just
    sops
  ];

  # The chromium package and its command-line args/extensions are both
  # declared through this one module (not also in home.packages) --
  # programs.chromium installs its own finalPackage internally, and listing
  # chromium separately in home.packages collides with it (two different
  # /bin/chromium-browser derivations in the same profile).
  #
  # Extensions are force-installed via enterprise policy -- shown as
  # "installed by your administrator" in chrome://extensions and can't be
  # disabled/removed from the UI, only by editing this list. IDs verified
  # against this machine's actual installed extensions, not guessed.
  programs.chromium = {
    enable = true;
    package = pkgs.chromium.override { enableWideVine = true; };
    # Skip KWallet/keyring integration entirely -- password manager is
    # 1Password, not Chromium's own, so there's nothing sensitive riding on
    # this storage backend. Avoids a KWallet unlock prompt on every fresh
    # profile.
    commandLineArgs = [ "--password-store=basic" ];
    extensions = [
      "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1Password - Passwort-Manager
      "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
      "oldceeleldhonbafppcapldpdifcinji" # LanguageTool
    ];
  };
}
