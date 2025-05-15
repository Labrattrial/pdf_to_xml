FROM python:3.9-slim

# Install Java and other dependencies
RUN apt-get update && apt-get install -y \
    default-jre \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Download and install Audiveris
RUN wget https://github.com/Audiveris/audiveris/releases/download/5.6.0-bis/audiveris-5.6.0-bis.zip \
    && unzip audiveris-5.6.0-bis.zip \
    && mv audiveris-5.6.0-bis/audiveris.jar /usr/local/bin/ \
    && rm -rf audiveris-5.6.0-bis.zip audiveris-5.6.0-bis

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