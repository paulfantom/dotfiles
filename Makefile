SHELL := /bin/bash

DOTFILES=$(shell find "$(CURDIR)/dots" -name "*" -type f -printf "$(HOME)/.%P\n")
BINSCRIPTS=$(shell find $(CURDIR)/bin -type f -printf "/usr/local/bin/%P\n")
APPCONFIG=$(shell find $(CURDIR)/appconfig -name "*" -type f | sed -e 's|$(CURDIR)\/app|$(HOME)/.|')
ETCFILES=$(shell find $(CURDIR)/etc -type f | sed -e 's|$(CURDIR)||')

.PHONY: all
all: bin install dotfiles gpg appconfig vim etc tools ## Installs the bin and etc directory files and the dotfiles.

.PHONY: install
install:  ## Install system packages and configure repositories
	sudo $(MAKE) -C packages all
	# flatpak install $(shell cat packages/flatpaks.txt)

.PHONY: tools
tools:  ## Install all external developer tools
	$(MAKE) -f Makefile.tools all

.PHONY: push
push:
	git add -A
	git commit -m '[update] synchronize with upstream $(shell date)'
	git push

.PHONY: gpg
gpg:
	gpg --list-keys || true;
	ln -sfn $(CURDIR)/gnupg/gpg.conf $(HOME)/.gnupg/gpg.conf;
	ln -sfn $(CURDIR)/gnupg/gpg-agent.conf $(HOME)/.gnupg/gpg-agent.conf;
	git update-index --skip-worktree $(CURDIR)/.gitconfig;

.PHONY: vim
vim: ## Install and configure VIM
	ln -snf $(CURDIR)/vim $(HOME)/.vim;
	ln -snf $(CURDIR)/vim/vimrc $(HOME)/.vimrc;
	sudo ln -snf $(CURDIR)/vim /root/.vim;
	sudo ln -snf $(CURDIR)/vim/vimrc /root/.vimrc;
	git submodule update --init --recursive
	git submodule foreach git pull --recurse-submodules origin master

.PHONY: account
account:  ## Configure user account groups and sudo access
	-gpasswd -a "$(USER)" wheel 
	# add user to systemd groups
	# then you wont need sudo to view logs and stuff
	-gpasswd -a "$(USER)" systemd-journal
	-gpasswd -a "$(USER)" systemd-network
	sudo sh -c 'echo -e "$(USER) ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers'

.PHONY: bin
bin: $(BINSCRIPTS)  ## Install bin directory files.
$(BINSCRIPTS):
	sudo ln -sf $(CURDIR)/bin/$(shell basename $@) $@

.PHONY: dotfiles
dotfiles: $(DOTFILES)  ## Install dotfiles.
$(DOTFILES):
	ln -sfn $(CURDIR)/dots/$(shell basename $@ | cut -c2-) $@

.PHONY: appconfig
appconfig: $(APPCONFIG)  ## Install application configuration files
$(APPCONFIG):
	ln -sfn $(shell echo $@ | sed -e "s|$(HOME)/.|$(CURDIR)/app|")

.PHONY: etc
etc: $(ETCFILES) /etc/systemd/system/home-$(USER)-Downloads.mount  ## Install etc directory files.
$(ETCFILES):
	sudo ln -f "$(CURDIR)$@" "$@"
	sudo chown root:root "$@"
	sudo restorecon -FvR "$@"
	-systemctl --user daemon-reload
	sudo systemctl daemon-reload

/etc/systemd/system/home-$(USER)-Downloads.mount:
	sudo sh -c "sed 's/USER/$(USER)/' templates/home-USER-Downloads.mount > /etc/systemd/system/home-$(USER)-Downloads.mount"
	sudo systemctl daemon-reload
	sudo systemctl start home-$(USER)-Downloads.mount
	
.PHONY: fonts
fonts: /usr/share/fonts/comicmono
	fc-cache -v

/usr/share/fonts/comicmono:
	sudo mkdir -p /usr/share/fonts/comicmono
	sudo wget https://dtinth.github.io/comic-mono-font/ComicMono.ttf -O /usr/share/fonts/comicmono/ComicMono.ttf
	sudo wget https://dtinth.github.io/comic-mono-font/ComicMono-Bold.ttf -O /usr/share/fonts/comicmono/ComicMono-Bold.ttf

.PHONY: test
test: shellcheck ## Run all the tests on the files in the repository.

.PHONY: shellcheck
shellcheck: $(shell find $(CURDIR) -type f -not -iwholename '*.git*' -not -iwholename '*/.vim/pack/default/start/*' | while read in ; do if file -i "$${in}" | grep -q x-shell ; then echo "$${in}" ; fi ; done)  ## Runs shellcheck tests on the scripts.
	shellcheck --format=gcc $^

.PHONY: help
help:  ## Print this message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

