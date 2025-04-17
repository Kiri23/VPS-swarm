# Docker Swarm vs Docker Compose

## ¿Cuándo usar Docker Swarm con un solo nodo?

Docker Swarm ofrece ventajas incluso cuando se ejecuta en un solo servidor:

- Despliegue declarativo de múltiples servicios
- Actualizaciones sin tiempo de inactividad
- Auto-recuperación de servicios caídos
- Escalabilidad simple con balanceo de carga automático
- Preparación para expansión futura

## Comparación con Docker Compose estándar

Podrías lograr algo similar con Docker Compose estándar (`docker-compose up -d`), pero hay diferencias clave:

| Característica | Docker Swarm (incluso con 1 nodo) | Docker Compose estándar |
|----------------|-----------------------------------|-------------------------|
| Despliegue declarativo | ✅ `docker stack deploy` | ✅ `docker-compose up` |
| Actualizaciones sin tiempo de inactividad | ✅ Automático | ❌ Requiere scripts adicionales |
| Auto-recuperación | ✅ Automático | ✅ Pero menos robusto |
| Escalabilidad | ✅ `docker service scale` | ✅ `docker-compose scale` (más limitado) |
| Balanceo de carga interno | ✅ Automático | ❌ Requiere configuración adicional |
| Preparado para multi-nodo | ✅ Solo añadir nodos | ❌ Requiere migración a Swarm |

## Comandos básicos

### Docker Swarm
```bash
# Desplegar stack
docker stack deploy -c docker-compose.yml myapp

# Escalar servicio
docker service scale myapp_web=3

# Ver servicios
docker service ls

# Ver réplicas de un servicio
docker service ps myapp_web
```

### Docker Compose
```bash
# Iniciar servicios
docker-compose up -d

# Escalar servicio (más limitado)
docker-compose up -d --scale web=3

# Ver contenedores
docker-compose ps
```

## Escalado de servicios: Swarm vs Compose

### Escalado en Docker Swarm

Cuando escalas un servicio en Swarm (`docker service scale myapp_web=3`):

- Crea múltiples réplicas idénticas del mismo contenedor
- Todas las réplicas son gestionadas como una unidad
- El tráfico se balancea automáticamente entre todas las réplicas
- Comparten la misma definición de servicio

```bash
# Ejemplo de escalado en Swarm
docker service scale myapp_web=3

# Resultado
ID            NAME          IMAGE                NODE        DESIRED STATE  CURRENT STATE
abc123        myapp_web.1   kiri23/express:prod  srv704143   Running        Running 2 hours
def456        myapp_web.2   kiri23/express:prod  srv704143   Running        Running 30 seconds
ghi789        myapp_web.3   kiri23/express:prod  srv704143   Running        Running 30 seconds
```

### Docker Compose múltiples veces NO es lo mismo

Ejecutar `docker compose up` varias veces NO es equivalente a escalar en Swarm:

- Causaría conflictos de nombres de contenedores
- Causaría conflictos de puertos
- No hay balanceo de carga automático
- Requiere gestionar cada instancia por separado

Para escalar con Compose necesitas configuración específica y tiene limitaciones.
