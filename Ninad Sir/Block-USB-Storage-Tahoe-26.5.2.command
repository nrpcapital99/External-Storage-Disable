#!/bin/bash
# NRP Capitals - Block USB Storage
# Target: macOS 26.x (tested design for Tahoe)
# This is a local LaunchDaemon. It unmounts USB storage disks.
# It does NOT disable USB keyboards, mice, printers, etc.

set -u

DAEMON="/Library/LaunchDaemons/com.nrpcapitals.blockusb.tahoe.plist"
HELPER="/Library/PrivilegedHelperTools/com.nrpcapitals.blockusb.tahoe.sh"
LABEL="com.nrpcapitals.blockusb.tahoe"

# ---- Require macOS 26.x ----
OS_VERSION="$(/usr/bin/sw_vers -productVersion)"
case "$OS_VERSION" in
  26.*) ;;
  *)
    echo "ERROR: This script is for macOS 26.x only."
    echo "Detected macOS version: $OS_VERSION"
    exit 1
    ;;
esac

# ---- Require administrator privileges ----
if [ "$(id -u)" -ne 0 ]; then
    echo "Administrator permission is required."
    exec /usr/bin/sudo "$0"
fi

echo "NRP Capitals - USB Storage Protection"
echo "Detected macOS: $OS_VERSION"
echo

# Stop an older copy if present
/usr/bin/launchctl bootout system "$DAEMON" >/dev/null 2>&1 || true

# Create helper
/bin/cat > "$HELPER" <<'HELPER_EOF'
#!/bin/bash

# Only act on external physical USB disks.
# USB keyboards/mice/printers are not disks and are not targeted.

while true; do
    for disk in $(/usr/sbin/diskutil list external physical 2>/dev/null | \
        /usr/bin/awk '/^\/dev\/disk[0-9]+ / {print $1}')
    do
        [ -z "$disk" ] && continue

        info="$(/usr/sbin/diskutil info "$disk" 2>/dev/null)"

        # Only USB protocol devices
        if /usr/bin/printf '%s\n' "$info" | /usr/bin/grep -qE '^[[:space:]]*Protocol:[[:space:]]+USB[[:space:]]*$'; then
            /usr/sbin/diskutil unmountDisk force "$disk" >/dev/null 2>&1
        fi
    done

    /bin/sleep 2
done
HELPER_EOF

/usr/sbin/chown root:wheel "$HELPER"
/bin/chmod 755 "$HELPER"

# Create LaunchDaemon
/bin/cat > "$DAEMON" <<PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>

    <key>ProgramArguments</key>
    <array>
        <string>$HELPER</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>ProcessType</key>
    <string>Background</string>
</dict>
</plist>
PLIST_EOF

/usr/sbin/chown root:wheel "$DAEMON"
/bin/chmod 644 "$DAEMON"

# Load daemon
/usr/bin/launchctl bootstrap system "$DAEMON"

if /usr/bin/launchctl print "system/$LABEL" >/dev/null 2>&1; then
    echo "STATUS: PASS"
    echo "USB storage protection is ACTIVE."
    echo
    echo "Insert a test USB flash drive."
    echo "It should be detected by macOS but immediately unmounted."
else
    echo "STATUS: FAILED"
    echo "The LaunchDaemon could not be loaded."
    exit 1
fi

echo
echo "IMPORTANT: Test with a non-critical USB drive."
