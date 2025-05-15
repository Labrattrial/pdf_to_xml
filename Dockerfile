FROM python:3.9-slim

# Install Java and other dependencies
RUN apt-get update && apt-get install -y \
    default-jre \
    wget \
    libasound2 \
    libatk1.0-0 \
    libc6 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libexpat1 \
    libfontconfig1 \
    libfreetype6 \
    libgcc1 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libstdc++6 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    libxtst6 \
    libnss3 \
    && rm -rf /var/lib/apt/lists/*

# Download and install Audiveris
RUN wget https://github.com/Audiveris/audiveris/releases/download/5.6.0-bis/Audiveris-5.6.0-ubuntu22.04-x86_64.deb \
    && apt-get update \
    && apt-get install -y ./Audiveris-5.6.0-ubuntu22.04-x86_64.deb \
    && rm Audiveris-5.6.0-ubuntu22.04-x86_64.deb \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /tmp/uploads /tmp/downloads

# Set permissions
RUN chmod -R 777 /tmp/uploads /tmp/downloads

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Expose the port
EXPOSE 8080

# Start the application
CMD ["python", "app.py"] 