{ pkgs, ... }:

{
  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    freecad
    qidi-slicer-bin
    LycheeSlicer
  ];
}
