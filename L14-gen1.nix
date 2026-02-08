{ config, pkgs, lib, ... }:

{
  imports = [
    ./general/i18n.nix
    ./general/pipewire.nix
    ./general/network.nix

    ./desktops/kde.nix
  ];

  networking.hostName = "l14";

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Firmware / microcode
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;

  services.xserver.enable = false;
  #services.xserver.videoDrivers = [ "amdgpu" ];

  #enable wayland + sddm for correct fas user switch
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };


  # (OpenGL/Vulkan/VA-API)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa
      libva
      libva-utils
      vaapiVdpau
      libvdpau-va-gl
      vulkan-loader
      vulkan-validation-layers
    ];
  };

  environment.systemPackages = with pkgs; [
    mesa
    mesa-demos
    vulkan-tools
    wayland
    wayland-utils
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";  # for Electron/Chromium
    # LIBVA_DRIVER_NAME = "radeonsi";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # ThinkPad: firmware update
  services.fwupd.enable = true;
  services.acpid.enable = true;

  # ThinkPad + Linux: tlp power control
  services.tlp.enable = true;
  services.power-profiles-daemon.enable = lib.mkForce false;

  #  fingerprint readers handling.
  services.fprintd.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  hardware.enableAllFirmware = true;
  environment.variables = {
    NIXPKGS_ALLOW_UNFREE = "1";
  };

  # Cap old NixOS generations
  # https://hugosum.com/blog/how-to-avoid-too-many-old-nixos-generations
  boot.loader.systemd-boot.configurationLimit = 10; # only 10 generations are kept
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.eg = {
    isNormalUser = true;
    description = "eg";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  # Before changing this value read the documentation for this option
  #https://search.nixos.org/options?channel=25.11&show=system.stateVersion&query=system.stateVersion
  system.stateVersion = "25.11";
}
