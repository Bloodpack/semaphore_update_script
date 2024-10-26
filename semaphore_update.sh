#!/bin/bash

# bash script to update SemaphoreUI Packageinstallation on Ubuntu Server.
# Copyright (c) 2023 Bloodpack
# Author: Bloodpack 
# License: GPL-3.0 license
# Follow or contribute on GitHub here:
# https://github.com/Bloodpack/semaphore_update_script
################################
# VERSION: 1.0 from 26.10.2024 #
################################


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
echo "Stopping Semaphore service..."
systemctl stop semaphore

# Download the latest amd64.deb package
curl -LO "$DOWNLOAD_URL"

# Install the downloaded package
echo "Installing the package..."
dpkg -i "semaphore_${RELEASE}_linux_amd64.deb"

# Start the Semaphore service
echo "Starting Semaphore service..."
systemctl start semaphore

echo "Update complete."
