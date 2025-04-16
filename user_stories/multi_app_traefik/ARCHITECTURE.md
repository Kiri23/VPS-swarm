# Arquitectura Multi-Aplicación con Traefik

Este documento describe la arquitectura para ejecutar múltiples aplicaciones Node.js en un único servidor VPS, utilizando Traefik como punto de entrada y load balancer.

## Visión general

```
                                  ┌─────────────────┐
                                  │                 │
                                  │  Traefik Master │
                                  │                 │
                                  └────────┬────────┘
                                           │
                                           │
                 ┌─────────────────────────┼─────────────────────────┐
                 │                         │                         │
                 │                         │                         │
        ┌────────▼────────┐      ┌─────────▼────────┐      ┌─────────▼────────┐
        │                 │      │                  │      │                  │
        │   Node App 1    │      │    Node App 2    │      │    Node App 3    │
        │                 │      │                  │      │                  │
        └─────────────────┘      └──────────────────┘      └──────────────────┘
```

## Componentes principales

### 1. Traefik Master

- **Función**: Punto de entrada único para todas las aplicaciones
- **Responsabilidades**:
  - Enrutamiento basado en dominios
  - Gestión de certificados SSL/TLS
  - Load balancing
  - Dashboard de administración

### 2. Aplicaciones Node.js

- **Función**: Servicios independientes que proporcionan funcionalidad específica
- **Características**:
  - Cada aplicación tiene su propio dominio
  - Pueden escalar independientemente
  - Se despliegan como servicios de Docker Swarm
  - Comparten la red de Traefik

## Redes

- **traefik-public**: Red compartida que permite la comunicación entre Traefik y las aplicaciones

## Ventajas de esta arquitectura

1. **Eficiencia de recursos**: Múltiples aplicaciones en un único servidor
2. **Aislamiento**: Cada aplicación se ejecuta en su propio contenedor
3. **Escalabilidad**: Las aplicaciones pueden escalar independientemente
4. **Gestión centralizada de SSL/TLS**: Un único punto para gestionar certificados
5. **Facilidad de mantenimiento**: Añadir nuevas aplicaciones no requiere modificar las existentes

## Alternativas consideradas

### Opción 1: Un único Traefik maestro (implementación actual)

- Ventajas:
  - Configuración más simple
  - Gestión centralizada
  - Menor sobrecarga

- Desventajas:
  - Punto único de fallo
  - Configuración compartida para todas las aplicaciones

### Opción 2: Traefik maestro con Traefiks secundarios

```
                                  ┌─────────────────┐
                                  │                 │
                                  │  Traefik Master │
                                  │                 │
                                  └────────┬────────┘
                                           │
                                           │
                 ┌─────────────────────────┼─────────────────────────┐
                 │                         │                         │
                 │                         │                         │
        ┌────────▼────────┐      ┌─────────▼────────┐      ┌─────────▼────────┐
        │                 │      │                  │      │                  │
        │   Traefik App1  │      │   Node App 2     │      │   Traefik App3   │
        │                 │      │                  │      │                  │
        └────────┬────────┘      └──────────────────┘      └────────┬────────┘
                 │                                                   │
                 │                                                   │
        ┌────────▼────────┐                                 ┌────────▼────────┐
        │                 │                                 │                 │
        │   Node App 1    │                                 │   Node App 3    │
        │                 │                                 │                 │
        └─────────────────┘                                 └─────────────────┘
```

- Ventajas:
  - Configuración más flexible para aplicaciones específicas
  - Aislamiento adicional
  - Posibilidad de configuraciones especializadas

- Desventajas:
  - Mayor complejidad
  - Mayor consumo de recursos
  - Más puntos de fallo potenciales

## Decisiones de diseño

Se ha optado por la Opción 1 (un único Traefik maestro) por su simplicidad y eficiencia. Esta arquitectura proporciona un buen equilibrio entre flexibilidad y facilidad de mantenimiento, permitiendo añadir nuevas aplicaciones de forma sencilla sin comprometer el rendimiento o la seguridad.

## Evolución futura

La arquitectura está diseñada para ser extensible. Si en el futuro se requiere una configuración más especializada para alguna aplicación, se puede migrar a la Opción 2 de forma incremental, añadiendo Traefiks secundarios solo para las aplicaciones que lo necesiten.
