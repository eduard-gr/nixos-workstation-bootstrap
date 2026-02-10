{ config, pkgs, inputs, ... }:

{

  imports = [
    inputs.plasma-manager.homeManagerModules.plasma-manager
  ];

  programs.plasma = {
    enable = true;

    workspace = {
      lookAndFeel = "org.kde.breezetwilight.desktop";
      theme = "Breeze Twilight";
      colorScheme = "BreezeDark";
      iconTheme = "breeze-dark";
      cursorTheme = "Breeze";
    };



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
