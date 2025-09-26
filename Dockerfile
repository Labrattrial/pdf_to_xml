# Use Ubuntu base image with Java support for Audiveris
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies including Java 24+ for Audiveris 5.7+
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    wget \
    curl \
    unzip \
    tesseract-ocr \
    tesseract-ocr-eng \
    ghostscript \
    git \
    gradle \
    software-properties-common \
    libxi6 \
    libxtst6 \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Java 24 (required for Audiveris 5.7.1)
RUN wget -O- https://apt.corretto.aws/corretto.key | apt-key add - \
    && add-apt-repository 'deb https://apt.corretto.aws stable main' \
    && apt-get update \
    && apt-get install -y java-24-amazon-corretto-jdk \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME for Java 24
ENV JAVA_HOME=/usr/lib/jvm/java-24-amazon-corretto

# Create app directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Download and install Audiveris from official release
WORKDIR /tmp
# Download the Windows Console MSI (contains cross-platform Java binaries)
RUN wget -O audiveris.msi "https://download1648.mediafire.com/szwayw9o7rgg0WIdqK5ZIwi2sfIMr7Cmk_uU8quf5hdQgBO0Hq2OOp7IhuIVwfVbQVCGgB3p8irKPSw-adl-IbtUTP0h6bIdLom_ZRhp8BCPWinv-5qnqAuymbUvsiK8cnCw3yQuz2Xvz_CCs4Fs1itAo0M9Mosql0zg9y64/5euy8etgfb8a9rq/Audiveris-5.7.1-windowsConsole-x86_64.msi" \
    && echo "=== Installing msitools to extract MSI ===" \
    && apt-get update && apt-get install -y msitools \
    && echo "=== Extracting Audiveris from MSI ===" \
    && msiextract audiveris.msi \
    && echo "=== Finding extracted Audiveris files ===" \
    && find . -name "*audiveris*" -type f 2>/dev/null | head -20 \
    && echo "=== Looking for executable files ===" \
    && find . -name "*.jar" -o -name "*.bat" -o -name "audiveris*" 2>/dev/null \
    && echo "=== Moving Audiveris to /opt/audiveris ===" \
    && mkdir -p /opt/audiveris \
    && cp -r . /opt/audiveris/ \
    && echo "=== Creating audiveris wrapper script ===" \
    && echo '#!/bin/bash' > /usr/bin/audiveris \
    && echo 'cd /opt/audiveris' >> /usr/bin/audiveris \
    && echo 'java -jar $(find /opt/audiveris -name "*.jar" | head -1) "$@"' >> /usr/bin/audiveris \
    && chmod +x /usr/bin/audiveris \
    && echo "=== Testing audiveris command ===" \
    && which audiveris \
    && ls -la /usr/bin/audiveris \
    && rm -rf /tmp/*

# Set Audiveris path - check common locations and use the correct one
ENV AUDIVERIS_PATH=/usr/bin/audiveris

# Go back to app directory
WORKDIR /app

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p uploads outputs

# Expose port
EXPOSE 5000

# Run the application with gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]