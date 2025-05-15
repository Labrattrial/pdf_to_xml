FROM ghcr.io/nirmata-1/audiforge:latest

# Create directories for uploads and downloads
RUN mkdir -p /tmp/uploads /tmp/downloads

# Set permissions
RUN chmod -R 777 /tmp/uploads /tmp/downloads

# Expose the port
EXPOSE 8080

# The container will use the default command from the base image 