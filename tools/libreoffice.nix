{ pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    libreoffice-qt-fresh
    adwaita-icon-theme
    hicolor-icon-theme

    kdePackages.qt6ct
    kdePackages.breeze-icons
  ];

  environment.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt6ct";
  };

}
