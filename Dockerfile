FROM python:3.9-slim

# Install Java and build dependencies
RUN apt-get update && apt-get install -y \
    default-jre \
    default-jdk \
    wget \
    unzip \
    git \
    maven \
    && rm -rf /var/lib/apt/lists/*

# Clone and build Audiveris
RUN git clone https://github.com/Audiveris/audiveris.git \
    && cd audiveris \
    && git checkout 5.6.0-bis \
    && cd app \
    && mvn clean install -DskipTests \
    && cp target/audiveris-*.jar /usr/local/bin/audiveris.jar \
    && cd ../.. \
    && rm -rf audiveris

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