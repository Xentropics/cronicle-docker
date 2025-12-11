# Cronicle Workloads

This directory contains scripts, jobs, and other executables that can be scheduled and run by Cronicle.

## Directory Structure

```
workloads/
├── examples/          # Example scripts demonstrating various use cases
│   ├── backup.sh     # Backup script example
│   ├── cleanup.sh    # Cleanup/maintenance script
│   └── health-check.py  # Python health check example
├── scripts/          # Your custom bash/shell scripts
├── python/           # Your custom Python scripts
├── jobs/             # Other job types (Node.js, Perl, etc.)
└── README.md         # This file
```

## Creating Workloads

### Bash Scripts

```bash
#!/bin/bash
# Your script must start with a shebang
set -e  # Exit on error

echo "Starting job at $(date)"

# Your job logic here

exit 0  # Return success
```

### Python Scripts

```python
#!/usr/bin/env python3
import sys

def main():
    print("Starting Python job")
    # Your job logic here
    return 0  # Return success

if __name__ == "__main__":
    sys.exit(main())
```

### Node.js Scripts

```javascript
#!/usr/bin/env node

console.log('Starting Node.js job');

// Your job logic here

process.exit(0); // Return success
```

## Making Scripts Executable

Before scheduling your scripts in Cronicle, make sure they are executable:

```bash
chmod +x workloads/scripts/your-script.sh
```

Or use the Makefile helper:

```bash
make chmod-workloads
```

## Accessing Workloads in Cronicle

1. **Access the Web UI**: http://localhost:3012
2. **Create a New Event**: Go to Schedule → Add Event
3. **Configure Plugin**: Select "Shell Script" or appropriate plugin
4. **Set Script Path**: Use the full path inside the container:
   ```
   /opt/cronicle/workloads/scripts/your-script.sh
   ```

## Environment Variables

Your scripts can access environment variables set in Cronicle or passed from the job configuration:

```bash
#!/bin/bash

echo "Job ID: $JOB_ID"
echo "Event Title: $EVENT_TITLE"
echo "Custom Var: $MY_CUSTOM_VAR"
```

## Best Practices

### 1. Error Handling

Always use proper error handling:

```bash
#!/bin/bash
set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Your script logic
```

### 2. Logging

Provide clear logging output:

```bash
echo "[$(date)] Starting backup process..."
echo "[$(date)] Backup completed successfully"
```

### 3. Exit Codes

Return appropriate exit codes:
- `0`: Success
- `1-255`: Error (Cronicle will mark job as failed)

```bash
if [ $? -eq 0 ]; then
    echo "Success!"
    exit 0
else
    echo "Failed!"
    exit 1
fi
```

### 4. Timeouts

Set reasonable timeouts in Cronicle to prevent hung jobs:
- Go to Event settings → Timeout
- Set based on expected job duration

### 5. Resource Management

Be mindful of resource usage:
- Clean up temporary files
- Close file handles
- Avoid memory leaks in long-running scripts

### 6. Security

- Don't hardcode credentials
- Use environment variables for sensitive data
- Validate inputs
- Use least privilege principle

## Common Use Cases

### Scheduled Backups

```bash
#!/bin/bash
BACKUP_DIR="/opt/cronicle/data/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

tar -czf "$BACKUP_DIR/backup_${TIMESTAMP}.tar.gz" /path/to/data
find "$BACKUP_DIR" -mtime +30 -delete  # Keep last 30 days
```

### Health Checks

```bash
#!/bin/bash
# Check if service is responding
curl -f http://localhost:8080/health || exit 1
```

### Data Processing

```python
#!/usr/bin/env python3
import sys
import pandas as pd

def process_data():
    df = pd.read_csv('/opt/cronicle/workloads/data/input.csv')
    # Process data
    df.to_csv('/opt/cronicle/workloads/data/output.csv')
    return 0

if __name__ == "__main__":
    sys.exit(process_data())
```

### Maintenance Tasks

```bash
#!/bin/bash
# Clean up old files
find /tmp -type f -mtime +7 -delete

# Restart service if needed
if ! systemctl is-active --quiet myservice; then
    systemctl restart myservice
fi
```

## Debugging

### Enable Debug Output

```bash
#!/bin/bash
set -x  # Print commands before execution

# Your script
```

### Check Job Logs

1. **In Cronicle UI**: Go to Jobs → View Job Details
2. **Container logs**: `docker-compose logs -f cronicle`
3. **Application logs**: `docker-compose exec cronicle cat /opt/cronicle/logs/cronicle.log`

### Test Scripts Manually

```bash
# Execute inside the container
docker-compose exec cronicle /opt/cronicle/workloads/scripts/your-script.sh

# Or from outside
docker-compose exec cronicle bash -c "cd /opt/cronicle && ./workloads/scripts/your-script.sh"
```

## Advanced Features

### Chain Jobs

Configure job chains in Cronicle:
1. Event A completes successfully
2. Trigger Event B automatically
3. On failure, trigger Event C (cleanup)

### Retry Logic

Add retry logic to your scripts:

```bash
#!/bin/bash
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if run_task; then
        exit 0
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep 10
done

echo "Failed after $MAX_RETRIES attempts"
exit 1
```

### Email Notifications

Cronicle can send email notifications on job completion/failure. Configure SMTP settings in your `.env` file.

## Example Workflows

### Daily Backup + Cleanup

1. **backup.sh** (runs at 2 AM)
   - Creates database backup
   - Archives logs
   - Returns 0 on success

2. **cleanup.sh** (runs at 3 AM, chained after backup)
   - Removes old backups (>30 days)
   - Cleans temp files
   - Sends summary email

### Monitoring Pipeline

1. **health-check.py** (runs every 5 minutes)
   - Checks system health
   - Returns 1 if issues found
   
2. **alert.sh** (triggered on health-check failure)
   - Sends alert email
   - Logs incident
   - Attempts auto-recovery

## Resources

- [Cronicle Documentation](https://github.com/jhuckaby/Cronicle)
- [Shell Scripting Guide](https://www.shellscript.sh/)
- [Python Best Practices](https://docs.python-guide.org/)

## Support

For issues with your workloads:
1. Test scripts manually first
2. Check Cronicle job logs
3. Verify file permissions
4. Ensure all dependencies are available in the container
