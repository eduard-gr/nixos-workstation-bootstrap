{ config, pkgs, inputs, ... }:

{

  imports = [
    inputs.plasma-manager.homeManagerModules.plasma-manager
  ];

  /**
   *
   * https://github.com/nix-community/plasma-manager
   */
  programs.plasma = {
    enable = true;

    workspace = {
      lookAndFeel = "org.kde.breezetwilight.desktop";
      theme = "Breeze Twilight";
      colorScheme = "BreezeClassic";
      iconTheme = "breeze-dark";
      cursorTheme = "Breeze";
    };

    panels = [
      {
        location = "left";
        height = 48;
        widgets = [
          "org.kde.plasma.kickoff"
          #"org.kde.plasma.taskmanager"
          {
            name = "org.kde.plasma.icontasks";
            config = {
              General = {
                launchers = [
                  "applications:firefox_firefox.desktop"
                  "applications:chrome_chrome.desktop"
                  "applications:dbeaver-ce.desktop"
                  "applications:org.kde.konsole.desktop"
                  "applications:org.kde.dolphin.desktop"
                  #"applications:chromium_chromium.desktop"

                ];
              };
            };
          }
          "org.kde.plasma.systemtray"
          "org.kde.plasma.digitalclock"
        ];
      }
    ];
  };

  home.stateVersion = "25.11";
}
