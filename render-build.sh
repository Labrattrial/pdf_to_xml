#!/bin/bash
set -e

# Download Audiveris (latest release)
AUDIVERIS_VERSION=5.3.3
AUDIVERIS_URL="https://github.com/Audiveris/audiveris/releases/download/${AUDIVERIS_VERSION}/audiveris-${AUDIVERIS_VERSION}.zip"

curl -L -o audiveris.zip "$AUDIVERIS_URL"
unzip audiveris.zip
cp audiveris-${AUDIVERIS_VERSION}/bin/audiveris.jar audiveris.jar
rm -rf audiveris.zip audiveris-${AUDIVERIS_VERSION} 