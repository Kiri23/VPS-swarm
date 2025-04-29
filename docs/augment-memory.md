# General
- User enjoys creating concise documentation for their "future self" to remember concepts and technical configurations.
- User prefers simpler deployment solutions like Heroku, Vercel, or AWS when not requiring multiple interconnected services.
- User prefers setting up multiple applications by configuring them with Traefik and adding them to a shared network to host multiple apps on a single domain.
- User prefers describing their project as a personal hosting system similar to Heroku/Vercel that runs on a VPS in Hostinger, not just locally, with a 'plug and play' infrastructure for adding applications.
- User is interested in creating a simple UI for adding new applications to their Docker Swarm setup without requiring local computer interaction.

# VPS Setup
- User has a VPS setup where files from /home/kiri on the VPS are mounted to containers, and they have documentation in README.md.
- User has a VPS setup and is interested in learning how to manage Docker Swarm nodes on it.

# Docker Swarm
- User is interested in Docker Swarm for connecting multiple physical devices (like Raspberry Pi and NAS) but questions the benefits over single-machine setups for multimedia services.
- User has multiple physical devices (Macbooks and Raspberry Pi) that they want to connect using Docker Swarm.
- User wants Docker Swarm documentation stored in @docs/Learning/ for future reference, showing interest in Docker Swarm's capabilities for connecting multiple physical devices.
- User is interested in Docker Swarm's manager-worker relationship and wants to understand the control hierarchy between nodes.
- User uses Docker context on their MacBook to connect to remote Docker environments rather than running Docker Swarm locally.

# Container Orchestration Technologies
- User is interested in container orchestration technologies like Kubernetes, Nomad (HashiCorp), and AWS services (Fargate, EC2) and is new to cluster technologies.
- User wants to understand the use cases and capabilities of Nomad.

# Docker Compose Configuration
- User has a docker-compose.local.yml for local development separate from their Docker Swarm configuration.
- User wants to implement multi-app Traefik setup locally without Docker Swarm's overlay network.
- User wants documentation in docker-compose.yml to clarify differences between regular Docker Compose and Docker Swarm mode for future reference.

# Traefik Configuration
- User is interested in container orchestration technologies like Traefik and Docker Swarm and wants to understand their capabilities as reverse proxies and for TLS certificate management.
- User's Traefik configuration was changed from using 'docker' provider to 'swarm' provider to work with Docker Swarm mode.