#!/bin/bash
set -e

echo "Starting build process..."

# Download Audiveris (latest release)
AUDIVERIS_VERSION=5.3.3
AUDIVERIS_URL="https://github.com/Audiveris/audiveris/releases/download/${AUDIVERIS_VERSION}/audiveris-${AUDIVERIS_VERSION}.zip"

echo "Downloading Audiveris version ${AUDIVERIS_VERSION}..."
curl -L -o audiveris.zip "$AUDIVERIS_URL"

echo "Extracting Audiveris..."
unzip audiveris.zip

echo "Copying Audiveris jar..."
cp audiveris-${AUDIVERIS_VERSION}/bin/audiveris.jar audiveris.jar

echo "Cleaning up..."
rm -rf audiveris.zip audiveris-${AUDIVERIS_VERSION}

echo "Build completed successfully!" 