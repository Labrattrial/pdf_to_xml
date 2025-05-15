#!/bin/bash

# Create necessary directories
mkdir -p uploads downloads

# Start the service using docker-compose
docker-compose up -d

echo "Audiforge is starting up..."
echo "The service will be available at http://localhost:8080"
echo "Uploads directory: ./uploads"
echo "Downloads directory: ./downloads" 