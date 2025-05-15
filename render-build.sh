#!/bin/bash
set -e

echo "Starting build process..."

# Download Audiveris (latest release)
AUDIVERIS_VERSION=5.6.0-bis
AUDIVERIS_URL="https://github.com/Audiveris/audiveris/archive/refs/tags/5.6.0-bis.zip"

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
cp audiveris-5.6.0-bis/app/build/libs/audiveris-5.6.0-bis.jar audiveris.jar

echo "Cleaning up..."
rm -rf audiveris.zip audiveris-5.6.0-bis

echo "Build completed successfully!" 