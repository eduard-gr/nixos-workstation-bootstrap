{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # dropbox - we don't need this in the environment. systemd unit pulls it in
    dropbox-cli
  ];

  networking.firewall = {
    allowedTCPPorts = [ 17500 ];
    allowedUDPPorts = [ 17500 ];
  };
}
