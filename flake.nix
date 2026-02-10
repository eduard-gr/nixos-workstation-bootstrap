{
  description = "NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
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
  };
}
