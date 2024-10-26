#!/bin/bash

# Set a flag for dry run
DRY_RUN=true  # Change this to false to execute the commands

# Function to execute or echo commands based on the dry run flag
run_command() {
    if $DRY_RUN; then
        echo "[DRY RUN] $*"
    else
        eval "$*"
    fi
}

# Fetch the latest releases from the specified GitHub repository
RELEASE_INFO=$(curl -s https://api.github.com/repos/semaphoreui/semaphore/releases)

# Extract the latest release tag and the download URL for amd64.deb
RELEASE=$(echo "$RELEASE_INFO" | grep -m 1 '"tag_name"' | awk '{print substr($2, 2, length($2)-3)}')
DOWNLOAD_URL=$(echo "$RELEASE_INFO" | grep -o "https://github.com/semaphoreui/semaphore/releases/download/${RELEASE}/semaphore_[^ ]*amd64.deb" | head -n 1)

# Check if the release tag and download URL were successfully fetched
if [ -z "$RELEASE" ] || [ -z "$DOWNLOAD_URL" ]; then
    echo "Failed to fetch the latest amd64.deb release."
    exit 1
fi

echo "The latest release is: $RELEASE"
echo "Downloading $DOWNLOAD_URL..."

# Stop the Semaphore service
run_command "systemctl stop semaphore"

# Download the latest amd64.deb package
run_command "curl -LO \"$DOWNLOAD_URL\""

# Install the downloaded package
run_command "dpkg -i \"semaphore_${RELEASE}_linux_amd64.deb\""

# Start the Semaphore service
run_command "systemctl start semaphore"

echo "Update complete."
