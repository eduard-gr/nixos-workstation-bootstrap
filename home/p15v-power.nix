# PowerDevil policy for p15v only (imported next to eg.nix in flake.nix).
#
# Freeze experiment started 2026-10-12 — see hosts/p15v/FREEZE-PLAN.md.
# Every retained hard freeze followed a resume from s2idle, so the laptop must
# not sleep for the duration of the trial. logind already refuses suspend
# (AllowSuspend=no in hosts/p15v/configuration.nix); this file keeps Plasma
# from even asking: idle -> never sleep, lid -> lock screen, display still
# turns off. Powerdevilrc used to be empty (all defaults: sleep after idle,
# sleep on lid), which is how freeze #12 was triggered unattended.
#
# Remove this import (or restore the sleep actions) when the trial is over.
{ ... }:

{
  programs.plasma.powerdevil = {
    AC = {
      autoSuspend.action = "nothing";
      whenLaptopLidClosed = "lockScreen";
      turnOffDisplay.idleTimeout = 600;
      dimDisplay.idleTimeout = 300;
    };
    battery = {
      autoSuspend.action = "nothing";
      whenLaptopLidClosed = "lockScreen";
      turnOffDisplay.idleTimeout = 300;
      dimDisplay.idleTimeout = 120;
    };
    lowBattery = {
      autoSuspend.action = "nothing";
      whenLaptopLidClosed = "lockScreen";
      turnOffDisplay.idleTimeout = 120;
      dimDisplay.idleTimeout = 60;
    };
  };
}
