#!/bin/bash
set -e

echo "Starting build process..."

# Install Java using sdkman
echo "Installing Java using sdkman..."
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install java 21.0.3-tem

# Set JAVA_HOME
export JAVA_HOME="$HOME/.sdkman/candidates/java/current"
export PATH=$JAVA_HOME/bin:$PATH

# Verify Java installation
echo "Using Java version:"
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
# Find the jar file in the build directory
JAR_FILE=$(find . -name "audiveris-*.jar" -type f)
if [ -z "$JAR_FILE" ]; then
    echo "Error: Could not find Audiveris jar file"
    exit 1
fi
echo "Found jar file: $JAR_FILE"
cp "$JAR_FILE" ../audiveris.jar
cd ..

echo "Cleaning up..."
rm -rf audiveris.zip audiveris-5.6.0-bis

echo "Build completed successfully!" 