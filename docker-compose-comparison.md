# Docker Compose Configurations Comparison

This document explains the key differences between the two Docker Compose configurations used in this project:

## docker-compose.local.yml (Local Development)

Key characteristics:
- **Build vs Image**: Uses `build` to build the web service from your local source code, rather than pulling a pre-built image
- **Standard Labels**: Places labels directly under the service (standard Docker Compose approach)
- **Local Domains**: Uses `localhost` as the host
- **Different Ports**: Maps to ports 8000 and 8081 to avoid conflicts with other local services
- **Local Config**: Loads Traefik config from a local file (`./config/traefik.local.yml`)
- **No Watchtower**: Doesn't include Watchtower for auto-updates (not needed in development)
- **No Deploy Section**: Doesn't use the Swarm-specific `deploy` section
- **Local Volume Paths**: Uses relative paths (`./config/traefik.local.yml`) for easier local development

## docker-compose.yml (Production/Swarm)

Key characteristics:
- **Pre-built Images**: Uses pre-built images (`kiri23/express:prod`) that you push to Docker Hub
- **Swarm Features**: Uses the `deploy` section with replicas and restart policies
- **Swarm Labels**: Places labels under the `deploy` section for Traefik in Swarm mode
- **Production Domain**: Uses your actual domain (`kiri231.com`)
- **Standard Ports**: Uses standard ports (80, 443, 8080)
- **Server Config**: Loads Traefik config from the server (`/home/kiri/traefik.yml`)
- **Includes Watchtower**: Includes Watchtower for automatic updates
- **Absolute Paths**: Uses absolute paths on the server for configuration files

## Usage Commands

### Local Development
```bash
# Build and start the containers
docker compose -f docker-compose.local.yml up --build -d

# Check the status of the containers
docker ps

# Stop the containers
docker compose -f docker-compose.local.yml down
```

### Production Deployment
```bash
# Switch to remote Docker context
docker context use hostinger

# Deploy the stack
docker stack deploy -c docker-compose.yml myapp

# Verify deployment
docker service ls
```

## File Structure
- `docker-compose.yml`: Production configuration for Docker Swarm
- `docker-compose.local.yml`: Local development configuration
- `config/traefik.yml`: Traefik configuration for production (copied to VPS)
- `config/traefik.local.yml`: Traefik configuration for local development
