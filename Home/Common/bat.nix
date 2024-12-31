{ pkgs, ... }:
{
  programs.bat = {
    enable = true;
    extraPackages = with pkgs.bat-extras; [ batdiff batman batgrep batwatch ];
    config = {};
  };

  programs.bash.shellAliases = {
    cat = "bat -P";
  };

}
