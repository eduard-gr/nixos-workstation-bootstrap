{ pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    libreoffice-qt-fresh
    adwaita-icon-theme
    hicolor-icon-theme
  ];

  # environment.sessionVariables = {
  #   QT_QPA_PLATFORMTHEME = "qt5ct";
  # };

}
