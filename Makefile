-include config.in

SHELL := /bin/bash
DESTDIR ?= $(HOME)
bindir ?= $(DESTDIR)/.local/bin

INSTALL := install -C
M4 := m4

# Verbosity control: V=1 for verbose output
Q := $(if $(V),,@)
msg = echo '  $(1)	$(2)'

TARGETS := install-bin \
	install-bash \
	install-ssh \
	install-git \
	install-gnupg \
	install-tmux \
	install-psqlrc \
	install-mycnf \
	install-vim \
	install-i3

.PHONY: all default install uninstall install-system clean help configure $(TARGETS)

.DEFAULT_GOAL := default

default: git/.gitconfig

all: $(TARGETS)

install: $(TARGETS)

# Generate .gitconfig from template
configure git/.gitconfig: git/gitconfig.m4
	@./scripts/mkconfig.sh
	$(Q)$(call msg,GEN,$@)
	$(Q)$(M4) -DNAME='$(NAME)' -DEMAIL='$(EMAIL)' -DEDITOR='$(EDITOR)' -DKEY='$(KEY)' $< > git/.gitconfig

# Bash configuration files
BASH_FILES := .bashrc .bash_profile .bash_logout .bash_aliases .path .functions .env .bash_prompt .inputrc

install-bash: ## install bash files
	$(Q)for f in $(BASH_FILES); do \
		cmp -s bash/$$f $(DESTDIR)/$$f || echo "  INSTALL	bash/$$f"; \
		$(INSTALL) -m 644 bash/$$f $(DESTDIR)/$$f; \
	done

# SSH configuration
install-ssh: ssh/config ## install SSH config
	$(Q)mkdir -p -m 0700 $(DESTDIR)/.ssh
	$(Q)cmp -s $< $(DESTDIR)/.ssh/config || $(call msg,INSTALL,$<)
	$(Q)$(INSTALL) -m 600 $< $(DESTDIR)/.ssh/config

# Git configuration
install-git: git/.gitconfig git/.gitignore_global ## install git config
	$(Q)for f in $^; do \
		cmp -s $$f $(DESTDIR)/$$(basename $$f) || echo "  INSTALL	$$f"; \
		$(INSTALL) -m 644 $$f $(DESTDIR)/$$(basename $$f); \
	done

