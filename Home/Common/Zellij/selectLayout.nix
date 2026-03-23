{ writeShellApplication, pkgs }:

writeShellApplication {
  name = "selectLayout";
  runtimeInputs = with pkgs; [ zellij fzf ];
  # bashOptions = [ "errexit" ];
  text = builtins.readFile ./selectLayout.sh;
}


