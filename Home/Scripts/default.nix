{ pkgs, ... }:

# https://nix.dev/tutorials/callpackage.html

let
  callPackage = pkgs.lib.callPackageWith (pkgs // packages);
  packages = {
    open = callPackage ./open.nix { };
    gitlist = callPackage ./gitlist.nix { };
    colors = callPackage ./Colors/colors.nix { };
    colortest = callPackage ./ColorTest/colortest.nix { };
    comment-code = callPackage ./CommentCode/comment-code.nix { };
    implement = callPackage ./Implement/implement.nix { };
    explain = callPackage ./Explain/explain.nix { };
    ask = callPackage ./Ask/ask.nix { };
    about = callPackage ./About/about.nix { };
  };
in
{
  home.packages = with packages; [
    open
    gitlist
    colortest
    comment-code
    implement
    explain
    ask
    about
  ];
}
