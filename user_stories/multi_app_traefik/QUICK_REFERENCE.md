# Guía Rápida de Referencia: Multi-Aplicación con Traefik

Esta guía proporciona comandos y configuraciones clave para gestionar la arquitectura multi-aplicación con Traefik.

## Comandos esenciales

### Gestión de Docker Swarm

```bash
# Ver servicios en ejecución
docker service ls

# Ver detalles de un servicio
docker service ps app1_web

# Ver logs de un servicio
docker service logs app1_web

# Escalar un servicio
docker service scale app1_web=3

# Actualizar un servicio
docker service update --force app1_web
```

### Gestión de Traefik

```bash
# Ver logs de Traefik
docker service logs traefik-master_traefik

# Verificar configuración de Traefik
docker service inspect traefik-master_traefik

# Acceder al dashboard de Traefik
curl -k https://traefik.kiri231.com/dashboard/
```

### Gestión de aplicaciones

```bash
# Construir imagen Docker
docker build --platform linux/amd64 -t kiri23/app1:prod .

# Subir imagen a Docker Hub
docker push kiri23/app1:prod

# Desplegar aplicación
docker stack deploy -c docker-compose.yml app1

# Eliminar aplicación
docker stack rm app1
```

## Configuraciones clave

### Traefik Master (docker-compose.yml)

```yaml
version: '3'

services:
  traefik:
    image: traefik:v3.1
    command:
      - "--api.dashboard=true"
      - "--api.insecure=true"
      - "--providers.swarm=true"
      - "--providers.swarm.endpoint=unix:///var/run/docker.sock"
      - "--providers.swarm.exposedByDefault=false"
      - "--providers.swarm.watch=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.myresolver.acme.email=your-email@example.com"
      - "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
      - "--certificatesresolvers.myresolver.acme.tlschallenge=true"
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - traefik-data:/letsencrypt
    networks:
      - traefik-public
    deploy:
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.dashboard.rule=Host(`traefik.kiri231.com`)"
        - "traefik.http.routers.dashboard.service=api@internal"
        - "traefik.http.routers.dashboard.entrypoints=websecure"
        - "traefik.http.routers.dashboard.tls.certresolver=myresolver"
        - "traefik.http.services.dashboard.loadbalancer.server.port=8080"

networks:
  traefik-public:
    external: true

volumes:
  traefik-data:
```

### Aplicación Node.js (docker-compose.yml)

```yaml
version: '3'

services:
  web:
    image: kiri23/app1:prod
    networks:
      - traefik-public
    deploy:
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.app1.rule=Host(`app1.kiri231.com`)"
        - "traefik.http.routers.app1.entrypoints=websecure"
        - "traefik.http.routers.app1.tls.certresolver=myresolver"
        - "traefik.http.services.app1-service.loadbalancer.server.port=3000"

networks:
  traefik-public:
    external: true
```

## Etiquetas de Traefik importantes

| Etiqueta | Descripción | Ejemplo |
|----------|-------------|---------|
| `traefik.enable` | Habilita Traefik para este servicio | `true` |
| `traefik.http.routers.[name].rule` | Regla para enrutar tráfico | `Host(\`app1.kiri231.com\`)` |
| `traefik.http.routers.[name].entrypoints` | Punto de entrada a usar | `websecure` |
| `traefik.http.routers.[name].tls.certresolver` | Resolver de certificados | `myresolver` |
| `traefik.http.services.[name].loadbalancer.server.port` | Puerto del servicio | `3000` |

## Flujo de trabajo para añadir una nueva aplicación

1. **Crear estructura de directorios**
   ```bash
   mkdir -p ~/app3/src
   cd ~/app3
   ```

2. **Crear archivos de la aplicación**
   - `src/server.js`
   - `package.json`
   - `Dockerfile`
   - `docker-compose.yml`

3. **Construir y subir imagen**
   ```bash
   docker build --platform linux/amd64 -t kiri23/app3:prod .
   docker push kiri23/app3:prod
   ```

4. **Desplegar aplicación**
   ```bash
   docker stack deploy -c docker-compose.yml app3
   ```

5. **Verificar despliegue**
   ```bash
   docker service ls
   curl -k https://app3.kiri231.com
   ```
