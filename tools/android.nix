{ pkgs, ... }:

# Android development runs inside a Distrobox container (Ubuntu), not in Nix.
# Android Studio, the SDK, NDK, emulator and Gradle all expect a regular FHS
# Linux; inside the container they get one, while $HOME is shared with the
# host so ~/Android/Sdk, ~/.android, ~/.gradle and the projects themselves
# stay where they are. The container is described declaratively in
# android-dev/distrobox.ini — see android-dev/README.md.
#
# /dev/kvm (emulator) comes from tools/kvm.nix plus the "kvm" group on the
# user; distrobox keeps the host groups inside the container. USB phones need
# nothing extra: systemd >= 258 grants uaccess to Android devices on its own.
{
  environment.systemPackages = with pkgs; [
    distrobox
  ];

  # Rootless podman is distrobox's preferred backend. It coexists with the
  # docker daemon from tools/docker.nix as long as dockerCompat stays off
  # (dockerCompat would install a `docker` shim that collides with it).
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    defaultNetwork.settings.dns_enabled = true;
  };

  # Both docker and podman are installed; pin distrobox to podman so it never
  # picks the rootful docker daemon (which would need sudo for every command).
  environment.etc."distrobox/distrobox.conf".text = ''
    container_manager="podman"
  '';

  # install-android-studio.sh exports adb/fastboot from the container's SDK
  # into ~/.local/bin; put that on PATH for host shells.
  environment.localBinInPath = true;
}
