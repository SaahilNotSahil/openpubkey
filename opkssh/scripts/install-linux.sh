#!/bin/bash

set -e  # Exit if any command fails

# This script generated by chatGPT4o and then modified by hand

# Define variables
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="opkssh"
GITHUB_REPO="openpubkey/openpubkey"
PROVIDER_GOOGLE="https://accounts.google.com 411517154569-7f10v0ftgp5elms1q8fm7avtp33t7i7n.apps.googleusercontent.com 24h"
PROVIDER_MICROSOFT="https://login.microsoftonline.com/9188040d-6c67-4c5b-b112-36a304b66dad/v2.0 096ce0a3-5e72-4da8-9c86-12924b294a01 24h"
PROVIDER_GITLAB="https://gitlab.com 8d8b7024572c7fd501f64374dec6bba37096783dfcd792b3988104be08cb6923 24h"

# Ensure wget is installed
if ! command -v wget &> /dev/null; then
    echo "Error: wget is not installed. Please install it first."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Please install it first."
    exit 1
fi

# Get the latest release version dynamically using wget
LATEST_VERSION=$(wget -qO- "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | jq -r .tag_name)

if [ "$LATEST_VERSION" == "null" ] || [ -z "$LATEST_VERSION" ]; then
    echo "Error: Failed to fetch the latest release version."
    exit 1
fi

BINARY_URL="https://github.com/$GITHUB_REPO/releases/download/$LATEST_VERSION/opkssh-linux-amd64"

# Download the binary
echo "Downloading $BINARY_NAME from $BINARY_URL..."
wget -q --show-progress -O "$BINARY_NAME" "$BINARY_URL"

# Make the binary executable
chmod +x "$BINARY_NAME"

# Move to installation directory
sudo mv "$BINARY_NAME" "$INSTALL_DIR/"

# Verify installation
if command -v $BINARY_NAME &> /dev/null; then
    sudo chmod +x /usr/local/bin/opkssh
    echo "Installation successful! Run '$BINARY_NAME' to use it."

    # Setup configuration
    echo "Configuring opkssh."
    sudo mkdir -p /etc/opk
    sudo touch /etc/opk/auth_id
    sudo chown root /etc/opk/auth_id
    sudo chmod 600 /etc/opk/auth_id

    sudo touch /etc/opk/providers
    sudo chown root /etc/opk/providers
    sudo chmod 600 /etc/opk/providers

    if [ -s /etc/opk/providers ]; then
        echo "The providers policy file (/etc/opk/providers) is not empty. Keeping existing values"
    else
        echo "$PROVIDER_GOOGLE" >> /etc/opk/providers
        echo "$PROVIDER_MICROSOFT" >> /etc/opk/providers
        echo "$PROVIDER_GITLAB" >> /etc/opk/providers
    fi

    sed -i '/^AuthorizedKeysCommand /s/^/#/' /etc/ssh/sshd_config
    sed -i '/^AuthorizedKeysCommandUser /s/^/#/' /etc/ssh/sshd_config
    echo "AuthorizedKeysCommand /usr/local/bin/opkssh verify %u %k %t" >> /etc/ssh/sshd_config
    echo "AuthorizedKeysCommandUser root" >> /etc/ssh/sshd_config

    sudo systemctl restart ssh

else
    echo "Installation failed."
    exit 1
fi
