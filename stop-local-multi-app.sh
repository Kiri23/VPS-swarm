#!/bin/bash

# Stop the second application
echo "Stopping second application..."
cd app2 && docker compose -f docker-compose.local.yml down

# Stop the main application with Traefik
echo "Stopping main application with Traefik..."
cd .. && docker compose -f docker-compose.local.yml down

echo ""
echo "All applications have been stopped."
echo ""
echo "To remove the traefik-local network, run:"
echo "docker network rm traefik-local"
