#!/bin/bash
set -e
set -o pipefail

# install.sh
#    This script installs my basic setup for a fedora laptop
#    Based on similiar script from @jessfraz 
#    (https://github.com/jessfraz/dotfiles/blob/master/bin/install.sh)

check_is_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root."
        exit
    fi
}

# Choose a user account to use for this installation
get_user() {
    if [ -z "${TARGET_USER-}" ]; then
        mapfile -t options < <(find /home/* -maxdepth 0 -printf "%f\\n" -type d)
        # if there is only one option just use that user
        if [ "${#options[@]}" -eq "1" ]; then
            readonly TARGET_USER="${options[0]}"
            echo "Using user account: ${TARGET_USER}"
            return
        fi

        # iterate through the user options and print them
        PS3='Which user account should be used? '

        select opt in "${options[@]}"; do
            readonly TARGET_USER=$opt
            break
        done
    fi
}

github_download() {
    local VERSION REPO_SLUG ASSET TMP_DIR
    VERSION="$1"
    REPO_SLUG="$2"
    ASSET="$3"
    if [ "$VERSION" == "latest" ]; then
        VERSION=$(curl --silent "https://api.github.com/repos/${REPO_SLUG}/tags" | jq -r '.[0].name')
    fi
    TMP_DIR=$(mktemp -d)
    mkdir -p "${TMP_DIR}/${REPO_SLUG}"
    echo "Downloading ${REPO_SLUG}:${VERSION}"
    curl -sSL "https://github.com/${REPO_SLUG}/releases/download/${VERSION}/${ASSET}" > "${TMP_DIR}/${REPO_SLUG}/${ASSET}"

    # TODO: Figure out file type and extract if needed

    chmod +x "${TMP_DIR}/${REPO_SLUG}/${ASSET}"
    mv "${TMP_DIR}/${REPO_SLUG}/${ASSET}" "/usr/local/bin/${REPO_SLUG##*/}"
}

setup_repos() {
   dnf install -y \
       "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
       "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

   cat <<-EOF > /etc/yum.repos.d/google-chrome.repo
	[google-chrome]
	name=google-chrome
	baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
	enabled=1
	gpgcheck=1
	gpgkey=https://dl.google.com/linux/linux_signing_key.pub
	EOF

   cat <<-EOF > /etc/yum.repos.d/docker.repo
	[docker-ce-stable]
	baseurl = https://download.docker.com/linux/fedora/\$releasever/\$basearch/stable
	gpgkey = https://download.docker.com/linux/fedora/gpg
	name = Docker CE Stable - \$basearch
	enabled = 1
	EOF
}

base() {
    ANS="N"
    read -t 30 -r -p "Do you want to remove KDE bloatware? [Y]es/[N]o  " -n 1 ANS || :
    if [[ "$ANS" =~ Y|y ]]; then
    	#shellcheck disable=SC2046
        dnf remove -y $(cat "packages/remove.txt")
    fi

    #shellcheck disable=SC2046
    dnf install -y $(cat "packages/install.txt")

    systemctl enable --now haveged
    setup_sudo

    install_scripts  
    install_python
    install_docker
    install_ansible
}

install_git_lfs() {
    # install git-lfs
    GIT_LFS_VERSION=2.5.2
    curl -sSL "https://github.com/git-lfs/git-lfs/releases/download/v${GIT_LFS_VERSION}/git-lfs-linux-amd64-v${GIT_LFS_VERSION}.tar.gz" > "/tmp/git-lfs-linux-amd64-v${GIT_LFS_VERSION}.tar.gz"
    mkdir /tmp/git-lfs
    tar -xvf "/tmp/git-lfs-linux-amd64-v${GIT_LFS_VERSION}.tar.gz" -C /tmp/git-lfs
    exec /tmp/git-lfs/install.sh
}

install_scripts() {
    # install speedtest
    curl -sSL https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py  > /usr/local/bin/speedtest
    chmod +x /usr/local/bin/speedtest
    
    # install icdiff
    curl -sSL https://raw.githubusercontent.com/jeffkaufman/icdiff/master/icdiff > /usr/local/bin/icdiff
    curl -sSL https://raw.githubusercontent.com/jeffkaufman/icdiff/master/git-icdiff > /usr/local/bin/git-icdiff
    chmod +x /usr/local/bin/icdiff
    chmod +x /usr/local/bin/git-icdiff
    
    # install lolcat
    curl -sSL https://raw.githubusercontent.com/tehmaze/lolcat/master/lolcat > /usr/local/bin/lolcat
    chmod +x /usr/local/bin/lolcat

    # install flash
    curl -sSL https://raw.githubusercontent.com/hypriot/flash/master/flash > /usr/local/bin/flash
    chmod +x /usr/local/bin/flash

    # install tuptime
    curl -sSL https://raw.githubusercontent.com/rfrail3/tuptime/master/src/tuptime > /usr/bin/tuptime
    curl -sSL https://raw.githubusercontent.com/rfrail3/tuptime/master/src/systemd/tuptime.service > /etc/systemd/system/tuptime.service
    curl -sSL https://raw.githubusercontent.com/rfrail3/tuptime/master/src/systemd/tuptime.timer > /etc/systemd/system/tuptime.timer
    chmod +x /usr/bin/tuptime
    systemctl daemon-reload
    systemctl enable tuptime.timer
}

