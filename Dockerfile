# Use Ubuntu base image with Java support for Audiveris
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies including Java 21 for Audiveris compatibility
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
    libleptonica-dev \
    libtesseract-dev \
    libx11-6 \
    libxext6 \
    libxrender1 \
    libfreetype6 \
    fontconfig \
    fonts-dejavu-core \
    xvfb \
    liblcms2-2 \
    libpng16-16 \
    libjpeg8 \
    libtiff5 \
    libwebp6 \
    libopenjp2-7 \
    && rm -rf /var/lib/apt/lists/*

# Install Java 21 (compatible with Gradle 8.7 and Audiveris)
RUN wget -O- https://apt.corretto.aws/corretto.key | apt-key add - \
    && add-apt-repository 'deb https://apt.corretto.aws stable main' \
    && apt-get update \
    && apt-get install -y java-21-amazon-corretto-jdk \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME for Java 21
ENV JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto

# Create app directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy local Audiveris installation into container
WORKDIR /app

# Create audiveris directory in container
RUN mkdir -p /opt/audiveris

# Copy the entire Audiveris installation from your local machine
COPY audiveris_local/ /opt/audiveris/

# Use the pre-built JAR files from your local installation
RUN echo "Using pre-built Audiveris JAR files..." && \
    find /opt/audiveris -name "*.jar" -type f | head -10 && \
    echo "Setting up Audiveris wrapper..." && \
    echo "Setting up native library path for Leptonica..." && \
    find /opt/audiveris -name "*leptonica*" -type f && \
    find /opt/audiveris -name "*tesseract*" -type f

# Make sure the Audiveris executable is executable
RUN find /opt/audiveris -name "Audiveris" -type f -exec chmod +x {} \; || \
    find /opt/audiveris -name "audiveris" -type f -exec chmod +x {} \; || \
    find /opt/audiveris -name "*.jar" -type f -exec echo "Found JAR: {}" \;

# Create a proper wrapper script to run Audiveris using the pre-built JAR
RUN if [ -f /opt/audiveris/audiveris/bin/Audiveris ]; then \
        echo "Using built Audiveris executable" && \
        ln -s /opt/audiveris/audiveris/bin/Audiveris /usr/local/bin/audiveris; \
    elif [ -f /opt/audiveris/audiveris/app/build/distributions/app-*/bin/Audiveris ]; then \
        echo "Using distribution Audiveris executable" && \
        find /opt/audiveris -name "Audiveris" -path "*/bin/*" -exec ln -s {} /usr/local/bin/audiveris \;; \
    else \
        echo "Creating JAR wrapper for pre-built Audiveris" && \
        echo '#!/bin/bash' > /usr/local/bin/audiveris && \
        echo 'export DISPLAY=:99' >> /usr/local/bin/audiveris && \
        echo 'export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"' >> /usr/local/bin/audiveris && \
        echo 'Xvfb :99 -screen 0 1024x768x24 > /dev/null 2>&1 &' >> /usr/local/bin/audiveris && \
        echo 'sleep 2' >> /usr/local/bin/audiveris && \
        echo 'AUDIVERIS_JAR=$(find /opt/audiveris -name "audiveris.jar" -type f | head -1)' >> /usr/local/bin/audiveris && \
        echo 'if [ -z "$AUDIVERIS_JAR" ]; then' >> /usr/local/bin/audiveris && \
        echo '  echo "Error: Could not find audiveris.jar"' >> /usr/local/bin/audiveris && \
        echo '  echo "Available JAR files:"' >> /usr/local/bin/audiveris && \
        echo '  find /opt/audiveris -name "*.jar" | head -10' >> /usr/local/bin/audiveris && \
        echo '  exit 1' >> /usr/local/bin/audiveris && \
        echo 'fi' >> /usr/local/bin/audiveris && \
        echo 'AUDIVERIS_LIB_DIR=$(dirname "$AUDIVERIS_JAR")' >> /usr/local/bin/audiveris && \
        echo 'CLASSPATH="$AUDIVERIS_JAR:$AUDIVERIS_LIB_DIR/*"' >> /usr/local/bin/audiveris && \
        echo '# Extract native libraries from JAR files' >> /usr/local/bin/audiveris && \
        echo 'NATIVE_LIB_DIR="/tmp/audiveris-native-$$"' >> /usr/local/bin/audiveris && \
        echo 'mkdir -p "$NATIVE_LIB_DIR"' >> /usr/local/bin/audiveris && \
        echo 'for jar in "$AUDIVERIS_LIB_DIR"/*leptonica*.jar "$AUDIVERIS_LIB_DIR"/*tesseract*.jar "$AUDIVERIS_LIB_DIR"/*javacpp*.jar; do' >> /usr/local/bin/audiveris && \
        echo '  if [ -f "$jar" ]; then' >> /usr/local/bin/audiveris && \
        echo '    unzip -j "$jar" "*.so*" -d "$NATIVE_LIB_DIR" 2>/dev/null || true' >> /usr/local/bin/audiveris && \
        echo '    unzip -j "$jar" "linux-x86_64/*.so*" -d "$NATIVE_LIB_DIR" 2>/dev/null || true' >> /usr/local/bin/audiveris && \
        echo '  fi' >> /usr/local/bin/audiveris && \
        echo 'done' >> /usr/local/bin/audiveris && \
        echo 'chmod +x "$NATIVE_LIB_DIR"/*.so* 2>/dev/null || true' >> /usr/local/bin/audiveris && \
        echo 'export LD_LIBRARY_PATH="$NATIVE_LIB_DIR:/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"' >> /usr/local/bin/audiveris && \
        echo 'java -Djava.awt.headless=false -Djava.library.path="$NATIVE_LIB_DIR:/usr/lib/x86_64-linux-gnu:/usr/lib:/lib" -cp "$CLASSPATH" Audiveris "$@"' >> /usr/local/bin/audiveris && \
        echo 'rm -rf "$NATIVE_LIB_DIR"' >> /usr/local/bin/audiveris && \
        chmod +x /usr/local/bin/audiveris; \
    fi

# Set Audiveris path environment variable
ENV AUDIVERIS_PATH=/usr/local/bin/audiveris

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