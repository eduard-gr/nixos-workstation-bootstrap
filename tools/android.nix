{ pkgs, ... }:

# Declarative SDK strategy: the Android SDK, emulator and AVD system images
# are built by Nix (androidenv) and live in /nix/store. Android Studio is
# pointed at that SDK via ANDROID_HOME and must never download its own copy —
# the store path is read-only, so to add SDK components extend the lists
# below and rebuild instead of using Studio's SDK Manager.

let
  androidComposition = pkgs.androidenv.composeAndroidPackages {

    includeNDK = true;
    includeEmulator = true;
    includeSystemImages = true;

    platformToolsVersion = "37.0.1";
    buildToolsVersions = [ "34.0.0" ];
    platformVersions = [ "34"];
    cmakeVersions = [ "3.10.2" ];
    extraLicenses = [
      "android-googletv-license"
      "android-sdk-arm-dbt-license"
      "android-sdk-license"
      "android-sdk-preview-license"
      "google-gdk-license"
      "intel-android-extra-license"
      "intel-android-sysimage-license"
      "mips-android-sysimage-license"
    ];

    systemImageTypes = [ "google_apis" ];
    abiVersions = [ "x86_64" ];

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

  environment.systemPackages = with pkgs; [
    # Provides adb/fastboot/emulator/sdkmanager etc. on PATH; android-tools
    # was dropped to avoid colliding with the SDK's own platform-tools.
    androidComposition.androidsdk
    androidComposition.ndk-bundle

    android-studio

    gnumake
    steam-run
  ];

  environment.variables = {
      ANDROID_HOME = sdkRoot;
      ANDROID_SDK_ROOT = sdkRoot;

      ANDROID_NDK_ROOT = "${sdkRoot}/ndk-bundle";
  };
}
