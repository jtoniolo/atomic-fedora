#!/bin/bash
set -euo pipefail

# Send all script output to stderr so it's visible in BuildKit container builds.
# BuildKit suppresses stdout from RUN steps but shows stderr.
exec 1>&2

echo "=== Building EVDI kernel module ==="

# Get kernel version - in container there's no grub, so query rpm directly.
# Use \n separator and sort to handle multiple installed kernels correctly.
KVER=$(rpm -q kernel --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' | sort -V | tail -1)
echo "Building for kernel: $KVER"

# Install kernel-devel for the target kernel BEFORE akmods needs it.
# This is the most common cause of akmods failures in ostree container builds:
# the base image ships a new kernel but kernel-devel hasn't been pulled in.
echo "Installing kernel-devel for $KVER..."
if ! dnf install -y kernel-devel-${KVER}; then
    echo "WARNING: kernel-devel-${KVER} not directly available, trying kernel-devel-matched..."
    dnf install -y kernel-devel-matched
fi

# Install EVDI/DisplayLink build dependencies
dnf install -y --enablerepo=fedora-multimedia --setopt=tsflags=noscripts displaylink akmod-evdi

# Create log directory for akmods
mkdir -p /var/log/akmods

# Verify kernel-devel is actually installed
echo "Checking kernel-devel..."
if ! rpm -q kernel-devel-${KVER} &>/dev/null; then
    echo "ERROR: kernel-devel-${KVER} is not installed after install attempt"
    echo "Installed kernel packages:"
    rpm -qa | grep -E "^kernel" || true
    echo "Available kernel-devel in repos:"
    dnf repoquery 'kernel-devel*' 2>/dev/null || true
    exit 1
fi

# Ensure /tmp is world-writable. BlueBuild's bind mounts under /tmp
# (for scripts, modules, files) can change /tmp permissions, which prevents
# the akmods user from creating its temp build directory there.
chmod 1777 /tmp /var/tmp

# Build the kmod for the specific kernel.
# Capture exit code so we can dump the build log on failure instead of
# letting set -e kill us before we print diagnostics.
echo "Running akmods for kernel $KVER..."
AKMODS_RC=0
akmods --force --kernels ${KVER} || AKMODS_RC=$?

if [ $AKMODS_RC -ne 0 ]; then
    echo "ERROR: akmods exited with code $AKMODS_RC"
    echo "=== akmods build log ==="
    cat /var/cache/akmods/evdi/*.log 2>/dev/null || echo "(no log files found)"
    echo "=== end build log ==="
    exit 1
fi

# Check if RPM was created (akmods can exit 0 but still fail to produce output)
if ! ls /var/cache/akmods/evdi/kmod-evdi-*.rpm 1>/dev/null 2>&1; then
    echo "ERROR: akmods completed but no kmod-evdi RPM was created"
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
