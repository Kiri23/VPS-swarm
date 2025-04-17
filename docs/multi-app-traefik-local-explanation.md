# Multi-App Traefik Local Setup: Detailed Explanation

## Key Components

### 1. Docker Network (`traefik-local`)

The shared network is the foundation of this setup. It allows all containers to communicate with each other, similar to how an overlay network works in Docker Swarm, but without requiring Swarm mode.

```bash
# How the network is created
docker network create traefik-local
```

In each docker-compose file, we connect to this network:

```yaml
networks:
  traefik-local:
    external: true
```

### 2. Traefik Configuration

The Traefik configuration (`config/traefik.local.yml`) is set up to:

1. **Use the Docker provider**: This allows Traefik to discover services running in Docker
2. **Watch for changes**: Traefik automatically detects when containers are added or removed
3. **Use the specified network**: The `network: traefik-local` setting tells Traefik to look for containers on this network

```yaml
providers:
  docker:
    exposedByDefault: false
    watch: true
    network: traefik-local
```

### 3. Application Labels

Each application uses labels to tell Traefik how to route traffic:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.app1.rule=Host(`app1.localhost`)"
  - "traefik.http.services.app1-service.loadbalancer.server.port=3000"
```

These labels define:
- That Traefik should route to this container (`traefik.enable=true`)
- The domain that should route to this container (`Host(`app1.localhost`)`)
- The internal port the application is listening on (`server.port=3000`)

### 4. Local Domain Resolution

For local development, we use `.localhost` domains which are automatically resolved by most browsers. For better isolation, we use:
- `app1.localhost` for the first application
- `app2.localhost` for the second application

If your browser doesn't automatically resolve these domains, you can add them to your `/etc/hosts` file:

```
127.0.0.1 app1.localhost app2.localhost
```

## How Requests Are Processed

When you enter `http://app1.localhost:8000` in your browser:

1. The browser resolves `app1.localhost` to `127.0.0.1` (your local machine)
2. The request goes to port 8000, which is mapped to Traefik's port 80
3. Traefik receives the request and checks the `Host` header
4. Traefik matches the `Host` header (`app1.localhost`) to the router rule for App 1
5. Traefik forwards the request to App 1 on port 3000
6. App 1 processes the request and sends a response
7. Traefik forwards the response back to your browser

The same process happens for `http://app2.localhost:8000`, but Traefik routes to App 2 instead.

## Differences from Docker Swarm Setup

This local setup achieves the same result as a Docker Swarm setup, but with some key differences:

| Feature | Local Setup | Docker Swarm Setup |
|---------|------------|-------------------|
| Network Type | Standard Docker network | Overlay network |
| Provider | Docker provider | Swarm provider |
| Label Placement | Directly under service | Under deploy section |
| Service Discovery | Via Docker API | Via Swarm API |
| Scaling | Manual | Via Swarm replicas |

## Adding More Applications

To add more applications to this setup:

1. Create a new directory for your application
2. Create a `docker-compose.local.yml` file that:
   - Connects to the `traefik-local` network
   - Uses appropriate Traefik labels with a unique domain (e.g., `app3.localhost`)
3. Start the application with `docker compose -f docker-compose.local.yml up -d`

Traefik will automatically discover the new application and start routing traffic to it.

## Troubleshooting

If you encounter issues:

1. **Check network connectivity**: Make sure all containers are connected to the `traefik-local` network
2. **Verify Traefik labels**: Ensure each application has the correct labels
3. **Check Traefik logs**: Look at the Traefik dashboard or logs for routing issues
4. **Test domain resolution**: Make sure your browser can resolve the `.localhost` domains
