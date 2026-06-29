{ pkgs, ... }:

{
  home.packages = with pkgs; [ gitui ];

  home.file."key_bindings.ron" = {
    source = ./key_bindings.ron;
    target = ".config/gitui/key_bindings.ron";
  };
}
