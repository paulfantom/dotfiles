SHELL := /bin/bash

DOTFILES=$(shell find "$(CURDIR)/dots" -name "*" -type f)
APPCONFIG=$(shell find $(CURDIR)/appconfig -name "*" -type f)
BINSCRIPTS=$(shell find $(CURDIR)/bin -type f)
ETCFILES=$(shell find $(CURDIR)/etc -type f)

.PHONY: all
all: bin install dotfiles gpg appconfig vim etc ## Installs the bin and etc directory files and the dotfiles.

.PHONY: install
install: ## Execute full installation script
	sudo ./install.sh full

.PHONY: gpg
gpg:
	gpg --list-keys || true;
	ln -sfn $(CURDIR)/gnupg/gpg.conf $(HOME)/.gnupg/gpg.conf;
	ln -sfn $(CURDIR)/gnupg/gpg-agent.conf $(HOME)/.gnupg/gpg-agent.conf;
	git update-index --skip-worktree $(CURDIR)/.gitconfig;

.PHONY: vim
vim: ## Installs and configures VIM
	ln -snf $(CURDIR)/vim $(HOME)/.vim;
	ln -snf $(CURDIR)/vim/vimrc $(HOME)/.vimrc;
	sudo ln -snf $(CURDIR)/vim /root/.vim;
	sudo ln -snf $(CURDIR)/vim/vimrc /root/.vimrc;
	git submodule update --init --recursive
	git submodule foreach git pull --recurse-submodules origin master

.PHONY: bin
bin: $(BINSCRIPTS)  ## Installs the bin directory files.
$(BINSCRIPTS):
	sudo ln -sf $@ /usr/local/bin/$(shell basename $@)

.PHONY: dotfiles
dotfiles: $(DOTFILES)  ## Installs the dotfiles.
$(DOTFILES):
	ln -sfn $@ $(HOME)/.$(shell basename $@)

.PHONY: appconfig
appconfig: $(APPCONFIG)  ## Install application configuration files
$(APPCONFIG):
	ln -sfn "$@" "$(HOME)/$(shell echo $@ | sed -e 's|$(CURDIR)\/app|.|')"

.PHONY: etc
etc: $(ETCFILES) ## Installs the etc directory files.
$(ETCFILES):
	sudo ln -f "$@" "$(shell echo $@ | sed -e 's|$(CURDIR)||')"
	sudo chown root:root "$(shell echo $@ | sed -e 's|$(CURDIR)||')"
	sudo restorecon -FvR "$(shell echo $@ | sed -e 's|$(CURDIR)||')"
	systemctl --user daemon-reload || true
	sudo systemctl daemon-reload

.PHONY: test
test: shellcheck ## Runs all the tests on the files in the repository.

.PHONY: shellcheck
shellcheck: $(shell find $(CURDIR) -type f -not -iwholename '*.git*' -not -iwholename '*/.vim/pack/default/start/*' | while read in ; do if file -i "$${in}" | grep -q x-shell ; then echo "$${in}" ; fi ; done)  ## Runs shellcheck tests on the scripts.
	shellcheck --format=gcc $^

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

