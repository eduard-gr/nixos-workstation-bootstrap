{ config, pkgs, inputs, ... }:

{

  imports = [
    inputs.plasma-manager.homeManagerModules.plasma-manager
  ];

  programs.plasma = {
    enable = true;

    workspace = {
      lookAndFeel = "org.kde.breeze-twilight.desktop";
      cursorTheme = "Breeze";
      iconTheme = "breeze-dark";
    };

    colorScheme = "BreezeTwilight";

    panels = [
      {
        location = "left";
        height = 48;
        widgets = [
          "org.kde.plasma.kickoff"
          "org.kde.plasma.taskmanager"
          "org.kde.plasma.systemtray"
          "org.kde.plasma.digitalclock"
        ];
      }
    ];
  };

  home.stateVersion = "25.11";
}
