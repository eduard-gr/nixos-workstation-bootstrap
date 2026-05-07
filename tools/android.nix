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

  environment.variables = {
      ANDROID_HOME = "$HOME/android/sdk";

      PATH = [
        "$HOME/android/sdk/platform-tools"
        "$HOME/android/sdk/emulator"
        "$HOME/android/sdk/cmdline-tools/latest/bin"
      ];
    };
}
