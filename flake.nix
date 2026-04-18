{
  description = "My Private Nixos Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-colors.url = "github:misterio77/nix-colors";
    deploy-rs.url = "github:serokell/deploy-rs";
    onedev.url = "/home/tim/OneDev/Onedev-Nixos-Flake";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-colors,
      deploy-rs,
      onedev,
      ...
    }@inputs:
    let
      # Common config for both stable and unstable
      commonPkgsArgs = {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };

      pkgs-stable = import inputs.nixpkgs-stable commonPkgsArgs;
    in
    {
      nixosConfigurations = {
        "bootstrap" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./Images/bootstrap.nix ];
        };
        "microstar" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            inherit home-manager;
            inherit nix-colors;
            inherit pkgs-stable;
          };
          modules = [
            ./Maschines/microstar.nix
          ];
        };
        "moab" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            inherit home-manager;
            inherit nix-colors;
            inherit onedev;
            inherit pkgs-stable;
          };
          modules = [
            ./Maschines/moab.nix
          ];
        };
        "lenovo" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            inherit home-manager;
            inherit nix-colors;
          };
          modules = [
            ./Maschines/lenovo.nix
          ];
        };
        "wsl" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            inherit home-manager;
            inherit nix-colors;
          };
          modules = [
            ./Maschines/wsl.nix
          ];
        };
      };

      deploy.nodes.some-random-system = {
        hostname = "some-random-system";
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.some-random-system;
        };
      };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
