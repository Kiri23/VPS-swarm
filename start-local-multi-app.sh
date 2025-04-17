#!/bin/bash

# Create the shared network if it doesn't exist
if ! docker network ls | grep -q traefik-local; then
  echo "Creating traefik-local network..."
  docker network create traefik-local
else
  echo "traefik-local network already exists."
fi

# Start the main application with Traefik
echo "Starting main application with Traefik..."
docker compose -f docker-compose.local.yml up --build -d

# Start the second application
echo "Starting second application..."
cd app2 && docker compose -f docker-compose.local.yml up --build -d

echo ""
echo "Multi-app setup is running!"
echo "You can access:"
echo "- App 1: http://app1.localhost:8000"
echo "- App 2: http://app2.localhost:8000"
echo "- Traefik Dashboard: http://localhost:8081/dashboard/"
echo ""
echo "Note: Make sure you have added the following to your /etc/hosts file:"
echo "127.0.0.1 app1.localhost app2.localhost"
