#!/bin/bash
set -ouex pipefail

### Install packages
## starship
dnf5 -y copr enable atim/starship
dnf5 install -y starship
dnf5 -y copr disable atim/starship # disable COPRs so they don't end up enabled on the final image

## tailscale
dnf5 config-manager addrepo \
  --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo \
  --save-filename=tailscale \
  --overwrite
dnf5 install -y tailscale
rm -f /etc/yum.repos.d/tailscale.repo
systemctl enable tailscaled.service

## install ffmpeg and codecs from RPM Fusion
# see: https://rpmfusion.org/Howto/OSTree
dnf5 install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
# Enable stable RPM Fusion repos; disable Rawhide if present
dnf5 config-manager setopt \
  rpmfusion-free.enabled=1 \
  rpmfusion-free-updates.enabled=1 \
  rpmfusion-nonfree.enabled=1 \
  rpmfusion-nonfree-updates.enabled=1
dnf5 config-manager setopt 'rpmfusion-*-rawhide.enabled=0' || :
# software codecs
dnf5 install -y \
  gstreamer1-plugin-libav \
  gstreamer1-plugins-bad-free-extras \
  gstreamer1-plugins-bad-freeworld \
  gstreamer1-plugins-ugly \
  gstreamer1-vaapi \
  ffmpeg \
  --allowerasing
dnf5 install -y intel-media-driver
# hardware codecs
# now disable RPM Fusion repos
dnf5 config-manager setopt 'rpmfusion-*.enabled=0'

# more packages
PACKAGES=(
    emacs
    fzf
    ripgrep
    fd-find
    bfs
    syncthing
    thunderbird
    libxcrypt-compat # needed to make biber (texlive) work
    fuse-sshfs # sshfs
    rclone # cloud storage and sync
    restic # backup tool
    wl-mirror # mirror screen/output
    NetworkManager-tui # nmtui
    flameshot # screenshot
    trash-cli # delete by moving to trash
    fastfetch # system info
    wayvnc # VNC/remote desktop
)
dnf5 install -y "${PACKAGES[@]}"

# clean caches
dnf5 clean all


### Set up install of Flatpak packages at boot
source /ctx/default-flatpaks.sh
FLATPAK_REMOTE_NAME="flathub"
FLATPAK_REMOTE_URL="https://dl.flathub.org/repo/flathub.flatpakrepo"
DISABLE_FEDORA_REMOTE="true"
FLATPAKS=(
    # org.mozilla.firefox
    # org.mozilla.Thunderbird
    org.goldendict.GoldenDict
    org.kde.okular
    org.zotero.Zotero
    net.ankiweb.Anki
    org.keepassxc.KeePassXC
    us.zoom.Zoom
    com.github.jeromerobert.pdfarranger
    com.brave.Browser
    com.github.tchx84.Flatseal
    com.github.xournalpp.xournalpp
    io.mpv.Mpv
    org.libreoffice.LibreOffice
    com.github.johnfactotum.Foliate
    net.nokyan.Resources # system monitor
)
setup_default_flatpaks
