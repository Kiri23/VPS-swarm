# Docker Swarm: Orquestación Multi-Dispositivo

## ¿Qué es Docker Swarm?

Docker Swarm es un sistema de orquestación nativo de Docker que permite gestionar un clúster de múltiples instancias de Docker (llamadas "nodos") como si fueran una sola entidad. Esto significa que puedes conectar diferentes dispositivos físicos (como MacBooks, PCs, o Raspberry Pis) para que trabajen juntos como un único sistema.

## ¿Por qué usar Docker Swarm?

### Ventajas principales:

1. **Aprovechamiento de hardware existente**: Puedes utilizar todos tus dispositivos (incluso los menos potentes como Raspberry Pi) para formar un clúster más potente.

2. **Alta disponibilidad**: Si un dispositivo falla, los servicios se redistribuyen automáticamente a otros nodos.

3. **Escalabilidad horizontal**: Añadir más capacidad es tan simple como conectar un nuevo dispositivo al Swarm.

4. **Balanceo de carga integrado**: Distribuye automáticamente las solicitudes entre las réplicas de un servicio.

5. **Gestión centralizada**: Administras todo el clúster desde un único punto de control.

6. **Actualizaciones sin tiempo de inactividad**: Puedes actualizar servicios de forma progresiva sin interrupciones.

## Conceptos clave de Docker Swarm

### Nodos

- **Manager nodes**: Controlan el estado del clúster y distribuyen las tareas. Se recomienda tener un número impar (3, 5, 7) para tolerancia a fallos.
- **Worker nodes**: Ejecutan los contenedores asignados por los managers.

### Servicios

Un servicio es la definición de las tareas a ejecutar en los nodos. Por ejemplo, "ejecutar 3 réplicas de la imagen nginx".

### Tareas

Una tarea es una instancia en ejecución de un servicio (un contenedor individual).

### Redes Overlay

Permiten que los contenedores se comuniquen entre sí, incluso cuando están en diferentes nodos físicos.

## Configuración práctica: MacBook + Raspberry Pi

### Requisitos previos

- Docker instalado en todos los dispositivos
- Conectividad de red entre los dispositivos
- Puertos necesarios abiertos (2377, 7946, 4789)

### Paso 1: Inicializar el Swarm en tu MacBook (como manager)

```bash
# Obtener la IP de tu MacBook
ip=$(ifconfig en0 | grep inet | awk '$1=="inet" {print $2}')
echo $ip  # Anota esta IP

# Inicializar el Swarm
docker swarm init --advertise-addr $ip
```

Este comando mostrará un token que necesitarás para el siguiente paso.

### Paso 2: Unir la Raspberry Pi al Swarm (como worker)

```bash
# Conéctate por SSH a tu Raspberry Pi
ssh raspberry@ip.address

# Una vez dentro de la Raspberry Pi, ejecuta el comando que te dio el paso anterior
docker swarm join --token SWMTKN-1-xxxxxxxxxxxxxxxxxxxx <IP-DE-TU-MACBOOK>:2377
```

### Paso 3: Verificar que ambos nodos están en el Swarm

```bash
# En tu MacBook (el manager)
docker node ls
```

Deberías ver dos nodos: tu MacBook (como manager) y tu Raspberry Pi (como worker).

### Paso 4: Crear una red overlay para que los contenedores se comuniquen

```bash
# En tu MacBook
docker network create --driver overlay traefik-public
```

### Paso 5: Desplegar servicios que se ejecuten en ambos dispositivos

```bash
# Desplegar Traefik como punto de entrada
docker service create --name traefik \
  --network traefik-public \
  --publish 80:80 \
  --publish 8080:8080 \
  --mount type=bind,source=/var/run/docker.sock,destination=/var/run/docker.sock \
  traefik:v2.9 \
  --providers.docker.swarmMode=true \
  --providers.docker.exposedByDefault=false \
  --providers.docker.network=traefik-public \
  --api.insecure=true

# Desplegar una aplicación web
docker service create --name webapp \
  --network traefik-public \
  --replicas 3 \
  --label "traefik.enable=true" \
  --label "traefik.http.routers.webapp.rule=Host(`webapp.local`)" \
  --label "traefik.http.services.webapp.loadbalancer.server.port=80" \
  nginx:latest
```

## Consideraciones para entornos multi-arquitectura

### 1. Arquitecturas diferentes

Tu MacBook (ARM64 si es M1/M2 o AMD64 si es Intel) y tu Raspberry Pi (ARM) tienen arquitecturas diferentes:

```bash
# Ver la arquitectura de cada nodo
docker node ls -q | xargs docker node inspect -f '{{ .Description.Hostname }} {{ .Description.Platform.Architecture }}'
```

Para manejar esto:

- Usa imágenes multi-arquitectura cuando sea posible
- Especifica restricciones para ciertos servicios:

```bash
# Forzar que un servicio se ejecute en la Raspberry Pi
docker service create --name rpi-app \
  --constraint 'node.hostname==raspberry-pi' \
  arm32v7/nginx:latest

# Forzar que un servicio se ejecute en el MacBook
docker service create --name mac-app \
  --constraint 'node.hostname==macbook-pro' \
  nginx:latest
```

### 2. Diferencia de rendimiento

La Raspberry Pi tiene menos recursos que tu MacBook:

```bash
# Limitar recursos para proteger la Raspberry Pi
docker service create --name lightweight-app \
  --limit-cpu 0.5 \
  --limit-memory 256M \
  nginx:latest
```

