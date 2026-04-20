# Enable NetworkManager for GUI setups

# `nmtui` can be used to manage network connections

# Include this file in /etc/nixos/configuration.nix imports section
# and run `nixos-rebuild switch --upgrade-all` to sync system state
{ config, pkgs, ... }:

{

  networking.firewall.enable = true;
  networking.networkmanager.enable = true;
  networking.networkmanager.plugins = with pkgs; [
        networkmanager-l2tp
    ];

  services.dbus.packages = with pkgs; [
    networkmanager-l2tp
  ];

  environment.systemPackages = with pkgs; [
    networkmanager-l2tp
    strongswan
    ppp
    xl2tpd
  ];

  environment.etc.hosts.enable = false;
}
