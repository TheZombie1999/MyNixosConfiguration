{ writeShellApplication, pkgs }:

writeShellApplication {
  name = "yaziOpener";
  runtimeInputs = with pkgs; [
    zellij
    alacritty
  ];
  bashOptions = [ "errexit" ];
  text = builtins.readFile ./yaziOpener.sh;
}
