#!/usr/bin/env bash
# Disk space maximizer for GitHub Actions kernel builds
# Equivalent to the upstream maximize-build-space.sh (free large preinstalled dirs)
set -uo pipefail

echo "=== Disk before cleanup ==="
df -h / || true

echo "=== Removing large preinstalled toolchains ==="
for d in \
  /usr/share/dotnet \
  /usr/local/lib/android \
  /usr/local/lib/android/sdk \
  /opt/ghc \
  /usr/local/.ghcup \
  /opt/hostedtoolcache/CodeQL \
  /usr/local/share/boost \
  /usr/share/swift \
  /usr/lib/jvm \
  /usr/lib/mono \
  /usr/lib/R \
  /usr/local/share/chromium \
  /opt/microsoft \
  /opt/google/chrome \
  /var/lib/snapd ; do
  if [ -e "$d" ]; then
    echo "  removing $d"
    rm -rf "$d" 2>/dev/null || true
  fi
done

echo "=== apt clean ==="
apt-get clean 2>/dev/null || true
rm -rf /var/lib/apt/lists/* 2>/dev/null || true

echo "=== Setting up 3G swap ==="
swapoff -a 2>/dev/null || true
rm -f /swapfile 2>/dev/null || true
dd if=/dev/zero of=/swapfile bs=1M count=3072 status=none 2>/dev/null || true
chmod 600 /swapfile 2>/dev/null || true
mkswap /swapfile 2>/dev/null || true
swapon /swapfile 2>/dev/null || true

echo "=== Disk after cleanup ==="
df -h / || true
free -h || true

exit 0
