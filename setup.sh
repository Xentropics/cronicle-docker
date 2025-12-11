#!/bin/bash
# Quick start script for Cronicle Docker setup

set -e

echo "======================================"
echo "Cronicle Docker Setup"
echo "======================================"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running"
    echo "Please start Docker and try again"
    exit 1
fi

echo "✓ Docker is running"

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Error: docker-compose is not installed"
    echo "Please install docker-compose and try again"
    exit 1
fi

echo "✓ docker-compose is available"
echo ""

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
    
    # Generate a random secret key
    SECRET_KEY=$(openssl rand -hex 32 2>/dev/null || head -c 32 /dev/urandom | base64)
    
    # Update secret key in .env
    if command -v perl &> /dev/null; then
        perl -i -pe "s/CHANGE_THIS_TO_A_RANDOM_SECURE_STRING/$SECRET_KEY/g" .env
        echo "✓ Created .env file with random secret key"
    else
        echo "⚠ Created .env file - please update CRONICLE_secret_key manually!"
    fi
else
    echo "✓ .env file already exists"
fi

echo ""

# Create workloads directories
echo "Setting up workloads directories..."
mkdir -p workloads/scripts
mkdir -p workloads/python
mkdir -p workloads/jobs
echo "✓ Workloads directories created"

echo ""

# Make example scripts executable
echo "Making example scripts executable..."
find workloads/examples -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \; 2>/dev/null || true
echo "✓ Example scripts are executable"

echo ""
echo "======================================"
echo "Building Docker image..."
echo "======================================"
docker-compose build

echo ""
echo "======================================"
echo "Starting Cronicle..."
echo "======================================"
docker-compose up -d

echo ""
echo "Waiting for Cronicle to start (30 seconds)..."
sleep 30

# Check if container is running
if docker-compose ps | grep -q "Up"; then
    echo "✓ Cronicle is running!"
    echo ""
    echo "======================================"
    echo "Setup Complete!"
    echo "======================================"
    echo ""
    echo "Access Cronicle at: http://localhost:3012"
    echo ""
    echo "Default credentials (change immediately!):"
    echo "  Username: admin"
    echo "  Password: admin"
    echo ""
    echo "Useful commands:"
    echo "  make logs      - View container logs"
    echo "  make shell     - Open shell in container"
    echo "  make restart   - Restart Cronicle"
    echo "  make down      - Stop Cronicle"
    echo "  make backup    - Create backup"
    echo ""
    echo "Documentation: See README.md"
    echo "Workloads: See workloads/README.md"
    echo ""
else
    echo "❌ Error: Cronicle failed to start"
    echo ""
    echo "Check logs with: docker-compose logs"
    exit 1
fi
