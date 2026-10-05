{
  description = "Android development environment (FHS: Android Studio, Gradle, ADB, emulator)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";

      # android-studio is unfree. The flake is evaluated in pure mode, so the
      # NIXPKGS_ALLOW_UNFREE environment variable is not visible here and the
      # permission has to be given in the nixpkgs config itself.
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # The SDK lives in $HOME, not in /nix/store: Android Studio, sdkmanager
      # and Gradle download and update it themselves. buildFHSEnv is what makes
      # those downloaded, non-patchelfed binaries runnable — inside the sandbox
      # there is a real /lib64, /usr/lib and /etc, so the dynamic loader
      # (/lib64/ld-linux-x86-64.so.2) that aapt2, the NDK toolchain and the
      # emulator expect is actually there.
      androidSdkEnv = pkgs.buildFHSEnv {
        name = "android-sdk-env";

        targetPkgs = pkgs:
          (with pkgs; [
            # --- the core of the environment ---
            android-studio
            jdk17
            glibc
            zlib
            ncurses5
            # libstdcxx5 no longer exists in nixpkgs; this is the modern
            # libstdc++.so.6 that the NDK toolchain and aapt2 link against.
            stdenv.cc.cc.lib
            libGL
            alsa-lib
            fontconfig
            freetype

            # --- X11 / XCB ---
            # The xorg.* package set is deprecated in nixos-unstable, these are
            # the current top-level names for the same libraries.
            libx11
            libxext
            libxdamage
            libxfixes
            libxrender
            libxcb
          ])
          ++ (with pkgs; [
            # --- additionally required in practice ---

            # IntelliJ/Studio UI toolkit
            libxi
            libxtst
            libxrandr
            libxcursor
            libxinerama
            libxscrnsaver
            libxcomposite
            libxkbfile
            libxkbcommon
            libxcb-cursor
            libxcb-util
            libxcb-wm
            libxcb-image
            libxcb-keysyms
            libxcb-render-util
            libxshmfence
            gtk3
            glib
            cairo
            pango
            gdk-pixbuf
            atk
            at-spi2-atk
            at-spi2-core
            nss
            nspr
            expat
            dbus
            cups
            libnotify
            libuuid
            fribidi
            harfbuzz

            # emulator: audio, GL/Vulkan, KMS
            libpulseaudio
            pipewire
            libdrm
            libgbm
            mesa
            libva
            vulkan-loader
            wayland

            # Gradle, sdkmanager and native builds
            gnumake
            cmake
            ninja
            pkg-config
            gcc
            binutils
            patchelf
            python3
            ruby
            perl
            git
            openssh
            curl
            wget
            unzip
            zip
            gnutar
            gzip
            bzip2
            xz
            openssl
            libxml2
            libxslt

            # basic userland inside the sandbox
            coreutils
            findutils
            which
            file
            gnugrep
            gnused
            gawk
            procps
            psmisc
            lsof
            util-linux
            e2fsprogs
          ]);

        profile = ''
          export ANDROID_HOME="$HOME/Android/Sdk"
          export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
          export ANDROID_USER_HOME="$HOME/.android"
          export ANDROID_AVD_HOME="$HOME/.android/avd"

          export JAVA_HOME="${pkgs.jdk17.home}"
          export GRADLE_USER_HOME="''${GRADLE_USER_HOME:-$HOME/.gradle}"

          export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$JAVA_HOME/bin:$PATH"

          # IntelliJ-based IDEs under a Wayland compositor (KDE Plasma 6).
          export _JAVA_AWT_WM_NONREPARENTING=1

          mkdir -p "$ANDROID_HOME" "$ANDROID_AVD_HOME"
        '';

        runScript = "bash";
      };
    in
    {
      # `nix develop` / direnv `use flake`
      devShells.${system}.default = androidSdkEnv.env;

      # `nix run .#android-sdk-env` — drops straight into the FHS shell
      # without direnv, e.g. from a different machine.
      packages.${system} = {
        default = androidSdkEnv;
        android-sdk-env = androidSdkEnv;
      };
    };
}
