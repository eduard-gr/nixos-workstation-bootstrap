{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    cmake
    javaPackages.compiler.openjdk25
    maven
    go
    python314

    php83
    php83Packages.composer
    php83Extensions.pdo
    php83Extensions.pdo_pgsql
    php83Extensions.mbstring
    php83Extensions.opcache
    php83Extensions.pgsql
    php83Extensions.intl
    php83Extensions.zip
    php83Extensions.curl
    php83Extensions.xsl
    php83Extensions.xsl

    ghex
    meld
    #inputs.zed.packages.x86_64-linux.default
    zed-editor
    dbeaver-bin
    postman

    jetbrains.phpstorm
    jetbrains.idea
  ];

services = {
  nginx.enable = false;
  httpd.enable = false;
};


}
