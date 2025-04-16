# Guía de Implementación: Multi-Aplicación con Traefik

Esta guía proporciona instrucciones paso a paso para implementar una arquitectura multi-aplicación con Traefik como load balancer.

## Requisitos previos

- Acceso SSH a un servidor VPS
- Docker y Docker Swarm instalados en el servidor
- Dominios configurados para apuntar al servidor
- Conocimientos básicos de Docker, Docker Compose y Node.js

## Fase 1: Preparación de la infraestructura base

### Paso 1: Conectarse al servidor VPS

```bash
# Añadir clave SSH al agente
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# Conectarse al servidor
ssh kiri@kiri231.com
```

### Paso 2: Crear la red compartida de Traefik

```bash
# Crear red overlay para Docker Swarm
docker network create --driver=overlay --attachable traefik-public

# Verificar que la red se ha creado correctamente
docker network ls
```

### Paso 3: Configurar Traefik maestro

1. Crear un directorio para el Traefik maestro
```bash
mkdir -p ~/traefik-master
cd ~/traefik-master
```

2. Crear el archivo docker-compose.yml
```bash
nano docker-compose.yml
```

3. Añadir la siguiente configuración:
```yaml
version: '3'

services:
  traefik:
    image: traefik:v3.1
    command:
      - "--api.dashboard=true"
      - "--api.insecure=true"  # Solo para desarrollo, usar con precaución
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
      - "8080:8080"  # Dashboard
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - traefik-data:/letsencrypt
    networks:
      - traefik-public
    deploy:
      placement:
        constraints:
          - node.role == manager
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

4. Desplegar el Traefik maestro
```bash
docker stack deploy -c docker-compose.yml traefik-master
```

5. Verificar que Traefik se ha desplegado correctamente
```bash
docker service ls
docker service logs traefik-master_traefik
```

## Fase 2: Desplegar la primera aplicación Node.js

### Paso 1: Preparar la aplicación

1. Crear un directorio para la aplicación
```bash
mkdir -p ~/app1/src
cd ~/app1
```

2. Crear el archivo server.js
```bash
nano src/server.js
```

3. Añadir el siguiente código:
```javascript
const express = require("express");
const app = express();

app.get("/", (req, res) => {
  res.send("Hello from App 1!");
});

