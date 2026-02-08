## NixOS
Ok, Let's see how it works.

### Make file system

#### Partitions
- 1G EFI 
- 64G swap Dedicated Swap Partition
- linux filesystem

#### Partitions
```bash
mkswap -L swap /dev/sda2
swapon /dev/nvme0n1p2
```
