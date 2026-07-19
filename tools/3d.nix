{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    freecad
    qidi-slicer-bin
    lycheeslicer
    orca-slicer
  ];
}
