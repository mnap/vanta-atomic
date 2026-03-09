#!/usr/bin/env bash

setup_default_flatpaks() {
  install -Dpm0644 /ctx/files/usr/lib/systemd/system/install-default-flatpaks.service \
    /usr/lib/systemd/system/install-default-flatpaks.service

  install -Dpm0644 /ctx/files/usr/lib/systemd/system/install-default-flatpaks.timer \
    /usr/lib/systemd/system/install-default-flatpaks.timer

  install -d /usr/libexec

  {
    echo '#!/usr/bin/env bash'
    echo 'set -euo pipefail'

    printf 'FLATPAK_REMOTE_NAME=%q\n' "$FLATPAK_REMOTE_NAME"
    printf 'FLATPAK_REMOTE_URL=%q\n' "$FLATPAK_REMOTE_URL"
    printf 'DISABLE_FEDORA_REMOTE=%q\n' "${DISABLE_FEDORA_REMOTE:-false}"

    echo 'FLATPAKS=('
    for app in "${FLATPAKS[@]}"; do
      printf '  %q\n' "$app"
    done
    echo ')'

    cat <<'EOF'
echo "default-flatpaks: starting installation"
if [[ "${DISABLE_FEDORA_REMOTE:-false}" == "true" ]]; then
  echo "default-flatpaks: removing Fedora Flatpak remotes if present"
  flatpak remote-delete --system fedora || true
  flatpak remote-delete --system fedora-testing || true
fi
echo "default-flatpaks: ensuring remote ${FLATPAK_REMOTE_NAME} exists"
flatpak remote-add --system --if-not-exists \
  "$FLATPAK_REMOTE_NAME" \
  "$FLATPAK_REMOTE_URL"
if ((${#FLATPAKS[@]})); then
  echo "default-flatpaks: installing ${#FLATPAKS[@]} Flatpak(s)"
  flatpak install --system --noninteractive \
    "$FLATPAK_REMOTE_NAME" \
    "${FLATPAKS[@]}"
else
  echo "default-flatpaks: no Flatpaks configured"
fi
echo "default-flatpaks: done"
EOF
  } > /usr/libexec/install-default-flatpaks.sh

  chmod 0755 /usr/libexec/install-default-flatpaks.sh

  systemctl enable install-default-flatpaks.timer
}
