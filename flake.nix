{
  description = "NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
        url = "github:nix-community/plasma-manager";
        inputs.nixpkgs.follows = "nixpkgs";
        inputs.home-manager.follows = "home-manager";
    };

    zed.url = "github:zed-industries/zed";
  };

  outputs = { self, nixpkgs, home-manager, plasma-manager, zed, ... }@inputs:
  let
    specialArgs = { inherit inputs; };

  in {
    nixosConfigurations = {

      l14 = nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        modules = [
          ./hosts/l14/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.eg = import ./home/eg.nix;
          }
        ];
      };
    };

    packages.${system}.zed-latest = zed.packages.${system}.default;
  };
}
