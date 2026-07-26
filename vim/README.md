# vim

## Plugins

Plugins are managed as native Vim packages under `~/.vim/pack`. On startup the
vimrc clones any missing plugin listed in its `s:plugins` bootstrap table:

- [vim-lsp](https://github.com/prabirshrestha/vim-lsp) and
  [async.vim](https://github.com/prabirshrestha/async.vim)
- [vim-go](https://github.com/fatih/vim-go)
- [vim-terraform](https://github.com/hashivim/vim-terraform)
- [rust.vim](https://github.com/rust-lang/rust.vim)

Post-install steps:

```bash
pip install python-lsp-server
```

Run `:GoInstallBinaries` to install vim-go binaries.
