{ pkgs, ... }:

{
  #no longer has any effect
  #programs.adb.enable = true;

  #list devices
  #services.udev.packages = [ pkgs.android-udev-rules ];

  #enable dynamic libs
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
      stdenv.cc.cc
      libGL
      glib
      nss
      nspr
      expat
      fontconfig
      freetype
      dbus
      udev
      libvirt
      xorg.libX11
      xorg.libXcursor
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXi
      xorg.libXrender
      xorg.libXtst
      libpulseaudio
      libuuid
    ];

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
