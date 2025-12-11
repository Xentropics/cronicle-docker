#!/usr/bin/env python3
"""
Example Python workload for Cronicle
Demonstrates a simple health check script
"""

import sys
import time
import json
from datetime import datetime


def check_disk_space():
    """Check disk space (simplified example)"""
    # In a real scenario, you'd use shutil or psutil
    return {"status": "ok", "usage": "45%"}


def check_memory():
    """Check memory usage (simplified example)"""
    # In a real scenario, you'd use psutil
    return {"status": "ok", "usage": "60%"}


def check_services():
    """Check if required services are running"""
    # Simplified example
    return {"cronicle": "running", "status": "healthy"}


def main():
    print(f"Health check started at {datetime.now().isoformat()}")

    results = {
        "timestamp": datetime.now().isoformat(),
        "disk": check_disk_space(),
        "memory": check_memory(),
        "services": check_services()
    }

    # Print results as JSON
    print(json.dumps(results, indent=2))

    # Determine overall health status
    all_ok = all(
        check.get("status") == "ok"
        for check in [results["disk"], results["memory"]]
    )

    if all_ok:
        print("✓ All health checks passed")
        return 0
    else:
        print("✗ Some health checks failed")
        return 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        print(f"Error during health check: {e}", file=sys.stderr)
        sys.exit(1)
