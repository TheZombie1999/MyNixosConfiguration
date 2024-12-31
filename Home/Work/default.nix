{config, pkgs, ...}:

{
 imports = [
    ./labor.nix
    ./packages.nix
    ./bash.nix
    ./Shellcheck/shellcheck.nix
    ./Keepass
  ];
}
