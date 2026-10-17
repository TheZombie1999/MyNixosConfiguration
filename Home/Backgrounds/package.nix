{ pkgs, stdenv, ... }:

stdenv.mkDerivation {
  pname = "background";
  version = "1.0";

  src = ./Dark;

  sourceRoot = "Dark";

  nativeBuildInputs = [ pkgs.tree ];

  installPhase = /* bash */ ''
    mkdir $out
    cp ./nix-wallpaper-nineish-dark-gray.png $out/image.png
  '';
}
