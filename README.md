# Cronicle Docker

**Hardened Docker container for Cronicle task scheduler**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![Security](https://img.shields.io/badge/Security-Hardened-green.svg)]()

## About

Secure, production-ready Docker container for [Cronicle](https://github.com/jhuckaby/Cronicle) - a multi-server task scheduler with web UI. Built with comprehensive security hardening, rootless execution, and following container best practices.

**Project:** xentropics-cronicle  
**Author:** Jeroen Seeverens, Xentropics  
**Base Application:** [Cronicle by jhuckaby](https://github.com/jhuckaby/Cronicle)  
**License:** MIT  
**Last Updated:** December 2025

---

## Features

- Ubuntu 24.04 LTS with comprehensive security hardening
- Rootless execution (UID/GID 3012)
- Environment-based configuration
- Read-only root filesystem support
- Multi-storage backends (Filesystem, Couchbase, S3)
- SMTP notifications
- Mountable workloads directory
- Kubernetes and Podman deployment options

## Quick Start

### Docker Compose (Recommended)

```bash
./setup.sh
```

Or manually:
```bash
cp .env.example .env
# Edit .env - set CRONICLE_secret_key to random value
docker-compose up -d
```

### Kubernetes

See [KUBERNETES.md](KUBERNETES.md) for full deployment guide.

```bash
kubectl apply -f kubernetes.yaml
kubectl -n cronicle port-forward svc/cronicle 3012:3012
```

### Podman

See [PODMAN.md](PODMAN.md) for detailed instructions.

```bash
podman-compose up -d
# Or use podman directly
podman run -d --name cronicle -p 3012:3012 xentropics/cronicle:latest
```

Access: `http://localhost:3012`

## Admin Credentials

On first boot, if no password is set, a random password is generated:

```bash
# Docker Compose
docker-compose exec cronicle cat /opt/cronicle/data/.admin_credentials

# Kubernetes
kubectl -n cronicle exec deployment/cronicle -- cat /opt/cronicle/data/.admin_credentials

# Podman
podman exec cronicle cat /opt/cronicle/data/.admin_credentials
```

## Configuration

All settings use `CRONICLE_` prefixed environment variables. See [.env.example](.env.example).

Key variables:
```env
CRONICLE_base_app_url=http://localhost:3012
CRONICLE_secret_key=<generate-random-32-char-string>
CRONICLE_smtp_hostname=smtp.gmail.com
CRONICLE_storage_engine=Filesystem
```

## Workloads

Place executable scripts in `./workloads/` - accessible at `/opt/cronicle/workloads/` in container.

```bash
mkdir -p workloads/scripts
chmod +x workloads/scripts/backup.sh
```

See [workloads/README.md](workloads/README.md) for examples.

## Volumes

- `cronicle-data` - Application data
- `cronicle-logs` - Log files  
- `./workloads` - Job scripts (read-only mount)

## Commands

```bash
make build       # Build image
make up          # Start service
make down        # Stop service
make logs        # View logs
make shell       # Container shell
make backup      # Backup volumes
```

## Security

**Hardening Principles:**
- Rootless execution (UID/GID 3012, no shell access)
- Read-only root filesystem
- Dropped all Linux capabilities
- No new privileges flag
- AppArmor profile enforcement
- Resource limits (2GB RAM, 200 PID limit)
- Unattended security updates enabled
- Minimal attack surface (removed wget, nc, telnet, ftp)
- Kernel hardening (suid_dumpable=0, dmesg_restrict=1, kptr_restrict=2)
- Locked system accounts and root

Change admin password immediately after first login. Generate strong secret key:
```bash
openssl rand -hex 32
```

## Troubleshooting

View logs:
```bash
docker-compose logs -f
```

Debug mode:
```env
CRONICLE_debug=true
CRONICLE_log_level=9
```

Fix permissions:
```bash
sudo chown -R 3012:3012 /var/lib/docker/volumes/cronicle-*/_data
```

## License

MIT - See Cronicle project for details.
