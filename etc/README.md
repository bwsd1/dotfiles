# etc

System-wide hardening for a Debian 13 workstation. This tree mirrors its
destination, so `etc/sysctl.d/99-hardening.conf` installs to
`/etc/sysctl.d/99-hardening.conf`.

These files need root, so they are **not** part of `make install`, which
only ever writes to `$HOME`.

```sh
make install-system                 # needs root, writes to /etc
make install-system sysconfdir=/tmp/x   # dry run into a throwaway tree
```

Nothing here takes effect at install time. Each file needs a separate
activation step, listed below, so you can adopt them one at a time.

## What is installed

| File | Effect | Activate |
| ---- | ------ | -------- |
| `sysctl.d/99-hardening.conf` | 42 kernel and network settings | `sudo sysctl --system` |
| `modprobe.d/99-hardening.conf` | Refuse to load unused protocol, filesystem and DMA drivers | `sudo update-initramfs -u`, reboot |
| `default/grub.d/99-hardening.cfg` | Kernel command line: allocator hardening, IOMMU, RNG | `sudo update-grub`, reboot |
| `systemd/coredump.conf.d/99-hardening.conf` | Never write core dumps to disk | `sudo systemctl daemon-reload` |
| `security/limits.d/99-hardening.conf` | Core dump hard limit of 0 | next login |
| `nftables.conf` | Default-deny inbound firewall | `sudo systemctl enable --now nftables` |

## Rollback

Delete the file and re-run its activation step. Specifically:

```sh
sudo rm /etc/sysctl.d/99-hardening.conf   && sudo sysctl --system
sudo rm /etc/modprobe.d/99-hardening.conf && sudo update-initramfs -u
sudo rm /etc/default/grub.d/99-hardening.cfg && sudo update-grub
sudo systemctl disable --now nftables && sudo nft flush ruleset
```

Only the GRUB and modprobe changes need a reboot to take effect or to
revert. If a kernel command line change prevents boot, press `e` at the
GRUB menu and remove the parameter for that boot only, then delete the
file.

## Scope

Kernel and network configuration only. Boot integrity, disk encryption,
and per-application confinement are out of scope here and are what
actually bound the result; treat this directory as one layer rather than
a posture.
