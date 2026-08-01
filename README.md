# dotfiles

Personal configuration for a Debian workstation: bash, vim, tmux, git,
GnuPG, SSH, i3, alacritty, dict, and a handful of small user scripts.

## Installation

```sh
sudo apt-get install build-essential m4
make install
```

`make help` lists the individual targets (`install-bash`, `install-vim`,
and so on) if you only want part of it.

**Note**: `make install` overwrites the contents of the current user's
`$HOME`. To test changes against a throwaway `$HOME` first:

```sh
tmpdir="$(mktemp -d)"
make && make install DESTDIR="$tmpdir"
env -i HOME="$tmpdir" TERM="$TERM" "$SHELL" -l
```

## License

MIT. See [LICENSE](LICENSE).
