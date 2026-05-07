{ pkgs, ... }:

{
  #no longer has any effect
  #programs.adb.enable = true;

  #list devices
  #services.udev.packages = [ pkgs.android-udev-rules ];

  environment.systemPackages = with pkgs; [
    android-tools
    android-studio-full
    gnumake
    steam-run
  ];
}
