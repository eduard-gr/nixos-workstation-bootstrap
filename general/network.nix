# Enable NetworkManager for GUI setups

# `nmtui` can be used to manage network connections

# Include this file in /etc/nixos/configuration.nix imports section
# and run `nixos-rebuild switch --upgrade-all` to sync system state
{ pkgs, ... }:

{
  networking.networkmanager.enable = true;

  environment.systemPackages = with pkgs; [
    networkmanager-l2tp
    strongswan
  ];
}
