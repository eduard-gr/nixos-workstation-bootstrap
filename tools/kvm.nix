{ pkgs, ... }:

{
  boot.kernelModules = [ "kvm-amd" ];
  virtualisation.libvirtd.enable = true;

  programs.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
    dnsmasq
    virtiofsd
  ];

  networking.firewall.trustedInterfaces = [ "virbr0" ];
}
