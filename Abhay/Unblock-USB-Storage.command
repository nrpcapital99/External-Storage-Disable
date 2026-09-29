#!/bin/bash

DAEMON="/Library/LaunchDaemons/com.nrpcapitals.blockusb.plist"
SCRIPT="/Library/PrivilegedHelperTools/com.nrpcapitals.blockusb.sh"

if [ "$EUID" -ne 0 ]; then
    echo "Administrator permission required."
    exec sudo "$0"
fi

echo ""
echo "=============================================="
echo " NRP Capitals - Remove USB Storage Protection"
echo "=============================================="
echo ""

# Stop the LaunchDaemon
/bin/launchctl bootout system "$DAEMON" >/dev/null 2>&1

# Remove daemon
rm -f "$DAEMON"

# Remove helper
rm -f "$SCRIPT"

echo "USB/External storage protection has been removed."
echo ""
echo "External storage should now work normally."
echo ""

echo "STATUS: UNBLOCKED"

echo ""
read -p "Press Enter to close..."
