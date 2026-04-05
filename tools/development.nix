{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    cmake
    javaPackages.compiler.openjdk25
    maven
    go

    ghex
    meld
    #inputs.zed.packages.x86_64-linux.default
    zed-editor
    dbeaver-bin
    postman

    jetbrains.goland
    jetbrains.pycharm
    jetbrains.phpstorm
    jetbrains.idea
  ];

  services = {
    nginx.enable = false;
    httpd.enable = false;
  };
}
