# Multi-App Traefik Local Architecture

```
                                                 ┌─────────────────────┐
                                                 │                     │
                                                 │    Host Machine     │
                                                 │                     │
                                                 └─────────────────────┘
                                                           │
                                                           │
                                                           ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                     │
│                              Docker Environment                                     │
│                                                                                     │
│   ┌─────────────────────┐          ┌─────────────────────┐                         │
│   │                     │          │                     │                         │
│   │  Browser Request    │          │   /etc/hosts file   │                         │
│   │                     │          │                     │                         │
│   └─────────────────────┘          └─────────────────────┘                         │
│             │                                 │                                     │
│             │                                 │                                     │
│             ▼                                 ▼                                     │
│   ┌─────────────────────┐          ┌─────────────────────┐                         │
│   │                     │          │  Domain Resolution  │                         │
│   │ app1.localhost:8000 │◄─────────┤  127.0.0.1 app1.localhost │                   │
│   │ app2.localhost:8000 │◄─────────┤  127.0.0.1 app2.localhost │                   │
│   │                     │          │                     │                         │
│   └─────────────────────┘          └─────────────────────┘                         │
│             │                                                                      │
│             │                                                                      │
│             ▼                                                                      │
│   ┌─────────────────────────────────────────────────────────────────┐             │
│   │                                                                 │             │
│   │                      Traefik (reverse-proxy)                    │             │
│   │                      Port 8000 (HTTP) & 8081 (Dashboard)        │             │
│   │                                                                 │             │
│   └─────────────────────────────────────────────────────────────────┘             │
│             │                                 │                                     │
│             │                                 │                                     │
│             │                                 │                                     │
│             │                                 │                                     │
│             │                                 │                                     │
│             ▼                                 ▼                                     │
│   ┌─────────────────────┐          ┌─────────────────────┐                         │
│   │                     │          │                     │                         │
│   │      App 1          │          │      App 2          │                         │
│   │   (Express.js)      │          │   (Express.js)      │                         │
│   │   Port 3000         │          │   Port 3000         │                         │
│   │                     │          │                     │                         │
│   └─────────────────────┘          └─────────────────────┘                         │
│                                                                                     │
│                                                                                     │
│                                                                                     │
│                         traefik-local network                                       │
│                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## How It Works

1. **Shared Network**: All containers (Traefik, App1, App2) are connected to the `traefik-local` network
   - This allows them to communicate with each other
   - Traefik can discover and route to both applications

2. **Domain Resolution**: 
   - `/etc/hosts` file maps `app1.localhost` and `app2.localhost` to `127.0.0.1`
   - Browser requests to these domains are directed to your local machine

3. **Traefik Routing**:
   - Traefik receives requests on port 8000
   - Based on the `Host` header, it routes to the appropriate application:
     - `app1.localhost` → App 1
     - `app2.localhost` → App 2

4. **Labels**: Each application has Traefik labels that define:
   - The domain it responds to (`traefik.http.routers.*.rule=Host(*)`)
   - The internal port it runs on (`traefik.http.services.*-service.loadbalancer.server.port=3000`)

This setup works without Docker Swarm because:
1. We're using a standard Docker network instead of an overlay network
2. Traefik is configured to use the Docker provider instead of the Swarm provider
3. All containers are on the same Docker host (your local machine)
