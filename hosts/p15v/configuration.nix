{ pkgs, lib, ... }:

# Target hardware:
#   Manufactory: Lenovo ThinkPad p15v Gen 3
#   Bios version: N3KET43W (1.21)
#   Cpu type: AMD Ryzen 7 PRO 6850H with Radeon 680M iGPU
#   Gpu type: AMD Radeon 680M iGPU
#   Nvidia gpu type: NVIDIA RTX A2000 Laptop GPU

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
    ../../tools/php83.nix
    ../../tools/libreoffice.nix
    ../../tools/multimedia.nix
    ../../tools/3d.nix
    ../../tools/kvm.nix
    ../../tools/python.nix
    ../../tools/frontend.nix
    #../../tools/ai.nix
    ../../tools/agentic.nix
  ];

  assertions = [
    {
      assertion =
        gpuBusIds.amdgpuBusId != ""
        && gpuBusIds.nvidiaBusId != ""
        # Equal IDs mean detection picked the same card twice (an old
        # detect-gpu-bus-ids.sh bug did exactly that), never a valid PRIME pair.
        && gpuBusIds.amdgpuBusId != gpuBusIds.nvidiaBusId;
      message = ''
        Fill gpu-bus-ids.nix with the real AMD and NVIDIA PCI Bus IDs
        (they must be non-empty and different). Run on the ThinkPad P15v:
          nix shell nixpkgs#pciutils -c bash ./detect-gpu-bus-ids.sh
      '';
    }
  ];

  # Recent kernel for the Ryzen 7 PRO 6850H / Radeon 680M platform.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Store NVIDIA video-memory snapshots outside a potentially RAM-backed /tmp.
  # amd_pstate=active gives the kernel full EPP-based control of the Zen3+
  # (Rembrandt) CPU's frequency scaling, instead of falling back to the
  # older acpi-cpufreq / "guided" behaviour.
  boot.kernelParams = [
    # Receives the VRAM snapshot on suspend — see checklist item 5.
    # NVreg_UseKernelSuspendNotifiers and NVreg_PreserveVideoMemoryAllocations
    # are deliberately NOT repeated here: the NixOS NVIDIA module already sets
    # both via hardware.nvidia.moduleParams (from powerManagement.enable and
    # .kernelSuspendNotifier below) and writes them to modprobe.d.
    "nvidia.NVreg_TemporaryFilePath=/var/tmp"

    # Correct for this machine: /sys/power/mem_sleep offers only "[s2idle]"
    # (verified on the P15v, 2026-10-05) — the platform has no S3/"deep" at
    # all, so S0ix power management matches reality. The module does not set
    # this one itself.
    "nvidia.NVreg_EnableS0ixPowerManagement=1"

    "amd_pstate=active"

    # The three below are workarounds, and each one costs sleep quality. When
    # bisecting a suspend/resume problem, remove them ONE AT A TIME and re-test;
    # dropping all three at once tells you nothing.
    #   nvme_core...=0 disables NVMe APST outright, so the SSD never enters a
    #                  low-power state during s2idle.
    #   pcie_aspm=off  keeps PCIe links out of low-power states, which works
    #                  against both S0ix residency and the RTD3 runtime
    #                  power-down enabled by nvidia.powerManagement.finegrained
    #                  just below — this file asks for both at once.
    #   iommu=soft     forces SWIOTLB instead of the hardware IOMMU; unusual on
    #                  AMD and at odds with the PCI passthrough that
    #                  tools/kvm.nix implies.
    "nvme_core.default_ps_max_latency_us=0"
    "pcie_aspm=off"
    "iommu=soft"
  ];

  # Load amdgpu in the initrd so the iGPU (the boot/display GPU in this PRIME
  # offload setup) gets KMS as early as possible, avoiding a mode switch/flicker
  # right before the display manager starts.
  boot.initrd.kernelModules = [ "amdgpu" ];

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
    # Newest production/new-feature branch packaged for the selected kernel
    # (flake.nix currently tracks nixos-unstable). To include beta drivers in
    # future, use "bleeding_edge".
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
  # userspace libraries and nvidia-vaapi-driver automatically; the Mesa drivers
  # for the iGPU come with hardware.graphics.enable itself. extraPackages is
  # only for extra driver backends.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
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
    ];
  };

  security.sudo.wheelNeedsPassword = true;

  # ---------------------------------------------------------------------------
  # SUSPEND / HIBERNATE — audit checklist, re-verified on the P15V 2026-10-05
  #
  # 1. RESOLVED. The logind keys below used to be spelled LidSwitch/PowerKey/
  #    PowerKeyLongPress; logind.conf(5) wants Handle* names, and systemd
  #    logged "Unknown key 'LidSwitch' in section [Login], ignoring" for all
  #    three. They are renamed now. (services.logind.settings.Login is a
  #    freeform attrset — NixOS writes through whatever it is given without
  #    validating, so typos here are silent.)
  #
  # 2. STILL OPEN. Renaming them changes little under KDE: PowerDevil takes
  #    the lid and the power key away from logind with an inhibitor in
  #    "block" mode (verified: systemd-inhibit --list shows PowerDevil with
  #    handle-power-key:handle-suspend-key:handle-hibernate-key:
  #    handle-lid-switch, mode block), so Plasma's own power settings decide.
  #    logind only governs the no-session case (SDDM greeter, TTY). The real
  #    policy belongs in Plasma, which can be declared via plasma-manager in
  #    home/eg.nix — that file currently sets nothing power-related.
  #
  # 3. VERIFIED, with one caveat. Swap exists and is large enough: a 59.6 GiB
  #    partition vs 30 GiB RAM, declared in hardware-configuration.nix as
  #    /dev/disk/by-uuid/... — the /dev/ prefix means stage-1 derives the
  #    resume device from it automatically. CAVEAT: the root filesystem is on
  #    LUKS (cryptroot) but the swap partition is NOT encrypted, so
  #    hibernation writes the full RAM image to disk in plaintext. To close
  #    that hole, move swap inside LUKS (or a second LUKS volume) — resume
  #    then needs the initrd to unlock it.
  #
  # 4. VERIFIED. /sys/power/mem_sleep is "[s2idle]" — s2idle is the ONLY mode
  #    this platform offers, there is no S3/"deep". SuspendState=mem below
  #    therefore always resolves to s2idle, and NVreg_EnableS0ixPowerManagement
  #    (kernelParams above) agrees with reality. Nothing to pin: with a single
  #    available mode, mem_sleep_default= would be a no-op.
  #
  # 5. VERIFIED. /var/tmp (receives the VRAM snapshot via
  #    NVreg_TemporaryFilePath) is a btrfs subvolume on cryptroot, not tmpfs,
  #    so the 4-8 GB A2000 snapshot does not land back in RAM.
  #
  # 6. If resume breaks on the GPU specifically: kernelSuspendNotifier = true
  #    means nixpkgs deliberately does NOT create the nvidia-suspend,
  #    nvidia-hibernate and nvidia-resume services (confirmed: no such units
  #    exist on the running system). Flipping it to false brings the classic
  #    scripts back and is a useful bisect lever.
  #
  # 7. Dynamic Boost is real on this machine: nvidia-powerd is active
  #    (running). After a failed wake-up, these show where it fell over:
  #      journalctl -b -1 -p err --no-pager | tail -40
  #      journalctl -b | grep -iE "PM: |suspend|resume|hibernat" | tail -40
  # ---------------------------------------------------------------------------

  # Suspend first, then hibernate after the configured delay. These only apply
  # outside a Plasma session — see checklist item 2.
  services.logind.settings.Login.HandleLidSwitch = "suspend-then-hibernate";
  services.logind.settings.Login.HandlePowerKey = "hibernate";
  services.logind.settings.Login.HandlePowerKeyLongPress = "poweroff";

  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "30m";
    SuspendState = "mem";
  };

  # Keep the value from the installed system. Do not change it merely because
  # the NixOS channel was upgraded.
  system.stateVersion = "26.05";
}
