#!/bin/bash
# OpenVPN Access Server Installation Script
# The script will automatically install OpenVPN Access Server based on your Linux distribution.
#
# Copyright 2024 OpenVPN Inc. All Rights Reserved.
#

set -eu

ARCH=""
PLIST="openvpn-as"
DCO_NAME="openvpn-dco-dkms"
IF_HELD=false
YES_MODE=false
WITHOUT_DCO=false

abort() {
    echo "This $PRETTY_NAME $ARCH distribution is not officially supported. Aborted." >&2
    exit 1
}

repo_error() {
    echo
    echo "Unfortunately the package management program on your operating system is reporting a problem." >&2
    echo "Please refer to our online documentation or contact our support team for assistance." >&2
    echo
    echo "The installation therefore had to be stopped." >&2
    exit 4
}

initialization() {
    if [ -f "/etc/os-release" ]; then
        . /etc/os-release
    else
        echo "Can not detect OS/distribution. Aborted." >&2
        exit 1
    fi

    case $(uname -m) in
        x86_64)  ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        *)       abort ;;
    esac

    if [[ "$ARCH" == "arm64" && "$ID" != "ubuntu" ]]; then
        abort
    fi
    echo "Detected Linux distribution: $PRETTY_NAME $ARCH"
    echo
}

install_packages() {
    initialization

    case $ID in
        ubuntu|debian)
            install_deb
            ;;
        rhel|centos|rocky|almalinux|ol|amzn)
            DCO_NAME="kmod-ovpn-dco"
            install_rpm
            ;;
        *)
            abort
            ;;
    esac
}

install_deb() {
    DISTRO_LIST="buster bullseye bookworm focal jammy noble"
    if echo $DISTRO_LIST |grep -q $VERSION_CODENAME ; then
        check_upgrade "deb"
        confirmation_prompt

        apt update || repo_error
        if $IF_HELD ; then
            apt-mark unhold $PLIST $DCO_NAME
        fi
        DEBIAN_FRONTEND=noninteractive apt -y install ca-certificates wget net-tools gnupg || repo_error
        mkdir -p /etc/apt/keyrings
        wget https://as-repository.openvpn.net/as-repo-public.asc -qO /etc/apt/keyrings/as-repository.asc
        echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/as-repository.asc] http://as-repository.openvpn.net/as/debian $VERSION_CODENAME main" > /etc/apt/sources.list.d/openvpn-as-repo.list
        apt update || repo_error
        DEBIAN_FRONTEND=noninteractive apt -y install $PLIST || repo_error
    else
        abort
    fi

    # DCO installation
    if echo $VERSION_CODENAME |grep -qv buster ; then
        if install_dco "deb" ; then
            apt update || repo_error
            DEBIAN_FRONTEND=noninteractive apt -y install $DCO_NAME || repo_error
        fi
    fi

    if $IF_HELD ; then
        apt-mark hold $PLIST $DCO_NAME
    fi
}

install_rpm() {
    RELEASE=$(echo $VERSION_ID |sed 's/\.[0-9]*//')
    DIST=$ID
    RPM_CLONES="rocky almalinux ol"

    if echo $RPM_CLONES |grep -q $ID ; then
        echo "WARNING: This Linux OS is a RHEL Clone and not officially supported," >&2
        echo "however in theory, it's compatible with RHEL Repositories which we do support." >&2
        echo "This should be compatible but there is no guarantee to function as expected." >&2
    fi

    check_upgrade "rpm"

    yum list updates 1>/dev/null || repo_error

    if [[ "$RELEASE" == "7" ]]; then
        if [[ "$ID" == "rhel" ]]; then
            confirmation_prompt
            subscription-manager repos --enable rhel-7-server-optional-rpms --enable rhel-server-rhscl-7-rpms || repo_error
        elif [[ "$ID" == "centos" ]]; then
            confirmation_prompt
            yum -y install centos-release-scl-rh || repo_error
        fi
        DIST="centos"
    elif [[ "$RELEASE" == "8" || "$RELEASE" == "9" ]]; then
        confirmation_prompt
        DIST="rhel"
    elif [[ "$ID" == "amzn" && "$RELEASE" == "2" ]]; then
        confirmation_prompt
    else
        abort
    fi

    if $IF_HELD ; then
        yum versionlock delete $PLIST $DCO_NAME
    fi
    yum -y remove openvpn-as-yum || repo_error
    yum -y install "https://as-repository.openvpn.net/as-repo-${DIST}${RELEASE}.rpm" || repo_error
    yum -y install $PLIST || repo_error

    # DCO installation
    if [[ "$RELEASE" == "8" || "$RELEASE" == "9" ]]; then
        if install_dco "rpm" ; then
            if [[ "$ID" == "rocky" || "$ID" == "almalinux" ]]; then
                if [[ "$RELEASE" == "8" ]]; then
                    yum config-manager --set-enabled powertools || repo_error
                elif [[ "$RELEASE" == "9" ]]; then
                    yum config-manager --set-enabled crb || repo_error
                fi
                yum -y install epel-release || repo_error
            elif [[ "$ID" == "rhel" ]]; then
                yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-"$RELEASE".noarch.rpm || repo_error
            fi
            yum -y install $DCO_NAME || repo_error
        fi
    fi

    if $IF_HELD ; then
        yum versionlock add $PLIST $DCO_NAME
    fi
}

