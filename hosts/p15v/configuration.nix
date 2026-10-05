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
  # amd_pstate=active gives the kernel full EPP-based control of the Zen3+
  # (Rembrandt) CPU's frequency scaling, instead of falling back to the
  # older acpi-cpufreq / "guided" behaviour.
  boot.kernelParams = [
    # Receives the VRAM snapshot on suspend — see checklist item 5.
    "nvidia.NVreg_TemporaryFilePath=/var/tmp"

    # Redundant: the NixOS NVIDIA module already sets both of these from
    # hardware.nvidia.powerManagement.kernelSuspendNotifier and .enable
    # (nixos/modules/hardware/video/nvidia.nix). Not broken, but the module
    # writes them into modprobe.d while these go on the kernel cmdline, so a
    # future divergence would be painful to debug.
    "nvidia.NVreg_UseKernelSuspendNotifiers=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"

    # Only correct when this machine really suspends via s2idle/S0ix — see
    # checklist item 4. If the BIOS sleep state is "Linux"/S3 and the kernel
    # uses "deep", this flag contradicts reality.
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
    ];
  };

  security.sudo.wheelNeedsPassword = true;

  # ---------------------------------------------------------------------------
  # SUSPEND / HIBERNATE — what to verify on this laptop
  #
  # Items found while auditing this file. Most of them cannot be checked from
  # another machine, so work through them ON THE P15V itself.
  #
  # 1. The three logind keys below are misspelled and systemd ignores them.
  #    services.logind.settings.Login is a freeform attrset, so NixOS writes
  #    through whatever it is given without validating. The valid names all
  #    start with "Handle" — see logind.conf(5), and the renames in
  #    nixos/modules/system/boot/systemd/logind.nix which map the old NixOS
  #    options (lidSwitch, powerKey, powerKeyLongPress) onto HandleLidSwitch,
  #    HandlePowerKey and HandlePowerKeyLongPress. Confirmed on l14, which
  #    carries identical lines:
  #      journalctl -b -u systemd-logind | grep -i unknown
  #      -> /etc/systemd/logind.conf:3: Unknown key 'LidSwitch' in section
  #         [Login], ignoring.
  #    Until they are renamed the systemd defaults apply: lid close suspends
  #    (never suspend-then-hibernate) and the power key powers off.
  #
  # 2. Renaming them still changes little under KDE. PowerDevil takes the lid
  #    and the power key away from logind with an inhibitor in "block" mode,
  #    so Plasma's own power settings decide. Check who is in charge:
  #      systemd-inhibit --list | grep -i powerdevil
  #      -> PowerDevil ... handle-power-key:...:handle-lid-switch ... block
  #    logind only governs the no-session case (SDDM greeter, TTY). The real
  #    policy belongs in Plasma, which can be declared via plasma-manager in
  #    home/eg.nix — that file currently sets nothing power-related.
  #
  # 3. Hibernate needs swap and this host declares none. l14 declares its swap
  #    partition in the host file; here it would have to come from the
  #    (gitignored) hardware-configuration.nix. Verify it exists and is at
  #    least as large as RAM:
  #      swapon --show; free -h
  #    A swap FILE is not sufficient by itself: stage-1.nix derives
  #    resumeDevices only from swapDevices entries whose device starts with
  #    /dev/, so a file is filtered out and resume silently fails. For a
  #    swapfile, add explicitly:
  #      boot.resumeDevice = "/dev/nvme0n1pN";
  #      boot.kernelParams = [ "resume_offset=..." ];  # filefrag -v /swapfile
  #
  # 4. The sleep mode this host actually uses is unverified:
  #      cat /sys/power/mem_sleep    # "[s2idle] deep" or "s2idle [deep]"
  #    SuspendState=mem below only writes "mem" to /sys/power/state; what that
  #    resolves to is decided by mem_sleep_default=. l14 pins it explicitly
  #    ("mem_sleep_default=deep"), this host does not pin anything. Once the
  #    answer is known, pin it here via MemorySleepMode= or via
  #    mem_sleep_default= in boot.kernelParams, and make
  #    NVreg_EnableS0ixPowerManagement agree with it (see kernelParams above).
  #
  # 5. /var/tmp receives the VRAM snapshot (NVreg_TemporaryFilePath). The
  #    A2000 Laptop carries 4-8 GB, and a tmpfs would put that straight back
  #    into RAM, defeating the point:
  #      findmnt /var/tmp; df -h /var/tmp
  #
  # 6. If resume breaks on the GPU specifically: kernelSuspendNotifier = true
  #    means nixpkgs deliberately does NOT create the nvidia-suspend,
  #    nvidia-hibernate and nvidia-resume services (nvidia.nix). Flipping it to
  #    false brings the classic scripts back and is a useful bisect lever.
  #
  # 7. After a failed wake-up, these show where it fell over:
  #      journalctl -b -1 -p err --no-pager | tail -40
  #      journalctl -b | grep -iE "PM: |suspend|resume|hibernat" | tail -40
  #      systemctl status nvidia-powerd   # is Dynamic Boost actually supported?
  # ---------------------------------------------------------------------------

  # Suspend first, then hibernate after the configured delay.
  # NOTE: these three keys are ignored by systemd as written — checklist item 1.
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