# User scripts
BIN_FILES := $(wildcard bin/*)

install-bin: $(BIN_FILES) ## install user scripts
	$(Q)mkdir -p $(bindir)
	$(Q)for f in $^; do \
		cmp -s $$f $(bindir)/$$(basename $$f) || echo "  INSTALL	$$f"; \
		$(INSTALL) -m 755 $$f $(bindir); \
	done

# Vim runtime files
VIM_FILES := $(shell find vim -type f -name '*.vim') vim/vimrc

install-vim: $(VIM_FILES) ## install vim runtime
	$(Q)for f in $(VIM_FILES); do \
		dest=".vim/$${f#vim/}"; \
		mkdir -p $(DESTDIR)/$$(dirname $$dest); \
		cmp -s $$f $(DESTDIR)/$$dest || echo "  INSTALL	$$f"; \
		$(INSTALL) -m 644 $$f $(DESTDIR)/$$dest; \
	done

# GnuPG configuration
GNUPGHOME ?= .gnupg
GPG_FILES := gnupg/gpg.conf gnupg/gpg-agent.conf

install-gnupg: $(GPG_FILES) ## install gnupg config
	$(Q)mkdir -p -m 0700 $(DESTDIR)/$(GNUPGHOME)
	$(Q)for f in $^; do \
		cmp -s $$f $(DESTDIR)/$(GNUPGHOME)/$$(basename $$f) || echo "  INSTALL	$$f"; \
		$(INSTALL) -m 600 $$f $(DESTDIR)/$(GNUPGHOME)/$$(basename $$f); \
	done

# Tmux configuration
install-tmux: tmux/.tmux.conf ## install tmux.conf
	$(Q)cmp -s $< $(DESTDIR)/.tmux.conf || $(call msg,INSTALL,$<)
	$(Q)$(INSTALL) -m 644 $< $(DESTDIR)/.tmux.conf

# PostgreSQL configuration
install-psqlrc: psql/.psqlrc ## install psqlrc
	$(Q)cmp -s $< $(DESTDIR)/.psqlrc || $(call msg,INSTALL,$<)
	$(Q)$(INSTALL) -m 644 $< $(DESTDIR)/.psqlrc

# MySQL configuration
install-mycnf: mysql/.my.cnf ## install mysql config
	$(Q)cmp -s $< $(DESTDIR)/.my.cnf || $(call msg,INSTALL,$<)
	$(Q)$(INSTALL) -m 644 $< $(DESTDIR)/.my.cnf

# i3 window manager configuration
install-i3: i3/config ## install i3 config
	$(Q)mkdir -p $(DESTDIR)/.config/i3
	$(Q)cmp -s $< $(DESTDIR)/.config/i3/config || $(call msg,INSTALL,$<)
	$(Q)$(INSTALL) -m 644 $< $(DESTDIR)/.config/i3/config

# System-wide hardening. The etc/ tree mirrors its destination, so
# etc/sysctl.d/99-hardening.conf installs to /etc/sysctl.d/99-hardening.conf.
#
# These files belong to /etc rather than $HOME, so sysconfdir is rooted at
# / and not at $(DESTDIR). install-system is deliberately kept out of
# $(TARGETS): `make install` must never need root or touch anything
# outside the user's home directory.
#
# Test into a throwaway tree with:  make install-system sysconfdir=/tmp/x
sysconfdir ?= /etc

ETC_FILES := \
	sysctl.d/99-hardening.conf \
	modprobe.d/99-hardening.conf \
	default/grub.d/99-hardening.cfg \
	systemd/coredump.conf.d/99-hardening.conf \
	security/limits.d/99-hardening.conf \
	nftables.conf

# Installing a file under /etc does not activate it, and the grub.d
# fragment and module blacklist need a reboot rather than a reload. The
# changed files are collected and handed to activation-hint.sh, which
# prints only the steps those files require. It never runs them, and
# never reboots.
#
# nftables.conf is installed 0755 to match what Debian ships, so it stays
# directly runnable via its nft shebang; everything else is 0644.
#
# When a GRUB password is configured (password_pbkdf2 in grub.d), setting
# superusers makes every menu entry demand credentials at boot. Appending
# --unrestricted to the CLASS variable in grub.d/10_linux keeps normal
# boots passwordless while still requiring the password for the edit (e)
# and console (c) commands. 10_linux is a dpkg conffile, so a grub-common
# upgrade can drop the edit; re-running install-system restores it.
install-system: ## install /etc hardening config (needs root)
	$(Q)changed=''; \
	for f in $(ETC_FILES); do \
		mkdir -p "$(sysconfdir)/$$(dirname $$f)"; \
		if ! cmp -s etc/$$f "$(sysconfdir)/$$f"; then \
			echo "  INSTALL	etc/$$f"; \
			changed="$$changed $$f"; \
		fi; \
		case $$f in \
		nftables.conf) m=755 ;; \
		*) m=644 ;; \
		esac; \
		$(INSTALL) -m $$m etc/$$f "$(sysconfdir)/$$f"; \
	done; \
	g="$(sysconfdir)/grub.d/10_linux"; \
	if [ -f "$$g" ] \
		&& grep -qs '^[[:space:]]*password_pbkdf2[[:space:]]' "$(sysconfdir)"/grub.d/* \
		&& ! grep -q -- '--unrestricted' "$$g"; then \
		echo "  EDIT	$$g (CLASS += --unrestricted)"; \
		sed -i 's/^CLASS="\(.*\)"/CLASS="\1 --unrestricted"/' "$$g"; \
		changed="$$changed grub.d/10_linux"; \
	fi; \
	./scripts/activation-hint.sh $$changed

# Cleanup
clean: ## clean generated files
	$(Q)rm -f git/.gitconfig

# Uninstall
uninstall: ## uninstall targets
	$(Q)for f in $(notdir $(BIN_FILES)); do \
		rm -f "$(bindir)/$$f"; \
	done

# Help
help: ## print this help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' Makefile | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}' | \
		sort
	@echo ''
	@echo 'Run "make install" to install all targets'
