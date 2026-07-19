{ config, pkgs, lib, ... }:

# Target hardware:
#   AMD Ryzen 7 PRO 6850H
#   AMD Radeon 680M iGPU
#   NVIDIA RTX A2000 Laptop GPU

let
  # Generated on the target laptop by detect-gpu-bus-ids.sh.
  # PRIME cannot be configured safely without the real PCI addresses.
  gpuBusIds = import ../../gpu-bus-ids.nix;
in
{
  imports = [
    ../../hardware-configuration.nix

    ../../general/i18n.nix
    ../../general/pipewire.nix
    ../../general/network.nix

    ../../workspace/kde.nix

    ../../tools/common.nix
    ../../tools/dropbox.nix
    ../../tools/docker.nix
    ../../tools/www.nix
    ../../tools/development.nix
    #../../tools/android.nix
    ../../tools/php83.nix
    ../../tools/libreoffice.nix
    ../../tools/multimedia.nix
    ../../tools/3d.nix
    ../../tools/kvm.nix
    ../../tools/python.nix
    ../../tools/frontend.nix
    #../../tools/ai.nix
  ];

  assertions = [
    {
      assertion =
        gpuBusIds.amdgpuBusId != ""
        && gpuBusIds.nvidiaBusId != "";
      message = ''
        Fill gpu-bus-ids.nix with the real AMD and NVIDIA PCI Bus IDs.
        Run on the ThinkPad P15v:
          nix shell nixpkgs#pciutils -c bash ./detect-gpu-bus-ids.sh
      '';
    }
  ];

  # Recent kernel for the Ryzen 7 PRO 6850H / Radeon 680M platform.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Store NVIDIA video-memory snapshots outside a potentially RAM-backed /tmp.
  boot.kernelParams = [
    "nvidia.NVreg_TemporaryFilePath=/var/tmp"
  ];

  networking.hostName = "p15v";

  # Firmware / microcode
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;

  # Wayland + SDDM. Xorg itself is not used as the desktop session, but the
  # videoDrivers option is also consumed by the NixOS NVIDIA module.
  services.xserver.enable = false;
  services.xserver.videoDrivers = [
    "amdgpu"
    "nvidia"
  ];

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # AMD Radeon 680M + NVIDIA RTX A2000 hybrid graphics.
  # The desktop runs on the Radeon 680M; demanding applications can be started
  # with: nvidia-offload <program>
  hardware.nvidia = {
    # NixOS 26.05: newest production/new-feature branch packaged for the
    # selected kernel. To include beta drivers in future, use "bleeding_edge".
    branch = "latest";

    # RTX A2000 is Ampere, so use NVIDIA's open kernel modules.
    open = true;
    modesetting.enable = true;
    nvidiaSettings = true;
    videoAcceleration = true;

    # Better suspend/hibernate handling and runtime power-off in PRIME offload.
    powerManagement = {
      enable = true;
      finegrained = true;
      kernelSuspendNotifier = true;
    };

    # The P15v Gen 3 AMD advertises NVIDIA Dynamic Boost 2.0 support.
    dynamicBoost.enable = true;

    prime = {
      amdgpuBusId = gpuBusIds.amdgpuBusId;
      nvidiaBusId = gpuBusIds.nvidiaBusId;

      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
    };
  };

  # OpenGL / Vulkan / VA-API. The NixOS NVIDIA module adds the matching NVIDIA
  # userspace libraries and nvidia-vaapi-driver automatically.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa
      libva
      libva-vdpau-driver
    ];
  };

  environment.systemPackages = with pkgs; [
    mesa-demos
    vulkan-tools
    libva-utils
    wayland-utils
    pciutils
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # ThinkPad firmware and ACPI support
  services.fwupd.enable = true;
  services.acpid.enable = true;

  # Power management
  services.tlp.enable = true;
  services.power-profiles-daemon.enable = lib.mkForce false;

  # Fingerprint reader
  services.fprintd.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.config.allowUnfree = true;
  environment.variables.NIXPKGS_ALLOW_UNFREE = "1";

  # Keep only a limited number of old generations.
  boot.loader.systemd-boot.configurationLimit = 10;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  users.users.eg = {
    isNormalUser = true;
    initialPassword = "";
    description = "eg";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "libvirtd"
      "kvm"
      "adbusers"
    ];
  };

  # Suspend first, then hibernate after the configured delay.
  services.logind.settings.Login.LidSwitch = "suspend-then-hibernate";
  services.logind.settings.Login.PowerKey = "hibernate";
  services.logind.settings.Login.PowerKeyLongPress = "poweroff";

  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "30m";
    SuspendState = "mem";
  };

  # Keep the value from the installed system. Do not change it merely because
  # the NixOS channel was upgraded.
  system.stateVersion = "26.05";
}
