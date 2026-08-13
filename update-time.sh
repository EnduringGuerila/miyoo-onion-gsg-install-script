#!/bin/sh

# ==============================================================================
# GSG (Game Save Genie) Smart Time-Fix (with Persistence)
# Target: Miyoo Mini Plus (ARMv7)
# Description: Detects TZ via GeoIP, saves it locally, and uses it as fallback.
# ==============================================================================

set -e

# --- Configuration ---
ONION_APPS_DIR="/mnt/SDCARD/App"
TIME_FIX_TARGET="$ONION_APPS_DIR/TimeQuickFix"

# Persistence File: Stores the last known good timezone
TZ_STATE_FILE="$TIME_FIX_TARGET/last_tz.txt"

# UI Notification (Keep this, it's good UX)
if [ -f "/mnt/SDCARD/miyoo/lib/libpadsp.so" ]; then
    LD_PRELOAD=/mnt/SDCARD/miyoo/lib/libpadsp.so /mnt/SDCARD/.tmp_update/bin/infoPanel -t "Syncing Time" -m "Detecting timezone and syncing..." --auto &
fi

# Move to script directory
cd "$(dirname "$0")"

echo "Starting smart time sync..."

# 1. Determine Fallback Timezone from local state
FALLBACK_TZ=""
if [ -f "$TZ_STATE_FILE" ]; then
    FALLBACK_TZ=$(cat "$TZ_STATE_FILE" | tr -d '\r\n')
    echo "Found previous timezone in state file: $FALLBACK_TZ"
else
    echo "No previous timezone found. Defaulting to UTC."
    FALLBACK_TZ="UTC"
fi

# 2. Attempt GeoIP Detection
echo "Attempting to detect current timezone via internet..."
# We use a timeout to ensure the script doesn't hang if there is no connection
NEW_TZ=$(wget -T 5 -qO- http://ip-api.com/line?fields=timezone 2>/dev/null | tr -d '\r\n')

# 3. Logic: New Detection vs Fallback
if [ -n "$NEW_TZ" ] && [ "$NEW_TZ" != "null" ]; then
    echo "Success! Detected new timezone: $NEW_TZ"
    export TZ="$NEW_TZ"
    
    # Save this for next time (Persistence)
    echo "$NEW_TZ" > "$TZ_STATE_FILE"
else
    echo "GeoIP detection failed or timed out."
    echo "Using fallback timezone: $FALLBACK_TZ"
    export TZ="$FALLBACK_TZ"
fi

# 4. Robust NTP Sync
# -q: one-shot sync
# -g: allow 'stepping' (jumping) the clock if it is far off
echo "Syncing with NTP pool..."
if ntpd -q -g -p pool.ntp.org; then
    echo "NTP Sync successful."
else
    echo "NTP Sync failed. Attempting fallback server..."
    ntpd -q -g -p time.google.com || echo "Warning: Time sync failed entirely."
fi

# 5. Commit to Hardware Clock
# We use '-l' to tell hwclock that the system time we just set is Local Time.
echo "Writing local time to hardware clock..."
hwclock -l -w

echo "Time sync complete!"
