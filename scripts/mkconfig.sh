#!/bin/sh
#
# Write identity values to untracked files: config.local for make and
# ~/.env.local for the shell, so no tracked file ever carries them.
# Email comes from $EMAIL, then the GECOS other-field, then a prompt.
set -eu

username="$(id -un)"
gecos="$(getent passwd "$username" | cut -d: -f5)"
name="${gecos%%,*}"

email="${EMAIL:-$(printf '%s\n' "$gecos" | cut -s -d, -f2)}"
if [ -z "$email" ]; then
	printf 'Email: ' >&2
	read -r email
fi

# First secret key matching the email; empty when there is none, in
# which case the gitconfig template omits signingKey.
key="$(gpg --list-secret-keys --with-colons "$email" 2>/dev/null |
	awk -F: '$1 == "sec" { print "0x" $5; exit }')"

{
	printf "NAME='%s'\n" "$name"
	printf "EMAIL='%s'\n" "$email"
	printf "KEY='%s'\n" "$key"
} > config.local
printf 'export EMAIL=%s\n' "$email" > "$HOME/.env.local"
