{ config, pkgs, ... }:

{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.eg = {
    imports = [
      inputs.plasma-manager.homeManagerModules.plasma-manager
    ];

    programs.plasma = {
      enable = true;

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
  };
}
