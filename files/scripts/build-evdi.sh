#!/bin/bash
set -euo pipefail

echo "=== Building EVDI kernel module ==="

# Install dependencies
dnf install -y --setopt=tsflags=noscripts displaylink akmod-evdi

# Create log directory for akmods
mkdir -p /var/log/akmods

# Build the kmod
echo "Running akmods..."
akmods --force

# Check if RPM was created
if ! ls /var/cache/akmods/evdi/kmod-evdi-*.rpm 1>/dev/null 2>&1; then
    echo "ERROR: akmods failed to create kmod-evdi RPM"
    echo "Cache contents:"
    ls -la /var/cache/akmods/evdi/ || echo "No cache dir"
    echo "Log files:"
    cat /var/cache/akmods/evdi/*.log 2>/dev/null || echo "No logs"
    exit 1
fi

# Get kernel version
KVER=$(rpm -q kernel --qf '%{VERSION}-%{RELEASE}.%{ARCH}')
echo "Kernel version: $KVER"

# Extract and install the module
cd /tmp
rpm2cpio /var/cache/akmods/evdi/kmod-evdi-*.rpm | cpio -idmv
mkdir -p /lib/modules/${KVER}/extra/evdi
cp -v lib/modules/*/extra/evdi/evdi.ko* /lib/modules/${KVER}/extra/evdi/
depmod -a ${KVER}

# Cleanup
rm -rf /tmp/lib

echo "=== EVDI module installed successfully ==="
