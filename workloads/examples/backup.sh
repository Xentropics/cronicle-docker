#!/bin/bash
# Example backup script
# This demonstrates a simple workload that can be scheduled in Cronicle

set -e

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/cronicle/data/backups"

echo "Starting backup at $(date)"
echo "Backup directory: $BACKUP_DIR"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Example: Backup some configuration files
echo "Creating backup archive..."
tar -czf "$BACKUP_DIR/config_backup_${TIMESTAMP}.tar.gz" /opt/cronicle/conf/ 2>/dev/null || true

# Check if backup was successful
if [ -f "$BACKUP_DIR/config_backup_${TIMESTAMP}.tar.gz" ]; then
    echo "Backup completed successfully: config_backup_${TIMESTAMP}.tar.gz"
    ls -lh "$BACKUP_DIR/config_backup_${TIMESTAMP}.tar.gz"
else
    echo "Backup failed!"
    exit 1
fi

# Cleanup old backups (keep last 7 days)
echo "Cleaning up old backups..."
find "$BACKUP_DIR" -name "config_backup_*.tar.gz" -mtime +7 -delete

echo "Backup job finished at $(date)"
exit 0
