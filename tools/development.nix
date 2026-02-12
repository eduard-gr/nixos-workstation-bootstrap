{ pkgs, inputs, ... }:

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
    #inputs.zed.packages.x86_64-linux.default
    zed-editor
    dbeaver-bin
    postman

    jetbrains.phpstorm
    jetbrains.idea
  ];
}