install_docker() {
    dnf install -y docker-ce || dnf install -y docker
    groupadd docker
    gpasswd -a "$TARGET_USER" docker
    systemctl enable docker
    if command -v pip >/dev/null 2>&1; then
        pip install docker-compose
    fi
}

install_python() {
    dnf install -y \
        python3 \
        python3-pip \
        python3-virtualenv

    pip3 install --upgrade pip || echo "Couldn't upgrade pip3"
}

install_monitoring_tools() {
    local VERSION
    tmp=$(mktemp -d)
    echo "Installing promtool"
    VERSION=$(curl --silent "https://api.github.com/repos/prometheus/prometheus/tags" | jq -r '.[0].name' | sed 's/v//')
    curl -sSL "https://github.com/prometheus/prometheus/releases/download/v${VERSION}/prometheus-${VERSION}.linux-amd64.tar.gz" > "${tmp}/prometheus-${VERSION}.linux-amd64.tar.gz"
    tar -xvf "${tmp}/prometheus-${VERSION}.linux-amd64.tar.gz" -C "${tmp}"
    cp "${tmp}/prometheus-${VERSION}.linux-amd64/promtool" /usr/local/bin/promtool

    echo "Installing jsonnet"
    VERSION=$(curl --silent "https://api.github.com/repos/google/jsonnet/tags" | jq -r '.[0].name')
    curl -sSL "https://github.com/google/jsonnet/archive/${VERSION}.tar.gz" > "${tmp}/jsonnet-${VERSION}.tar.gz"
    tar -xvf "${tmp}/jsonnet-${VERSION}.tar.gz" -C "${tmp}"
    here=$(pwd)
    cd "${tmp}/jsonnet-${VERSION}"
    make
    cp jsonnet /usr/local/bin/jsonnet
    cd "${here}"

}

install_clouds() {
    local VERSION
    VERSION=$(curl --silent "https://api.github.com/repos/digitalocean/doctl/tags" | jq -r '.[0].name')
    echo "Installing doctl ${VERSION}"
    curl -sSL "https://github.com/digitalocean/doctl/releases/download/${VERSION}/doctl-${VERSION}-linux-amd64.tar.gz" > "/tmp/doctl-${VERSION}-linux-amd64.tar.gz"
    tar -xvf "/tmp/doctl-${VERSION}-linux-amd64.tar.gz"
    mv doctl /usr/local/bin/doctl
    chmod +x /usr/local/bin/doctl
}

setup_sudo() {
    # add user to sudoers
    gpasswd -a "$TARGET_USER" wheel
    
    # add user to systemd groups
    # then you wont need sudo to view logs and shit
    gpasswd -a "$TARGET_USER" systemd-journal
    gpasswd -a "$TARGET_USER" systemd-network
    
    { \
        echo -e "${TARGET_USER} ALL=(ALL) NOPASSWD:ALL"; \
        echo -e "${TARGET_USER} ALL=NOPASSWD: /sbin/ifconfig, /sbin/ifup, /sbin/ifdown, /sbin/ifquery"; \
    } >> /etc/sudoers
}

downloads_tmpfs() {
    # setup downloads folder as tmpfs
    # that way things are removed on reboot
    # i like things clean but you may not want this
    if [ -z "${TARGET_USER-}" ]; then
        echo "Something went wrong when getting user name"
        exit 0
    fi
    mkdir -p "/home/$TARGET_USER/Downloads"
    { \
        echo -e "\\n# tmpfs for downloads"; \
        echo -e "tmpfs\\t/home/${TARGET_USER}/Downloads\\ttmpfs\\tnodev,nosuid,size=3G\\t0\\t0"; \
    } >> /etc/fstab
}

usage() {
    echo -e "install.sh\\n\\tThis script installs my basic setup for a fedora laptop\\n"
    echo "Usage:"
    echo "  full                                - install almost everything"
    echo "  base                                - setup sources & install base pkgs"
    echo "  ansible                             - install ansible and packages"
    echo "  scripts                             - install scripts"
    echo "  libvirt                             - install libvirt"
    echo "  downloads                           - use TMPFS for downloads directory"
}

main() {
    local cmd=$1
    
    if [[ -z "$cmd" ]]; then
        usage
        exit 1
    fi

    if [[ "$cmd" == "full" ]]; then
        check_is_sudo
        get_user
        setup_repos
        base
        install_scripts
        install_libvirt
        install_monitoring_tools
        install_git_lfs
        downloads
    elif [[ "$cmd" == "base" ]]; then
        check_is_sudo
        get_user
        setup_repos
        base
    elif [[ "$cmd" == "ansible" ]]; then
        check_is_sudo
        install_ansible "$2"
    elif [[ "$cmd" == "scripts" ]]; then
        check_is_sudo
        install_scripts
    elif [[ "$cmd" == "libvirt" ]]; then
        check_is_sudo
        get_user
    	install_libvirt
    elif [ "$cmd" == "k8s" ] || [ "$cmd" == "kubernetes" ] || [ "$cmd" == "openshift" ]; then
        check_is_sudo
    elif [[ "$cmd" == "downloads" ]]; then
        check_is_sudo
        get_user
        downloads_tmpfs
    elif [[ "$cmd" == "slack" ]]; then
        install_slack
    else
        usage
    fi
}

main "$@"
