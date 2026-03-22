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

    atuin = {
      url = "github:atuinsh/atuin";
    };

    #zed.url = "github:zed-industries/zed";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
    };

    qidi-studio = pkgs.appimageTools.wrapType2 {
      name = "qidi-studio";
      version = "2.05.01.52";

      src = pkgs.fetchurl {
        url = "https://github.com/QIDITECH/QIDIStudio/releases/download/v2.05.01.52/QIDIStudio_v02.05.01.52_Ubuntu24.AppImage";
        sha256 = "sha256:6e342c2d6b81700f6b5b05fc5080a087448a277cd07b5a1959ca9fedbba87ba1";
      };
    };

    specialArgs = {
      inherit inputs;
    };

  in {
    nixosConfigurations = {

      l14 = nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        modules = [
          ./hosts/l14/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              backupFileExtension = "backup";
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit inputs qidi-studio;
              };

              users.eg = import ./home/eg.nix;
            };
          }
        ];
      };
    };
  };
}
