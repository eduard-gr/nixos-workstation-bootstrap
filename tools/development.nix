{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    cmake
    javaPackages.compiler.openjdk25
    maven
    go

    python314

    php85
    php85Packages.composer
    php85Extensions.pdo
    php85Extensions.pdo_pgsql

    ghex
    meld
    zed
    dbeaver-bin
    postman

    jetbrains.phpstorm
    jetbrains.idea
  ];
}
