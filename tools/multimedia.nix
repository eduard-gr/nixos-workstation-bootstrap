{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    spotify
    vlc
    kdePackages.kdenlive

  ];
}
