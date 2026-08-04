{
  description = "My Private Nixos Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-colors.url = "github:misterio77/nix-colors";
    deploy-rs.url = "github:serokell/deploy-rs";
    # sheets.url = "github:maaslalani/sheets/v0.3.0";
    # onedev.url = "github:thezombie1999/Onedev-Nixos-Flake";
    finanzbro.url = "path:/home/tim/OneDev/FinanzeBro";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-colors,
      deploy-rs,
      ...
    }@inputs:
    let
      commonPkgsArgs = {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };

      pkgs = nixpkgs.legacyPackages."x86_64-linux";

      pkgs-unstable = import inputs.nixpkgs-unstable commonPkgsArgs;
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
            inherit pkgs-unstable;
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
            inherit pkgs-unstable;
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
            inherit pkgs-unstable;
          };
          modules = [
            ./Maschines/lenovo.nix
          ];
        };
        "nixos-onedev" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./Maschines/nixos-onedev.nix
          ];
        };
        "wsl" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            inherit home-manager;
            inherit nix-colors;
            inherit pkgs-unstable;
          };
          modules = [
            ./Maschines/wsl.nix
          ];
        };
      };

      devShells."x86_64-linux".default = pkgs.mkShell {
        packages = [
          deploy-rs.outputs.packages."x86_64-linux".deploy-rs
        ]
        ++ (with pkgs; [
          pre-commit
          nixfmt
          statix
          deadnix
        ]);
        shellHook = ''
          pre-commit install
        '';
      };

      deploy.nodes.nixos-onedev = {
        hostname = "nixos-onedev";
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."nixos-onedev";
          sshUser = "tim";
        };
      };

      checks = builtins.mapAttrs (_system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