install_dco() {
    if $WITHOUT_DCO; then
        return 103
    fi
    echo
    echo
    echo "Access Server 2.12 and newer supports OpenVPN Data Channel Offload (DCO)."
    echo "You can benefit from performance improvements when you enable DCO for your VPN server and clients."
    echo
    echo "Your running kernel version is '$(uname -r)'"
    echo
    echo "DCO needs Linux kernel headers to be installed."
    echo "If the Linux kernel headers are not present, they will be installed automatically."
    echo
    if ! $YES_MODE; then
        read -p "Would you like to install OpenVPN Data Channel Offload? (Y/n): " resp

        if [[ "$resp" == "N" || "$resp" == "n" ]]; then
            return 102
        fi
    fi
    if check_install_headers "$1" ; then
        echo
        echo "Linux kernel headers are installed. Proceeding with DCO installation."
        echo
        echo "Keep in mind that if newer kernel versions are available,"
        echo "there is a possibility that DCO installation could fail."
        return 0
    else
        echo
        echo "WARNING: The actual kernel headers could not be located and installed." >&2
        echo "For further guidance, please refer to our online documentation or contact our support team." >&2
        echo "https://openvpn.net/vpn-server-resources/openvpn-dco-access-server/" >&2
        echo
        echo "DCO can not be installed. Skipped." >&2
    fi
    return 101
}

check_install_headers() {
    if [[ "$1" == "rpm" ]]; then
        if rpm -q kernel-headers-$(uname -r) ; then
            return 0
        else
            if yum -y install kernel-headers-$(uname -r) kernel-devel-$(uname -r) ; then
                return 0
            fi
        fi
    elif [[ "$1" == "deb" ]]; then
        if dpkg -l |grep linux-headers-$(uname -r) ; then
            return 0
        else
            apt update || repo_error
            if apt -y install linux-headers-$(uname -r) ; then
                return 0
            fi
        fi
    fi
    return 100
}

check_upgrade() {
    if [[ "$1" == "rpm" ]]; then
        if rpm -q --quiet $PLIST ; then
            INSTALLED_VERSION=$(rpm -q --qf "%{VERSION}" $PLIST)
            upgrade_message $INSTALLED_VERSION
        fi
        if yum versionlock list 2>/dev/null |grep $PLIST |grep -q -v "yum\|bundled"; then
            IF_HELD=true
            held_message
        fi
    elif [[ "$1" == "deb" ]]; then
        if dpkg -s $PLIST 2>/dev/null |grep Status |grep -q installed ; then
            INSTALLED_VERSION=$(dpkg-query -W -f='${Version}\n' $PLIST)
            upgrade_message $INSTALLED_VERSION
        fi
        if apt-mark showhold |grep -q $PLIST ; then
            IF_HELD=true
            held_message
        fi
    else
        echo "Package type '$1' is not supported." >&2
        exit 200
    fi
}

upgrade_message() {
    echo "The OpenVPN Aceess Server $1 package is currently installed."
    echo "Upon proceeding, the script will check for a newer version available for"
    echo "the operating system and upgrade the existing installation."
    echo
}

held_message() {
    echo "WARNING:"
    echo "The current installation is pinned to that version so normal upgrade actions don't inadvertently upgrade it."
    echo "However, if you proceed this will be temporarily ignored and upgraded anyway."
    echo
}

confirmation_prompt() {
    if ! $YES_MODE; then
        echo "If you're ready to install the latest available version of OpenVPN Access Server, you can continue below."
        echo
        read -p "Do you want to proceed with the installation? (Y/n): " response

        if [[ "$response" == "N" || "$response" == "n" ]]; then
            echo "Installation aborted." >&2
            exit 0
        fi
    fi
}

usage() {
    echo "Usage: $0 [-y|--yes] [--without-dco] [-h|--help]"
    echo
    echo "OpenVPN Access Server installation script."
    echo
    echo "-y, --yes"
    echo "    Automatic yes to prompts. Assume 'yes' as answer to all prompts and run non-interactively."
    echo "    If an undesirable situation occurs then installation will abort."
    echo
    echo "--without-dco"
    echo "    Disables Data Channel Offload (DCO) installation."
    echo
    echo "-h, --help"
    echo "    Show a short usage summary."
    exit 0
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -y|--yes) YES_MODE=true; shift ;;
        --without-dco) WITHOUT_DCO=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
done

echo
echo
echo "Welcome to the OpenVPN Access Server Installation Script!"
echo
echo
echo "WARNING: Please verify if there are any available security"
echo "and kernel updates for your operating system. We recommend"
echo "installing and applying these updates before proceeding."
echo

install_packages

echo
echo "Installation successful!"