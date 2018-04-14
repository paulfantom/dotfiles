## dotfiles

[![Travis CI](https://travis-ci.org/paulfantom/dotfiles.svg?branch=master)](https://travis-ci.org/paulfantom/dotfiles)

**To install:**

```console
$ make
```

This will create symlinks from this repo to your home folder.

**To customize:**

Save env vars, etc in a `.extra` file, that looks something like
this:

```bash
###
### Git credentials
###

GIT_AUTHOR_NAME="Your Name"
GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
git config --global user.name "$GIT_AUTHOR_NAME"
GIT_AUTHOR_EMAIL="email@you.com"
GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
git config --global user.email "$GIT_AUTHOR_EMAIL"
GH_USER="nickname"
git config --global github.user "$GH_USER"
```

### Tests

The tests use [shellcheck](https://github.com/koalaman/shellcheck). You don't
need to install anything. They run in a container.

```console
$ make test
```

### Based on

https://github.com/gpakosz/.tmux
https://github.com/mathiasbynens/dotfiles
https://github.com/sheerun/vim-polyglot
https://github.com/jessfraz/.vim/blob/master/vimrc
https://github.com/drduh/YubiKey-Guide

### TODO

- Full KDE configuration
- golang installation
- libvirt configuration
- vagrant and virtualbox configuration
