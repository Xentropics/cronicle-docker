#!/bin/bash
set -e

DATA_DIR="/opt/cronicle/data"
CONFIG_FILE="/opt/cronicle/conf/config.json"
ADMIN_USER="${CRONICLE_ADMIN_USER:-admin}"
ADMIN_PASSWORD="${CRONICLE_ADMIN_PASSWORD:-}"
PASSWORD_FILE="$DATA_DIR/.admin_credentials"

# Function to update config value - defined first so it's available everywhere
update_config() {
    local env_var=$1
    local json_key=$2
    local value_type=${3:-string}  # string, number, or boolean
    
    if [ -n "${!env_var}" ]; then
        local tmp_file=$(mktemp)
        echo "  Setting $json_key"
        
        if [ "$value_type" = "number" ]; then
            # Update as number
            if jq ".$json_key = ${!env_var}" "$CONFIG_FILE" > "$tmp_file" 2>/dev/null; then
                mv "$tmp_file" "$CONFIG_FILE"
            else
                echo "  Warning: Failed to set $json_key as number"
                rm -f "$tmp_file"
            fi
        elif [ "$value_type" = "boolean" ]; then
            # Convert string true/false to boolean
            local bool_val="false"
            local env_lower=$(echo "${!env_var}" | tr '[:upper:]' '[:lower:]')
            if [ "$env_lower" = "true" ] || [ "${!env_var}" = "1" ]; then
                bool_val="true"
            fi
            if jq ".$json_key = $bool_val" "$CONFIG_FILE" > "$tmp_file" 2>/dev/null; then
                mv "$tmp_file" "$CONFIG_FILE"
            else
                echo "  Warning: Failed to set $json_key as boolean"
                rm -f "$tmp_file"
            fi
        else
            # Update as string
            if jq --arg val "${!env_var}" ".$json_key = \$val" "$CONFIG_FILE" > "$tmp_file" 2>/dev/null; then
                mv "$tmp_file" "$CONFIG_FILE"
            else
                echo "  Warning: Failed to set $json_key as string"
                rm -f "$tmp_file"
            fi
        fi
    fi
}

# Check if initial setup is needed
if [ ! -f "$DATA_DIR/.setup_done" ]; then
    echo "Running initial Cronicle setup..."
    
    # Run setup - if it fails because data already exists, that's OK
    if /opt/cronicle/bin/control.sh setup 2>&1 | tee /tmp/setup.log; then
        echo "Setup completed successfully"
        touch "$DATA_DIR/.setup_done"
    elif grep -q "already been set up" /tmp/setup.log; then
        echo "Setup already exists (detected by setup command), marking as done"
        touch "$DATA_DIR/.setup_done"
    else
        echo "WARNING: Setup command failed but continuing anyway"
        touch "$DATA_DIR/.setup_done"
    fi
    
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
    /opt/cronicle/bin/control.sh admin "$ADMIN_USER" "$ADMIN_PASSWORD" 2>/dev/null || echo "Admin user creation skipped (may already exist)"
else
    echo "Setup already completed, skipping initialization..."
fi

# ALWAYS apply CRONICLE_* environment variables to config.json (even on restarts)
if [ -f "$CONFIG_FILE" ]; then
    echo "Updating configuration from environment variables..."
    
    # SMTP Configuration
    update_config "CRONICLE_email_from" "email_from"
    update_config "CRONICLE_smtp_hostname" "smtp_hostname"
    update_config "CRONICLE_smtp_port" "smtp_port" "number"
    update_config "CRONICLE_smtp_use_tls" "smtp_use_tls" "boolean"
    update_config "CRONICLE_smtp_username" "smtp_username"
    update_config "CRONICLE_smtp_password" "smtp_password"
    
    # Other common CRONICLE_ environment variables
    update_config "CRONICLE_base_app_url" "base_app_url"
    update_config "CRONICLE_server_hostname" "hostname"
    update_config "CRONICLE_web_http_port" "WebServer.http_port" "number"
    update_config "CRONICLE_secret_key" "secret_key"
    update_config "CRONICLE_timezone" "timezone"
    update_config "CRONICLE_storage_engine" "Storage.engine"
    update_config "CRONICLE_log_level" "log_level" "number"
    update_config "CRONICLE_master_ping_freq" "master_ping_freq" "number"
    update_config "CRONICLE_master_ping_timeout" "master_ping_timeout" "number"
    
    # For single-server setups, reduce master election timeout from 60s to 10s
    if [ -z "$CRONICLE_master_ping_timeout" ]; then
        echo "  Setting master_ping_timeout = 10 (for faster single-server startup)"
        TMP_FILE=$(mktemp)
        if jq ".master_ping_timeout = 10" "$CONFIG_FILE" > "$TMP_FILE" 2>/dev/null; then
            mv "$TMP_FILE" "$CONFIG_FILE"
        else
            rm -f "$TMP_FILE"
        fi
    fi
    
    echo "Configuration update complete."
fi

# ALWAYS start Cronicle (regardless of setup status)
echo "Starting Cronicle in foreground..."
cd /opt/cronicle
exec node lib/main.js --foreground
