# Tim's Bjarne Configuration

{ pkgs, ... }:

let
  nix-colors = import <nix-colors> { };
in
{

  imports = [
    nix-colors.homeManagerModules.default
    ../Common
    # ../Personal
    ../Scripts
  ];

  home.username = "tim";
  home.homeDirectory = "/home/tim";

  programs.ranger = {
    enable = true;
    settings = {
      column_ratios = "1,2,3";
    };
  };

  home.packages = with pkgs; [
    ncdu # A Amazing tool to find Large Files that you want to delete
    htop-vim # htop with vim bindings
    hishtory # A tool for a better bash history
    eza
    nil
    glab
    ranger
    broot
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # Bashrc
    # ".bashrc".source = ./bashrc;
    ".gnu-agent" = {
      source = ./../gnu-agent;
      target = ".gnupg/gnu-agent";
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  home.stateVersion = "23.11"; # Please read the comment before changing.
}
