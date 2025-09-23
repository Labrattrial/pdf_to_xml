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

# Download and install Audiveris from MediaFire
WORKDIR /tmp
RUN wget -O audiveris.deb "https://download1588.mediafire.com/06s7w9ref4ugPDFfGxS4PpHaFMb7wPk4A162408vutNoP-e-u5mmUhAApR558aRCXID8UeVbnLHV1yK7l0SPj7Hd-nYiMN_vPye7VvG7i2YfHdL9gbayVCYPLvlRYwfYp6nL-h0yokz2f-Is0JMAhalCULlTo9dFt43-rZYOcUurLo8/vwgzvsxi0lyqw6i/Audiveris-5.7.1-ubuntu22.04-x86_64.deb" \
    && dpkg -i audiveris.deb || true \
    && rm audiveris.deb \
    && find /usr -name "audiveris*" -type f -executable 2>/dev/null || echo "Audiveris not found in /usr" \
    && find /opt -name "audiveris*" -type f -executable 2>/dev/null || echo "Audiveris not found in /opt" \
    && ls -la /usr/bin/ | grep -i audiveris || echo "No audiveris in /usr/bin" \
    && ls -la /opt/ 2>/dev/null || echo "No /opt directory"

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