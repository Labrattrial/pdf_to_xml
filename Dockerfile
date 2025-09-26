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

# Copy local Audiveris installation into container
WORKDIR /app

# Create audiveris directory in container
RUN mkdir -p /opt/audiveris

# Copy the entire Audiveris installation from your local machine
# You'll need to copy your D:\Audiveris folder to ./audiveris_local/ first
COPY audiveris_local/ /opt/audiveris/

# Make sure the Audiveris executable is executable
RUN find /opt/audiveris -name "Audiveris" -type f -exec chmod +x {} \; || \
    find /opt/audiveris -name "audiveris" -type f -exec chmod +x {} \; || \
    find /opt/audiveris -name "*.jar" -type f -exec echo "Found JAR: {}" \;

# Create a wrapper script to run Audiveris
RUN if [ -f /opt/audiveris/bin/Audiveris ]; then \
        echo "Using native Audiveris executable" && \
        ln -s /opt/audiveris/bin/Audiveris /usr/local/bin/audiveris; \
    elif [ -f /opt/audiveris/app/build/distributions/app-*/bin/Audiveris ]; then \
        echo "Using built Audiveris executable" && \
        find /opt/audiveris -name "Audiveris" -path "*/bin/*" -exec ln -s {} /usr/local/bin/audiveris \;; \
    else \
        echo "Creating JAR wrapper" && \
        echo '#!/bin/bash' > /usr/local/bin/audiveris && \
        echo 'java -jar $(find /opt/audiveris -name "*.jar" | head -1) "$@"' >> /usr/local/bin/audiveris && \
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