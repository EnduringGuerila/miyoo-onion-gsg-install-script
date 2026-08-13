#!/bin/sh

# ==============================================================================
# GSG (Game Save Genie) OnionOS Setup & Dependency Installer
# Target: Miyoo Mini Plus (ARMv7)
# Description: Installs latest rclone, TimeQuickFix via ZIP, and GSG as an App.
# ==============================================================================

set -e

# --- Configuration ---
ONION_ROOT="/mnt/SDCARD"
ONION_APPS_DIR="$ONION_ROOT/App"

# rclone (Using the 'current' link for always-latest)
RCLONE_BIN="$ONION_ROOT/rclone"
RCLONE_URL="https://downloads.rclone.org/rclone-current-linux-arm-v7.zip"

# GSG App Configuration
GSG_DIR="$ONION_APPS_DIR/GSG"

# TimeQuickFix Dependency (Using GitHub ZIP)
TIME_FIX_TARGET="$ONION_APPS_DIR/TimeQuickFix"
TIME_FIX_LAUNCH="$TIME_FIX_TARGET/launch.sh"
TIME_FIX_CONFIG="$TIME_FIX_TARGET/config.json"
TIME_FIX_REPO="https://github.com/hotcereal/time-quick-fix"
TIME_FIX_ZIP="https://github.com/hotcereal/time-quick-fix/archive/refs/heads/main.zip"

# FIX: Use SD card for temp files to avoid "No space left on device" in RAM (/tmp)
TEMP_DIR="$ONION_ROOT/gsg_temp"

# Cleanup function to be called on exit (success or error)
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        echo -e "${YELLOW}Cleaning up temporary files...${NC}"
        rm -rf "$TEMP_DIR"
    fi
}

# Register the cleanup function to run whenever the script exits
trap cleanup EXIT

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Starting GSG Setup for OnionOS...${NC}"

# 1. Prepare Directories
echo -e "${YELLOW}[1/4] Preparing directories...${NC}"
mkdir -p "$GSG_DIR"
mkdir -p "$TEMP_DIR"

# 2. Install rclone (Global Utility)
echo -e "${YELLOW}[2/4] Checking rclone installation...${NC}"
if [ -x "$RCLONE_BIN" ]; then
    echo -e "${GREEN}✓ rclone is already installed at $RCLONE_BIN${NC}"
else
    echo "rclone not found. Downloading latest..."
    wget -q "$RCLONE_URL" -O "$TEMP_DIR/rclone.zip"
    
    echo "Extracting archive (BusyBox compatible mode)..."
    mkdir -p "$TEMP_DIR/rclone_extracted"
    unzip -q "$TEMP_DIR/rclone.zip" -d "$TEMP_DIR/rclone_extracted"
    
    echo "Locating and moving binary to SD root..."
    RCLONE_FOUND=$(find "$TEMP_DIR/rclone_extracted" -name "rclone" | head -n 1)
    
    if [ -n "$RCLONE_FOUND" ]; then
        mv "$RCLONE_FOUND" "$RCLONE_BIN"
        chmod +x "$RCLONE_BIN"
        echo -e "${GREEN}✓ rclone installed to $RCLONE_BIN${NC}"
    else
        echo -e "${RED}Error: Could not find rclone binary in the zip file.${NC}"
        exit 1
    fi
fi

# 3. Install time-quick-fix (The Dependency via ZIP)
echo -e "${YELLOW}[3/4] Checking time-quick-fix dependency...${NC}"
if [ -f "$TIME_FIX_LAUNCH" ] && [ -f "$TIME_FIX_CONFIG" ]; then
    echo -e "${GREEN}✓ time-quick-fix is already installed and verified.${NC}"
else
    if [ -d "$TIME_FIX_TARGET" ]; then
        echo -e "${YELLOW}! Incomplete or corrupt TimeQuickFix detected. Reinstalling...${NC}"
        rm -rf "$TIME_FIX_TARGET"
    fi

    echo "Downloading time-quick-fix ZIP..."
    wget -q "$TIME_FIX_ZIP" -O "$TEMP_DIR/tf.zip"
    
    echo "Extracting TimeQuickFix..."
    mkdir -p "$TEMP_DIR/tf_extracted"
    unzip -q "$TEMP_DIR/tf.zip" -d "$TEMP_DIR/tf_extracted"
    
    EXTRACTED_SUBDIR=$(find "$TEMP_DIR/tf_extracted" -maxdepth 1 -type d -name "time-quick-fix-*" | head -n 1)
    
    if [ -d "$EXTRACTED_SUBDIR/App/TimeQuickFix" ]; then
        mkdir -p "$TIME_FIX_TARGET"
        cp -r "$EXTRACTED_SUBDIR/App/TimeQuickFix/"* "$TIME_FIX_TARGET/"
        chmod +x "$TIME_FIX_TARGET/launch.sh"
        
        if [ -f "$TIME_FIX_LAUNCH" ] && [ -f "$TIME_FIX_CONFIG" ]; then
            echo -e "${GREEN}✓ time-quick-fix installed and verified.${NC}"
        else
            echo -e "${RED}Error: Installation finished but files are missing!${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Error: Could not find App/TimeQuickFix inside the downloaded ZIP.${NC}"
        exit 1
    fi
fi

# 4. Create GSG Launch Script (The App Entry Point)
echo -e "${YELLOW}[4/4] Skipping GSG App entry...${NC}"

:' #commenting out this section for testing
# 4. Create GSG Launch Script (The App Entry Point)
if [ -f "$GSG_DIR/launch.sh" ]; then
    echo -e "${GREEN}✓ GSG launch script already exists.${NC}"
else
    echo "Creating launch.sh for GSG..."
    cat <<EOF > "$GSG_DIR/launch.sh"
#!/bin/sh
# GSG Launch Script
echo "Starting Game Save Genie..."
# When the dev is ready, replace the line below with the actual execution command:
# /mnt/SDCARD/App/GSG/main.sh
sleep 2
EOF
    chmod +x "$GSG_DIR/launch.sh"
    echo -e "${GREEN}✓ GSG launch script created.${NC}"
fi
' # end of comment block

echo -e "\n${GREEN}==============================================${NC}"
echo -e "${GREEN}   GSG Setup Complete!${NC}"
echo -e "   rclone: $RCLONE_BIN"
echo -e "   GSG App: $GSG_DIR"
echo -e "   TimeFix: $TIME_FIX_TARGET"
echo -e "${GREEN}==============================================${NC}"
