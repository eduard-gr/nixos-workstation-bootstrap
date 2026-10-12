# p15v hard-freeze investigation — action plan

Status as of 2026-10-12. Twelve hard freezes since 2026-07-20, the last one
2026-10-10 ≈03:15:50 (Sat night, nobody at the machine, lock screen up).

## What the logs prove

- Every freeze is a **platform-level hang below the kernel**: EFI pstore is
  always empty, the perf NMI hard-lockup detector (`hardlockup_panic=1`) never
  fires, there is no triple fault, and the SP5100 TCO watchdog *counts down*
  (`/sys/class/watchdog/watchdog0/bootstatus` = 32 after #11 and #12) but its
  reset never takes effect — the FCH reset-reason register shows only the
  manual power cycle (`0x00200800`), never bit 25 "watchdog".
- **Trigger = resume from s2idle.** Over the 20 retained boots (monotonic
  clock, so the pm_trace clock freeze does not distort it):

  | state of the boot                    | awake time | freezes |
  |--------------------------------------|-----------:|--------:|
  | before the first s2idle of the boot  |      9.6 h |       0 |
  | after at least one resume            |     12.5 h |       8 |

  Time from the last resume to the freeze: 13 min, 18 min, 20 min, 34 min,
  61 min, 1 h 47 min, 2 h 12 min, plus #10 which hung at the *second* suspend
  entry. Longest clean post-resume uptime: 1 h 43 min. Chance of 8/8 landing
  in the post-resume share by luck ≈ 1 %.
- Not the cause (already ruled out): NVIDIA RTD3 (pinned off, #9/#11/#12
  happened with runtime D3 disabled), idle-only trigger (#9 and #11 during
  active work), the fingerprint-reader USB resets (background noise), D-state
  hangs (`hung_task_panic=1` never fired).
- Things that are power-cycled or re-initialised on every resume and are
  therefore the suspects: NVIDIA A2000 (`NVreg_EnableS0ixPowerManagement=1`,
  VRAM self-refresh), ath11k QCNFA765 Wi-Fi (MHI power-on at every resume,
  regulatory domain flapping DE/LV/LT ~136×/boot, DMA unprotected because of
  `iommu=soft`), AMD SMU/PMFW (`amd_pstate=active`), EC (`[Firmware Bug]:
  Unexpected lid state reported by firmware` at every resume).

## Plan

1. **Confirm the trigger — run without suspend (ACTIVE since 2026-10-12).**
   `suspendDisabled = true` in `hosts/p15v/configuration.nix` sets
   `AllowSuspend=no` (logind refuses, PowerDevil hides sleep), masks the
   suspend targets and makes the lid lock the screen; `home/p15v-power.nix`
   sets the same PowerDevil policy (idle → nothing, lid → lock).
   Verify after the switch:
   ```
   systemctl show -p AllowSuspend  # not exposed; use the next two instead
   busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanSuspend   # s "no" (a method, not a property)
   systemctl is-enabled suspend.target                                                                            # masked
   journalctl -b -k | grep -c 'PM: suspend entry'                                                                 # must stay 0
   ```
   Success criterion: ≥ 2 weeks / ≥ 40 h of uptime with no unclean boot.
   Hazard after a resume was ≈ 0.6 freezes per awake hour, so a clean
   40 h would be far outside what the old behaviour allows.
   If it still freezes with 0 suspend cycles, the s2idle theory is dead and
   the next lever is item 4.

2. **Bisect the resume path (only if item 1 confirms it).** Re-enable suspend
   and change ONE thing per week:
   1. `nvidia.NVreg_EnableS0ixPowerManagement=0` (dGPU keeps the classic
      suspend path).
   2. Unbind ath11k around sleep (`powerManagement.powerDownCommands`:
      `echo 0000:02:00.0 > /sys/bus/pci/drivers/ath11k_pci/unbind`, rebind in
      `resumeCommands`), or blacklist Wi-Fi for a week and use Ethernet.
   3. Drop `iommu=soft` (gives the hardware IOMMU back, so a rogue DMA faults
      instead of corrupting memory) — note this interacts with the NVMe
      resume quirk on Lenovo AMD laptops; watch resume times.
   4. `amd_pmc` diagnostics per the kernel doc "Debugging AMD Zen systems"
      (`arch/x86/amd-debugging`): `echo 1 > /sys/power/pm_debug_messages`,
      `amd_s2idle.py`, `/sys/kernel/debug/amd_pmc/s0ix_stats` (root). If the
      platform never reaches S0i3 because of `pcie_aspm=off` /
      `nvme_core.default_ps_max_latency_us=0`, it sleeps in a half-way state
      for hours; try removing those two one at a time.

3. **Find out whether the TCO watchdog can reset this board at all** (one
   deliberate reboot, do it when convenient):
   ```
   sudo busctl set-property org.freedesktop.systemd1 /org/freedesktop/systemd1 \
     org.freedesktop.systemd1.Manager RuntimeWatchdogUSec t 0
   sudo sh -c 'exec 3>/dev/watchdog0; sleep 600' &   # arms it; then
   sudo kill -9 <that sh pid>                         # no magic close -> keeps running
   ```
   Reset within 60 s ⇒ the TCO works and the freezes kill the FCH too
   (power/firmware level, go to item 4). No reset ⇒ the TCO is masked by the
   firmware on this board; drop `RuntimeWatchdogSec` (it only adds noise) and
   stop reading `bootstatus`.
   Restore afterwards: `RuntimeWatchdogUSec t 30000000` or just reboot.

4. **Firmware / hardware.** BIOS N3KET53W 1.31 (2026-05-26) is installed;
   check the Lenovo support page for P15v Gen 3 AMD for anything newer and
   read its changelog for S0ix/"system hang" fixes. In BIOS setup: check that
   "Sleep State" is Windows/Linux S0ix (the only mode offered, so just
   confirm), disable "Always On USB" and Wake-on-LAN if present (the 01:03
   spontaneous wake before #12 has no logged source). Run memtest86+ for one
   night (not yet done).

5. **Alternative to suspend during the trial:** hibernate is *not* ready —
   `/sys/power/resume` is `0:0` and the kernel command line has no `resume=`;
   the 59.6 GiB swap partition is also unencrypted. Wire `boot.resumeDevice`
   (and ideally move swap under LUKS) before relying on it.

## How to judge the next incident

- Running generation: `ls -l /nix/var/nix/profiles/system`,
  `sysctl kernel.hardlockup_panic`, `cat /sys/power/pm_trace`.
- Suspend cycles in that boot: `journalctl -b -1 -k | grep 'PM: suspend'`.
- Real timeline (pm_trace freezes the wall clock across sleep until NTP):
  `journalctl -b -1 -o short-monotonic`, NTP line `Initial clock
  synchronization`.
- Was anyone there: Chrome `~/.config/google-chrome/Default/History` (sqlite,
  copy first) and `~/.cache/JetBrains` mtimes; unlocks in the journal.
- Capture state: `Platform Persistent Storage Archival skipped` = pstore empty;
  `x86/amd: Previous system reset reason` line; `watchdog0/bootstatus`.