app.listen(3000, () => {
  console.log("App 1 is running on port 3000");
});
```

4. Crear el archivo package.json
```bash
nano package.json
```

5. Añadir la siguiente configuración:
```json
{
  "name": "app1",
  "version": "1.0.0",
  "description": "App 1",
  "main": "src/server.js",
  "scripts": {
    "start": "node src/server.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
```

6. Crear el archivo Dockerfile
```bash
nano Dockerfile
```

7. Añadir la siguiente configuración:
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["node", "src/server.js"]
```

### Paso 2: Configurar el despliegue

1. Crear el archivo docker-compose.yml
```bash
nano docker-compose.yml
```

2. Añadir la siguiente configuración:
```yaml
version: '3'

services:
  web:
    image: kiri23/app1:prod
    build:
      context: .
      dockerfile: Dockerfile
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

### Paso 3: Construir y desplegar la aplicación

1. Construir la imagen Docker
```bash
docker build --platform linux/amd64 -t kiri23/app1:prod .
```

2. Subir la imagen a Docker Hub
```bash
docker push kiri23/app1:prod
```

3. Desplegar la aplicación
```bash
docker stack deploy -c docker-compose.yml app1
```

4. Verificar que la aplicación se ha desplegado correctamente
```bash
docker service ls
docker service logs app1_web
```

## Fase 3: Desplegar la segunda aplicación Node.js

### Paso 1: Preparar la aplicación

1. Crear un directorio para la aplicación
```bash
mkdir -p ~/app2/src
cd ~/app2
```

2. Crear el archivo server.js
```bash
nano src/server.js
```

3. Añadir el siguiente código:
```javascript
const express = require("express");
const app = express();

app.get("/", (req, res) => {
  res.send("Hello from App 2!");
});

app.listen(3000, () => {
  console.log("App 2 is running on port 3000");
});
```

4. Crear el archivo package.json
```bash
nano package.json
```

5. Añadir la siguiente configuración:
```json
{
  "name": "app2",
  "version": "1.0.0",
  "description": "App 2",
  "main": "src/server.js",
  "scripts": {
    "start": "node src/server.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
```

6. Crear el archivo Dockerfile
```bash
nano Dockerfile
```

7. Añadir la siguiente configuración:
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["node", "src/server.js"]
```

### Paso 2: Configurar el despliegue

1. Crear el archivo docker-compose.yml
```bash
nano docker-compose.yml
```

2. Añadir la siguiente configuración:
```yaml
version: '3'

services:
  web:
    image: kiri23/app2:prod
    build:
      context: .
      dockerfile: Dockerfile
    networks:
      - traefik-public
    deploy:
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.app2.rule=Host(`app2.kiri231.com`)"
        - "traefik.http.routers.app2.entrypoints=websecure"
        - "traefik.http.routers.app2.tls.certresolver=myresolver"
        - "traefik.http.services.app2-service.loadbalancer.server.port=3000"

networks:
  traefik-public:
    external: true
```

### Paso 3: Construir y desplegar la aplicación

1. Construir la imagen Docker
```bash
docker build --platform linux/amd64 -t kiri23/app2:prod .
```

2. Subir la imagen a Docker Hub
```bash
docker push kiri23/app2:prod
```

3. Desplegar la aplicación
```bash
docker stack deploy -c docker-compose.yml app2
```

4. Verificar que la aplicación se ha desplegado correctamente
```bash
docker service ls
docker service logs app2_web
```

## Fase 4: Verificación y pruebas

### Paso 1: Verificar que Traefik está funcionando correctamente

```bash
# Verificar que el servicio está en ejecución
docker service ls | grep traefik

# Verificar los logs
docker service logs traefik-master_traefik

# Verificar que el dashboard es accesible
curl -k https://traefik.kiri231.com/dashboard/
```

### Paso 2: Verificar que las aplicaciones son accesibles

```bash
# Verificar que la aplicación 1 es accesible
curl -k https://app1.kiri231.com

# Verificar que la aplicación 2 es accesible
curl -k https://app2.kiri231.com
```

## Fase 5: Escalado y optimización

### Paso 1: Escalar la aplicación 1

```bash
# Escalar la aplicación 1 a 3 instancias
docker service scale app1_web=3

# Verificar que las instancias se han creado correctamente
docker service ps app1_web

# Verificar que Traefik está balanceando la carga correctamente
for i in {1..10}; do curl -k https://app1.kiri231.com; echo; done
```

## Guía rápida para añadir una nueva aplicación

1. Crear un nuevo directorio para la aplicación
```bash
mkdir -p ~/app3/src
cd ~/app3
```

2. Crear los archivos necesarios (server.js, package.json, Dockerfile, docker-compose.yml)

3. Construir y subir la imagen Docker
```bash
docker build --platform linux/amd64 -t kiri23/app3:prod .
docker push kiri23/app3:prod
```

4. Desplegar la aplicación
```bash
docker stack deploy -c docker-compose.yml app3
```

5. Verificar que la aplicación es accesible
```bash
curl -k https://app3.kiri231.com
```

## Solución de problemas comunes

### Problema: La aplicación no es accesible

1. Verificar que el servicio está en ejecución
```bash
docker service ls
```

2. Verificar los logs del servicio
```bash
docker service logs app1_web
```

3. Verificar que Traefik está enrutando correctamente
```bash
docker service logs traefik-master_traefik | grep app1
```

4. Verificar que las etiquetas de Traefik son correctas
```bash
docker service inspect app1_web --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' | jq
```

### Problema: Certificados SSL/TLS no válidos

1. Verificar los logs de Traefik
```bash
docker service logs traefik-master_traefik | grep acme
```

2. Verificar que el dominio apunta al servidor
```bash
dig app1.kiri231.com
```

3. Verificar que el puerto 443 está abierto
```bash
curl -k https://app1.kiri231.com
```

### Problema: Traefik no encuentra las aplicaciones

1. Verificar que las aplicaciones están conectadas a la red traefik-public
```bash
docker network inspect traefik-public
```

2. Verificar que las etiquetas de Traefik son correctas
```bash
docker service inspect app1_web --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' | jq
```

3. Verificar que Traefik está configurado correctamente
```bash
docker service inspect traefik-master_traefik --format '{{json .Spec.TaskTemplate.ContainerSpec.Command}}' | jq
```
