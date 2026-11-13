# Printing and scanning for network printers (HP Color LaserJet MFP M182,
# Epson L3250). Both speak driverless IPP/eSCL, so avahi discovery plus
# sane-airscan covers most of it; hplip and epson-escpr are the classic
# drivers as a fallback. Printers themselves are added in KDE System
# Settings -> Printers (stored by CUPS, not in this repo).
{ pkgs, ... }:

{
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      hplip
      epson-escpr
    ];
  };

  # Finds printers/scanners on the LAN and resolves *.local names.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  hardware.sane = {
    enable = true;
    extraBackends = with pkgs; [
      sane-airscan
      hplip
    ];
  };

  environment.systemPackages = with pkgs; [
    kdePackages.skanpage  # KDE scanning app
  ];
}
