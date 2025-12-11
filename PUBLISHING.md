# Publishing Guide

Guide for publishing the Cronicle Docker image to registries and GitHub.

## Prerequisites

- Docker Hub account
- GitHub account
- Git installed locally
- Docker installed and running

## 1. Publish to GitHub

### Initialize Git Repository

```bash
cd /path/to/xentropics-cronicle
git init
git add .
git commit -m "Initial commit: Hardened Cronicle Docker container"
```

### Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `xentropics-cronicle`
3. Description: "Hardened, rootless Docker container for Cronicle task scheduler"
4. Public or Private
5. Do NOT initialize with README (we have one)
6. Click "Create repository"

### Push to GitHub

```bash
# Add remote (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/xentropics-cronicle.git

# Push
git branch -M main
git push -u origin main
```

## 2. Publish Docker Image

### Manual Publishing

#### Tag the Image

```bash
# Build with proper tags
docker build -t xentropics/cronicle:latest .
docker build -t xentropics/cronicle:1.0.0 .
docker build -t xentropics/cronicle:1.0 .
docker build -t xentropics/cronicle:1 .
```

#### Login to Docker Hub

```bash
docker login
# Enter username and password
```

#### Push to Docker Hub

```bash
docker push xentropics/cronicle:latest
docker push xentropics/cronicle:1.0.0
docker push xentropics/cronicle:1.0
docker push xentropics/cronicle:1
```

### Automated Publishing via GitHub Actions

The repository includes GitHub Actions workflow for automated builds.

#### Setup GitHub Secrets

1. Go to: `https://github.com/YOUR_USERNAME/xentropics-cronicle/settings/secrets/actions`
2. Click "New repository secret"
3. Add:
   - Name: `DOCKER_USERNAME`, Value: your Docker Hub username
   - Name: `DOCKER_PASSWORD`, Value: your Docker Hub password or access token

#### Trigger Build

Builds trigger automatically on:
- Push to main/master branch
- New tags (e.g., `v1.0.0`)
- Pull requests (build only, no push)

```bash
# Create and push a tag
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

#### Monitor Build

Check: `https://github.com/YOUR_USERNAME/xentropics-cronicle/actions`

## 3. Multi-Architecture Build

Build for multiple platforms:

```bash
# Create buildx builder
docker buildx create --name multiarch --use
docker buildx inspect --bootstrap

# Build and push multi-arch
docker buildx build --platform linux/amd64,linux/arm64 \
  -t xentropics/cronicle:latest \
  -t xentropics/cronicle:1.0.0 \
  --push .
```

## 4. Docker Hub Repository Setup

### Update Docker Hub Description

1. Go to: `https://hub.docker.com/r/xentropics/cronicle`
2. Click "Description" tab
3. Paste README.md content
4. Click "Update"

### Add Repository Links

1. Click "Builds" tab
2. Link GitHub repository
3. Set build rules:
   - Source: `main` → Docker Tag: `latest`
   - Source: `v*` → Docker Tag: `{sourceref}`

## 5. Create GitHub Release

```bash
# Create annotated tag
git tag -a v1.0.0 -m "Release v1.0.0 - Initial hardened Cronicle container"
git push origin v1.0.0
```

Then on GitHub:
1. Go to `https://github.com/YOUR_USERNAME/xentropics-cronicle/releases/new`
2. Choose tag: `v1.0.0`
3. Release title: `v1.0.0 - Initial Release`
4. Description: Include changelog, features, security improvements
5. Click "Publish release"

## 6. Badge Updates

Add shields to README.md:

```markdown
[![Docker Pulls](https://img.shields.io/docker/pulls/xentropics/cronicle)](https://hub.docker.com/r/xentropics/cronicle)
[![Docker Image Size](https://img.shields.io/docker/image-size/xentropics/cronicle/latest)](https://hub.docker.com/r/xentropics/cronicle)
[![GitHub](https://img.shields.io/github/license/YOUR_USERNAME/xentropics-cronicle)](LICENSE)
```

## 7. Alternative Registries

### GitHub Container Registry (ghcr.io)

```bash
# Login
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Tag
docker tag xentropics/cronicle:latest ghcr.io/YOUR_USERNAME/cronicle:latest

# Push
docker push ghcr.io/YOUR_USERNAME/cronicle:latest
```

### Quay.io

```bash
# Login
docker login quay.io

# Tag
docker tag xentropics/cronicle:latest quay.io/YOUR_USERNAME/cronicle:latest

# Push
docker push quay.io/YOUR_USERNAME/cronicle:latest
```

## 8. Security Scanning

### Trivy

```bash
trivy image xentropics/cronicle:latest
```

### Snyk

```bash
snyk container test xentropics/cronicle:latest
```

### Docker Scout

```bash
docker scout cves xentropics/cronicle:latest
```

## 9. Version Tagging Strategy

Recommended semantic versioning:

- `latest` - Latest stable release
- `1` - Major version
- `1.0` - Minor version
- `1.0.0` - Patch version
- `1.0.0-alpine` - Variant (if multiple base images)

## 10. Maintenance

### Update Image

```bash
# Make changes
git add .
git commit -m "feat: add new security hardening"
git push

# Create new version
git tag -a v1.0.1 -m "Security improvements"
git push origin v1.0.1

# Rebuild and push
docker build -t xentropics/cronicle:1.0.1 -t xentropics/cronicle:latest .
docker push xentropics/cronicle:1.0.1
docker push xentropics/cronicle:latest
```

## Checklist

- [ ] Git repository initialized
- [ ] GitHub repository created
- [ ] Code pushed to GitHub
- [ ] Docker Hub account created
- [ ] GitHub secrets configured (DOCKER_USERNAME, DOCKER_PASSWORD)
- [ ] Multi-arch build tested
- [ ] Image pushed to Docker Hub
- [ ] Docker Hub description updated
- [ ] GitHub release created
- [ ] README badges updated
- [ ] Security scan passed
- [ ] Documentation complete
- [ ] License file present

## Resources

- [Docker Hub](https://hub.docker.com)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [GitHub Actions Docker](https://docs.github.com/en/actions/publishing-packages/publishing-docker-images)
- [Semantic Versioning](https://semver.org/)
