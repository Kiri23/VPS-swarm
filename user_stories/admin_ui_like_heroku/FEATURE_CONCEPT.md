# Panel de Administración Web para Gestión de Aplicaciones

## Visión General

Crear una interfaz web simple que permita gestionar las aplicaciones desplegadas en nuestra infraestructura Docker Swarm sin necesidad de acceder a la línea de comandos o a la computadora local.

## Objetivos

- Simplificar la gestión de aplicaciones
- Permitir añadir nuevas aplicaciones desde cualquier dispositivo
- Visualizar el estado y logs de las aplicaciones existentes
- Proporcionar una experiencia similar a plataformas como Heroku/Vercel

## Historias de Usuario

### Historia 1: Visualización de Aplicaciones

**Como** administrador del sistema,  
**Quiero** ver todas las aplicaciones desplegadas actualmente,  
**Para** tener una visión general del estado de mi infraestructura.

**Criterios de aceptación:**
- Mostrar una lista de todas las aplicaciones
- Indicar el estado de cada aplicación (activa, inactiva, error)
- Mostrar recursos utilizados (CPU, memoria)
- Mostrar la URL de acceso a cada aplicación

### Historia 2: Añadir Nueva Aplicación

**Como** administrador del sistema,  
**Quiero** añadir una nueva aplicación a través de un formulario web,  
**Para** no tener que escribir archivos docker-compose manualmente.

**Criterios de aceptación:**
- Formulario con campos para nombre, imagen Docker, puerto y dominio
- Opción para añadir variables de entorno
- Botón para desplegar la aplicación
- Feedback visual del proceso de despliegue

### Historia 3: Gestión de Aplicaciones Existentes

**Como** administrador del sistema,  
**Quiero** gestionar aplicaciones existentes (reiniciar, escalar, eliminar),  
**Para** mantener mi infraestructura sin acceder a la línea de comandos.

**Criterios de aceptación:**
- Botones para reiniciar, escalar y eliminar aplicaciones
- Confirmación antes de acciones destructivas
- Feedback visual del resultado de las acciones

### Historia 4: Visualización de Logs

**Como** administrador del sistema,  
**Quiero** ver los logs de mis aplicaciones en tiempo real,  
**Para** diagnosticar problemas sin acceder a la línea de comandos.

**Criterios de aceptación:**
- Visualización de logs en tiempo real
- Opción para filtrar logs
- Opción para descargar logs

## Posibles Enfoques de Implementación

### Opción 1: Utilizar Portainer

- Desplegar Portainer como parte de la infraestructura
- Configurar Traefik para enrutar a Portainer
- Personalizar según sea necesario

### Opción 2: Desarrollar UI Personalizada

- Crear un servicio backend que interactúe con la API de Docker
- Desarrollar un frontend simple con React/Vue
- Desplegar como una aplicación más en la infraestructura

## Consideraciones de Seguridad

- Implementar autenticación robusta
- Limitar el acceso a la UI desde IPs específicas
- Considerar el uso de HTTPS con certificados válidos
- Limitar los permisos del servicio al mínimo necesario

## Próximos Pasos

1. Evaluar si Portainer cubre las necesidades o si es necesario desarrollar una solución personalizada
2. Definir el alcance mínimo viable para una primera versión
3. Diseñar la arquitectura básica de la solución
4. Implementar un prototipo para validar el concepto


## Alternativa crea tu propio UI , portainer es pagando $150 yearly 

Backend: Un servicio que interactúe con la API de Docker
Node.js con la biblioteca dockerode
Python con docker-py
Go con la biblioteca oficial de Docker

Frontend: Una interfaz web simple
React/Vue/Angular para la interfaz

Formularios para configurar nuevas aplicaciones
Visualización de logs y métricas
Funcionalidades clave:
Formulario para crear docker-compose.yml
Selección de imágenes de Docker Hub
Configuración de etiquetas de Traefik
Gestión de variables de entorno
Botones para iniciar/detener/reiniciar servicios


Ejemplo conceptual de tu propia UI
Un servicio Node.js que podría servir como base:


const express = require('express');
const Docker = require('dockerode');
const yaml = require('js-yaml');
const fs = require('fs');
const app = express();
const docker = new Docker({socketPath: '/var/run/docker.sock'});

app.use(express.json());
app.use(express.static('public'));

// Listar todas las aplicaciones
app.get('/api/apps', async (req, res) => {
  const services = await docker.listServices();
  res.json(services);
});

// Añadir nueva aplicación
app.post('/api/apps', async (req, res) => {
  const { name, image, port, domain } = req.body;
  
  // Crear docker-compose.yml
  const composeConfig = {
    version: '3',
    services: {
      [name]: {
        image,
        networks: ['traefik-local'],
        labels: [
          'traefik.enable=true',
          `traefik.http.routers.${name}.rule=Host(\`${domain}\`)`,
          `traefik.http.services.${name}-service.loadbalancer.server.port=${port}`
        ]
      }
    },
    networks: {
      'traefik-local': {
        external: true
      }
    }
  };
  
  // Guardar el archivo
  fs.writeFileSync(`/app/stacks/${name}.yml`, yaml.dump(composeConfig));
  
  // Desplegar el stack
  const exec = require('child_process').exec;
  exec(`docker stack deploy -c /app/stacks/${name}.yml ${name}`, (error, stdout, stderr) => {
    if (error) {
      return res.status(500).json({ error: stderr });
    }
    res.json({ success: true, message: stdout });
  });
});

// Más endpoints para gestionar aplicaciones...

app.listen(3000, () => {
  console.log('App Manager UI running on port 3000');
});
