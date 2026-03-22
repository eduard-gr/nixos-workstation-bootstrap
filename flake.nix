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
      pname = "qidi-studio";
      version = "2.05.01.52";

      src = pkgs.fetchurl {
        url = "https://github.com/QIDITECH/QIDIStudio/releases/download/v2.05.01.52/QIDIStudio_v02.05.01.52_Ubuntu22.AppImage";
        hash = "sha256:c212caf4fd53f7a5e195fd97cfb6acc4af2cd0ec72755e44a710024e76a4ba11";
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
