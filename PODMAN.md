# Podman Deployment Guide

Podman is a daemonless container engine that can run containers as a drop-in replacement for Docker.

## Installation

**macOS:**
```bash
brew install podman
podman machine init
podman machine start
```

**Linux:**
```bash
# Ubuntu/Debian
sudo apt-get install podman

# RHEL/Fedora
sudo dnf install podman
```

## Using Podman Compose

Podman supports docker-compose files via `podman-compose`:

```bash
# Install podman-compose
pip3 install podman-compose

# Use existing docker-compose.yml
podman-compose up -d
podman-compose ps
podman-compose logs -f
podman-compose down
```

## Using Podman Directly

### Run Single Container

```bash
# Create volumes
podman volume create cronicle-data
podman volume create cronicle-logs
podman volume create cronicle-conf
podman volume create cronicle-queue

# Run container
podman run -d \
  --name cronicle \
  --user 1000:1000 \
  -p 3012:3012 \
  --security-opt no-new-privileges=true \
  --cap-drop ALL \
  --read-only \
  --memory 2g \
  --cpus 2 \
  --pids-limit 200 \
  -v cronicle-data:/opt/cronicle/data \
  -v cronicle-logs:/opt/cronicle/logs \
  -v cronicle-conf:/opt/cronicle/conf \
  -v cronicle-queue:/opt/cronicle/queue \
  -v ./workloads:/opt/cronicle/workloads:ro \
  --tmpfs /tmp:rw,size=100m,mode=1777 \
  --tmpfs /opt/cronicle/tmp:rw,size=100m,mode=0750 \
  --tmpfs /var/tmp:rw,size=50m,mode=1777 \
  -e CRONICLE_base_app_url=http://localhost:3012 \
  -e CRONICLE_secret_key=YOUR_RANDOM_SECRET_KEY \
  --restart unless-stopped \
  xentropics/cronicle:latest
```

### Management Commands

```bash
# View logs
podman logs -f cronicle

# Shell access
podman exec -it cronicle /bin/sh

# Stop/start
podman stop cronicle
podman start cronicle

# Remove
podman rm -f cronicle

# Retrieve admin password
podman exec cronicle cat /opt/cronicle/data/.admin_credentials
```

## Podman Pod (Similar to Docker Compose)

Create a pod with multiple containers:

```bash
# Create pod
podman pod create --name cronicle-pod -p 3012:3012

# Run Cronicle in the pod
podman run -d \
  --pod cronicle-pod \
  --name cronicle \
  --user 1000:1000 \
  --security-opt no-new-privileges=true \
  --cap-drop ALL \
  --read-only \
  -v cronicle-data:/opt/cronicle/data \
  -v cronicle-logs:/opt/cronicle/logs \
  -v cronicle-conf:/opt/cronicle/conf \
  -v cronicle-queue:/opt/cronicle/queue \
  --tmpfs /tmp:rw,size=100m \
  --tmpfs /opt/cronicle/tmp:rw,size=100m \
  -e CRONICLE_base_app_url=http://localhost:3012 \
  xentropics/cronicle:latest

# Manage pod
podman pod ps
podman pod stop cronicle-pod
podman pod start cronicle-pod
podman pod rm cronicle-pod
```

## Systemd Integration

Generate systemd unit files for auto-start:

```bash
# Generate systemd service
podman generate systemd --new --name cronicle > ~/.config/systemd/user/cronicle.service

# Enable and start
systemctl --user enable cronicle.service
systemctl --user start cronicle.service

# Check status
systemctl --user status cronicle.service
```

## Rootless Mode

Podman runs rootless by default - no daemon required:

```bash
# Check if running rootless
podman info | grep -i root

# Run as unprivileged user (default)
podman run --user 1000:1000 xentropics/cronicle:latest
```

## Advantages of Podman

- **Daemonless**: No background daemon required
- **Rootless**: Run containers without root privileges
- **Docker compatible**: Uses same CLI commands
- **Systemd integration**: Native service management
- **Pod support**: Kubernetes-like pod concept
- **Security**: Better default security posture

## Migration from Docker

Most Docker commands work with Podman:

```bash
# Create alias
alias docker=podman

# Or use docker-compose compatibility
alias docker-compose=podman-compose
```

## Troubleshooting

**Port already in use:**
```bash
podman ps -a
podman rm -f cronicle
```

**Permission errors:**
```bash
# Check volume permissions
podman volume inspect cronicle-data
podman volume prune
```

**SELinux issues (Linux):**
```bash
# Add :Z flag to volumes for SELinux
-v cronicle-data:/opt/cronicle/data:Z
```

## Resources

- [Podman Documentation](https://docs.podman.io/)
- [Podman Compose](https://github.com/containers/podman-compose)
- [Migration from Docker](https://podman.io/getting-started/migration)
