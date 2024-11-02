#!/bin/bash

# bash script to update SemaphoreUI Package installation on Ubuntu Server.
# Copyright (c) 2023 Bloodpack
# Author: Bloodpack 
# License: GPL-3.0 license
# Follow or contribute on GitHub here:
# https://github.com/Bloodpack/semaphore_update_script
################################
# VERSION: 1.0 from 26.10.2024 #
################################

# Set a flag for verbosity
VERBOSE=true  # Change to false to disable verbose output

# Color codes
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"

# Function to execute commands based on the verbosity flag
run_command() {
    if $VERBOSE; then
        echo -e "${BLUE}[EXECUTE] $*${RESET}"
    fi
    eval "$*"
}

# Function to print messages with colors if verbosity is enabled
verbose_echo() {
    if $VERBOSE; then
        echo -e "$1"
    fi
}

# Start script
echo -e "${GREEN}=== Updating Semaphore ===${RESET}"

# Change to /opt directory
cd /opt || { echo -e "${RED}Failed to change directory to /opt.${RESET}"; exit 1; }

# Fetch the latest releases from the specified GitHub repository
verbose_echo "${YELLOW}Fetching latest releases...${RESET}"
RELEASE_INFO=$(curl -s https://api.github.com/repos/semaphoreui/semaphore/releases)

# Extract the latest release tag and the download URL for amd64.deb
RELEASE=$(echo "$RELEASE_INFO" | grep -m 1 '"tag_name"' | awk '{print substr($2, 2, length($2)-3)}')
DOWNLOAD_URL=$(echo "$RELEASE_INFO" | grep -o "https://github.com/semaphoreui/semaphore/releases/download/${RELEASE}/semaphore_[^ ]*amd64.deb" | head -n 1)

# Check if the release tag and download URL were successfully fetched
if [ -z "$RELEASE" ] || [ -z "$DOWNLOAD_URL" ]; then
    echo -e "${RED}Failed to fetch the latest amd64.deb release.${RESET}"
    exit 1
fi

# Get the currently running version and strip any 'v' prefix
CURRENT_VERSION=$(dpkg -s semaphore | grep 'Version:' | awk '{print $2}')
CURRENT_VERSION=${CURRENT_VERSION#v}  # Strip 'v' if it exists
verbose_echo "${GREEN}Current version is: $CURRENT_VERSION${RESET}"
verbose_echo "${GREEN}Latest release is: $RELEASE${RESET}"

# Strip 'v' from the latest release for comparison
LATEST_VERSION=${RELEASE#v}  # Ensure the latest version is without 'v'

# Check if a new version is available
if [ "$CURRENT_VERSION" == "$LATEST_VERSION" ]; then
    echo -e "${YELLOW}You are already running the latest version. Aborting update.${RESET}"
    exit 0
else
    read -p "$(echo -e "${YELLOW}A new version is available. Do you want to proceed with the update? (y/n): ${RESET}")" confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Update aborted by user.${RESET}"
        exit 0
    fi
fi

# Stop the Semaphore service
verbose_echo "${YELLOW}Stopping Semaphore service...${RESET}"
run_command "systemctl stop semaphore"

# Download the latest amd64.deb package
verbose_echo "${YELLOW}Downloading $DOWNLOAD_URL...${RESET}"
run_command "curl -LO \"$DOWNLOAD_URL\""

# Download the latest amd64.deb package
verbose_echo "${YELLOW}Downloading $DOWNLOAD_URL...${RESET}"
run_command "curl -LO \"$DOWNLOAD_URL\""

# Print the downloaded file name
echo -e "${GREEN}Downloaded file: semaphore_${RELEASE}_linux_amd64.deb${RESET}"

# Install the downloaded package
verbose_echo "${YELLOW}Installing the package...${RESET}"
run_command "dpkg -i \"semaphore_${RELEASE}_linux_amd64.deb\""

# Start the Semaphore service
verbose_echo "${YELLOW}Starting Semaphore service...${RESET}"
run_command "systemctl start semaphore"

echo -e "${GREEN}=== Update complete! ===${RESET}"