## Visualización de la arquitectura

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│                         Red Física / Wi-Fi                              │
│                                                                         │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
        ┌─────────────────────┐ │ ┌─────────────────────┐
        │                     │ │ │                     │
        │   MacBook           │◄┼─┼►   Raspberry Pi      │
        │   (Manager Node)    │ │ │   (Worker Node)     │
        │                     │ │ │                     │
        └─────────┬───────────┘ │ └─────────┬───────────┘
                  │             │           │
                  │             │           │
┌─────────────────┴─────────────┴───────────┴─────────────┴───────────────┐
│                                                                         │
│                      Red Overlay "traefik-public"                       │
│                                                                         │
└───────────┬───────────────────────────┬───────────────────────────┬─────┘
            │                           │                           │
┌───────────▼───────────┐   ┌───────────▼───────────┐   ┌───────────▼───────────┐
│                       │   │                       │   │                       │
│  Contenedor Traefik   │   │  Contenedor App1      │   │  Contenedor App2      │
│  (MacBook)            │   │  (MacBook)            │   │  (Raspberry Pi)       │
│                       │   │                       │   │                       │
└───────────────────────┘   └───────────────────────┘   └───────────────────────┘
```

## Comandos útiles para gestionar tu Swarm

```bash
# Ver todos los nodos
docker node ls

# Ver todos los servicios
docker service ls

# Ver detalles de un servicio
docker service ps webapp

# Escalar un servicio
docker service scale webapp=5

# Actualizar un servicio
docker service update --image nginx:alpine webapp

# Inspeccionar la red overlay
docker network inspect traefik-public

# Eliminar un servicio
docker service rm webapp

# Abandonar el Swarm (desde un worker)
docker swarm leave

# Forzar la salida de un nodo (desde un manager)
docker node rm raspberry-pi

# Eliminar el Swarm completamente (desde un manager)
docker swarm leave --force
```

## Casos de uso prácticos

### 1. Servidor doméstico + dispositivos auxiliares

Puedes tener un servidor principal en casa (como un NAS o un mini PC) que actúe como manager, y añadir Raspberry Pis u otros dispositivos como workers para tareas específicas.

### 2. Entorno de desarrollo distribuido

Puedes utilizar tu MacBook como manager y añadir máquinas virtuales o dispositivos físicos como workers para probar aplicaciones en diferentes entornos.

### 3. Laboratorio de aprendizaje

Crear un mini-clúster con dispositivos diversos es una excelente manera de aprender sobre orquestación de contenedores, microservicios y arquitecturas distribuidas.

## El concepto de "Cluster"

Un clúster es simplemente un grupo de computadoras que trabajan juntas como un sistema unificado. Los conceptos clave son:

1. **Nodos**: Las máquinas individuales (físicas o virtuales) que forman el clúster

2. **Plano de control**: El "cerebro" del clúster que toma decisiones sobre:
   - Dónde ejecutar cargas de trabajo
   - Cómo responder a fallos
   - Cómo escalar servicios

3. **Plano de datos**: Donde realmente se ejecutan las aplicaciones

4. **Networking**: Cómo se comunican los componentes entre sí
   - Redes overlay en Docker Swarm
   - CNI (Container Network Interface) en Kubernetes

5. **Almacenamiento**: Cómo persisten los datos
   - Volúmenes locales
   - Almacenamiento compartido en red
   - Servicios de almacenamiento en la nube

## Comparación con otras tecnologías de orquestación

| Concepto en Docker Swarm | Equivalente en Kubernetes | Equivalente en AWS |
|--------------------------|---------------------------|-------------------|
| Swarm Cluster | Kubernetes Cluster | ECS/EKS Cluster |
| Manager Node | Control Plane | ECS Control Service / EKS Control Plane |
| Worker Node | Worker Node | EC2 Instance / ECS Container Instance |
| Service | Deployment + Service | ECS Service / EKS Deployment |
| Task | Pod | ECS Task / Fargate Task |
| Stack | Helm Chart | CloudFormation Stack |
| Overlay Network | Pod Network | VPC + Security Groups |
| Secret | Secret | AWS Secrets Manager |
| Config | ConfigMap | AWS Parameter Store |

Docker Swarm es generalmente más simple pero menos potente que Kubernetes. AWS ofrece servicios gestionados que eliminan parte de la complejidad de administrar estos sistemas por tu cuenta.

al utilizar pass como heroku netlify etc.Estas plataformas están ejecutando clusters, contenedores, balanceadores de carga y todo lo demás por ti, pero te lo presentan como una experiencia simplificada donde solo te preocupas por tu código. Es como la diferencia entre conducir un auto (tú controlas la dirección, velocidad, etc.) y tomar un taxi (llegas al mismo lugar, pero alguien más se encarga de conducir).



## Conclusión

Docker Swarm te permite aprovechar todos tus dispositivos, incluso aquellos que podrían parecer obsoletos o de baja potencia, para crear un sistema distribuido potente y resiliente. Es una excelente manera de maximizar el uso de tu hardware existente y aprender sobre sistemas distribuidos en el proceso.

La próxima vez que pienses en comprar un nuevo servidor o dispositivo, considera si podrías lograr lo mismo conectando los dispositivos que ya tienes mediante Docker Swarm.

## Recursos adicionales

- [Documentación oficial de Docker Swarm](https://docs.docker.com/engine/swarm/)
- [Tutorial: Primeros pasos con Swarm](https://docs.docker.com/engine/swarm/swarm-tutorial/)
- [Gestión de secretos en Swarm](https://docs.docker.com/engine/swarm/secrets/)
- [Gestión de configuraciones en Swarm](https://docs.docker.com/engine/swarm/configs/)
