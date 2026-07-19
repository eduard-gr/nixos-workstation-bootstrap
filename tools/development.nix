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

    claude-code
    cursor-cli
    code-cursor
    antigravity

    jetbrains.goland
    jetbrains.pycharm
    jetbrains.phpstorm
    jetbrains.idea

    grpc-tools
    protobuf
    protoc-gen-grpc-java
  ];

  services = {
    nginx.enable = false;
    httpd.enable = false;
  };
}
