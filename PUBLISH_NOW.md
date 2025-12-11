# Publishing Checklist

Follow these steps in order:

## Step 1: Create GitHub Repository

1. Open: https://github.com/new
2. Fill in:
   - **Repository name:** `cronicle-docker`
   - **Description:** `Hardened, rootless Docker container for Cronicle task scheduler`
   - **Visibility:** Public
   - **⚠️ IMPORTANT:** Do NOT check "Initialize with README"
3. Click "Create repository"

## Step 2: Push to GitHub

After creating the repository, run:

```bash
cd /Users/xentropics/ProjectenNieuweStijl/Applications/Docker/xentropics-cronicle
git push -u origin main
git push origin v1.0.0
```

## Step 3: Login to Docker Hub

```bash
docker login
```

Enter your Docker Hub username and password when prompted.

## Step 4: Build and Publish Docker Image

Run the automated script:

```bash
./publish-image.sh
```

Or build manually:

```bash
# Build for current platform
docker build -t xentropics/cronicle:latest -t xentropics/cronicle:1.0.0 .

# Test
docker run --rm xentropics/cronicle:latest node --version

# Push to Docker Hub
docker push xentropics/cronicle:latest
docker push xentropics/cronicle:1.0.0
```

## Step 5: Create GitHub Release

1. Go to: https://github.com/xentropics/cronicle-docker/releases/new
2. Choose tag: `v1.0.0`
3. Release title: `v1.0.0 - Initial Release`
4. Add description:
   ```
   # Hardened Cronicle Docker Container v1.0.0
   
   Initial release of production-ready, security-hardened Cronicle container.
   
   ## Features
   - ✅ Rootless execution (UID 1000)
   - ✅ Read-only root filesystem
   - ✅ Auto-generated admin passwords
   - ✅ Comprehensive security hardening
   - ✅ Unattended security updates
   - ✅ Multi-platform support (Docker, Kubernetes, Podman)
   
   ## Quick Start
   ```bash
   docker run -d -p 3012:3012 xentropics/cronicle:latest
   ```
   
   Access at: http://localhost:3012
   
   See README.md for full documentation.
   ```
5. Click "Publish release"

## Step 6: Update Docker Hub Description

1. Go to: https://hub.docker.com/r/xentropics/cronicle
2. Click "Description" tab
3. Copy content from README.md
4. Paste and save

## Done! 🎉

Your project is now published:
- GitHub: https://github.com/xentropics/cronicle-docker
- Docker Hub: https://hub.docker.com/r/xentropics/cronicle
