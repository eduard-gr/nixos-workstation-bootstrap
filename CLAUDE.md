# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal NixOS flake configuring two Lenovo ThinkPad hosts (`l14` and `p15v`). It lives at `/etc/nixos` on the target machine. There is no application code, no tests, and no build step other than `nixos-rebuild`/`nixos-install`.

## Commands

```bash
# Rebuild the running system after editing config (run on the target host)
nixos-rebuild switch --flake .#l14      # or .#p15v

# Update all flake inputs, then rebuild
nix flake update
nixos-rebuild switch --flake .#<host>

# Fresh install (from the NixOS installer, after partitioning — see README.md)
nixos-install --flake .#<host> --root /mnt

# Regenerate PCI bus IDs for the p15v dual-GPU PRIME setup (run on p15v)
nix shell nixpkgs#pciutils -c bash ./detect-gpu-bus-ids.sh
```

There is no linter. To sanity-check a change without switching, use `nixos-rebuild build --flake .#<host>` or `nix flake check`.

## Architecture

`flake.nix` defines two `nixosConfigurations` (`l14`, `p15v`). Both wire in `home-manager` as a NixOS module (users.eg → `home/eg.nix`) and pass `inputs` plus a locally-defined `qidi-studio` AppImage package through `extraSpecialArgs`. Adding a third host means adding another entry here that imports its own `hosts/<name>/configuration.nix`.

Configuration is composed by import, split into four layers:

- **`hosts/<name>/configuration.nix`** — the only per-host file and the entry point for that host. Holds hostname, hardware/kernel/GPU specifics, power management, the user account, and the `imports` list selecting which shared modules to activate. `l14` (AMD iGPU only) and `p15v` (AMD 680M iGPU + NVIDIA RTX A2000 PRIME offload) differ mainly in GPU and kernel-param setup.
- **`general/`** — cross-cutting system concerns (`i18n`, `network` with NetworkManager + L2TP VPN, `pipewire` audio).
- **`workspace/kde.nix`** — the KDE Plasma 6 + Wayland desktop, fonts, xdg portals.
- **`tools/*.nix`** — one file per capability area (`docker`, `python`, `php83`, `3d`, `kvm`, `multimedia`, `agentic` = claude-code, etc.). Each is a self-contained module. Enable a capability on a host by adding its import to that host's `imports` list; several are commented out per-host (e.g. `android`, `ai`).

`home/eg.nix` is home-manager user config: heavy per-app setup for the Zed editor, KDE Plasma via `plasma-manager`, atuin, and a user-level Dropbox systemd service.

## Key conventions

- **`hardware-configuration.nix` and `gpu-bus-ids.nix` are gitignored** (see `.gitignore`) because they are machine-generated and machine-specific. During install they must be force-added (`git add -f`) so the flake can see them, or generated on the target. `p15v` has an `assertion` that fails the build if `gpu-bus-ids.nix` still holds empty PCI IDs — regenerate it with `detect-gpu-bus-ids.sh` on that laptop. Note the committed root-owned `gpu-bus-ids.nix` currently holds placeholder/duplicate IDs.
- Both hosts pin nixpkgs to a release channel (`nixos-26.05`), enable flakes + `allowUnfree`, cap boot generations at 10, and garbage-collect weekly.
- Shared modules take only `{ pkgs, ... }` (plus `lib`/`config` as needed) and add to `environment.systemPackages` or enable services — keep new capabilities as new `tools/*.nix` modules rather than expanding host files.
- The user is `eg`; `system.stateVersion` is `26.05` and must not be bumped just because the channel moved.
