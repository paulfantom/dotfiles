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

setup_repos() {
   dnf install -y \
       "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
       "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

   cat <<-EOF > /etc/yum.repos.d/negativo-spotify.repo
	[negativo-spotify]
	baseurl = http://negativo17.org/repos/spotify/fedora-\$releasever/\$basearch
	gpgkey = http://negativo17.org/repos/RPM-GPG-KEY-slaanesh
	name = negativo17 - Spotify
	skip_if_unavailable = 1
	EOF

   cat <<-EOF > /etc/yum.repos.d/vivaldi.repo
	[vivaldi]
	baseurl = http://repo.vivaldi.com/archive/rpm/x86_64
	gpgkey = http://repo.vivaldi.com/archive/linux_signing_key.pub
	name = vivaldi
	enabled = 1
	EOF

   cat <<-EOF > /etc/yum.repos.d/docker.repo
	[docker-ce-stable]
	baseurl = https://download.docker.com/linux/fedora/\$releasever/\$basearch/stable
	gpgkey = https://download.docker.com/linux/fedora/gpg
	name = Docker CE Stable - \$basearch
	enabled = 1
	EOF
}

base_min() {
    dnf upgrade -y
    dnf install -y \
    	automake \
    	bind-utils \
        curl \
        gcc \
        git \
        gnupg \
        gnupg2 \
        hdparm \
        htop \
        lsof \
        make \
        mtr \
        nmap \
        pbzip2 \
        pigz \
        pv \
        openssh \
        tree \
        unzip \
        vim \
        wget \
        zip

    install_scripts
}

base() {
    ANS="N"
    read -t 30 -r -p "Do you want to remove KDE bloatware? [Y]es/[N]o  " -n 1 ANS || :
    if [[ "$ANS" =~ Y|y ]]; then
        dnf remove -y \
        akregator \
        amarok \
        dragonplayer \
        kcalendar \
        kget \
        kmail \
        kontact \
        korganizer \
        ktp-* \
        kwrite \
        mariadb \
        mariadb-* || echo "Bloatware already removed"
    fi

    base_min
    dnf install -y \
        bridge-utils \
        kate \
        keepassxc \
        latte-dock \
        libreoffice \
        nextcloud-client \
        nextcloud-client-dolphin \
        pavucontrol \
        powerline \
        powerline-fonts \
        powertop \
        spotify \
        tlp \
        vim-powerline \
        vivaldi-stable \
        vlc \
        xbindkeys \
        xmodmap \
        yakuake
    
    setup_sudo

    install_python
    install_docker
    install_ansible
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
    curl -sSL https://raw.githubusercontent.com/hypriot/flash/master/Linux/flash > /usr/local/bin/flash
    chmod +x /usr/local/bin/flash
}

install_docker() {
    dnf install -y docker-ce
    gpasswd -a "$TARGET_USER" docker
    systemctl enable docker
    if [ "$(command -v pip >/dev/null 2>&1)" ]; then
        pip install docker-compose
    fi
}

install_python() {
    dnf install -y \
        python{2,3} \
        python{2,3}-pip \
        python{2,3}-virtualenv

    pip install --upgrade pip
    pip3 install --upgrade pip
}

install_ansible() {
    if [[ ! -z "$1" ]]; then
        ANSIBLE="ansible==$1"
    else
	ANSIBLE="ansible"
    fi

    command -v pip >/dev/null 2>&1 || install_python

    pip install \
    	"$ANSIBLE" \
        molecule==1.25.1 \
        testinfra
}

install_vagrant() {
    dnf install -y \
        VirtualBox \
        vagrant \
        vagrant-sshfs \
        vagrant-digitalocean 
    echo "TODO: configure virtualbox and vagrant"
}

install_libvirt() {
    dnf install -y \
        libvirt-client \
        libvirt-daemon \
        libvirt-daemon-kvm \
        virt-install \
        virt-manager

    gpasswd -a "$TARGET_USER" libvirt
    systemctl enable libvirtd
}

install_golang() {
#    export GO_VERSION
#    GO_VERSION=$(curl -sSL "https://golang.org/VERSION?m=text")
#    export GO_SRC=/usr/local/go
    dnf install -y golang
}

get_dotfiles() {
    if [ "$EUID" -eq 0 ]; then
        echo "Don't run this as root"
        exit 1
    fi

    # create subshell
    (
    USERHOME="/home/${TARGET_USER}"
    cd "$USERHOME"
    mkdir -p "${USERHOME}/Development"

    # install dotfiles from repo
    git clone https://github.com/paulfantom/dotfiles.git "${USERHOME}/Development/dotfiles" || :
    #git clone git@github.com:paulfantom/dotfiles.git "${USERHOME}/Development/dotfiles"
    cd "${USERHOME}/Development/dotfiles"
    git pull

    # install all the things
    make   
    )
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
    mkdir -p "/home/$TARGET_USER/Downloads"
    { \
        echo -e "\\n# tmpfs for downloads"; \
        echo -e "tmpfs\\t/home/${TARGET_USER}/Downloads\\ttmpfs\\tnodev,nosuid,size=2G\\t0\\t0"; \
    } >> /etc/fstab
}

usage() {
    echo -e "install.sh\\n\\tThis script installs my basic setup for a fedora laptop\\n"
    echo "Usage:"
    echo "  full                                - install almost everything"
    echo "  base                                - setup sources & install base pkgs"
    echo "  dotfiles                            - get dotfiles"
    echo "  golang                              - install golang and packages"
    echo "  ansible                             - install ansible and packages"
    echo "  scripts                             - install scripts"
    echo "  libvirt                             - install libvirt"
    echo "  vagrant                             - install vagrant and virtualbox"
    echo "  downloads                           - use TMPFS for downloads directory"
}

main() {
    local cmd=$1
    
    if [[ -z "$cmd" ]]; then
        usage
        exit 1
    fi

    if [[ $cmd == "full" ]]; then
        check_is_sudo
        get_user
        setup_repos
        base
        install_scripts
        install_libvirt
        install_vagrant
        install_golang
        echo "To finish configuration run '$0 dotfiles' as a non-root user"
    elif [[ $cmd == "base" ]]; then
        check_is_sudo
        get_user
        setup_repos
        base
    elif [[ $cmd == "dotfiles" ]]; then
        get_user
        get_dotfiles
    elif [[ $cmd == "golang" ]]; then
        install_golang "$2"
    elif [[ $cmd == "ansible" ]]; then
        check_is_sudo
        install_ansible "$2"
    elif [[ $cmd == "scripts" ]]; then
        check_is_sudo
        install_scripts
    elif [[ $cmd == "libvirt" ]]; then
        check_is_sudo
        get_user
    	install_libvirt
    elif [[ $cmd == "vagrant" ]]; then
        check_is_sudo
        install_vagrant "$2"
    elif [[ $cmd == "downloads" ]]; then
        check_is_sudo
        downloads_tmpfs
    else
        usage
    fi
}

main "$@"
