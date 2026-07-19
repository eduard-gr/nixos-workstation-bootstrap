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
mkfs.btrfs -L nixos /dev/nvme0n1p3
mount /dev/nvme0n1p3 /mnt

btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/nix
btrfs subvolume create /mnt/log
umount /mnt

export FLAGS="noatime,compress=zstd,ssd,space_cache=v2"

mount -o subvol=root,$FLAGS /dev/nvme0n1p3 /mnt
mkdir -p /mnt/{boot,home,nix,var/log}

mount /dev/nvme0n1p1 /mnt/boot
mount -o subvol=home,$FLAGS /dev/nvme0n1p3 /mnt/home
mount -o subvol=nix,$FLAGS /dev/nvme0n1p3 /mnt/nix
mount -o subvol=log,$FLAGS /dev/nvme0n1p3 /mnt/var/log
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
nixos-install --flake .#my-host-name --root /mnt
```
#### p15v
PRIME for Radeon + Nvidea
nix shell nixpkgs#pciutils -c bash ./detect-gpu-bus-ids.sh
# saves hosts/p15v/gpu-bus-ids.nix
