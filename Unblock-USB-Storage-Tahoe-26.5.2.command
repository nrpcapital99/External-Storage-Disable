#!/bin/bash
# NRP Capitals - Unblock USB Storage
# Target: macOS 26.x

set -u

OS_VERSION="$(/usr/bin/sw_vers -productVersion)"
case "$OS_VERSION" in
  26.*) ;;
  *)
    echo "ERROR: This script is for macOS 26.x only."
    echo "Detected macOS version: $OS_VERSION"
    exit 1
    ;;
esac

if [ "$(id -u)" -ne 0 ]; then
    echo "Administrator permission is required."
    exec /usr/bin/sudo "$0"
fi

DAEMON="/Library/LaunchDaemons/com.nrpcapitals.blockusb.tahoe.plist"
HELPER="/Library/PrivilegedHelperTools/com.nrpcapitals.blockusb.tahoe.sh"
LABEL="com.nrpcapitals.blockusb.tahoe"

echo "NRP Capitals - Removing USB Storage Protection"
echo "Detected macOS: $OS_VERSION"
echo

/usr/bin/launchctl bootout system "$DAEMON" >/dev/null 2>&1 || true

/bin/rm -f "$DAEMON"
/bin/rm -f "$HELPER"

if /usr/bin/launchctl print "system/$LABEL" >/dev/null 2>&1; then
    echo "STATUS: FAILED"
    echo "The background service is still present."
    exit 1
fi

echo "STATUS: PASS"
echo "USB storage protection has been removed."
echo "External USB storage can be mounted normally again."
