{ pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    libreoffice-qt-fresh
  };
}
