#!/bin/sh

# 1. UI Notification (Keep this, it's good UX)
# We use the existing infoPanel if available
if [ -f "/mnt/SDCARD/miyoo/lib/libpadsp.so" ]; then
    LD_PRELOAD=/mnt/SDCARD/miyoo/lib/libpadsp.so /mnt/SDCARD/.tmp_update/bin/infoPanel -t "Syncing Time" -m "Detecting timezone and syncing..." --auto &
fi

# Move to script directory
cd "$(dirname "$0")"

echo "Starting smart time sync..."

# 2. Detect Timezone via GeoIP API
# We use the 'line' format from ip-api.com because it is much easier 
# for a minimal shell script to parse than JSON.
echo "Detecting timezone..."
NEW_TZ=$(wget -qO- http://ip-api.com/line?fields=timezone | tr -d '\r\n')

if [ -n "$NEW_TZ" ] && [ "$NEW_TZ" != "null" ]; then
    echo "Detected Timezone: $NEW_TZ"
    export TZ="$NEW_TZ"
else
    echo "Timezone detection failed. Falling back to UTC."
    export TZ="UTC"
fi

# 3. Robust NTP Sync
# Instead of one hardcoded IP, we use the NTP Pool. This is much more reliable.
# -q tells ntpd to quit after setting the time (one-shot sync)
echo "Syncing with NTP pool..."
if ntpd -q -p pool.ntp.org; then
    echo "NTP Sync successful."
else
    echo "NTP Sync failed. Attempting fallback server..."
    ntpd -q -p time.google.com || echo "Warning: Time sync failed entirely."
fi

# 4. Commit to Hardware Clock
# This ensures the time survives a reboot/power cycle.
echo "Writing to hardware clock..."
hwclock -w

echo "Time sync complete!"
