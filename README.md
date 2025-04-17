# Docker Stack Example

## ¿Qué es este proyecto?

Este proyecto es un sistema de hosting personal basado en Docker Swarm y Traefik. Proporciona una infraestructura maestra que funciona como un sistema de "plug and play" para aplicaciones web.

### Características principales

- **Infraestructura flexible**: No necesita modificaciones cuando añades nuevas aplicaciones
- **Gestión automática**: Se encarga del enrutamiento, balanceo de carga y descubrimiento de servicios
- **Compatible con cualquier tecnología**: Permite añadir cualquier tipo de aplicación independientemente del lenguaje
- **Funciona local y remotamente**: Configura el mismo entorno tanto en tu máquina local como en un VPS

Esencialmente, has construido un sistema similar a lo que ofrecen servicios como Heroku o Vercel, pero completamente bajo tu control y funcionando tanto en tu máquina local como en tu VPS en Hostinger.

## Getting Started

### 1. Prepare SSH Environment

Before doing anything, ensure your SSH environment is properly configured:

```bash
# Add your SSH key to the agent (avoids passphrase prompts)
ssh-add --apple-use-keychain ~/.ssh/id_ed25519  # For macOS
# OR
ssh-add ~/.ssh/id_ed25519  # For Linux/older macOS

# Test SSH connection
ssh kiri@kiri231.com echo "SSH connection successful"
```

### 2. Make a Simple Change

Let's make a simple change to the application:

```bash
# Edit the server.js file to change the message
vi src/server.js

# Example change: Update the response message
# res.send("Hello World! Updated message: " + new Date());
```

### 3. Build and Push the Image

After making changes, build and push the Docker image:

```bash
# Build for AMD64 (VPS architecture)
docker build --platform linux/amd64 -t kiri23/express:prod .

# Push the image to Docker Hub
docker push kiri23/express:prod
```

### 4. Deploy to Server

Deploy the updated application:

```bash
# Switch to remote Docker context
docker context use hostinger

# Deploy the stack
docker stack deploy -c docker-compose.yml myapp

# Verify deployment
docker service ls

# Check logs to confirm the update
docker service logs myapp_web --tail 10
```

### 5. Verify the Deployment

Check that your application is running correctly:

```bash
# Test the application
curl -k https://kiri231.com
```

You should see your updated message.

## Advanced Build Options

For multi-platform builds (if needed):

```bash
# Set up multi-platform build support
docker buildx create --name mybuilder --use
docker buildx inspect --bootstrap

# Build and push for both ARM and AMD platforms
docker buildx build --platform linux/amd64,linux/arm64 -t kiri23/express:prod --push .
```

## Traefik Configuration

If you need to update the Traefik configuration:

```bash
# Edit the traefik.yml file locally
vi config/traefik.yml

# Copy to the server
scp config/traefik.yml kiri@kiri231.com:/home/kiri/

# Redeploy to apply changes
docker stack deploy -c docker-compose.yml myapp
```



## Common Issues and Solutions

### 1. SSH Connection Issues

If you can't connect to the server:

```bash
# Add your SSH key to the agent
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# Test SSH connection
ssh kiri@kiri231.com echo "SSH connection successful"
```

### 2. Docker Context Connection Issues

If you see this error:
```
error during connect: Get "http://docker.example.com/v1.24/info": command [ssh -l kiri -- kiri231.com docker system dial-stdio] has exited with exit status 255
```

Try these steps:
```bash
# Test direct SSH connection to Docker
ssh kiri@kiri231.com docker info

# Reset Docker context
docker context use default
docker context use hostinger
```

### 3. Architecture Mismatch

If you see this warning:
```
WARNING: The requested image's platform (linux/arm64) does not match the detected host platform (linux/amd64)
```

Make sure to build specifically for AMD64:
```bash
docker build --platform linux/amd64 -t kiri23/express:prod .
```

### 4. Application Not Updating

If your changes aren't appearing after deployment:

```bash
# Check if the image was pushed correctly
docker pull kiri23/express:prod

# Force update the service
docker service update --force myapp_web

# Check logs
docker service logs myapp_web --tail 20
```

### 5. Traefik Routing Issues

If your application is running but not accessible via the domain:

```bash
# Check Traefik logs
docker service logs myapp_reverse-proxy --tail 20

# Verify traefik.yml is in the correct location
ssh kiri@kiri231.com "ls -l /home/kiri/traefik.yml"

# If needed, copy traefik.yml again and redeploy
scp config/traefik.yml kiri@kiri231.com:/home/kiri/
docker stack deploy -c docker-compose.yml myapp
```

## Notes

- Your VPS uses AMD64 architecture
- Your local M2 Mac uses ARM64 architecture
- The stack includes:
  - Traefik for SSL/TLS and reverse proxy (configuration in `config/traefik.yml`)
  - Express web application
  - Watchtower for automatic updates

## Advanced Debugging

For more detailed debugging information, including:
- SSH and Docker Context configuration
- Troubleshooting connection issues
- Advanced service debugging

See the [DEBUGGING.md](docs/DEBUGGING.md) file.

## Local Development

### Running the Application Locally

You can run the application locally using Docker Compose:

```bash
# Build and start the containers
docker compose -f docker-compose.local.yml up --build -d

# Check the status of the containers
docker ps

# Stop the containers
docker compose -f docker-compose.local.yml down
```

Once the containers are running, you can access:
- The application at http://localhost:8000
- The Traefik dashboard at http://localhost:8081/dashboard/

### Local Configuration Files

- `docker-compose.local.yml`: Configuration for local development
- `config/traefik.local.yml`: Traefik configuration for local development

These files are configured to run the application locally without SSL/TLS certificates, making it easier to test changes before deploying to the VPS.

For a detailed comparison between the local and production Docker Compose configurations, see [docker-compose-comparison.md](docs/docker-compose-comparison.md).

## Añadir nuevas aplicaciones

Una de las principales ventajas de esta infraestructura es la facilidad para añadir nuevas aplicaciones sin modificar la configuración central.

### Proceso para añadir una nueva aplicación

1. **Dockerizar la aplicación**:
   - Crear un Dockerfile que construya y ejecute tu aplicación
   - Asegurarte de que expone algún puerto HTTP

2. **Crear un docker-compose.yml** con:
   ```yaml
   version: "3"

   services:
     mi-app:
       build: .
       # o image: nombre-imagen:tag si usas una imagen existente
       networks:
         - traefik-local
       labels:
         - "traefik.enable=true"
         - "traefik.http.routers.mi-app.rule=Host(`mi-app.localhost`)"
         - "traefik.http.services.mi-app-service.loadbalancer.server.port=PUERTO_INTERNO"

   networks:
     traefik-local:
       external: true
   ```

3. **Iniciar la aplicación**:
   ```bash
   docker compose up -d
   ```

4. **Actualizar tu archivo hosts** (para desarrollo local):
   ```
   127.0.0.1 mi-app.localhost
   ```

Y eso es todo. Traefik detectará automáticamente la nueva aplicación y comenzará a enrutar el tráfico a ella basándose en el dominio.

Para desplegar en producción, simplemente adapta el docker-compose.yml para usar Docker Swarm y despliégalo en tu VPS.