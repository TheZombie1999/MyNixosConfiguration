{
  description = "My Private Nixos Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations = {
        "microstar" = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./Maschines/microstar.nix
            ];
        };
      };
  };
}
