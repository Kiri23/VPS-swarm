# Debugging Guide

This document contains detailed information for debugging and troubleshooting the Docker Stack Example project.

## SSH and Docker Context Configuration

### Setting Up SSH for Docker Context

Before using Docker Context to connect to your remote server, ensure your SSH configuration is properly set up:

1. Configure your SSH client in `~/.ssh/config`:

```
Host kiri231.com
    HostName kiri231.com
    User kiri
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    AddKeysToAgent yes
```

2. Add your SSH key to the SSH agent to avoid entering the passphrase repeatedly:

```bash
# For macOS
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# For Linux/older macOS versions
ssh-add ~/.ssh/id_ed25519
```

3. Test your SSH connection:

```bash
ssh kiri@kiri231.com docker info
```

### Setting Up Docker Context

1. Create a Docker context for your remote server:

```bash
docker context create hostinger --docker "host=ssh://kiri@kiri231.com"
```

2. Switch to the remote context:

```bash
docker context use hostinger
```

3. Verify the connection:

```bash
docker info
```

### Troubleshooting Docker Context

If you encounter issues with Docker Context:

1. **SSH Authentication Issues**:
   - Ensure your SSH key is added to the agent: `ssh-add ~/.ssh/id_ed25519`
   - Verify SSH connection works: `ssh kiri@kiri231.com docker info`
   - Check SSH configuration in `~/.ssh/config`

2. **TCP Forwarding Issues**:
   - Ensure TCP forwarding is enabled on the server:
     ```bash
     # Check current setting
     ssh kiri@kiri231.com "grep -i AllowTcpForwarding /etc/ssh/sshd_config"
     
     # Enable if needed (requires sudo)
     ssh kiri@kiri231.com "sudo sed -i 's/#AllowTcpForwarding yes/AllowTcpForwarding yes/' /etc/ssh/sshd_config && sudo systemctl restart sshd"
     ```

3. **Docker Permissions**:
   - Ensure your user is in the docker group on the server:
     ```bash
     ssh kiri@kiri231.com "groups"
     ```
   - Add user to docker group if needed:
     ```bash
     ssh kiri@kiri231.com "sudo usermod -aG docker kiri && newgrp docker"
     ```

## Advanced Debugging

### Understanding Service Names

- Services in Docker Swarm follow the naming convention:
  `<stack_name>_<service_name>`
- Example: `myapp_web`, `myapp_watchtower`

### Common Debugging Commands

#### 1. Check Service Status

```bash
# List all services and their status
docker service ls

# Get detailed info about a specific service
docker service ps myapp_web
```

- `service ps` shows:
  - Current and previous container instances
  - Image versions
  - Node placement
  - Container states
  - Error messages if any

#### 2. Check Service Logs

```bash
# View all logs
docker service logs myapp_web

# View recent logs (last 2 minutes)
docker service logs --since 2m myapp_web

# Follow logs in real-time
docker service logs -f myapp_web
```

#### 3. Debugging Watchtower

```bash
# View Watchtower logs
docker service logs myapp_watchtower
```

Understanding Watchtower logs:

- `Scanned=0`: Watchtower isn't finding containers to monitor
  - Check if containers have the label
    `com.centurylinklabs.watchtower.enable=true`
- `Scanned=1, Updated=0`: Found container but no updates needed
- `Scanned=1, Updated=1`: Successfully updated a container

Common Watchtower Warnings:

```
"Could not do a head request... falling back to regular pull"
"Parsed container image ref has no tag"
```

These warnings are normal and indicate:

- Watchtower is using an alternative method to check for updates
- The container is using a SHA-based image reference (secure and normal)
- Not an error if you see `Scanned=X Updated=0` in the same log

#### 4. Force Update Service

If Watchtower isn't updating automatically:

```bash
docker service update --force myapp_web
```

### SSH Passphrase Issues

- If you're repeatedly prompted for your SSH key passphrase:
  ```bash
  # Start or restart the SSH agent
  eval "$(ssh-agent -s)"
  
  # Add your key to the agent
  ssh-add --apple-use-keychain ~/.ssh/id_ed25519  # macOS
  # OR
  ssh-add ~/.ssh/id_ed25519  # Linux/older macOS
  ```

- For persistent SSH agent configuration on macOS, add to `~/.ssh/config`:
  ```
  Host *
    UseKeychain yes
    AddKeysToAgent yes
  ```
