{ pkgs, pkgs-android, ... }:
let
  my-android-sdk = pkgs-android.androidenv.composeAndroidPackages {
    platformVersions = [ "34" "35" "36" "37" ];
    abiVersions = [ "x86_64" ];
    includeSystemImages = true;
    includeEmulator = true;
    systemImageTypes = [ "google_apis_playstore" ];
  };
in
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
      libvirt

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
      libdrm

      vulkan-loader
    ];

  environment.systemPackages = [
    pkgs-android.android-tools
    pkgs-android.android-studio-full

    my-android-sdk.androidsdk
    my-android-sdk.emulator
    my-android-sdk.platform-tools
    #my-android-sdk.ndk-bundle

    pkgs.gnumake
    pkgs.steam-run
  ];


  environment.etc."android-sdk".source = "${my-android-sdk.androidsdk}/libexec/android-sdk";
  environment.variables = {

      #ANDROID_HOME = "${my-android-sdk.androidsdk}/libexec/android-sdk";
      #ANDROID_SDK_ROOT = "${my-android-sdk.androidsdk}/libexec/android-sdk";

      ANDROID_HOME = "$HOME/android/sdk";
      ANDROID_SDK_ROOT = "$HOME/android/sdk";
      ANDROID_AVD_HOME = "$HOME/.config/.android/avd";
  };

  # environment.shellAliases = {
  #     emulator = "QT_QPA_PLATFORM=xcb steam-run $HOME/android/sdk/emulator/emulator -gpu swiftshader_indirect";
  # };

}
