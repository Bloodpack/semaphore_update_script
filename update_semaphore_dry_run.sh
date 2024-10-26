#!/bin/bash

# Set a flag for dry run and verbosity
DRY_RUN=false  # Change to true for a dry run
VERBOSE=true   # Change to false to disable verbose output

# Function to execute or echo commands based on the dry run flag
run_command() {
    if $DRY_RUN; then
        echo "[DRY RUN] $*"
    else
        if $VERBOSE; then
            echo "[EXECUTE] $*"
        fi
        eval "$*"
    fi
}

# Function to print messages if verbosity is enabled
verbose_echo() {
    if $VERBOSE; then
        echo "$1"
    fi
}

# Fetch the latest releases from the specified GitHub repository
verbose_echo "Fetching latest releases..."
RELEASE_INFO=$(curl -s https://api.github.com/repos/semaphoreui/semaphore/releases)

# Extract the latest release tag and the download URL for amd64.deb
RELEASE=$(echo "$RELEASE_INFO" | grep -m 1 '"tag_name"' | awk '{print substr($2, 2, length($2)-3)}')
DOWNLOAD_URL=$(echo "$RELEASE_INFO" | grep -o "https://github.com/semaphoreui/semaphore/releases/download/${RELEASE}/semaphore_[^ ]*amd64.deb" | head -n 1)

# Check if the release tag and download URL were successfully fetched
if [ -z "$RELEASE" ] || [ -z "$DOWNLOAD_URL" ]; then
    echo "Failed to fetch the latest amd64.deb release."
    exit 1
fi

# Get the currently running version and strip any 'v' prefix
CURRENT_VERSION=$(dpkg -s semaphore | grep 'Version:' | awk '{print $2}')
CURRENT_VERSION=${CURRENT_VERSION#v}  # Strip 'v' if it exists
verbose_echo "Current version is: $CURRENT_VERSION"
verbose_echo "Latest release is: $RELEASE"

# Strip 'v' from the latest release for comparison
LATEST_VERSION=${RELEASE#v}  # Ensure the latest version is without 'v'

# Check if a new version is available
if [ "$CURRENT_VERSION" == "$LATEST_VERSION" ]; then
    echo "You are already running the latest version. Aborting update."
    exit 0
else
    read -p "A new version is available. Do you want to proceed with the update? (y/n): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Update aborted by user."
        exit 0
    fi
fi

# Stop the Semaphore service
verbose_echo "Stopping Semaphore service..."
run_command "systemctl stop semaphore"

# Download the latest amd64.deb package
verbose_echo "Downloading $DOWNLOAD_URL..."
run_command "curl -LO \"$DOWNLOAD_URL\""

# Install the downloaded package
verbose_echo "Installing the package..."
run_command "dpkg -i \"semaphore_${RELEASE}_linux_amd64.deb\""

# Start the Semaphore service
verbose_echo "Starting Semaphore service..."
run_command "systemctl start semaphore"

echo "Update complete."

