#!/usr/bin/env bash
# Installs (or updates) Android Studio inside the `android` distrobox and
# exports it to the host's application menu.
#
# Run from the host:
#   /etc/nixos/android-dev/install-android-studio.sh
#
# The tarball URL is scraped from developer.android.com. The version token in
# the file name is numeric in older releases and a codename in newer ones
# (android-studio-2024.3.1.14-linux.tar.gz, android-studio-rabbit1-linux.tar.gz),
# so the pattern only fixes the android-studio-...-linux.tar.gz shape.
# To pin a version or install a preview build, pass the URL explicitly:
#   ANDROID_STUDIO_URL=https://.../android-studio-<ver>-linux.tar.gz \
#     /etc/nixos/android-dev/install-android-studio.sh
set -euo pipefail

# On the host: re-run inside the container. The container has its own /etc,
# so /etc/nixos is not there; the host filesystem is mounted at /run/host.
if [ -z "${CONTAINER_ID:-}" ]; then
  exec distrobox enter android -- \
    env ANDROID_STUDIO_URL="${ANDROID_STUDIO_URL:-}" \
    bash "/run/host$(realpath "$0")"
fi

install_dir="$HOME/.local/share/android-studio"
sdk_dir="$HOME/Android/Sdk"

url="${ANDROID_STUDIO_URL:-}"
if [ -z "$url" ]; then
  url="$(curl -fsSL https://developer.android.com/studio \
    | grep -oE 'https://[^"]+/android-studio-[^"/]+-linux\.tar\.gz' \
    | head -n1)"
fi
if [ -z "$url" ]; then
  echo "Could not find the Android Studio download URL; set ANDROID_STUDIO_URL." >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "Downloading $url"
curl -fL --progress-bar -o "$tmp/studio.tar.gz" "$url"
mkdir "$tmp/x"
tar -xzf "$tmp/studio.tar.gz" -C "$tmp/x"

# The tarball holds a single top-level directory (normally android-studio/).
extracted="$(find "$tmp/x" -mindepth 1 -maxdepth 1 -type d | head -n1)"
if [ -z "$extracted" ] || [ ! -d "$extracted/bin" ]; then
  echo "Unexpected tarball layout:" >&2
  ls -la "$tmp/x" "$extracted" >&2 || true
  exit 1
fi

# Replace the previous install; settings and plugins live in
# ~/.config/Google and ~/.local/share/Google, not here.
rm -rf "$install_dir"
mkdir -p "$(dirname "$install_dir")"
mv "$extracted" "$install_dir"

# Newer releases ship a native bin/studio launcher, older ones only
# bin/studio.sh; take whichever exists.
launcher=""
for name in studio studio.sh; do
  if [ -x "$install_dir/bin/$name" ]; then
    launcher="$install_dir/bin/$name"
    break
  fi
done
if [ -z "$launcher" ]; then
  echo "No studio launcher in $install_dir/bin:" >&2
  ls -la "$install_dir/bin" >&2
  exit 1
fi

icon="$install_dir/bin/studio.svg"
[ -f "$icon" ] || icon="$install_dir/bin/studio.png"

# A stable command name inside the container, whatever the launcher is called.
sudo ln -sf "$launcher" /usr/local/bin/android-studio

mkdir -p "$sdk_dir" "$HOME/.android/avd"

# Environment for every shell opened in the container (`distrobox enter android`).
sudo tee /etc/profile.d/android.sh >/dev/null <<EOF
export ANDROID_HOME="$sdk_dir"
export ANDROID_SDK_ROOT="$sdk_dir"
export ANDROID_USER_HOME="\$HOME/.android"
export ANDROID_AVD_HOME="\$HOME/.android/avd"
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
export PATH="$install_dir/bin:\$ANDROID_HOME/emulator:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/cmdline-tools/latest/bin:\$PATH"
# IntelliJ-based IDEs under a Wayland compositor (KDE Plasma 6, via XWayland).
export _JAVA_AWT_WM_NONREPARENTING=1
EOF

# A desktop entry inside the container, so distrobox-export can put a
# launcher (`distrobox enter android -- android-studio`) into the host menu.
sudo tee /usr/share/applications/android-studio.desktop >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Android Studio
Comment=Android IDE
Exec=/usr/local/bin/android-studio %f
Icon=$icon
Categories=Development;IDE;
Terminal=false
StartupWMClass=jetbrains-studio
EOF

distrobox-export --app android-studio

# adb/fastboot for host terminals, running the SDK's copy inside the
# container. One adb server per machine: the host has no adb of its own, so
# Studio and host shells never fight over port 5037 with mismatched versions.
for bin in adb fastboot; do
  if [ -x "$sdk_dir/platform-tools/$bin" ]; then
    distrobox-export --bin "$sdk_dir/platform-tools/$bin" --export-path "$HOME/.local/bin"
  else
    echo "Skipping $bin export: install SDK Platform-Tools in Studio, then re-run this script."
  fi
done

echo "Android Studio installed to $install_dir (launcher: $launcher)"
echo "Start it from the KDE menu or: distrobox enter android -- android-studio"
