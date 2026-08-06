{ pkgs, ... }:

# Declarative SDK strategy: the Android SDK, emulator and AVD system images
# are built by Nix (androidenv) and live in /nix/store. Android Studio is
# pointed at that SDK via ANDROID_HOME and must never download its own copy —
# the store path is read-only, so to add SDK components extend the lists
# below and rebuild instead of using Studio's SDK Manager.

let
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [ "34" "35" "36" ];
    buildToolsVersions = [ "34.0.0" "35.0.0" "36.0.0" ];

    # Emulator + system images for AVDs (the AVDs themselves are created in
    # Studio's Device Manager as usual and live in ~/.android/avd).
    includeEmulator = true;
    includeSystemImages = true;
    systemImageTypes = [ "google_apis" ];
    abiVersions = [ "x86_64" ];

    includeNDK = false;
    includeSources = false;
  };

  sdkRoot = "${androidComposition.androidsdk}/libexec/android-sdk";
in
{
  nixpkgs.config.android_sdk.accept_license = true;

  # Gradle still downloads some prebuilt binaries itself (e.g. aapt2 from
  # Maven); nix-ld is what lets those run on NixOS.
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
    # Provides adb/fastboot/emulator/sdkmanager etc. on PATH; android-tools
    # was dropped to avoid colliding with the SDK's own platform-tools.
    androidComposition.androidsdk
    pkgs.android-studio

    pkgs.gnumake
    pkgs.steam-run
  ];

  environment.variables = {
      ANDROID_HOME = sdkRoot;
      ANDROID_SDK_ROOT = sdkRoot;
  };
}
