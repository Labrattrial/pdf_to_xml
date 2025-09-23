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
    unzip \
    tesseract-ocr \
    tesseract-ocr-eng \
    ghostscript \
    git \
    gradle \
    software-properties-common \
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

# Download and install pre-built Audiveris binary distribution
WORKDIR /tmp
RUN wget -O audiveris.tar https://github.com/Audiveris/audiveris/releases/download/5.7.1/Audiveris-5.7.1.tar \
    && tar -xf audiveris.tar \
    && mkdir -p /opt/audiveris \
    && cp -r Audiveris-5.7.1/* /opt/audiveris/ \
    && chmod +x /opt/audiveris/bin/Audiveris \
    && rm -rf /tmp/*

# Set Audiveris path - pre-built binary
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