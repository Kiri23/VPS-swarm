# Gestión de Infraestructura a Largo Plazo

Este documento proporciona una guía para mantener el control de las aplicaciones desplegadas en tu VPS a lo largo del tiempo, especialmente cuando vuelves al proyecto después de un período sin trabajar en él.

## Cómo saber qué aplicaciones tienes desplegadas después de tiempo

Este es un problema común: vuelves a tu proyecto después de meses y no recuerdas qué tienes desplegado. Aquí tienes varias formas de hacer un "inventario":

### 1. Listar todos los stacks

```bash
docker context use hostinger
docker stack ls
```

Esto te mostrará algo como:

```
NAME      SERVICES   ORCHESTRATOR
myapp     3          Swarm
blog      1          Swarm
portfolio 2          Swarm
```

### 2. Ver los servicios de un stack específico

```bash
docker stack services myapp
```

Mostrará:

```
ID             NAME                MODE         REPLICAS   IMAGE                    PORTS
abc123def456   myapp_web          replicated   1/1        kiri23/express:prod      
ghi789jkl012   myapp_watchtower   replicated   1/1        containrrr/watchtower:latest
mno345pqr678   myapp_reverse-proxy replicated  1/1        traefik:v3.1
```

### 3. Ver todos los servicios (de todos los stacks)

```bash
docker service ls
```

### 4. Ver detalles de un servicio específico

```bash
docker service inspect --pretty myapp_web
```

### 5. Ver a qué dominios está respondiendo Traefik

```bash
docker service logs myapp_reverse-proxy | grep "Host("
```

O mejor aún, acceder al dashboard de Traefik (si lo tienes habilitado) en `https://traefik.kiri231.com/dashboard/` o similar.

## Buenas prácticas para mantener el control

Para facilitar el "redescubrimiento" de tu infraestructura después de tiempo:

### 1. Mantén un repositorio con todos tus archivos docker-compose.yml

```
mi-infraestructura/
├── traefik/
│   └── docker-compose.yml
├── blog/
│   └── docker-compose.yml
├── portfolio/
│   └── docker-compose.yml
└── README.md  # Documentación general
```

### 2. Documenta cada aplicación en su propio README

En cada carpeta de aplicación, incluye un README.md con:
- Qué hace la aplicación
- Qué dominio usa
- Cualquier configuración especial
- Cómo se construye y despliega
- Dependencias con otros servicios

Ejemplo:
```markdown
# Blog Personal

Blog construido con Ghost CMS.

- **Dominio**: blog.kiri231.com
- **Puerto interno**: 2368
- **Dependencias**: Necesita base de datos MySQL
- **Última actualización**: 2023-11-15
```

### 3. Usa nombres descriptivos para los stacks

En lugar de nombres genéricos como "app1", usa nombres que describan la función:

```bash
docker stack deploy -c docker-compose.yml blog
docker stack deploy -c docker-compose.yml portfolio
docker stack deploy -c docker-compose.yml monitoring
```

### 4. Etiqueta tus servicios con metadatos

```yaml
services:
  web:
    # ...
    deploy:
      labels:
        - "com.kiri231.description=Mi blog personal"
        - "com.kiri231.created=2023-11-15"
        - "com.kiri231.domain=blog.kiri231.com"
```

Luego puedes consultar estos metadatos:
```bash
docker service inspect blog_web --format '{{json .Spec.Labels}}' | jq
```

### 5. Crea un "dashboard" simple

Podrías desplegar una aplicación simple que muestre todas tus aplicaciones y sus dominios, como un "portal" personal. Esta aplicación podría:

- Listar todas tus aplicaciones y sus URLs
- Mostrar el estado de cada aplicación
- Proporcionar enlaces a la documentación
- Servir como página de inicio para tu dominio principal

## Uso de Portainer para gestión visual

Portainer te proporciona una interfaz web para gestionar tu infraestructura Docker:

```yaml
version: "3"

services:
  portainer:
    image: portainer/portainer-ce:latest
    command: -H unix:///var/run/docker.sock
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    deploy:
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.portainer.rule=Host(`portainer.kiri231.com`)"
        - "traefik.http.services.portainer-service.loadbalancer.server.port=9000"
      placement:
        constraints:
          - node.role == manager

volumes:
  portainer_data:
```

Con Portainer puedes:
- Ver todos tus stacks, servicios, contenedores, redes y volúmenes
- Gestionar servicios (iniciar, detener, escalar)
- Ver logs
- Desplegar nuevas aplicaciones
- Monitorear recursos

## Flujo de trabajo recomendado para añadir nuevas aplicaciones

1. **Desarrollar** la aplicación en su propio repositorio
2. **Crear** un Dockerfile y docker-compose.yml
3. **Construir y subir** la imagen a Docker Hub
4. **Desplegar** como un stack separado
5. **Documentar** en el repositorio central de infraestructura

## Comandos útiles para gestión diaria

```bash
# Ver logs de un servicio
docker service logs blog_web

# Escalar un servicio
docker service scale blog_web=3

# Actualizar un servicio a una nueva imagen
docker service update --image kiri23/blog:v2 blog_web

# Eliminar un stack completo
docker stack rm blog

# Ver recursos utilizados
docker stats
```

## Respaldo de configuración

Es recomendable hacer respaldos periódicos de tus archivos de configuración:

```bash
# Desde tu máquina local
scp -r kiri@kiri231.com:/home/kiri/docker-configs ./backups/$(date +%Y-%m-%d)
```

O configurar un sistema automatizado de respaldo de configuraciones.
