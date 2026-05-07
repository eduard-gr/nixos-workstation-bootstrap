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

      libx11
      libxcursor
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxi
      libxrender
      libxtst
      libxcb
      libXScrnSaver
      libxkbfile      # <--- ТЕКУЩАЯ ОШИБКА
      libXinerama
      libXrandr
      libXres
      libXv


      libpulseaudio
      libuuid
      libpng
      libjpeg
      zlib
      mesa
      libdrm
      libxkbcommon
      vulkan-loader
    ];

  environment.systemPackages = with pkgs; [
    android-tools
    android-studio-full
    gnumake
    steam-run
  ];

  environment.variables = {
      ANDROID_HOME = "$HOME/android/sdk";
      ANDROID_SDK_ROOT = "$HOME/android/sdk";
      ANDROID_AVD_HOME = "$HOME/.config/.android/avd";

      PATH = [
        "$HOME/android/sdk/platform-tools"
        "$HOME/android/sdk/emulator"
        "$HOME/android/sdk/cmdline-tools/latest/bin"
      ];
    };
}
