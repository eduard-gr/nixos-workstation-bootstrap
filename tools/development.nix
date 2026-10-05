{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gcc
    cmake
    javaPackages.compiler.openjdk25
    maven
    go

    ghex
    meld
    #inputs.zed.packages.x86_64-linux.default
    zed-editor
    dbeaver-bin
    postman

    claude-code
    cursor-cli
    code-cursor
    antigravity-ide

    jetbrains.goland
    jetbrains.pycharm
    jetbrains.phpstorm
    jetbrains.idea

    grpc-tools
    protobuf
    protoc-gen-grpc-java

    # adb, fastboot, mke2fs. Android work itself happens inside the per-project
    # FHS environment (android-dev/), which ships its own platform-tools, but
    # having adb on PATH outside it means a plugged-in phone can be queried from
    # any terminal without first cd'ing into a project.
    android-tools

    gnumake

    # Escape hatch for running a foreign binary without entering a project
    # environment: steam-run <binary>.
    steam-run
  ];

  # Lets unpatched, downloaded binaries run outside an FHS sandbox — a Gradle
  # wrapper pulling aapt2 from Maven, a vendored node/python toolchain, a
  # release artifact from a CI job. Inside android-dev/ this is redundant
  # (buildFHSEnv provides a real /lib64); outside it, this is what stands in.
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

  # Per-project dev environments: a project drops a flake.nix plus an .envrc
  # containing `use flake`, and direnv activates it on cd. nix-direnv keeps the
  # resulting shell in the store and registers a GC root, so re-entering the
  # directory is instant and nix-collect-garbage does not discard it.
  # Zed is configured to pick this up (home/eg.nix: load_direnv = "shell_hook").
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  services = {
    nginx.enable = false;
    httpd.enable = false;
  };
}
