# Enables essential CLI tools

# Include this file in /etc/nixos/configuration.nix imports section
# and run `nixos-rebuild switch --upgrade-all` to sync system state

{ pkgs, ... }:

{
  # Not enabled by default, even though some nixos utilities rely on it?
  programs.git = {
    enable = true;
    config.user = {
      name = "Edaurds Gruberts";
      email = "edaurds.gruberts@gmail.com";
    };
  };

  programs.lazygit.enable = true;

  programs.vim.enable = true;
  programs.vim.defaultEditor = true;

  programs.screen.enable = true;

  # https://search.nixos.org/packages
  environment.systemPackages = with pkgs; [
    vim
    htop
    mc
    nmap
    wget
    appimage-run
    openssl_3_5
    dig
    unixtools.netstat

  ];
}
