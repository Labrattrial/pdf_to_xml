#!/bin/bash
set -e

echo "Starting build process..."

# Install Java
echo "Installing Java..."
apt-get update
apt-get install -y default-jdk

# Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/default-java
export PATH=$JAVA_HOME/bin:$PATH

# Verify Java installation
java -version

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

echo "Building Audiveris..."
cd audiveris-5.6.0-bis
chmod +x gradlew
./gradlew build -x test

echo "Copying Audiveris jar..."
cp app/build/libs/audiveris-5.6.0-bis.jar ../audiveris.jar
cd ..

echo "Cleaning up..."
rm -rf audiveris.zip audiveris-5.6.0-bis

echo "Build completed successfully!" 