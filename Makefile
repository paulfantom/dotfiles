.PHONY: all
all: bin install dotfiles vim kde etc ## Installs the bin and etc directory files and the dotfiles.

.PHONY: bin
bin: ## Installs the bin directory files.
	# add aliases for things in bin
	for file in $(shell find $(CURDIR)/bin -type f -not -name ".*.swp"); do \
		f=$$(basename $$file); \
		sudo ln -sf $$file /usr/local/bin/$$f; \
	done

.PHONY: install
install: ## Execute full installation script
	sudo ./install.sh full

.PHONY: dotfiles
dotfiles: ## Installs the dotfiles.
	# add aliases for dotfiles
	for file in $(shell find $(CURDIR) -name ".*" -not -name ".gitignore" -not -name ".travis.yml" -not -name ".git" -not -name ".*.swp" -not -name ".gnupg" -not -name ".config" -not -name ".vim"); do \
		f=$$(basename $$file); \
		ln -sfn $$file $(HOME)/$$f; \
	done;
	gpg --list-keys || true;
	ln -sfn $(CURDIR)/.gnupg/gpg.conf $(HOME)/.gnupg/gpg.conf;
	ln -sfn $(CURDIR)/.gnupg/gpg-agent.conf $(HOME)/.gnupg/gpg-agent.conf;
	ln -fn $(CURDIR)/gitignore $(HOME)/.gitignore;
	git update-index --skip-worktree $(CURDIR)/.gitconfig;
#	ln -snf $(CURDIR)/.fonts $(HOME)/.local/share/fonts;

.PHONY: vim
vim: ## Installs and configures VIM
	ln -snf $(CURDIR)/.vim $(HOME)/.vim;
	sudo ln -snf $(CURDIR)/.vim /root/.vim;
	ln -snf $(CURDIR)/.vim/vimrc $(HOME)/.vimrc;
	sudo ln -snf $(CURDIR)/.vim/vimrc /root/.vimrc;
	git submodule update --init --recursive
	git submodule foreach git pull --recurse-submodules origin master

.PHONY: kde
kde: ## Installs the KDE configuration.
	for file in $(shell find $(CURDIR)/.config -name "*"); do \
		f=$$(echo $$file | sed -e 's|$(CURDIR)\/||'); \
		ln -sfn $$file $(HOME)/$$f; \
	done

.PHONY: etc
etc: ## Installs the etc directory files.
	for file in $(shell find $(CURDIR)/etc -type f -not -name ".*.swp"); do \
		f=$$(echo $$file | sed -e 's|$(CURDIR)||'); \
		sudo ln -f $$file $$f; \
		sudo chown root:root $$f; \
		sudo restorecon -FvR $$f; \
	done
	systemctl --user daemon-reload || true
	sudo systemctl daemon-reload

.PHONY: test
test: shellcheck pylint ## Runs all the tests on the files in the repository.

# if this session isn't interactive, then we don't want to allocate a
# TTY, which would fail, but if it is interactive, we do want to attach
# so that the user can send e.g. ^C through.
INTERACTIVE := $(shell [ -t 0 ] && echo 1 || echo 0)
ifeq ($(INTERACTIVE), 1)
	DOCKER_FLAGS += -t
endif
SHELL := /bin/bash

PHONY: shellcheck
shellcheck: ## Runs shellcheck tests on the scripts.
	for file in $(shell find $(CURDIR) -type f -not -iwholename '*.git*' -not -iwholename '*/.vim/pack/default/start/*' | while read in ; do if file -i "$${in}" | grep -q x-shell ; then echo "$${in}" ; fi ; done); do \
                f=$$(echo $$file | sed -e 's|$(CURDIR)||'); \
		docker run -v "$(CURDIR):/code:Z" koalaman/shellcheck -f gcc "/code$$f" && echo -e "\033[32m[OK]\033[0m: sucessfully linted $$f" || ( echo -e "\033[31m[FAIL]\033[0m: linting $$f" && exit 1 );\
	done

PHONY: pylint
pylint: ## Runs pylint tests on the scripts.
	for file in $(shell find $(CURDIR) -type f -not -iwholename '*.git*' -not -iwholename '*/.vim/pack/default/start/*' | while read in ; do if file -i "$${in}" | grep -q x-python ; then echo "$${in}" ; fi ; done); do \
                f=$$(echo $$file | sed -e 's|$(CURDIR)||'); \
		docker run -v "$(CURDIR):/code:Z" eeacms/pylint --ignore-patterns "/code/.vim/*" "/code$$f" && echo -e "\033[32m[OK]\033[0m: sucessfully linted $$f" || ( echo -e "\033[31m[FAIL]\033[0m: linting $$f" && exit 1 );\
	done

PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

