#!/bin/bash
set -e

DATA_DIR="/opt/cronicle/data"
ADMIN_USER="${CRONICLE_ADMIN_USER:-admin}"
ADMIN_PASSWORD="${CRONICLE_ADMIN_PASSWORD:-}"
PASSWORD_FILE="$DATA_DIR/.admin_credentials"

# Initialize Cronicle if needed
if [ ! -f "$DATA_DIR/.setup_done" ]; then
    echo "Initializing Cronicle..."
    /opt/cronicle/bin/control.sh setup
    touch "$DATA_DIR/.setup_done"
    
    # Generate random password if not provided
    if [ -z "$ADMIN_PASSWORD" ]; then
        ADMIN_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-20)
        # Write credentials to file only (not to logs)
        cat > "$PASSWORD_FILE" << EOF
========================================
CRONICLE ADMIN CREDENTIALS
========================================
Username: $ADMIN_USER
Password: $ADMIN_PASSWORD
========================================
Generated: $(date)
========================================
EOF
        chmod 600 "$PASSWORD_FILE"
        echo "========================================"
        echo "Random admin password generated!"
        echo "Retrieve with: docker exec cronicle cat /opt/cronicle/data/.admin_credentials"
        echo "========================================"
    else
        echo "Using provided admin password for user: $ADMIN_USER"
    fi
    
    # Create admin user with password
    echo "Creating admin user..."
    sleep 3  # Wait for setup to complete
    /opt/cronicle/bin/control.sh admin "$ADMIN_USER" "$ADMIN_PASSWORD" 2>/dev/null || true
fi

echo "Starting Cronicle in foreground..."
cd /opt/cronicle
exec node lib/main.js --foreground
