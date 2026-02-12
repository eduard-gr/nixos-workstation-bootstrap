{ config, pkgs, inputs, ... }:

{

  systemd.user.services.dropbox = {
      Unit = {
          Description = "Dropbox service";
      };
      Install = {
          WantedBy = [ "default.target" ];
      };
      Service = {
          ExecStart = "${pkgs.dropbox}/bin/dropbox";
          Restart = "on-failure";
      };
  };

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
      wallpaper = "/home/eg/Dropbox/Wallpapers/ibm-retro-mainframe.jpg";
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
                  "applications:org.kde.konsole.desktop"
                  "applications:google-chrome.desktop"
                  "applications:chromium-browser.desktop"
                  "applications:firefox.desktop"
                  "applications:dbeaver.desktop"
                  "applications:phpstorm.desktop"
                  "applications:postman.desktop"
                  "applications:org.kde.dolphin.desktop"
                ];
              };
            };
          }
          "org.kde.plasma.systemtray"
          "org.kde.plasma.digitalclock"
        ];
      }
    ];

    shortcuts = {
      kwin = {
        "Show Desktop Grid" = "Meta+G";
        "Window to Next Screen" = "Meta+Left";
        "Window to Previous Screen" = "Meta+Left";
      };
    };
  };

  xdg.configFile."dolphinrc" = {
    force = true;
    text = ''
      [General]
      ShowTerminalPanel=true
      ShowPlacesPanel=true
      ViewMode=Details
    '';
  };


  home.stateVersion = "25.11";
}
