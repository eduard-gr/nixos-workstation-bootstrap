{ pkgs, ... }:

# Imperative SDK strategy: Android Studio manages the SDK in $HOME/android/sdk.
# nix-ld below is what makes the prebuilt SDK binaries (aapt2, adb, emulator)
# downloaded by Studio work on NixOS.

{
  nixpkgs.config.android_sdk.accept_license = true;

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

      alsa-lib
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
      libxkbfile
      libXinerama
      libXrandr
      libXres
      libXv
      libxkbcommon
      libxcb-cursor
      xcb-util-cursor

      libbsd
      atk
      at-spi2-atk
      cups
      libdrm

      libpulseaudio
      libuuid
      libpng
      libjpeg
      zlib
      mesa

      vulkan-loader
    ];

  environment.systemPackages = [
    pkgs.android-tools
    pkgs.android-studio

    pkgs.gnumake
    pkgs.steam-run
  ];

  environment.variables = {
      ANDROID_HOME = "$HOME/android/sdk";
      ANDROID_SDK_ROOT = "$HOME/android/sdk";
  };
}
