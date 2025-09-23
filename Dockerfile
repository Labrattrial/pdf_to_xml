# Use Ubuntu base image with Java support for Audiveris
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies including Java 21+ for Audiveris 5.7+
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    openjdk-21-jdk \
    wget \
    unzip \
    tesseract-ocr \
    tesseract-ocr-eng \
    ghostscript \
    git \
    gradle \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME for Java 21
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64

# Create app directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Build Audiveris from source (more reliable than downloading .deb files)
WORKDIR /tmp
RUN git clone https://github.com/Audiveris/audiveris.git \
    && cd audiveris \
    && git checkout 5.7.1 \
    && gradle wrapper \
    && ./gradlew clean build \
    && tar -xf build/distributions/Audiveris-*.tar \
    && mkdir -p /opt/audiveris \
    && cp -r Audiveris-*/bin /opt/audiveris/ \
    && cp -r Audiveris-*/lib /opt/audiveris/ \
    && chmod +x /opt/audiveris/bin/Audiveris \
    && cd / \
    && rm -rf /tmp/audiveris

# Set Audiveris path - built from source
ENV AUDIVERIS_PATH=/opt/audiveris/bin/Audiveris

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