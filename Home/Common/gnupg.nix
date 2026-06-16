{ config, pkgs, ...}:

{
  programs.gpg.enable = true;

  services.gpg-agent.enable = true;
  services.gpg-agent.pinentry.package = pkgs.pinentry-curses;

}
