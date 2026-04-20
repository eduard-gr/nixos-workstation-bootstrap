{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    docker
  ];

  virtualisation.docker = {
    enable = true;
  };

  networking.firewall = {
    trustedInterfaces = [ "docker0" ];
    allowedTCPPorts = [
      5432
      5672
      6379
      9005
      8123
      9000
      7070
    ];
  };

}
