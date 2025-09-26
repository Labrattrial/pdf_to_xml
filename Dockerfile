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
    && rm -rf /var/lib/apt/lists/*

# Install Java 21 (compatible with Audiveris)
RUN wget -O- https://apt.corretto.aws/corretto.key | apt-key add - \
    && add-apt-repository 'deb https://apt.corretto.aws stable main' \
    && apt-get update \
    && apt-get install -y java-21-amazon-corretto-jdk \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME for Java 21
ENV JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto

# Create app directory
WORKDIR /app

# Copy the Audiveris DEB file
COPY Audiveris-5.7.1.deb /tmp/Audiveris-5.7.1.deb

# Install Audiveris from DEB package
RUN dpkg -i /tmp/Audiveris-5.7.1.deb || true \
    && apt-get update \
    && apt-get install -f -y \
    && rm /tmp/Audiveris-5.7.1.deb

# Set Audiveris path environment variable
ENV AUDIVERIS_PATH=/opt/audiveris/bin/Audiveris

# Install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy application files
COPY . .

# Create directories for uploads and outputs
RUN mkdir -p uploads outputs

# Expose port
EXPOSE 5000

# Run the application
CMD ["python3", "app.py"]