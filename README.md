## NixOS
Ok, Let's see how it works.

### Don't forget to turn on the wifi
```bash
nmtui
```

### Make file system

#### Partitions
- 1G EFI 
- 64G swap Dedicated Swap Partition
- linux filesystem

#### File system

##### Boot
```bash
mkfs.fat -F 32 -n boot /dev/nvme0n1p1
```

##### Swap
```bash
mkswap -L swap /dev/sda2
swapon /dev/nvme0n1p2
```

##### Main FS
```bash

cryptsetup luksFormat /dev/nvme0n1p3
cryptsetup open /dev/nvme0n1p3 cryptroot

mkfs.btrfs -L nixos /dev/mapper/cryptroot

mount /dev/mapper/cryptroot /mnt

btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/nix
btrfs subvolume create /mnt/log
umount /mnt

export FLAGS="noatime,compress=zstd:3,ssd"

mount -o subvol=root,$FLAGS /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{boot,home,nix,var/log}

mount /dev/nvme0n1p1 /mnt/boot

mount -o subvol=home,$FLAGS /dev/mapper/cryptroot /mnt/home
mount -o subvol=nix,$FLAGS /dev/mapper/cryptroot /mnt/nix
mount -o subvol=log,$FLAGS /dev/mapper/cryptroot /mnt/var/log
```

### Setup NixOS

#### Clon repo
```bash
mkdir -p /mnt/etc
git clone... /mnt/etc/nixos
```

#### Config
```bash
nixos-generate-config --root /mnt

git add -f gpu-bus-ids.nix
git add -f hardware-configuration.nix

nixos-install --flake .#my-host-name --root /mnt
```



If you have a user account declared in your configuration.nix and plan to log in using this user, set a password before rebooting, e.g. for the alice user:
```bash
nixos-enter --root /mnt -c 'passwd alice'
```

#### p15v
PRIME for Radeon + Nvidea
nix shell nixpkgs#pciutils -c bash ./detect-gpu-bus-ids.sh
# saves hosts/p15v/gpu-bus-ids.nix


### Maintanence NixOS
#### Update
```bash
nix flake update
nixos-rebuild switch --flake .#my-host-name
```
