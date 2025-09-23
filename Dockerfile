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
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME for Java 21
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64

# Create app directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Download and install the latest Audiveris (5.7.1) with proper Linux installer
RUN wget -O audiveris.deb https://github.com/Audiveris/audiveris/releases/download/5.7.1/Audiveris-5.7.1-linux-x64.deb \
    && dpkg -i audiveris.deb || apt-get install -f -y \
    && rm audiveris.deb

# Set Audiveris path - the .deb installer puts it in /opt/audiveris/bin/
ENV AUDIVERIS_PATH=/opt/audiveris/bin/audiveris

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p uploads outputs

# Expose port
EXPOSE 5000

# Run the application with gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]