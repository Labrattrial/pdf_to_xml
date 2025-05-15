#!/bin/bash
set -e

echo "Starting build process..."

# Download Audiveris (latest release)
AUDIVERIS_VERSION=5.6.0
AUDIVERIS_URL="https://github.com/Audiveris/audiveris/releases/download/v${AUDIVERIS_VERSION}/audiveris-${AUDIVERIS_VERSION}.zip"

echo "Downloading Audiveris version ${AUDIVERIS_VERSION}..."
wget -O audiveris.zip "$AUDIVERIS_URL"

# Verify the download
if [ ! -s audiveris.zip ]; then
    echo "Error: Download failed or file is empty"
    exit 1
fi

echo "Extracting Audiveris..."
unzip -o audiveris.zip

echo "Copying Audiveris jar..."
cp audiveris-${AUDIVERIS_VERSION}/bin/audiveris.jar audiveris.jar

echo "Cleaning up..."
rm -rf audiveris.zip audiveris-${AUDIVERIS_VERSION}

echo "Build completed successfully!" 