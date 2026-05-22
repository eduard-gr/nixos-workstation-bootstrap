{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    (python314.withPackages (ps: with ps; [
      pandas
      scipy
      matplotlib
      numpy
      plotly
    ]))
  ];
}
