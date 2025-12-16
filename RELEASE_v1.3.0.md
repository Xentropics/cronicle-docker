# Hardened Cronicle Docker Container v1.3.0

Production-ready, security-hardened Cronicle task scheduler container.

## Features

- **Ubuntu 24.04 LTS** - Latest long-term support base
- **Rootless execution** - UID/GID 3012, no shell access
- **Read-only root filesystem** - Enhanced security
- **Auto-generated admin passwords** - Secure by default
- **Comprehensive security hardening** - Dropped capabilities, no new privileges
- **Unattended security updates** - Automatic security patches
- **Multi-platform support** - Docker, Kubernetes, Podman
- **Node.js 22** - Latest LTS runtime
- **Python 3 with venv** - For job scripts

## Quick Start

```bash
docker run -d -p 3012:3012 xentropics/cronicle:1.3.0
```

Or with Docker Compose:

```bash
curl -O https://raw.githubusercontent.com/Xentropics/cronicle-docker/main/docker-compose.yml
curl -O https://raw.githubusercontent.com/Xentropics/cronicle-docker/main/.env.example
cp .env.example .env
# Edit .env - set CRONICLE_secret_key
docker-compose up -d
```

Access at: **http://localhost:3012**

## What's Changed

- Updated to Ubuntu 24.04 LTS
- Updated to Node.js 22
- Fixed UID/GID to 3012 for better isolation
- Enhanced security hardening
- Documentation improvements

## Security

This container follows security best practices:
- Non-root user (UID 3012)
- No SUID/SGID binaries
- Locked accounts
- Removed unnecessary network tools
- AppArmor enforcement
- Resource limits (2GB RAM, 200 PID)

**Important:** Change the default admin password immediately after first login.

## Documentation

See [README.md](https://github.com/Xentropics/cronicle-docker#readme) for full documentation.

## Container Images

- `xentropics/cronicle:latest`
- `xentropics/cronicle:1.3.0`

**Docker Hub:** https://hub.docker.com/r/xentropics/cronicle
