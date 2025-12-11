#!/bin/bash
# Example cleanup script for Cronicle workloads
# Cleans up temporary files and old logs

set -e

TEMP_DIR="/tmp"
LOG_DIR="/opt/cronicle/logs"
MAX_AGE_DAYS=7

echo "==================================="
echo "Cleanup Job Started"
echo "==================================="
echo "Timestamp: $(date)"
echo "Temp directory: $TEMP_DIR"
echo "Log directory: $LOG_DIR"
echo "Max age: $MAX_AGE_DAYS days"
echo ""

# Cleanup old temporary files
echo "Cleaning temporary files..."
if [ -d "$TEMP_DIR" ]; then
    TEMP_COUNT=$(find "$TEMP_DIR" -type f -mtime +$MAX_AGE_DAYS 2>/dev/null | wc -l)
    find "$TEMP_DIR" -type f -mtime +$MAX_AGE_DAYS -delete 2>/dev/null || true
    echo "  Removed $TEMP_COUNT temporary files older than $MAX_AGE_DAYS days"
fi

# Cleanup old log files
echo "Cleaning old log files..."
if [ -d "$LOG_DIR" ]; then
    LOG_COUNT=$(find "$LOG_DIR" -name "*.log.*" -mtime +$MAX_AGE_DAYS 2>/dev/null | wc -l)
    find "$LOG_DIR" -name "*.log.*" -mtime +$MAX_AGE_DAYS -delete 2>/dev/null || true
    echo "  Removed $LOG_COUNT log files older than $MAX_AGE_DAYS days"
fi

# Report disk usage
echo ""
echo "Current disk usage:"
df -h / 2>/dev/null || echo "  Unable to determine disk usage"

echo ""
echo "==================================="
echo "Cleanup Job Completed Successfully"
echo "==================================="

exit 0
