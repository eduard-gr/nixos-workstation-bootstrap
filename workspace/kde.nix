# Defines desired GUI Desktop Environment configuration

# Include this file in /etc/nixos/configuration.nix imports section
# and run `nixos-rebuild switch --upgrade-all` to sync system state

{ pkgs, ... }:

{
  # KDE Plasma 6 + Wayland
  services.desktopManager.plasma6.enable = true;

  environment.systemPackages = with pkgs; [
    adwaita-icon-theme
    kdePackages.breeze-icons
    hicolor-icon-theme
    #kdePackages.qt6ct
  ];

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
  };

  # environment.sessionVariables = {
  #   SAL_USE_VCLPLUGIN = "kf5";
  # };

  # https://wiki.nixos.org/wiki/Fonts
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [ corefonts vista-fonts twemoji-color-font ];
    fontconfig = {
      defaultFonts = {
        serif = [ "Liberation Serif" ];
        sansSerif = [ "Liberation Sans" ];
        monospace = [ "Liberation Mono" ];
        emoji = [ "Twemoji" ];
      };
    };
  };
}
