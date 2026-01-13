#!/bin/bash
set -euo pipefail

echo "=== Building EVDI kernel module ==="

# Get kernel version first - in container there's no grub, so query rpm directly
KVER=$(rpm -q kernel --qf '%{VERSION}-%{RELEASE}.%{ARCH}' | head -1)
echo "Building for kernel: $KVER"

# Install dependencies
dnf install -y --setopt=tsflags=noscripts displaylink akmod-evdi

# Create log directory for akmods
mkdir -p /var/log/akmods

# Verify kernel-devel is available
echo "Checking kernel-devel..."
if ! rpm -q kernel-devel-${KVER} &>/dev/null; then
    echo "WARNING: kernel-devel-${KVER} not found, checking available:"
    rpm -qa | grep -E "^kernel" || true
fi

# Build the kmod for the specific kernel
echo "Running akmods for kernel $KVER..."
akmods --force --kernels ${KVER}

# Check if RPM was created
if ! ls /var/cache/akmods/evdi/kmod-evdi-*.rpm 1>/dev/null 2>&1; then
    echo "ERROR: akmods failed to create kmod-evdi RPM"
    echo "Cache contents:"
    ls -la /var/cache/akmods/evdi/ || echo "No cache dir"
    echo "Log files:"
    cat /var/cache/akmods/evdi/*.log 2>/dev/null || echo "No logs"
    exit 1
fi

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
