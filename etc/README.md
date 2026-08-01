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
| `default/grub.d/99-hardening.cfg` | Kernel command line: allocator hardening, IOMMU, RNG, kernel lockdown | `sudo update-grub`, reboot |
| `systemd/coredump.conf.d/99-hardening.conf` | Never write core dumps to disk | `sudo systemctl daemon-reload` |
| `security/limits.d/99-hardening.conf` | Core dump hard limit of 0 | next login |
| `nftables.conf` | Default-deny inbound firewall | `sudo systemctl enable --now nftables` |
| `pam.d/sudo` | Yubikey touch for sudo, password fallback | see below |

## Yubikey sudo

`pam.d/sudo` adds `pam_u2f` as `sufficient` above the password stack:
touch the key to authenticate, or let it fall through to the normal
password prompt. The line is prefixed with `-`, so it is skipped while
`libpam-u2f` is not installed — installing the file alone changes
nothing and cannot lock you out.

Any number of keys can be enrolled for the same user; they end up as
extra credentials on the same `u2f_mappings` line and a touch from any
one of them authenticates. Enrol both, keeping a root shell open in
another pane until verified:

```sh
sudo apt install libpam-u2f

pamu2fcfg > /tmp/u2f      # first key inserted; touch it
# swap in the second key
pamu2fcfg -n >> /tmp/u2f  # -n omits the username so the entry appends
                          # to the same line; touch the second key
sudo install -m 644 /tmp/u2f /etc/security/u2f_mappings
rm /tmp/u2f

sudo -k && sudo true      # touch either key
```

The mapping contains only key handles and public keys, no secrets, so
staging it in /tmp is safe. Enrol a key later by appending another
`pamu2fcfg -n` entry to the line.

The mapping deliberately lives in root-owned `/etc/security/u2f_mappings`
rather than the default `~/.config/Yubico/u2f_keys`: a user-writable
authfile would let any code running as the user enrol its own key and
satisfy sudo. Note the trade-off: touch-to-sudo replaces a knowledge
factor with possession and presence, so a key left in the slot lets
anyone at an unlocked session escalate by touching it.

## Rollback

Delete the file and re-run its activation step. Specifically:

```sh
sudo rm /etc/sysctl.d/99-hardening.conf   && sudo sysctl --system
sudo rm /etc/modprobe.d/99-hardening.conf && sudo update-initramfs -u
sudo rm /etc/default/grub.d/99-hardening.cfg && sudo update-grub
sudo systemctl disable --now nftables && sudo nft flush ruleset
sudo rm /etc/security/u2f_mappings    # sudo reverts to password only
```

Only the GRUB and modprobe changes need a reboot to take effect or to
revert. If a kernel command line change prevents boot, press `e` at the
GRUB menu and remove the parameter for that boot only, then delete the
file.
