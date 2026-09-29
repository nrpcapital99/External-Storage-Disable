#!/bin/bash

# ============================================================
# NRP Capitals - Block External Storage
# macOS Ventura 13.5
#
# This installs a LaunchDaemon that continuously checks for
# external physical storage devices and unmounts them.
#
# USB keyboards, mice, printers, etc. are not targeted.
# ============================================================

DAEMON="/Library/LaunchDaemons/com.nrpcapitals.blockusb.plist"
SCRIPT="/Library/PrivilegedHelperTools/com.nrpcapitals.blockusb.sh"

if [ "$EUID" -ne 0 ]; then
    echo "Administrator permission required."
    echo "Requesting administrator access..."
    exec sudo "$0"
fi

echo ""
echo "=============================================="
echo " NRP Capitals - USB Storage Protection"
echo "=============================================="
echo ""

# Create helper script
cat > "$SCRIPT" <<'HELPER'
#!/bin/bash

# Continuously monitor external physical disks.
while true
do
    # Get external physical disks
    DISKS=$(/usr/sbin/diskutil list external physical 2>/dev/null | \
        /usr/bin/awk '/^\/dev\/disk[0-9]+/ {print $1}')

    for DISK in $DISKS
    do
        # Never touch disk0.
        # This is an additional safety check.
        if [ "$DISK" != "/dev/disk0" ]; then

            # Check whether it is actually external
            INFO=$(/usr/sbin/diskutil info "$DISK" 2>/dev/null)

            INTERNAL=$(/usr/bin/echo "$INFO" | \
                /usr/bin/grep -i "Internal:" | \
                /usr/bin/awk '{print $2}')

            if [ "$INTERNAL" = "No" ]; then
                /usr/sbin/diskutil unmountDisk force "$DISK" >/dev/null 2>&1
            fi
        fi
    done

    sleep 2
done
HELPER

chmod 755 "$SCRIPT"
chown root:wheel "$SCRIPT"

# Create LaunchDaemon
cat > "$DAEMON" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>

    <key>Label</key>
    <string>com.nrpcapitals.blockusb</string>

    <key>ProgramArguments</key>
    <array>
        <string>$SCRIPT</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>ProcessType</key>
    <string>Background</string>

</dict>
</plist>
PLIST

chmod 644 "$DAEMON"
chown root:wheel "$DAEMON"

# Remove any old instance
/bin/launchctl bootout system "$DAEMON" >/dev/null 2>&1

# Load the protection
/bin/launchctl bootstrap system "$DAEMON"

if [ $? -eq 0 ]; then
    echo ""
    echo "USB/External storage protection is ACTIVE."
    echo ""
    echo "Testing service status..."
    /bin/launchctl print system/com.nrpcapitals.blockusb >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "STATUS: PASS"
        echo ""
        echo "Insert a USB pen drive to test."
        echo "It should be automatically unmounted."
    else
        echo "STATUS: FAILED"
    fi
else
    echo ""
    echo "STATUS: FAILED"
    echo "The protection could not be loaded."
fi

echo ""
read -p "Press Enter to close..."
