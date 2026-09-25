#!/usr/bin/env bash
# Disk space maximizer for GitHub Actions kernel builds
set -uo pipefail

echo "=== Disk before cleanup ==="
df -h / || true

echo "=== Removing large preinstalled toolchains (KEEP /usr/lib/jvm for Kotlin) ==="
for d in \
  /usr/share/dotnet \
  /usr/local/lib/android \
  /usr/local/lib/android/sdk \
  /opt/ghc \
  /usr/local/.ghcup \
  /opt/hostedtoolcache/CodeQL \
  /usr/local/share/boost \
  /usr/share/swift \
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

# Ensure a JDK exists (needed by Kotlin scripts in the build workflow)
if ! command -v java >/dev/null 2>&1; then
  echo "=== java not found, installing default-jre-headless ==="
  apt-get update -qq 2>/dev/null || true
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq default-jre-headless 2>/dev/null || true
fi
echo "java: $(command -v java || echo MISSING)"

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
