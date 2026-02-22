{ pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    docker
  ];

  virtualisation.docker = {
    enable = true;
  };

  networking.firewall = {
    allowedTCPPorts = [
      5432
      5672
      6379
    ];
  };

}
