{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vllm

    (python314.withPackages (ps: with ps; [
      llama-cpp-python
    ]))
  ];
}
