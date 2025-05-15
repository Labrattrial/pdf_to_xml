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

# Create necessary directories
mkdir -p uploads musicxml

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

# Build the entire project
echo "Building all modules..."
./gradlew clean build -x test

echo "Copying Audiveris jar..."
# List all jar files in the build directory for debugging
echo "Searching for jar files in build directory..."
find . -name "*.jar" -type f

# Look for the main application jar file
JAR_FILE=$(find . -path "*/app/build/libs/audiveris-*.jar" -type f | head -n 1)
if [ -z "$JAR_FILE" ]; then
    echo "Error: Could not find main Audiveris jar file"
    echo "Current directory: $(pwd)"
    echo "Directory contents:"
    ls -R
    exit 1
fi
echo "Found jar file: $JAR_FILE"
cp "$JAR_FILE" ../audiveris.jar
cd ..

# Set proper permissions
chmod +x audiveris.jar
chmod -R 755 uploads musicxml

echo "Cleaning up..."
rm -rf audiveris.zip audiveris-5.6.0-bis

# Install Python dependencies
echo "Installing Python dependencies..."
pip install -r requirements.txt

echo "Build completed successfully!" 