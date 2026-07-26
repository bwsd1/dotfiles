#!/bin/sh
#
# Usage: activation-hint.sh [path...]
#
# Print the activation steps required by the files that make
# install-system actually changed, given their paths relative to
# $sysconfdir.
#
# Copying a file into /etc never makes it take effect: each subsystem has
# its own reload, and the kernel command line and module blacklist are
# only read at boot. Nothing here runs those steps and nothing reboots.
# When to restart is the operator's call, not the build system's.
set -eu

if [ $# -eq 0 ]; then
	echo "  nothing changed, no action needed"
	exit 0
fi

sysctl=''
initramfs=''
grub=''
daemon=''
login=''
nft=''
u2f=''
reboot=''

for f; do
	case $f in
	sysctl.d/*)          sysctl=1 ;;
	modprobe.d/*)        initramfs=1; reboot=1 ;;
	default/grub.d/*)    grub=1; reboot=1 ;;
	grub.d/*)            grub=1 ;;
	systemd/coredump*)   daemon=1 ;;
	security/limits.d/*) login=1 ;;
	pam.d/sudo)          u2f=1 ;;
	nftables.conf)       nft=1 ;;
	esac
done

# Guard with a function rather than "[ -n "$x" ] && echo", which returns
# non-zero on the empty case and would trip set -e.
step() {
	[ -n "$1" ] || return 0
	echo "  $2"
}

echo
echo "Installed. Nothing is active yet; run what applies:"
step "$sysctl"    "sudo sysctl --system"
step "$daemon"    "sudo systemctl daemon-reload"
step "$nft"       "sudo systemctl enable --now nftables"
step "$initramfs" "sudo update-initramfs -u"
step "$grub"      "sudo update-grub"
step "$login"     "log out and back in (pam_limits reads limits.d at login)"

# Password sudo keeps working before, during, and after these steps; the
# pam_u2f line is inert until the module and mapping both exist.
if [ -n "$u2f" ]; then
	echo
	echo "Yubikey sudo (enrol with a root shell open in another pane):"
	echo "  sudo apt install libpam-u2f"
	echo "  pamu2fcfg > /tmp/u2f      # first key inserted; touch it"
	echo "  pamu2fcfg -n >> /tmp/u2f  # second key swapped in; touch it"
	echo "  sudo install -m 644 /tmp/u2f /etc/security/u2f_mappings && rm /tmp/u2f"
	echo "  sudo -k && sudo true      # touch either key to verify"
fi

if [ -n "$reboot" ]; then
	if [ -n "$grub" ] && [ -n "$initramfs" ]; then
		what="the kernel command line and module blacklist take"
	elif [ -n "$grub" ]; then
		what="the kernel command line takes"
	else
		what="the module blacklist takes"
	fi
	echo
	echo "Then reboot:"
	echo "  $what effect only at boot."
	echo
	echo "Verify afterwards:"
	step "$grub"      "cat /proc/cmdline"
	step "$initramfs" "lsmod | grep -cE '^(dccp|sctp|firewire_core) ' # expect 0"
fi
