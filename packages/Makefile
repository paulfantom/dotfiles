.PHONY: all
all: install-packages remove-bloat configure-packages

.PHONY: remove-bloat
remove-bloat:
	dnf remove $(shell cat "remove.txt")

.PHONY: install-packages
install-packages: repositories
	dnf install -y $(shell cat "install.txt")
	dnf install -y docker-ce
	dnf install -y python3 python3-{pip,virtualenv}

.PHONY: configure-packages
configure-packages: install-packages
	systemctl enable --now haveged
	-groupadd docker
	-gpasswd -a "$(USER)" docker
	systemctl enable --now docker

.PHONY: repositories
repositories: /etc/yum.repos.d/google-chrome.repo /etc/yum.repos.d/rpmfusion-nonfree-steam.repo /etc/yum.repos.d/docker.repo /etc/yum.repos.d/rpmfusion-free.repo /etc/yum.repos.d/rpmfusion-nonfree.repo

/etc/yum.repos.d/google-chrome.repo:
	dnf install -y fedora-workstation-repositories
	dnf config-manager --set-enabled google-chrome

/etc/yum.repos.d/rpmfusion-nonfree-steam.repo:
	dnf install -y fedora-workstation-repositories
	dnf config-manager --set-enabled rpmfusion-nonfree-steam

/etc/yum.repos.d/docker.repo:
	dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

/etc/yum.repos.d/rpmfusion-free.repo:
	dnf install -y "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(shell rpm -E %fedora).noarch.rpm"

/etc/yum.repos.d/rpmfusion-nonfree.repo:
	dnf install -y "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(shell rpm -E %fedora).noarch.rpm"

