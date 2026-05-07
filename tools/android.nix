{ pkgs, lib, ... }:

{
  #systemd 258 no longer has any effect
  #programs.adb.enable = true;

  #list devices
  #services.udev.packages = [ pkgs.android-udev-rules ];
  nixpkgs.config.android_sdk.accept_license = true;

  #enable dynamic libs
  #programs.nix-ld.enable = true;
  # programs.nix-ld.libraries = with pkgs; [
  #     stdenv.cc.cc
  #     libGL
  #     glib
  #     nss
  #     nspr
  #     expat
  #     fontconfig
  #     freetype
  #     dbus
  #     udev
  #     libvirt

  #     alsa-lib
  #     libx11
  #     libxcursor
  #     libxcomposite
  #     libxdamage
  #     libxext
  #     libxfixes
  #     libxi
  #     libxrender
  #     libxtst
  #     libxcb
  #     libXScrnSaver
  #     libxkbfile
  #     libXinerama
  #     libXrandr
  #     libXres
  #     libXv
  #     libxkbcommon
  #     libxcb-cursor
  #     xcb-util-cursor

  #     libbsd
  #     atk
  #     at-spi2-atk
  #     cups
  #     libdrm

  #     libpulseaudio
  #     libuuid
  #     libpng
  #     libjpeg
  #     zlib
  #     mesa
  #     libdrm

  #     vulkan-loader
  #   ];

  environment.systemPackages = with pkgs; [
    android-tools
    android-studio-full

    androidenv.androidPkgs.androidsdk
    androidenv.androidPkgs.emulator
    androidenv.androidPkgs.platform-tools
    androidenv.androidPkgs.ndk-bundle

    gnumake
    steam-run
  ];

  # environment.variables = {

  #     ANDROID_HOME = "$HOME/android/sdk";
  #     ANDROID_SDK_ROOT = "$HOME/android/sdk";
  #     ANDROID_AVD_HOME = "$HOME/.config/.android/avd";

  #     PATH = [
  #       "$HOME/android/sdk/platform-tools"
  #       "$HOME/android/sdk/emulator"
  #       "$HOME/android/sdk/cmdline-tools/latest/bin"
  #     ];
  # };

  # environment.shellAliases = {
  #     emulator = "QT_QPA_PLATFORM=xcb steam-run $HOME/android/sdk/emulator/emulator -gpu swiftshader_indirect";
  # };

}
