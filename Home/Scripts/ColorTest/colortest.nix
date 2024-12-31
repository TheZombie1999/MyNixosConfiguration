# { writeShellApplication, colors, lib }:

# https://discourse.nixos.org/t/need-help-understanding-how-to-escape-special-characters-in-the-list-of-str-type/11389/3

{ writeShellApplication, symlinkJoin, colors, lib }:

with lib;

let
  source= symlinkJoin {
    name = "symlinks";
    paths = [ colors ];
    postBuild = ''
      mkdir -p $out/lib
    '';
  };
in
writeShellApplication {
    name = "colortest";

    extraShellCheckFlags = [ "-P" "${source}/lib" "-x" ];

    text = ''
      SOURCE="${source}/lib"

      ${fileContents ./colortest.sh} 
    '';
}

