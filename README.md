# Docker Stack Example

## Building and Deploying

### 1. Build and Push the Image

First, set up multi-platform build support:

```bash
# Create and configure buildx builder
docker buildx create --name mybuilder --use
docker buildx inspect --bootstrap
```

Build and push the multi-platform image:

```bash
# Build and push for both ARM and AMD platforms
docker buildx build --platform linux/amd64,linux/arm64 -t kiri23/express:prod --push .
```

Alternative simpler command without buildx:

```bash
# Build only for AMD64 (VPS)
docker build --platform linux/amd64 -t kiri23/express:prod .
docker push kiri23/express:prod
```

### 2. Deploy to Server

To deploy the app in your host machine run:

```bash
docker context use hostinger
docker stack deploy -c docker-compose.yml myapp
```

### 3. Update the Application

When you make changes to the code:

1. Build and push a new version (choose appropriate build command from above)
2. Watchtower will automatically detect and deploy the new version within 5
   minutes.

## Debugging Guide

### Understanding Service Names

- Services in Docker Swarm follow the naming convention:
  `<stack_name>_<service_name>`
- Example: `myapp_web`, `myapp_watchtower`

### Common Debugging Commands

#### 1. Check Service Status

```bash
# List all services and their status
docker service ls

# Get detailed info about a specific service
docker service ps myapp_web
```

- `service ps` shows:
  - Current and previous container instances
  - Image versions
  - Node placement
  - Container states
  - Error messages if any

#### 2. Check Service Logs

```bash
# View all logs
docker service logs myapp_web

# View recent logs (last 2 minutes)
docker service logs --since 2m myapp_web

# Follow logs in real-time
docker service logs -f myapp_web
```

#### 3. Debugging Watchtower

```bash
# View Watchtower logs
docker service logs myapp_watchtower
```

Understanding Watchtower logs:

- `Scanned=0`: Watchtower isn't finding containers to monitor
  - Check if containers have the label
    `com.centurylinklabs.watchtower.enable=true`
- `Scanned=1, Updated=0`: Found container but no updates needed
- `Scanned=1, Updated=1`: Successfully updated a container

Common Watchtower Warnings:

```
"Could not do a head request... falling back to regular pull"
"Parsed container image ref has no tag"
```

These warnings are normal and indicate:

- Watchtower is using an alternative method to check for updates
- The container is using a SHA-based image reference (secure and normal)
- Not an error if you see `Scanned=X Updated=0` in the same log

Troubleshooting No Updates:

1. Verify the image was pushed:

```bash
# Check if image exists in registry
docker pull kiri23/express:prod
```

2. Compare image digests:

```bash
# Get current running image digest
docker service ps myapp_web --format "{{.Image}}"

# Get latest image digest
docker image inspect kiri23/express:prod -f "{{.Id}}"
```

3. Force pull latest image:

```bash
# Force pull new image
docker pull kiri23/express:prod

# Force service update
docker service update --force myapp_web
```

#### 4. Force Update Service

If Watchtower isn't updating automatically:

```bash
docker service update --force myapp_web
```

### Common Issues and Solutions

1. Architecture Mismatch

```
WARNING: The requested image's platform (linux/arm64) does not match the detected host platform (linux/amd64)
```

Solution: Build specifically for AMD64 (VPS architecture)

2. Watchtower Not Updating

- Verify labels in docker-compose.yml
- Check Watchtower logs for scanning status
- Verify image was pushed correctly to registry

3. Container Startup Issues

- Use `docker service ps` to check for error messages
- Use `docker service logs` to view application logs
- Check for platform compatibility issues

### Notes

- Your VPS uses AMD64 architecture
- Your local M2 Mac uses ARM64 architecture
- Always check service logs when debugging
- Use `--force` update when immediate service refresh is needed
- The stack includes Traefik for SSL/TLS and reverse proxy
